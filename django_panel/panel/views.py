from datetime import datetime

from django.contrib import messages
from django.http import HttpResponse, JsonResponse
from django.shortcuts import redirect, render
from django.views import View
from django.views.decorators.http import require_GET

from .forms import (
    AppearanceSettingsForm,
    AppointmentFilterForm,
    AppointmentNoteForm,
    AppointmentStatusForm,
    DataManagementForm,
    DoctorForm,
    DoctorHolidayForm,
    DoctorWorkingHoursForm,
    GalleryAddForm,
    GeneralSettingsForm,
    HolidayAddForm,
    HospitalGeneralForm,
    HospitalServicesForm,
    NotificationSettingsForm,
    ReviewFilterForm,
    ReviewReplyForm,
    ScheduleFilterForm,
    ScheduleHolidayForm,
    SecuritySettingsForm,
    ServiceAssignmentForm,
    ServiceForm,
    WorkingHoursForm,
    DAYS,
)
from .services import (
    appointment_service,
    doctor_service,
    hospital_service,
    user_service,
    location_service,
)
from .services.dashboard_service import load_dashboard_context
from .services import schedule_service, service_service, review_service, settings_service


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
            province_choices = location_service.as_choice_tuples(location_service.get_provinces())
            province_id = request.POST.get("province")
            district_id = request.POST.get("district")
            district_choices = location_service.as_choice_tuples(location_service.get_districts(province_id))
            neighborhood_choices = location_service.as_choice_tuples(location_service.get_neighborhoods(district_id))
            form = HospitalGeneralForm(
                request.POST,
                request.FILES,
                province_choices=province_choices,
                district_choices=district_choices,
                neighborhood_choices=neighborhood_choices,
            )
            if form.is_valid():
                try:
                    hospital_service.update_general_info(
                        hospital,
                        form.cleaned_data,
                        request.FILES.get("logo"),
                    )
                except ValueError as exc:
                    messages.error(request, str(exc))
                else:
                    messages.success(request, "Genel bilgiler güncellendi.")
                    return redirect("hospital_settings")
            else:
                messages.error(request, "Genel bilgiler güncellenemedi. Lütfen formu kontrol edin.")
            context = self._build_context(general_form=form)
            context["active_tab"] = "general"
            return render(request, self.template_name, context)

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

    def _build_context(self, general_form: HospitalGeneralForm | None = None):
        hospital = hospital_service.get_hospital()
        services = hospital_service.get_services()
        holidays = hospital_service.get_holidays()
        province_choices = location_service.as_choice_tuples(location_service.get_provinces())
        selected_province = hospital.get("provinceId")
        selected_district = hospital.get("districtId")
        district_choices = location_service.as_choice_tuples(location_service.get_districts(selected_province))
        neighborhood_choices = location_service.as_choice_tuples(location_service.get_neighborhoods(selected_district))

        if general_form is None:
            general_form = HospitalGeneralForm(
                initial={
                    "name": hospital.get("name"),
                    "address": hospital.get("address"),
                    "province": hospital.get("provinceId"),
                    "district": hospital.get("districtId"),
                    "neighborhood": hospital.get("neighborhoodId"),
                    "latitude": hospital.get("latitude"),
                    "longitude": hospital.get("longitude"),
                    "phone": hospital.get("phone"),
                    "email": hospital.get("email"),
                    "description": hospital.get("description"),
                },
                province_choices=province_choices,
                district_choices=district_choices,
                neighborhood_choices=neighborhood_choices,
            )

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
        if action == "update_service":
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
            "doctor_choices": doctor_choices,
            "hospital_choices": hospital_choices,
        }
        return context


