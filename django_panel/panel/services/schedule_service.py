from __future__ import annotations

from calendar import monthrange
from datetime import date, datetime, timedelta

from .json_repository import load_json, save_json

ACTIVE_HOSPITAL_ID = "1"


def get_hospital_working_hours() -> dict:
    hospitals = load_json("hospitals")
    hospital = next((h for h in hospitals if h["id"] == ACTIVE_HOSPITAL_ID), None)
    return hospital.get("workingHours", {}) if hospital else {}


def get_doctor_working_hours(doctor_id: str | None = None) -> dict:
    doctors = load_json("doctors")
    if doctor_id:
        doctor = next((d for d in doctors if d["id"] == doctor_id), None)
        return doctor.get("workingHours", {}) if doctor else {}
    return {}


def get_holidays_for_month(year: int, month: int, doctor_id: str | None = None) -> list[dict]:
    holidays = load_json("holidays")
    result = []
    for holiday in holidays:
        if holiday.get("hospitalId") != ACTIVE_HOSPITAL_ID:
            continue
        if doctor_id and holiday.get("doctorId") != doctor_id:
            continue
        if not doctor_id and holiday.get("doctorId"):
            continue
        h_date = datetime.strptime(holiday["date"], "%Y-%m-%d").date()
        if h_date.year == year and h_date.month == month:
            result.append(holiday)
    return result


def build_calendar_data(year: int, month: int, selected_doctor_id: str | None = None) -> dict:
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
            hospital_hours = get_hospital_working_hours().get(weekday_name, {})
            if hospital_hours.get("isAvailable"):
                day_data["hospital_hours"] = f"{hospital_hours.get('start')} - {hospital_hours.get('end')}"
            
            if selected_doctor_id:
                doctor_hours = get_doctor_working_hours(selected_doctor_id).get(weekday_name, {})
                if doctor_hours.get("isAvailable"):
                    day_data["doctor_hours"] = f"{doctor_hours.get('start')} - {doctor_hours.get('end')}"
            
            month_holidays = get_holidays_for_month(current.year, current.month, selected_doctor_id)
            day_holidays = [h for h in month_holidays if datetime.strptime(h["date"], "%Y-%m-%d").date() == current]
            day_data["holidays"] = day_holidays
            
            # Tüm gün tatil kontrolü - eğer o günde tüm gün tatil varsa çalışma saatlerini iptal et
            # Sadece hastane tatilleri kontrol et (doctorId olmayanlar)
            has_full_day_holiday = any(
                h.get("isFullDay", True) for h in day_holidays
                if not h.get("doctorId")  # Sadece hastane tatilleri
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


def get_day_details(day_date: date, doctor_id: str | None = None) -> dict:
    weekday_name = _get_weekday_name(day_date.weekday())
    hospital_hours = get_hospital_working_hours().get(weekday_name, {})
    doctor_hours = get_doctor_working_hours(doctor_id).get(weekday_name, {}) if doctor_id else {}
    
    holidays = []
    all_holidays = load_json("holidays")
    for holiday in all_holidays:
        if holiday.get("hospitalId") != ACTIVE_HOSPITAL_ID:
            continue
        h_date = datetime.strptime(holiday["date"], "%Y-%m-%d").date()
        if h_date == day_date:
            if not doctor_id and not holiday.get("doctorId"):
                holidays.append(holiday)
            elif doctor_id and holiday.get("doctorId") == doctor_id:
                holidays.append(holiday)
    
    doctors_working = []
    if not doctor_id:
        doctors = load_json("doctors")
        for doctor in doctors:
            if doctor.get("hospitalId") != ACTIVE_HOSPITAL_ID:
                continue
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
