"""Supabase Auth servisi - Kullanıcı girişi ve kayıt işlemleri."""

from __future__ import annotations

from django.conf import settings
from supabase import create_client, Client


def get_auth_client() -> Client:
    """Supabase Auth client'ı döndürür (anon key ile)."""
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)


def sign_up(email: str, password: str) -> dict:
    """Yeni kullanıcı kaydı oluşturur.
    
    Args:
        email: Kullanıcı email'i
        password: Kullanıcı şifresi
        
    Returns:
        dict: Kullanıcı bilgileri ve session token
        
    Raises:
        Exception: Kayıt başarısız olursa
    """
    supabase = get_auth_client()
    
    # Email doğrulama kapalı olacak (sadece admin onayı)
    response = supabase.auth.sign_up({
        "email": email,
        "password": password,
        "options": {
            "email_redirect_to": None  # Email doğrulama kapalı
        }
    })
    
    if response.user is None:
        raise ValueError("Kullanıcı kaydı oluşturulamadı")
    
    return {
        "user_id": str(response.user.id),
        "email": response.user.email,
        "session": response.session,
    }


def sign_in(email: str, password: str) -> dict:
    """Kullanıcı girişi yapar.
    
    Args:
        email: Kullanıcı email'i
        password: Kullanıcı şifresi
        
    Returns:
        dict: Kullanıcı bilgileri ve session token
        
    Raises:
        Exception: Giriş başarısız olursa
    """
    supabase = get_auth_client()
    
    response = supabase.auth.sign_in_with_password({
        "email": email,
        "password": password,
    })
    
    if response.user is None:
        raise ValueError("Email veya şifre hatalı")
    
    return {
        "user_id": str(response.user.id),
        "email": response.user.email,
        "session": response.session,
    }


def get_user_by_email(email: str) -> dict | None:
    """Email'e göre kullanıcı bilgilerini getirir.
    
    Args:
        email: Kullanıcı email'i
        
    Returns:
        dict: Kullanıcı bilgileri veya None
    """
    try:
        supabase = get_auth_client()
        # Supabase Admin API kullanarak kullanıcıyı bul
        # Not: Bu service_role key gerektirir
        from .supabase_client import get_supabase_client
        admin_client = get_supabase_client()
        
        # auth.users tablosuna direkt erişim yok, bu yüzden user_profiles üzerinden kontrol edelim
        result = admin_client.table("user_profiles").select("*").eq("email", email).execute()
        
        if result.data:
            return result.data[0]
        return None
    except Exception:
        return None

