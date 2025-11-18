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

TIME_CHOICES = [("", "Saat seçin")]
for hour in range(0, 24):
    for minute in (0, 30):
        label = f"{hour:02d}:{minute:02d}"
        TIME_CHOICES.append((label, label))


class HospitalGeneralForm(forms.Form):
    name = forms.CharField(label="Hastane Adı", max_length=120)
    address = forms.CharField(label="Adres Açıklaması", max_length=200, required=False)
    province = forms.ChoiceField(label="İl", choices=[])
    district = forms.ChoiceField(label="İlçe", choices=[])
    neighborhood = forms.ChoiceField(label="Mahalle", choices=[])
    latitude = forms.DecimalField(label="Enlem (Latitude)", max_digits=10, decimal_places=6)
    longitude = forms.DecimalField(label="Boylam (Longitude)", max_digits=10, decimal_places=6)
    phone = forms.CharField(label="Telefon", max_length=20)
    email = forms.EmailField(label="E-posta", max_length=120)
    description = forms.CharField(label="Açıklama", widget=forms.Textarea, required=False)
    logo = forms.FileField(label="Logo", required=False)

    def __init__(self, *args, **kwargs):
        province_choices = kwargs.pop("province_choices", [])
        district_choices = kwargs.pop("district_choices", [])
        neighborhood_choices = kwargs.pop("neighborhood_choices", [])
        super().__init__(*args, **kwargs)

        self.fields["province"].choices = [("", "İl seçin")] + province_choices

        if district_choices:
            self.fields["district"].choices = [("", "İlçe seçin")] + district_choices
            self.fields["district"].widget.attrs.pop("disabled", None)
        else:
            self.fields["district"].choices = [("", "Önce il seçin")]
            self.fields["district"].widget.attrs["disabled"] = "disabled"

        if neighborhood_choices:
            self.fields["neighborhood"].choices = [("", "Mahalle seçin")] + neighborhood_choices
            self.fields["neighborhood"].widget.attrs.pop("disabled", None)
        else:
            self.fields["neighborhood"].choices = [("", "Önce ilçe seçin")]
            self.fields["neighborhood"].widget.attrs["disabled"] = "disabled"

        self.fields["province"].widget.attrs.setdefault("data-initial", self.initial.get("province", ""))
        self.fields["district"].widget.attrs.setdefault("data-initial", self.initial.get("district", ""))
        self.fields["neighborhood"].widget.attrs.setdefault("data-initial", self.initial.get("neighborhood", ""))

        numeric_attrs = {"step": "0.000001", "placeholder": "00.000000"}
        self.fields["latitude"].widget.attrs.update(numeric_attrs)
        self.fields["longitude"].widget.attrs.update({**numeric_attrs, "placeholder": "000.000000"})


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
        initial = kwargs.pop('initial', {})
        super().__init__(*args, **kwargs)
        for key, label in DAYS:
            # Checkbox için initial değer
            is_open_initial = initial.get(f"{key}_is_open", False)
            
            self.fields[f"{key}_is_open"] = forms.BooleanField(
                label=f"{label} açık mı?",
                required=False,
                initial=is_open_initial,
            )
            
            # Saat alanları için initial değerleri time objesinden string'e çevir
            start_initial = initial.get(f"{key}_start")
            end_initial = initial.get(f"{key}_end")
            
            # time objesi ise "HH:MM" formatına çevir
            if start_initial and hasattr(start_initial, 'strftime'):
                start_initial = start_initial.strftime("%H:%M")
            elif start_initial is None:
                start_initial = ""
            
            if end_initial and hasattr(end_initial, 'strftime'):
                end_initial = end_initial.strftime("%H:%M")
            elif end_initial is None:
                end_initial = ""
            
            self.fields[f"{key}_start"] = forms.ChoiceField(
                label=f"{label} başlangıç",
                required=False,
                choices=TIME_CHOICES,
                initial=start_initial,
                widget=forms.Select(attrs={"class": "time-select"}),
            )
            self.fields[f"{key}_end"] = forms.ChoiceField(
                label=f"{label} bitiş",
                required=False,
                choices=TIME_CHOICES,
                initial=end_initial,
                widget=forms.Select(attrs={"class": "time-select"}),
            )


