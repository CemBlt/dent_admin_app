## Telemetry & Event Logging
Bu proje için Flutter uygulaması ve Django paneli artık merkezi bir `app_events` tablosuna gönderim yapıyor. Kurulum için Supabase SQL editöründe aşağıdaki komutu çalıştırmanız yeterli:

```sql
create table if not exists app_events (
  id uuid primary key default gen_random_uuid(),
  event_name text not null,
  user_id uuid,
  hospital_id uuid,
  event_props jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc', now())
);
```

### Kayıt Örnekleri

| Event Adı | Kaynak | Açıklama |
|-----------|--------|----------|
| `app_opened` | Flutter | Uygulama açıldığında `MainScreen` tarafından tetiklenir. |
| `cta_create_appointment_pressed` | Flutter | Ana ekrandaki randevu oluştur butonu tıklandığında gönderilir. |
| `appointment_created_backend` | Flutter | Supabase'e başarılı randevu kaydı sonrası otomatik log. |
| `panel_login_success` | Django Panel | Başarılı panel girişlerinde tetiklenir. |
| `hospital_general_updated` | Django Panel | Hastane genel ayarları kaydedildiğinde gönderilir. |
| `panel_settings_*` | Django Panel | Ayarlar sekmesindeki kaydet işlemleri için detaylı event seti. |

`event_props` alanı JSON olduğu için ihtiyaç duyduğunuz ek bilgileri (ör. `doctor_id`, `theme`, `status`) özgürce ekleyebilirsiniz.

### Raporlama

Örnek sorgular:

```sql
select event_name, count(*) as hit_count, max(created_at) as last_seen
from app_events
group by event_name
order by hit_count asc;
```

Grup bazlı filtrelemek için:

```sql
select date_trunc('day', created_at) as day, event_name, count(*)
from app_events
where created_at >= now() - interval '30 days'
group by 1, 2
order by 1;
```

Bu yapı sayesinde hangi feature'ların aktif kullanıldığını izleyebilir, kullanılmayan ekran/aksiyonları veriyle tespit edebilirsiniz.

