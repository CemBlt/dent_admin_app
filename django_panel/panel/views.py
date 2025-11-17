from datetime import datetime

from django.contrib import messages
from django.shortcuts import redirect, render
from django.views import View

from .forms import (
    AppointmentFilterForm,
    AppointmentNoteForm,
    AppointmentStatusForm,
    DoctorForm,
    DoctorHolidayForm,
    DoctorWorkingHoursForm,
    GalleryAddForm,
    HolidayAddForm,
    HospitalGeneralForm,
    HospitalServicesForm,
    ScheduleFilterForm,
    ScheduleHolidayForm,
    ServiceAssignmentForm,
    ServiceForm,
    WorkingHoursForm,
    DAYS,
)
from .services import appointment_service, doctor_service, hospital_service, user_service
from .services.dashboard_service import load_dashboard_context
from .services import schedule_service, service_service


def dashboard(request):
    """Panel ana sayfası: JSON verilerinden özet metrikleri oluşturur."""
    context = load_dashboard_context()
    context["page_title"] = "Genel Bakış"
    return render(request, "panel/dashboard.html", context)


class HospitalSettingsView(View):
    template_name = "panel/hospital_settings.html"

    def get(self, request):
        context = self._build_context()
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("form_type")
        hospital = hospital_service.get_hospital()
        services = hospital_service.get_services()

        if action == "general":
            form = HospitalGeneralForm(request.POST, request.FILES)
            if form.is_valid():
                hospital_service.update_general_info(hospital, form.cleaned_data, request.FILES.get("logo"))
                messages.success(request, "Genel bilgiler güncellendi.")
                return redirect("hospital_settings")
            messages.error(request, "Genel bilgiler güncellenemedi. Lütfen formu kontrol edin.")

        elif action == "services":
            form = HospitalServicesForm(request.POST, service_choices=[(s["id"], s["name"]) for s in services])
            if form.is_valid():
                hospital_service.update_services(hospital, form.cleaned_data.get("services", []))
                messages.success(request, "Hizmet listesi güncellendi.")
                return redirect("hospital_settings")
            messages.error(request, "Hizmetler güncellenemedi.")

        elif action == "working_hours":
            form = WorkingHoursForm(request.POST)
            if form.is_valid() and self._validate_working_hours(form, request):
                working_hours = hospital_service.build_working_hours_from_form(form.cleaned_data)
                hospital_service.update_working_hours(hospital, working_hours)
                messages.success(request, "Çalışma saatleri güncellendi.")
                return redirect("hospital_settings")

        elif action == "gallery_add":
            form = GalleryAddForm(request.POST, request.FILES)
            if form.is_valid():
                try:
                    hospital_service.add_gallery_image(hospital, request.FILES["image"])
                    messages.success(request, "Galeriye görsel eklendi.")
                except ValueError as exc:
                    messages.error(request, str(exc))
                return redirect("hospital_settings")
            messages.error(request, "Galeri görseli eklenemedi.")

        elif action == "gallery_remove":
            try:
                index = int(request.POST.get("index", -1))
                hospital_service.remove_gallery_image(hospital, index)
                messages.success(request, "Galeri görseli kaldırıldı.")
            except ValueError:
                messages.error(request, "Geçersiz galeri öğesi.")
            return redirect("hospital_settings")

        elif action == "holiday_add":
            form = HolidayAddForm(request.POST)
            if form.is_valid():
                hospital_service.add_holiday(
                    form.cleaned_data["date"].isoformat(),
                    form.cleaned_data["reason"],
                )
                messages.success(request, "Tatil bilgisi eklendi.")
                return redirect("hospital_settings")
            messages.error(request, "Tatil bilgisi eklenemedi.")

        elif action == "holiday_delete":
            holiday_id = request.POST.get("holiday_id")
            hospital_service.delete_holiday(holiday_id)
            messages.success(request, "Tatil kaydı silindi.")
            return redirect("hospital_settings")

        context = self._build_context()
        context["active_tab"] = action
        return render(request, self.template_name, context)

    def _build_context(self):
        hospital = hospital_service.get_hospital()
        services = hospital_service.get_services()
        holidays = hospital_service.get_holidays()

        general_form = HospitalGeneralForm(initial={
            "name": hospital.get("name"),
            "address": hospital.get("address"),
            "phone": hospital.get("phone"),
            "email": hospital.get("email"),
            "description": hospital.get("description"),
        })

        services_form = HospitalServicesForm(
            initial={"services": hospital.get("services", [])},
            service_choices=[(s["id"], s["name"]) for s in services],
        )

        working_hours_form = WorkingHoursForm(
            initial=hospital_service.build_initial_working_hours(hospital)
        )

        day_fields = []
        for key, label in DAYS:
            day_fields.append({
                "label": label,
                "open_field": working_hours_form[f"{key}_is_open"],
                "start_field": working_hours_form[f"{key}_start"],
                "end_field": working_hours_form[f"{key}_end"],
            })

        gallery_list = hospital.get("gallery") or []

        context = {
            "page_title": "Hastane Bilgileri",
            "hospital": hospital,
            "gallery_list": gallery_list,
            "services_catalog": services,
            "holidays": holidays,
            "general_form": general_form,
            "services_form": services_form,
            "working_hours_form": working_hours_form,
            "day_fields": day_fields,
            "gallery_add_form": GalleryAddForm(),
            "holiday_add_form": HolidayAddForm(),
            "days": DAYS,
        }
        return context

    def _validate_working_hours(self, form, request) -> bool:
        valid = True
        for key, label in DAYS:
            is_open = form.cleaned_data.get(f"{key}_is_open")
            start = form.cleaned_data.get(f"{key}_start")
            end = form.cleaned_data.get(f"{key}_end")
            if is_open and (not start or not end):
                form.add_error(f"{key}_start", f"{label} için başlangıç/bitiş saatlerini giriniz.")
                valid = False
            if start and end and start >= end:
                form.add_error(f"{key}_start", f"{label} için başlangıç saati bitişten küçük olmalıdır.")
                valid = False
        if not valid:
            messages.error(request, "Çalışma saatleri doğrulaması başarısız.")
        return valid


