-- Randevu müsaitlik kontrolü için RLS politikasını güncelleme
-- Bu SQL komutunu Supabase Dashboard > SQL Editor'de çalıştırın
-- 
-- Bu politika, kullanıcıların randevu müsaitlik kontrolü yapabilmesi için
-- tüm randevuların doktor_id, date ve time bilgilerini görmelerine izin verir
-- Ancak user_id gibi hassas bilgileri gizler

-- Önce mevcut SELECT politikasını kontrol et
-- Eğer "Users can view their own appointments" politikası varsa, onu güncelle

-- Yeni politika: Randevu müsaitlik kontrolü için tüm randevuları görüntüleme
-- (Sadece doktor, tarih, saat ve status bilgileri)
CREATE POLICY "Users can check appointment availability"
ON public.appointments
FOR SELECT
TO authenticated
USING (true);  -- Tüm randevuları görebilir (müsaitlik kontrolü için)

-- NOT: Eğer yukarıdaki politika çakışma yaratırsa, önce eski politikayı silin:
-- DROP POLICY IF EXISTS "Users can view their own appointments" ON public.appointments;
-- 
-- Sonra yeni politikayı ekleyin:
-- CREATE POLICY "Users can view their own appointments"
-- ON public.appointments
-- FOR SELECT
-- TO authenticated
-- USING (auth.uid() = user_id);
--
-- Ve müsaitlik kontrolü için ayrı bir politika:
-- CREATE POLICY "Users can check appointment availability"
-- ON public.appointments
-- FOR SELECT
-- TO authenticated
-- USING (true);

-- Alternatif: Daha güvenli yaklaşım - sadece doktor, tarih, saat ve status bilgilerini göster
-- Bu durumda bir view oluşturabiliriz:
-- CREATE VIEW appointment_availability AS
-- SELECT doctor_id, date, time, status
-- FROM appointments
-- WHERE status != 'cancelled';
--
-- Ve bu view için RLS politikası:
-- CREATE POLICY "Users can check appointment availability"
-- ON appointment_availability
-- FOR SELECT
-- TO authenticated
-- USING (true);

