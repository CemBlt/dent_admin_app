-- services tablosundan price kolonunu kaldır
ALTER TABLE public.services 
DROP COLUMN IF EXISTS price;

