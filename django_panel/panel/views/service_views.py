from django.shortcuts import render, redirect
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from .auth_views import login_required
from ..forms import ServiceForm, ServiceAssignmentForm
from ..utils import build_doctor_choices
from ..services import doctor_service, service_service, hospital_service

class ServiceManagementView(View):
    template_name = "panel/service_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        return render(request, self.template_name, self._build_context(request))

    def post(self, request):
        action = request.POST.get("form_type")
        if action == "update_service":
            form = ServiceForm(request.POST)
            if form.is_valid():
                service_service.update_service(form.cleaned_data["service_id"], form.cleaned_data)
                messages.success(request, "Hizmet güncellendi.")
                return redirect("service_management")
            messages.error(request, "Hizmet güncellenemedi.")

        elif action == "delete_service":
            service_service.delete_service(request.POST.get("service_id"))
            messages.success(request, "Hizmet silindi.")
            return redirect("service_management")

        elif action == "update_assignments":
            doctors = request.POST.getlist("doctors")
            service_id = request.POST.get("service_id")
            service_service.update_doctor_assignments(service_id, doctors)
            messages.success(request, "Atamalar güncellendi.")
            return redirect("service_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        all_services = service_service.get_services()
        doctors = doctor_service.get_doctors(request)
        hospital = hospital_service.get_hospital(request)
        
        selected_service_ids = set(hospital.get("services", []))
        services = [s for s in all_services if s["id"] in selected_service_ids]

        doctor_choices = build_doctor_choices(doctors)

        service_cards = []
        for service in services:
            general_form = ServiceForm(initial={
                "service_id": service["id"],
                "name": service["name"],
                "description": service.get("description", ""),
            })
            assigned_doctors = [doc["id"] for doc in doctors if service["id"] in doc.get("services", [])]
            assignment_form = ServiceAssignmentForm(
                initial={
                    "service_id": service["id"],
                    "doctors": assigned_doctors,
                },
                doctor_choices=doctor_choices,
            )
            service_cards.append({
                "data": service,
                "general_form": general_form,
                "assignment_form": assignment_form,
                "assigned_doctors": [doc for doc in doctors if doc["id"] in assigned_doctors],
            })

        context = {
            "page_title": "Hizmetler",
            "service_cards": service_cards,
            "doctor_choices": doctor_choices,
        }
        return context

