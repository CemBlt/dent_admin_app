from __future__ import annotations

import uuid
from datetime import datetime
from pathlib import Path

from .supabase_client import get_supabase_client
from .hospital_service import _get_active_hospital_id, get_hospital


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
    """Doktor görselini 300x300px'e resize edip Supabase Storage'a yükler ve public URL döndürür."""
    if not file:
        return None
    
    try:
        from PIL import Image
        from io import BytesIO
    except ImportError:
        raise ValueError(
            "Görsel işleme için Pillow kütüphanesi gerekli. "
            "Lütfen 'pip install Pillow' komutu ile yükleyin."
        )
    
    supabase = get_supabase_client()
    
    # Dosya adını güvenli şekilde al
    original_filename = getattr(file, 'name', 'doctor.jpg')
    if not original_filename or original_filename == '':
        original_filename = 'doctor.jpg'
    
    # Her zaman .jpg olarak kaydet (resize sonrası)
    filename = f"doctors/doctor_{uuid.uuid4().hex}.jpg"
    content_type = 'image/jpeg'
    
    # Supabase Storage'a yükle (public bucket)
    try:
        file.seek(0)  # Dosyayı başa al
        
        # Görseli aç ve resize et
        image = Image.open(file)
        # RGBA modundaysa RGB'ye çevir (JPEG RGBA desteklemez)
        if image.mode in ('RGBA', 'LA', 'P'):
            # Transparent arka planı beyaz yap
            rgb_image = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            rgb_image.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
            image = rgb_image
        elif image.mode != 'RGB':
            image = image.convert('RGB')
        
        # 300x300px'e resize et (thumbnail kullanarak aspect ratio korunur, sonra crop)
        image.thumbnail((300, 300), Image.Resampling.LANCZOS)
        
        # Kare yapmak için crop (ortadan)
        width, height = image.size
        if width != height:
            size = min(width, height)
            left = (width - size) // 2
            top = (height - size) // 2
            image = image.crop((left, top, left + size, top + size))
        
        # 300x300px'e resize et
        image = image.resize((300, 300), Image.Resampling.LANCZOS)
        
        # Bytes'a çevir
        output = BytesIO()
        image.save(output, format='JPEG', quality=85, optimize=True)
        file_bytes = output.getvalue()
        
        result = supabase.storage.from_("hospital-media").upload(
            path=filename,
            file=file_bytes,
            file_options={"content-type": content_type}
        )
        
        # Public URL'yi al
        public_url = supabase.storage.from_("hospital-media").get_public_url(filename)
        return public_url
    except Exception as upload_error:
        error_msg = str(upload_error)
        # Bucket yoksa kullanıcıya bilgi ver
        if "bucket" in error_msg.lower() or "not found" in error_msg.lower():
            raise ValueError(
                "Doktor görseli yüklenemedi: 'hospital-media' bucket'ı bulunamadı. "
                "Lütfen Supabase Dashboard > Storage > New Bucket'dan 'hospital-media' adında "
                "public bir bucket oluşturun."
            )
        raise ValueError(f"Doktor görseli yüklenemedi: {error_msg}")


def add_doctor(data: dict, image_file=None, request=None) -> dict:
    """Yeni doktor ekler."""
    supabase = get_supabase_client()
    
    hospital_id = _get_active_hospital_id(request)
    working_hours = _build_default_working_hours(request)
    doctor_data = {
        "hospital_id": hospital_id,
        "name": data["name"],
        "surname": data["surname"],
        "bio": data.get("bio", ""),
        "services": list(data.get("services", [])),
        "working_hours": working_hours,
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


def _build_default_working_hours(request=None) -> dict:
    """Hastane çalışma saatlerinden varsayılan doktor çalışma saatlerini oluşturur."""
    try:
        hospital = get_hospital(request)
        hospital_hours = hospital.get("workingHours", {}) or {}
    except ValueError:
        hospital_hours = {}

    from panel.forms import DAYS

    default_hours = {}
    for key, _ in DAYS:
        day_info = hospital_hours.get(key, {}) or {}
        default_hours[key] = {
            "isAvailable": bool(day_info.get("isAvailable")),
            "start": day_info.get("start"),
            "end": day_info.get("end"),
        }

    # Eğer hastane çalışma saatleri boşsa tamamen kapalı template döner
    if not any(slot.get("isAvailable") for slot in default_hours.values()):
        return _default_working_hours()
    return default_hours


def _delete_file(file_url_or_path: str | None) -> None:
    """Supabase Storage'dan veya yerel dosya sisteminden dosyayı siler."""
    if not file_url_or_path:
        return
    
    # Eğer URL ise (Supabase Storage'dan), storage'dan sil
    if file_url_or_path.startswith("http"):
        try:
            supabase = get_supabase_client()
            # URL'den dosya yolunu çıkar
            # Örnek: https://xxx.supabase.co/storage/v1/object/public/hospital-media/doctors/doctor_xxx.jpg
            # -> doctors/doctor_xxx.jpg
            if "/hospital-media/" in file_url_or_path:
                file_path = file_url_or_path.split("/hospital-media/")[-1]
                supabase.storage.from_("hospital-media").remove([file_path])
        except Exception:
            pass
    else:
        # Eski yerel dosya sistemi için (geriye dönük uyumluluk)
        from django.conf import settings
        from pathlib import Path
        abs_path = Path(settings.BASE_DIR, "panel", "static", "uploads", "doctors", Path(file_url_or_path).name)
        if abs_path.exists() and abs_path.is_file():
            try:
                import os
                os.remove(abs_path)
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
