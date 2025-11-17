from __future__ import annotations

import os
import uuid
from datetime import datetime
from pathlib import Path

from django.conf import settings
from django.core.files.storage import FileSystemStorage

from .json_repository import load_json, save_json

ACTIVE_HOSPITAL_ID = "1"
UPLOAD_ROOT = Path(settings.BASE_DIR, "panel", "static", "uploads", "doctors")
UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
storage = FileSystemStorage(location=UPLOAD_ROOT, base_url="/static/uploads/doctors/")


def _load_doctors() -> list[dict]:
    return load_json("doctors")


def _persist(doctors: list[dict]) -> None:
    save_json("doctors", doctors)


def get_doctors() -> list[dict]:
    return [doc for doc in _load_doctors() if doc["hospitalId"] == ACTIVE_HOSPITAL_ID]


def _generate_id(doctors: list[dict]) -> str:
    return str(max((int(doc["id"]) for doc in doctors), default=0) + 1)


def _save_image(file) -> str | None:
    if not file:
        return None
    filename = f"doctor_{uuid.uuid4().hex}{Path(file.name).suffix}"
    saved = storage.save(filename, file)
    return f"uploads/doctors/{Path(saved).name}"


def add_doctor(data: dict, image_file=None) -> dict:
    doctors = _load_doctors()
    new_id = _generate_id(doctors)
    doctor = {
        "id": new_id,
        "hospitalId": ACTIVE_HOSPITAL_ID,
        "name": data["name"],
        "surname": data["surname"],
        "specialty": data["specialty"],
        "bio": data.get("bio", ""),
        "services": list(data.get("services", [])),
        "workingHours": _default_working_hours(),
        "image": _save_image(image_file),
        "isActive": data.get("is_active", True),
        "createdAt": datetime.utcnow().isoformat(),
    }
    doctors.append(doctor)
    _persist(doctors)
    return doctor


def update_doctor(doctor_id: str, data: dict, image_file=None) -> dict:
    doctors = _load_doctors()
    for idx, doctor in enumerate(doctors):
        if doctor["id"] == doctor_id:
            doctor["name"] = data["name"]
            doctor["surname"] = data["surname"]
            doctor["specialty"] = data["specialty"]
            doctor["bio"] = data.get("bio", "")
            doctor["services"] = list(data.get("services", []))
            doctor["isActive"] = data.get("is_active", False)
            if image_file:
                _delete_file(doctor.get("image"))
                doctor["image"] = _save_image(image_file)
            doctors[idx] = doctor
            _persist(doctors)
            return doctor
    raise ValueError("Doktor bulunamadı")


def delete_doctor(doctor_id: str) -> None:
    doctors = _load_doctors()
    updated = []
    removed_image = None
    for doctor in doctors:
        if doctor["id"] == doctor_id:
            removed_image = doctor.get("image")
        else:
            updated.append(doctor)
    _persist(updated)
    _delete_file(removed_image)
    _delete_doctor_holidays(doctor_id)


def update_working_hours(doctor_id: str, working_hours: dict) -> None:
    doctors = _load_doctors()
    for idx, doctor in enumerate(doctors):
        if doctor["id"] == doctor_id:
            doctor["workingHours"] = working_hours
            doctors[idx] = doctor
            _persist(doctors)
            return
    raise ValueError("Doktor bulunamadı")


def build_initial_working_hours(doctor: dict) -> dict:
    from panel.forms import DAYS

    initial = {"doctor_id": doctor.get("id")}
    hours = doctor.get("workingHours", {})
    for day, _ in DAYS:
        info = hours.get(day, {})
        initial[f"{day}_is_open"] = info.get("isAvailable")
        start = info.get("start")
        end = info.get("end")
        initial[f"{day}_start"] = datetime.strptime(start, "%H:%M").time() if start else None
        initial[f"{day}_end"] = datetime.strptime(end, "%H:%M").time() if end else None
    return initial


def build_working_hours_from_form(cleaned_data: dict) -> dict:
    from panel.forms import DAYS

    working_hours = {}
    for key, _ in DAYS:
        is_open = cleaned_data.get(f"{key}_is_open")
        start = cleaned_data.get(f"{key}_start")
        end = cleaned_data.get(f"{key}_end")
        working_hours[key] = {
            "isAvailable": bool(is_open),
            "start": start.strftime("%H:%M") if start else None,
            "end": end.strftime("%H:%M") if end else None,
        }
    return working_hours


def get_doctor_holidays() -> dict[str, list[dict]]:
    holidays = load_json("holidays")
    result: dict[str, list[dict]] = {}
    for holiday in holidays:
        doctor_id = holiday.get("doctorId")
        if doctor_id:
            result.setdefault(doctor_id, []).append(holiday)
    return result


def add_doctor_holiday(doctor_id: str, date_str: str, reason: str) -> None:
    holidays = load_json("holidays")
    new_id = str(max((int(item["id"]) for item in holidays), default=0) + 1)
    holidays.append({
        "id": new_id,
        "hospitalId": ACTIVE_HOSPITAL_ID,
        "doctorId": doctor_id,
        "date": date_str,
        "reason": reason,
    })
    save_json("holidays", holidays)


def delete_doctor_holiday(holiday_id: str) -> None:
    holidays = load_json("holidays")
    updated = [h for h in holidays if str(h["id"]) != str(holiday_id)]
    save_json("holidays", updated)


def toggle_active(doctor_id: str, is_active: bool) -> None:
    doctors = _load_doctors()
    for doctor in doctors:
        if doctor["id"] == doctor_id:
            doctor["isActive"] = is_active
            break
    _persist(doctors)


def _default_working_hours() -> dict:
    from panel.forms import DAYS

    return {
        key: {"isAvailable": False, "start": None, "end": None}
        for key, _ in DAYS
    }


def _delete_file(relative_path: str | None) -> None:
    if not relative_path:
        return
    path = Path(settings.BASE_DIR, "panel", "static", relative_path)
    if path.exists():
        try:
            os.remove(path)
        except OSError:
            pass


def _delete_doctor_holidays(doctor_id: str) -> None:
    holidays = load_json("holidays")
    updated = [h for h in holidays if h.get("doctorId") != doctor_id]
    save_json("holidays", updated)
