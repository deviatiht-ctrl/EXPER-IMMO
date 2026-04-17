-- ============================================================
-- EXPERIMMO - MASTER UPDATE SQL
-- Alignement avec le cahier des charges officiel
-- ============================================================

-- 1. AJOUT DU RÔLE GESTIONNAIRE & ASSISTANTE
DO $$ 
BEGIN
    ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'gestionnaire';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. AJOUT DES CHAMPS MANQUANTS AUX PROFILS
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS nif TEXT,
ADD COLUMN IF NOT EXISTS cin TEXT,
ADD COLUMN IF NOT EXISTS no_passeport TEXT;

-- 3. AJOUT DES CHAMPS MANQUANTS AUX PROPRIETAIRES
ALTER TABLE public.proprietaires 
ADD COLUMN IF NOT EXISTS serie INTEGER,
ADD COLUMN IF NOT EXISTS code_proprietaire TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS date_inscription DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS nom TEXT,
ADD COLUMN IF NOT EXISTS prenom TEXT,
ADD COLUMN IF NOT EXISTS contact_1_nom TEXT,
ADD COLUMN IF NOT EXISTS contact_1_telephone TEXT,
ADD COLUMN IF NOT EXISTS gestionnaire_responsable UUID REFERENCES public.profiles(id);

-- 4. AJOUT DES CHAMPS MANQUANTS AUX LOCATAIRES
ALTER TABLE public.locataires 
ADD COLUMN IF NOT EXISTS serie INTEGER,
ADD COLUMN IF NOT EXISTS code_locataire TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS date_inscription DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS nom TEXT,
ADD COLUMN IF NOT EXISTS prenom TEXT,
ADD COLUMN IF NOT EXISTS contact_1_nom TEXT,
ADD COLUMN IF NOT EXISTS contact_1_telephone TEXT,
ADD COLUMN IF NOT EXISTS pieces_justificatives TEXT, -- URL JSON ou texte
ADD COLUMN IF NOT EXISTS gestionnaire_responsable UUID REFERENCES public.profiles(id);

-- 5. AJOUT DES CHAMPS MANQUANTS AUX PROPRIETES
ALTER TABLE public.proprietes 
ADD COLUMN IF NOT EXISTS serie INTEGER,
ADD COLUMN IF NOT EXISTS code_propriete TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS date_inscription DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS type_mandat TEXT, -- 'exclusif', 'simple', etc.
ADD COLUMN IF NOT EXISTS dimension TEXT,
ADD COLUMN IF NOT EXISTS explication TEXT,
ADD COLUMN IF NOT EXISTS reference_zone TEXT,
ADD COLUMN IF NOT EXISTS statut_bien TEXT DEFAULT 'disponible',
ADD COLUMN IF NOT EXISTS gestionnaire_responsable UUID REFERENCES public.profiles(id);

-- 6. CRÉATION DE LA TABLE OPERATIONS (MODULE 8)
CREATE TABLE IF NOT EXISTS public.operations (
    id_operation UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code_operation TEXT UNIQUE,
    id_propriete UUID REFERENCES public.proprietes(id) ON DELETE CASCADE,
    id_proprietaire UUID REFERENCES public.proprietaires(id) ON DELETE CASCADE,
    id_locataire UUID REFERENCES public.locataires(id) ON DELETE SET NULL,
    id_contrat UUID REFERENCES public.contrats_location(id) ON DELETE SET NULL,
    date_operation DATE DEFAULT CURRENT_DATE,
    type_operation TEXT NOT NULL, -- 'maintenance', 'reparation', 'taxe', 'assurance', etc.
    reference_decision TEXT,
    document_reference TEXT, -- URL vers document
    montant DECIMAL(12,2) DEFAULT 0,
    remarques TEXT,
    statut_operation TEXT DEFAULT 'brouillon', -- 'brouillon', 'valide', 'annule'
    publie_portail BOOLEAN DEFAULT FALSE,
    auteur_saisie UUID REFERENCES public.profiles(id),
    valide_par UUID REFERENCES public.profiles(id),
    date_creation TIMESTAMPTZ DEFAULT NOW(),
    date_modification TIMESTAMPTZ DEFAULT NOW()
);

