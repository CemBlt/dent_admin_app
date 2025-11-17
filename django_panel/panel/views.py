from django.contrib import messages
from django.shortcuts import redirect, render
from django.views import View

from .forms import (
    DoctorForm,
    DoctorHolidayForm,
    DoctorWorkingHoursForm,
    GalleryAddForm,
    HolidayAddForm,
    HospitalGeneralForm,
    HospitalServicesForm,
    WorkingHoursForm,
    DAYS,
)
from .services import doctor_service, hospital_service
from .services.dashboard_service import load_dashboard_context


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
