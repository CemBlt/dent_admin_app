from __future__ import annotations

from calendar import monthrange
from datetime import date, datetime, timedelta

from .supabase_client import get_supabase_client
from .hospital_service import _get_active_hospital_id, get_hospital
from .doctor_service import get_doctors


def get_hospital_working_hours(request=None) -> dict:
    """Hastane çalışma saatlerini getirir."""
    try:
        hospital = get_hospital(request)
        return hospital.get("workingHours", {})
    except:
        return {}


def get_doctor_working_hours(doctor_id: str | None = None) -> dict:
    """Doktor çalışma saatlerini getirir."""
    if not doctor_id:
        return {}
    
    try:
        supabase = get_supabase_client()
        result = supabase.table("doctors").select("working_hours").eq("id", doctor_id).single().execute()
        return result.data.get("working_hours", {}) if result.data else {}
    except:
        return {}


def get_holidays_for_month(year: int, month: int, doctor_id: str | None = None, request=None) -> list[dict]:
    """Belirli bir ay için tatilleri getirir."""
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id(request)
    
    query = supabase.table("holidays").select("*").eq("hospital_id", hospital_id)
    
    if doctor_id:
        query = query.eq("doctor_id", doctor_id)
    else:
        query = query.is_("doctor_id", "null")
    
    result = query.execute()
    
    if not result.data:
        return []
    
    holidays = []
    for holiday in result.data:
        h_date_str = holiday.get("date")
        if h_date_str:
            try:
                h_date = datetime.strptime(h_date_str, "%Y-%m-%d").date()
                if h_date.year == year and h_date.month == month:
                    # Format dönüştür
                    holidays.append({
                        "id": str(holiday.get("id", "")),
                        "hospitalId": str(holiday.get("hospital_id", "")),
                        "doctorId": str(holiday.get("doctor_id", "")) if holiday.get("doctor_id") else None,
                        "date": h_date_str,
                        "reason": holiday.get("reason", ""),
                        "isFullDay": holiday.get("is_full_day", True),
                        "startTime": holiday.get("start_time"),
                        "endTime": holiday.get("end_time"),
                    })
            except ValueError:
                continue
    
    return holidays


def build_calendar_data(year: int, month: int, selected_doctor_id: str | None = None, request=None) -> dict:
    """Takvim verilerini oluşturur."""
    first_day = date(year, month, 1)
    last_day = date(year, month, monthrange(year, month)[1])
    start_cal = first_day - timedelta(days=first_day.weekday())
    end_cal = last_day + timedelta(days=(6 - last_day.weekday()))
    
    weeks = []
    current = start_cal
    while current <= end_cal:
        week = []
        for _ in range(7):
            day_data = {
                "date": current,
                "is_current_month": current.month == month,
                "is_today": current == date.today(),
                "is_past": current < date.today(),
                "holidays": [],
                "hospital_hours": None,
                "doctor_hours": None,
            }
            weekday_name = _get_weekday_name(current.weekday())
            hospital_hours = get_hospital_working_hours(request).get(weekday_name, {})
            if hospital_hours.get("isAvailable"):
                day_data["hospital_hours"] = f"{hospital_hours.get('start')} - {hospital_hours.get('end')}"
            
            if selected_doctor_id:
                doctor_hours = get_doctor_working_hours(selected_doctor_id).get(weekday_name, {})
                if doctor_hours.get("isAvailable"):
                    day_data["doctor_hours"] = f"{doctor_hours.get('start')} - {doctor_hours.get('end')}"
            
            month_holidays = get_holidays_for_month(current.year, current.month, selected_doctor_id, request=request)
            day_holidays = [
                h for h in month_holidays 
                if datetime.strptime(h["date"], "%Y-%m-%d").date() == current
            ]
            day_data["holidays"] = day_holidays
            
            # Tüm gün tatil kontrolü
            has_full_day_holiday = any(
                h.get("isFullDay", True) for h in day_holidays
                if not h.get("doctorId")
            )
            day_data["has_full_day_holiday"] = has_full_day_holiday
            
            week.append(day_data)
            current += timedelta(days=1)
        weeks.append(week)
    
    return {
        "year": year,
        "month": month,
        "month_name": _get_month_name(month),
        "weeks": weeks,
        "selected_doctor_id": selected_doctor_id,
    }


def _get_weekday_name(weekday: int) -> str:
    names = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    return names[weekday]


def _get_month_name(month: int) -> str:
    names = [
        "", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ]
    return names[month]


def get_day_details(day_date: date, doctor_id: str | None = None, request=None) -> dict:
    """Belirli bir günün detaylarını getirir."""
    weekday_name = _get_weekday_name(day_date.weekday())
    hospital_hours = get_hospital_working_hours(request).get(weekday_name, {})
    doctor_hours = get_doctor_working_hours(doctor_id).get(weekday_name, {}) if doctor_id else {}
    
    # Tatilleri getir
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id(request)
    day_str = day_date.isoformat()
    
    query = supabase.table("holidays").select("*").eq("hospital_id", hospital_id).eq("date", day_str)
    
    if doctor_id:
        query = query.eq("doctor_id", doctor_id)
    else:
        query = query.is_("doctor_id", "null")
    
    result = query.execute()
    
    holidays = []
    if result.data:
        for holiday in result.data:
            if not doctor_id and not holiday.get("doctor_id"):
                holidays.append({
                    "id": str(holiday.get("id", "")),
                    "hospitalId": str(holiday.get("hospital_id", "")),
                    "doctorId": None,
                    "date": holiday.get("date", ""),
                    "reason": holiday.get("reason", ""),
                    "isFullDay": holiday.get("is_full_day", True),
                    "startTime": holiday.get("start_time"),
                    "endTime": holiday.get("end_time"),
                })
            elif doctor_id and str(holiday.get("doctor_id", "")) == doctor_id:
                holidays.append({
                    "id": str(holiday.get("id", "")),
                    "hospitalId": str(holiday.get("hospital_id", "")),
                    "doctorId": str(holiday.get("doctor_id", "")),
                    "date": holiday.get("date", ""),
                    "reason": holiday.get("reason", ""),
                    "isFullDay": holiday.get("is_full_day", True),
                    "startTime": holiday.get("start_time"),
                    "endTime": holiday.get("end_time"),
                })
    
    # Çalışan doktorları getir
    doctors_working = []
    if not doctor_id:
        doctors = get_doctors()
        for doctor in doctors:
            doc_hours = doctor.get("workingHours", {}).get(weekday_name, {})
            if doc_hours.get("isAvailable"):
                doctors_working.append({
                    "id": doctor["id"],
                    "name": f"{doctor['name']} {doctor['surname']}",
                    "hours": f"{doc_hours.get('start')} - {doc_hours.get('end')}",
                })
    
    return {
        "date": day_date,
        "hospital_hours": hospital_hours,
        "doctor_hours": doctor_hours if doctor_id else None,
        "holidays": holidays,
        "doctors_working": doctors_working,
    }
