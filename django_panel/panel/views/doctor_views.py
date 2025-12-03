from django.shortcuts import render, redirect
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from .auth_views import login_required
from ..forms import DoctorForm, DoctorWorkingHoursForm, DoctorHolidayForm, DAYS
from ..utils import build_service_choices, validate_working_hours_form
from ..services import doctor_service, hospital_service, event_service

class DoctorManagementView(View):
    template_name = "panel/doctor_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        return render(request, self.template_name, self._build_context(request))

    def post(self, request):
        action = request.POST.get("form_type")
        services = hospital_service.get_services()
        service_choices = build_service_choices(services)

        if action == "create_doctor":
            form = DoctorForm(request.POST, request.FILES, service_choices=service_choices)
            if form.is_valid():
                doctor_service.add_doctor(form.cleaned_data, request.FILES.get("image"), request=request)
                messages.success(request, "Doktor eklendi.")
                event_service.log_event(
                    "doctor_created",
                    request=request,
                    properties={"doctor_name": form.cleaned_data.get("name")},
                )
                return redirect("doctor_management")
            messages.error(request, "Doktor eklenemedi. Formu kontrol edin.")

        elif action == "update_doctor":
            form = DoctorForm(request.POST, request.FILES, service_choices=service_choices)
            if form.is_valid():
                doctor_service.update_doctor(form.cleaned_data["doctor_id"], form.cleaned_data, request.FILES.get("image"))
                messages.success(request, "Doktor bilgileri güncellendi.")
                event_service.log_event(
                    "doctor_updated",
                    request=request,
                    properties={"doctor_id": form.cleaned_data.get("doctor_id")},
                )
                return redirect("doctor_management")
            messages.error(request, "Doktor güncellenemedi.")

        elif action == "delete_doctor":
            doctor_id = request.POST.get("doctor_id")
            doctor_service.delete_doctor(doctor_id)
            messages.success(request, "Doktor silindi.")
            event_service.log_event(
                "doctor_deleted",
                request=request,
                properties={"doctor_id": doctor_id},
            )
            return redirect("doctor_management")

        elif action == "working_hours":
            form = DoctorWorkingHoursForm(request.POST)
            if form.is_valid() and self._validate_working_hours(form, request):
                working_hours = doctor_service.build_working_hours_from_form(form.cleaned_data)
                doctor_service.update_working_hours(form.cleaned_data["doctor_id"], working_hours)
                messages.success(request, "Çalışma saatleri güncellendi.")
                event_service.log_event(
                    "doctor_hours_updated",
                    request=request,
                    properties={"doctor_id": form.cleaned_data.get("doctor_id")},
                )
                return redirect("doctor_management")

        elif action == "toggle_active":
            doctor_id = request.POST.get("doctor_id")
            is_active = request.POST.get("is_active") == "true"
            doctor_service.toggle_active(doctor_id, is_active)
            messages.success(request, "Doktor durumu güncellendi.")
            event_service.log_event(
                "doctor_toggle_active",
                request=request,
                properties={"doctor_id": doctor_id, "is_active": is_active},
            )
            return redirect("doctor_management")

        elif action == "add_holiday":
            form = DoctorHolidayForm(request.POST)
            if form.is_valid():
                doctor_service.add_doctor_holiday(
                    form.cleaned_data["doctor_id"],
                    form.cleaned_data["date"].isoformat(),
                    form.cleaned_data["reason"],
                    request=request,
                )
                messages.success(request, "Doktor tatili eklendi.")
                event_service.log_event(
                    "doctor_holiday_added",
                    request=request,
                    properties={
                        "doctor_id": form.cleaned_data.get("doctor_id"),
                        "date": form.cleaned_data.get("date").isoformat(),
                    },
                )
                return redirect("doctor_management")
            messages.error(request, "Tatil eklenemedi.")

        elif action == "delete_holiday":
            doctor_service.delete_doctor_holiday(request.POST.get("holiday_id"))
            messages.success(request, "Tatil kaydı silindi.")
            event_service.log_event(
                "doctor_holiday_deleted",
                request=request,
                properties={"holiday_id": request.POST.get("holiday_id")},
            )
            return redirect("doctor_management")

        context = self._build_context(request)
        context["active_tab"] = action
        return render(request, self.template_name, context)

    def _build_context(self, request):
        services = hospital_service.get_services()
        service_choices = build_service_choices(services)
        doctors = doctor_service.get_doctors(request)
        holidays_map = doctor_service.get_doctor_holidays(request)

        doctor_cards = []
        for doctor in doctors:
            doctor.setdefault("isActive", True)
            general_form = DoctorForm(
                initial={
                    "doctor_id": doctor["id"],
                    "name": doctor["name"],
                    "surname": doctor["surname"],
                    "bio": doctor.get("bio", ""),
                    "services": doctor.get("services", []),
                    "is_active": doctor.get("isActive", True),
                },
                service_choices=service_choices,
            )
            working_form = DoctorWorkingHoursForm(
                initial=doctor_service.build_initial_working_hours(doctor)
            )
            holiday_form = DoctorHolidayForm(initial={"doctor_id": doctor["id"]})

            doctor_cards.append(
                {
                    "data": doctor,
                    "general_form": general_form,
                    "working_form": working_form,
                    "holiday_form": holiday_form,
                    "holidays": holidays_map.get(doctor["id"], []),
                }
            )

        context = {
            "page_title": "Doktor Yönetimi",
            "doctor_cards": doctor_cards,
            "doctor_create_form": DoctorForm(service_choices=service_choices),
        }
        return context

    def _validate_working_hours(self, form, request) -> bool:
        """Çalışma saatleri formunu validate eder."""
        return validate_working_hours_form(form, DAYS, request)

