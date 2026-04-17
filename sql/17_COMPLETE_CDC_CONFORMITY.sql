-- ============================================================
-- EXPERIMMO - COMPLÉMENT DE MISE EN CONFORMITÉ CDC (Phase 2)
-- ============================================================

-- 1. MISE À JOUR DE LA TABLE PROPRIETES (Champs spécifiques CDC 6.3)
ALTER TABLE public.proprietes 
ADD COLUMN IF NOT EXISTS id_proprietaire_temp UUID REFERENCES public.profiles(id); -- Pour la liaison

-- 2. MISE À JOUR DE LA TABLE CONTRATS (Champs financiers CDC 6.5)
ALTER TABLE public.contrats_location 
ADD COLUMN IF NOT EXISTS description_espace TEXT,
ADD COLUMN IF NOT EXISTS montant_lettre TEXT,
ADD COLUMN IF NOT EXISTS montant_chiffre DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS renouvellement BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS modalite_paiement TEXT,
ADD COLUMN IF NOT EXISTS versement_1 DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS date_versement_1 DATE,
ADD COLUMN IF NOT EXISTS versement_2 DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS date_versement_2 DATE,
ADD COLUMN IF NOT EXISTS versement_3 DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS date_versement_3 DATE,
ADD COLUMN IF NOT EXISTS frais_cabinet DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS recurrence_frais_cabinet TEXT,
ADD COLUMN IF NOT EXISTS frais_courtier DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS recurrence_frais_courtier TEXT,
ADD COLUMN IF NOT EXISTS document_contrat TEXT; -- URL PDF

-- 3. CRÉATION DE LA TABLE MESSAGES (CDC 6.8)
CREATE TABLE IF NOT EXISTS public.messages (
    id_message UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    expediteur UUID REFERENCES public.profiles(id),
    destinataire UUID REFERENCES public.profiles(id),
    type_expediteur TEXT, -- 'proprietaire', 'locataire', 'gestionnaire', 'admin'
    type_destinataire TEXT,
    objet TEXT,
    categorie TEXT,
    message TEXT,
    piece_jointe TEXT,
    statut_message TEXT DEFAULT 'nouveau', -- 'nouveau', 'en cours', 'repondu', 'clos'
    date_envoi TIMESTAMPTZ DEFAULT NOW(),
    date_reponse TIMESTAMPTZ,
    reponse TEXT,
    lu_oui_non BOOLEAN DEFAULT FALSE
);

-- 4. MISE À JOUR DU JOURNAL D'ACTIVITÉ (CDC 6.11)
-- On modifie la table existante audit_log pour correspondre au CDC
ALTER TABLE public.audit_log 
ADD COLUMN IF NOT EXISTS module TEXT,
ADD COLUMN IF NOT EXISTS reference UUID,
ADD COLUMN IF NOT EXISTS ancienne_valeur JSONB,
ADD COLUMN IF NOT EXISTS nouvelle_valeur JSONB,
ADD COLUMN IF NOT EXISTS adresse_ip TEXT;

-- 5. AJOUT DU RÔLE 'assistante' DANS L'ENUM
DO $$ 
BEGIN
    ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'assistante';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 6. AMÉLIORATION DU TRIGGER DE CODES UNIQUES (CDC 7.1 & 21.5)
-- Format demandé : 46077PR-1 (46 + serie + prefixe + - + sequence)
CREATE OR REPLACE FUNCTION generate_experimmo_code() RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    seq_val INTEGER;
    fixed_prefix TEXT := '46'; -- Préfixe EXPERIMMO
BEGIN
    IF TG_TABLE_NAME = 'proprietaires' THEN prefix := 'PR';
    ELSIF TG_TABLE_NAME = 'locataires' THEN prefix := 'L';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN prefix := 'P';
    ELSIF TG_TABLE_NAME = 'contrats_location' THEN prefix := 'C';
    ELSIF TG_TABLE_NAME = 'operations' THEN prefix := 'OP';
    ELSIF TG_TABLE_NAME = 'factures' THEN prefix := 'F';
    ELSE prefix := 'GEN';
    END IF;

    -- On utilise la colonne 'serie' comme valeur de séquence
    EXECUTE format('SELECT COALESCE(MAX(serie), 0) + 1 FROM public.%I', TG_TABLE_NAME) INTO seq_val;
    NEW.serie := seq_val;
    
    -- Format final: 46[SERIE][PREFIXE]-[SEQUENCE_LOCALE]
    -- Note: ici sequence_locale est simplifiée à la serie
    IF TG_TABLE_NAME = 'proprietaires' THEN NEW.code_proprietaire := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'locataires' THEN NEW.code_locataire := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN NEW.code_propriete := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'contrats_location' THEN NEW.code_contrat := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    -- Pour les tables sans colonne serie, on génère juste le code
    ELSIF TG_TABLE_NAME = 'operations' THEN NEW.code_operation := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    ELSIF TG_TABLE_NAME = 'factures' THEN NEW.code_facture := fixed_prefix || LPAD(seq_val::text, 3, '0') || prefix || '-1';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-lier les triggers
DROP TRIGGER IF EXISTS trg_gen_code_prop ON public.proprietaires;
CREATE TRIGGER trg_gen_code_prop BEFORE INSERT ON public.proprietaires FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code();

DROP TRIGGER IF EXISTS trg_gen_code_loc ON public.locataires;
CREATE TRIGGER trg_gen_code_loc BEFORE INSERT ON public.locataires FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code();

DROP TRIGGER IF EXISTS trg_gen_code_prop_biens ON public.proprietes;
CREATE TRIGGER trg_gen_code_prop_biens BEFORE INSERT ON public.proprietes FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code();
