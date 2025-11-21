from __future__ import annotations

import requests
from django.conf import settings
from .supabase_client import get_supabase_client


def get_users() -> list[dict]:
    """Tüm kullanıcıları Supabase'den getirir.
    
    Önce user_profiles tablosundan kullanıcıları getirir.
    Eğer user_profiles tablosunda kullanıcı yoksa, Supabase Auth'dan bilgileri alır.
    """
    supabase = get_supabase_client()
    users_dict = {}
    
    # 1. Önce user_profiles tablosundan kullanıcıları getir
    try:
        result = supabase.table("user_profiles").select("*").execute()
        if result.data:
            for u in result.data:
                user_id = str(u.get("id", ""))
                if user_id:
                    users_dict[user_id] = _format_user_from_db(u)
    except Exception:
        pass
    
    # 2. Appointments tablosundaki tüm user_id'leri topla
    try:
        appointments_result = supabase.table("appointments").select("user_id").execute()
        if appointments_result.data:
            user_ids_from_appointments = set()
            for apt in appointments_result.data:
                user_id = str(apt.get("user_id", ""))
                if user_id and user_id not in users_dict:
                    user_ids_from_appointments.add(user_id)
            
            # 3. user_profiles'da olmayan kullanıcılar için Supabase Auth'dan bilgileri al
            # Supabase Admin REST API kullanarak auth.users tablosuna erişim
            if user_ids_from_appointments:
                try:
                    supabase_url = getattr(settings, 'SUPABASE_URL', None)
                    service_role_key = getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
                    
                    if supabase_url and service_role_key:
                        # Her kullanıcı için Supabase Admin API'den bilgileri al
                        for user_id in user_ids_from_appointments:
                            if user_id not in users_dict:
                                try:
                                    # Supabase Admin API: GET /auth/v1/admin/users/{user_id}
                                    url = f"{supabase_url}/auth/v1/admin/users/{user_id}"
                                    headers = {
                                        "apikey": service_role_key,
                                        "Authorization": f"Bearer {service_role_key}",
                                    }
                                    response = requests.get(url, headers=headers, timeout=5)
                                    
                                    if response.status_code == 200:
                                        auth_user = response.json()
                                        user_metadata = auth_user.get("user_metadata", {})
                                        
                                        users_dict[user_id] = {
                                            "id": user_id,
                                            "email": auth_user.get("email", ""),
                                            "password": "",
                                            "name": user_metadata.get("name", ""),
                                            "surname": user_metadata.get("surname", ""),
                                            "phone": user_metadata.get("phone", ""),
                                            "profileImage": None,
                                            "createdAt": auth_user.get("created_at", ""),
                                        }
                                    else:
                                        # API'den bilgi alınamazsa minimal obje oluştur
                                        users_dict[user_id] = {
                                            "id": user_id,
                                            "email": "",
                                            "password": "",
                                            "name": "",
                                            "surname": "",
                                            "phone": "",
                                            "profileImage": None,
                                            "createdAt": "",
                                        }
                                except Exception:
                                    # Hata durumunda minimal obje oluştur
                                    users_dict[user_id] = {
                                        "id": user_id,
                                        "email": "",
                                        "password": "",
                                        "name": "",
                                        "surname": "",
                                        "phone": "",
                                        "profileImage": None,
                                        "createdAt": "",
                                    }
                except Exception:
                    pass
    except Exception:
        pass
    
    return list(users_dict.values())


def get_user_map() -> dict[str, dict]:
    """Kullanıcıları ID'ye göre map'ler.
    
    user_profiles tablosunda olmayan kullanıcılar için,
    Supabase Auth'dan bilgileri alır.
    """
    supabase = get_supabase_client()
    users_dict = {}
    
    # 1. Önce user_profiles tablosundan kullanıcıları getir
    try:
        result = supabase.table("user_profiles").select("*").execute()
        if result.data:
            for u in result.data:
                user_id = str(u.get("id", ""))
                if user_id:
                    users_dict[user_id] = _format_user_from_db(u)
    except Exception:
        pass
    
    # 2. Appointments tablosundaki tüm user_id'leri topla
    try:
        appointments_result = supabase.table("appointments").select("user_id").execute()
        if appointments_result.data:
            user_ids_from_appointments = set()
            for apt in appointments_result.data:
                user_id = str(apt.get("user_id", ""))
                if user_id and user_id not in users_dict:
                    user_ids_from_appointments.add(user_id)
            
            # 3. user_profiles'da olmayan kullanıcılar için Supabase Auth'dan bilgileri al
            # Supabase Admin REST API kullanarak auth.users tablosuna erişim
            if user_ids_from_appointments:
                try:
                    supabase_url = getattr(settings, 'SUPABASE_URL', None)
                    service_role_key = getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
                    
                    if supabase_url and service_role_key:
                        # Her kullanıcı için Supabase Admin API'den bilgileri al
                        for user_id in user_ids_from_appointments:
                            if user_id not in users_dict:
                                try:
                                    # Supabase Admin API: GET /auth/v1/admin/users/{user_id}
                                    url = f"{supabase_url}/auth/v1/admin/users/{user_id}"
                                    headers = {
                                        "apikey": service_role_key,
                                        "Authorization": f"Bearer {service_role_key}",
                                    }
                                    response = requests.get(url, headers=headers, timeout=5)
                                    
                                    if response.status_code == 200:
                                        auth_user = response.json()
                                        user_metadata = auth_user.get("user_metadata", {})
                                        
                                        users_dict[user_id] = {
                                            "id": user_id,
                                            "email": auth_user.get("email", ""),
                                            "password": "",
                                            "name": user_metadata.get("name", ""),
                                            "surname": user_metadata.get("surname", ""),
                                            "phone": user_metadata.get("phone", ""),
                                            "profileImage": None,
                                            "createdAt": auth_user.get("created_at", ""),
                                        }
                                    else:
                                        # API'den bilgi alınamazsa minimal obje oluştur
                                        users_dict[user_id] = {
                                            "id": user_id,
                                            "email": "",
                                            "password": "",
                                            "name": "",
                                            "surname": "",
                                            "phone": "",
                                            "profileImage": None,
                                            "createdAt": "",
                                        }
                                except Exception:
                                    # Hata durumunda minimal obje oluştur
                                    users_dict[user_id] = {
                                        "id": user_id,
                                        "email": "",
                                        "password": "",
                                        "name": "",
                                        "surname": "",
                                        "phone": "",
                                        "profileImage": None,
                                        "createdAt": "",
                                    }
                except Exception:
                    pass
    except Exception:
        pass
    
    return users_dict


def _format_user_from_db(db_user: dict) -> dict:
    """Supabase'den gelen kullanıcı verisini mevcut formata çevirir."""
    return {
        "id": str(db_user.get("id", "")),
        "email": db_user.get("email", ""),  # auth.users'dan alınacak
        "password": "",  # Şifre gösterilmez
        "name": db_user.get("name", ""),
        "surname": db_user.get("surname", ""),
        "phone": db_user.get("phone", ""),
        "profileImage": db_user.get("profile_image"),
        "createdAt": db_user.get("created_at", ""),
    }
