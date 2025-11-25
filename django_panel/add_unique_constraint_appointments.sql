-- Supabase appointments tablosuna unique constraint ekleme
-- Bu SQL komutunu Supabase Dashboard > SQL Editor'de çalıştırın
-- 
-- Bu constraint, aynı doktorun aynı tarih ve saatte birden fazla randevu almasını engeller
-- Sadece 'cancelled' (iptal edilmiş) randevular hariç tutulur

-- Önce mevcut constraint'i kontrol et ve varsa sil
DO $$ 
BEGIN
    -- Eğer constraint varsa sil
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'unique_doctor_date_time'
    ) THEN
        ALTER TABLE public.appointments 
        DROP CONSTRAINT unique_doctor_date_time;
    END IF;
END $$;

-- Unique constraint ekle (sadece iptal edilmemiş randevular için)
-- PostgreSQL'de partial unique index kullanarak sadece belirli koşulları kontrol edebiliriz
CREATE UNIQUE INDEX IF NOT EXISTS unique_doctor_date_time_active
ON public.appointments (doctor_id, date, time)
WHERE status != 'cancelled';

-- Alternatif: Eğer PostgreSQL'in eski versiyonunu kullanıyorsanız, 
-- tüm randevular için unique constraint (iptal edilmişler dahil):
-- ALTER TABLE public.appointments
-- ADD CONSTRAINT unique_doctor_date_time 
-- UNIQUE (doctor_id, date, time);

-- Açıklama ekle
COMMENT ON INDEX unique_doctor_date_time_active IS 
'Aynı doktorun aynı tarih ve saatte birden fazla aktif randevu almasını engeller. İptal edilmiş randevular hariç tutulur.';

