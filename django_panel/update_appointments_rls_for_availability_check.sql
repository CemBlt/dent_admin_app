-- Randevu müsaitlik kontrolü için RLS politikasını güncelleme
-- Bu SQL komutunu Supabase Dashboard > SQL Editor'de çalıştırın
-- 
-- Bu politika, kullanıcıların randevu müsaitlik kontrolü yapabilmesi için
-- tüm randevuların doktor_id, date, time ve status bilgilerini görmelerine izin verir

-- Önce mevcut politikayı kontrol et ve varsa sil
DROP POLICY IF EXISTS "Users can check appointment availability" ON public.appointments;

-- Yeni politika: Randevu müsaitlik kontrolü için tüm randevuları görüntüleme
CREATE POLICY "Users can check appointment availability"
ON public.appointments
FOR SELECT
TO authenticated
USING (true);

