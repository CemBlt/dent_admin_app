"""Ayarlar yönetimi servisi."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

from django.conf import settings
from django.http import HttpResponse

from .json_repository import load_json, save_json
from .hospital_service import get_hospitals


def get_settings() -> dict:
    """Tüm ayarları getirir."""
    try:
        return load_json("settings")
    except FileNotFoundError:
        # Varsayılan ayarları döndür
        return {
            "general": {
                "active_hospital_id": "1",
                "panel_title": "Hastane Yönetim Paneli",
                "date_format": "DD.MM.YYYY",
                "time_format": "24",
                "language": "tr",
            },
            "notifications": {
                "email_enabled": True,
                "new_appointment": True,
                "new_review": True,
                "appointment_reminder": True,
                "reminder_hours_before": 24,
            },
            "data_management": {
                "backup_enabled": True,
                "auto_backup_days": 7,
            },
            "security": {
                "session_timeout_minutes": 30,
            },
            "appearance": {
                "theme": "default",
                "show_dashboard_widgets": True,
                "records_per_page": 20,
            },
        }


def update_settings(category: str, updates: dict) -> dict:
    """Belirli bir kategori ayarlarını günceller."""
    settings_data = get_settings()
    if category not in settings_data:
        settings_data[category] = {}
    settings_data[category].update(updates)
    save_json("settings", settings_data)
    return settings_data


def get_data_statistics() -> dict:
    """Tüm JSON dosyalarından istatistikleri hesaplar."""
    stats = {}
    data_dir = settings.PANEL_DATA_DIR
    
    files_to_check = [
        "appointments",
        "doctors",
        "hospitals",
        "reviews",
        "ratings",
        "services",
        "users",
        "holidays",
        "workingHours",
    ]
    
    for file_name in files_to_check:
        try:
            data = load_json(file_name)
            if isinstance(data, list):
                stats[file_name] = len(data)
            elif isinstance(data, dict):
                stats[file_name] = len(data)
            else:
                stats[file_name] = 0
        except FileNotFoundError:
            stats[file_name] = 0
    
    return stats


def export_data_as_json() -> bytes:
    """Tüm JSON verilerini tek bir JSON dosyası olarak export eder."""
    import json
    
    data_dir = settings.PANEL_DATA_DIR
    export_data = {}
    
    files_to_export = [
        "appointments",
        "doctors",
        "hospitals",
        "reviews",
        "ratings",
        "services",
        "users",
        "holidays",
        "workingHours",
        "settings",
    ]
    
    for file_name in files_to_export:
        try:
            export_data[file_name] = load_json(file_name)
        except FileNotFoundError:
            export_data[file_name] = None
    
    return json.dumps(export_data, ensure_ascii=False, indent=2).encode('utf-8')


def get_hospital_choices() -> list[tuple[str, str]]:
    """Hastane seçim listesi oluşturur."""
    hospitals = get_hospitals()
    return [(h["id"], h["name"]) for h in hospitals]

