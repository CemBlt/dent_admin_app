from __future__ import annotations

from datetime import datetime, date, time
from typing import List

from .supabase_client import get_supabase_client


def get_appointments() -> List[dict]:
    """Tüm randevuları Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("appointments").select("*").execute()
    
    if not result.data:
        return []
    
    return [_format_appointment_from_db(a) for a in result.data]


def filter_appointments(status=None, doctor_id=None, service_id=None, start_date=None, end_date=None):
    """Randevuları filtreler."""
    supabase = get_supabase_client()
    query = supabase.table("appointments").select("*")
    
    if status:
        query = query.eq("status", status)
    if doctor_id:
        query = query.eq("doctor_id", doctor_id)
    if service_id:
        query = query.eq("service_id", service_id)
    if start_date:
        query = query.gte("date", start_date.isoformat())
    if end_date:
        query = query.lte("date", end_date.isoformat())
    
    result = query.execute()
    
    if not result.data:
        return []
    
    return [_format_appointment_from_db(a) for a in result.data]


def update_appointment(appointment_id: str, **changes):
    """Randevu bilgilerini günceller."""
    supabase = get_supabase_client()
    
    # Supabase formatına çevir
    db_changes = {}
    if "status" in changes:
        db_changes["status"] = changes["status"]
    if "date" in changes:
        db_changes["date"] = changes["date"] if isinstance(changes["date"], str) else changes["date"].isoformat()
    if "time" in changes:
        db_changes["time"] = changes["time"] if isinstance(changes["time"], str) else changes["time"].strftime("%H:%M")
    if "notes" in changes:
        db_changes["notes"] = changes["notes"]
    
    result = supabase.table("appointments").update(db_changes).eq("id", appointment_id).execute()
    
    if not result.data:
        raise ValueError("Randevu bulunamadı veya güncellenemedi")
    
    return _format_appointment_from_db(result.data[0])


def delete_appointment(appointment_id: str):
    """Randevuyu siler."""
    supabase = get_supabase_client()
    result = supabase.table("appointments").delete().eq("id", appointment_id).execute()
    
    if not result.data:
        raise ValueError("Randevu bulunamadı veya silinemedi")


def get_summary():
    """Randevu özet istatistiklerini getirir."""
    supabase = get_supabase_client()
    today = datetime.now().date()
    
    # Tüm randevuları al
    all_appointments = supabase.table("appointments").select("status,date").execute()
    
    stats = {
        "pending": 0,
        "completed": 0,
        "cancelled": 0,
        "today": 0,
    }
    
    if all_appointments.data:
        for apt in all_appointments.data:
            status = apt.get("status", "")
            if status == "pending":
                stats["pending"] += 1
            elif status == "completed":
                stats["completed"] += 1
            elif status == "cancelled":
                stats["cancelled"] += 1
            
            apt_date = apt.get("date", "")
            if apt_date == today.isoformat():
                stats["today"] += 1
    
    return stats


def auto_cancel_overdue_appointments(hospital_id: str = "1") -> int:
    """
    Randevu tarihinden 5 gün geçmiş ve hala tamamlanmamış randevuları otomatik iptal eder.
    Returns: İptal edilen randevu sayısı
    """
    from datetime import timedelta
    
    supabase = get_supabase_client()
    today = date.today()
    five_days_ago = (today - timedelta(days=5)).isoformat()
    
    # 5 günden eski, pending olan randevuları bul
    result = supabase.table("appointments").select("id").eq("hospital_id", hospital_id).eq("status", "pending").lt("date", five_days_ago).execute()
    
    cancelled_count = 0
    if result.data:
        for apt in result.data:
            supabase.table("appointments").update({"status": "cancelled"}).eq("id", apt["id"]).execute()
            cancelled_count += 1
    
    return cancelled_count


def is_appointment_time_blocked(appointment_date: date, appointment_time: str, hospital_id: str = "1") -> bool:
    """
    Belirli bir tarih ve saatte randevu alınıp alınamayacağını kontrol eder.
    Tüm gün tatillerde True döner (randevu alınamaz).
    Saatli tatillerde sadece tatil saatleri içinde True döner.
    """
    supabase = get_supabase_client()
    appointment_date_str = appointment_date.isoformat()
    
    # Randevu saatini time objesine çevir
    try:
        apt_time = datetime.strptime(appointment_time, "%H:%M").time()
    except (ValueError, TypeError):
        return False
    
    # O tarihteki hastane tatillerini getir
    result = supabase.table("holidays").select("*").eq("hospital_id", hospital_id).eq("date", appointment_date_str).is_("doctor_id", "null").execute()
    
    if not result.data:
        return False
    
    for holiday in result.data:
        # Tüm gün tatil
        if holiday.get("is_full_day", True):
            return True
        
        # Saatli tatil kontrolü
        start_time_str = holiday.get("start_time")
        end_time_str = holiday.get("end_time")
        if start_time_str and end_time_str:
            try:
                start_time = datetime.strptime(start_time_str, "%H:%M").time()
                end_time = datetime.strptime(end_time_str, "%H:%M").time()
                # Randevu saati tatil saatleri arasındaysa engelle
                if start_time <= apt_time <= end_time:
                    return True
            except (ValueError, TypeError):
                continue
    
    return False


def _format_appointment_from_db(db_appointment: dict) -> dict:
    """Supabase'den gelen randevu verisini mevcut formata çevirir."""
    return {
        "id": str(db_appointment.get("id", "")),
        "userId": str(db_appointment.get("user_id", "")),
        "hospitalId": str(db_appointment.get("hospital_id", "")),
        "doctorId": str(db_appointment.get("doctor_id", "")),
        "date": db_appointment.get("date", ""),
        "time": db_appointment.get("time", ""),
        "status": db_appointment.get("status", ""),
        "service": str(db_appointment.get("service_id", "")),
        "notes": db_appointment.get("notes", ""),
        "createdAt": db_appointment.get("created_at", ""),
    }
