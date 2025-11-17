from __future__ import annotations

from datetime import datetime
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
