from __future__ import annotations

import os
import uuid
from copy import deepcopy
from datetime import datetime
from pathlib import Path

from django.conf import settings
from django.core.files.storage import FileSystemStorage

from .json_repository import (
    append_to_collection,
    load_json,
    save_json,
    update_collection,
)

ACTIVE_HOSPITAL_ID = "1"
UPLOAD_DIR = Path(settings.BASE_DIR, "panel", "static", "uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
upload_storage = FileSystemStorage(location=UPLOAD_DIR, base_url="/static/uploads/")


def get_hospital() -> dict:
    hospitals = load_json("hospitals")
    for hospital in hospitals:
        if hospital["id"] == ACTIVE_HOSPITAL_ID:
            return deepcopy(hospital)
    raise ValueError("Aktif hastane bulunamadı")


def save_hospital(updated: dict) -> None:
    update_collection(
        "hospitals",
        lambda h: h["id"] == ACTIVE_HOSPITAL_ID,
        lambda _: updated,
    )


def get_services() -> list[dict]:
    return load_json("services")


def get_holidays() -> list[dict]:
    return [
        holiday
        for holiday in load_json("holidays")
        if holiday["hospitalId"] == ACTIVE_HOSPITAL_ID
    ]


def add_holiday(date_str: str, reason: str) -> None:
    existing = load_json("holidays")
    new_id = str(max((int(item["id"]) for item in existing), default=0) + 1)
    payload = {
        "id": new_id,
        "hospitalId": ACTIVE_HOSPITAL_ID,
        "doctorId": None,
        "date": date_str,
        "reason": reason,
    }
    append_to_collection("holidays", payload)


def delete_holiday(holiday_id: str) -> None:
    holidays = load_json("holidays")
    updated = [h for h in holidays if h["id"] != holiday_id]
    save_json("holidays", updated)


def save_logo(file) -> str:
    filename = f"logo_{uuid.uuid4().hex}{Path(file.name).suffix}"
    return upload_storage.save(filename, file)


def save_gallery_image(file) -> str:
    filename = f"gallery_{uuid.uuid4().hex}{Path(file.name).suffix}"
    return upload_storage.save(filename, file)


def delete_file_if_exists(relative_path: str) -> None:
    if not relative_path:
        return
    abs_path = UPLOAD_DIR / Path(relative_path).name
    if abs_path.exists() and abs_path.is_file():
        try:
            os.remove(abs_path)
        except OSError:
            pass


def update_general_info(hospital: dict, data: dict, logo_file=None) -> dict:
    hospital["name"] = data["name"]
    hospital["address"] = data["address"]
    hospital["phone"] = data["phone"]
    hospital["email"] = data["email"]
    hospital["description"] = data.get("description", "")

    if logo_file:
        delete_file_if_exists(hospital.get("image"))
        saved_path = save_logo(logo_file)
        hospital["image"] = f"uploads/{Path(saved_path).name}"

    save_hospital(hospital)
    return hospital


def update_services(hospital: dict, service_ids: list[str]) -> dict:
    hospital["services"] = service_ids
    save_hospital(hospital)
    return hospital


def update_working_hours(hospital: dict, working_hours: dict) -> dict:
    hospital["workingHours"] = working_hours
    save_hospital(hospital)
    return hospital


def add_gallery_image(hospital: dict, file) -> dict:
    saved_path = save_gallery_image(file)
    gallery = hospital.get("gallery", [])
    if len(gallery) >= 5:
        raise ValueError("Maksimum 5 görsel eklenebilir")
    gallery.append(f"uploads/{Path(saved_path).name}")
    hospital["gallery"] = gallery
    save_hospital(hospital)
    return hospital


def remove_gallery_image(hospital: dict, index: int) -> dict:
    gallery = hospital.get("gallery", [])
    if 0 <= index < len(gallery):
        delete_file_if_exists(gallery[index])
        gallery.pop(index)
        hospital["gallery"] = gallery
        save_hospital(hospital)
    return hospital


def build_working_hours_from_form(cleaned_data: dict) -> dict:
    working_hours = {}
    from panel.forms import DAYS

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


def build_initial_working_hours(hospital: dict) -> dict:
    initial = {}
    working_hours = hospital.get("workingHours", {})
    for key, value in working_hours.items():
        initial[f"{key}_is_open"] = value.get("isAvailable")
        start = value.get("start")
        end = value.get("end")
        initial[f"{key}_start"] = datetime.strptime(start, "%H:%M").time() if start else None
        initial[f"{key}_end"] = datetime.strptime(end, "%H:%M").time() if end else None
    return initial

def get_hospitals() -> list[dict]:
    return load_json("hospitals")
