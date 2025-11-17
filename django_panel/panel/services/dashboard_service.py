from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from datetime import date, datetime
from typing import Any

from .json_repository import load_json

ACTIVE_HOSPITAL_ID = "1"


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
    hospitals = load_json('hospitals')
    doctors = [d for d in load_json('doctors') if d['hospitalId'] == ACTIVE_HOSPITAL_ID]
    appointments = [
        apt for apt in load_json('appointments')
        if apt['hospitalId'] == ACTIVE_HOSPITAL_ID
    ]
    services = load_json('services')
    ratings = [r for r in load_json('ratings') if r['hospitalId'] == ACTIVE_HOSPITAL_ID]
    reviews = [r for r in load_json('reviews') if r['hospitalId'] == ACTIVE_HOSPITAL_ID]
    users = {u['id']: u for u in load_json('users')}
    holidays = [h for h in load_json('holidays') if h['hospitalId'] == ACTIVE_HOSPITAL_ID]

    hospital = next((h for h in hospitals if h['id'] == ACTIVE_HOSPITAL_ID), hospitals[0])

    today = _today()
    pending_count = sum(1 for apt in appointments if apt['status'] == 'pending')
    today_count = sum(1 for apt in appointments if _parse_date(apt['date']) == today)
    doctor_count = len(doctors)
    avg_rating = (
        sum(r['hospitalRating'] for r in ratings) / len(ratings)
        if ratings else 0
    )

    kpi_cards = [
        KPI("Bekleyen Randevu", str(pending_count), "Onay bekleyen randevular", "schedule", "#FDE68A"),
        KPI("Bugünkü Randevu", str(today_count), "Günün toplam randevusu", "today", "#A5F3FC"),
        KPI("Aktif Doktor", str(doctor_count), "Paneldeki toplam doktor", "medical_services", "#C7D2FE"),
        KPI("Ortalama Puan", f"{avg_rating:.1f}", "Hastane ortalaması", "star", "#FBCFE8"),
    ]

    upcoming_appointments = sorted(
        appointments,
        key=lambda a: (a['date'], a['time'])
    )
    todays_appointments = [
        _build_appointment_card(apt, doctors, services, users)
        for apt in upcoming_appointments
        if _parse_date(apt['date']) == today
    ][:6]

    doctor_status = [_build_doctor_status(doc, today) for doc in doctors]

    service_stats = _build_service_stats(appointments, services)

    latest_reviews = _build_reviews(reviews, users)

    upcoming_holidays = _build_upcoming_holidays(holidays, today)

    return {
        'hospital': hospital,
        'kpi_cards': kpi_cards,
        'todays_appointments': todays_appointments,
        'doctor_status': doctor_status,
        'service_stats': service_stats,
        'latest_reviews': latest_reviews,
        'upcoming_holidays': upcoming_holidays,
    }


def _build_appointment_card(apt, doctors, services, users):
    doctor = next((d for d in doctors if d['id'] == apt['doctorId']), None)
    service = next((s for s in services if s['id'] == apt['service']), None)
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
        count = counts.get(service['id'], 0)
        percent = round((count / total) * 100)
        stats.append({
            'name': service['name'],
            'count': count,
            'percent': percent,
        })
    stats.sort(key=lambda s: s['count'], reverse=True)
    return stats[:4]


def _build_reviews(reviews, users):
    sorted_reviews = sorted(reviews, key=lambda r: r['createdAt'], reverse=True)
    latest = []
    for rev in sorted_reviews[:3]:
        user = users.get(rev['userId'])
        latest.append({
            'patient': f"{user['name']} {user['surname']}" if user else 'Hasta',
            'comment': rev['comment'],
            'date': rev['createdAt'][:10],
        })
    return latest


def _build_upcoming_holidays(holidays, today):
    parsed = []
    for holiday in holidays:
        h_date = _parse_date(holiday['date'])
        if h_date and h_date >= today:
            parsed.append({
                'date': h_date.strftime('%d %B %Y'),
                'reason': holiday['reason'],
            })
    parsed.sort(key=lambda h: h['date'])
    return parsed[:4]
