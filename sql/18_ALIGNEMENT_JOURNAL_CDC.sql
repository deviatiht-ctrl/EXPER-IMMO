-- ============================================================
-- EXPERIMMO - SQL 18 - CORRECTION & ALIGNEMENT JOURNAL CDC 6.11
-- ============================================================

-- 1. RENOMMAGE DES COLONNES DE LA TABLE audit_log POUR MATCH LE CDC
ALTER TABLE public.audit_log RENAME COLUMN id TO id_log;
ALTER TABLE public.audit_log RENAME COLUMN user_id TO utilisateur;
ALTER TABLE public.audit_log RENAME COLUMN old_data TO ancienne_valeur;
ALTER TABLE public.audit_log RENAME COLUMN new_data TO nouvelle_valeur;
ALTER TABLE public.audit_log RENAME COLUMN ip_address TO adresse_ip;
ALTER TABLE public.audit_log RENAME COLUMN created_at TO horodatage;

-- 2. AJOUT DES CHAMPS MANQUANTS S'ILS N'EXISTENT PAS
ALTER TABLE public.audit_log 
ADD COLUMN IF NOT EXISTS module TEXT,
ADD COLUMN IF NOT EXISTS reference UUID;

-- 3. MISE À JOUR DU TYPE POUR ADRESSE IP SI NÉCESSAIRE (INET -> TEXT pour plus de flexibilité selon CDC)
ALTER TABLE public.audit_log ALTER COLUMN adresse_ip TYPE TEXT USING adresse_ip::text;

-- 4. VÉRIFICATION DU RÔLE 'assistante' (Ajustement final)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role' AND 'assistante' = ANY(enum_range(NULL::user_role)::text[])) THEN
        ALTER TYPE user_role ADD VALUE 'assistante';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 5. COMMENTAIRES POUR CLARTÉ
COMMENT ON TABLE public.audit_log IS 'Journal d’activité conforme au CDC 6.11 EXPERIMMO';
COMMENT ON COLUMN public.audit_log.utilisateur IS 'Lien vers public.profiles(id)';
