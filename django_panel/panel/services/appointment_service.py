from __future__ import annotations

from datetime import datetime, date, time
from typing import List

from .json_repository import load_json, save_json


def get_appointments() -> List[dict]:
    return load_json("appointments")


def filter_appointments(status=None, doctor_id=None, service_id=None, start_date=None, end_date=None):
    appointments = get_appointments()
    result = []
    for apt in appointments:
        if status and apt["status"] != status:
            continue
        if doctor_id and apt["doctorId"] != doctor_id:
            continue
        if service_id and apt["service"] != service_id:
            continue
        apt_date = datetime.strptime(apt["date"], "%Y-%m-%d").date()
        if start_date and apt_date < start_date:
            continue
        if end_date and apt_date > end_date:
            continue
        result.append(apt)
    return result


def update_appointment(appointment_id: str, **changes):
    appointments = get_appointments()
    for idx, apt in enumerate(appointments):
        if apt["id"] == appointment_id:
            appointments[idx] = {**apt, **changes}
            save_json("appointments", appointments)
            return appointments[idx]
    raise ValueError("Randevu bulunamadı")


def delete_appointment(appointment_id: str):
    appointments = get_appointments()
    filtered = [apt for apt in appointments if apt["id"] != appointment_id]
    save_json("appointments", filtered)


def get_summary():
    appointments = get_appointments()
    stats = {
        "pending": sum(1 for apt in appointments if apt["status"] == "pending"),
        "completed": sum(1 for apt in appointments if apt["status"] == "completed"),
        "cancelled": sum(1 for apt in appointments if apt["status"] == "cancelled"),
    }
    today = datetime.now().date()
    stats["today"] = sum(1 for apt in appointments if apt["date"] == today.isoformat())
    return stats


def is_appointment_time_blocked(appointment_date: date, appointment_time: str, hospital_id: str = "1") -> bool:
    """
    Belirli bir tarih ve saatte randevu alınıp alınamayacağını kontrol eder.
    Tüm gün tatillerde True döner (randevu alınamaz).
    Saatli tatillerde sadece tatil saatleri içinde True döner.
    """
    holidays = load_json("holidays")
    appointment_date_str = appointment_date.isoformat()
    
    # Randevu saatini time objesine çevir
    try:
        apt_time = datetime.strptime(appointment_time, "%H:%M").time()
    except (ValueError, TypeError):
        return False
    
    for holiday in holidays:
        if holiday.get("hospitalId") != hospital_id:
            continue
        if holiday.get("doctorId"):  # Doktor tatillerini atla, sadece hastane tatilleri
            continue
        if holiday.get("date") != appointment_date_str:
            continue
        
        # Tüm gün tatil
        if holiday.get("isFullDay", True):
            return True
        
        # Saatli tatil kontrolü
        start_time_str = holiday.get("startTime")
        end_time_str = holiday.get("endTime")
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
