from django.shortcuts import render

from .services.dashboard_service import load_dashboard_context


def dashboard(request):
    """Panel ana sayfası: JSON verilerinden özet metrikleri oluşturur."""
    context = load_dashboard_context()
    context["page_title"] = "Genel Bakış"
    return render(request, "panel/dashboard.html", context)
