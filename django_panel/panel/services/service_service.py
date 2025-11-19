from __future__ import annotations

from .supabase_client import get_supabase_client


def get_services() -> list[dict]:
    """Tüm hizmetleri Supabase'den getirir."""
    supabase = get_supabase_client()
    result = supabase.table("services").select("*").execute()
    return result.data if result.data else []


def add_service(data: dict) -> dict:
    """Yeni hizmet ekler."""
    supabase = get_supabase_client()
    service_data = {
        "name": data["name"],
        "description": data.get("description", ""),
        "price": int(float(data["price"])),
    }
    
    result = supabase.table("services").insert(service_data).execute()
    
    if not result.data:
        raise ValueError("Hizmet eklenemedi")
    
    return result.data[0]


def update_service(service_id: str, data: dict) -> dict:
    """Hizmet bilgilerini günceller."""
    supabase = get_supabase_client()
    update_data = {
        "name": data["name"],
        "description": data.get("description", ""),
    }
    
    # Price alanı formdan kaldırıldı, mevcut değeri koru
    if "price" in data:
        update_data["price"] = int(float(data["price"]))
    
    result = supabase.table("services").update(update_data).eq("id", service_id).execute()
    
    if not result.data:
        raise ValueError("Hizmet bulunamadı veya güncellenemedi")
    
    return result.data[0]


def delete_service(service_id: str) -> None:
    """Hizmeti siler."""
    supabase = get_supabase_client()
    
    # Doktorlardan ve hastanelerden hizmeti kaldır
    _remove_service_from_doctors(service_id)
    _remove_service_from_hospitals(service_id)
    
    # Hizmeti sil
    result = supabase.table("services").delete().eq("id", service_id).execute()
    
    if not result.data:
        raise ValueError("Hizmet bulunamadı veya silinemedi")


def update_doctor_assignments(service_id: str, doctor_ids: list[str]) -> None:
    """Doktorlara hizmet ataması yapar."""
    supabase = get_supabase_client()
    
    # Tüm doktorları getir
    all_doctors = supabase.table("doctors").select("id,services").execute()
    
    if not all_doctors.data:
        return
    
    for doctor in all_doctors.data:
        services = set(doctor.get("services", []))
        doctor_id = str(doctor.get("id", ""))
        
        if doctor_id in doctor_ids:
            services.add(service_id)
        else:
            services.discard(service_id)
        
        # Güncelle
        supabase.table("doctors").update({"services": list(services)}).eq("id", doctor_id).execute()


def update_hospital_assignments(service_id: str, hospital_ids: list[str]) -> None:
    """Hastanelere hizmet ataması yapar."""
    supabase = get_supabase_client()
    
    # Tüm hastaneleri getir
    all_hospitals = supabase.table("hospitals").select("id,services").execute()
    
    if not all_hospitals.data:
        return
    
    for hospital in all_hospitals.data:
        services = set(hospital.get("services", []))
        hospital_id = str(hospital.get("id", ""))
        
        if hospital_id in hospital_ids:
            services.add(service_id)
        else:
            services.discard(service_id)
        
        # Güncelle
        supabase.table("hospitals").update({"services": list(services)}).eq("id", hospital_id).execute()


def _remove_service_from_doctors(service_id: str) -> None:
    """Doktorlardan hizmeti kaldırır."""
    supabase = get_supabase_client()
    
    # Tüm doktorları getir
    all_doctors = supabase.table("doctors").select("id,services").execute()
    
    if not all_doctors.data:
        return
    
    for doctor in all_doctors.data:
        services = set(doctor.get("services", []))
        services.discard(service_id)
        
        # Güncelle
        supabase.table("doctors").update({"services": list(services)}).eq("id", doctor.get("id")).execute()


def _remove_service_from_hospitals(service_id: str) -> None:
    """Hastanelerden hizmeti kaldırır."""
    supabase = get_supabase_client()
    
    # Tüm hastaneleri getir
    all_hospitals = supabase.table("hospitals").select("id,services").execute()
    
    if not all_hospitals.data:
        return
    
    for hospital in all_hospitals.data:
        services = set(hospital.get("services", []))
        services.discard(service_id)
        
        # Güncelle
        supabase.table("hospitals").update({"services": list(services)}).eq("id", hospital.get("id")).execute()
