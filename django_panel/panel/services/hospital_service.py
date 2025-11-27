from __future__ import annotations

import mimetypes
import os
import uuid
from datetime import datetime
from pathlib import Path

from django.conf import settings

from . import location_service
from .supabase_client import get_supabase_client

REQUIRED_LOGO_WIDTH = 400
REQUIRED_LOGO_HEIGHT = 300
ALLOWED_LOGO_EXTENSIONS = ('.jpg', '.jpeg', '.png')

# Aktif hastane ID'si - Session'dan veya ilk hastaneyi alır
def _get_active_hospital_id(request=None) -> str:
    """Session'dan veya ilk hastanenin ID'sini döndürür."""
    # Eğer request varsa ve session'da hospital_id varsa onu kullan
    if request and hasattr(request, 'session') and request.session.get('hospital_id'):
        return request.session.get('hospital_id')
    
    # Fallback: İlk hastaneyi al (sadece login olmadan erişim için)
    supabase = get_supabase_client()
    result = supabase.table("hospitals").select("id").limit(1).execute()
    
    if not result.data or len(result.data) == 0:
        raise ValueError("Supabase'de hiç hastane bulunamadı. Lütfen önce bir hastane oluşturun.")
    
    return str(result.data[0]['id'])

# UPLOAD_DIR artık sadece geriye dönük uyumluluk için delete_file_if_exists içinde kullanılıyor
UPLOAD_DIR = Path(settings.BASE_DIR, "panel", "static", "uploads")


def get_hospital(request=None) -> dict:
    """Aktif hastaneyi Supabase'den getirir (session'dan veya ilk hastaneyi alır)."""
    try:
        supabase = get_supabase_client()
        hospital_id = _get_active_hospital_id(request)

        result = supabase.table("hospitals").select("*").eq("id", hospital_id).single().execute()
        data = result.data

        if isinstance(data, dict):
            hospital = data
        elif isinstance(data, list) and data:
            hospital = data[0]
        else:
            raise ValueError("Supabase'den hastane verisi alınamadı.")

        return _format_hospital_from_db(hospital)
    except Exception as exc:
        raise ValueError(f"Hastane bulunamadı: {exc}") from exc


def save_hospital(updated: dict, request=None) -> None:
    """Hastane bilgilerini Supabase'e kaydeder."""
    supabase = get_supabase_client()
    # Veriyi Supabase formatına çevir
    db_data = _format_hospital_to_db(updated)
    hospital_id = updated.get("id") or _get_active_hospital_id(request)
    
    result = supabase.table("hospitals").update(db_data).eq("id", hospital_id).execute()
    
    if not result.data:
        raise ValueError("Hastane güncellenemedi")


def get_services() -> list[dict]:
    """Tüm hizmetleri Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("services").select("*").execute()
    return result.data if result.data else []


def get_holidays(request=None) -> list[dict]:
    """Aktif hastaneye ait tatilleri Supabase'den getirir."""
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id(request)
    result = supabase.table("holidays").select("*").eq("hospital_id", hospital_id).is_("doctor_id", "null").execute()
    
    if not result.data:
        return []
    
    # Supabase formatından mevcut formata çevir
    return [_format_holiday_from_db(h) for h in result.data]


def add_holiday(date_str: str, reason: str, is_full_day: bool = True, start_time: str | None = None, end_time: str | None = None, request=None) -> None:
    """Yeni tatil ekler."""
    from datetime import datetime, date
    
    supabase = get_supabase_client()
    hospital_id = _get_active_hospital_id(request)
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
        
        hospital = get_hospital(request)
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
    f"""
    Hastane logosunu Supabase Storage'a yükler.
    Görselin {REQUIRED_LOGO_WIDTH}x{REQUIRED_LOGO_HEIGHT}px ölçülerinde olması zorunludur.
    """
    try:
        from PIL import Image
    except ImportError:
        raise ValueError(
            "Görsel işleme için Pillow kütüphanesi gerekli. "
            "Lütfen 'pip install Pillow' komutu ile yükleyin."
        )

    supabase = get_supabase_client()

    original_name = getattr(file, "name", "") or "logo.jpg"
    extension = os.path.splitext(original_name)[1].lower()
    if extension not in ALLOWED_LOGO_EXTENSIONS:
        extension = ".jpg"

    filename = f"logos/logo_{uuid.uuid4().hex}{extension}"
    content_type = getattr(file, "content_type", None) or mimetypes.types_map.get(extension, "image/jpeg")

    try:
        if hasattr(file, "seek"):
            file.seek(0)

        image = Image.open(file)
        image.load()
        width, height = image.size

        if width != REQUIRED_LOGO_WIDTH or height != REQUIRED_LOGO_HEIGHT:
            raise ValueError(
                f"Logo {REQUIRED_LOGO_WIDTH}x{REQUIRED_LOGO_HEIGHT}px olmalıdır. "
                "Lütfen bu ölçülerde bir görsel yükleyin."
            )

        if hasattr(file, "seek"):
            file.seek(0)
        file_bytes = file.read()

        supabase.storage.from_("hospital-media").upload(
            path=filename,
            file=file_bytes,
            file_options={"content-type": content_type},
        )

        return supabase.storage.from_("hospital-media").get_public_url(filename)
    except ValueError:
        raise
    except Exception as upload_error:
        error_msg = str(upload_error)
        error_type = type(upload_error).__name__

        if "bucket" in error_msg.lower() or "not found" in error_msg.lower():
            raise ValueError(
                "Logo yüklenemedi: 'hospital-media' bucket'ı bulunamadı. "
                "Lütfen Supabase Dashboard > Storage > New Bucket'dan 'hospital-media' adında "
                "public bir bucket oluşturun."
            )

        if "cannot identify image" in error_msg.lower() or "cannot open" in error_msg.lower():
            raise ValueError(
                f"Logo yüklenemedi: Geçersiz görsel dosyası. "
                f"Lütfen {REQUIRED_LOGO_WIDTH}x{REQUIRED_LOGO_HEIGHT}px boyutunda JPG veya PNG yükleyin. "
                f"Hata: {error_msg}"
            )

        raise ValueError(f"Logo yüklenemedi ({error_type}): {error_msg}")


