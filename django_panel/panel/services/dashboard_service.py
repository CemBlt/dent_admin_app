from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from datetime import date, datetime
from typing import Any

from .supabase_client import get_supabase_client
from .hospital_service import _get_active_hospital_id, _format_hospital_from_db
from .appointment_service import get_appointments, _format_appointment_from_db
from .doctor_service import get_doctors, _format_doctor_from_db
from .service_service import get_services
from .review_service import _load_reviews, _load_ratings
from .user_service import get_user_map


@dataclass
class KPI:
    title: str
    value: str
    description: str
    icon: str
    color: str


def _parse_date(value: str) -> date | None:
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _today() -> date:
    return datetime.now().date()


def load_dashboard_context() -> dict[str, Any]:
    """Dashboard için gerekli tüm verileri Supabase'den getirir."""
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id()
    
    # Hastane bilgisi
    hospital_result = supabase.table("hospitals").select("*").eq("id", hospital_id).single().execute()
    hospital = _format_hospital_from_db(hospital_result.data)
    
    # Doktorlar
    doctors_result = supabase.table("doctors").select("*").eq("hospital_id", hospital_id).execute()
    doctors = [_format_doctor_from_db(d) for d in doctors_result.data] if doctors_result.data else []
    
    # Randevular
    appointments_result = supabase.table("appointments").select("*").eq("hospital_id", hospital_id).execute()
    appointments = [_format_appointment_from_db(a) for a in appointments_result.data] if appointments_result.data else []
    
    # Hizmetler
    services_result = supabase.table("services").select("*").execute()
    services = services_result.data if services_result.data else []
    
    # Puanlamalar
    ratings_result = supabase.table("ratings").select("*").eq("hospital_id", hospital_id).execute()
    ratings = ratings_result.data if ratings_result.data else []
    
    # Yorumlar
    reviews_result = supabase.table("reviews").select("*").eq("hospital_id", hospital_id).execute()
    reviews = reviews_result.data if reviews_result.data else []
    
    # Kullanıcılar
    users = get_user_map()
    
    # Tatiller
    holidays_result = supabase.table("holidays").select("*").eq("hospital_id", hospital_id).execute()
    holidays = holidays_result.data if holidays_result.data else []
    
    # KPI hesaplamaları
    today = _today()
    pending_count = sum(1 for apt in appointments if apt['status'] == 'pending')
    today_count = sum(1 for apt in appointments if _parse_date(apt['date']) == today)
    doctor_count = len(doctors)
    
    # Ortalama puan hesapla
    hospital_ratings = [r.get('hospital_rating', 0) or 0 for r in ratings]
    avg_rating = sum(hospital_ratings) / len(hospital_ratings) if hospital_ratings else 0
    
    kpi_cards = [
        KPI("Bekleyen Randevu", str(pending_count), "Onay bekleyen randevular", "schedule", "#FDE68A"),
        KPI("Bugünkü Randevu", str(today_count), "Günün toplam randevusu", "today", "#A5F3FC"),
        KPI("Aktif Doktor", str(doctor_count), "Paneldeki toplam doktor", "medical_services", "#C7D2FE"),
        KPI("Ortalama Puan", f"{avg_rating:.1f}", "Hastane ortalaması", "star", "#FBCFE8"),
    ]
    
    # Bugünkü randevular
    upcoming_appointments = sorted(
        appointments,
        key=lambda a: (a['date'], a['time'])
    )
    todays_appointments = [
        _build_appointment_card(apt, doctors, services, users)
        for apt in upcoming_appointments
        if _parse_date(apt['date']) == today
    ][:6]
    
    # Doktor durumları
    doctor_status = [_build_doctor_status(doc, today) for doc in doctors]
    
    # Hizmet istatistikleri
    service_stats = _build_service_stats(appointments, services)
    
    # Son yorumlar
    latest_reviews = _build_reviews(reviews, users)
    
    # Yaklaşan tatiller
    upcoming_holidays = _build_upcoming_holidays(holidays, today)
    
    # Doktor puanlamaları
    doctor_ratings = _build_doctor_ratings(doctors, ratings)
    
    return {
        'hospital': hospital,
        'kpi_cards': kpi_cards,
        'todays_appointments': todays_appointments,
        'doctor_status': doctor_status,
        'service_stats': service_stats,
        'latest_reviews': latest_reviews,
        'upcoming_holidays': upcoming_holidays,
        'doctor_ratings': doctor_ratings,
    }


