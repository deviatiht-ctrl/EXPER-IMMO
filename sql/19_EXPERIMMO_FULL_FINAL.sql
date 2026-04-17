-- ============================================================
-- EXPERIMMO - SQL 19 - ALIGNEMENT FINAL ET COMPLET (SÉCURISÉ)
-- ============================================================

-- 1. CORRECTION SÉCURISÉE DU JOURNAL D'ACTIVITÉ (Audit Log)
DO $$ 
BEGIN
    -- Gestion de id -> id_log
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='id') THEN
        ALTER TABLE public.audit_log RENAME COLUMN id TO id_log;
    END IF;

    -- Gestion de user_id -> utilisateur
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='user_id') THEN
        ALTER TABLE public.audit_log RENAME COLUMN user_id TO utilisateur;
    END IF;

    -- Gestion de old_data -> ancienne_valeur (si ancienne_valeur n'existe pas encore)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='old_data') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='ancienne_valeur') THEN
        ALTER TABLE public.audit_log RENAME COLUMN old_data TO ancienne_valeur;
    END IF;

    -- Gestion de new_data -> nouvelle_valeur
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='new_data') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='nouvelle_valeur') THEN
        ALTER TABLE public.audit_log RENAME COLUMN new_data TO nouvelle_valeur;
    END IF;

    -- Gestion de ip_address -> adresse_ip
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='ip_address') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='adresse_ip') THEN
        ALTER TABLE public.audit_log RENAME COLUMN ip_address TO adresse_ip;
    END IF;

    -- Gestion de created_at -> horodatage
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='created_at') THEN
        ALTER TABLE public.audit_log RENAME COLUMN created_at TO horodatage;
    END IF;
END $$;

-- 2. ALIGNEMENT DES TABLES PRINCIPALES (Champs CDC manquants)
ALTER TABLE public.proprietaires 
ADD COLUMN IF NOT EXISTS nif TEXT,
ADD COLUMN IF NOT EXISTS cin TEXT,
ADD COLUMN IF NOT EXISTS no_passeport TEXT;

ALTER TABLE public.locataires 
ADD COLUMN IF NOT EXISTS nif TEXT,
ADD COLUMN IF NOT EXISTS cin TEXT,
ADD COLUMN IF NOT EXISTS no_passeport TEXT,
ADD COLUMN IF NOT EXISTS pieces_justificatives TEXT;

-- 3. ALIGNEMENT CONTRATS (Champs financiers CDC 6.5)
ALTER TABLE public.contrats_location 
ADD COLUMN IF NOT EXISTS description_espace TEXT,
ADD COLUMN IF NOT EXISTS montant_lettre TEXT,
ADD COLUMN IF NOT EXISTS montant_chiffre DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS versement_1 DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS date_versement_1 DATE,
ADD COLUMN IF NOT EXISTS versement_2 DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS date_versement_2 DATE,
ADD COLUMN IF NOT EXISTS versement_3 DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS date_versement_3 DATE,
ADD COLUMN IF NOT EXISTS frais_cabinet DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS recurrence_frais_cabinet TEXT,
ADD COLUMN IF NOT EXISTS frais_courtier DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS recurrence_frais_courtier TEXT;

-- 4. ALIGNEMENT PROPRIETES (CDC 6.3)
ALTER TABLE public.proprietes 
ADD COLUMN IF NOT EXISTS dimension TEXT,
ADD COLUMN IF NOT EXISTS explication TEXT,
ADD COLUMN IF NOT EXISTS reference_zone TEXT,
ADD COLUMN IF NOT EXISTS type_mandat TEXT DEFAULT 'simple';

-- 5. CRÉATION TABLE MESSAGES SI MANQUANTE (CDC 6.8)
CREATE TABLE IF NOT EXISTS public.messages (
    id_message UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    expediteur UUID REFERENCES public.profiles(id),
    destinataire UUID REFERENCES public.profiles(id),
    type_expediteur TEXT,
    type_destinataire TEXT,
    objet TEXT,
    categorie TEXT,
    message TEXT,
    piece_jointe TEXT,
    statut_message TEXT DEFAULT 'nouveau',
    date_envoi TIMESTAMPTZ DEFAULT NOW(),
    date_reponse TIMESTAMPTZ,
    reponse TEXT,
    lu_oui_non BOOLEAN DEFAULT FALSE
);

-- 6. DÉFINITION DU RÔLE ASSISTANTE
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role' AND 'assistante' = ANY(enum_range(NULL::user_role)::text[])) THEN
        ALTER TYPE user_role ADD VALUE 'assistante';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 7. TRIGGER DE CODES UNIQUES - VERSION FINALE CDC
CREATE OR REPLACE FUNCTION generate_experimmo_code_v2() RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    seq_val INTEGER;
    fixed_prefix TEXT := '46'; 
BEGIN
    IF TG_TABLE_NAME = 'proprietaires' THEN prefix := 'PR';
    ELSIF TG_TABLE_NAME = 'locataires' THEN prefix := 'L';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN prefix := 'P';
    ELSIF TG_TABLE_NAME = 'contrats_location' THEN prefix := 'C';
    ELSIF TG_TABLE_NAME = 'operations' THEN prefix := 'OP';
    ELSIF TG_TABLE_NAME = 'factures' THEN prefix := 'F';
    ELSE prefix := 'GEN';
    END IF;

    EXECUTE format('SELECT COALESCE(MAX(serie), 0) + 1 FROM public.%I', TG_TABLE_NAME) INTO seq_val;
    NEW.serie := seq_val;
    
    -- Format final conforme: 46[SEQUENCE]PREFIXE-1
    IF TG_TABLE_NAME = 'proprietaires' THEN NEW.code_proprietaire := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'locataires' THEN NEW.code_locataire := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN NEW.code_propriete := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'contrats_location' THEN NEW.code_contrat := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'operations' THEN NEW.code_operation := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'factures' THEN NEW.code_facture := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ré-application des triggers sur la version V2
DROP TRIGGER IF EXISTS trg_gen_code_prop ON public.proprietaires;
CREATE TRIGGER trg_gen_code_prop BEFORE INSERT ON public.proprietaires FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code_v2();

DROP TRIGGER IF EXISTS trg_gen_code_loc ON public.locataires;
CREATE TRIGGER trg_gen_code_loc BEFORE INSERT ON public.locataires FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code_v2();

DROP TRIGGER IF EXISTS trg_gen_code_prop_biens ON public.proprietes;
CREATE TRIGGER trg_gen_code_prop_biens BEFORE INSERT ON public.proprietes FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code_v2();

COMMENT ON TABLE public.audit_log IS 'Journal d’activité EXPERIMMO - Alignement Final v19';
