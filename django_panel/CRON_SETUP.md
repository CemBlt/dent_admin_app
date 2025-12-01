# Cron Job Kurulum Talimatları (Linux/Unix/Mac)

**NOT: Windows kullanıyorsanız, `WINDOWS_TASK_SCHEDULER_SETUP.md` dosyasına bakın.**

Bu dosya, randevu durumlarını otomatik olarak güncellemek için cron job kurulumunu açıklar (Linux/Unix/Mac için).

## Komut

Django management command'i periyodik olarak çalıştırmak için cron job kullanılmalıdır.

## Kurulum Adımları

### 1. Crontab Dosyasını Düzenle

```bash
crontab -e
```

### 2. Cron Job Ekle

Her saat başı çalışması için:

```bash
0 * * * * cd /path/to/django_panel && /path/to/python manage.py update_appointment_statuses >> /var/log/appointment_status_update.log 2>&1
```

Her 30 dakikada bir çalışması için:

```bash
*/30 * * * * cd /path/to/django_panel && /path/to/python manage.py update_appointment_statuses >> /var/log/appointment_status_update.log 2>&1
```

Her gün saat 00:00'da çalışması için:

```bash
0 0 * * * cd /path/to/django_panel && /path/to/python manage.py update_appointment_statuses >> /var/log/appointment_status_update.log 2>&1
```

### 3. Path'leri Güncelle

- `/path/to/django_panel`: Django projenizin tam yolu
- `/path/to/python`: Python interpreter'ınızın tam yolu (genellikle virtualenv içindeki python)

Örnek:
```bash
0 * * * * cd /home/user/dent_admin_app/django_panel && /home/user/dent_admin_app/venv/bin/python manage.py update_appointment_statuses >> /var/log/appointment_status_update.log 2>&1
```

### 4. Log Dosyası İzinlerini Kontrol Et

```bash
sudo touch /var/log/appointment_status_update.log
sudo chmod 666 /var/log/appointment_status_update.log
```

Veya kullanıcı dizininizde log tutmak için:

```bash
0 * * * * cd /path/to/django_panel && /path/to/python manage.py update_appointment_statuses >> ~/appointment_status_update.log 2>&1
```

## Test Etme

Cron job'u manuel olarak test etmek için:

```bash
cd /path/to/django_panel
/path/to/python manage.py update_appointment_statuses
```

## Cron Format Açıklaması

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Haftanın günü (0-7, 0 ve 7 = Pazar)
│ │ │ └───── Ay (1-12)
│ │ └─────── Ayın günü (1-31)
│ └───────── Saat (0-23)
└─────────── Dakika (0-59)
```

## Örnekler

- `0 * * * *` - Her saat başı
- `*/30 * * * *` - Her 30 dakikada bir
- `0 0 * * *` - Her gün gece yarısı
- `0 9 * * 1` - Her Pazartesi saat 09:00
- `0 0 1 * *` - Her ayın 1'inde gece yarısı

## Notlar

- Cron job'un çalıştığından emin olmak için log dosyasını kontrol edin
- Django settings'teki SUPABASE ayarlarının doğru olduğundan emin olun
- Virtualenv kullanıyorsanız, cron job'da virtualenv'in python'unu kullanın

