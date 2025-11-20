-- created_by_user_id foreign key constraint'ini kaldır
-- auth.users tablosuna direkt foreign key constraint çalışmaz
ALTER TABLE public.hospitals 
DROP CONSTRAINT IF EXISTS hospitals_created_by_user_id_fkey;

-- created_by_user_id kolonunu nullable yap (opsiyonel)
ALTER TABLE public.hospitals 
ALTER COLUMN created_by_user_id DROP NOT NULL;

