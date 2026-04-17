-- ============================================================
-- EXPERIMMO - 18_EXPERIMMO_COMPLETE_FIX.sql
-- Script CORRECTIF COMPLET - Exécuter après les scripts 01 → 17
-- Corrige : rôles manquants, tables CDC manquantes, RLS, triggers
-- Idempotent - peut être exécuté plusieurs fois sans erreur
-- ============================================================

-- ============================================================
-- 1. AJOUTER LES RÔLES MANQUANTS DANS L'ENUM user_role
--    (gestionnaire + assistante n'existaient pas dans SQL 15)
-- ============================================================
DO $$ BEGIN
    ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'gestionnaire';
EXCEPTION WHEN duplicate_object THEN NULL;
             WHEN others THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'assistante';
EXCEPTION WHEN duplicate_object THEN NULL;
             WHEN others THEN NULL;
END $$;

-- ============================================================
-- 2. TABLE GESTIONNAIRES (lien user ↔ portefeuille)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gestionnaires (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    matricule   TEXT UNIQUE,
    specialite  TEXT,
    zone_id     UUID REFERENCES public.zones(id),
    est_actif   BOOLEAN DEFAULT TRUE,
    notes_admin TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.gestionnaires ADD COLUMN IF NOT EXISTS matricule   TEXT;
ALTER TABLE public.gestionnaires ADD COLUMN IF NOT EXISTS specialite  TEXT;
ALTER TABLE public.gestionnaires ADD COLUMN IF NOT EXISTS zone_id     UUID;
ALTER TABLE public.gestionnaires ADD COLUMN IF NOT EXISTS est_actif   BOOLEAN DEFAULT TRUE;
ALTER TABLE public.gestionnaires ADD COLUMN IF NOT EXISTS notes_admin TEXT;
ALTER TABLE public.gestionnaires ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ DEFAULT NOW();

-- Ajouter colonne gestionnaire_id aux tables qui en ont besoin
ALTER TABLE public.proprietes         ADD COLUMN IF NOT EXISTS gestionnaire_id UUID REFERENCES public.gestionnaires(id);
ALTER TABLE public.proprietaires      ADD COLUMN IF NOT EXISTS gestionnaire_id UUID;
ALTER TABLE public.locataires         ADD COLUMN IF NOT EXISTS gestionnaire_id UUID;
ALTER TABLE public.contrats_location  ADD COLUMN IF NOT EXISTS gestionnaire_id UUID;

CREATE INDEX IF NOT EXISTS idx_gestionnaires_user ON public.gestionnaires(user_id);

-- ============================================================
-- 3. TABLE OPERATIONS (CDC 6.6 - Rapports d'opération)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.operations (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code_operation      TEXT UNIQUE,
    serie               INTEGER DEFAULT 1,
    propriete_id        UUID REFERENCES public.proprietes(id),
    proprietaire_id     UUID REFERENCES public.proprietaires(id),
    locataire_id        UUID REFERENCES public.locataires(id),
    contrat_id          UUID REFERENCES public.contrats_location(id),
    date_operation      DATE NOT NULL DEFAULT CURRENT_DATE,
    type_operation      TEXT NOT NULL DEFAULT 'autre',
    reference_decision  TEXT,
    document_reference  TEXT,
    montant             DECIMAL(12,2) DEFAULT 0,
    remarques           TEXT,
    description         TEXT,
    statut_operation    TEXT DEFAULT 'brouillon'
                        CHECK (statut_operation IN ('brouillon','soumis','publie','archive')),
    publie_portail      BOOLEAN DEFAULT FALSE,
    auteur_saisie       UUID REFERENCES public.profiles(id),
    valide_par          UUID REFERENCES public.profiles(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS code_operation     TEXT;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS serie              INTEGER DEFAULT 1;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS reference_decision TEXT;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS document_reference TEXT;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS description        TEXT;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS publie_portail     BOOLEAN DEFAULT FALSE;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS valide_par         UUID;
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS updated_at         TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_operations_propriete    ON public.operations(propriete_id);
CREATE INDEX IF NOT EXISTS idx_operations_proprietaire ON public.operations(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_operations_statut       ON public.operations(statut_operation);
CREATE INDEX IF NOT EXISTS idx_operations_date         ON public.operations(date_operation);
CREATE INDEX IF NOT EXISTS idx_operations_publie       ON public.operations(publie_portail);

-- ============================================================
-- 4. TABLE FACTURES (CDC 6.7)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.factures (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code_facture        TEXT UNIQUE,
    serie               INTEGER DEFAULT 1,
    type_facture        TEXT NOT NULL DEFAULT 'loyer'
                        CHECK (type_facture IN ('loyer','eau','electricite','autre')),
    locataire_id        UUID REFERENCES public.locataires(id),
    propriete_id        UUID REFERENCES public.proprietes(id),
    contrat_id          UUID REFERENCES public.contrats_location(id),
    periode             TEXT,
    date_emission       DATE DEFAULT CURRENT_DATE,
    date_echeance       DATE,
    montant             DECIMAL(12,2) NOT NULL DEFAULT 0,
    statut_facture      TEXT DEFAULT 'en_attente'
                        CHECK (statut_facture IN ('en_attente','payee','en_retard','annulee')),
    document_facture    TEXT,
    justificatif_paiement TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS code_facture           TEXT;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS serie                  INTEGER DEFAULT 1;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS contrat_id             UUID;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS periode                TEXT;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS document_facture       TEXT;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS justificatif_paiement  TEXT;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS notes                  TEXT;
ALTER TABLE public.factures ADD COLUMN IF NOT EXISTS updated_at             TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_factures_locataire ON public.factures(locataire_id);
CREATE INDEX IF NOT EXISTS idx_factures_propriete ON public.factures(propriete_id);
CREATE INDEX IF NOT EXISTS idx_factures_statut    ON public.factures(statut_facture);
CREATE INDEX IF NOT EXISTS idx_factures_type      ON public.factures(type_facture);

-- ============================================================
-- 5. TABLE MESSAGES (CDC 6.8) - si non créée par SQL 17
-- ============================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id_message      UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    expediteur      UUID REFERENCES public.profiles(id),
    destinataire    UUID REFERENCES public.profiles(id),
    type_expediteur TEXT,
    type_destinataire TEXT,
    objet           TEXT,
    categorie       TEXT DEFAULT 'general',
    message         TEXT,
    piece_jointe    TEXT,
    statut_message  TEXT DEFAULT 'nouveau'
                    CHECK (statut_message IN ('nouveau','en_cours','repondu','clos','en_attente')),
    date_envoi      TIMESTAMPTZ DEFAULT NOW(),
    date_reponse    TIMESTAMPTZ,
    reponse         TEXT,
    lu_oui_non      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS categorie         TEXT DEFAULT 'general';
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS type_expediteur   TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS type_destinataire TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS piece_jointe      TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS date_reponse      TIMESTAMPTZ;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reponse           TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS lu_oui_non        BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_messages_expediteur   ON public.messages(expediteur);
CREATE INDEX IF NOT EXISTS idx_messages_destinataire ON public.messages(destinataire);
CREATE INDEX IF NOT EXISTS idx_messages_statut       ON public.messages(statut_message);

-- ============================================================
-- 6. TABLE AUDIT_LOG (Journal d'activité CDC 6.11)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.audit_log (
    id            UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    utilisateur   UUID REFERENCES public.profiles(id),
    action        TEXT NOT NULL,
    module        TEXT,
    reference     UUID,
    ancienne_valeur JSONB,
    nouvelle_valeur JSONB,
    adresse_ip    TEXT,
    horodatage    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS module          TEXT;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS reference       UUID;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS ancienne_valeur JSONB;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS nouvelle_valeur JSONB;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS adresse_ip      TEXT;

CREATE INDEX IF NOT EXISTS idx_audit_utilisateur ON public.audit_log(utilisateur);
CREATE INDEX IF NOT EXISTS idx_audit_module      ON public.audit_log(module);
CREATE INDEX IF NOT EXISTS idx_audit_horodatage  ON public.audit_log(horodatage);

-- ============================================================
-- 7. COLONNES MANQUANTES CDC DANS TABLES EXISTANTES
-- ============================================================

-- Profiles : dernière connexion
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ;

-- Proprietes : champs CDC 6.3
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS code_propriete   TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS serie             INTEGER DEFAULT 1;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS date_inscription  DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS type_bien         TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS dimension         TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS explication       TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS fichier_dossier   TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS reference_zone    TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS statut_bien       TEXT DEFAULT 'disponible';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS type_mandat       TEXT DEFAULT 'gestion';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS statut_mandat     TEXT DEFAULT 'actif';

-- Proprietaires : champs CDC 6.2
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS serie             INTEGER DEFAULT 1;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS code_proprietaire TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS date_inscription  DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS nif               TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS no_passeport      TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS cin               TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS contact_1_nom     TEXT;
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS contact_1_telephone TEXT;

-- Locataires : champs CDC 6.4
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS serie               INTEGER DEFAULT 1;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS code_locataire      TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS date_inscription     DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS nif                  TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS no_passeport         TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS cin                  TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_1_nom        TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_1_telephone  TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS pieces_justificatives TEXT;

-- Contrats : champs CDC 6.5 (ajoutés par SQL 17, on s'assure qu'ils existent)
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS serie               INTEGER DEFAULT 1;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS code_contrat        TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS date_signature      DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS objet_contrat       TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS description_espace  TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS montant_lettre      TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS montant_chiffre     DECIMAL(12,2);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS renouvellement      BOOLEAN DEFAULT FALSE;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS modalite_paiement   TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS versement_1         DECIMAL(12,2);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS date_versement_1    DATE;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS versement_2         DECIMAL(12,2);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS date_versement_2    DATE;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS versement_3         DECIMAL(12,2);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS date_versement_3    DATE;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS frais_cabinet       DECIMAL(12,2);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS recurrence_frais_cabinet TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS frais_courtier      DECIMAL(12,2);
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS recurrence_frais_courtier TEXT;
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS document_contrat    TEXT;

-- ============================================================
-- 8. FONCTIONS HELPER MANQUANTES
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_gestionnaire()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role::text = 'gestionnaire'
    );
$$;

CREATE OR REPLACE FUNCTION public.is_assistante()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role::text IN ('assistante', 'admin')
    );
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role::text IN ('admin', 'gestionnaire', 'assistante')
    );
$$;

CREATE OR REPLACE FUNCTION public.get_gestionnaire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id FROM public.gestionnaires WHERE user_id = auth.uid() LIMIT 1;
$$;

-- ============================================================
-- 9. TRIGGER UPDATED_AT POUR NOUVELLES TABLES
-- ============================================================
DROP TRIGGER IF EXISTS upd_gestionnaires ON public.gestionnaires;
DROP TRIGGER IF EXISTS upd_operations    ON public.operations;
DROP TRIGGER IF EXISTS upd_factures      ON public.factures;

CREATE TRIGGER upd_gestionnaires BEFORE UPDATE ON public.gestionnaires
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_operations BEFORE UPDATE ON public.operations
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_factures BEFORE UPDATE ON public.factures
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 10. AUTO-GÉNÉRATION DE CODES EXPERIMMO (CDC 21.5)
--     Format: 46077PR-1, 46077L-1, 46081C-1 etc.
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS experimmo_seq START 77;

CREATE OR REPLACE FUNCTION public.generate_experimmo_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    prefix    TEXT;
    seq_val   INTEGER;
    base      TEXT := '46';
BEGIN
    CASE TG_TABLE_NAME
        WHEN 'proprietaires'      THEN prefix := 'PR';
        WHEN 'locataires'         THEN prefix := 'L';
        WHEN 'proprietes'         THEN prefix := 'P';
        WHEN 'contrats_location'  THEN prefix := 'C';
        WHEN 'operations'         THEN prefix := 'OP';
        WHEN 'factures'           THEN prefix := 'F';
        ELSE prefix := 'GEN';
    END CASE;

    seq_val := NEXTVAL('experimmo_seq');

    -- Mettre à jour serie
    BEGIN NEW.serie := seq_val; EXCEPTION WHEN undefined_column THEN NULL; END;

    -- Générer le code selon le champ disponible
    CASE TG_TABLE_NAME
        WHEN 'proprietaires' THEN
            IF NEW.code_proprietaire IS NULL THEN
                NEW.code_proprietaire := base || LPAD(seq_val::TEXT, 3, '0') || prefix || '-1';
            END IF;
        WHEN 'locataires' THEN
            IF NEW.code_locataire IS NULL THEN
                NEW.code_locataire := base || LPAD(seq_val::TEXT, 3, '0') || prefix || '-1';
            END IF;
        WHEN 'proprietes' THEN
            IF NEW.code_propriete IS NULL THEN
                NEW.code_propriete := base || LPAD(seq_val::TEXT, 3, '0') || prefix || '-1';
            END IF;
        WHEN 'contrats_location' THEN
            IF NEW.code_contrat IS NULL THEN
                NEW.code_contrat := base || LPAD(seq_val::TEXT, 3, '0') || prefix || '-1';
            END IF;
        WHEN 'operations' THEN
            IF NEW.code_operation IS NULL THEN
                NEW.code_operation := base || LPAD(seq_val::TEXT, 3, '0') || prefix || '-1';
            END IF;
        WHEN 'factures' THEN
            IF NEW.code_facture IS NULL THEN
                NEW.code_facture := base || LPAD(seq_val::TEXT, 3, '0') || prefix || '-1';
            END IF;
        ELSE NULL;
    END CASE;

    RETURN NEW;
END;
$$;

-- Attacher les triggers
DROP TRIGGER IF EXISTS trg_code_proprietaires     ON public.proprietaires;
DROP TRIGGER IF EXISTS trg_code_locataires        ON public.locataires;
DROP TRIGGER IF EXISTS trg_code_proprietes        ON public.proprietes;
DROP TRIGGER IF EXISTS trg_code_contrats_location ON public.contrats_location;
DROP TRIGGER IF EXISTS trg_code_operations        ON public.operations;
DROP TRIGGER IF EXISTS trg_code_factures          ON public.factures;

CREATE TRIGGER trg_code_proprietaires     BEFORE INSERT ON public.proprietaires
    FOR EACH ROW EXECUTE FUNCTION public.generate_experimmo_code();
CREATE TRIGGER trg_code_locataires        BEFORE INSERT ON public.locataires
    FOR EACH ROW EXECUTE FUNCTION public.generate_experimmo_code();
CREATE TRIGGER trg_code_proprietes        BEFORE INSERT ON public.proprietes
    FOR EACH ROW EXECUTE FUNCTION public.generate_experimmo_code();
CREATE TRIGGER trg_code_contrats_location BEFORE INSERT ON public.contrats_location
    FOR EACH ROW EXECUTE FUNCTION public.generate_experimmo_code();
CREATE TRIGGER trg_code_operations        BEFORE INSERT ON public.operations
    FOR EACH ROW EXECUTE FUNCTION public.generate_experimmo_code();
CREATE TRIGGER trg_code_factures          BEFORE INSERT ON public.factures
    FOR EACH ROW EXECUTE FUNCTION public.generate_experimmo_code();

-- ============================================================
-- 11. TRIGGER HANDLE_NEW_USER - VERSION ÉTENDUE
--     Gère maintenant gestionnaire + assistante
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_role user_role;
BEGIN
    -- Lire le rôle depuis les métadonnées, défaut 'locataire'
    BEGIN
        v_role := COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'locataire');
    EXCEPTION WHEN invalid_text_representation THEN
        v_role := 'locataire';
    END;

    -- Créer/mettre à jour le profil
    INSERT INTO public.profiles (id, email, full_name, phone, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email,'@',1)),
        NEW.raw_user_meta_data->>'phone',
        v_role
    )
    ON CONFLICT (id) DO UPDATE SET
        email      = EXCLUDED.email,
        full_name  = COALESCE(EXCLUDED.full_name, profiles.full_name),
        updated_at = NOW();

    -- Créer la fiche métier selon le rôle
    CASE v_role::text
        WHEN 'proprietaire' THEN
            INSERT INTO public.proprietaires (user_id)
            VALUES (NEW.id)
            ON CONFLICT (user_id) DO NOTHING;
        WHEN 'locataire' THEN
            INSERT INTO public.locataires (user_id)
            VALUES (NEW.id)
            ON CONFLICT (user_id) DO NOTHING;
        WHEN 'gestionnaire' THEN
            INSERT INTO public.gestionnaires (user_id)
            VALUES (NEW.id)
            ON CONFLICT (user_id) DO NOTHING;
        ELSE NULL;
    END CASE;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 12. FONCTION : Mettre à jour derniere_connexion
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_derniere_connexion(p_user_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.profiles
    SET derniere_connexion = NOW(), updated_at = NOW()
    WHERE id = p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_derniere_connexion(UUID) TO authenticated;

-- ============================================================
-- 13. ACTIVER RLS SUR NOUVELLES TABLES
-- ============================================================
ALTER TABLE public.gestionnaires  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.factures       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log      ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 14. NETTOYAGE POLITIQUES DUPLIQUÉES (nouvelles tables)
-- ============================================================
DROP POLICY IF EXISTS "gestionnaires_select" ON public.gestionnaires;
DROP POLICY IF EXISTS "gestionnaires_update" ON public.gestionnaires;
DROP POLICY IF EXISTS "gestionnaires_insert" ON public.gestionnaires;
DROP POLICY IF EXISTS "gestionnaires_delete" ON public.gestionnaires;
DROP POLICY IF EXISTS "operations_select"    ON public.operations;
DROP POLICY IF EXISTS "operations_write"     ON public.operations;
DROP POLICY IF EXISTS "operations_insert"    ON public.operations;
DROP POLICY IF EXISTS "factures_select"      ON public.factures;
DROP POLICY IF EXISTS "factures_write"       ON public.factures;
DROP POLICY IF EXISTS "messages_select"      ON public.messages;
DROP POLICY IF EXISTS "messages_insert"      ON public.messages;
DROP POLICY IF EXISTS "messages_update"      ON public.messages;
DROP POLICY IF EXISTS "messages_delete"      ON public.messages;
DROP POLICY IF EXISTS "audit_select"         ON public.audit_log;
DROP POLICY IF EXISTS "audit_insert"         ON public.audit_log;

-- ============================================================
-- 15. POLITIQUES RLS POUR LES NOUVELLES TABLES
-- ============================================================

-- GESTIONNAIRES
CREATE POLICY "gestionnaires_select" ON public.gestionnaires
    FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "gestionnaires_update" ON public.gestionnaires
    FOR UPDATE USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "gestionnaires_insert" ON public.gestionnaires
    FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "gestionnaires_delete" ON public.gestionnaires
    FOR DELETE USING (public.is_admin());

-- OPERATIONS : lecture par propriétaires de leurs biens, gestionnaires, admin
CREATE POLICY "operations_select" ON public.operations
    FOR SELECT USING (
        public.is_admin()
        OR public.is_staff()
        OR auteur_saisie = auth.uid()
        OR (publie_portail = TRUE AND propriete_id IN (
            SELECT p.id FROM public.proprietes p
            JOIN public.proprietaires pr ON pr.id = p.proprietaire_id
            WHERE pr.user_id = auth.uid()
        ))
        OR (publie_portail = TRUE AND locataire_id IN (
            SELECT id FROM public.locataires WHERE user_id = auth.uid()
        ))
    );
CREATE POLICY "operations_insert" ON public.operations
    FOR INSERT WITH CHECK (
        public.is_admin() OR public.is_gestionnaire() OR public.is_assistante()
    );
CREATE POLICY "operations_write" ON public.operations
    FOR ALL USING (public.is_admin() OR public.is_assistante());

-- FACTURES : locataires voient les leurs, admin voit tout
CREATE POLICY "factures_select" ON public.factures
    FOR SELECT USING (
        public.is_admin()
        OR public.is_staff()
        OR locataire_id IN (SELECT id FROM public.locataires WHERE user_id = auth.uid())
        OR propriete_id IN (
            SELECT p.id FROM public.proprietes p
            JOIN public.proprietaires pr ON pr.id = p.proprietaire_id
            WHERE pr.user_id = auth.uid()
        )
    );
CREATE POLICY "factures_write" ON public.factures
    FOR ALL USING (public.is_admin() OR public.is_assistante());

-- MESSAGES : l'expéditeur et le destinataire peuvent lire, staff aussi
CREATE POLICY "messages_select" ON public.messages
    FOR SELECT USING (
        expediteur = auth.uid()
        OR destinataire = auth.uid()
        OR public.is_staff()
    );
CREATE POLICY "messages_insert" ON public.messages
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
        AND (expediteur = auth.uid() OR public.is_staff())
    );
CREATE POLICY "messages_update" ON public.messages
    FOR UPDATE USING (
        destinataire = auth.uid() OR public.is_staff()
    );
CREATE POLICY "messages_delete" ON public.messages
    FOR DELETE USING (public.is_admin());

-- AUDIT_LOG : admin lit tout, authenticated peut insérer
CREATE POLICY "audit_select" ON public.audit_log
    FOR SELECT USING (public.is_admin());
CREATE POLICY "audit_insert" ON public.audit_log
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- 16. CORRECTION RLS POUR GESTIONNAIRE SUR TABLES EXISTANTES
-- ============================================================

-- Propriétaires : gestionnaire peut voir ses clients
DROP POLICY IF EXISTS "proprietaires_gestionnaire" ON public.proprietaires;
CREATE POLICY "proprietaires_gestionnaire" ON public.proprietaires
    FOR SELECT USING (
        user_id = auth.uid()
        OR public.is_admin()
        OR gestionnaire_id IN (SELECT id FROM public.gestionnaires WHERE user_id = auth.uid())
    );

-- Locataires : gestionnaire peut voir ses locataires
DROP POLICY IF EXISTS "locataires_gestionnaire" ON public.locataires;
CREATE POLICY "locataires_gestionnaire" ON public.locataires
    FOR SELECT USING (
        user_id = auth.uid()
        OR public.is_admin()
        OR gestionnaire_id IN (SELECT id FROM public.gestionnaires WHERE user_id = auth.uid())
    );

-- Contrats : gestionnaire peut voir les contrats de son portefeuille
DROP POLICY IF EXISTS "contrats_gestionnaire" ON public.contrats_location;
CREATE POLICY "contrats_gestionnaire" ON public.contrats_location
    FOR SELECT USING (
        public.is_admin()
        OR public.is_assistante()
        OR gestionnaire_id IN (SELECT id FROM public.gestionnaires WHERE user_id = auth.uid())
        OR locataire_id IN (SELECT id FROM public.locataires WHERE user_id = auth.uid())
        OR proprietaire_id IN (SELECT id FROM public.proprietaires WHERE user_id = auth.uid())
    );

-- Paiements : propriétaire peut voir ses loyers
DROP POLICY IF EXISTS "paiements_proprietaire" ON public.paiements;
CREATE POLICY "paiements_proprietaire" ON public.paiements
    FOR SELECT USING (
        public.is_admin()
        OR public.is_assistante()
        OR locataire_id IN (SELECT id FROM public.locataires WHERE user_id = auth.uid())
        OR propriete_id IN (
            SELECT p.id FROM public.proprietes p
            JOIN public.proprietaires pr ON pr.id = p.proprietaire_id
            WHERE pr.user_id = auth.uid()
        )
    );

-- ============================================================
-- 17. GRANTS POUR NOUVELLES FONCTIONS
-- ============================================================
GRANT EXECUTE ON FUNCTION public.is_gestionnaire()       TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_assistante()         TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff()              TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_gestionnaire_id()   TO authenticated;

-- ============================================================
-- 18. STORAGE BUCKET pour documents et pièces jointes
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'documents',
    'documents',
    FALSE,
    52428800,
    ARRAY['application/pdf','image/jpeg','image/png','image/webp',
          'application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
ON CONFLICT (id) DO UPDATE SET file_size_limit = 52428800;

INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('operations-docs','operations-docs',FALSE,20971520)
ON CONFLICT (id) DO NOTHING;

-- Policies storage documents
DROP POLICY IF EXISTS "Documents authenticated access"  ON storage.objects;
DROP POLICY IF EXISTS "Documents admin full access"     ON storage.objects;
DROP POLICY IF EXISTS "Documents staff upload"          ON storage.objects;

CREATE POLICY "Documents authenticated access" ON storage.objects
    FOR SELECT USING (bucket_id = 'documents' AND auth.role() = 'authenticated');

CREATE POLICY "Documents staff upload" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id IN ('documents','operations-docs')
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Documents admin full access" ON storage.objects
    FOR ALL USING (
        bucket_id IN ('documents','operations-docs')
        AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role::text = 'admin')
    );

-- ============================================================
-- 19. DONNÉES DE BASE NÉCESSAIRES (seed minimal)
-- ============================================================

-- Zones géographiques d'Haïti
INSERT INTO public.zones (nom, slug, ville, actif, ordre) VALUES
    ('Pétion-Ville',      'petion-ville',      'Port-au-Prince', TRUE, 1),
    ('Delmas',            'delmas',             'Port-au-Prince', TRUE, 2),
    ('Tabarre',           'tabarre',            'Port-au-Prince', TRUE, 3),
    ('Croix-des-Bouquets','croix-des-bouquets', 'Port-au-Prince', TRUE, 4),
    ('Kenscoff',          'kenscoff',           'Port-au-Prince', TRUE, 5),
    ('Morne-à-Cabri',     'morne-a-cabri',      'Port-au-Prince', TRUE, 6),
    ('Jacmel',            'jacmel',             'Jacmel',         TRUE, 7),
    ('Cap-Haïtien',       'cap-haitien',        'Cap-Haïtien',    TRUE, 8),
    ('Léogâne',           'leogane',            'Léogâne',        TRUE, 9),
    ('Gonaïves',          'gonaives',           'Gonaïves',       TRUE, 10)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- 20. RECHARGER LE CACHE POSTGREST
-- ============================================================
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- 21. VÉRIFICATION FINALE
-- ============================================================
DO $$
DECLARE
    tables_ok TEXT := '';
    t         TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'profiles','proprietaires','locataires','gestionnaires',
        'proprietes','contrats_location','paiements','operations',
        'factures','messages','documents','tickets_support',
        'notifications_systeme','audit_log','agents','zones','contacts'
    ] LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = t
        ) THEN
            tables_ok := tables_ok || '✓ ' || t || E'\n';
        ELSE
            RAISE WARNING 'TABLE MANQUANTE : %', t;
        END IF;
    END LOOP;
    RAISE NOTICE E'=== TABLES VÉRIFIÉES ===\n%', tables_ok;
END $$;

SELECT
    tablename,
    policyname,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
