from __future__ import annotations

from .json_repository import load_json, save_json


def _load_services() -> list[dict]:
    return load_json("services")


def _persist_services(services: list[dict]) -> None:
    save_json("services", services)


def get_services() -> list[dict]:
    return _load_services()


def _generate_id(services: list[dict]) -> str:
    return str(max((int(service["id"]) for service in services), default=0) + 1)


def add_service(data: dict) -> dict:
    services = _load_services()
    new_service = {
        "id": _generate_id(services),
        "name": data["name"],
        "description": data.get("description", ""),
        "price": float(data["price"]),
    }
    services.append(new_service)
    _persist_services(services)
    return new_service


def update_service(service_id: str, data: dict) -> dict:
    services = _load_services()
    for idx, service in enumerate(services):
        if service["id"] == service_id:
            service["name"] = data["name"]
            service["description"] = data.get("description", "")
            # Price alanı formdan kaldırıldı, mevcut değeri koru
            if "price" in data:
                service["price"] = float(data["price"])
            services[idx] = service
            _persist_services(services)
            return service
    raise ValueError("Hizmet bulunamadı")


def delete_service(service_id: str) -> None:
    services = [service for service in _load_services() if service["id"] != service_id]
    _persist_services(services)
    _remove_service_from_doctors(service_id)
    _remove_service_from_hospitals(service_id)


def update_doctor_assignments(service_id: str, doctor_ids: list[str]) -> None:
    doctors = load_json("doctors")
    for doctor in doctors:
        services = set(doctor.get("services", []))
        if doctor["id"] in doctor_ids:
            services.add(service_id)
        else:
            services.discard(service_id)
        doctor["services"] = list(services)
    save_json("doctors", doctors)


def update_hospital_assignments(service_id: str, hospital_ids: list[str]) -> None:
    hospitals = load_json("hospitals")
    for hospital in hospitals:
        services = set(hospital.get("services", []))
        if hospital["id"] in hospital_ids:
            services.add(service_id)
        else:
            services.discard(service_id)
        hospital["services"] = list(services)
    save_json("hospitals", hospitals)


def _remove_service_from_doctors(service_id: str) -> None:
    doctors = load_json("doctors")
    for doctor in doctors:
        services = set(doctor.get("services", []))
        services.discard(service_id)
        doctor["services"] = list(services)
    save_json("doctors", doctors)


def _remove_service_from_hospitals(service_id: str) -> None:
    hospitals = load_json("hospitals")
    for hospital in hospitals:
        services = set(hospital.get("services", []))
        services.discard(service_id)
        hospital["services"] = list(services)
    save_json("hospitals", hospitals)
