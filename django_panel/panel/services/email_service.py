"""Email gönderim servisi."""

from __future__ import annotations

from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string


def send_hospital_registration_notification(hospital_data: dict) -> bool:
    """Yeni hastane kayıt isteği için admin'e email gönderir.
    
    Args:
        hospital_data: Hastane bilgileri dict'i
        
    Returns:
        bool: Email başarıyla gönderildiyse True
    """
    try:
        subject = f"Yeni Hastane Kayıt İsteği - {hospital_data.get('name', 'Bilinmeyen')}"
        
        # Email içeriği
        message = f"""
Merhaba,

Yeni bir hastane kayıt isteği alındı.

Hastane Bilgileri:
- Ad: {hospital_data.get('name', '')}
- Adres: {hospital_data.get('address', '')}
- Telefon: {hospital_data.get('phone', '')}
- Email: {hospital_data.get('email', '')}
- Açıklama: {hospital_data.get('description', '')}

Kayıt Durumu: Onay Bekliyor

Lütfen Supabase panel'den hastaneyi inceleyip onaylayın veya reddedin.

Supabase Dashboard: {settings.SUPABASE_URL.replace('https://', 'https://app.supabase.com/project/')}
        """
        
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[settings.ADMIN_EMAIL],
            fail_silently=False,
        )
        
        return True
    except Exception as e:
        print(f"Email gönderim hatası: {e}")
        return False


def send_hospital_approval_notification(hospital_email: str, hospital_code: str, hospital_name: str) -> bool:
    """Hastane onaylandığında kullanıcıya email gönderir.
    
    Args:
        hospital_email: Hastane sahibinin email'i
        hospital_code: 6 haneli giriş kodu
        hospital_name: Hastane adı
        
    Returns:
        bool: Email başarıyla gönderildiyse True
    """
    try:
        subject = f"Hastane Kaydınız Onaylandı - {hospital_name}"
        
        message = f"""
Merhaba,

Hastane kaydınız onaylandı!

Hastane Adı: {hospital_name}
Giriş Kodunuz: {hospital_code}

Giriş yapmak için:
1. Panel giriş sayfasına gidin
2. Giriş kodunuzu, email adresinizi ve şifrenizi girin
3. Panel'e erişebilirsiniz

Giriş Sayfası: http://127.0.0.1:8000/login/

Not: Giriş kodunuzu güvenli bir yerde saklayın.

İyi çalışmalar!
        """
        
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[hospital_email],
            fail_silently=False,
        )
        
        return True
    except Exception as e:
        print(f"Email gönderim hatası: {e}")
        return False