def save_gallery_image(file) -> str:
    """Galeri görselini Supabase Storage'a yükler ve public URL döndürür."""
    supabase = get_supabase_client()
    
    # Dosya adını güvenli şekilde al
    original_filename = getattr(file, 'name', 'gallery.jpg')
    if not original_filename or original_filename == '':
        original_filename = 'gallery.jpg'
    
    file_extension = Path(original_filename).suffix if original_filename else '.jpg'
    if not file_extension:
        file_extension = '.jpg'
    
    filename = f"gallery/gallery_{uuid.uuid4().hex}{file_extension}"
    
    # Content type'ı belirle
    content_type = getattr(file, 'content_type', None) or 'image/jpeg'
    
    # Supabase Storage'a yükle (public bucket)
    # Dosyayı bytes'a çevir
    try:
        file.seek(0)  # Dosyayı başa al
        file_bytes = file.read()  # Bytes'a çevir
        file.seek(0)  # Tekrar başa al (ileride kullanılabilir)
        
        result = supabase.storage.from_("hospital-media").upload(
            path=filename,
            file=file_bytes,  # Bytes olarak gönder
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
                "Galeri görseli yüklenemedi: 'hospital-media' bucket'ı bulunamadı. "
                "Lütfen Supabase Dashboard > Storage > New Bucket'dan 'hospital-media' adında "
                "public bir bucket oluşturun."
            )
        raise ValueError(f"Galeri görseli yüklenemedi: {error_msg}")


def delete_file_if_exists(file_url_or_path: str) -> None:
    """Supabase Storage'dan veya yerel dosya sisteminden dosyayı siler."""
    if not file_url_or_path:
        return
    
    # Eğer URL ise (Supabase Storage'dan), storage'dan sil
    if file_url_or_path.startswith("http"):
        try:
            supabase = get_supabase_client()
            # URL'den dosya yolunu çıkar
            # Örnek: https://xxx.supabase.co/storage/v1/object/public/hospital-media/logos/logo_xxx.jpg
            # -> logos/logo_xxx.jpg
            if "/hospital-media/" in file_url_or_path:
                file_path = file_url_or_path.split("/hospital-media/")[-1]
                supabase.storage.from_("hospital-media").remove([file_path])
        except Exception:
            pass
    else:
        # Eski yerel dosya sistemi için (geriye dönük uyumluluk)
        abs_path = UPLOAD_DIR / Path(file_url_or_path).name
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


def update_general_info(hospital: dict, data: dict, logo_file=None, request=None) -> dict:
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
        public_url = save_logo(logo_file)
        hospital["image"] = public_url  # Artık tam URL kaydediyoruz

    save_hospital(hospital, request)
    return hospital


def update_services(hospital: dict, service_ids: list[str], request=None) -> dict:
    hospital["services"] = service_ids
    save_hospital(hospital, request)
    return hospital


def update_working_hours(hospital: dict, working_hours: dict, request=None) -> dict:
    hospital["workingHours"] = working_hours
    save_hospital(hospital, request)
    return hospital


def update_is_open_24_hours(hospital: dict, is_open_24_hours: bool, request=None) -> dict:
    """Hastane 7/24 açık durumunu günceller."""
    hospital["isOpen24Hours"] = is_open_24_hours
    # Çalışma saatlerini de güncelle (7/24 açıksa tüm günleri açık yap)
    if is_open_24_hours:
        from panel.forms import DAYS
        working_hours = {}
        for key, _ in DAYS:
            working_hours[key] = {
                "isAvailable": True,
                "start": None,
                "end": None,
            }
        hospital["workingHours"] = working_hours
    save_hospital(hospital, request)
    return hospital


def add_gallery_image(hospital: dict, file, request=None) -> dict:
    public_url = save_gallery_image(file)
    gallery = hospital.get("gallery", [])
    if len(gallery) >= 5:
        raise ValueError("Maksimum 5 görsel eklenebilir")
    gallery.append(public_url)  # Artık tam URL kaydediyoruz
    hospital["gallery"] = gallery
    save_hospital(hospital, request)
    return hospital


def remove_gallery_image(hospital: dict, index: int, request=None) -> dict:
    gallery = hospital.get("gallery", [])
    if 0 <= index < len(gallery):
        delete_file_if_exists(gallery[index])
        gallery.pop(index)
        hospital["gallery"] = gallery
        save_hospital(hospital, request)
    return hospital


def build_working_hours_from_form(cleaned_data: dict) -> dict:
    working_hours = {}
    from panel.forms import DAYS

    # 7/24 açık kontrolü
    is_open_24_hours = cleaned_data.get("is_open_24_hours", False)
    
    if is_open_24_hours:
        # 7/24 açıksa tüm günleri açık olarak işaretle (saat bilgisi olmadan)
        for key, _ in DAYS:
            working_hours[key] = {
                "isAvailable": True,
                "start": None,
                "end": None,
            }
    else:
        # Normal çalışma saatleri
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
    
    # 7/24 açık kontrolü
    is_open_24_hours = hospital.get("is_open_24_hours", False)
    initial["is_open_24_hours"] = is_open_24_hours
    
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
        "is_open_24_hours": db_hospital.get("is_open_24_hours", False),
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
        "is_open_24_hours": hospital.get("isOpen24Hours", False),
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
