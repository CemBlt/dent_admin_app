-- Doctors tablosundan specialty kolonunu kaldırır
-- Bu script Supabase SQL Editor'de çalıştırılmalıdır

-- Önce kolonun var olup olmadığını kontrol et ve kaldır
ALTER TABLE public.doctors 
DROP COLUMN IF EXISTS specialty;

-- Değişiklikleri doğrula
COMMENT ON TABLE public.doctors IS 
'Doctors tablosundan specialty kolonu kaldırıldı. Uzmanlık bilgisi artık tutulmamaktadır.';

