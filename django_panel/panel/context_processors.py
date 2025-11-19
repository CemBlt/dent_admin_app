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
    return {
        "hospital": hospital_service.get_hospital(),
    }

