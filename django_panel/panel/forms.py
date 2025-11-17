from __future__ import annotations

from django import forms

DAYS = [
    ("monday", "Pazartesi"),
    ("tuesday", "Salı"),
    ("wednesday", "Çarşamba"),
    ("thursday", "Perşembe"),
    ("friday", "Cuma"),
    ("saturday", "Cumartesi"),
    ("sunday", "Pazar"),
]


class HospitalGeneralForm(forms.Form):
    name = forms.CharField(label="Hastane Adı", max_length=120)
    address = forms.CharField(label="Adres", max_length=200)
    phone = forms.CharField(label="Telefon", max_length=20)
    email = forms.EmailField(label="E-posta", max_length=120)
    description = forms.CharField(label="Açıklama", widget=forms.Textarea, required=False)
    logo = forms.FileField(label="Logo", required=False)


class HospitalServicesForm(forms.Form):
    services = forms.MultipleChoiceField(
        label="Verilen Hizmetler",
        choices=[],
        required=False,
        widget=forms.CheckboxSelectMultiple,
    )

    def __init__(self, *args, **kwargs):
        service_choices = kwargs.pop("service_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["services"].choices = service_choices


class WorkingHoursForm(forms.Form):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for key, label in DAYS:
            self.fields[f"{key}_is_open"] = forms.BooleanField(
                label=f"{label} açık mı?",
                required=False,
            )
            self.fields[f"{key}_start"] = forms.TimeField(
                label=f"{label} başlangıç",
                required=False,
                widget=forms.TimeInput(format="%H:%M"),
            )
            self.fields[f"{key}_end"] = forms.TimeField(
                label=f"{label} bitiş",
                required=False,
                widget=forms.TimeInput(format="%H:%M"),
            )


class GalleryAddForm(forms.Form):
    image = forms.FileField(label="Galeri Görseli")


class HolidayAddForm(forms.Form):
    date = forms.DateField(label="Tarih", widget=forms.DateInput(attrs={"type": "date"}))
    reason = forms.CharField(label="Açıklama", max_length=120)


class DoctorForm(forms.Form):
    doctor_id = forms.CharField(widget=forms.HiddenInput, required=False)
    name = forms.CharField(label="Ad", max_length=80)
    surname = forms.CharField(label="Soyad", max_length=80)
    specialty = forms.CharField(label="Uzmanlık", max_length=120)
    bio = forms.CharField(label="Biyografi", widget=forms.Textarea, required=False)
    is_active = forms.BooleanField(label="Aktif mi?", required=False, initial=True)
    services = forms.MultipleChoiceField(
        label="Verdiği Hizmetler",
        choices=[],
        required=False,
        widget=forms.CheckboxSelectMultiple,
    )
    image = forms.FileField(label="Profil Fotoğrafı", required=False)

    def __init__(self, *args, **kwargs):
        service_choices = kwargs.pop("service_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["services"].choices = service_choices


class DoctorWorkingHoursForm(forms.Form):
    doctor_id = forms.CharField(widget=forms.HiddenInput)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for key, label in DAYS:
            self.fields[f"{key}_is_open"] = forms.BooleanField(
                label=f"{label} açık mı?",
                required=False,
            )
            self.fields[f"{key}_start"] = forms.TimeField(
                label=f"{label} başlangıç",
                required=False,
                widget=forms.TimeInput(format="%H:%M"),
            )
            self.fields[f"{key}_end"] = forms.TimeField(
                label=f"{label} bitiş",
                required=False,
                widget=forms.TimeInput(format="%H:%M"),
            )


class DoctorHolidayForm(forms.Form):
    doctor_id = forms.CharField(widget=forms.HiddenInput)
    date = forms.DateField(label="Tarih", widget=forms.DateInput(attrs={"type": "date"}))
    reason = forms.CharField(label="Açıklama", max_length=120)


class AppointmentFilterForm(forms.Form):
    status = forms.ChoiceField(
        label="Durum",
        required=False,
        choices=[
            ("", "Tümü"),
            ("pending", "Bekleyen"),
            ("completed", "Tamamlandı"),
            ("cancelled", "İptal"),
        ],
    )
    doctor = forms.ChoiceField(label="Doktor", required=False)
    service = forms.ChoiceField(label="Hizmet", required=False)
    start_date = forms.DateField(label="Başlangıç Tarihi", required=False, widget=forms.DateInput(attrs={"type": "date"}))
    end_date = forms.DateField(label="Bitiş Tarihi", required=False, widget=forms.DateInput(attrs={"type": "date"}))

    def __init__(self, *args, **kwargs):
        doctor_choices = kwargs.pop("doctor_choices", [])
        service_choices = kwargs.pop("service_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["doctor"].choices = [("", "Tümü")] + doctor_choices
        self.fields["service"].choices = [("", "Tümü")] + service_choices


class AppointmentNoteForm(forms.Form):
    appointment_id = forms.CharField(widget=forms.HiddenInput)
    notes = forms.CharField(label="Notlar", widget=forms.Textarea, required=False)


class AppointmentStatusForm(forms.Form):
    appointment_id = forms.CharField(widget=forms.HiddenInput)
    status = forms.ChoiceField(
        label="Durum",
        choices=[
            ("pending", "Bekleyen"),
            ("completed", "Tamamlandı"),
            ("cancelled", "İptal"),
        ],
    )


class ScheduleFilterForm(forms.Form):
    doctor = forms.ChoiceField(label="Doktor", required=False)
    year = forms.IntegerField(label="Yıl", min_value=2020, max_value=2100)
    month = forms.IntegerField(label="Ay", min_value=1, max_value=12)

    def __init__(self, *args, **kwargs):
        doctor_choices = kwargs.pop("doctor_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["doctor"].choices = [("", "Tüm Doktorlar")] + doctor_choices


class ScheduleHolidayForm(forms.Form):
    date = forms.DateField(label="Tarih", widget=forms.DateInput(attrs={"type": "date"}))
    reason = forms.CharField(label="Açıklama", max_length=120)
    doctor_id = forms.ChoiceField(label="Doktor (Opsiyonel)", required=False)

    def __init__(self, *args, **kwargs):
        doctor_choices = kwargs.pop("doctor_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["doctor_id"].choices = [("", "Hastane Geneli")] + doctor_choices

class ServiceForm(forms.Form):
    service_id = forms.CharField(widget=forms.HiddenInput, required=False)
    name = forms.CharField(label="Hizmet Adı", max_length=120)
    description = forms.CharField(label="Açıklama", widget=forms.Textarea, required=False)
    price = forms.DecimalField(label="Fiyat (₺)", max_digits=10, decimal_places=2)


class ServiceAssignmentForm(forms.Form):
    service_id = forms.CharField(widget=forms.HiddenInput)
    doctors = forms.MultipleChoiceField(label="Doktorlar", required=False, widget=forms.CheckboxSelectMultiple)
    hospitals = forms.MultipleChoiceField(label="Hastaneler", required=False, widget=forms.CheckboxSelectMultiple)

    def __init__(self, *args, **kwargs):
        doctor_choices = kwargs.pop("doctor_choices", [])
        hospital_choices = kwargs.pop("hospital_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["doctors"].choices = doctor_choices
        self.fields["hospitals"].choices = hospital_choices
