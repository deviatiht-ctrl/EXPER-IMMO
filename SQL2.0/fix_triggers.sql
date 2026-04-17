-- ============================================================
-- EXPERIMMO — FIX TRIGGERS v1
-- Correction de TOUTES les fonctions cassées après renommages
-- (MASTER_FIX_TOTAL : contrats_location→contrats, id→id_*)
-- Idempotent — sûr à re-exécuter
-- ============================================================

-- 0. Colonnes manquantes + renames PK (idempotent — même logique que seed step 0.5)
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS serie INTEGER, ADD COLUMN IF NOT EXISTS code_proprietaire TEXT;
ALTER TABLE public.locataires    ADD COLUMN IF NOT EXISTS serie INTEGER, ADD COLUMN IF NOT EXISTS code_locataire   TEXT;
ALTER TABLE public.proprietes    ADD COLUMN IF NOT EXISTS serie INTEGER, ADD COLUMN IF NOT EXISTS code_propriete   TEXT;
ALTER TABLE public.factures   ADD COLUMN IF NOT EXISTS type_facture    TEXT,
                              ADD COLUMN IF NOT EXISTS id_locataire   UUID,
                              ADD COLUMN IF NOT EXISTS id_propriete   UUID,
                              ADD COLUMN IF NOT EXISTS periode        TEXT,
                              ADD COLUMN IF NOT EXISTS date_emission  DATE DEFAULT CURRENT_DATE,
                              ADD COLUMN IF NOT EXISTS date_echeance  DATE,
                              ADD COLUMN IF NOT EXISTS montant        DECIMAL(12,2),
                              ADD COLUMN IF NOT EXISTS statut_facture TEXT DEFAULT 'impaye';
ALTER TABLE public.operations ADD COLUMN IF NOT EXISTS type_operation  TEXT,
                              ADD COLUMN IF NOT EXISTS id_propriete    UUID,
                              ADD COLUMN IF NOT EXISTS id_proprietaire UUID,
                              ADD COLUMN IF NOT EXISTS montant         DECIMAL(12,2) DEFAULT 0,
                              ADD COLUMN IF NOT EXISTS date_operation  DATE DEFAULT CURRENT_DATE,
                              ADD COLUMN IF NOT EXISTS statut_operation TEXT DEFAULT 'brouillon',
                              ADD COLUMN IF NOT EXISTS remarques       TEXT;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietes'    AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietes'    AND column_name='id_propriete')   THEN ALTER TABLE public.proprietes    RENAME COLUMN id TO id_propriete;   END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietaires' AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietaires' AND column_name='id_proprietaire') THEN ALTER TABLE public.proprietaires RENAME COLUMN id TO id_proprietaire; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='locataires'    AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='locataires'    AND column_name='id_locataire')   THEN ALTER TABLE public.locataires    RENAME COLUMN id TO id_locataire;   END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contrats'      AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contrats'      AND column_name='id_contrat')     THEN ALTER TABLE public.contrats      RENAME COLUMN id TO id_contrat;     END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='paiements'     AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='paiements'     AND column_name='id_paiement')    THEN ALTER TABLE public.paiements     RENAME COLUMN id TO id_paiement;    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='factures'      AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='factures'      AND column_name='id_facture')     THEN ALTER TABLE public.factures      RENAME COLUMN id TO id_facture;     END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='operations'    AND column_name='id') AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='operations'    AND column_name='id_operation')   THEN ALTER TABLE public.operations    RENAME COLUMN id TO id_operation;   END IF;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 1. get_proprietaire_id()
CREATE OR REPLACE FUNCTION public.get_proprietaire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id_proprietaire FROM public.proprietaires WHERE user_id = auth.uid();
$$;

-- 2. get_locataire_id()
CREATE OR REPLACE FUNCTION public.get_locataire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id_locataire FROM public.locataires WHERE user_id = auth.uid();
$$;

-- 3. log_audit() v1 — COALESCE(NEW.id) cassé + anciens noms audit_log
CREATE OR REPLACE FUNCTION public.log_audit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_role      user_role;
    v_row       JSONB;
    v_record_id UUID;
