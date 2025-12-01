# Windows Task Scheduler Kurulum Talimatları

Windows'ta randevu durumlarını otomatik olarak güncellemek için Windows Task Scheduler kullanılmalıdır.

## Yöntem 1: Windows Task Scheduler (Önerilen)

### Adım 1: Task Scheduler'ı Açın

1. Windows tuşuna basın ve "Task Scheduler" yazın
2. "Task Scheduler" uygulamasını açın

### Adım 2: Yeni Görev Oluşturun

1. Sağ tarafta "Create Basic Task..." veya "Create Task..." seçeneğine tıklayın
2. Görev için bir isim verin (örn: "Update Appointment Statuses")
3. Açıklama ekleyin: "Randevu durumlarını otomatik olarak günceller"

### Adım 3: Tetikleyici Ayarlayın

1. "Trigger" sekmesine gidin
2. "New..." butonuna tıklayın
3. "Begin the task" kısmında "On a schedule" seçin
4. "Settings" kısmında:
   - **Her saat başı için**: "Daily" seçin, "Repeat task every" kısmına "1 hour" yazın
   - **Her 30 dakikada bir için**: "Daily" seçin, "Repeat task every" kısmına "30 minutes" yazın
   - **Her gün gece yarısı için**: "Daily" seçin, "Start time" kısmına "00:00:00" yazın

### Adım 4: Eylem (Action) Ayarlayın

1. "Actions" sekmesine gidin
2. "New..." butonuna tıklayın
3. "Action" kısmında "Start a program" seçin
4. "Program/script" kısmına Python'un tam yolunu yazın:
   ```
   C:\Python39\python.exe
   ```
   Veya virtualenv kullanıyorsanız:
   ```
   C:\Users\Cem\Documents\GitHub\dent_admin_app\venv\Scripts\python.exe
   ```
5. "Add arguments" kısmına:
   ```
   manage.py update_appointment_statuses
   ```
6. "Start in" kısmına Django projenizin tam yolunu yazın:
   ```
   C:\Users\Cem\Documents\GitHub\dent_admin_app\django_panel
   ```

### Adım 5: Koşullar (Conditions) Ayarlayın

1. "Conditions" sekmesine gidin
2. "Start the task only if the computer is on AC power" seçeneğini kaldırın (laptop için)
3. "Wake the computer to run this task" seçeneğini işaretleyin (isteğe bağlı)

### Adım 6: Ayarlar (Settings) Ayarlayın

1. "Settings" sekmesine gidin
2. "Allow task to be run on demand" seçeneğini işaretleyin
3. "If the task fails, restart every" seçeneğini işaretleyip "10 minutes" yazın
4. "Stop the task if it runs longer than" seçeneğini işaretleyip "1 hour" yazın

### Adım 7: Test Edin

1. Görevi sağ tıklayıp "Run" seçeneğine tıklayın
2. "Last Run Result" kısmında başarılı olup olmadığını kontrol edin

## Yöntem 2: Python Script ile Windows Service (Gelişmiş)

Eğer daha gelişmiş bir çözüm istiyorsanız, Python'un `schedule` kütüphanesini kullanabilirsiniz.

### Adım 1: Schedule Kütüphanesini Kurun

```bash
pip install schedule
```

### Adım 2: Service Script Oluşturun

`django_panel/panel/services/appointment_status_service.py` dosyası oluşturun:

```python
import schedule
import time
from django.core.management import call_command
import os
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')
django.setup()

def update_appointments():
    call_command('update_appointment_statuses')

# Her saat başı çalıştır
schedule.every().hour.do(update_appointments)

while True:
    schedule.run_pending()
    time.sleep(60)  # Her dakika kontrol et
```

## Yöntem 3: Manuel Test

Komutu manuel olarak test etmek için:

```bash
cd C:\Users\Cem\Documents\GitHub\dent_admin_app\django_panel
python manage.py update_appointment_statuses
```

## Sorun Giderme

### Python Yolu Bulunamıyor

Python'un tam yolunu bulmak için:
```bash
where python
```

### Virtualenv Kullanıyorsanız

Virtualenv'in Python'unu kullanın:
```
C:\Users\Cem\Documents\GitHub\dent_admin_app\venv\Scripts\python.exe
```

### Log Dosyası Oluşturma

Task Scheduler'da "Add arguments" kısmına log eklemek için:
```
manage.py update_appointment_statuses >> C:\logs\appointment_status.log 2>&1
```

Önce log klasörünü oluşturun:
```bash
mkdir C:\logs
```

## Notlar

- Windows Task Scheduler, bilgisayar kapalıyken çalışmaz
- Bilgisayarın açık olması gerekir
- Eğer sürekli çalışan bir sunucu varsa, Linux/Unix kullanmanız önerilir
- Development ortamında manuel olarak çalıştırabilirsiniz

