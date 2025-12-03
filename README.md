# Dişçi Bul

Kurumsal diş hastanesi/klinik yönetim çözümü. Flutter tabanlı hasta uygulaması ile Django paneli aynı repoda tutulur; Supabase veri katmanı ve telemetry altyapısı ile entegredir.

- **Flutter (klasör:** `django_panel/klasor/app_dent`)  
  - Riverpod tabanlı state yönetimi  
  - Randevu alma/iptal, klinik ve doktor arama, bildirim ve dil ayarları  
  - Supabase ve yerel JSON servisleri üzerinden veri tüketimi
- **Django Panel (klasör:** `django_panel/`)  
  - Supabase ile senkron çalışan yönetim paneli  
  - E-posta/Supabase anahtar yönetimi `.env` ile sağlanır

## İçindekiler
1. [Mimari Özeti](#mimari-özeti)  
2. [Ön Gereksinimler](#ön-gereksinimler)  
3. [Kurulum](#kurulum)  
4. [Flutter Uygulamasını Çalıştırma](#flutter-uygulamasını-çalıştırma)  
5. [Django Panelini Çalıştırma](#django-panelini-çalıştırma)  
6. [State Yönetimi ve Modüler Yapı](#state-yönetimi-ve-modüler-yapı)  
7. [Telemetry ve Supabase Ayarları](#telemetry-ve-supabase-ayarları)  
8. [Testler](#testler)  
9. [CI/CD](#cicd)  
10. [Katkı Rehberi](#katkı-rehberi)

## Mimari Özeti

```text
Flutter App (Riverpod)  <--->  Supabase  <--->  Django Panel Services
            \                                /
             \-- Telemetry (event_service) --/
```

- Flutter uygulaması Riverpod StateNotifier controller’larıyla parçalanmıştır (`lib/providers/*`).
- Django panel servisleri (örn. `panel/services/appointment_service.py`) Supabase REST API’lerini kullanır.
- Telemetry ve kritik iş akış metrikleri Supabase event tablolarında tutulur (bkz. `TELEMETRY.md`).

## Ön Gereksinimler

| Bileşen            | Sürüm / Not                             |
|--------------------|-----------------------------------------|
| Flutter SDK        | 3.24+ (stable channel)                  |
| Dart               | Flutter ile gelen sürüm                 |
| Python             | 3.11+                                   |
| Pipenv / pip       | Tercihe göre                            |
| Node / npm         | (Opsiyonel) yalnızca Supabase CLI için |
| Supabase hesabı    | URL + service role key gerekli          |

## Kurulum

1. Repoyu klonla  
   ```bash
   git clone https://github.com/<org>/dent_admin_app.git
   cd dent_admin_app
   ```
2. **Django ortam değişkenleri**  
   - `django_panel/.env` dosyasını oluştur ve `ENV_SETUP_GUIDE.md`’deki talimatla doldur.
3. **Flutter ortam değişkenleri**  
   - `django_panel/klasor/app_dent/assets/env.client` dosyasını Supabase `SUPABASE_URL` ve `SUPABASE_ANON_KEY` değerleriyle güncelle.
4. Bağımlılıkları kur  
   ```bash
   # Django
   cd django_panel
   python -m pip install -r requirements.txt

   # Flutter
   cd klasor/app_dent
   flutter pub get
   ```

## Flutter Uygulamasını Çalıştırma

```bash
cd django_panel/klasor/app_dent
flutter run --flavor staging
```

- Varsayılan giriş ekranı Supabase Auth olmayan mock akışa dayanır; gerçek API geçişi için `JsonService` adaptörlerini güncelle.
- Hot reload/hot restart desteklenir.

## Kullanıcı Kayıt & E-posta Doğrulaması

- Supabase Dashboard → **Authentication → Providers → Email** bölümünde “Confirm email” seçeneğini açık tut.
- (Opsiyonel) Aynı sayfada `SITE_URL` ve `EMAIL_REDIRECT_URL` alanlarını Flutter uygulamasının desteklediği deep-link’e yönlendirirsen doğrulama sonrası kullanıcı otomatik olarak mobil uygulamaya dönebilir.
- Flutter’daki kayıt akışı:
  1. Kullanıcı formu doldurur, Supabase `signUp` çağrısı yapılır.
  2. Kayıt sonrası uygulama doğrulama diyalogu gösterir ve Login ekranına geri döner; kullanıcı e-postasını doğrulamadan devam edemez.
  3. Login ekranı Supabase’ten gelen `email not confirmed` hatalarını yakalar ve kullanıcıyı bilgilendirir.
  4. Kullanıcı e-postasını doğrulayıp giriş yaptığında, login ekranına verilen `onLoginSuccess` callback sayesinde başlangıçta gitmek istediği akış (ör: randevu oluşturma) tekrar açılır.
- Django panel veya CLI’dan kullanıcı oluşturulacaksa aynı kurala uyulmalı; eğer servis üzerinden doğrulanmamış kullanıcı oluşturursan mobil uygulamada giriş yapamaz.

## Django Panelini Çalıştırma

```bash
cd django_panel
python manage.py migrate
python manage.py runserver
```

- Yönetim paneli varsayılan olarak `http://127.0.0.1:8000` adresinden servis verir.
- Supabase’e bağlanmak için `.env` veya GitHub Actions ortam değişkenlerinde Supabase anahtarları hazır olmalıdır.

## State Yönetimi ve Modüler Yapı

- Riverpod StateNotifier yapısı tüm kritik akışlara uygulanmıştır:
  - `appointments_provider.dart`, `create_appointment_provider.dart`
  - `profile_provider.dart`, `auth_provider.dart`
  - `notification_settings_provider.dart`, `language_settings_provider.dart`
- Her controller yalnızca iş mantığını içerir; ekranlar `ConsumerWidget` / `ConsumerStatefulWidget` olarak sade tutulur.
- Ortak modeller `lib/models` klasöründe, servis katmanı `lib/services` altında bulunur.

## Telemetry ve Supabase Ayarları

- Telemetry rehberi için `TELEMETRY.md` dosyasını incele.
- Flutter tarafında `AppEventService` üzerinden, panel tarafında `panel/services/event_service.py` üzerinden Supabase event tablosuna yazılır.
- Supabase bağlantısı:
  - Flutter: `lib/config/supabase_config.dart`
  - Django: `panel/services/supabase_client.py`

## Testler

| Komut                                  | Açıklama                                  |
|----------------------------------------|--------------------------------------------|
| `python manage.py test panel`          | Django servis testleri                     |
| `flutter test`                         | Flutter unit/widget ve provider testleri   |

Yeni testler eklerken:
- Supabase çağrılarını mock’larsan CI’da gerçek bağlantıya ihtiyaç kalmaz.
- Flutter tarafında SharedPreferences için `SharedPreferences.setMockInitialValues` kullan.

## CI/CD

- `.github/workflows/ci.yml` iki job çalıştırır:
  1. **Django Tests:** Python 3.11 üzerinde `manage.py test panel`
  2. **Flutter Tests:** Stable channel Flutter ile `flutter test`
- Workflow hem `push` hem `pull_request` için `main` branch’inde tetiklenir.
- Gerekli env değerleri job içinde sahte olarak tanımlanmıştır; gerçek ortamlarda Secrets kullanabilirsin.

## Katkı Rehberi

1. Yeni bir branch aç (`feature/<özellik-adi>`).
2. Düzenlemeleri yap, `flutter test` ve `python manage.py test panel` komutlarını çalıştır.
3. CI yeşil olmadan PR açma.
4. Kod incelemesi sonrası merge et.

Sorular için proje yöneticisiyle iletişime geçebilir veya ilgili dosyalardaki yorumlara bakabilirsin; telemetry veya Supabase yapılandırmasıyla ilgili güncellemeleri `TELEMETRY.md` ve `ENV_SETUP_GUIDE.md` üzerinden senkron tutmayı unutma.