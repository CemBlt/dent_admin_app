-- Supabase appointments tablosuna unique constraint ekleme
-- Bu SQL komutunu Supabase Dashboard > SQL Editor'de çalıştırın
-- 
-- Bu constraint, aynı doktorun aynı tarih ve saatte birden fazla randevu almasını engeller
-- Sadece 'cancelled' (iptal edilmiş) randevular hariç tutulur
--
-- NOT: Eğer duplicate randevular varsa, önce fix_duplicate_appointments.sql dosyasını çalıştırın

-- Önce mevcut index'i kontrol et ve varsa sil
DROP INDEX IF EXISTS public.unique_doctor_date_time_active;

-- Unique constraint ekle (sadece iptal edilmemiş randevular için)
CREATE UNIQUE INDEX unique_doctor_date_time_active
ON public.appointments (doctor_id, date, time)
WHERE status != 'cancelled';

-- Açıklama ekle
COMMENT ON INDEX unique_doctor_date_time_active IS 
'Aynı doktorun aynı tarih ve saatte birden fazla aktif randevu almasını engeller. İptal edilmiş randevular hariç tutulur.';