BEGIN
    v_row := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
    v_record_id := CASE TG_TABLE_NAME
        WHEN 'contrats'      THEN (v_row->>'id_contrat')::UUID
        WHEN 'proprietes'    THEN (v_row->>'id_propriete')::UUID
        WHEN 'proprietaires' THEN (v_row->>'id_proprietaire')::UUID
        WHEN 'locataires'    THEN (v_row->>'id_locataire')::UUID
        WHEN 'paiements'     THEN (v_row->>'id_paiement')::UUID
        WHEN 'factures'      THEN (v_row->>'id_facture')::UUID
        WHEN 'operations'    THEN (v_row->>'id_operation')::UUID
        ELSE (v_row->>'id')::UUID
    END;
    SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
    INSERT INTO public.audit_log (utilisateur, user_role, action, table_name, record_id, ancienne_valeur, nouvelle_valeur, horodatage)
    VALUES (auth.uid(), v_role, TG_OP, TG_TABLE_NAME, v_record_id,
        CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
        NOW());
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN RETURN COALESCE(NEW, OLD);
END; $$;

-- 4. log_audit_v3() — idem
CREATE OR REPLACE FUNCTION public.log_audit_v3()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_row       JSONB;
    v_record_id UUID;
BEGIN
    v_row := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
    v_record_id := CASE TG_TABLE_NAME
        WHEN 'contrats'      THEN (v_row->>'id_contrat')::UUID
        WHEN 'proprietes'    THEN (v_row->>'id_propriete')::UUID
        WHEN 'proprietaires' THEN (v_row->>'id_proprietaire')::UUID
        WHEN 'locataires'    THEN (v_row->>'id_locataire')::UUID
        WHEN 'paiements'     THEN (v_row->>'id_paiement')::UUID
        WHEN 'factures'      THEN (v_row->>'id_facture')::UUID
        WHEN 'operations'    THEN (v_row->>'id_operation')::UUID
        ELSE (v_row->>'id')::UUID
    END;
    INSERT INTO public.audit_log (utilisateur, user_role, action, table_name, record_id, ancienne_valeur, nouvelle_valeur, horodatage)
    VALUES (auth.uid(),
        (SELECT role FROM public.profiles WHERE id = auth.uid()),
        TG_OP, TG_TABLE_NAME, v_record_id,
        CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
        NOW());
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN RETURN COALESCE(NEW, OLD);
END; $$;

-- 5. update_proprietaire_stats() — WHERE id→id_proprietaire, prix_location→prix_loyer
CREATE OR REPLACE FUNCTION public.update_proprietaire_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.proprietaires SET
        nb_proprietes = (
            SELECT COUNT(*) FROM public.proprietes
            WHERE proprietaire_id = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id)
        ),
        revenu_total = (
            SELECT COALESCE(SUM(prix_loyer), 0) FROM public.proprietes
            WHERE proprietaire_id = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id)
            AND statut = 'loue'
        ),
        updated_at = NOW()
    WHERE id_proprietaire = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id);
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN RETURN COALESCE(NEW, OLD);
END; $$;

-- 6. notifier_paiement() — contrats_location→contrats, .id→id_locataire/id_proprietaire/id_contrat
CREATE OR REPLACE FUNCTION public.notifier_paiement()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_locataire_user_id    UUID;
    v_proprietaire_user_id UUID;
BEGIN
    SELECT user_id INTO v_locataire_user_id
    FROM public.locataires WHERE id_locataire = NEW.locataire_id;

    SELECT p.user_id INTO v_proprietaire_user_id
    FROM public.proprietaires p
    JOIN public.contrats c ON c.proprietaire_id = p.id_proprietaire
    WHERE c.id_contrat = NEW.contrat_id;

    IF NEW.statut = 'paye' AND v_locataire_user_id IS NOT NULL THEN
        INSERT INTO public.notifications_systeme (destinataire_id, type, titre, message, lien)
        VALUES (v_locataire_user_id, 'paiement_recu', 'Paiement confirmé',
            'Votre paiement de '||NEW.montant_paye||' '||NEW.devise||' a été reçu.',
            '/locataire/paiements');
    END IF;
    IF NEW.statut = 'paye' AND v_proprietaire_user_id IS NOT NULL THEN
        INSERT INTO public.notifications_systeme (destinataire_id, type, titre, message, lien)
        VALUES (v_proprietaire_user_id, 'paiement_recu', 'Loyer reçu',
            'Un paiement de '||NEW.montant_paye||' '||NEW.devise||' a été reçu.',
            '/proprietaire/paiements');
    END IF;
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW;
END; $$;

