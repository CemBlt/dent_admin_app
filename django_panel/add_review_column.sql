-- Supabase appointments tablosuna review (yorum) sütunu ekleme
-- Bu SQL komutunu Supabase Dashboard > SQL Editor'de çalıştırın

ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS review TEXT;

-- Yorum sütunu için açıklama ekle
COMMENT ON COLUMN public.appointments.review IS 'Kullanıcının randevu hakkındaki yorumu/değerlendirmesi';

