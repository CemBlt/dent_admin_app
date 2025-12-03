from datetime import date
from django.shortcuts import render, redirect
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from .auth_views import login_required
from ..forms import ScheduleFilterForm, ScheduleHolidayForm
from ..utils import build_doctor_choices
from ..services import doctor_service, schedule_service, hospital_service

class ScheduleManagementView(View):
    template_name = "panel/schedule_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        today = date.today()
        year = int(request.GET.get("year", today.year))
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

        holiday_form = ScheduleHolidayForm(doctor_choices=doctor_choices)

        context = {
            "page_title": "Çalışma Takvimi",
            "calendar": calendar_data,
            "filter_form": filter_form,
            "holiday_form": holiday_form,
            "doctors": doctors,
        }
        return render(request, self.template_name, context)

    def post(self, request):
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

