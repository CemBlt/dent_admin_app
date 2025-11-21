-- Diş Hekimi Hizmetleri - Supabase services tablosuna ekleme
-- Tablo yapısı: id (UUID), name (TEXT), description (TEXT), created_at (TIMESTAMPTZ)

INSERT INTO public.services (id, name, description, created_at) VALUES
-- Temel Hizmetler
(gen_random_uuid(), 'Genel Muayene / Kontrol', 'Diş ve ağız sağlığı genel kontrolü ve muayenesi', NOW()),
(gen_random_uuid(), 'Diş Temizliği (Detertraj)', 'Diş taşı temizliği ve polisaj işlemi', NOW()),
(gen_random_uuid(), 'Diş Dolgusu', 'Çürük dişlerin dolgu ile tedavisi', NOW()),
(gen_random_uuid(), 'Kök Kanal Tedavisi', 'İlerlemiş çürüklerde kök kanal tedavisi', NOW()),
(gen_random_uuid(), 'Diş Çekimi', 'Çekilmesi gereken dişlerin çıkarılması', NOW()),

-- Protez ve İmplant
(gen_random_uuid(), 'Protez (Takma Diş)', 'Eksik dişlerin protez ile tamamlanması', NOW()),
(gen_random_uuid(), 'İmplant', 'Eksik dişlerin implant ile tedavisi', NOW()),

-- Estetik ve Düzeltme
(gen_random_uuid(), 'Ortodonti (Diş Teli)', 'Diş düzeltme ve çene düzenleme tedavisi', NOW()),
(gen_random_uuid(), 'Estetik Diş Tedavisi (Lamina/Bonding)', 'Diş estetiği ve gülüş tasarımı', NOW()),
(gen_random_uuid(), 'Diş Beyazlatma', 'Diş rengi açma ve beyazlatma işlemi', NOW()),

-- Özel Durumlar
(gen_random_uuid(), 'Acil Diş Tedavisi', 'Acil durumlarda diş tedavisi', NOW()),
(gen_random_uuid(), 'Çocuk Diş Tedavisi', 'Çocuklara özel diş tedavisi ve koruyucu uygulamalar', NOW());


