from django.http import JsonResponse
from django.views.decorators.http import require_GET
from ..services import location_service

@require_GET
def location_provinces(request):
    return JsonResponse({"results": location_service.get_provinces()})

@require_GET
def location_districts(request, province_id: str):
    return JsonResponse({"results": location_service.get_districts(province_id)})

@require_GET
def location_neighborhoods(request, district_id: str):
    return JsonResponse({"results": location_service.get_neighborhoods(district_id)})

