-- ============================================================
-- EXPER IMMO - 15_MASTER_FIX.sql
-- Script de correction DEFINITIF et IDEMPOTENT
-- Résout TOUS les conflits entre les scripts 02 → 14
-- Peut être exécuté plusieurs fois sans erreur
-- ============================================================

-- ============================================================
-- 1. EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ============================================================
-- 2. ENUM TYPES (safe)
-- ============================================================
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('admin', 'proprietaire', 'locataire');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE payment_status AS ENUM ('en_attente', 'paye', 'en_retard', 'partiel', 'annule');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE ticket_status AS ENUM ('ouvert', 'en_cours', 'resolu', 'ferme');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE ticket_priority AS ENUM ('basse', 'moyenne', 'haute', 'urgente');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE contrat_status AS ENUM ('brouillon', 'actif', 'expire', 'resilie', 'renouvele');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 3. TABLE PROFILES - colonnes OBLIGATOIRES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email       TEXT UNIQUE NOT NULL,
    full_name   TEXT NOT NULL DEFAULT 'Utilisateur',
    phone       TEXT,
    role        user_role NOT NULL DEFAULT 'locataire',
    is_active   BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- CRITIQUE : ajouter role si absent (cas table créée par 02_schema.sql sans role)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='profiles' AND column_name='role'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN role user_role NOT NULL DEFAULT 'locataire';
    END IF;
END $$;

