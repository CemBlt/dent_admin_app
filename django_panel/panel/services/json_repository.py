"""JSON okuma/yazma yardımcıları.
Panel uygulamasında tüm veriler geçici olarak JSON dosyalarında tutulur.
Bu modül, aynı kodu tekrar yazmadan güvenli okuma ve yazma işlemleri
sağlamak için ortak fonksiyonları içerir.
"""

from __future__ import annotations

import json
from pathlib import Path
from threading import Lock
from typing import Any

from django.conf import settings

# Dosya bazlı kilit mekanizması: aynı anda birden fazla yazma olursa veri
# kaybını önlemek için basit bir Lock havuzu kullanıyoruz.
_FILE_LOCKS: dict[Path, Lock] = {}


def _resolve_data_file(file_name: str) -> Path:
    """panel/data klasörü içindeki hedef dosyanın mutlak yolunu döndür."""
    if not file_name.endswith('.json'):
        file_name = f"{file_name}.json"

    data_path = settings.PANEL_DATA_DIR / file_name
    if not data_path.exists():
        raise FileNotFoundError(
            f"Beklenen veri dosyası bulunamadı: {data_path}. "
            "Lütfen panel/data klasöründe olduğundan emin olun."
        )
    return data_path


def _get_lock(path: Path) -> Lock:
    if path not in _FILE_LOCKS:
        _FILE_LOCKS[path] = Lock()
    return _FILE_LOCKS[path]


def load_json(file_name: str) -> Any:
    """Belirtilen JSON dosyasını okuyup Python objesi olarak döndür."""
    data_path = _resolve_data_file(file_name)
    with data_path.open('r', encoding='utf-8') as fp:
        return json.load(fp)


def save_json(file_name: str, data: Any) -> None:
    """JSON verisini güvenli şekilde diske yazar."""
    data_path = _resolve_data_file(file_name)
    lock = _get_lock(data_path)

    with lock:
        tmp_path = data_path.with_suffix('.tmp')
        with tmp_path.open('w', encoding='utf-8') as fp:
            json.dump(data, fp, ensure_ascii=False, indent=2)
        tmp_path.replace(data_path)


def update_collection(file_name: str, predicate, update_fn) -> Any:
    """Liste içeren JSON dosyasında kayıt güncellemek için yardımcı.

    Args:
        file_name: JSON dosya adı.
        predicate: Güncellenecek kaydı seçen fonksiyon (item -> bool).
        update_fn: Eşleşen kayıt üzerinde değişiklik yapan fonksiyon.
    Returns:
        Güncellenen kayıt.
    Raises:
        ValueError: Eşleşen kayıt bulunamazsa.
    """
    records = load_json(file_name)
    for index, item in enumerate(records):
        if predicate(item):
            new_item = update_fn(item)
            records[index] = new_item
            save_json(file_name, records)
            return new_item
    raise ValueError(f"{file_name} içinde eşleşen kayıt bulunamadı.")


def append_to_collection(file_name: str, item: dict[str, Any]) -> dict[str, Any]:
    """Liste içeren JSON dosyasına yeni kayıt ekler."""
    records = load_json(file_name)
    if not isinstance(records, list):
        raise TypeError(f"{file_name} list tipinde olmalıdır.")
    records.append(item)
    save_json(file_name, records)
    return item
