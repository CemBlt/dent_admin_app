from django.shortcuts import render
from .auth_views import login_required
from ..services.dashboard_service import load_dashboard_context

@login_required
def dashboard(request):
    """Panel ana sayfası: JSON verilerinden özet metrikleri oluşturur."""
    context = load_dashboard_context(request)
    context["page_title"] = "Genel Bakış"
    # hospital context processor tarafından otomatik ekleniyor
    return render(request, "panel/dashboard.html", context)