-- CRITIQUE : ajouter is_active si absent (utilisé par proprietaires.js)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active   BOOLEAN DEFAULT TRUE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_secondary TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url  TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS adresse     TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ville       TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS code_postal TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pays        TEXT DEFAULT 'Haïti';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS numero_identite TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS type_identite   TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS document_url    TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS contact_urgence_nom      TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS contact_urgence_tel      TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS contact_urgence_relation TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_naissance    DATE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_profiles_role  ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ============================================================
-- 4. TABLE ZONES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.zones (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nom         TEXT NOT NULL,
    slug        TEXT UNIQUE,
    ville       TEXT DEFAULT 'Port-au-Prince',
    description TEXT,
    image_url   TEXT,
    actif       BOOLEAN DEFAULT TRUE,
    ordre       INTEGER DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS slug        TEXT;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS image_url   TEXT;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS actif       BOOLEAN DEFAULT TRUE;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS ordre       INTEGER DEFAULT 0;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS ville       TEXT DEFAULT 'Port-au-Prince';

-- ============================================================
-- 5. TABLE AGENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agents (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    prenom      TEXT NOT NULL,
    nom         TEXT NOT NULL,
    titre       TEXT DEFAULT 'Agent Immobilier',
    email       TEXT,
    telephone   TEXT,
    photo_url   TEXT,
    actif       BOOLEAN DEFAULT TRUE,
    ordre       INTEGER DEFAULT 1,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS email         TEXT;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS actif         BOOLEAN DEFAULT TRUE;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS ordre         INTEGER DEFAULT 1;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS whatsapp      TEXT;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS specialites   TEXT[] DEFAULT '{}';
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS experience_ans INTEGER DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS nb_ventes      INTEGER DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS nb_locations   INTEGER DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS biographie     TEXT;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMPTZ DEFAULT NOW();

-- ============================================================
-- 6. TABLE PROPRIETES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.proprietes (
    id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference        TEXT UNIQUE,
    titre            TEXT NOT NULL,
    slug             TEXT UNIQUE,
    description      TEXT,
    type_propriete   TEXT DEFAULT 'appartement',
    type_transaction TEXT DEFAULT 'location',
    statut           TEXT DEFAULT 'disponible',
    prix             DECIMAL(15,2) DEFAULT 0,
    prix_location    DECIMAL(15,2),
    prix_vente       DECIMAL(15,2),
    devise           TEXT DEFAULT 'USD',
    superficie_m2    DECIMAL(10,2),
    nb_chambres      INTEGER DEFAULT 0,
    nb_salles_bain   INTEGER DEFAULT 0,
    nb_garages       INTEGER DEFAULT 0,
    nb_etages        INTEGER DEFAULT 0,
    meuble           BOOLEAN DEFAULT FALSE,
    amenagements     TEXT[] DEFAULT '{}',
    images           TEXT[] DEFAULT '{}',
    adresse          TEXT,
    ville            TEXT DEFAULT 'Port-au-Prince',
    latitude         DECIMAL(10,8),
    longitude        DECIMAL(11,8),
    zone_id          UUID REFERENCES public.zones(id),
    agent_id         UUID REFERENCES public.agents(id),
    est_vedette      BOOLEAN DEFAULT FALSE,
    est_actif        BOOLEAN DEFAULT TRUE,
    vue_count        INTEGER DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS slug             TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS prix_location    DECIMAL(15,2);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS prix_vente       DECIMAL(15,2);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS superficie_m2    DECIMAL(10,2);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS nb_garages       INTEGER DEFAULT 0;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS est_vedette      BOOLEAN DEFAULT FALSE;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS est_actif        BOOLEAN DEFAULT TRUE;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS vue_count        INTEGER DEFAULT 0;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS type_transaction TEXT DEFAULT 'location';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS type_propriete   TEXT DEFAULT 'appartement';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS amenagements     TEXT[] DEFAULT '{}';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS proprietaire_id  UUID;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS est_gere         BOOLEAN DEFAULT FALSE;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS description_courte TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS meuble           BOOLEAN DEFAULT FALSE;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS updated_at       TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_prop_statut       ON public.proprietes(statut);
CREATE INDEX IF NOT EXISTS idx_prop_type         ON public.proprietes(type_propriete);
CREATE INDEX IF NOT EXISTS idx_prop_transaction  ON public.proprietes(type_transaction);
CREATE INDEX IF NOT EXISTS idx_prop_zone         ON public.proprietes(zone_id);
CREATE INDEX IF NOT EXISTS idx_prop_actif        ON public.proprietes(est_actif);
CREATE INDEX IF NOT EXISTS idx_prop_vedette      ON public.proprietes(est_vedette);

-- ============================================================
-- 7. TABLE CONTACTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.contacts (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nom         TEXT NOT NULL,
    email       TEXT NOT NULL,
    telephone   TEXT,
    sujet       TEXT,
    message     TEXT NOT NULL,
    statut      TEXT DEFAULT 'nouveau',
    traite      BOOLEAN DEFAULT FALSE,
    propriete_id UUID REFERENCES public.proprietes(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.contacts ADD COLUMN IF NOT EXISTS sujet          TEXT;
ALTER TABLE public.contacts ADD COLUMN IF NOT EXISTS traite         BOOLEAN DEFAULT FALSE;
ALTER TABLE public.contacts ADD COLUMN IF NOT EXISTS statut         TEXT DEFAULT 'nouveau';
ALTER TABLE public.contacts ADD COLUMN IF NOT EXISTS locataire_id   UUID;
ALTER TABLE public.contacts ADD COLUMN IF NOT EXISTS proprietaire_id UUID;

-- ============================================================
-- 8. TABLE PROPRIETAIRES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.proprietaires (
    id                UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id           UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    type_proprietaire TEXT DEFAULT 'particulier'
                        CHECK (type_proprietaire IN ('particulier','entreprise','syndic')),
    nom_entreprise    TEXT,
    numero_fiscal     TEXT,
    nom_banque        TEXT,
    numero_compte     TEXT,
    rib_iban          TEXT,
    mode_paiement_prefere TEXT DEFAULT 'virement',
    frequence_rapport TEXT DEFAULT 'mensuel',
    notification_email     BOOLEAN DEFAULT TRUE,
    notification_sms       BOOLEAN DEFAULT FALSE,
    notification_whatsapp  BOOLEAN DEFAULT TRUE,
    date_debut_mandat DATE,
    date_fin_mandat   DATE,
    commission_taux   DECIMAL(5,2) DEFAULT 10.00,
    nb_proprietes     INTEGER DEFAULT 0,
    revenu_total      DECIMAL(15,2) DEFAULT 0,
    est_actif         BOOLEAN DEFAULT TRUE,
    notes_admin       TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS nom_banque      TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS numero_compte   TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS rib_iban        TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS commission_taux DECIMAL(5,2) DEFAULT 10.00;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS notes_admin     TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS nb_proprietes   INTEGER DEFAULT 0;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS revenu_total    DECIMAL(15,2) DEFAULT 0;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_proprietaires_user ON public.proprietaires(user_id);

-- FK proprietes → proprietaires (ajout après la création de proprietaires)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'proprietes_proprietaire_id_fkey'
          AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.proprietes
        ADD CONSTRAINT proprietes_proprietaire_id_fkey
        FOREIGN KEY (proprietaire_id) REFERENCES public.proprietaires(id);
    END IF;
END $$;

-- ============================================================
-- 9. TABLE LOCATAIRES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.locataires (
    id                     UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id                UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    profession             TEXT,
    employeur              TEXT,
    revenu_mensuel         DECIMAL(12,2),
    garant_nom             TEXT,
    garant_telephone       TEXT,
    garant_email           TEXT,
    garant_adresse         TEXT,
    garant_profession      TEXT,
    ancien_proprietaire_nom TEXT,
    ancien_proprietaire_tel TEXT,
    raison_depart          TEXT,
    fiche_paie_url         TEXT,
    contrat_travail_url    TEXT,
    score_paiement         INTEGER DEFAULT 100,
    nb_retards_paiement    INTEGER DEFAULT 0,
    est_actif              BOOLEAN DEFAULT TRUE,
    est_blackliste         BOOLEAN DEFAULT FALSE,
    raison_blacklist       TEXT,
    notes_admin            TEXT,
    contact_urgence_nom    TEXT,
    contact_urgence_phone  TEXT,
    contact_urgence_relation TEXT,
    nb_personnes           INTEGER DEFAULT 1,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS score_paiement      INTEGER DEFAULT 100;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS nb_retards_paiement  INTEGER DEFAULT 0;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS est_blackliste       BOOLEAN DEFAULT FALSE;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS raison_blacklist     TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS notes_admin          TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_urgence_nom  TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_urgence_phone TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_urgence_relation TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS nb_personnes         INTEGER DEFAULT 1;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS updated_at           TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_locataires_user  ON public.locataires(user_id);
CREATE INDEX IF NOT EXISTS idx_locataires_score ON public.locataires(score_paiement);

-- ============================================================
-- 10. TABLE CONTRATS_LOCATION
-- ============================================================
CREATE TABLE IF NOT EXISTS public.contrats_location (
    id                   UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference            TEXT UNIQUE,
    propriete_id         UUID REFERENCES public.proprietes(id) ON DELETE CASCADE NOT NULL,
    locataire_id         UUID REFERENCES public.locataires(id) ON DELETE CASCADE NOT NULL,
    proprietaire_id      UUID REFERENCES public.proprietaires(id),
    agent_id             UUID REFERENCES public.agents(id),
    date_debut           DATE NOT NULL,
    date_fin             DATE NOT NULL,
    duree_mois           INTEGER,
    loyer_mensuel        DECIMAL(12,2) NOT NULL,
    devise               TEXT DEFAULT 'USD',
    charges_mensuelles   DECIMAL(10,2) DEFAULT 0,
    depot_garantie       DECIMAL(12,2) DEFAULT 0,
    depot_garantie_paye  BOOLEAN DEFAULT FALSE,
    jour_paiement        INTEGER DEFAULT 1 CHECK (jour_paiement BETWEEN 1 AND 28),
    mode_paiement        TEXT DEFAULT 'virement',
    penalite_retard_pct  DECIMAL(5,2) DEFAULT 5.00,
    jours_grace          INTEGER DEFAULT 5,
    contrat_pdf_url      TEXT,
    etat_des_lieux_entree_url TEXT,
    etat_des_lieux_sortie_url TEXT,
    statut               contrat_status DEFAULT 'brouillon',
    motif_resiliation    TEXT,
    date_resiliation     DATE,
    preavis_donne        BOOLEAN DEFAULT FALSE,
    date_preavis         DATE,
    renouvellement_auto  BOOLEAN DEFAULT FALSE,
    preavis_requis_jours INTEGER DEFAULT 30,
    conditions_speciales TEXT,
    clauses              TEXT,
    notes_internes       TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS notes_internes      TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS conditions_speciales TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS depot_garantie_paye  BOOLEAN DEFAULT FALSE;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS clauses              TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS updated_at           TIMESTAMPTZ DEFAULT NOW();
-- Permettre insertion sans proprietaire_id depuis le formulaire admin simplifié
ALTER TABLE public.contrats_location ALTER COLUMN proprietaire_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_contrat_propriete    ON public.contrats_location(propriete_id);
CREATE INDEX IF NOT EXISTS idx_contrat_locataire    ON public.contrats_location(locataire_id);
CREATE INDEX IF NOT EXISTS idx_contrat_proprietaire ON public.contrats_location(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_contrat_statut       ON public.contrats_location(statut);

-- ============================================================
-- 11. TABLE PAIEMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.paiements (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference           TEXT UNIQUE,
    contrat_id          UUID REFERENCES public.contrats_location(id) ON DELETE CASCADE,
    locataire_id        UUID REFERENCES public.locataires(id),
    propriete_id        UUID REFERENCES public.proprietes(id),
    mois                INTEGER DEFAULT EXTRACT(MONTH FROM NOW())::INTEGER,
    annee               INTEGER DEFAULT EXTRACT(YEAR  FROM NOW())::INTEGER,
    periode_debut       DATE,
    periode_fin         DATE,
    montant_loyer       DECIMAL(12,2) DEFAULT 0,
    montant_charges     DECIMAL(10,2) DEFAULT 0,
    montant_penalite    DECIMAL(10,2) DEFAULT 0,
    montant_autre       DECIMAL(10,2) DEFAULT 0,
    description_autre   TEXT,
    montant_total       DECIMAL(12,2) NOT NULL,
    montant_paye        DECIMAL(12,2) DEFAULT 0,
    solde_restant       DECIMAL(12,2) DEFAULT 0,
    devise              TEXT DEFAULT 'USD',
    date_echeance       DATE NOT NULL,
    date_paiement       DATE,
    mode_paiement       TEXT,
    methode_paiement    TEXT,
    reference_transaction TEXT,
    statut              payment_status DEFAULT 'en_attente',
    jours_retard        INTEGER DEFAULT 0,
    recu_url            TEXT,
    preuve_paiement_url TEXT,
    traite_par          UUID REFERENCES public.profiles(id),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.paiements ADD COLUMN IF NOT EXISTS notes               TEXT;
ALTER TABLE public.paiements ADD COLUMN IF NOT EXISTS traite_par          UUID;
ALTER TABLE public.paiements ADD COLUMN IF NOT EXISTS preuve_paiement_url TEXT;
ALTER TABLE public.paiements ADD COLUMN IF NOT EXISTS methode_paiement    TEXT;
ALTER TABLE public.paiements ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ DEFAULT NOW();
-- Rendre les colonnes non-obligatoires pour insertion depuis le formulaire admin simplifié
ALTER TABLE public.paiements ALTER COLUMN contrat_id    DROP NOT NULL;
ALTER TABLE public.paiements ALTER COLUMN locataire_id  DROP NOT NULL;
ALTER TABLE public.paiements ALTER COLUMN propriete_id  DROP NOT NULL;
ALTER TABLE public.paiements ALTER COLUMN montant_loyer DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_paiements_contrat   ON public.paiements(contrat_id);
CREATE INDEX IF NOT EXISTS idx_paiements_locataire ON public.paiements(locataire_id);
CREATE INDEX IF NOT EXISTS idx_paiements_statut    ON public.paiements(statut);
CREATE INDEX IF NOT EXISTS idx_paiements_echeance  ON public.paiements(date_echeance);

-- ============================================================
-- 12. TABLE TICKETS_SUPPORT
-- ============================================================
CREATE TABLE IF NOT EXISTS public.tickets_support (
    id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference        TEXT UNIQUE,
    createur_id      UUID REFERENCES public.profiles(id) NOT NULL,
    type_createur    user_role NOT NULL DEFAULT 'locataire',
    propriete_id     UUID REFERENCES public.proprietes(id),
    contrat_id       UUID REFERENCES public.contrats_location(id),
    sujet            TEXT NOT NULL,
    description      TEXT NOT NULL DEFAULT '',
    categorie        TEXT NOT NULL DEFAULT 'autre',
    priorite         ticket_priority DEFAULT 'moyenne',
    assigne_a        UUID REFERENCES public.profiles(id),
    agent_responsable UUID REFERENCES public.agents(id),
    statut           ticket_status DEFAULT 'ouvert',
    date_resolution  TIMESTAMPTZ,
    resolution_notes TEXT,
    photos           TEXT[],
    documents        TEXT[],
    note_satisfaction INTEGER CHECK (note_satisfaction BETWEEN 1 AND 5),
    commentaire_satisfaction TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tickets_createur  ON public.tickets_support(createur_id);
CREATE INDEX IF NOT EXISTS idx_tickets_propriete ON public.tickets_support(propriete_id);
CREATE INDEX IF NOT EXISTS idx_tickets_statut    ON public.tickets_support(statut);

-- ============================================================
-- 13. TABLE NOTIFICATIONS_SYSTEME
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications_systeme (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    destinataire_id UUID REFERENCES public.profiles(id) NOT NULL,
    type            TEXT NOT NULL,
    titre           TEXT NOT NULL,
    message         TEXT NOT NULL,
    lien            TEXT,
    est_lu          BOOLEAN DEFAULT FALSE,
    date_lecture    TIMESTAMPTZ,
    envoye_email    BOOLEAN DEFAULT FALSE,
    envoye_sms      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notif_destinataire ON public.notifications_systeme(destinataire_id);
CREATE INDEX IF NOT EXISTS idx_notif_lu           ON public.notifications_systeme(est_lu);

-- ============================================================
-- 14. TABLE DOCUMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    proprietaire_id  UUID REFERENCES public.proprietaires(id),
    locataire_id     UUID REFERENCES public.locataires(id),
    propriete_id     UUID REFERENCES public.proprietes(id),
    contrat_id       UUID REFERENCES public.contrats_location(id),
    nom              TEXT NOT NULL,
    type_document    TEXT NOT NULL DEFAULT 'autre',
    description      TEXT,
    fichier_url      TEXT NOT NULL,
    taille_octets    INTEGER,
    mime_type        TEXT,
    est_public       BOOLEAN DEFAULT FALSE,
    visible_proprietaire BOOLEAN DEFAULT TRUE,
    visible_locataire    BOOLEAN DEFAULT TRUE,
    telecharge_par   UUID REFERENCES public.profiles(id),
    date_expiration  DATE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 15. FONCTIONS UTILITAIRES (version définitive)
-- ============================================================

-- is_admin() : vérifie role = 'admin' via la colonne role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role::text = 'admin'
    );
$$;

CREATE OR REPLACE FUNCTION public.is_proprietaire()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role::text = 'proprietaire'
    );
$$;

CREATE OR REPLACE FUNCTION public.is_locataire()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role::text = 'locataire'
    );
$$;

CREATE OR REPLACE FUNCTION public.get_proprietaire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id FROM public.proprietaires WHERE user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_locataire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id FROM public.locataires WHERE user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

-- ============================================================
-- 16. TRIGGER PROFIL AUTO (inscription)
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_role user_role;
BEGIN
    v_role := COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'locataire');
    INSERT INTO public.profiles (id, email, full_name, phone, role)
    VALUES (
        NEW.id, NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        NEW.raw_user_meta_data->>'phone',
        v_role
    )
    ON CONFLICT (id) DO UPDATE SET
        email     = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        updated_at = NOW();
    IF v_role = 'proprietaire' THEN
        INSERT INTO public.proprietaires (user_id) VALUES (NEW.id)
        ON CONFLICT (user_id) DO NOTHING;
    ELSIF v_role = 'locataire' THEN
        INSERT INTO public.locataires (user_id) VALUES (NEW.id)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 17. TRIGGERS UPDATED_AT
-- ============================================================
DROP TRIGGER IF EXISTS upd_profiles      ON public.profiles;
DROP TRIGGER IF EXISTS upd_proprietaires ON public.proprietaires;
DROP TRIGGER IF EXISTS upd_locataires    ON public.locataires;
DROP TRIGGER IF EXISTS upd_contrats      ON public.contrats_location;
DROP TRIGGER IF EXISTS upd_paiements     ON public.paiements;
DROP TRIGGER IF EXISTS upd_tickets       ON public.tickets_support;
DROP TRIGGER IF EXISTS upd_proprietes    ON public.proprietes;

CREATE TRIGGER upd_profiles      BEFORE UPDATE ON public.profiles       FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_proprietaires BEFORE UPDATE ON public.proprietaires  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_locataires    BEFORE UPDATE ON public.locataires     FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_contrats      BEFORE UPDATE ON public.contrats_location FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_paiements     BEFORE UPDATE ON public.paiements      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_tickets       BEFORE UPDATE ON public.tickets_support FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_proprietes    BEFORE UPDATE ON public.proprietes     FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 18. TRIGGER REFERENCES AUTO
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS contrat_seq   START 1;
CREATE SEQUENCE IF NOT EXISTS paiement_seq  START 1;
CREATE SEQUENCE IF NOT EXISTS ticket_seq    START 1;
CREATE SEQUENCE IF NOT EXISTS propriete_seq START 1;

CREATE OR REPLACE FUNCTION public.generer_reference_contrat()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'CTR-' || TO_CHAR(NOW(),'YYYY') || '-' || LPAD(NEXTVAL('contrat_seq')::TEXT, 5, '0');
    END IF; RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.generer_reference_paiement()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'PAY-' || TO_CHAR(NOW(),'YYMM') || '-' || LPAD(NEXTVAL('paiement_seq')::TEXT, 6, '0');
    END IF; RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.generer_reference_ticket()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'TKT-' || TO_CHAR(NOW(),'YYMM') || '-' || LPAD(NEXTVAL('ticket_seq')::TEXT, 5, '0');
    END IF; RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.generer_reference_propriete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'PROP-' || TO_CHAR(NOW(),'YYYY') || '-' || LPAD(NEXTVAL('propriete_seq')::TEXT, 5, '0');
    END IF; RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS set_reference_contrat   ON public.contrats_location;
DROP TRIGGER IF EXISTS set_reference_paiement  ON public.paiements;
DROP TRIGGER IF EXISTS set_reference_ticket    ON public.tickets_support;
DROP TRIGGER IF EXISTS set_reference_propriete ON public.proprietes;

CREATE TRIGGER set_reference_contrat   BEFORE INSERT ON public.contrats_location FOR EACH ROW EXECUTE FUNCTION public.generer_reference_contrat();
CREATE TRIGGER set_reference_paiement  BEFORE INSERT ON public.paiements          FOR EACH ROW EXECUTE FUNCTION public.generer_reference_paiement();
CREATE TRIGGER set_reference_ticket    BEFORE INSERT ON public.tickets_support     FOR EACH ROW EXECUTE FUNCTION public.generer_reference_ticket();
CREATE TRIGGER set_reference_propriete BEFORE INSERT ON public.proprietes          FOR EACH ROW EXECUTE FUNCTION public.generer_reference_propriete();

-- ============================================================
-- 19. CALCUL SOLDE RESTANT (paiements)
-- ============================================================
CREATE OR REPLACE FUNCTION public.calc_solde_restant()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.solde_restant := NEW.montant_total - COALESCE(NEW.montant_paye, 0);
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS calc_solde_paiement ON public.paiements;
CREATE TRIGGER calc_solde_paiement
    BEFORE INSERT OR UPDATE ON public.paiements
    FOR EACH ROW EXECUTE FUNCTION public.calc_solde_restant();

-- ============================================================
-- 20. RLS - ACTIVER SUR TOUTES LES TABLES
-- ============================================================
ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proprietaires     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locataires        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zones             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proprietes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contrats_location ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paiements         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets_support   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_systeme ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 21. NETTOYAGE COMPLET : supprimer TOUTES les politiques
--     existantes de tous les anciens scripts
-- ============================================================

-- profiles (scripts 04, 08, 13)
DROP POLICY IF EXISTS "p_sel"                ON public.profiles;
DROP POLICY IF EXISTS "p_ins"                ON public.profiles;
DROP POLICY IF EXISTS "p_upd"                ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_admin" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_all"   ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles;

-- agents (scripts 04, 08, 13)
DROP POLICY IF EXISTS "ag_sel"               ON public.agents;
DROP POLICY IF EXISTS "ag_adm"               ON public.agents;
DROP POLICY IF EXISTS "agents_select_public" ON public.agents;
DROP POLICY IF EXISTS "agents_admin_all"     ON public.agents;
DROP POLICY IF EXISTS "agents_public_select" ON public.agents;
DROP POLICY IF EXISTS "agents_admin_write"   ON public.agents;

-- zones (scripts 04, 08)
DROP POLICY IF EXISTS "zo_sel"               ON public.zones;
DROP POLICY IF EXISTS "zo_adm"               ON public.zones;
DROP POLICY IF EXISTS "zones_select_public"  ON public.zones;
DROP POLICY IF EXISTS "zones_admin_all"      ON public.zones;

-- proprietes (scripts 04, 08, 13)
DROP POLICY IF EXISTS "prop_pub"                      ON public.proprietes;
DROP POLICY IF EXISTS "prop_adm"                      ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_select_public"      ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_select_proprietaire" ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_select_locataire"   ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_admin_all"          ON public.proprietes;
DROP POLICY IF EXISTS "prop_public_select"            ON public.proprietes;
DROP POLICY IF EXISTS "prop_admin_write"              ON public.proprietes;

-- proprietaires (scripts 08, 13)
DROP POLICY IF EXISTS "proprietaires_select_own"   ON public.proprietaires;
DROP POLICY IF EXISTS "proprietaires_update_own"   ON public.proprietaires;
DROP POLICY IF EXISTS "proprietaires_admin_all"    ON public.proprietaires;
DROP POLICY IF EXISTS "prop_admin_all"             ON public.proprietaires;
DROP POLICY IF EXISTS "prop_self_select"           ON public.proprietaires;

-- locataires (scripts 08, 13)
DROP POLICY IF EXISTS "locataires_select_own"           ON public.locataires;
DROP POLICY IF EXISTS "locataires_update_own"           ON public.locataires;
DROP POLICY IF EXISTS "locataires_admin_all"            ON public.locataires;
DROP POLICY IF EXISTS "locataires_proprietaire_select"  ON public.locataires;
DROP POLICY IF EXISTS "loc_admin_all"                   ON public.locataires;
DROP POLICY IF EXISTS "loc_self_select"                 ON public.locataires;

-- contrats (scripts 08, 13)
DROP POLICY IF EXISTS "contrats_select_locataire"   ON public.contrats_location;
DROP POLICY IF EXISTS "contrats_select_proprietaire" ON public.contrats_location;
DROP POLICY IF EXISTS "contrats_admin_all"          ON public.contrats_location;
DROP POLICY IF EXISTS "contrats_parties"            ON public.contrats_location;

-- paiements (scripts 08, 13)
DROP POLICY IF EXISTS "paiements_select_locataire"   ON public.paiements;
DROP POLICY IF EXISTS "paiements_select_proprietaire" ON public.paiements;
DROP POLICY IF EXISTS "paiements_admin_all"          ON public.paiements;
DROP POLICY IF EXISTS "paiements_locataire_sel"      ON public.paiements;

-- contacts (scripts 04, 08, 13)
DROP POLICY IF EXISTS "cont_ins"              ON public.contacts;
DROP POLICY IF EXISTS "cont_sel"              ON public.contacts;
DROP POLICY IF EXISTS "cont_upd"              ON public.contacts;
DROP POLICY IF EXISTS "contacts_insert_public" ON public.contacts;
DROP POLICY IF EXISTS "contacts_admin_all"    ON public.contacts;
DROP POLICY IF EXISTS "contacts_public_insert" ON public.contacts;

-- tickets (scripts 08, 13)
DROP POLICY IF EXISTS "tickets_select_createur"    ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_insert_locataire"   ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_insert_proprietaire" ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_select_proprietaire" ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_admin_all"           ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_creator_sel"         ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_public_insert"       ON public.tickets_support;

-- documents (scripts 08, 13)
DROP POLICY IF EXISTS "documents_select_proprietaire" ON public.documents;
DROP POLICY IF EXISTS "documents_select_locataire"    ON public.documents;
DROP POLICY IF EXISTS "documents_admin_all"           ON public.documents;
DROP POLICY IF EXISTS "documents_parties"             ON public.documents;

-- notifications (scripts 08, 13)
DROP POLICY IF EXISTS "notif_adm"            ON public.notifications_systeme;
DROP POLICY IF EXISTS "notif_select_own"     ON public.notifications_systeme;
DROP POLICY IF EXISTS "notif_update_own"     ON public.notifications_systeme;
DROP POLICY IF EXISTS "notif_admin_all"      ON public.notifications_systeme;
DROP POLICY IF EXISTS "notif_own_select"     ON public.notifications_systeme;

-- ============================================================
-- 22. RECRÉER DES POLITIQUES RLS PROPRES ET DEFINITIVES
-- ============================================================

-- PROFILES
CREATE POLICY "profiles_select" ON public.profiles
    FOR SELECT USING (id = auth.uid() OR public.is_admin());
CREATE POLICY "profiles_insert" ON public.profiles
    FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update" ON public.profiles
    FOR UPDATE USING (id = auth.uid() OR public.is_admin());
CREATE POLICY "profiles_delete" ON public.profiles
    FOR DELETE USING (public.is_admin());

-- AGENTS : lecture publique, écriture admin
CREATE POLICY "agents_select" ON public.agents
    FOR SELECT USING (TRUE);
CREATE POLICY "agents_write" ON public.agents
    FOR ALL USING (public.is_admin());

-- ZONES : lecture publique, écriture admin
CREATE POLICY "zones_select" ON public.zones
    FOR SELECT USING (TRUE);
CREATE POLICY "zones_write" ON public.zones
    FOR ALL USING (public.is_admin());

-- PROPRIETES : lecture publique (tous), écriture admin
CREATE POLICY "proprietes_select" ON public.proprietes
    FOR SELECT USING (TRUE);
CREATE POLICY "proprietes_write" ON public.proprietes
    FOR ALL USING (public.is_admin());

-- PROPRIETAIRES
CREATE POLICY "proprietaires_select" ON public.proprietaires
    FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "proprietaires_update" ON public.proprietaires
    FOR UPDATE USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "proprietaires_insert" ON public.proprietaires
    FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "proprietaires_delete" ON public.proprietaires
    FOR DELETE USING (public.is_admin());

-- LOCATAIRES
CREATE POLICY "locataires_select" ON public.locataires
    FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "locataires_update" ON public.locataires
    FOR UPDATE USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "locataires_insert" ON public.locataires
    FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "locataires_delete" ON public.locataires
    FOR DELETE USING (public.is_admin());

-- CONTRATS_LOCATION
CREATE POLICY "contrats_select" ON public.contrats_location
    FOR SELECT USING (
        public.is_admin()
        OR locataire_id IN (SELECT id FROM public.locataires WHERE user_id = auth.uid())
        OR proprietaire_id IN (SELECT id FROM public.proprietaires WHERE user_id = auth.uid())
    );
CREATE POLICY "contrats_write" ON public.contrats_location
    FOR ALL USING (public.is_admin());

-- PAIEMENTS
CREATE POLICY "paiements_select" ON public.paiements
    FOR SELECT USING (
        public.is_admin()
        OR locataire_id IN (SELECT id FROM public.locataires WHERE user_id = auth.uid())
    );
CREATE POLICY "paiements_write" ON public.paiements
    FOR ALL USING (public.is_admin());

-- TICKETS_SUPPORT
CREATE POLICY "tickets_select" ON public.tickets_support
    FOR SELECT USING (createur_id = auth.uid() OR public.is_admin());
CREATE POLICY "tickets_insert" ON public.tickets_support
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "tickets_write_admin" ON public.tickets_support
    FOR ALL USING (public.is_admin());

-- CONTACTS
CREATE POLICY "contacts_insert" ON public.contacts
    FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "contacts_admin"  ON public.contacts
    FOR ALL USING (public.is_admin());

-- DOCUMENTS
CREATE POLICY "documents_select" ON public.documents
    FOR SELECT USING (
        public.is_admin()
        OR proprietaire_id IN (SELECT id FROM public.proprietaires WHERE user_id = auth.uid())
        OR locataire_id    IN (SELECT id FROM public.locataires    WHERE user_id = auth.uid())
    );
CREATE POLICY "documents_write" ON public.documents
    FOR ALL USING (public.is_admin());

-- NOTIFICATIONS_SYSTEME
CREATE POLICY "notif_select" ON public.notifications_systeme
    FOR SELECT USING (destinataire_id = auth.uid() OR public.is_admin());
CREATE POLICY "notif_update" ON public.notifications_systeme
    FOR UPDATE USING (destinataire_id = auth.uid() OR public.is_admin());

-- ============================================================
-- 23. RPC FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.incrementer_vues(p_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.proprietes SET vue_count = COALESCE(vue_count, 0) + 1 WHERE id = p_id;
END; $$;

DROP FUNCTION IF EXISTS public.rechercher_proprietes(TEXT,TEXT,NUMERIC,NUMERIC,INTEGER,BOOLEAN,UUID,INTEGER,INTEGER);
CREATE OR REPLACE FUNCTION public.rechercher_proprietes(
    p_transaction TEXT    DEFAULT NULL,
    p_type        TEXT    DEFAULT NULL,
    p_prix_min    NUMERIC DEFAULT NULL,
    p_prix_max    NUMERIC DEFAULT NULL,
    p_chambres_min INTEGER DEFAULT NULL,
    p_meuble      BOOLEAN DEFAULT NULL,
    p_zone_id     UUID    DEFAULT NULL,
    p_limit       INTEGER DEFAULT 12,
    p_offset      INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID, titre TEXT, slug TEXT, type_transaction TEXT, type_propriete TEXT,
    prix NUMERIC, prix_location NUMERIC, prix_vente NUMERIC, devise TEXT,
    nb_chambres INTEGER, nb_salles_bain INTEGER, superficie_m2 NUMERIC,
    images TEXT[], adresse TEXT, ville TEXT, zone_nom TEXT, statut TEXT,
    est_vedette BOOLEAN, vue_count INTEGER, created_at TIMESTAMPTZ, total BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM public.proprietes p
    LEFT JOIN public.zones z ON z.id = p.zone_id
    WHERE p.est_actif = TRUE
      AND (p_transaction IS NULL  OR p.type_transaction = p_transaction)
      AND (p_type        IS NULL  OR p.type_propriete   = p_type)
      AND (p_prix_min    IS NULL  OR COALESCE(p.prix_location, p.prix_vente, p.prix) >= p_prix_min)
      AND (p_prix_max    IS NULL  OR COALESCE(p.prix_location, p.prix_vente, p.prix) <= p_prix_max)
      AND (p_chambres_min IS NULL OR p.nb_chambres >= p_chambres_min)
      AND (p_meuble      IS NULL  OR p.meuble = p_meuble)
      AND (p_zone_id     IS NULL  OR p.zone_id = p_zone_id);

    RETURN QUERY
    SELECT p.id, p.titre, p.slug, p.type_transaction, p.type_propriete,
           COALESCE(p.prix, 0), p.prix_location, p.prix_vente, COALESCE(p.devise,'USD'),
           p.nb_chambres, p.nb_salles_bain, p.superficie_m2,
           COALESCE(p.images,'{}'), p.adresse, p.ville, z.nom, p.statut,
           COALESCE(p.est_vedette,FALSE), COALESCE(p.vue_count,0), p.created_at, v_total
    FROM public.proprietes p
    LEFT JOIN public.zones z ON z.id = p.zone_id
    WHERE p.est_actif = TRUE
      AND (p_transaction IS NULL  OR p.type_transaction = p_transaction)
      AND (p_type        IS NULL  OR p.type_propriete   = p_type)
      AND (p_prix_min    IS NULL  OR COALESCE(p.prix_location, p.prix_vente, p.prix) >= p_prix_min)
      AND (p_prix_max    IS NULL  OR COALESCE(p.prix_location, p.prix_vente, p.prix) <= p_prix_max)
      AND (p_chambres_min IS NULL OR p.nb_chambres >= p_chambres_min)
      AND (p_meuble      IS NULL  OR p.meuble = p_meuble)
      AND (p_zone_id     IS NULL  OR p.zone_id = p_zone_id)
    ORDER BY p.est_vedette DESC, p.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;

CREATE OR REPLACE FUNCTION public.get_locataire_dashboard(p_locataire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'contrat_actif', (SELECT json_build_object(
            'id', c.id, 'reference', c.reference,
            'propriete_titre', pr.titre, 'propriete_adresse', pr.adresse,
            'loyer_mensuel', c.loyer_mensuel, 'date_fin', c.date_fin,
            'jours_restants', (c.date_fin - CURRENT_DATE)
        ) FROM public.contrats_location c
        JOIN public.proprietes pr ON pr.id = c.propriete_id
        WHERE c.locataire_id = p_locataire_id AND c.statut = 'actif' LIMIT 1),
        'prochain_paiement', (SELECT json_build_object(
            'montant', montant_total, 'date_echeance', date_echeance,
            'jours_avant', (date_echeance - CURRENT_DATE)
        ) FROM public.paiements
        WHERE locataire_id = p_locataire_id AND statut = 'en_attente'
        ORDER BY date_echeance LIMIT 1),
        'solde_du', (SELECT COALESCE(SUM(solde_restant),0) FROM public.paiements
            WHERE locataire_id = p_locataire_id AND statut IN ('en_attente','en_retard','partiel')),
        'paiements_retard', (SELECT COUNT(*) FROM public.paiements
            WHERE locataire_id = p_locataire_id AND statut = 'en_retard'),
        'score_paiement', (SELECT score_paiement FROM public.locataires WHERE id = p_locataire_id)
    ) INTO result;
    RETURN result;
END; $$;

CREATE OR REPLACE FUNCTION public.get_proprietaire_dashboard(p_proprietaire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'mes_proprietes', (SELECT COUNT(*) FROM public.proprietes
            WHERE proprietaire_id = p_proprietaire_id AND est_actif = TRUE),
        'proprietes_louees', (SELECT COUNT(*) FROM public.proprietes
            WHERE proprietaire_id = p_proprietaire_id AND statut = 'loue'),
        'revenus_ce_mois', (SELECT COALESCE(SUM(p.montant_paye),0)
            FROM public.paiements p
            JOIN public.contrats_location c ON c.id = p.contrat_id
            WHERE c.proprietaire_id = p_proprietaire_id AND p.statut = 'paye'
            AND DATE_TRUNC('month', p.date_paiement) = DATE_TRUNC('month', CURRENT_DATE)),
        'contrats_actifs', (SELECT COUNT(*) FROM public.contrats_location
            WHERE proprietaire_id = p_proprietaire_id AND statut = 'actif'),
        'taux_occupation', (SELECT
            CASE WHEN COUNT(*) > 0
            THEN ROUND(COUNT(*) FILTER (WHERE statut='loue')::NUMERIC / COUNT(*) * 100, 1)
            ELSE 0 END
            FROM public.proprietes WHERE proprietaire_id = p_proprietaire_id AND est_actif = TRUE)
    ) INTO result;
    RETURN result;
END; $$;

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'total_proprietes',        (SELECT COUNT(*) FROM public.proprietes WHERE est_actif = TRUE),
        'proprietes_disponibles',  (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'disponible' AND est_actif = TRUE),
        'proprietes_louees',       (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'loue'),
        'total_proprietaires',     (SELECT COUNT(*) FROM public.proprietaires WHERE est_actif = TRUE),
        'total_locataires',        (SELECT COUNT(*) FROM public.locataires WHERE est_actif = TRUE),
        'total_agents',            (SELECT COUNT(*) FROM public.agents WHERE actif = TRUE),
        'contrats_actifs',         (SELECT COUNT(*) FROM public.contrats_location WHERE statut = 'actif'),
        'paiements_en_attente',    (SELECT COUNT(*) FROM public.paiements WHERE statut = 'en_attente'),
        'paiements_en_retard',     (SELECT COUNT(*) FROM public.paiements WHERE statut = 'en_retard'),
        'revenus_ce_mois',         (SELECT COALESCE(SUM(montant_paye),0) FROM public.paiements
                                    WHERE statut='paye'
                                    AND DATE_TRUNC('month',date_paiement) = DATE_TRUNC('month',CURRENT_DATE)),
        'tickets_ouverts',         (SELECT COUNT(*) FROM public.tickets_support WHERE statut IN ('ouvert','en_cours')),
        'nouveaux_contacts',       (SELECT COUNT(*) FROM public.contacts WHERE traite = FALSE)
    ) INTO result;
    RETURN result;
END; $$;

-- ============================================================
-- 24. GRANTS pour fonctions RPC
-- ============================================================
GRANT EXECUTE ON FUNCTION public.incrementer_vues(UUID)                                                              TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rechercher_proprietes(TEXT,TEXT,NUMERIC,NUMERIC,INTEGER,BOOLEAN,UUID,INTEGER,INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_locataire_dashboard(UUID)                                                        TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_proprietaire_dashboard(UUID)                                                     TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_stats()                                                          TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin()                                                                           TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_proprietaire()                                                                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_locataire()                                                                       TO authenticated;

-- ============================================================
-- 25. STORAGE BUCKETS
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('property-images','property-images',true,10485760,ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO UPDATE SET public=true, file_size_limit=10485760;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profile-avatars','profile-avatars',true,5242880,ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE SET public=true, file_size_limit=5242880;

-- ============================================================
-- 26. STORAGE POLICIES (nettoyage + recréation)
-- ============================================================
DROP POLICY IF EXISTS "Public view property images"  ON storage.objects;
DROP POLICY IF EXISTS "Admin upload property images" ON storage.objects;
DROP POLICY IF EXISTS "Admin delete property images" ON storage.objects;
DROP POLICY IF EXISTS "Public view avatars"          ON storage.objects;
DROP POLICY IF EXISTS "Users upload own avatar"      ON storage.objects;
DROP POLICY IF EXISTS "Admin manage all avatars"     ON storage.objects;

CREATE POLICY "Public view property images" ON storage.objects
    FOR SELECT USING (bucket_id = 'property-images');

CREATE POLICY "Admin upload property images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'property-images'
        AND EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND role::text='admin'));

CREATE POLICY "Admin delete property images" ON storage.objects
    FOR DELETE USING (bucket_id = 'property-images'
        AND EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND role::text='admin'));

CREATE POLICY "Public view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-avatars');

CREATE POLICY "Users upload own avatar" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profile-avatars'
        AND ((storage.foldername(name))[1] = auth.uid()::text
            OR EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND role::text='admin')));

CREATE POLICY "Admin manage all avatars" ON storage.objects
    FOR ALL USING (bucket_id = 'profile-avatars'
        AND EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND role::text='admin'));

-- ============================================================
-- 27. RECHARGER LE SCHEMA CACHE DE POSTGREST/SUPABASE
-- ============================================================
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- 28. VÉRIFICATION FINALE
-- ============================================================
SELECT
    table_name,
    COUNT(*) AS nb_colonnes
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles','proprietaires','locataires','proprietes',
    'contrats_location','paiements','agents','zones',
    'contacts','tickets_support','documents','notifications_systeme'
  )
GROUP BY table_name
ORDER BY table_name;
