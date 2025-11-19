"""Yorum ve yanıt yönetimi servisi."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Optional

from .supabase_client import get_supabase_client
from .doctor_service import get_doctors
from .hospital_service import get_hospital
from .user_service import get_user_map

from .hospital_service import _get_active_hospital_id


def _load_reviews() -> list[dict]:
    """Tüm yorumları Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("reviews").select("*").execute()
    return result.data if result.data else []


def _load_ratings() -> list[dict]:
    """Tüm puanlamaları Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("ratings").select("*").execute()
    return result.data if result.data else []


def get_reviews_with_details(
    doctor_id: Optional[str] = None,
    min_rating: Optional[int] = None,
    max_rating: Optional[int] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    has_reply: Optional[bool] = None,
) -> list[dict]:
    """Yorumları detaylı bilgilerle birlikte getirir."""
    reviews = _load_reviews()
    ratings = _load_ratings()
    user_map = get_user_map()
    doctors = {d["id"]: d for d in get_doctors()}
    hospital = get_hospital()

    # Rating'leri appointment_id'ye göre map'le
    rating_map = {str(r.get("appointment_id", "")): r for r in ratings}

    result = []
    for review in reviews:
        # Sadece aktif hastaneye ait yorumları al
        hospital_id = _get_active_hospital_id()
        if str(review.get("hospital_id", "")) != hospital_id:
            continue

        # Filtreleme
        if doctor_id and str(review.get("doctor_id", "")) != doctor_id:
            continue

        rating = rating_map.get(str(review.get("appointment_id", "")))
        if rating:
            doctor_rating = rating.get("doctor_rating", 0) or 0
            hospital_rating = rating.get("hospital_rating", 0) or 0
            avg_rating = (doctor_rating + hospital_rating) / 2

            if min_rating and avg_rating < min_rating:
                continue
            if max_rating and avg_rating > max_rating:
                continue
        else:
            avg_rating = 0

        # Tarih filtresi (ISO format string karşılaştırması)
        created_at = review.get("created_at", "")
        if date_from:
            # date_from "YYYY-MM-DD" formatında gelir, ISO string ile karşılaştır
            date_from_str = str(date_from) if date_from else ""
            if created_at and date_from_str and created_at[:10] < date_from_str:
                continue
        if date_to:
            # date_to "YYYY-MM-DD" formatında gelir, ISO string ile karşılaştır
            date_to_str = str(date_to) if date_to else ""
            if created_at and date_to_str and created_at[:10] > date_to_str:
                continue

        # Yanıt durumu filtresi
        has_reply_value = bool(review.get("reply"))
        if has_reply is not None and has_reply_value != has_reply:
            continue

        # Detaylı bilgileri ekle
        user = user_map.get(str(review.get("user_id", "")))
        doctor = doctors.get(str(review.get("doctor_id", "")))

        # Review'ı mevcut formata çevir
        formatted_review = _format_review_from_db(review)
        formatted_review.update({
            "user": user,
            "doctor": doctor,
            "hospital": hospital,
            "rating": rating,
            "doctor_rating": rating.get("doctor_rating", 0) if rating else 0,
            "hospital_rating": rating.get("hospital_rating", 0) if rating else 0,
            "avg_rating": avg_rating,
            "has_reply": has_reply_value,
        })
        
        result.append(formatted_review)

    # Tarihe göre sırala (en yeni önce)
    result.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    return result


def get_review_statistics() -> dict:
    """Yorum istatistiklerini hesaplar."""
    reviews = get_reviews_with_details()
    ratings = _load_ratings()
    hospital_id = _get_active_hospital_id()
    hospital_ratings = [
        r.get("hospital_rating", 0) or 0
        for r in ratings
        if str(r.get("hospital_id", "")) == hospital_id
    ]

    now = datetime.now()
    thirty_days_ago = (now - timedelta(days=30)).isoformat() + "Z"

    recent_reviews = [
        r for r in reviews
        if r.get("createdAt", "") >= thirty_days_ago
    ]

    replied_count = sum(1 for r in reviews if r.get("has_reply", False))
    not_replied_count = len(reviews) - replied_count

    avg_rating = (
        sum(hospital_ratings) / len(hospital_ratings)
        if hospital_ratings else 0
    )

    return {
        "total_reviews": len(reviews),
        "average_rating": round(avg_rating, 1),
        "replied_count": replied_count,
        "not_replied_count": not_replied_count,
        "recent_count": len(recent_reviews),
    }


def add_reply(review_id: str, reply_text: str) -> dict:
    """Yoruma yanıt ekler veya günceller."""
    supabase = get_supabase_client()
    result = supabase.table("reviews").update({
        "reply": reply_text,
        "replied_at": datetime.now().isoformat() + "Z"
    }).eq("id", review_id).execute()
    
    if not result.data:
        raise ValueError("Yorum bulunamadı veya güncellenemedi")
    
    return _format_review_from_db(result.data[0])


def delete_reply(review_id: str) -> dict:
    """Yorumdan yanıtı siler."""
    supabase = get_supabase_client()
    result = supabase.table("reviews").update({
        "reply": None,
        "replied_at": None
    }).eq("id", review_id).execute()
    
    if not result.data:
        raise ValueError("Yorum bulunamadı veya güncellenemedi")
    
    return _format_review_from_db(result.data[0])


def _format_review_from_db(db_review: dict) -> dict:
    """Supabase'den gelen yorum verisini mevcut formata çevirir."""
    return {
        "id": str(db_review.get("id", "")),
        "userId": str(db_review.get("user_id", "")),
        "hospitalId": str(db_review.get("hospital_id", "")),
        "doctorId": str(db_review.get("doctor_id", "")) if db_review.get("doctor_id") else None,
        "appointmentId": str(db_review.get("appointment_id", "")),
        "comment": db_review.get("comment", ""),
        "reply": db_review.get("reply"),
        "repliedAt": db_review.get("replied_at"),
        "createdAt": db_review.get("created_at", ""),
    }

