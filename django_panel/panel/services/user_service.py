from __future__ import annotations

from .supabase_client import get_supabase_client


def get_users() -> list[dict]:
    """Tüm kullanıcıları Supabase'den getirir."""
    supabase = get_supabase_client()
    # user_profiles tablosundan kullanıcıları getir
    result = supabase.table("user_profiles").select("*").execute()
    
    if not result.data:
        return []
    
    # Supabase formatından mevcut formata çevir
    return [_format_user_from_db(u) for u in result.data]


def get_user_map() -> dict[str, dict]:
    """Kullanıcıları ID'ye göre map'ler."""
    users = get_users()
    return {user["id"]: user for user in users}


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
