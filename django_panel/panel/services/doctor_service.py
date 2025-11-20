from __future__ import annotations

import os
import uuid
from datetime import datetime
from pathlib import Path

from django.conf import settings
from django.core.files.storage import FileSystemStorage

from .supabase_client import get_supabase_client

from .hospital_service import _get_active_hospital_id
UPLOAD_ROOT = Path(settings.BASE_DIR, "panel", "static", "uploads", "doctors")
UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
storage = FileSystemStorage(location=UPLOAD_ROOT, base_url="/static/uploads/doctors/")


def get_doctors(request=None) -> list[dict]:
    """Aktif hastaneye ait doktorları Supabase'den getirir."""
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id(request)
    result = supabase.table("doctors").select("*").eq("hospital_id", hospital_id).execute()
    
    if not result.data:
        return []
    
    return [_format_doctor_from_db(d) for d in result.data]


# ID generation artık Supabase tarafından yapılıyor (UUID)


def _save_image(file) -> str | None:
    if not file:
        return None
    filename = f"doctor_{uuid.uuid4().hex}{Path(file.name).suffix}"
    saved = storage.save(filename, file)
    return f"uploads/doctors/{Path(saved).name}"


def add_doctor(data: dict, image_file=None, request=None) -> dict:
    """Yeni doktor ekler."""
    supabase = get_supabase_client()
    
    hospital_id = _get_active_hospital_id(request)
    doctor_data = {
        "hospital_id": hospital_id,
        "name": data["name"],
        "surname": data["surname"],
        "specialty": data["specialty"],
        "bio": data.get("bio", ""),
        "services": list(data.get("services", [])),
        "working_hours": _default_working_hours(),
        "image": _save_image(image_file),
        "is_active": data.get("is_active", True),
    }
    
    result = supabase.table("doctors").insert(doctor_data).execute()
    
    if not result.data:
        raise ValueError("Doktor eklenemedi")
    
    return _format_doctor_from_db(result.data[0])


def update_doctor(doctor_id: str, data: dict, image_file=None) -> dict:
    """Doktor bilgilerini günceller."""
    supabase = get_supabase_client()
    
    update_data = {
        "name": data["name"],
        "surname": data["surname"],
        "specialty": data["specialty"],
        "bio": data.get("bio", ""),
        "services": list(data.get("services", [])),
        "is_active": data.get("is_active", False),
    }
    
    if image_file:
        # Eski resmi sil
        old_doctor_result = supabase.table("doctors").select("image").eq("id", doctor_id).execute()
        if old_doctor_result.data and old_doctor_result.data[0].get("image"):
            _delete_file(old_doctor_result.data[0]["image"])
        
        update_data["image"] = _save_image(image_file)
    
    result = supabase.table("doctors").update(update_data).eq("id", doctor_id).execute()
    
    if not result.data:
        raise ValueError("Doktor bulunamadı veya güncellenemedi")
    
    return _format_doctor_from_db(result.data[0])


def delete_doctor(doctor_id: str) -> None:
    """Doktoru siler."""
    supabase = get_supabase_client()
    
    # Önce resmi al
    doctor_result = supabase.table("doctors").select("image").eq("id", doctor_id).execute()
    if doctor_result.data and doctor_result.data[0].get("image"):
        _delete_file(doctor_result.data[0]["image"])
    
    # Doktor tatillerini sil
    _delete_doctor_holidays(doctor_id)
    
    # Doktoru sil
    result = supabase.table("doctors").delete().eq("id", doctor_id).execute()
    
    if not result.data:
        raise ValueError("Doktor bulunamadı veya silinemedi")


def update_working_hours(doctor_id: str, working_hours: dict) -> None:
    """Doktor çalışma saatlerini günceller."""
    supabase = get_supabase_client()
    result = supabase.table("doctors").update({"working_hours": working_hours}).eq("id", doctor_id).execute()
    
    if not result.data:
        raise ValueError("Doktor bulunamadı veya güncellenemedi")


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


def get_doctor_holidays(request=None) -> dict[str, list[dict]]:
    """Doktor tatillerini getirir."""
    supabase = get_supabase_client()
    query = supabase.table("holidays").select("*").not_.is_("doctor_id", "null")
    try:
        hospital_id = _get_active_hospital_id(request)
        query = query.eq("hospital_id", hospital_id)
    except ValueError:
        pass
    result = query.execute()
    
    holidays_dict: dict[str, list[dict]] = {}
    if result.data:
        for holiday in result.data:
            doctor_id = str(holiday.get("doctor_id", ""))
            if doctor_id:
                formatted_holiday = _format_holiday_from_db(holiday)
                holidays_dict.setdefault(doctor_id, []).append(formatted_holiday)
    
    return holidays_dict


def add_doctor_holiday(doctor_id: str, date_str: str, reason: str, request=None) -> None:
    """Doktor tatili ekler."""
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id(request)
    payload = {
        "hospital_id": hospital_id,
        "doctor_id": doctor_id,
        "date": date_str,
        "reason": reason,
        "is_full_day": True,
    }
    
    result = supabase.table("holidays").insert(payload).execute()
    
    if not result.data:
        raise ValueError("Doktor tatili eklenemedi")


def delete_doctor_holiday(holiday_id: str) -> None:
    """Doktor tatilini siler."""
    supabase = get_supabase_client()
    result = supabase.table("holidays").delete().eq("id", holiday_id).execute()
    
    if not result.data:
        raise ValueError("Tatil bulunamadı veya silinemedi")


def toggle_active(doctor_id: str, is_active: bool) -> None:
    """Doktor aktif/pasif durumunu değiştirir."""
    supabase = get_supabase_client()
    result = supabase.table("doctors").update({"is_active": is_active}).eq("id", doctor_id).execute()
    
    if not result.data:
        raise ValueError("Doktor bulunamadı veya güncellenemedi")


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
    """Doktorun tüm tatillerini siler."""
    supabase = get_supabase_client()
    supabase.table("holidays").delete().eq("doctor_id", doctor_id).execute()


def _format_doctor_from_db(db_doctor: dict) -> dict:
    """Supabase'den gelen doktor verisini mevcut formata çevirir."""
    return {
        "id": str(db_doctor.get("id", "")),
        "hospitalId": str(db_doctor.get("hospital_id", "")),
        "name": db_doctor.get("name", ""),
        "surname": db_doctor.get("surname", ""),
        "specialty": db_doctor.get("specialty", ""),
        "image": db_doctor.get("image"),
        "bio": db_doctor.get("bio", ""),
        "workingHours": db_doctor.get("working_hours", {}),
        "isActive": db_doctor.get("is_active", True),
        "services": db_doctor.get("services", []),
        "createdAt": db_doctor.get("created_at", ""),
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
