from datetime import datetime, date
from functools import wraps

from django.contrib import messages
from django.core.paginator import Paginator
from django.http import HttpResponse, JsonResponse
from django.shortcuts import redirect, render
from django.utils.decorators import method_decorator
from django.views import View
from django.views.decorators.http import require_GET

from .forms import (
    AppearanceSettingsForm,
    AppointmentFilterForm,
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
from .utils import (
    build_doctor_choices,
    build_service_choices,
    format_date,
    validate_working_hours_form,
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
from .services.auth_service import sign_in
from .services.hospital_registration_service import register_hospital
from .services.supabase_client import get_supabase_client
from .forms import LoginForm, HospitalRegistrationForm


# Login required decorator
def login_required(view_func):
    """Kullanıcının giriş yapmış olmasını kontrol eder."""
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not request.session.get('user_id') or not request.session.get('hospital_id'):
            messages.warning(request, "Lütfen giriş yapın.")
            return redirect('login')
        return view_func(request, *args, **kwargs)
    return _wrapped_view


def login_view(request):
    """Kullanıcı giriş sayfası."""
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            hospital_code = form.cleaned_data['hospital_code']
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            
            try:
                # 1. Hospital code'dan hospital_id bul
                supabase = get_supabase_client()
                hospital_result = supabase.table("hospitals").select("id, status, name").eq("hospital_code", hospital_code).single().execute()
                
                if not hospital_result.data:
                    messages.error(request, "Geçersiz hastane kodu.")
                    return render(request, "panel/login.html", {"form": form})
                
                hospital = hospital_result.data
                
                # 2. Hastane onaylanmış mı kontrol et
                if hospital.get("status") != "approved":
                    messages.error(request, "Hastaneniz henüz onaylanmamış. Lütfen onay bekleyin.")
                    return render(request, "panel/login.html", {"form": form})
                
                # 3. Supabase Auth ile giriş yap
                auth_response = sign_in(email, password)
                user_id = auth_response["user_id"]
                
                # 4. Kullanıcının bu hastaneye ait olduğunu kontrol et
                hospital_check = supabase.table("hospitals").select("id").eq("id", hospital["id"]).eq("created_by_user_id", user_id).execute()
                
                if not hospital_check.data:
                    messages.error(request, "Bu email adresi bu hastaneye ait değil.")
                    return render(request, "panel/login.html", {"form": form})
                
                # 5. Session'a kaydet
                request.session['user_id'] = user_id
                request.session['hospital_id'] = str(hospital["id"])
                request.session['hospital_name'] = hospital.get("name", "")
                request.session['user_email'] = email
                
                messages.success(request, f"Hoş geldiniz, {hospital.get('name', '')}!")
                return redirect('dashboard')
                
            except ValueError as e:
                messages.error(request, str(e))
            except Exception as e:
                messages.error(request, f"Giriş yapılamadı: {str(e)}")
    else:
        form = LoginForm()
    
    return render(request, "panel/login.html", {"form": form})


def register_view(request):
    """Hastane kayıt sayfası."""
    if request.method == 'POST':
        # Lokasyon seçeneklerini hazırla
        from .services import location_service
        province_choices = location_service.as_choice_tuples(location_service.get_provinces())
        province_id = request.POST.get("province")
        district_choices = []
        neighborhood_choices = []
        
        if province_id:
            district_choices = location_service.as_choice_tuples(location_service.get_districts(province_id))
            district_id = request.POST.get("district")
            if district_id:
                neighborhood_choices = location_service.as_choice_tuples(location_service.get_neighborhoods(district_id))
        
        form = HospitalRegistrationForm(
            request.POST,
            request.FILES,
            province_choices=province_choices,
            district_choices=district_choices,
            neighborhood_choices=neighborhood_choices,
        )
        
        if form.is_valid():
            try:
                result = register_hospital(form.cleaned_data, request.FILES.get("logo"))
                messages.success(
                    request,
                    "Kayıt başarıyla oluşturuldu! "
                    "Kaydınız admin tarafından onaylandıktan sonra giriş yapabileceksiniz. "
                    "Onay sonrası email adresinize giriş kodunuz gönderilecektir."
                )
                return redirect('login')
            except ValueError as e:
                messages.error(request, str(e))
            except Exception as e:
                messages.error(request, f"Kayıt oluşturulamadı: {str(e)}")
    else:
        from .services import location_service
        province_choices = location_service.as_choice_tuples(location_service.get_provinces())
        form = HospitalRegistrationForm(
            province_choices=province_choices,
            district_choices=[],
            neighborhood_choices=[],
        )
    
    return render(request, "panel/register.html", {"form": form})


def logout_view(request):
    """Kullanıcı çıkışı."""
    request.session.flush()
    messages.success(request, "Başarıyla çıkış yaptınız.")
    return redirect('login')


@login_required
def dashboard(request):
    """Panel ana sayfası: JSON verilerinden özet metrikleri oluşturur."""
    context = load_dashboard_context(request)
    context["page_title"] = "Genel Bakış"
    # hospital context processor tarafından otomatik ekleniyor
    return render(request, "panel/dashboard.html", context)


class HospitalSettingsView(View):
    template_name = "panel/hospital_settings.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        context = self._build_context(request)
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("form_type")
        hospital = hospital_service.get_hospital(request)
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
                        request,
                    )
                except ValueError as exc:
                    messages.error(request, str(exc))
                else:
                    messages.success(request, "Genel bilgiler güncellendi.")
                    # Aynı sayfada kal (general sekmesinde)
                    context = self._build_context(request, general_form=form)
                    context["active_tab"] = "general"
                    return render(request, self.template_name, context)
            else:
                messages.error(request, "Genel bilgiler güncellenemedi. Lütfen formu kontrol edin.")
            context = self._build_context(request, general_form=form)
            context["active_tab"] = "general"
            return render(request, self.template_name, context)

        elif action == "services":
            form = HospitalServicesForm(request.POST, service_choices=build_service_choices(services))
            if form.is_valid():
                hospital_service.update_services(hospital, form.cleaned_data.get("services", []), request)
                messages.success(request, "Hizmet listesi güncellendi.")
                # Aynı sayfada kal (services sekmesinde)
                context = self._build_context(request)
                context["active_tab"] = "services"
                return render(request, self.template_name, context)
            else:
                messages.error(request, "Hizmetler güncellenemedi.")
                context = self._build_context(request)
                context["active_tab"] = "services"
                return render(request, self.template_name, context)

        elif action == "working_hours":
            form = WorkingHoursForm(request.POST)
            if form.is_valid():
                # 7/24 açık kontrolü - eğer 7/24 açıksa validasyon yapma
                is_open_24_hours = form.cleaned_data.get("is_open_24_hours", False)
                if not is_open_24_hours and not self._validate_working_hours(form, request):
                    messages.error(request, "Çalışma saatleri güncellenemedi.")
                    context = self._build_context(request)
                    context["active_tab"] = "hours"
                    return render(request, self.template_name, context)
                
                working_hours = hospital_service.build_working_hours_from_form(form.cleaned_data)
                # is_open_24_hours değerini de güncelle
                hospital_service.update_working_hours(hospital, working_hours, request)
                hospital_service.update_is_open_24_hours(hospital, is_open_24_hours, request)
                messages.success(request, "Çalışma saatleri güncellendi.")
                # Aynı sayfada kal (working_hours sekmesinde)
                context = self._build_context(request)
                context["active_tab"] = "hours"  # Template'de tab-hours id'si var
                return render(request, self.template_name, context)
            else:
                messages.error(request, "Çalışma saatleri güncellenemedi.")
                context = self._build_context(request)
                context["active_tab"] = "hours"  # Template'de tab-hours id'si var
                return render(request, self.template_name, context)

        elif action == "gallery_add":
            form = GalleryAddForm(request.POST, request.FILES)
            if form.is_valid():
                try:
                    # Birden fazla görsel seçilmiş olabilir
                    files = request.FILES.getlist("images")
                    if not files:
                        messages.error(request, "Lütfen en az bir görsel seçin.")
                    else:
                        current_gallery_count = len(hospital.get("gallery", []))
                        remaining_slots = 5 - current_gallery_count
                        
                        if len(files) > remaining_slots:
                            messages.error(request, f"Maksimum 5 görsel eklenebilir. {remaining_slots} görsel daha ekleyebilirsiniz.")
                        else:
                            added_count = 0
                            for file in files:
                                try:
                                    hospital_service.add_gallery_image(hospital, file, request)
                                    added_count += 1
                                except ValueError as exc:
                                    messages.error(request, f"Görsel eklenemedi: {str(exc)}")
                            
                            if added_count > 0:
                                messages.success(request, f"{added_count} görsel galeriye eklendi.")
                except Exception as exc:
                    messages.error(request, f"Hata: {str(exc)}")
                
                # Aynı sayfada kal (gallery sekmesinde)
                context = self._build_context(request)
                context["active_tab"] = "gallery"
                return render(request, self.template_name, context)
            else:
                messages.error(request, "Galeri görseli eklenemedi. Lütfen formu kontrol edin.")
                context = self._build_context(request)
                context["active_tab"] = "gallery"
                return render(request, self.template_name, context)

        elif action == "gallery_remove":
            try:
                index = int(request.POST.get("index", -1))
                hospital_service.remove_gallery_image(hospital, index, request)
                messages.success(request, "Galeri görseli kaldırıldı.")
            except ValueError:
                messages.error(request, "Geçersiz galeri öğesi.")
            
            # Aynı sayfada kal (gallery sekmesinde)
            context = self._build_context(request)
            context["active_tab"] = "gallery"
            return render(request, self.template_name, context)

        elif action == "holiday_add":
            form = HolidayAddForm(request.POST)
            if form.is_valid():
                is_full_day = form.cleaned_data.get("is_full_day", True)
                start_time = form.cleaned_data.get("start_time") if not is_full_day else None
                end_time = form.cleaned_data.get("end_time") if not is_full_day else None
                
                # Saatli tatil için validasyon
                if not is_full_day:
                    if not start_time or not end_time:
                        messages.error(request, "Saatli tatil için başlangıç ve bitiş saatleri zorunludur.")
                        context = self._build_context(request)
                        context["holiday_add_form"] = form
                        context["active_tab"] = "holidays"
                        return render(request, self.template_name, context)
                    if start_time >= end_time:
                        messages.error(request, "Bitiş saati başlangıç saatinden sonra olmalıdır.")
                        context = self._build_context(request)
                        context["holiday_add_form"] = form
                        context["active_tab"] = "holidays"
                        return render(request, self.template_name, context)
                
                hospital_service.add_holiday(
                    form.cleaned_data["date"].isoformat(),
                    form.cleaned_data["reason"],
                    is_full_day=is_full_day,
                    start_time=start_time,
                    end_time=end_time,
                    request=request,
                )
                messages.success(request, "Tatil bilgisi eklendi.")
                return redirect("hospital_settings")
            messages.error(request, "Tatil bilgisi eklenemedi.")

        elif action == "holiday_delete":
            holiday_id = request.POST.get("holiday_id")
            hospital_service.delete_holiday(holiday_id)
            messages.success(request, "Tatil kaydı silindi.")
            return redirect("hospital_settings")

        context = self._build_context(request)
        context["active_tab"] = action
        return render(request, self.template_name, context)

    def _build_context(self, request=None, general_form: HospitalGeneralForm | None = None):
        hospital = hospital_service.get_hospital(request)
        services = hospital_service.get_services()
        holidays = hospital_service.get_holidays(request)
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
            service_choices=build_service_choices(services),
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
        
        # JavaScript için hastane çalışma saatlerini JSON olarak geçir
        import json
        working_hours_json = json.dumps(hospital.get("workingHours", {}))
        
        # Logo bilgisini hazırla (URL'den dosya adını çıkar)
        current_logo = None
        logo_url = hospital.get("image")
        if logo_url:
            # URL'den dosya adını çıkar
            # Örnek: https://xxx.supabase.co/storage/v1/object/public/hospital-media/logos/logo_abc123.jpg
            # -> logo_abc123.jpg
            if "/hospital-media/" in logo_url:
                current_logo = logo_url.split("/hospital-media/")[-1]
            elif "/" in logo_url:
                current_logo = logo_url.split("/")[-1]
            else:
                current_logo = logo_url

        context = {
            "page_title": "Hastane Bilgileri",
            # hospital context processor tarafından otomatik ekleniyor
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
            "working_hours_json": working_hours_json,
            "current_logo": current_logo,  # Mevcut logo dosya adı
        }
        return context

    def _validate_working_hours(self, form, request) -> bool:
        # 7/24 açıksa validasyon yapma
        is_open_24_hours = form.cleaned_data.get("is_open_24_hours", False)
        if is_open_24_hours:
            return True
        
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
                    request=request,
                )
                messages.success(request, "Doktor tatili eklendi.")
                return redirect("doctor_management")
            messages.error(request, "Tatil eklenemedi.")

        elif action == "delete_holiday":
            doctor_service.delete_doctor_holiday(request.POST.get("holiday_id"))
            messages.success(request, "Tatil kaydı silindi.")
            return redirect("doctor_management")

        context = self._build_context(request)
        context["active_tab"] = action
        return render(request, self.template_name, context)

    def _build_context(self, request):
        # hospital context processor tarafından otomatik ekleniyor
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
            # hospital context processor tarafından otomatik ekleniyor
            "doctor_cards": doctor_cards,
            "doctor_create_form": DoctorForm(service_choices=service_choices),
        }
        return context

    def _validate_working_hours(self, form, request) -> bool:
        """Çalışma saatleri formunu validate eder."""
        return validate_working_hours_form(form, DAYS, request)


