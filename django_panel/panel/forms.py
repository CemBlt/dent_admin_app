from __future__ import annotations

from django import forms
from django.core.exceptions import ValidationError
from django.utils.safestring import mark_safe

REQUIRED_LOGO_WIDTH = 400
REQUIRED_LOGO_HEIGHT = 300


def validate_logo_image(file):
    """
    Logo görselinin zorunlu ölçülerde (400x300px) olup olmadığını kontrol eder.
    """
    if not file:
        return

    try:
        from PIL import Image
    except ImportError as exc:
        raise ValidationError(
            "Görsel doğrulaması için Pillow kütüphanesi gerekli. "
            "Lütfen sistem yöneticisine Pillow kurulumunu sorunuz."
        ) from exc

    if hasattr(file, "seek"):
        file.seek(0)

    try:
        image = Image.open(file)
        image.load()
    except Exception:
        raise ValidationError("Lütfen geçerli bir görsel dosyası yükleyin.")
    finally:
        if hasattr(file, "seek"):
            file.seek(0)

    width, height = image.size
    if width != REQUIRED_LOGO_WIDTH or height != REQUIRED_LOGO_HEIGHT:
        raise ValidationError(
            f"Logo {REQUIRED_LOGO_WIDTH}x{REQUIRED_LOGO_HEIGHT}px ölçülerinde olmalıdır. "
            "Yüklediğiniz görsel bu kriteri karşılamıyor."
        )


class MultipleFileInput(forms.FileInput):
    """Multiple file upload desteği olan FileInput widget'ı"""
    def __init__(self, attrs=None):
        # Django multiple attribute'unu reddediyor, bu yüzden __init__'te eklemiyoruz
        if attrs is None:
            attrs = {}
        # multiple'ı attrs'tan çıkar (varsa)
        attrs = {k: v for k, v in attrs.items() if k != 'multiple'}
        super().__init__(attrs)
    
    def render(self, name, value, attrs=None, renderer=None):
        # HTML'i manuel oluştur ve multiple attribute'unu ekle
        if attrs is None:
            attrs = {}
        # multiple'ı attrs'tan çıkar (varsa) - Django bunu reddediyor
        attrs = {k: v for k, v in attrs.items() if k != 'multiple'}
        
        # HTML'i manuel oluştur
        final_attrs = self.build_attrs(attrs, extra_attrs={'name': name})
        final_attrs['type'] = 'file'
        
        # HTML string'ini oluştur
        html = '<input'
        for key, val in final_attrs.items():
            html += f' {key}="{val}"'
        html += ' multiple>'
        return mark_safe(html)

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
    logo = forms.FileField(
        label="Logo",
        required=False,
        help_text=f"{REQUIRED_LOGO_WIDTH}x{REQUIRED_LOGO_HEIGHT}px boyutlarında PNG veya JPG yükleyin",
    )

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

    def clean_logo(self):
        logo = self.cleaned_data.get("logo")
        if logo:
            validate_logo_image(logo)
        return logo


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
    # 7/24 Açık seçeneği
    is_open_24_hours = forms.BooleanField(
        label="7/24 Açık",
        required=False,
        help_text="İşaretlendiğinde çalışma saatleri girmenize gerek kalmaz"
    )
    
    def __init__(self, *args, **kwargs):
        initial = kwargs.pop('initial', {})
        super().__init__(*args, **kwargs)
        
        # 7/24 açık initial değeri
        is_open_24_hours_initial = initial.get('is_open_24_hours', False)
        self.fields['is_open_24_hours'].initial = is_open_24_hours_initial
        
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
    images = forms.FileField(
        label="Galeri Görselleri",
        widget=MultipleFileInput(attrs={'accept': 'image/*'}),
        help_text="Birden fazla görsel seçebilirsiniz (Maksimum 5 görsel)"
    )


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
            ("completed", "Tamamlandı"),
            ("cancelled", "İptal"),
        ],
    )


class ScheduleFilterForm(forms.Form):
    doctor = forms.ChoiceField(label="Doktor", required=False)
    year = forms.IntegerField(label="Yıl", min_value=2020, max_value=2100)
    month = forms.ChoiceField(
        label="Ay",
        choices=[
            ("1", "Ocak"),
            ("2", "Şubat"),
            ("3", "Mart"),
            ("4", "Nisan"),
            ("5", "Mayıs"),
            ("6", "Haziran"),
            ("7", "Temmuz"),
            ("8", "Ağustos"),
            ("9", "Eylül"),
            ("10", "Ekim"),
            ("11", "Kasım"),
            ("12", "Aralık"),
        ],
    )

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


class LoginForm(forms.Form):
    """Login formu - Hospital Code, Email ve Şifre"""
    hospital_code = forms.CharField(
        label="Hastane Kodu",
        max_length=10,
        widget=forms.TextInput(attrs={
            'placeholder': '123456',
            'class': 'form-control'
        })
    )
    email = forms.EmailField(
        label="E-posta",
        widget=forms.EmailInput(attrs={
            'placeholder': 'ornek@email.com',
            'class': 'form-control'
        })
    )
    password = forms.CharField(
        label="Şifre",
        widget=forms.PasswordInput(attrs={
            'placeholder': 'Şifrenizi girin',
            'class': 'form-control'
        })
    )