-- 7. check_paiements_retard() — l.id→l.id_locataire
CREATE OR REPLACE FUNCTION public.check_paiements_retard()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.paiements
    SET statut = 'en_retard', jours_retard = CURRENT_DATE - date_echeance
    WHERE statut IN ('en_attente','partiel') AND date_echeance < CURRENT_DATE;

    INSERT INTO public.notifications_systeme (destinataire_id, type, titre, message, lien)
    SELECT DISTINCT l.user_id, 'paiement_retard', 'Paiement en retard',
        'Vous avez un paiement en retard. Veuillez régulariser.','/locataire/paiements'
    FROM public.paiements p
    JOIN public.locataires l ON l.id_locataire = p.locataire_id
    WHERE p.statut = 'en_retard' AND p.updated_at > NOW() - INTERVAL '1 hour';
EXCEPTION WHEN OTHERS THEN NULL;
END; $$;

-- 8. get_admin_dashboard_stats() — contrats_location→contrats
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'total_proprietes',       (SELECT COUNT(*) FROM public.proprietes WHERE est_actif=TRUE),
        'proprietes_disponibles', (SELECT COUNT(*) FROM public.proprietes WHERE statut='disponible' AND est_actif=TRUE),
        'proprietes_louees',      (SELECT COUNT(*) FROM public.proprietes WHERE statut='loue'),
        'total_proprietaires',    (SELECT COUNT(*) FROM public.proprietaires WHERE est_actif=TRUE),
        'total_locataires',       (SELECT COUNT(*) FROM public.locataires WHERE est_actif=TRUE),
        'total_agents',           (SELECT COUNT(*) FROM public.agents WHERE actif=TRUE),
        'contrats_actifs',        (SELECT COUNT(*) FROM public.contrats WHERE statut='actif'),
        'contrats_expire_bientot',(SELECT COUNT(*) FROM public.contrats WHERE statut='actif' AND date_fin<=CURRENT_DATE+INTERVAL'30 days'),
        'paiements_en_attente',   (SELECT COUNT(*) FROM public.paiements WHERE statut='en_attente'),
        'paiements_en_retard',    (SELECT COUNT(*) FROM public.paiements WHERE statut='en_retard'),
        'revenus_ce_mois',        (SELECT COALESCE(SUM(montant_paye),0) FROM public.paiements WHERE statut='paye' AND DATE_TRUNC('month',date_paiement)=DATE_TRUNC('month',CURRENT_DATE)),
        'tickets_ouverts',        (SELECT COUNT(*) FROM public.tickets_support WHERE statut IN ('ouvert','en_cours')),
        'nouveaux_contacts',      (SELECT COUNT(*) FROM public.contacts WHERE statut='nouveau')
    ) INTO result;
    RETURN result;
EXCEPTION WHEN OTHERS THEN RETURN '{}';
END; $$;

-- 9. get_proprietaire_dashboard() — contrats_location→contrats, c.id→id_contrat
CREATE OR REPLACE FUNCTION public.get_proprietaire_dashboard(p_proprietaire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'mes_proprietes',       (SELECT COUNT(*) FROM public.proprietes WHERE proprietaire_id=p_proprietaire_id AND est_actif=TRUE),
        'proprietes_louees',    (SELECT COUNT(*) FROM public.proprietes WHERE proprietaire_id=p_proprietaire_id AND statut='loue'),
        'proprietes_disponibles',(SELECT COUNT(*) FROM public.proprietes WHERE proprietaire_id=p_proprietaire_id AND statut='disponible'),
        'revenus_ce_mois',      (SELECT COALESCE(SUM(p.montant_paye),0) FROM public.paiements p JOIN public.contrats c ON c.id_contrat=p.contrat_id WHERE c.proprietaire_id=p_proprietaire_id AND p.statut='paye' AND DATE_TRUNC('month',p.date_paiement)=DATE_TRUNC('month',CURRENT_DATE)),
        'paiements_en_attente', (SELECT COUNT(*) FROM public.paiements p JOIN public.contrats c ON c.id_contrat=p.contrat_id WHERE c.proprietaire_id=p_proprietaire_id AND p.statut IN ('en_attente','en_retard')),
        'contrats_actifs',      (SELECT COUNT(*) FROM public.contrats WHERE proprietaire_id=p_proprietaire_id AND statut='actif'),
        'taux_occupation',      (SELECT CASE WHEN COUNT(*)>0 THEN ROUND(COUNT(*) FILTER (WHERE statut='loue')::NUMERIC/COUNT(*)*100,1) ELSE 0 END FROM public.proprietes WHERE proprietaire_id=p_proprietaire_id AND est_actif=TRUE)
    ) INTO result;
    RETURN result;
EXCEPTION WHEN OTHERS THEN RETURN '{}';
END; $$;