class AppointmentManagementView(View):
    template_name = "panel/appointment_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)
    
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

        elif action == "delete_appointment":
            appointment_service.delete_appointment(request.POST.get("appointment_id"))
            messages.success(request, "Randevu silindi.")
            return redirect("appointment_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        # Otomatik iptal kontrolü - her sayfa yüklendiğinde
        cancelled_count = appointment_service.auto_cancel_overdue_appointments(request=request)
        if cancelled_count > 0:
            messages.info(request, f"{cancelled_count} randevu otomatik olarak iptal edildi (5 gün geçmiş).")
        
        # hospital context processor tarafından otomatik ekleniyor
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
        # per_page değerini form'dan al, yoksa GET parametresinden al
        per_page = filters.get("per_page") or request.GET.get("per_page", "10")
        
        appointments = appointment_service.filter_appointments(
            status=filters.get("status") or None,
            doctor_id=filters.get("doctor") or None,
            service_id=filters.get("service") or None,
            start_date=start_date,
            end_date=end_date,
            request=request,
        )

        # Sıralama: Bekleyen randevular önce (tarih/saat), tamamlanan en altta
        enriched = self._enrich_appointments(appointments, doctors, services)
        enriched = self._sort_appointments(enriched)

        # Pagination
        per_page = int(per_page or "10")
        paginator = Paginator(enriched, per_page)
        page_number = request.GET.get("page", 1)
        try:
            page_obj = paginator.get_page(page_number)
        except:
            page_obj = paginator.get_page(1)

        # Filter form'a per_page değerini set et
        if filter_form.is_valid():
            filter_form.fields["per_page"].initial = str(per_page)
        else:
            filter_form.fields["per_page"].initial = request.GET.get("per_page", "10")
        
        context = {
            "page_title": "Randevu Yönetimi",
            # hospital context processor tarafından otomatik ekleniyor
            "filter_form": filter_form,
            "appointments": page_obj,
            "summary": appointment_service.get_summary(request=request),
            "paginator": paginator,
        }
        return context
    
    def _sort_appointments(self, appointments):
        """
        Randevuları sıralar: Bekleyen randevular önce (tarih/saat), tamamlanan en altta
        """
        pending = []
        completed = []
        cancelled = []
        
        for apt in appointments:
            status = apt["data"].get("status", "pending")
            if status == "pending":
                pending.append(apt)
            elif status == "completed":
                completed.append(apt)
            else:
                cancelled.append(apt)
        
        # Tarih ve saat sırasına göre sırala
        def sort_key(apt):
            try:
                date_str = apt["data"].get("date", "")
                time_str = apt["data"].get("time", "00:00")
                date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
                time_obj = datetime.strptime(time_str, "%H:%M").time()
                return (date_obj, time_obj)
            except (ValueError, KeyError):
                return (date.today(), datetime.min.time())
        
        pending.sort(key=sort_key)
        completed.sort(key=sort_key, reverse=True)  # Tamamlananlar en yeniden eskiye
        cancelled.sort(key=sort_key, reverse=True)
        
        # Bekleyen önce, sonra iptal, en son tamamlanan
        return pending + cancelled + completed

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
            
            # Tarihi formatla (gün.ay.yıl)
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


class ScheduleManagementView(View):
    template_name = "panel/schedule_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        from datetime import date

        today = date.today()
        year = int(request.GET.get("year", today.year))
        # Ay değeri artık string olarak gelebilir (form'dan) veya int olarak (URL'den)
        month_param = request.GET.get("month", str(today.month))
        month = int(month_param) if month_param else today.month
        selected_doctor_id = request.GET.get("doctor", "")

        doctors = doctor_service.get_doctors(request)
        doctor_choices = build_doctor_choices(doctors)

        filter_form = ScheduleFilterForm(
            initial={"year": year, "month": str(month), "doctor": selected_doctor_id},
            doctor_choices=doctor_choices,
        )

        calendar_data = schedule_service.build_calendar_data(
            year, month, selected_doctor_id if selected_doctor_id else None, request=request
        )

        # hospital context processor tarafından otomatik ekleniyor
        holiday_form = ScheduleHolidayForm(doctor_choices=doctor_choices)

        context = {
            "page_title": "Çalışma Takvimi",
            # hospital context processor tarafından otomatik ekleniyor
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
                    doctor_service.add_doctor_holiday(doctor_id, holiday_date.isoformat(), reason, request=request)
                else:
                    hospital_service.add_holiday(holiday_date.isoformat(), reason, request=request)

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
        # hospital iş mantığı için gerekli (services listesini filtrelemek için)
        hospital = hospital_service.get_hospital(request)
        
        # Sadece hastanenin seçtiği hizmetleri göster
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
            # hospital context processor tarafından otomatik ekleniyor
            "service_cards": service_cards,
            "doctor_choices": doctor_choices,
        }
        return context


class ReviewManagementView(View):
    template_name = "panel/review_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

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
                messages.success(request, "Yanıt eklendi.")
                return redirect("review_management")

        elif action == "edit_reply":
            form = ReviewReplyForm(request.POST)
            if form.is_valid():
                review_id = form.cleaned_data["review_id"]
                reply_text = form.cleaned_data["reply"]
                review_service.add_reply(review_id, reply_text)
                messages.success(request, "Yanıt güncellendi.")
                return redirect("review_management")

        elif action == "delete_reply":
            review_id = request.POST.get("review_id")
            if review_id:
                review_service.delete_reply(review_id)
                messages.success(request, "Yanıt silindi.")
                return redirect("review_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        doctors = doctor_service.get_doctors(request)
        doctor_choices = build_doctor_choices(doctors)

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
            request=request,
        )

        # İstatistikler
        stats = review_service.get_review_statistics(request=request)

        # Her yorum için yanıt formu ve tarih formatını düzelt
        from datetime import datetime
        review_cards = []
        for review in reviews:
            # Tarih formatını düzelt (ISO string'den datetime'a)
            created_at = review.get("createdAt", "")
            if created_at:
                try:
                    dt_str = created_at.replace("Z", "+00:00")
                    review["created_at_dt"] = datetime.fromisoformat(dt_str)
                except (ValueError, AttributeError):
                    review["created_at_dt"] = None
            else:
                review["created_at_dt"] = None
            
            replied_at = review.get("repliedAt", "")
            if replied_at:
                try:
                    dt_str = replied_at.replace("Z", "+00:00")
                    review["replied_at_dt"] = datetime.fromisoformat(dt_str)
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

        # hospital context processor tarafından otomatik ekleniyor

        context = {
            "page_title": "Yorumlar & Yanıtlar",
            # hospital context processor tarafından otomatik ekleniyor
            "filter_form": filter_form,
            "review_cards": review_cards,
            "statistics": stats,
            "doctor_choices": doctor_choices,
        }
        return context


class SettingsView(View):
    template_name = "panel/settings.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        context = self._build_context(request)
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
                messages.success(request, "Genel ayarlar güncellendi.")
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
                messages.success(request, "Bildirim ayarları güncellendi.")
                return redirect("settings")

        elif action == "data_management":
            form = DataManagementForm(request.POST)
            if form.is_valid():
                updates = {
                    "backup_enabled": form.cleaned_data.get("backup_enabled", False),
                    "auto_backup_days": form.cleaned_data["auto_backup_days"],
                }
                settings_service.update_settings("data_management", updates)
                messages.success(request, "Veri yönetimi ayarları güncellendi.")
                return redirect("settings")

        elif action == "security":
            form = SecuritySettingsForm(request.POST)
            if form.is_valid():
                updates = {
                    "session_timeout_minutes": form.cleaned_data["session_timeout_minutes"],
                }
                settings_service.update_settings("security", updates)
                messages.success(request, "Güvenlik ayarları güncellendi.")
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
                messages.success(request, "Görünüm ayarları güncellendi.")
                return redirect("settings")

        elif action == "export_data":
            # Veri export
            json_data = settings_service.export_data_as_json()
            response = HttpResponse(json_data, content_type="application/json")
            response["Content-Disposition"] = 'attachment; filename="panel_backup.json"'
            return response

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        settings_data = settings_service.get_settings()
        hospital_choices = settings_service.get_hospital_choices()
        data_stats = settings_service.get_data_statistics()
        # hospital context processor tarafından otomatik ekleniyor

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
            # hospital context processor tarafından otomatik ekleniyor
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
