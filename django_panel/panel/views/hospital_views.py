import json
from django.shortcuts import render, redirect
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from .auth_views import login_required
from ..forms import (
    HospitalGeneralForm,
    HospitalServicesForm,
    WorkingHoursForm,
    GalleryAddForm,
    HolidayAddForm,
    DAYS
)
from ..utils import build_service_choices
from ..services import hospital_service, location_service, event_service

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
                    event_service.log_event(
                        "hospital_general_updated",
                        request=request,
                        properties={"updated_fields": list(form.cleaned_data.keys())},
                    )
                    context = self._build_context(request)
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
                event_service.log_event(
                    "hospital_services_updated",
                    request=request,
                    properties={"service_count": len(form.cleaned_data.get("services", []))},
                )
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
                is_open_24_hours = form.cleaned_data.get("is_open_24_hours", False)
                if not is_open_24_hours and not self._validate_working_hours(form, request):
                    messages.error(request, "Çalışma saatleri güncellenemedi.")
                    context = self._build_context(request)
                    context["active_tab"] = "hours"
                    return render(request, self.template_name, context)
                
                working_hours = hospital_service.build_working_hours_from_form(form.cleaned_data)
                hospital_service.update_working_hours(hospital, working_hours, request)
                hospital_service.update_is_open_24_hours(hospital, is_open_24_hours, request)
                messages.success(request, "Çalışma saatleri güncellendi.")
                event_service.log_event(
                    "hospital_hours_updated",
                    request=request,
                    properties={"is_24_hours": is_open_24_hours},
                )
                context = self._build_context(request)
                context["active_tab"] = "hours"
                return render(request, self.template_name, context)
            else:
                messages.error(request, "Çalışma saatleri güncellenemedi.")
                context = self._build_context(request)
                context["active_tab"] = "hours"
                return render(request, self.template_name, context)

        elif action == "gallery_add":
            form = GalleryAddForm(request.POST, request.FILES)
            if form.is_valid():
                try:
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
                                event_service.log_event(
                                    "hospital_gallery_updated",
                                    request=request,
                                    properties={"added_count": added_count},
                                )
                except Exception as exc:
                    messages.error(request, f"Hata: {str(exc)}")
                
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
                event_service.log_event(
                    "hospital_gallery_removed",
                    request=request,
                    properties={"index": index},
                )
            except ValueError:
                messages.error(request, "Geçersiz galeri öğesi.")
            
            context = self._build_context(request)
            context["active_tab"] = "gallery"
            return render(request, self.template_name, context)

        elif action == "holiday_add":
            form = HolidayAddForm(request.POST)
            if form.is_valid():
                is_full_day = form.cleaned_data.get("is_full_day", True)
                start_time = form.cleaned_data.get("start_time") if not is_full_day else None
                end_time = form.cleaned_data.get("end_time") if not is_full_day else None
                
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
                event_service.log_event(
                    "hospital_holiday_added",
                    request=request,
                    properties={
                        "date": form.cleaned_data["date"].isoformat(),
                        "is_full_day": is_full_day,
                    },
                )
                return redirect("hospital_settings")
            messages.error(request, "Tatil bilgisi eklenemedi.")

        elif action == "holiday_delete":
            holiday_id = request.POST.get("holiday_id")
            hospital_service.delete_holiday(holiday_id)
            messages.success(request, "Tatil kaydı silindi.")
            event_service.log_event(
                "hospital_holiday_deleted",
                request=request,
                properties={"holiday_id": holiday_id},
            )
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
        else:
            if general_form.data:
                province_id = general_form.data.get("province", "")
                district_id = general_form.data.get("district", "")
                neighborhood_id = general_form.data.get("neighborhood", "")
                general_form.initial.update({
                    "province": province_id,
                    "district": district_id,
                    "neighborhood": neighborhood_id,
                })
                general_form.fields["province"].widget.attrs["data-initial"] = province_id
                general_form.fields["district"].widget.attrs["data-initial"] = district_id
                general_form.fields["neighborhood"].widget.attrs["data-initial"] = neighborhood_id

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
        
        working_hours_json = json.dumps(hospital.get("workingHours", {}))
        
        current_logo = None
        logo_url = hospital.get("image")
        if logo_url:
            if "/hospital-media/" in logo_url:
                current_logo = logo_url.split("/hospital-media/")[-1]
            elif "/" in logo_url:
                current_logo = logo_url.split("/")[-1]
            else:
                current_logo = logo_url

        context = {
            "page_title": "Hastane Bilgileri",
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
            "current_logo": current_logo,
        }
        return context

    def _validate_working_hours(self, form, request) -> bool:
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

