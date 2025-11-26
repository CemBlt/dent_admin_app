-- Hospitals tablosuna is_open_24_hours kolonu ekler
-- Bu script Supabase SQL Editor'de çalıştırılmalıdır

-- Kolonu ekle (varsayılan değer false)
ALTER TABLE public.hospitals 
ADD COLUMN IF NOT EXISTS is_open_24_hours BOOLEAN DEFAULT false NOT NULL;

-- Mevcut kayıtlar için varsayılan değeri ayarla
UPDATE public.hospitals 
SET is_open_24_hours = false 
WHERE is_open_24_hours IS NULL;

-- Kolon yorumu ekle
COMMENT ON COLUMN public.hospitals.is_open_24_hours IS 
'Hastane 7/24 açık mı? İşaretlenirse çalışma saatleri girilmesine gerek kalmaz.';

