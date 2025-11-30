-- user_profiles tablosunda phone ve email kolonlarına unique constraint ekle
-- Bu script, bir telefon numarasının ve email'in yalnızca bir kayıtta kullanılmasını sağlar

-- ==================== TELEFON NUMARASI UNIQUE CONSTRAINT ====================

-- Önce mevcut duplicate telefon kayıtlarını kontrol et (opsiyonel - manuel kontrol için)
-- SELECT phone, COUNT(*) as count 
-- FROM user_profiles 
-- WHERE phone IS NOT NULL AND phone != ''
-- GROUP BY phone 
-- HAVING COUNT(*) > 1;

-- Eğer duplicate kayıtlar varsa, önce onları temizlemeniz gerekebilir
-- Örnek: En eski kayıtları tut, yenilerini sil veya güncelle

-- Telefon numarası unique constraint ekle
-- Not: Eğer tabloda zaten duplicate kayıtlar varsa, bu komut hata verecektir
-- Önce duplicate kayıtları temizlemeniz gerekir

ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_phone_unique UNIQUE (phone);

-- ==================== EMAIL UNIQUE CONSTRAINT ====================

-- Önce mevcut duplicate email kayıtlarını kontrol et (opsiyonel - manuel kontrol için)
-- SELECT email, COUNT(*) as count 
-- FROM user_profiles 
-- WHERE email IS NOT NULL AND email != ''
-- GROUP BY email 
-- HAVING COUNT(*) > 1;

-- Eğer duplicate kayıtlar varsa, önce onları temizlemeniz gerekebilir
-- Örnek: En eski kayıtları tut, yenilerini sil veya güncelle

-- Email unique constraint ekle
-- Not: Eğer tabloda zaten duplicate kayıtlar varsa, bu komut hata verecektir
-- Önce duplicate kayıtları temizlemeniz gerekir
-- Email opsiyonel olduğu için NULL değerlere izin verilir

ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_email_unique UNIQUE (email);

-- Alternatif: Eğer NULL değerlere izin vermek istiyorsanız (opsiyonel)
-- NULL değerler unique constraint'te farklı değerlendirilir
-- Bu durumda birden fazla NULL değer olabilir, ama her telefon numarası ve email unique olmalı

-- Index ekle (performans için - unique constraint zaten index oluşturur, ama açıkça belirtmek için)
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_phone ON user_profiles(phone) WHERE phone IS NOT NULL AND phone != '';
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email) WHERE email IS NOT NULL AND email != '';

