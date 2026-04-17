-- ============================================================
-- EXPER IMMO - COMPLETE DATABASE SCHEMA
-- Multi-tenant Real Estate Management System
-- ============================================================
-- 3 User Types:
-- 1. ADMIN (Expert Immo) - Full access to everything
-- 2. PROPRIETAIRE (Property Owner) - Manage their own properties
-- 3. LOCATAIRE (Tenant) - Access their rental info & payments
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ============================================================
-- ENUM TYPES
-- ============================================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'proprietaire', 'locataire');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('en_attente', 'paye', 'en_retard', 'partiel', 'annule');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ticket_status AS ENUM ('ouvert', 'en_cours', 'resolu', 'ferme');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ticket_priority AS ENUM ('basse', 'moyenne', 'haute', 'urgente');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE contrat_status AS ENUM ('brouillon', 'actif', 'expire', 'resilie', 'renouvele');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 1. PROFILES - Extended User Profiles
-- ============================================================
DROP TABLE IF EXISTS public.profiles CASCADE;
CREATE TABLE public.profiles (
    id              UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email           TEXT UNIQUE NOT NULL,
    full_name       TEXT NOT NULL,
    phone           TEXT,
    phone_secondary TEXT,
    avatar_url      TEXT,
    
    -- Role & Permissions
    role            user_role NOT NULL DEFAULT 'locataire',
    is_verified     BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    
    -- Address Info
    adresse         TEXT,
    ville           TEXT,
    code_postal     TEXT,
    pays            TEXT DEFAULT 'Haïti',
    
    -- Identity Documents (for verification)
    numero_identite TEXT,           -- NIF/CIN
    type_identite   TEXT,           -- 'cin', 'passeport', 'permis'
    document_url    TEXT,           -- Scanned document
    
    -- Emergency Contact
    contact_urgence_nom      TEXT,
    contact_urgence_tel      TEXT,
    contact_urgence_relation TEXT,
    
    -- Metadata
    derniere_connexion TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- ============================================================
-- 2. PROPRIETAIRES - Property Owners
-- ============================================================
CREATE TABLE public.proprietaires (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    
    -- Business Info
    type_proprietaire TEXT DEFAULT 'particulier' CHECK (type_proprietaire IN ('particulier', 'entreprise', 'syndic')),
    nom_entreprise  TEXT,
    numero_fiscal   TEXT,
    
    -- Banking Info (for rent deposits)
    nom_banque      TEXT,
    numero_compte   TEXT,
    rib_iban        TEXT,
    
    -- Preferences
    mode_paiement_prefere   TEXT DEFAULT 'virement' CHECK (mode_paiement_prefere IN ('virement', 'cheque', 'especes', 'mobile_money')),
    frequence_rapport       TEXT DEFAULT 'mensuel' CHECK (frequence_rapport IN ('hebdomadaire', 'mensuel', 'trimestriel')),
    notification_email      BOOLEAN DEFAULT TRUE,
    notification_sms        BOOLEAN DEFAULT FALSE,
    notification_whatsapp   BOOLEAN DEFAULT TRUE,
    
    -- Contract with EXPER IMMO
    date_debut_mandat   DATE,
    date_fin_mandat     DATE,
    commission_taux     DECIMAL(5,2) DEFAULT 10.00,  -- % of rent
    
    -- Stats
    nb_proprietes   INTEGER DEFAULT 0,
    revenu_total    DECIMAL(15,2) DEFAULT 0,
    
    -- Status
    est_actif       BOOLEAN DEFAULT TRUE,
    notes_admin     TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_proprietaires_user ON public.proprietaires(user_id);

-- ============================================================
-- 3. LOCATAIRES - Tenants
-- ============================================================
CREATE TABLE public.locataires (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    
    -- Employment Info
    profession      TEXT,
    employeur       TEXT,
    revenu_mensuel  DECIMAL(12,2),
    
    -- Guarantor Info
    garant_nom      TEXT,
    garant_telephone TEXT,
    garant_email    TEXT,
    garant_adresse  TEXT,
    garant_profession TEXT,
    
    -- Rental History
    ancien_proprietaire_nom TEXT,
    ancien_proprietaire_tel TEXT,
    raison_depart   TEXT,
    
    -- Document References
    fiche_paie_url  TEXT,
    contrat_travail_url TEXT,
    
    -- Payment Rating
    score_paiement  INTEGER DEFAULT 100,  -- 0-100 score
    nb_retards_paiement INTEGER DEFAULT 0,
    
    -- Status
    est_actif       BOOLEAN DEFAULT TRUE,
    est_blackliste  BOOLEAN DEFAULT FALSE,
    raison_blacklist TEXT,
    notes_admin     TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_locataires_user ON public.locataires(user_id);
CREATE INDEX idx_locataires_score ON public.locataires(score_paiement);

-- ============================================================
-- 4. AGENTS (Keep existing but enhance)
-- ============================================================
-- Already exists in 02_schema.sql, we just reference it

-- ============================================================
-- 5. ZONES (Keep existing)
-- ============================================================
-- Already exists in 02_schema.sql

-- ============================================================
-- 6. PROPRIETES - Enhanced Properties Table
-- ============================================================
-- Add proprietaire_id to existing proprietes table
ALTER TABLE public.proprietes 
ADD COLUMN IF NOT EXISTS proprietaire_id UUID REFERENCES public.proprietaires(id);

ALTER TABLE public.proprietes
ADD COLUMN IF NOT EXISTS est_gere BOOLEAN DEFAULT FALSE;  -- Managed by EXPER IMMO

ALTER TABLE public.proprietes
ADD COLUMN IF NOT EXISTS date_acquisition DATE;

ALTER TABLE public.proprietes
ADD COLUMN IF NOT EXISTS valeur_estimee DECIMAL(15,2);

ALTER TABLE public.proprietes
ADD COLUMN IF NOT EXISTS charges_copropriete DECIMAL(10,2) DEFAULT 0;

ALTER TABLE public.proprietes
ADD COLUMN IF NOT EXISTS taxe_fonciere_annuelle DECIMAL(10,2) DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_prop_proprietaire ON public.proprietes(proprietaire_id);

-- ============================================================
-- 7. CONTRATS_LOCATION - Rental Contracts
-- ============================================================
CREATE TABLE public.contrats_location (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference           TEXT UNIQUE NOT NULL,
    
    -- Parties
    propriete_id        UUID REFERENCES public.proprietes(id) ON DELETE CASCADE NOT NULL,
    locataire_id        UUID REFERENCES public.locataires(id) ON DELETE CASCADE NOT NULL,
    proprietaire_id     UUID REFERENCES public.proprietaires(id) NOT NULL,
    agent_id            UUID REFERENCES public.agents(id),
    
    -- Contract Terms
    date_debut          DATE NOT NULL,
    date_fin            DATE NOT NULL,
    duree_mois          INTEGER,
    
    -- Financial Terms
    loyer_mensuel       DECIMAL(12,2) NOT NULL,
    devise              TEXT DEFAULT 'USD',
    charges_mensuelles  DECIMAL(10,2) DEFAULT 0,
    depot_garantie      DECIMAL(12,2) NOT NULL,
    depot_garantie_paye BOOLEAN DEFAULT FALSE,
    
    -- Payment Terms
    jour_paiement       INTEGER DEFAULT 1 CHECK (jour_paiement BETWEEN 1 AND 28),
    mode_paiement       TEXT DEFAULT 'virement',
    penalite_retard_pct DECIMAL(5,2) DEFAULT 5.00,
    jours_grace         INTEGER DEFAULT 5,
    
    -- Documents
    contrat_pdf_url     TEXT,
    etat_des_lieux_entree_url TEXT,
    etat_des_lieux_sortie_url TEXT,
    
    -- Status
    statut              contrat_status DEFAULT 'brouillon',
    motif_resiliation   TEXT,
    date_resiliation    DATE,
    preavis_donne       BOOLEAN DEFAULT FALSE,
    date_preavis        DATE,
    
    -- Renewal
    renouvellement_auto BOOLEAN DEFAULT FALSE,
    preavis_requis_jours INTEGER DEFAULT 30,
    
    -- Notes
    conditions_speciales TEXT,
    notes_internes      TEXT,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contrat_propriete ON public.contrats_location(propriete_id);
CREATE INDEX idx_contrat_locataire ON public.contrats_location(locataire_id);
CREATE INDEX idx_contrat_proprietaire ON public.contrats_location(proprietaire_id);
CREATE INDEX idx_contrat_statut ON public.contrats_location(statut);
CREATE INDEX idx_contrat_dates ON public.contrats_location(date_debut, date_fin);

-- ============================================================
-- 8. PAIEMENTS - Payment Records
-- ============================================================
CREATE TABLE public.paiements (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference           TEXT UNIQUE NOT NULL,
    
    -- Links
    contrat_id          UUID REFERENCES public.contrats_location(id) ON DELETE CASCADE NOT NULL,
    locataire_id        UUID REFERENCES public.locataires(id) NOT NULL,
    propriete_id        UUID REFERENCES public.proprietes(id) NOT NULL,
    
    -- Payment Period
    mois                INTEGER NOT NULL CHECK (mois BETWEEN 1 AND 12),
    annee               INTEGER NOT NULL,
    periode_debut       DATE NOT NULL,
    periode_fin         DATE NOT NULL,
    
    -- Amounts
    montant_loyer       DECIMAL(12,2) NOT NULL,
    montant_charges     DECIMAL(10,2) DEFAULT 0,
    montant_penalite    DECIMAL(10,2) DEFAULT 0,
    montant_autre       DECIMAL(10,2) DEFAULT 0,
    description_autre   TEXT,
    montant_total       DECIMAL(12,2) NOT NULL,
    montant_paye        DECIMAL(12,2) DEFAULT 0,
    solde_restant       DECIMAL(12,2) DEFAULT 0,
    devise              TEXT DEFAULT 'USD',
    
    -- Payment Info
    date_echeance       DATE NOT NULL,
    date_paiement       DATE,
    mode_paiement       TEXT,
    reference_transaction TEXT,
    
    -- Status
    statut              payment_status DEFAULT 'en_attente',
    jours_retard        INTEGER DEFAULT 0,
    
    -- Proof
    recu_url            TEXT,
    preuve_paiement_url TEXT,
    
    -- Processed by
    traite_par          UUID REFERENCES public.profiles(id),
    notes               TEXT,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_paiements_contrat ON public.paiements(contrat_id);
CREATE INDEX idx_paiements_locataire ON public.paiements(locataire_id);
CREATE INDEX idx_paiements_propriete ON public.paiements(propriete_id);
CREATE INDEX idx_paiements_statut ON public.paiements(statut);
CREATE INDEX idx_paiements_periode ON public.paiements(annee, mois);
CREATE INDEX idx_paiements_echeance ON public.paiements(date_echeance);

-- ============================================================
-- 9. TICKETS_SUPPORT - Support Tickets/Complaints
-- ============================================================
CREATE TABLE public.tickets_support (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference           TEXT UNIQUE NOT NULL,
    
    -- Who created it
    createur_id         UUID REFERENCES public.profiles(id) NOT NULL,
    type_createur       user_role NOT NULL,
    
    -- Related to
    propriete_id        UUID REFERENCES public.proprietes(id),
    contrat_id          UUID REFERENCES public.contrats_location(id),
    
    -- Ticket Info
    sujet               TEXT NOT NULL,
    description         TEXT NOT NULL,
    categorie           TEXT NOT NULL CHECK (categorie IN (
        'maintenance', 'plomberie', 'electricite', 'paiement', 
        'bruit', 'securite', 'nettoyage', 'autre'
    )),
    priorite            ticket_priority DEFAULT 'moyenne',
    
    -- Assignment
    assigne_a           UUID REFERENCES public.profiles(id),
    agent_responsable   UUID REFERENCES public.agents(id),
    
    -- Status
    statut              ticket_status DEFAULT 'ouvert',
    date_resolution     TIMESTAMPTZ,
    resolution_notes    TEXT,
    
    -- Attachments
    photos              TEXT[],
    documents           TEXT[],
    
    -- Satisfaction
    note_satisfaction   INTEGER CHECK (note_satisfaction BETWEEN 1 AND 5),
    commentaire_satisfaction TEXT,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tickets_createur ON public.tickets_support(createur_id);
CREATE INDEX idx_tickets_propriete ON public.tickets_support(propriete_id);
CREATE INDEX idx_tickets_statut ON public.tickets_support(statut);
CREATE INDEX idx_tickets_priorite ON public.tickets_support(priorite);

-- ============================================================
-- 10. TICKET_MESSAGES - Ticket Conversation
-- ============================================================
CREATE TABLE public.ticket_messages (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ticket_id           UUID REFERENCES public.tickets_support(id) ON DELETE CASCADE NOT NULL,
    auteur_id           UUID REFERENCES public.profiles(id) NOT NULL,
    
    message             TEXT NOT NULL,
    pieces_jointes      TEXT[],
    
    est_interne         BOOLEAN DEFAULT FALSE,  -- Internal note (only admin sees)
    est_lu              BOOLEAN DEFAULT FALSE,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ticket_msg_ticket ON public.ticket_messages(ticket_id);
CREATE INDEX idx_ticket_msg_auteur ON public.ticket_messages(auteur_id);

-- ============================================================
-- 11. DOCUMENTS - Document Management
-- ============================================================
CREATE TABLE public.documents (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Owner
    proprietaire_id     UUID REFERENCES public.proprietaires(id),
    locataire_id        UUID REFERENCES public.locataires(id),
    propriete_id        UUID REFERENCES public.proprietes(id),
    contrat_id          UUID REFERENCES public.contrats_location(id),
    
    -- Document Info
    nom                 TEXT NOT NULL,
    type_document       TEXT NOT NULL CHECK (type_document IN (
        'contrat', 'avenant', 'etat_lieux', 'quittance', 
        'facture', 'identite', 'attestation', 'autre'
    )),
    description         TEXT,
    fichier_url         TEXT NOT NULL,
    taille_octets       INTEGER,
    mime_type           TEXT,
    
    -- Access
    est_public          BOOLEAN DEFAULT FALSE,
    visible_proprietaire BOOLEAN DEFAULT TRUE,
    visible_locataire   BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    telecharge_par      UUID REFERENCES public.profiles(id),
    date_expiration     DATE,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_proprietaire ON public.documents(proprietaire_id);
CREATE INDEX idx_documents_locataire ON public.documents(locataire_id);
CREATE INDEX idx_documents_propriete ON public.documents(propriete_id);
CREATE INDEX idx_documents_contrat ON public.documents(contrat_id);

-- ============================================================
-- 12. VISITES - Property Visits Schedule
-- ============================================================
CREATE TABLE public.visites (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    propriete_id        UUID REFERENCES public.proprietes(id) NOT NULL,
    agent_id            UUID REFERENCES public.agents(id),
    
    -- Visitor Info
    visiteur_nom        TEXT NOT NULL,
    visiteur_email      TEXT NOT NULL,
    visiteur_telephone  TEXT NOT NULL,
    visiteur_type       TEXT DEFAULT 'prospect' CHECK (visiteur_type IN ('prospect', 'locataire_potentiel', 'acheteur_potentiel')),
    
    -- Schedule
    date_visite         DATE NOT NULL,
    heure_debut         TIME NOT NULL,
    heure_fin           TIME,
    
    -- Status
    statut              TEXT DEFAULT 'planifiee' CHECK (statut IN ('planifiee', 'confirmee', 'effectuee', 'annulee', 'no_show')),
    
    -- Feedback
    interesse           BOOLEAN,
    notes               TEXT,
    suite_prevue        TEXT,
    
    -- Notifications
    rappel_envoye       BOOLEAN DEFAULT FALSE,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_visites_propriete ON public.visites(propriete_id);
CREATE INDEX idx_visites_agent ON public.visites(agent_id);
CREATE INDEX idx_visites_date ON public.visites(date_visite);

-- ============================================================
-- 13. RAPPORTS_PROPRIETAIRE - Owner Reports
-- ============================================================
CREATE TABLE public.rapports_proprietaire (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    proprietaire_id     UUID REFERENCES public.proprietaires(id) NOT NULL,
    propriete_id        UUID REFERENCES public.proprietes(id),  -- NULL = all properties
    
    -- Period
    mois                INTEGER NOT NULL,
    annee               INTEGER NOT NULL,
    date_generation     TIMESTAMPTZ DEFAULT NOW(),
    
    -- Financial Summary
    loyers_percus       DECIMAL(12,2) DEFAULT 0,
    charges_percues     DECIMAL(10,2) DEFAULT 0,
    commission_exper    DECIMAL(10,2) DEFAULT 0,
    depenses_maintenance DECIMAL(10,2) DEFAULT 0,
    net_proprietaire    DECIMAL(12,2) DEFAULT 0,
    
    -- Stats
    taux_occupation     DECIMAL(5,2),
    nb_incidents        INTEGER DEFAULT 0,
    nb_visites          INTEGER DEFAULT 0,
    
    -- Report
    rapport_pdf_url     TEXT,
    envoye              BOOLEAN DEFAULT FALSE,
    date_envoi          TIMESTAMPTZ,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rapports_proprietaire ON public.rapports_proprietaire(proprietaire_id);
CREATE INDEX idx_rapports_periode ON public.rapports_proprietaire(annee, mois);

-- ============================================================
-- 14. TRANSACTIONS_FINANCIERES - Financial Ledger
-- ============================================================
CREATE TABLE public.transactions_financieres (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reference           TEXT UNIQUE NOT NULL,
    
    -- Type
    type_transaction    TEXT NOT NULL CHECK (type_transaction IN (
        'loyer_recu', 'commission_deduite', 'versement_proprietaire',
        'depot_garantie', 'remboursement_garantie', 'frais_maintenance',
        'frais_gestion', 'penalite', 'ajustement'
    )),
    
    -- Links
    proprietaire_id     UUID REFERENCES public.proprietaires(id),
    locataire_id        UUID REFERENCES public.locataires(id),
    propriete_id        UUID REFERENCES public.proprietes(id),
    paiement_id         UUID REFERENCES public.paiements(id),
    
    -- Amount
    montant             DECIMAL(12,2) NOT NULL,
    devise              TEXT DEFAULT 'USD',
    
    -- Details
    description         TEXT,
    date_transaction    DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Audit
    cree_par            UUID REFERENCES public.profiles(id),
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trans_proprietaire ON public.transactions_financieres(proprietaire_id);
CREATE INDEX idx_trans_locataire ON public.transactions_financieres(locataire_id);
CREATE INDEX idx_trans_date ON public.transactions_financieres(date_transaction);
CREATE INDEX idx_trans_type ON public.transactions_financieres(type_transaction);

-- ============================================================
-- 15. AUDIT_LOG - Security Audit Trail
-- ============================================================
CREATE TABLE public.audit_log (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    user_id             UUID REFERENCES public.profiles(id),
    user_role           user_role,
    
    action              TEXT NOT NULL,  -- 'create', 'update', 'delete', 'view', 'login', 'logout'
    table_name          TEXT,
    record_id           UUID,
    
    old_data            JSONB,
    new_data            JSONB,
    
    ip_address          INET,
    user_agent          TEXT,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON public.audit_log(user_id);
CREATE INDEX idx_audit_action ON public.audit_log(action);
CREATE INDEX idx_audit_table ON public.audit_log(table_name);
CREATE INDEX idx_audit_date ON public.audit_log(created_at);

-- ============================================================
-- 16. NOTIFICATIONS_SYSTEME - System Notifications
-- ============================================================
CREATE TABLE public.notifications_systeme (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    destinataire_id     UUID REFERENCES public.profiles(id) NOT NULL,
    
    type                TEXT NOT NULL CHECK (type IN (
        'paiement_recu', 'paiement_retard', 'nouveau_ticket',
        'ticket_resolu', 'contrat_expire_bientot', 'nouveau_rapport',
        'maintenance_planifiee', 'visite_planifiee', 'message_recu',
        'document_ajoute', 'rappel_echeance'
    )),
    
    titre               TEXT NOT NULL,
    message             TEXT NOT NULL,
    lien                TEXT,
    
    est_lu              BOOLEAN DEFAULT FALSE,
    date_lecture        TIMESTAMPTZ,
    
    -- Delivery
    envoye_email        BOOLEAN DEFAULT FALSE,
    envoye_sms          BOOLEAN DEFAULT FALSE,
    envoye_push         BOOLEAN DEFAULT FALSE,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notif_destinataire ON public.notifications_systeme(destinataire_id);
CREATE INDEX idx_notif_lu ON public.notifications_systeme(est_lu);
CREATE INDEX idx_notif_type ON public.notifications_systeme(type);

-- ============================================================
-- UPDATE EXISTING CONTACTS TABLE
-- ============================================================
ALTER TABLE public.contacts
ADD COLUMN IF NOT EXISTS locataire_id UUID REFERENCES public.locataires(id);

ALTER TABLE public.contacts
ADD COLUMN IF NOT EXISTS proprietaire_id UUID REFERENCES public.proprietaires(id);

ALTER TABLE public.contacts
ADD COLUMN IF NOT EXISTS traite BOOLEAN DEFAULT FALSE;

ALTER TABLE public.contacts
ADD COLUMN IF NOT EXISTS sujet TEXT;
