"""
Utility functions for panel app.
Ortak kullanılan helper fonksiyonları.
"""

from __future__ import annotations

from typing import Any


def build_choice_tuples(items: list[dict], id_key: str = "id", name_key: str = "name") -> list[tuple[str, str]]:
    """
    Dictionary listesinden Django ChoiceField için tuple listesi oluşturur.
    
    Args:
        items: Dictionary listesi
        id_key: ID için kullanılacak key (default: "id")
        name_key: İsim için kullanılacak key (default: "name")
    
    Returns:
        [(id, name), ...] formatında tuple listesi
    """
    return [(str(item[id_key]), str(item[name_key])) for item in items]


def build_doctor_choices(doctors: list[dict]) -> list[tuple[str, str]]:
    """
    Doktor listesinden choice tuple'ları oluşturur.
    Format: (id, "Ad Soyad")
    """
    return [
        (str(doc["id"]), f"{doc['name']} {doc['surname']}")
        for doc in doctors
    ]


def build_service_choices(services: list[dict]) -> list[tuple[str, str]]:
    """
    Hizmet listesinden choice tuple'ları oluşturur.
    Format: (id, name)
    """
    return build_choice_tuples(services, id_key="id", name_key="name")


def format_date(date_str: str, format_str: str = "%d.%m.%Y") -> str:
    """
    Tarih string'ini formatlar.
    
    Args:
        date_str: ISO format tarih string'i (örn: "2024-01-15")
        format_str: Çıktı formatı (default: "%d.%m.%Y")
    
    Returns:
        Formatlanmış tarih string'i
    """
    from datetime import datetime
    
    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
        return date_obj.strftime(format_str)
    except (ValueError, TypeError, AttributeError):
        return date_str  # Formatlanamazsa orijinal değeri döndür


def format_datetime(datetime_str: str, format_str: str = "%d.%m.%Y %H:%M") -> str:
    """
    Datetime string'ini formatlar.
    
    Args:
        datetime_str: ISO format datetime string'i
        format_str: Çıktı formatı (default: "%d.%m.%Y %H:%M")
    
    Returns:
        Formatlanmış datetime string'i
    """
    from datetime import datetime
    
    try:
        # ISO formatını parse et (Z veya +00:00 ile gelebilir)
        dt_str = datetime_str.replace("Z", "+00:00")
        dt = datetime.fromisoformat(dt_str)
        return dt.strftime(format_str)
    except (ValueError, TypeError, AttributeError):
        return datetime_str  # Formatlanamazsa orijinal değeri döndür


def safe_get(data: dict, *keys, default: Any = None) -> Any:
    """
    Nested dictionary'den güvenli şekilde değer alır.
    
    Args:
        data: Dictionary
        *keys: Key path (örn: "user", "name")
        default: Bulunamazsa döndürülecek değer
    
    Returns:
        Değer veya default
    """
    result = data
    for key in keys:
        if isinstance(result, dict):
            result = result.get(key)
            if result is None:
                return default
        else:
            return default
    return result if result is not None else default


def validate_working_hours_form(form, days: list[tuple[str, str]], request=None) -> bool:
    """
    Çalışma saatleri formunu validate eder.
    
    Args:
        form: WorkingHoursForm veya DoctorWorkingHoursForm
        days: Gün listesi [(key, label), ...]
        request: Django request objesi (mesaj için)
    
    Returns:
        True if valid, False otherwise
    """
    from django.contrib import messages
    
    valid = True
    for key, label in days:
        is_open = form.cleaned_data.get(f"{key}_is_open")
        start = form.cleaned_data.get(f"{key}_start")
        end = form.cleaned_data.get(f"{key}_end")
        
        if is_open and (not start or not end):
            form.add_error(f"{key}_start", f"{label} için başlangıç/bitiş saatlerini giriniz.")
            valid = False
        
        if start and end and start >= end:
            form.add_error(f"{key}_start", f"{label} için başlangıç saati bitişten küçük olmalıdır.")
            valid = False
    
    if not valid and request:
        messages.error(request, "Çalışma saatleri doğrulaması başarısız.")
    
    return valid

