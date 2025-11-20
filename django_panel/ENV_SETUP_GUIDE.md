# .env Dosyası Kurulum Rehberi

Bu rehber, `.env` dosyasını nasıl dolduracağınızı adım adım açıklar.

## 1. Supabase Ayarları

### SUPABASE_URL ve SUPABASE_ANON_KEY Nasıl Bulunur?

1. [Supabase Dashboard](https://app.supabase.com/)'a giriş yapın
2. Projenizi seçin
3. Sol menüden **Settings** > **API** seçeneğine tıklayın
4. Şu bilgileri kopyalayın:
   - **Project URL** → `SUPABASE_URL` olarak kullanın
   - **anon public** key → `SUPABASE_ANON_KEY` olarak kullanın
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY` olarak kullanın (zaten varsa)

**Örnek:**
```
SUPABASE_URL=https://lvbtbffqggupxmybozde.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 2. Gmail SMTP Ayarları

### EMAIL_HOST_USER ve EMAIL_HOST_PASSWORD Nasıl Alınır?

Gmail için **App Password** (Uygulama Şifresi) kullanmanız gerekiyor. Normal şifreniz çalışmaz!

#### Adım 1: Google Hesabınızda 2 Adımlı Doğrulamayı Aktif Edin

1. [Google Hesap Ayarları](https://myaccount.google.com/)'na gidin
2. **Güvenlik** sekmesine tıklayın
3. **2 Adımlı Doğrulama**'yı açın (eğer kapalıysa)

#### Adım 2: App Password (Uygulama Şifresi) Oluşturun

1. [Google App Passwords](https://myaccount.google.com/apppasswords) sayfasına gidin
2. **Uygulama seçin** → "Mail" seçin
3. **Cihaz seçin** → "Diğer (Özel ad)" yazın → "Django Panel" yazın
4. **Oluştur** butonuna tıklayın
5. **16 haneli şifreyi kopyalayın** (boşluksuz, örnek: `abcd efgh ijkl mnop` → `abcdefghijklmnop`)

**Örnek:**
```
EMAIL_HOST_USER=cem.bulut@gmail.com
EMAIL_HOST_PASSWORD=abcdefghijklmnop  # App Password (16 haneli)
DEFAULT_FROM_EMAIL=cem.bulut@gmail.com
```

### ⚠️ Önemli Notlar:

- **Normal Gmail şifreniz çalışmaz!** Mutlaka App Password kullanın
- App Password'u güvenli bir yerde saklayın
- App Password'u tekrar göremezsiniz, kaybederseniz yeni bir tane oluşturmanız gerekir

## 3. Diğer Email Ayarları

Bu değerler Gmail için sabit kalabilir:

```
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
ADMIN_EMAIL=cem.bulut@bumel.com.tr
```

## 4. .env Dosyasını Oluşturma

1. `django_panel` klasöründe `.env` adında bir dosya oluşturun
2. `.env.example` dosyasını kopyalayıp `.env` olarak kaydedin
3. Yukarıdaki adımlara göre değerleri doldurun

**Windows'ta:**
- Notepad veya herhangi bir metin editörü ile `.env` dosyası oluşturun
- Dosya adı sadece `.env` olmalı (uzantı yok!)

**Örnek .env dosyası:**
```env
# Supabase Ayarları
SUPABASE_URL=https://lvbtbffqggupxmybozde.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2YnRiZmZxZ2d1cHhteWJvemRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzU0MDU1NCwiZXhwIjoyMDc5MTE2NTU0fQ.xxxxx
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2YnRiZmZxZ2d1cHhteWJvemRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NDA1NTQsImV4cCI6MjA3OTExNjU1NH0.xxxxx

# Email Ayarları
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=cem.bulut@gmail.com
EMAIL_HOST_PASSWORD=abcdefghijklmnop
DEFAULT_FROM_EMAIL=cem.bulut@gmail.com

# Admin Email
ADMIN_EMAIL=cem.bulut@bumel.com.tr
```

## 5. Test Etme

Dosyayı oluşturduktan sonra Django sunucusunu yeniden başlatın:

```bash
python manage.py runserver
```

Eğer hata alırsanız, `.env` dosyasının doğru konumda olduğundan emin olun (`django_panel/.env`).

## Sorun Giderme

### "Module not found: dotenv" hatası
```bash
pip install python-dotenv
```

### Email gönderilemiyor
- App Password kullandığınızdan emin olun
- 2 Adımlı Doğrulama'nın açık olduğunu kontrol edin
- Gmail'in "Daha az güvenli uygulamalara izin ver" ayarını kontrol edin (artık gerekmiyor, App Password yeterli)

### Supabase bağlantı hatası
- URL ve key'lerin doğru kopyalandığından emin olun
- Boşluk veya fazladan karakter olmadığından emin olun

