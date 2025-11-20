"""
Context processors for panel app.
Hospital bilgisi tüm template'lere otomatik olarak eklenir.
"""

from .services import hospital_service


def hospital_context(request):
    """
    Hospital bilgisini tüm template'lere ekler.
    Bu sayede her view'de tekrar tekrar hospital_service.get_hospital() çağırmaya gerek kalmaz.
    """
    try:
        # Session'dan hospital_id al
        hospital = hospital_service.get_hospital(request)
        return {
            "hospital": hospital,
        }
    except (ValueError, AttributeError, KeyError, IndexError):
        # Login olmamışsa veya hastane bulunamazsa boş dict döndür
        return {
            "hospital": None,
        }