class DoctorManagementView(View):
    template_name = "panel/doctor_management.html"

    def get(self, request):
        return render(request, self.template_name, self._build_context())

    def post(self, request):
        action = request.POST.get("form_type")
        services = hospital_service.get_services()
        service_choices = [(s["id"], s["name"]) for s in services]

        if action == "create_doctor":
            form = DoctorForm(request.POST, request.FILES, service_choices=service_choices)
            if form.is_valid():
                doctor_service.add_doctor(form.cleaned_data, request.FILES.get("image"))
                messages.success(request, "Doktor eklendi.")
                return redirect("doctor_management")
            messages.error(request, "Doktor eklenemedi. Formu kontrol edin.")

        elif action == "update_doctor":
            form = DoctorForm(request.POST, request.FILES, service_choices=service_choices)
            if form.is_valid():
                doctor_service.update_doctor(form.cleaned_data["doctor_id"], form.cleaned_data, request.FILES.get("image"))
                messages.success(request, "Doktor bilgileri güncellendi.")
                return redirect("doctor_management")
            messages.error(request, "Doktor güncellenemedi.")

        elif action == "delete_doctor":
            doctor_id = request.POST.get("doctor_id")
            doctor_service.delete_doctor(doctor_id)
            messages.success(request, "Doktor silindi.")
            return redirect("doctor_management")

        elif action == "working_hours":
            form = DoctorWorkingHoursForm(request.POST)
            if form.is_valid() and self._validate_working_hours(form, request):
                working_hours = doctor_service.build_working_hours_from_form(form.cleaned_data)
                doctor_service.update_working_hours(form.cleaned_data["doctor_id"], working_hours)
                messages.success(request, "Çalışma saatleri güncellendi.")
                return redirect("doctor_management")

        elif action == "toggle_active":
            doctor_id = request.POST.get("doctor_id")
            is_active = request.POST.get("is_active") == "true"
            doctor_service.toggle_active(doctor_id, is_active)
            messages.success(request, "Doktor durumu güncellendi.")
            return redirect("doctor_management")

        elif action == "add_holiday":
            form = DoctorHolidayForm(request.POST)
            if form.is_valid():
                doctor_service.add_doctor_holiday(
                    form.cleaned_data["doctor_id"],
                    form.cleaned_data["date"].isoformat(),
                    form.cleaned_data["reason"],
                )
                messages.success(request, "Doktor tatili eklendi.")
                return redirect("doctor_management")
            messages.error(request, "Tatil eklenemedi.")

        elif action == "delete_holiday":
            doctor_service.delete_doctor_holiday(request.POST.get("holiday_id"))
            messages.success(request, "Tatil kaydı silindi.")
            return redirect("doctor_management")

        context = self._build_context()
        context["active_tab"] = action
        return render(request, self.template_name, context)

    def _build_context(self):
        hospital = hospital_service.get_hospital()
        services = hospital_service.get_services()
        service_choices = [(s["id"], s["name"]) for s in services]
        doctors = doctor_service.get_doctors()
        holidays_map = doctor_service.get_doctor_holidays()

        doctor_cards = []
        for doctor in doctors:
            doctor.setdefault("isActive", True)
            general_form = DoctorForm(
                initial={
                    "doctor_id": doctor["id"],
                    "name": doctor["name"],
                    "surname": doctor["surname"],
                    "specialty": doctor["specialty"],
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
            "hospital": hospital,
            "doctor_cards": doctor_cards,
            "doctor_create_form": DoctorForm(service_choices=service_choices),
        }
        return context

    def _validate_working_hours(self, form, request) -> bool:
        valid = True
        for key, label in DAYS:
            is_open = form.cleaned_data.get(f"{key}_is_open")
            start = form.cleaned_data.get(f"{key}_start")
            end = form.cleaned_data.get(f"{key}_end")
            if is_open and (not start or not end):
                form.add_error(f"{key}_start", f"{label} için başlangıç/bitiş saatlerini giriniz.")
                valid = False
            if start and end and start >= end:
                form.add_error(f"{key}_start", f"{label} için başlangıç saati bitişten küçük olmalıdır.")
                valid = False
        if not valid:
            messages.error(request, "Çalışma saatleri doğrulaması başarısız.")
        return valid


class AppointmentManagementView(View):
    template_name = "panel/appointment_management.html"
    STATUS_LABELS = {
        "pending": ("Bekleyen", "pending"),
        "completed": ("Tamamlandı", "completed"),
        "cancelled": ("İptal", "cancelled"),
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
                return redirect("appointment_management")
            messages.error(request, "Durum güncellenemedi.")

        elif action == "update_note":
            form = AppointmentNoteForm(request.POST)
            if form.is_valid():
                appointment_service.update_appointment(
                    form.cleaned_data["appointment_id"],
                    notes=form.cleaned_data["notes"],
                )
                messages.success(request, "Randevu notu kaydedildi.")
                return redirect("appointment_management")
            messages.error(request, "Not kaydedilemedi.")

        elif action == "delete_appointment":
            appointment_service.delete_appointment(request.POST.get("appointment_id"))
            messages.success(request, "Randevu silindi.")
            return redirect("appointment_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        hospital = hospital_service.get_hospital()
        doctors = doctor_service.get_doctors()
        services = hospital_service.get_services()
        doctor_choices = [(doc["id"], f"{doc['name']} {doc['surname']}") for doc in doctors]
        service_choices = [(svc["id"], svc["name"]) for svc in services]

        filter_form = AppointmentFilterForm(
            request.GET or None,
            doctor_choices=doctor_choices,
            service_choices=service_choices,
        )

        filters = filter_form.cleaned_data if filter_form.is_valid() else {}
        start_date = filters.get("start_date")
        end_date = filters.get("end_date")
        appointments = appointment_service.filter_appointments(
            status=filters.get("status") or None,
            doctor_id=filters.get("doctor") or None,
            service_id=filters.get("service") or None,
            start_date=start_date,
            end_date=end_date,
        )

        enriched = self._enrich_appointments(appointments, doctors, services)

        context = {
            "page_title": "Randevu Yönetimi",
            "hospital": hospital,
            "filter_form": filter_form,
            "appointments": enriched,
            "summary": appointment_service.get_summary(),
        }
        return context

    def _enrich_appointments(self, appointments, doctors, services):
        doctor_map = {doc["id"]: doc for doc in doctors}
        service_map = {svc["id"]: svc for svc in services}
        user_map = user_service.get_user_map()
        enriched = []
        for apt in appointments:
            doctor = doctor_map.get(apt["doctorId"])
            service = service_map.get(apt["service"])
            user = user_map.get(apt["userId"])
            status_label, status_class = self.STATUS_LABELS.get(
                apt["status"], (apt["status"], "pending")
            )
            enriched.append(
                {
                    "data": apt,
                    "patient": f"{user['name']} {user['surname']}" if user else "Hasta",
                    "doctor": f"{doctor['name']} {doctor['surname']}" if doctor else "Doktor",
                    "service": service["name"] if service else "Hizmet",
                    "status_label": status_label,
                    "status_class": status_class,
                    "note_form": AppointmentNoteForm(
                        initial={
                            "appointment_id": apt["id"],
                            "notes": apt.get("notes", ""),
                        }
                    ),
                    "status_form": AppointmentStatusForm(
                        initial={
                            "appointment_id": apt["id"],
                            "status": apt["status"],
                        }
                    ),
                }
            )
        return enriched


class ScheduleManagementView(View):
    template_name = "panel/schedule_management.html"

    def get(self, request):
        from datetime import date

        today = date.today()
        year = int(request.GET.get("year", today.year))
        month = int(request.GET.get("month", today.month))
        selected_doctor_id = request.GET.get("doctor", "")

        doctors = doctor_service.get_doctors()
        doctor_choices = [(doc["id"], f"{doc['name']} {doc['surname']}") for doc in doctors]

        filter_form = ScheduleFilterForm(
            initial={"year": year, "month": month, "doctor": selected_doctor_id},
            doctor_choices=doctor_choices,
        )

        calendar_data = schedule_service.build_calendar_data(
            year, month, selected_doctor_id if selected_doctor_id else None
        )

        hospital = hospital_service.get_hospital()
        holiday_form = ScheduleHolidayForm(doctor_choices=doctor_choices)

        context = {
            "page_title": "Çalışma Takvimi",
            "hospital": hospital,
            "calendar": calendar_data,
            "filter_form": filter_form,
            "holiday_form": holiday_form,
            "doctors": doctors,
        }
        return render(request, self.template_name, context)

    def post(self, request):
        from datetime import date

        form_type = request.POST.get("form_type")
        if form_type == "add_holiday":
            form = ScheduleHolidayForm(request.POST)
            if form.is_valid():
                holiday_date = form.cleaned_data["date"]
                reason = form.cleaned_data["reason"]
                doctor_id = form.cleaned_data.get("doctor_id") or None

                if doctor_id:
                    doctor_service.add_doctor_holiday(doctor_id, holiday_date.isoformat(), reason)
                else:
                    hospital_service.add_holiday(holiday_date.isoformat(), reason)

                messages.success(request, "Tatil başarıyla eklendi.")
            else:
                messages.error(request, "Tatil eklenirken hata oluştu.")
        elif form_type == "delete_holiday":
            holiday_id = request.POST.get("holiday_id")
            if holiday_id:
                hospital_service.delete_holiday(holiday_id)
                messages.success(request, "Tatil silindi.")

        today = date.today()
        year = int(request.POST.get("year", request.GET.get("year", today.year)))
        month = int(request.POST.get("month", request.GET.get("month", today.month)))
        doctor = request.POST.get("doctor", request.GET.get("doctor", ""))
        params = f"year={year}&month={month}"
        if doctor:
            params += f"&doctor={doctor}"
        return redirect(f"/schedule/?{params}")

class ServiceManagementView(View):
    template_name = "panel/service_management.html"

    def get(self, request):
        return render(request, self.template_name, self._build_context())

    def post(self, request):
        action = request.POST.get("form_type")
        if action == "create_service":
            form = ServiceForm(request.POST)
            if form.is_valid():
                service_service.add_service(form.cleaned_data)
                messages.success(request, "Hizmet oluşturuldu")
                return redirect("service_management")
            messages.error(request, "Hizmet oluşturulamadı")

        elif action == "update_service":
            form = ServiceForm(request.POST)
            if form.is_valid():
                service_service.update_service(form.cleaned_data["service_id"], form.cleaned_data)
                messages.success(request, "Hizmet güncellendi")
                return redirect("service_management")
            messages.error(request, "Hizmet güncellenemedi")

        elif action == "delete_service":
            service_service.delete_service(request.POST.get("service_id"))
            messages.success(request, "Hizmet silindi")
            return redirect("service_management")

        elif action == "update_assignments":
            doctors = request.POST.getlist("doctors")
            hospitals = request.POST.getlist("hospitals")
            service_id = request.POST.get("service_id")
            service_service.update_doctor_assignments(service_id, doctors)
            service_service.update_hospital_assignments(service_id, hospitals)
            messages.success(request, "Atamalar güncellendi")
            return redirect("service_management")

        context = self._build_context()
        return render(request, self.template_name, context)

    def _build_context(self):
        services = service_service.get_services()
        doctors = doctor_service.get_doctors()
        hospitals = hospital_service.get_hospitals()
        hospital = hospital_service.get_hospital()

        doctor_choices = [(doc["id"], f"{doc['name']} {doc['surname']}") for doc in doctors]
        hospital_choices = [(h["id"], h["name"]) for h in hospitals]

        service_cards = []
        for service in services:
            general_form = ServiceForm(initial={
                "service_id": service["id"],
                "name": service["name"],
                "description": service.get("description", ""),
                "price": service.get("price", 0),
            })
            assigned_doctors = [doc["id"] for doc in doctors if service["id"] in doc.get("services", [])]
            assigned_hospitals = [h["id"] for h in hospitals if service["id"] in h.get("services", [])]
            assignment_form = ServiceAssignmentForm(
                initial={
                    "service_id": service["id"],
                    "doctors": assigned_doctors,
                    "hospitals": assigned_hospitals,
                },
                doctor_choices=doctor_choices,
                hospital_choices=hospital_choices,
            )
            service_cards.append({
                "data": service,
                "general_form": general_form,
                "assignment_form": assignment_form,
                "assigned_doctors": [doc for doc in doctors if doc["id"] in assigned_doctors],
                "assigned_hospitals": [h for h in hospitals if h["id"] in assigned_hospitals],
            })

        context = {
            "page_title": "Hizmetler",
            "hospital": hospital,
            "service_cards": service_cards,
            "create_form": ServiceForm(),
            "doctor_choices": doctor_choices,
            "hospital_choices": hospital_choices,
        }
        return context
