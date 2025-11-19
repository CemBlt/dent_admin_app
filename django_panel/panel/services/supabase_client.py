"""Supabase client helper - Singleton pattern ile tek bir instance yönetimi."""

from __future__ import annotations

import os
from typing import Optional

from supabase import create_client, Client
from django.conf import settings


class SupabaseClient:
    """Supabase client singleton sınıfı.
    
    Tüm uygulama boyunca tek bir Supabase client instance'ı kullanılır.
    """
    
    _instance: Optional[SupabaseClient] = None
    _client: Optional[Client] = None
    
    def __new__(cls):
        """Singleton pattern: Tek bir instance döndürür."""
        if cls._instance is None:
            cls._instance = super(SupabaseClient, cls).__new__(cls)
        return cls._instance
    
    def __init__(self):
        """Client'ı sadece bir kez initialize et."""
        if self._client is None:
            self._initialize_client()
    
    def _initialize_client(self) -> None:
        """Supabase client'ı initialize eder."""
        supabase_url = getattr(settings, 'SUPABASE_URL', None)
        supabase_key = getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
        
        if not supabase_url:
            raise ValueError(
                "SUPABASE_URL ayarı bulunamadı. "
                "Lütfen settings.py dosyasında SUPABASE_URL'i tanımlayın veya "
                ".env dosyasında SUPABASE_URL değişkenini ayarlayın."
            )
        
        if not supabase_key:
            raise ValueError(
                "SUPABASE_SERVICE_ROLE_KEY ayarı bulunamadı. "
                "Lütfen settings.py dosyasında SUPABASE_SERVICE_ROLE_KEY'i tanımlayın veya "
                ".env dosyasında SUPABASE_SERVICE_ROLE_KEY değişkenini ayarlayın."
            )
        
        try:
            self._client = create_client(supabase_url, supabase_key)
        except Exception as e:
            raise ConnectionError(
                f"Supabase client oluşturulamadı: {str(e)}. "
                "Lütfen SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY değerlerini kontrol edin."
            ) from e
    
    def get_client(self) -> Client:
        """Supabase client instance'ını döndürür.
        
        Returns:
            Client: Supabase client instance
            
        Raises:
            ConnectionError: Client initialize edilemediyse
        """
        if self._client is None:
            self._initialize_client()
        
        return self._client
    
    @classmethod
    def reset(cls) -> None:
        """Test amaçlı: Singleton instance'ı sıfırla."""
        cls._instance = None
        cls._client = None


# Global helper function - Kolay kullanım için
def get_supabase_client() -> Client:
    """Supabase client'ı döndüren global helper fonksiyon.
    
    Usage:
        from panel.services.supabase_client import get_supabase_client
        
        supabase = get_supabase_client()
        result = supabase.table('hospitals').select('*').execute()
    
    Returns:
        Client: Supabase client instance
    """
    client_manager = SupabaseClient()
    return client_manager.get_client()

