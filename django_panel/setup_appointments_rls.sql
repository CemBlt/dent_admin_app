-- Supabase appointments tablosu için Row Level Security (RLS) politikaları
-- Bu SQL komutlarını Supabase Dashboard > SQL Editor'de çalıştırın

-- 1. Kullanıcılar kendi randevularını oluşturabilir
CREATE POLICY "Users can insert their own appointments"
ON public.appointments
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 2. Kullanıcılar kendi randevularını görebilir
CREATE POLICY "Users can view their own appointments"
ON public.appointments
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 3. Kullanıcılar kendi randevularını güncelleyebilir (iptal etmek için)
CREATE POLICY "Users can update their own appointments"
ON public.appointments
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. Kullanıcılar kendi randevularını silebilir (isteğe bağlı)
-- CREATE POLICY "Users can delete their own appointments"
-- ON public.appointments
-- FOR DELETE
-- TO authenticated
-- USING (auth.uid() = user_id);