class GalleryAddForm(forms.Form):
    image = forms.FileField(label="Galeri Görseli")


class HolidayAddForm(forms.Form):
    date = forms.DateField(label="Tarih", widget=forms.DateInput(attrs={"type": "date"}))
    reason = forms.CharField(label="Açıklama", max_length=120)
    is_full_day = forms.BooleanField(label="Tüm Gün", required=False, initial=True)
    start_time = forms.ChoiceField(
        label="Başlangıç Saati",
        choices=TIME_CHOICES,
        required=False,
        widget=forms.Select(attrs={"class": "time-select"})
    )
    end_time = forms.ChoiceField(
        label="Bitiş Saati",
        choices=TIME_CHOICES,
        required=False,
        widget=forms.Select(attrs={"class": "time-select"})
    )


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
        initial = kwargs.pop('initial', {})
        super().__init__(*args, **kwargs)
        for key, label in DAYS:
            # Checkbox için initial değer
            is_open_initial = initial.get(f"{key}_is_open", False)
            
            self.fields[f"{key}_is_open"] = forms.BooleanField(
                label=f"{label} açık mı?",
                required=False,
                initial=is_open_initial,
            )
            
            # Saat alanları için initial değerleri time objesinden string'e çevir
            start_initial = initial.get(f"{key}_start")
            end_initial = initial.get(f"{key}_end")
            
            # time objesi ise "HH:MM" formatına çevir
            if start_initial and hasattr(start_initial, 'strftime'):
                start_initial = start_initial.strftime("%H:%M")
            elif start_initial is None:
                start_initial = ""
            
            if end_initial and hasattr(end_initial, 'strftime'):
                end_initial = end_initial.strftime("%H:%M")
            elif end_initial is None:
                end_initial = ""
            
            self.fields[f"{key}_start"] = forms.ChoiceField(
                label=f"{label} başlangıç",
                required=False,
                choices=TIME_CHOICES,
                initial=start_initial,
                widget=forms.Select(attrs={"class": "time-select"}),
            )
            self.fields[f"{key}_end"] = forms.ChoiceField(
                label=f"{label} bitiş",
                required=False,
                choices=TIME_CHOICES,
                initial=end_initial,
                widget=forms.Select(attrs={"class": "time-select"}),
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
    per_page = forms.ChoiceField(
        label="Sayfa Başına",
        required=False,
        choices=[
            ("10", "10"),
            ("20", "20"),
            ("50", "50"),
        ],
        initial="10",
    )

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


class ServiceAssignmentForm(forms.Form):
    service_id = forms.CharField(widget=forms.HiddenInput)
    doctors = forms.MultipleChoiceField(label="Doktorlar", required=False, widget=forms.CheckboxSelectMultiple)

    def __init__(self, *args, **kwargs):
        doctor_choices = kwargs.pop("doctor_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["doctors"].choices = doctor_choices


class ReviewFilterForm(forms.Form):
    doctor = forms.ChoiceField(label="Doktor", required=False)
    min_rating = forms.ChoiceField(
        label="Minimum Puan",
        required=False,
        choices=[
            ("", "Tümü"),
            ("1", "1 Yıldız"),
            ("2", "2 Yıldız"),
            ("3", "3 Yıldız"),
            ("4", "4 Yıldız"),
            ("5", "5 Yıldız"),
        ],
    )
    max_rating = forms.ChoiceField(
        label="Maximum Puan",
        required=False,
        choices=[
            ("", "Tümü"),
            ("1", "1 Yıldız"),
            ("2", "2 Yıldız"),
            ("3", "3 Yıldız"),
            ("4", "4 Yıldız"),
            ("5", "5 Yıldız"),
        ],
    )
    date_from = forms.DateField(label="Başlangıç Tarihi", required=False, widget=forms.DateInput(attrs={"type": "date"}))
    date_to = forms.DateField(label="Bitiş Tarihi", required=False, widget=forms.DateInput(attrs={"type": "date"}))
    has_reply = forms.ChoiceField(
        label="Yanıt Durumu",
        required=False,
        choices=[
            ("", "Tümü"),
            ("true", "Yanıtlanmış"),
            ("false", "Yanıtlanmamış"),
        ],
    )

    def __init__(self, *args, **kwargs):
        doctor_choices = kwargs.pop("doctor_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["doctor"].choices = [("", "Tüm Doktorlar")] + doctor_choices


class ReviewReplyForm(forms.Form):
    review_id = forms.CharField(widget=forms.HiddenInput)
    reply = forms.CharField(label="Yanıt", widget=forms.Textarea(attrs={"rows": 4}))


class GeneralSettingsForm(forms.Form):
    active_hospital_id = forms.ChoiceField(label="Aktif Hastane", choices=[])
    panel_title = forms.CharField(label="Panel Başlığı", max_length=120)
    date_format = forms.ChoiceField(
        label="Tarih Formatı",
        choices=[
            ("DD.MM.YYYY", "DD.MM.YYYY"),
            ("MM/DD/YYYY", "MM/DD/YYYY"),
            ("YYYY-MM-DD", "YYYY-MM-DD"),
        ],
    )
    time_format = forms.ChoiceField(
        label="Saat Formatı",
        choices=[
            ("24", "24 Saat"),
            ("12", "12 Saat (AM/PM)"),
        ],
    )
    language = forms.ChoiceField(
        label="Dil",
        choices=[
            ("tr", "Türkçe"),
            ("en", "English"),
        ],
    )

    def __init__(self, *args, **kwargs):
        hospital_choices = kwargs.pop("hospital_choices", [])
        super().__init__(*args, **kwargs)
        self.fields["active_hospital_id"].choices = hospital_choices


class NotificationSettingsForm(forms.Form):
    email_enabled = forms.BooleanField(label="E-posta Bildirimleri", required=False)
    new_appointment = forms.BooleanField(label="Yeni Randevu Bildirimi", required=False)
    new_review = forms.BooleanField(label="Yeni Yorum Bildirimi", required=False)
    appointment_reminder = forms.BooleanField(label="Randevu Hatırlatması", required=False)
    reminder_hours_before = forms.IntegerField(
        label="Hatırlatma Süresi (Saat)",
        min_value=1,
        max_value=168,
        help_text="Randevudan kaç saat önce hatırlatma gönderilsin?",
    )


class DataManagementForm(forms.Form):
    backup_enabled = forms.BooleanField(label="Otomatik Yedekleme", required=False)
    auto_backup_days = forms.IntegerField(
        label="Yedekleme Sıklığı (Gün)",
        min_value=1,
        max_value=30,
        help_text="Kaç günde bir otomatik yedekleme yapılsın?",
    )


class SecuritySettingsForm(forms.Form):
    session_timeout_minutes = forms.IntegerField(
        label="Oturum Zaman Aşımı (Dakika)",
        min_value=5,
        max_value=480,
        help_text="Kaç dakika hareketsiz kalındığında oturum sonlandırılsın?",
    )


class AppearanceSettingsForm(forms.Form):
    theme = forms.ChoiceField(
        label="Tema",
        choices=[
            ("default", "Varsayılan"),
            ("light", "Açık"),
            ("dark", "Koyu"),
        ],
    )
    show_dashboard_widgets = forms.BooleanField(label="Dashboard Widget'larını Göster", required=False)
    records_per_page = forms.IntegerField(
        label="Sayfa Başına Kayıt Sayısı",
        min_value=5,
        max_value=100,
    )
