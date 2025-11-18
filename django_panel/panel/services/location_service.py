from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Iterable

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

PROVINCE_FILE = "sehirler.json"
DISTRICT_FILE = "ilceler.json"
NEIGHBORHOOD_FILES = [
    "mahalleler-1.json",
    "mahalleler-2.json",
    "mahalleler-3.json",
    "mahalleler-4.json",
]


def _load_json(filename: str) -> list[dict]:
    path = DATA_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"{filename} bulunamadı. Lütfen veri dosyasını ekleyin.")
    with path.open("r", encoding="utf-8") as fp:
        return json.load(fp)


@lru_cache
def _provinces() -> tuple[dict, ...]:
    return tuple(_load_json(PROVINCE_FILE))


@lru_cache
def _districts() -> tuple[dict, ...]:
    return tuple(_load_json(DISTRICT_FILE))


@lru_cache
def _neighborhoods() -> tuple[dict, ...]:
    items: list[dict] = []
    for filename in NEIGHBORHOOD_FILES:
        items.extend(_load_json(filename))
    return tuple(items)


def _normalize_name(value: str) -> str:
    if not value:
        return ""
    value = value.strip()
    return value.title()


def get_provinces() -> list[dict]:
    return [
        {"id": item["sehir_id"], "name": _normalize_name(item["sehir_adi"])}
        for item in _provinces()
    ]


def get_districts(province_id: str | None) -> list[dict]:
    if not province_id:
        return []
    return [
        {"id": item["ilce_id"], "name": _normalize_name(item["ilce_adi"])}
        for item in _districts()
        if item["sehir_id"] == province_id
    ]


def get_neighborhoods(district_id: str | None) -> list[dict]:
    if not district_id:
        return []
    return [
        {"id": item["mahalle_id"], "name": _normalize_name(item["mahalle_adi"])}
        for item in _neighborhoods()
        if item["ilce_id"] == district_id
    ]


def get_province(province_id: str | None) -> dict | None:
    if not province_id:
        return None
    for province in _provinces():
        if province["sehir_id"] == province_id:
            return {
                "id": province["sehir_id"],
                "name": _normalize_name(province["sehir_adi"]),
            }
    return None


def get_district(district_id: str | None) -> dict | None:
    if not district_id:
        return None
    for district in _districts():
        if district["ilce_id"] == district_id:
            province = get_province(district["sehir_id"])
            return {
                "id": district["ilce_id"],
                "name": _normalize_name(district["ilce_adi"]),
                "provinceId": district["sehir_id"],
                "provinceName": province["name"] if province else None,
            }
    return None


def get_neighborhood(neighborhood_id: str | None) -> dict | None:
    if not neighborhood_id:
        return None
    for neighborhood in _neighborhoods():
        if neighborhood["mahalle_id"] == neighborhood_id:
            district = get_district(neighborhood["ilce_id"])
            return {
                "id": neighborhood["mahalle_id"],
                "name": _normalize_name(neighborhood["mahalle_adi"]),
                "districtId": neighborhood["ilce_id"],
                "districtName": district["name"] if district else None,
                "provinceId": district["provinceId"] if district else None,
                "provinceName": district["provinceName"] if district else None,
            }
    return None


def as_choice_tuples(items: Iterable[dict]) -> list[tuple[str, str]]:
    return [(item["id"], item["name"]) for item in items]