-- 10. get_locataire_dashboard() — contrats_location→contrats, c.id→id_contrat, pr.id→id_propriete
CREATE OR REPLACE FUNCTION public.get_locataire_dashboard(p_locataire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'contrat_actif', (SELECT json_build_object(
            'id', c.id_contrat, 'reference', c.reference,
            'propriete_titre', pr.titre, 'propriete_adresse', pr.adresse,
            'loyer_mensuel', c.loyer_mensuel, 'date_fin', c.date_fin,
            'jours_restants', c.date_fin - CURRENT_DATE
        ) FROM public.contrats c
        JOIN public.proprietes pr ON pr.id_propriete = c.propriete_id
        WHERE c.locataire_id = p_locataire_id AND c.statut = 'actif' LIMIT 1),
        'prochain_paiement', (SELECT json_build_object('montant',montant_total,'date_echeance',date_echeance,'jours_avant',date_echeance-CURRENT_DATE)
            FROM public.paiements WHERE locataire_id=p_locataire_id AND statut='en_attente' ORDER BY date_echeance LIMIT 1),
        'solde_du',         (SELECT COALESCE(SUM(solde_restant),0) FROM public.paiements WHERE locataire_id=p_locataire_id AND statut IN ('en_attente','en_retard','partiel')),
        'paiements_retard', (SELECT COUNT(*) FROM public.paiements WHERE locataire_id=p_locataire_id AND statut='en_retard'),
        'score_paiement',   (SELECT score_paiement FROM public.locataires WHERE id_locataire=p_locataire_id)
    ) INTO result;
    RETURN result;
EXCEPTION WHEN OTHERS THEN RETURN '{}';
END; $$;

-- 11. generer_paiements_mensuels() — contrats_location→contrats, v_contrat.id→id_contrat
CREATE OR REPLACE FUNCTION public.generer_paiements_mensuels()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_contrat    RECORD;
    v_next_month DATE;
BEGIN
    v_next_month := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';
    FOR v_contrat IN SELECT * FROM public.contrats WHERE statut = 'actif' AND date_fin >= v_next_month
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM public.paiements
            WHERE contrat_id = v_contrat.id_contrat
            AND annee = EXTRACT(YEAR FROM v_next_month)
            AND mois  = EXTRACT(MONTH FROM v_next_month)
        ) THEN
            INSERT INTO public.paiements (contrat_id, locataire_id, propriete_id,
                mois, annee, periode_debut, periode_fin, montant_loyer, montant_charges,
                montant_total, date_echeance, devise)
            VALUES (
                v_contrat.id_contrat, v_contrat.locataire_id, v_contrat.propriete_id,
                EXTRACT(MONTH FROM v_next_month), EXTRACT(YEAR FROM v_next_month),
                v_next_month, (v_next_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
                v_contrat.loyer_mensuel, v_contrat.charges_mensuelles,
                v_contrat.loyer_mensuel + COALESCE(v_contrat.charges_mensuelles, 0),
                (v_next_month + (v_contrat.jour_paiement - 1) * INTERVAL '1 day')::DATE,
                v_contrat.devise
            );
        END IF;
    END LOOP;
EXCEPTION WHEN OTHERS THEN NULL;
END; $$;

-- 12. Re-attacher les triggers à la table renommée 'contrats'
DO $$ BEGIN DROP TRIGGER IF EXISTS calc_duree_contrat    ON public.contrats_location; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DROP TRIGGER IF EXISTS calc_duree_contrat    ON public.contrats;
CREATE TRIGGER calc_duree_contrat
    BEFORE INSERT OR UPDATE ON public.contrats
    FOR EACH ROW EXECUTE FUNCTION public.calc_duree_mois();

DO $$ BEGIN DROP TRIGGER IF EXISTS set_reference_contrat ON public.contrats_location; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DROP TRIGGER IF EXISTS set_reference_contrat ON public.contrats;
CREATE TRIGGER set_reference_contrat
    BEFORE INSERT ON public.contrats
    FOR EACH ROW EXECUTE FUNCTION public.generer_reference_contrat();

DO $$ BEGIN DROP TRIGGER IF EXISTS audit_contrats        ON public.contrats_location; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DROP TRIGGER IF EXISTS audit_contrats        ON public.contrats;
CREATE TRIGGER audit_contrats
    AFTER INSERT OR UPDATE OR DELETE ON public.contrats
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();

SELECT 'fix_triggers.sql appliqué ✓' AS status;