def _build_appointment_card(apt, doctors, services, users):
    doctor = next((d for d in doctors if d['id'] == apt['doctorId']), None)
    service = next((s for s in services if str(s['id']) == apt['service']), None)
    user = users.get(apt['userId'])
    return {
        'time': apt['time'],
        'patient': f"{user['name']} {user['surname']}" if user else 'Hasta',
        'doctor': doctor['name'] + ' ' + doctor['surname'] if doctor else 'Doktor',
        'service': service['name'] if service else 'Hizmet',
        'status': apt['status'],
    }


def _build_doctor_status(doctor, today):
    weekday = today.strftime('%A').lower()
    working = doctor['workingHours'].get(weekday, {})
    is_available = working.get('isAvailable')
    status = 'Ofiste' if is_available else 'İzinli'
    return {
        'name': f"{doctor['name']} {doctor['surname']}",
        'specialty': doctor['specialty'],
        'status': status,
        'is_available': bool(is_available),
    }


def _build_service_stats(appointments, services):
    counts = Counter(apt['service'] for apt in appointments)
    total = sum(counts.values()) or 1
    stats = []
    for service in services:
        service_id = str(service['id'])
        count = counts.get(service_id, 0)
        percent = round((count / total) * 100)
        stats.append({
            'name': service['name'],
            'count': count,
            'percent': percent,
        })
    stats.sort(key=lambda s: s['count'], reverse=True)
    return stats[:4]


def _build_reviews(reviews, users):
    sorted_reviews = sorted(reviews, key=lambda r: r.get('created_at', ''), reverse=True)
    latest = []
    for rev in sorted_reviews[:3]:
        user_id = str(rev.get('user_id', ''))
        user = users.get(user_id)
        latest.append({
            'patient': f"{user['name']} {user['surname']}" if user else 'Hasta',
            'comment': rev.get('comment', ''),
            'date': rev.get('created_at', '')[:10] if rev.get('created_at') else '',
        })
    return latest


def _build_upcoming_holidays(holidays, today):
    parsed = []
    for holiday in holidays:
        h_date_str = holiday.get('date')
        if h_date_str:
            h_date = _parse_date(h_date_str)
            if h_date and h_date >= today:
                parsed.append({
                    'date': h_date.strftime('%d %B %Y'),
                    'reason': holiday.get('reason', ''),
                })
    parsed.sort(key=lambda h: h['date'])
    return parsed[:4]


def _build_doctor_ratings(doctors, ratings):
    """
    Her doktor için ortalama puanı hesaplar.
    Sadece aktif hastanenin doktorları için puanları döndürür.
    """
    doctor_ratings_list = []
    
    for doctor in doctors:
        doctor_id = str(doctor['id'])
        # Bu doktora ait tüm puanları filtrele
        doctor_ratings_data = [
            r.get('doctor_rating', 0) or 0 for r in ratings
            if str(r.get('doctor_id', '')) == doctor_id and r.get('doctor_rating')
        ]
        
        # Ortalama puanı hesapla
        if doctor_ratings_data:
            avg_rating = sum(doctor_ratings_data) / len(doctor_ratings_data)
            rating_count = len(doctor_ratings_data)
        else:
            avg_rating = 0.0
            rating_count = 0
        
        doctor_ratings_list.append({
            'id': doctor['id'],
            'name': f"{doctor['name']} {doctor['surname']}",
            'specialty': doctor.get('specialty', ''),
            'rating': round(avg_rating, 1),
            'rating_count': rating_count,
        })
    
    # Puanına göre sırala (yüksekten düşüğe)
    doctor_ratings_list.sort(key=lambda d: d['rating'], reverse=True)
    
    return doctor_ratings_list