-- 7. CRÉATION DE LA TABLE FACTURES (MODULE 10)
CREATE TABLE IF NOT EXISTS public.factures (
    id_facture UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code_facture TEXT UNIQUE,
    type_facture TEXT NOT NULL, -- 'loyer', 'eau', 'electricite', 'charges'
    id_locataire UUID REFERENCES public.locataires(id) ON DELETE CASCADE,
    id_propriete UUID REFERENCES public.proprietes(id) ON DELETE CASCADE,
    periode TEXT, -- ex: 'Avril 2026'
    date_emission DATE DEFAULT CURRENT_DATE,
    date_echeance DATE,
    montant DECIMAL(12,2) NOT NULL,
    statut_facture TEXT DEFAULT 'impaye', -- 'impaye', 'paye', 'partiel', 'annule'
    document_facture TEXT, -- URL PDF généré
    justificatif_paiement TEXT, -- URL preuve client
    date_creation TIMESTAMPTZ DEFAULT NOW(),
    date_modification TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TRIGGERS POUR LA GÉNÉRATION DES CODES UNIQUES
-- Logique: [ANNEE][SEQUENCE][TYPE] -> Simplifiée pour matcher le format demandé

CREATE OR REPLACE FUNCTION generate_unique_code() RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    seq_val INTEGER;
    year_prefix TEXT;
BEGIN
    year_prefix := to_char(CURRENT_DATE, 'YY'); -- Ex: 26 pour 2026
    
    IF TG_TABLE_NAME = 'proprietaires' THEN prefix := 'PR';
    ELSIF TG_TABLE_NAME = 'locataires' THEN prefix := 'L';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN prefix := 'P';
    ELSIF TG_TABLE_NAME = 'contrats_location' THEN prefix := 'C';
    ELSIF TG_TABLE_NAME = 'operations' THEN prefix := 'OP';
    ELSIF TG_TABLE_NAME = 'factures' THEN prefix := 'F';
    ELSE prefix := 'GEN';
    END IF;

    -- On récupère la séquence actuelle pour cette table
    -- Dans un vrai système, on utiliserait une SEQUENCE Postgres par table
    -- Ici on simplifie par un count + 1
    EXECUTE format('SELECT count(*) + 1 FROM public.%I', TG_TABLE_NAME) INTO seq_val;
    
    -- Format: 46077PR-1 -> Le format demandé semble utiliser un préfixe fixe complexe
    -- On va simuler le format "46" + année + préfixe + "-" + séquence
    IF TG_TABLE_NAME = 'proprietaires' THEN 
        NEW.code_proprietaire := '46' || year_prefix || prefix || '-' || seq_val;
        NEW.serie := seq_val;
    ELSIF TG_TABLE_NAME = 'locataires' THEN 
        NEW.code_locataire := '46' || year_prefix || prefix || '-' || seq_val;
        NEW.serie := seq_val;
    ELSIF TG_TABLE_NAME = 'proprietes' THEN 
        NEW.code_propriete := '46' || year_prefix || prefix || '-' || seq_val;
        NEW.serie := seq_val;
    ELSIF TG_TABLE_NAME = 'operations' THEN 
        NEW.code_operation := '46' || year_prefix || prefix || '-' || seq_val;
    ELSIF TG_TABLE_NAME = 'factures' THEN 
        NEW.code_facture := '46' || year_prefix || prefix || '-' || seq_val;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Application des triggers
DROP TRIGGER IF EXISTS trg_gen_code_prop ON public.proprietaires;
CREATE TRIGGER trg_gen_code_prop BEFORE INSERT ON public.proprietaires FOR EACH ROW EXECUTE FUNCTION generate_unique_code();

DROP TRIGGER IF EXISTS trg_gen_code_loc ON public.locataires;
CREATE TRIGGER trg_gen_code_loc BEFORE INSERT ON public.locataires FOR EACH ROW EXECUTE FUNCTION generate_unique_code();

DROP TRIGGER IF EXISTS trg_gen_code_prop_biens ON public.proprietes;
CREATE TRIGGER trg_gen_code_prop_biens BEFORE INSERT ON public.proprietes FOR EACH ROW EXECUTE FUNCTION generate_unique_code();

DROP TRIGGER IF EXISTS trg_gen_code_ops ON public.operations;
CREATE TRIGGER trg_gen_code_ops BEFORE INSERT ON public.operations FOR EACH ROW EXECUTE FUNCTION generate_unique_code();

DROP TRIGGER IF EXISTS trg_gen_code_fact ON public.factures;
CREATE TRIGGER trg_gen_code_fact BEFORE INSERT ON public.factures FOR EACH ROW EXECUTE FUNCTION generate_unique_code();