class HospitalRegistrationForm(forms.Form):
    """Hastane kayıt formu - Tüm hastane bilgileri + email + şifre"""
    # Kullanıcı bilgileri (Supabase Auth için)
    email = forms.EmailField(
        label="E-posta",
        help_text="Giriş yapmak için kullanacağınız email adresi",
        widget=forms.EmailInput(attrs={'class': 'form-control'})
    )
    password = forms.CharField(
        label="Şifre",
        min_length=6,
        widget=forms.PasswordInput(attrs={'class': 'form-control'}),
        help_text="En az 6 karakter olmalıdır"
    )
    password_confirm = forms.CharField(
        label="Şifre Tekrar",
        widget=forms.PasswordInput(attrs={'class': 'form-control'})
    )
    
    # Hastane bilgileri
    name = forms.CharField(label="Hastane Adı", max_length=120, widget=forms.TextInput(attrs={'class': 'form-control'}))
    address = forms.CharField(label="Adres Açıklaması", max_length=200, required=False, widget=forms.TextInput(attrs={'class': 'form-control'}))
    province = forms.ChoiceField(label="İl", choices=[])
    district = forms.ChoiceField(label="İlçe", choices=[])
    neighborhood = forms.ChoiceField(label="Mahalle", choices=[])
    latitude = forms.DecimalField(label="Enlem (Latitude)", max_digits=10, decimal_places=6, widget=forms.NumberInput(attrs={'class': 'form-control', 'step': '0.000001'}))
    longitude = forms.DecimalField(label="Boylam (Longitude)", max_digits=10, decimal_places=6, widget=forms.NumberInput(attrs={'class': 'form-control', 'step': '0.000001'}))
    phone = forms.CharField(label="Telefon", max_length=20, widget=forms.TextInput(attrs={'class': 'form-control'}))
    hospital_email = forms.EmailField(label="Hastane E-posta", max_length=120, widget=forms.EmailInput(attrs={'class': 'form-control'}))
    description = forms.CharField(label="Açıklama", widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 4}), required=False)
    logo = forms.FileField(
        label="Logo",
        required=False,
        help_text=f"{REQUIRED_LOGO_WIDTH}x{REQUIRED_LOGO_HEIGHT}px boyutunda PNG/JPG yükleyin",
        widget=forms.FileInput(attrs={'class': 'form-control', 'accept': 'image/*'}),
    )
    
    # 7/24 Açık seçeneği
    is_open_24_hours = forms.BooleanField(
        label="7/24 Açık",
        required=False,
        help_text="İşaretlenirse çalışma saatleri girilmesine gerek kalmaz",
        widget=forms.CheckboxInput(attrs={'class': 'form-check-input'})
    )
    
    # Çalışma saatleri (basitleştirilmiş - sadece hafta içi/hafta sonu)
    working_hours_monday = forms.BooleanField(label="Pazartesi", required=False, initial=True)
    working_hours_tuesday = forms.BooleanField(label="Salı", required=False, initial=True)
    working_hours_wednesday = forms.BooleanField(label="Çarşamba", required=False, initial=True)
    working_hours_thursday = forms.BooleanField(label="Perşembe", required=False, initial=True)
    working_hours_friday = forms.BooleanField(label="Cuma", required=False, initial=True)
    working_hours_saturday = forms.BooleanField(label="Cumartesi", required=False)
    working_hours_sunday = forms.BooleanField(label="Pazar", required=False)
    
    working_hours_start = forms.ChoiceField(
        label="Başlangıç Saati",
        choices=TIME_CHOICES,
        initial="09:00",
        widget=forms.Select(attrs={'class': 'form-control'})
    )
    working_hours_end = forms.ChoiceField(
        label="Bitiş Saati",
        choices=TIME_CHOICES,
        initial="18:00",
        widget=forms.Select(attrs={'class': 'form-control'})
    )

    def __init__(self, *args, **kwargs):
        province_choices = kwargs.pop("province_choices", [])
        district_choices = kwargs.pop("district_choices", [])
        neighborhood_choices = kwargs.pop("neighborhood_choices", [])
        super().__init__(*args, **kwargs)

        self.fields["province"].choices = [("", "İl seçin")] + province_choices
        self.fields["province"].widget.attrs.update({'class': 'form-control'})

        if district_choices:
            self.fields["district"].choices = [("", "İlçe seçin")] + district_choices
            self.fields["district"].widget.attrs.update({'class': 'form-control'})
            self.fields["district"].widget.attrs.pop("disabled", None)
        else:
            self.fields["district"].choices = [("", "Önce il seçin")]
            self.fields["district"].widget.attrs.update({'class': 'form-control', 'disabled': 'disabled'})

        if neighborhood_choices:
            self.fields["neighborhood"].choices = [("", "Mahalle seçin")] + neighborhood_choices
            self.fields["neighborhood"].widget.attrs.update({'class': 'form-control'})
            self.fields["neighborhood"].widget.attrs.pop("disabled", None)
        else:
            self.fields["neighborhood"].choices = [("", "Önce ilçe seçin")]
            self.fields["neighborhood"].widget.attrs.update({'class': 'form-control', 'disabled': 'disabled'})

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        password_confirm = cleaned_data.get("password_confirm")
        is_open_24_hours = cleaned_data.get("is_open_24_hours", False)
        
        if password and password_confirm:
            if password != password_confirm:
                raise forms.ValidationError("Şifreler eşleşmiyor.")
        
        # 7/24 açık değilse çalışma saatleri kontrolü yapılabilir (opsiyonel)
        # Şu an için zorunlu değil, sadece bilgi amaçlı
        
        return cleaned_data

    def clean_logo(self):
        logo = self.cleaned_data.get("logo")
        if logo:
            validate_logo_image(logo)
        return logo