class ReviewManagementView(View):
    template_name = "panel/review_management.html"

    def get(self, request):
        context = self._build_context(request)
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("form_type")

        if action == "add_reply":
            form = ReviewReplyForm(request.POST)
            if form.is_valid():
                review_id = form.cleaned_data["review_id"]
                reply_text = form.cleaned_data["reply"]
                review_service.add_reply(review_id, reply_text)
                messages.success(request, "Yanıt eklendi")
                return redirect("review_management")

        elif action == "edit_reply":
            form = ReviewReplyForm(request.POST)
            if form.is_valid():
                review_id = form.cleaned_data["review_id"]
                reply_text = form.cleaned_data["reply"]
                review_service.add_reply(review_id, reply_text)
                messages.success(request, "Yanıt güncellendi")
                return redirect("review_management")

        elif action == "delete_reply":
            review_id = request.POST.get("review_id")
            if review_id:
                review_service.delete_reply(review_id)
                messages.success(request, "Yanıt silindi")
                return redirect("review_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        doctors = doctor_service.get_doctors()
        doctor_choices = [(doc["id"], f"{doc['name']} {doc['surname']}") for doc in doctors]

        # Filtre formu
        filter_form = ReviewFilterForm(
            request.GET,
            doctor_choices=doctor_choices,
        )

        # Filtreleme parametreleri
        doctor_id = request.GET.get("doctor") or None
        min_rating = int(request.GET.get("min_rating")) if request.GET.get("min_rating") else None
        max_rating = int(request.GET.get("max_rating")) if request.GET.get("max_rating") else None
        date_from = request.GET.get("date_from") or None
        date_to = request.GET.get("date_to") or None
        has_reply_str = request.GET.get("has_reply")
        has_reply = None
        if has_reply_str == "true":
            has_reply = True
        elif has_reply_str == "false":
            has_reply = False

        # Yorumları getir
        reviews = review_service.get_reviews_with_details(
            doctor_id=doctor_id,
            min_rating=min_rating,
            max_rating=max_rating,
            date_from=date_from,
            date_to=date_to,
            has_reply=has_reply,
        )

        # İstatistikler
        stats = review_service.get_review_statistics()

        # Her yorum için yanıt formu ve tarih formatını düzelt
        review_cards = []
        for review in reviews:
            # Tarih formatını düzelt (ISO string'den datetime'a)
            created_at = review.get("createdAt", "")
            if created_at:
                try:
                    from datetime import datetime
                    dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    review["created_at_dt"] = dt
                except (ValueError, AttributeError):
                    review["created_at_dt"] = None
            else:
                review["created_at_dt"] = None
            
            replied_at = review.get("repliedAt", "")
            if replied_at:
                try:
                    from datetime import datetime
                    dt = datetime.fromisoformat(replied_at.replace("Z", "+00:00"))
                    review["replied_at_dt"] = dt
                except (ValueError, AttributeError):
                    review["replied_at_dt"] = None
            else:
                review["replied_at_dt"] = None
            
            reply_form = ReviewReplyForm(initial={
                "review_id": review["id"],
                "reply": review.get("reply", ""),
            })
            review_cards.append({
                "data": review,
                "reply_form": reply_form,
            })

        hospital = hospital_service.get_hospital()

        context = {
            "page_title": "Yorumlar & Yanıtlar",
            "hospital": hospital,
            "filter_form": filter_form,
            "review_cards": review_cards,
            "statistics": stats,
            "doctor_choices": doctor_choices,
        }
        return context


class SettingsView(View):
    template_name = "panel/settings.html"

    def get(self, request):
        context = self._build_context()
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("form_type")
        settings_data = settings_service.get_settings()
        hospital_choices = settings_service.get_hospital_choices()

        if action == "general":
            form = GeneralSettingsForm(request.POST, hospital_choices=hospital_choices)
            if form.is_valid():
                updates = {
                    "active_hospital_id": form.cleaned_data["active_hospital_id"],
                    "panel_title": form.cleaned_data["panel_title"],
                    "date_format": form.cleaned_data["date_format"],
                    "time_format": form.cleaned_data["time_format"],
                    "language": form.cleaned_data["language"],
                }
                settings_service.update_settings("general", updates)
                messages.success(request, "Genel ayarlar güncellendi")
                return redirect("settings")

        elif action == "notifications":
            form = NotificationSettingsForm(request.POST)
            if form.is_valid():
                updates = {
                    "email_enabled": form.cleaned_data.get("email_enabled", False),
                    "new_appointment": form.cleaned_data.get("new_appointment", False),
                    "new_review": form.cleaned_data.get("new_review", False),
                    "appointment_reminder": form.cleaned_data.get("appointment_reminder", False),
                    "reminder_hours_before": form.cleaned_data["reminder_hours_before"],
                }
                settings_service.update_settings("notifications", updates)
                messages.success(request, "Bildirim ayarları güncellendi")
                return redirect("settings")

        elif action == "data_management":
            form = DataManagementForm(request.POST)
            if form.is_valid():
                updates = {
                    "backup_enabled": form.cleaned_data.get("backup_enabled", False),
                    "auto_backup_days": form.cleaned_data["auto_backup_days"],
                }
                settings_service.update_settings("data_management", updates)
                messages.success(request, "Veri yönetimi ayarları güncellendi")
                return redirect("settings")

        elif action == "security":
            form = SecuritySettingsForm(request.POST)
            if form.is_valid():
                updates = {
                    "session_timeout_minutes": form.cleaned_data["session_timeout_minutes"],
                }
                settings_service.update_settings("security", updates)
                messages.success(request, "Güvenlik ayarları güncellendi")
                return redirect("settings")

        elif action == "appearance":
            form = AppearanceSettingsForm(request.POST)
            if form.is_valid():
                updates = {
                    "theme": form.cleaned_data["theme"],
                    "show_dashboard_widgets": form.cleaned_data.get("show_dashboard_widgets", False),
                    "records_per_page": form.cleaned_data["records_per_page"],
                }
                settings_service.update_settings("appearance", updates)
                messages.success(request, "Görünüm ayarları güncellendi")
                return redirect("settings")

        elif action == "export_data":
            # Veri export
            json_data = settings_service.export_data_as_json()
            response = HttpResponse(json_data, content_type="application/json")
            response["Content-Disposition"] = 'attachment; filename="panel_backup.json"'
            return response

        context = self._build_context()
        return render(request, self.template_name, context)

    def _build_context(self):
        settings_data = settings_service.get_settings()
        hospital_choices = settings_service.get_hospital_choices()
        data_stats = settings_service.get_data_statistics()
        hospital = hospital_service.get_hospital()

        # Formları mevcut ayarlarla doldur
        general_form = GeneralSettingsForm(
            initial=settings_data.get("general", {}),
            hospital_choices=hospital_choices,
        )
        notification_form = NotificationSettingsForm(
            initial=settings_data.get("notifications", {}),
        )
        data_management_form = DataManagementForm(
            initial=settings_data.get("data_management", {}),
        )
        security_form = SecuritySettingsForm(
            initial=settings_data.get("security", {}),
        )
        appearance_form = AppearanceSettingsForm(
            initial=settings_data.get("appearance", {}),
        )

        context = {
            "page_title": "Ayarlar",
            "hospital": hospital,
            "general_form": general_form,
            "notification_form": notification_form,
            "data_management_form": data_management_form,
            "security_form": security_form,
            "appearance_form": appearance_form,
            "data_statistics": data_stats,
        }
        return context


@require_GET
def location_provinces(request):
    return JsonResponse({"results": location_service.get_provinces()})


@require_GET
def location_districts(request, province_id: str):
    return JsonResponse({"results": location_service.get_districts(province_id)})


@require_GET
def location_neighborhoods(request, district_id: str):
    return JsonResponse({"results": location_service.get_neighborhoods(district_id)})
