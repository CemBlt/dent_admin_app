from __future__ import annotations

import os
import uuid
from copy import deepcopy
from datetime import datetime
from pathlib import Path

from django.conf import settings
from django.core.files.storage import FileSystemStorage

from . import location_service
from .supabase_client import get_supabase_client

# Aktif hastane ID'si - İlk hastaneyi otomatik alır
def _get_active_hospital_id() -> str:
    """İlk hastanenin ID'sini döndürür."""
    supabase = get_supabase_client()
    result = supabase.table("hospitals").select("id").limit(1).execute()
    
    if not result.data:
        raise ValueError("Supabase'de hiç hastane bulunamadı. Lütfen önce bir hastane oluşturun.")
    
    return str(result.data[0]['id'])

UPLOAD_DIR = Path(settings.BASE_DIR, "panel", "static", "uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
upload_storage = FileSystemStorage(location=UPLOAD_DIR, base_url="/static/uploads/")


def get_hospital() -> dict:
    """Aktif hastaneyi Supabase'den getirir (ilk hastaneyi alır)."""
    supabase = get_supabase_client()
    result = supabase.table("hospitals").select("*").limit(1).execute()
    
    if not result.data:
        raise ValueError("Supabase'de hiç hastane bulunamadı. Lütfen önce bir hastane oluşturun.")
    
    hospital = result.data[0]
    # Supabase'den gelen veriyi mevcut format'a çevir
    return _format_hospital_from_db(hospital)


def save_hospital(updated: dict) -> None:
    """Hastane bilgilerini Supabase'e kaydeder."""
    supabase = get_supabase_client()
    # Veriyi Supabase formatına çevir
    db_data = _format_hospital_to_db(updated)
    hospital_id = updated.get("id") or _get_active_hospital_id()
    
    result = supabase.table("hospitals").update(db_data).eq("id", hospital_id).execute()
    
    if not result.data:
        raise ValueError("Hastane güncellenemedi")


def get_services() -> list[dict]:
    """Tüm hizmetleri Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("services").select("*").execute()
    return result.data if result.data else []


def get_holidays() -> list[dict]:
    """Aktif hastaneye ait tatilleri Supabase'den getirir."""
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id()
    result = supabase.table("holidays").select("*").eq("hospital_id", hospital_id).is_("doctor_id", "null").execute()
    
    if not result.data:
        return []
    
    # Supabase formatından mevcut formata çevir
    return [_format_holiday_from_db(h) for h in result.data]


def add_holiday(date_str: str, reason: str, is_full_day: bool = True, start_time: str | None = None, end_time: str | None = None) -> None:
    """Yeni tatil ekler."""
    from datetime import datetime, date
    
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id()
    payload = {
        "hospital_id": hospital_id,
        "doctor_id": None,
        "date": date_str,
        "reason": reason,
        "is_full_day": is_full_day,
        "start_time": start_time if not is_full_day else None,
        "end_time": end_time if not is_full_day else None,
    }
    
    result = supabase.table("holidays").insert(payload).execute()
    
    if not result.data:
        raise ValueError("Tatil eklenemedi")
    
    # Saatli tatil ise, o günün çalışma saatlerini tatil başlangıç saatine kadar kısalt
    if not is_full_day and start_time:
        holiday_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        weekday_names = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        weekday_name = weekday_names[holiday_date.weekday()]
        
        hospital = get_hospital()
        working_hours = hospital.get("workingHours", {})
        day_hours = working_hours.get(weekday_name, {})
        
        # Eğer o gün çalışma günü ise ve başlangıç saati varsa
        if day_hours.get("isAvailable") and day_hours.get("start"):
            # Çalışma saatlerini tatil başlangıç saatine kadar kısalt
            day_hours["end"] = start_time
            working_hours[weekday_name] = day_hours
            hospital["workingHours"] = working_hours
            save_hospital(hospital)


def delete_holiday(holiday_id: str) -> None:
    """Tatili siler."""
    supabase = get_supabase_client()
    result = supabase.table("holidays").delete().eq("id", holiday_id).execute()
    
    if not result.data:
        raise ValueError("Tatil bulunamadı veya silinemedi")


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


def _resolve_location_snapshot(province_id: str, district_id: str, neighborhood_id: str) -> dict:
    province = location_service.get_province(province_id)
    if not province:
        raise ValueError("Geçersiz il seçimi.")

    district = location_service.get_district(district_id)
    if not district or district["provinceId"] != province["id"]:
        raise ValueError("Geçersiz ilçe seçimi.")

    neighborhood = location_service.get_neighborhood(neighborhood_id)
    if not neighborhood or neighborhood["districtId"] != district["id"]:
        raise ValueError("Geçersiz mahalle seçimi.")

    return {
        "province": province,
        "district": district,
        "neighborhood": neighborhood,
    }


def update_general_info(hospital: dict, data: dict, logo_file=None) -> dict:
    hospital["name"] = data["name"]
    hospital["address"] = data.get("address", "")
    hospital["phone"] = data["phone"]
    hospital["email"] = data["email"]
    hospital["description"] = data.get("description", "")
    hospital["latitude"] = float(data["latitude"])
    hospital["longitude"] = float(data["longitude"])

    location_snapshot = _resolve_location_snapshot(
        data["province"],
        data["district"],
        data["neighborhood"],
    )
    hospital["provinceId"] = location_snapshot["province"]["id"]
    hospital["provinceName"] = location_snapshot["province"]["name"]
    hospital["districtId"] = location_snapshot["district"]["id"]
    hospital["districtName"] = location_snapshot["district"]["name"]
    hospital["neighborhoodId"] = location_snapshot["neighborhood"]["id"]
    hospital["neighborhoodName"] = location_snapshot["neighborhood"]["name"]

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
        
        # ChoiceField'den gelen değerler string olarak gelir
        # Eğer time objesi ise strftime kullan, string ise direkt kullan
        start_str = None
        if start:
            if hasattr(start, 'strftime'):
                start_str = start.strftime("%H:%M")
            elif isinstance(start, str):
                start_str = start
        
        end_str = None
        if end:
            if hasattr(end, 'strftime'):
                end_str = end.strftime("%H:%M")
            elif isinstance(end, str):
                end_str = end
        
        working_hours[key] = {
            "isAvailable": bool(is_open),
            "start": start_str,
            "end": end_str,
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


def _format_hospital_from_db(db_hospital: dict) -> dict:
    """Supabase'den gelen hastane verisini mevcut formata çevirir."""
    return {
        "id": str(db_hospital.get("id", "")),
        "name": db_hospital.get("name", ""),
        "address": db_hospital.get("address", ""),
        "latitude": float(db_hospital.get("latitude", 0)),
        "longitude": float(db_hospital.get("longitude", 0)),
        "phone": db_hospital.get("phone", ""),
        "email": db_hospital.get("email", ""),
        "description": db_hospital.get("description", ""),
        "image": db_hospital.get("image"),
        "gallery": db_hospital.get("gallery", []),
        "services": db_hospital.get("services", []),
        "workingHours": db_hospital.get("working_hours", {}),
        "createdAt": db_hospital.get("created_at", ""),
        "provinceId": db_hospital.get("province_id", ""),
        "provinceName": db_hospital.get("province_name", ""),
        "districtId": db_hospital.get("district_id", ""),
        "districtName": db_hospital.get("district_name", ""),
        "neighborhoodId": db_hospital.get("neighborhood_id", ""),
        "neighborhoodName": db_hospital.get("neighborhood_name", ""),
    }


def _format_hospital_to_db(hospital: dict) -> dict:
    """Hastane verisini Supabase formatına çevirir."""
    return {
        "name": hospital.get("name", ""),
        "address": hospital.get("address", ""),
        "latitude": float(hospital.get("latitude", 0)),
        "longitude": float(hospital.get("longitude", 0)),
        "phone": hospital.get("phone", ""),
        "email": hospital.get("email", ""),
        "description": hospital.get("description", ""),
        "image": hospital.get("image"),
        "gallery": hospital.get("gallery", []),
        "services": hospital.get("services", []),
        "working_hours": hospital.get("workingHours", {}),
        "province_id": hospital.get("provinceId", ""),
        "province_name": hospital.get("provinceName", ""),
        "district_id": hospital.get("districtId", ""),
        "district_name": hospital.get("districtName", ""),
        "neighborhood_id": hospital.get("neighborhoodId", ""),
        "neighborhood_name": hospital.get("neighborhoodName", ""),
    }


def _format_holiday_from_db(db_holiday: dict) -> dict:
    """Supabase'den gelen tatil verisini mevcut formata çevirir."""
    return {
        "id": str(db_holiday.get("id", "")),
        "hospitalId": str(db_holiday.get("hospital_id", "")),
        "doctorId": str(db_holiday.get("doctor_id", "")) if db_holiday.get("doctor_id") else None,
        "date": db_holiday.get("date", ""),
        "reason": db_holiday.get("reason", ""),
        "isFullDay": db_holiday.get("is_full_day", True),
        "startTime": db_holiday.get("start_time"),
        "endTime": db_holiday.get("end_time"),
    }

def get_hospitals() -> list[dict]:
    """Tüm hastaneleri Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("hospitals").select("*").execute()
    
    if not result.data:
        return []
    
    return [_format_hospital_from_db(h) for h in result.data]
