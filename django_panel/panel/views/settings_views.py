from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from .auth_views import login_required
from ..forms import (
    GeneralSettingsForm,
    NotificationSettingsForm,
    DataManagementForm,
    SecuritySettingsForm,
    AppearanceSettingsForm
)
from ..services import settings_service

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
        
        if action == "general":
            hospital_choices = settings_service.get_hospital_choices()
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
            "general_form": general_form,
            "notification_form": notification_form,
            "data_management_form": data_management_form,
            "security_form": security_form,
            "appearance_form": appearance_form,
            "data_statistics": data_stats,
        }
        return context

