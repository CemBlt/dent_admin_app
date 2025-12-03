from datetime import datetime
from django.shortcuts import render, redirect
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from django.core.paginator import Paginator
from .auth_views import login_required
from ..forms import AppointmentFilterForm, AppointmentStatusForm
from ..utils import build_doctor_choices, build_service_choices, format_date
from ..services import appointment_service, doctor_service, hospital_service, user_service, event_service

class AppointmentManagementView(View):
    template_name = "panel/appointment_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)
    
    STATUS_LABELS = {
        "completed": ("Tamamlandı", "completed"),
        "cancelled": ("İptal", "cancelled"),
        "planned": ("Planlandı", "planned"),
    }

    def get(self, request):
        context = self._build_context(request)
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("form_type")
        if action == "update_status":
            form = AppointmentStatusForm(request.POST)
            if form.is_valid():
                appointment_service.update_appointment(
                    form.cleaned_data["appointment_id"],
                    status=form.cleaned_data["status"],
                )
                messages.success(request, "Randevu durumu güncellendi.")
                event_service.log_event(
                    "appointment_status_updated",
                    request=request,
                    properties={
                        "appointment_id": form.cleaned_data["appointment_id"],
                        "status": form.cleaned_data["status"],
                    },
                )
                return redirect("appointment_management")
            messages.error(request, "Durum güncellenemedi.")

        elif action == "delete_appointment":
            appointment_service.delete_appointment(request.POST.get("appointment_id"))
            messages.success(request, "Randevu silindi.")
            event_service.log_event(
                "appointment_deleted",
                request=request,
                properties={"appointment_id": request.POST.get("appointment_id")},
            )
            return redirect("appointment_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        doctors = doctor_service.get_doctors(request)
        services = hospital_service.get_services()
        doctor_choices = build_doctor_choices(doctors)
        service_choices = build_service_choices(services)

        filter_form = AppointmentFilterForm(
            request.GET or None,
            doctor_choices=doctor_choices,
            service_choices=service_choices,
        )

        filters = filter_form.cleaned_data if filter_form.is_valid() else {}
        start_date = filters.get("start_date")
        end_date = filters.get("end_date")
        per_page = filters.get("per_page") or request.GET.get("per_page", "10")
        
        appointments = appointment_service.filter_appointments(
            status=filters.get("status") or None,
            doctor_id=filters.get("doctor") or None,
            service_id=filters.get("service") or None,
            start_date=start_date,
            end_date=end_date,
            request=request,
        )

        enriched = self._enrich_appointments(appointments, doctors, services)
        enriched = self._sort_appointments(enriched)

        per_page = int(per_page or "10")
        paginator = Paginator(enriched, per_page)
        page_number = request.GET.get("page", 1)
        try:
            page_obj = paginator.get_page(page_number)
        except:
            page_obj = paginator.get_page(1)

        if filter_form.is_valid():
            filter_form.fields["per_page"].initial = str(per_page)
        else:
            filter_form.fields["per_page"].initial = request.GET.get("per_page", "10")
        
        context = {
            "page_title": "Randevu Yönetimi",
            "filter_form": filter_form,
            "appointments": page_obj,
            "summary": appointment_service.get_summary(request=request),
            "paginator": paginator,
        }
        return context
    
    def _sort_appointments(self, appointments):
        upcoming = []
        cancelled = []
        completed = []

        def parse_datetime(apt):
            try:
                date_str = apt["data"].get("date", "")
                time_str = apt["data"].get("time", "00:00")
                date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
                time_obj = datetime.strptime(time_str, "%H:%M").time()
                return datetime.combine(date_obj, time_obj)
            except (ValueError, KeyError):
                return datetime.now()

        now = datetime.now()

        for apt in appointments:
            status = apt["data"].get("status", "completed")
            apt_datetime = parse_datetime(apt)

            if status == "cancelled":
                cancelled.append((apt_datetime, apt))
            elif apt_datetime >= now:
                upcoming.append((apt_datetime, apt))
            else:
                completed.append((apt_datetime, apt))

        upcoming.sort(key=lambda item: item[0])
        cancelled.sort(key=lambda item: item[0], reverse=True)
        completed.sort(key=lambda item: item[0], reverse=True)

        ordered = upcoming + cancelled + completed
        return [item[1] for item in ordered]

    def _enrich_appointments(self, appointments, doctors, services):
        doctor_map = {doc["id"]: doc for doc in doctors}
        service_map = {svc["id"]: svc for svc in services}
        user_map = user_service.get_user_map()
        enriched = []
        for apt in appointments:
            doctor = doctor_map.get(apt["doctorId"])
            service = service_map.get(apt["service"])
            user = user_map.get(apt["userId"])
            status = apt["status"] or "completed"
            try:
                date_str = apt.get("date", "")
                time_str = apt.get("time", "00:00")
                apt_datetime = datetime.strptime(
                    f"{date_str} {time_str}", "%Y-%m-%d %H:%M"
                )
            except (ValueError, TypeError):
                apt_datetime = None

            if status == "cancelled":
                status_label, status_class = self.STATUS_LABELS["cancelled"]
            else:
                if apt_datetime and apt_datetime >= datetime.now():
                    status_label, status_class = self.STATUS_LABELS["planned"]
                else:
                    status_label, status_class = self.STATUS_LABELS["completed"]
            
            formatted_date = format_date(apt.get("date", ""), "%d.%m.%Y")
            
            enriched.append(
                {
                    "data": apt,
                    "patient": f"{user['name']} {user['surname']}" if user else "Hasta",
                    "doctor": f"{doctor['name']} {doctor['surname']}" if doctor else "Doktor",
                    "service": service["name"] if service else "Hizmet",
                    "status_label": status_label,
                    "status_class": status_class,
                    "formatted_date": formatted_date,
                    "status_form": AppointmentStatusForm(
                        initial={
                            "appointment_id": apt["id"],
                            "status": apt["status"],
                        }
                    ),
                }
            )
        return enriched

