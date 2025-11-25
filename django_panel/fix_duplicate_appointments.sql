-- ÖNEMLİ: Bu script'i çalıştırmadan önce yedek alın!
-- Duplicate randevuları temizleme ve unique constraint ekleme
-- Bu SQL komutlarını Supabase Dashboard > SQL Editor'de çalıştırın

-- ============================================================
-- ADIM 1: Duplicate randevuları bul ve göster
-- ============================================================
-- Bu sorgu, aynı doktor/tarih/saat kombinasyonuna sahip randevuları gösterir
SELECT 
    doctor_id,
    date,
    time,
    COUNT(*) as duplicate_count,
    array_agg(id ORDER BY created_at) as appointment_ids,
    array_agg(status ORDER BY created_at) as statuses,
    array_agg(created_at ORDER BY created_at) as created_dates
FROM public.appointments
WHERE status != 'cancelled'
GROUP BY doctor_id, date, time
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- ============================================================
-- ADIM 2: Duplicate randevuları temizle
-- ============================================================
-- Strateji: Her duplicate grup için, en yeni randevuyu tutup 
-- diğerlerini 'cancelled' olarak işaretle (veya silebilirsiniz)

-- Seçenek 1: Duplicate'leri iptal et (önerilen - veri kaybı olmaz)
WITH duplicates AS (
    SELECT 
        id,
        doctor_id,
        date,
        time,
        ROW_NUMBER() OVER (
            PARTITION BY doctor_id, date, time 
            ORDER BY created_at DESC
        ) as row_num
    FROM public.appointments
    WHERE status != 'cancelled'
)
UPDATE public.appointments
SET status = 'cancelled',
    notes = COALESCE(notes, '') || ' [Otomatik iptal: Duplicate randevu temizleme]'
WHERE id IN (
    SELECT id 
    FROM duplicates 
    WHERE row_num > 1
);

-- Seçenek 2: Duplicate'leri sil (dikkatli kullanın!)
-- WITH duplicates AS (
--     SELECT 
--         id,
--         ROW_NUMBER() OVER (
--             PARTITION BY doctor_id, date, time 
--             ORDER BY created_at DESC
--         ) as row_num
--     FROM public.appointments
--     WHERE status != 'cancelled'
-- )
-- DELETE FROM public.appointments
-- WHERE id IN (
--     SELECT id 
--     FROM duplicates 
--     WHERE row_num > 1
-- );

-- ============================================================
-- ADIM 3: Temizleme sonrası kontrol
-- ============================================================
-- Duplicate kaldı mı kontrol et
SELECT 
    doctor_id,
    date,
    time,
    COUNT(*) as count
FROM public.appointments
WHERE status != 'cancelled'
GROUP BY doctor_id, date, time
HAVING COUNT(*) > 1;
-- Bu sorgu sonuç döndürmemeli (boş olmalı)

-- ============================================================
-- ADIM 4: Unique constraint ekle
-- ============================================================
-- Artık duplicate olmadığı için constraint ekleyebiliriz

-- Önce mevcut index'i kontrol et ve varsa sil
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE indexname = 'unique_doctor_date_time_active'
    ) THEN
        DROP INDEX IF EXISTS public.unique_doctor_date_time_active;
    END IF;
END $$;

-- Unique constraint ekle (sadece iptal edilmemiş randevular için)
CREATE UNIQUE INDEX unique_doctor_date_time_active
ON public.appointments (doctor_id, date, time)
WHERE status != 'cancelled';

-- Açıklama ekle
COMMENT ON INDEX unique_doctor_date_time_active IS 
'Aynı doktorun aynı tarih ve saatte birden fazla aktif randevu almasını engeller. İptal edilmiş randevular hariç tutulur.';

-- ============================================================
-- ADIM 5: Başarı kontrolü
-- ============================================================
-- Constraint'in başarıyla eklendiğini kontrol et
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'appointments' 
AND indexname = 'unique_doctor_date_time_active';

