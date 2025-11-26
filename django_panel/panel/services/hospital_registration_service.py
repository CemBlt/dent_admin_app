"""Hastane kayıt servisi."""

from __future__ import annotations

import random
from django.conf import settings
from .supabase_client import get_supabase_client
from .auth_service import sign_up
from .email_service import send_hospital_registration_notification
from . import location_service
from .hospital_service import _resolve_location_snapshot


def generate_hospital_code() -> str:
    """6 haneli unique hastane kodu oluşturur."""
    supabase = get_supabase_client()
    
    while True:
        code = f"{random.randint(100000, 999999)}"
        
        # Kod zaten var mı kontrol et
        result = supabase.table("hospitals").select("id").eq("hospital_code", code).execute()
        
        if not result.data:
            return code


def register_hospital(form_data: dict, logo_file=None) -> dict:
    """Yeni hastane kaydı oluşturur.
    
    Args:
        form_data: Form verileri
        logo_file: Logo dosyası (opsiyonel)
        
    Returns:
        dict: Oluşturulan hastane bilgileri
        
    Raises:
        ValueError: Kayıt başarısız olursa
    """
    supabase = get_supabase_client()
    
    # 1. Supabase Auth'da kullanıcı oluştur
    email = form_data["email"]
    password = form_data["password"]
    
    try:
        auth_response = sign_up(email, password)
        user_id = auth_response["user_id"]
    except Exception as e:
        raise ValueError(f"Kullanıcı kaydı oluşturulamadı: {str(e)}")
    
    # 2. Lokasyon bilgilerini çöz
    try:
        location_snapshot = _resolve_location_snapshot(
            form_data["province"],
            form_data["district"],
            form_data["neighborhood"],
        )
    except ValueError as e:
        raise ValueError(str(e))
    
    # 3. Çalışma saatlerini oluştur
    is_open_24_hours = form_data.get("is_open_24_hours", False)
    working_hours = {}
    
    if is_open_24_hours:
        # 7/24 açıksa tüm günleri açık olarak işaretle (saat bilgisi olmadan)
        days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for day in days:
            working_hours[day] = {
                "isAvailable": True,
                "start": None,
                "end": None,
            }
    else:
        # Normal çalışma saatleri
        days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        start_time = form_data.get("working_hours_start", "09:00")
        end_time = form_data.get("working_hours_end", "18:00")
        
        for day in days:
            is_open = form_data.get(f"working_hours_{day}", False)
            working_hours[day] = {
                "isAvailable": bool(is_open),
                "start": start_time if is_open else None,
                "end": end_time if is_open else None,
            }
    
    # 4. Logo dosyasını kaydet (eğer varsa)
    logo_path = None
    if logo_file:
        from .hospital_service import save_logo
        logo_path = save_logo(logo_file)  # Supabase Storage'dan public URL döner
    
    # 5. Hastane kaydını oluştur
    # Not: Tabloda olmayan kolonlar (status, owner_email, created_by_user_id) 
    # ALTER TABLE ile eklenmiş olmalı
    hospital_data = {
        "name": form_data["name"],
        "address": form_data.get("address", ""),
        "latitude": float(form_data["latitude"]),
        "longitude": float(form_data["longitude"]),
        "phone": form_data["phone"],
        "email": form_data["hospital_email"],
        "description": form_data.get("description", ""),
        "image": logo_path,
        "gallery": [],  # TEXT[] kolonu var, boş array gönder
        "services": [],  # TEXT[] veya JSONB - Hastane hizmetleri (başlangıçta boş, sonra eklenebilir)
        "working_hours": working_hours,
        "is_open_24_hours": is_open_24_hours,
        "province_id": location_snapshot["province"]["id"],
        "province_name": location_snapshot["province"]["name"],
        "district_id": location_snapshot["district"]["id"],
        "district_name": location_snapshot["district"]["name"],
        "neighborhood_id": location_snapshot["neighborhood"]["id"],
        "neighborhood_name": location_snapshot["neighborhood"]["name"],
        # Bu kolonlar ALTER TABLE ile eklenmiş olmalı:
        "status": "pending",  # Onay bekliyor
        "owner_email": email,
        "created_by_user_id": user_id,
    }
    
    result = supabase.table("hospitals").insert(hospital_data).execute()
    
    if not result.data:
        raise ValueError("Hastane kaydı oluşturulamadı")
    
    hospital = result.data[0]
    
    # 6. Admin'e email gönder
    send_hospital_registration_notification(hospital)
    
    return {
        "hospital_id": str(hospital["id"]),
        "hospital_name": hospital["name"],
        "status": hospital["status"],
    }


def approve_hospital(hospital_id: str) -> dict:
    """Hastane kaydını onaylar ve kullanıcıya kod gönderir.
    
    Args:
        hospital_id: Hastane UUID'si
        
    Returns:
        dict: Onaylanan hastane bilgileri
        
    Raises:
        ValueError: Onay başarısız olursa
    """
    supabase = get_supabase_client()
    
    # 1. Hastane bilgilerini al
    result = supabase.table("hospitals").select("*").eq("id", hospital_id).single().execute()
    
    if not result.data:
        raise ValueError("Hastane bulunamadı")
    
    hospital = result.data[0]
    
    # 2. Eğer zaten onaylanmışsa kod gönderme
    if hospital.get("status") == "approved":
        return {
            "hospital_id": str(hospital["id"]),
            "hospital_code": hospital.get("hospital_code"),
        }
    
    # 3. 6 haneli kod oluştur
    hospital_code = generate_hospital_code()
    
    # 4. Hastaneyi onayla ve kodu kaydet
    update_result = supabase.table("hospitals").update({
        "status": "approved",
        "hospital_code": hospital_code,
    }).eq("id", hospital_id).execute()
    
    if not update_result.data:
        raise ValueError("Hastane onaylanamadı")
    
    # 5. Kullanıcıya email gönder
    from .email_service import send_hospital_approval_notification
    send_hospital_approval_notification(
        hospital_email=hospital.get("owner_email"),
        hospital_code=hospital_code,
        hospital_name=hospital.get("name", "")
    )
    
    return {
        "hospital_id": str(hospital["id"]),
        "hospital_code": hospital_code,
    }



