-- ============================================================
-- EXPER IMMO - FUNCTIONS & TRIGGERS
-- For Multi-tenant Real Estate Management
-- ============================================================

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;

-- Check if user is proprietaire
CREATE OR REPLACE FUNCTION public.is_proprietaire()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'proprietaire'
    );
$$;

-- Check if user is locataire
CREATE OR REPLACE FUNCTION public.is_locataire()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'locataire'
    );
$$;

-- Get current user's proprietaire_id
CREATE OR REPLACE FUNCTION public.get_proprietaire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id FROM public.proprietaires WHERE user_id = auth.uid();
$$;

-- Get current user's locataire_id
CREATE OR REPLACE FUNCTION public.get_locataire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id FROM public.locataires WHERE user_id = auth.uid();
$$;

-- Get user role
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- PROFILE CREATION ON SIGNUP
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_role user_role;
BEGIN
    -- Default role from metadata or 'locataire'
    v_role := COALESCE(
        (NEW.raw_user_meta_data->>'role')::user_role,
        'locataire'
    );
    
    -- Insert profile
    INSERT INTO public.profiles (
        id, 
        email, 
        full_name, 
        phone,
        role
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        NEW.raw_user_meta_data->>'phone',
        v_role
    );
    
    -- Create role-specific record
    IF v_role = 'proprietaire' THEN
        INSERT INTO public.proprietaires (user_id)
        VALUES (NEW.id);
    ELSIF v_role = 'locataire' THEN
        INSERT INTO public.locataires (user_id)
        VALUES (NEW.id);
    END IF;
    
    RETURN NEW;
EXCEPTION WHEN unique_violation THEN 
    RETURN NEW;
END; $$;

-- Trigger for new user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- REFERENCE GENERATORS
-- ============================================================

-- Contract reference generator
CREATE SEQUENCE IF NOT EXISTS contrat_seq START 1;
CREATE OR REPLACE FUNCTION public.generer_reference_contrat()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'CTR-' || TO_CHAR(NOW(),'YYYY') || '-' ||
                         LPAD(NEXTVAL('contrat_seq')::TEXT, 5, '0');
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER set_reference_contrat
    BEFORE INSERT ON public.contrats_location
    FOR EACH ROW EXECUTE FUNCTION public.generer_reference_contrat();

-- Payment reference generator
CREATE SEQUENCE IF NOT EXISTS paiement_seq START 1;
CREATE OR REPLACE FUNCTION public.generer_reference_paiement()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'PAY-' || TO_CHAR(NOW(),'YYMM') || '-' ||
                         LPAD(NEXTVAL('paiement_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER set_reference_paiement
    BEFORE INSERT ON public.paiements
    FOR EACH ROW EXECUTE FUNCTION public.generer_reference_paiement();

-- Ticket reference generator
CREATE SEQUENCE IF NOT EXISTS ticket_seq START 1;
CREATE OR REPLACE FUNCTION public.generer_reference_ticket()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'TKT-' || TO_CHAR(NOW(),'YYMM') || '-' ||
                         LPAD(NEXTVAL('ticket_seq')::TEXT, 5, '0');
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER set_reference_ticket
    BEFORE INSERT ON public.tickets_support
    FOR EACH ROW EXECUTE FUNCTION public.generer_reference_ticket();

-- Transaction reference generator
CREATE SEQUENCE IF NOT EXISTS transaction_seq START 1;
CREATE OR REPLACE FUNCTION public.generer_reference_transaction()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'TRX-' || TO_CHAR(NOW(),'YYYYMMDD') || '-' ||
                         LPAD(NEXTVAL('transaction_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END; $$;

CREATE TRIGGER set_reference_transaction
    BEFORE INSERT ON public.transactions_financieres
    FOR EACH ROW EXECUTE FUNCTION public.generer_reference_transaction();

-- ============================================================
-- UPDATE TIMESTAMPS
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN 
    NEW.updated_at = NOW(); 
    RETURN NEW; 
END; $$;

CREATE TRIGGER upd_profiles BEFORE UPDATE ON public.profiles 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_proprietaires BEFORE UPDATE ON public.proprietaires 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_locataires BEFORE UPDATE ON public.locataires 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_contrats BEFORE UPDATE ON public.contrats_location 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_paiements BEFORE UPDATE ON public.paiements 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_tickets BEFORE UPDATE ON public.tickets_support 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_visites BEFORE UPDATE ON public.visites 
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- CALCULATED FIELDS TRIGGERS
-- ============================================================

-- Calculate solde_restant for payments
CREATE OR REPLACE FUNCTION public.calc_solde_restant()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.solde_restant := NEW.montant_total - COALESCE(NEW.montant_paye, 0);
    RETURN NEW;
END; $$;

CREATE TRIGGER calc_solde_paiement
    BEFORE INSERT OR UPDATE ON public.paiements
    FOR EACH ROW EXECUTE FUNCTION public.calc_solde_restant();

-- Calculate duree_mois for contracts
CREATE OR REPLACE FUNCTION public.calc_duree_mois()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.duree_mois := (
        EXTRACT(YEAR FROM AGE(NEW.date_fin, NEW.date_debut)) * 12 +
        EXTRACT(MONTH FROM AGE(NEW.date_fin, NEW.date_debut))
    )::INTEGER;
    RETURN NEW;
END; $$;

CREATE TRIGGER calc_duree_contrat
    BEFORE INSERT OR UPDATE ON public.contrats_location
    FOR EACH ROW EXECUTE FUNCTION public.calc_duree_mois();

-- ============================================================
-- NOTIFICATION TRIGGERS
-- ============================================================

-- Notify on new payment
CREATE OR REPLACE FUNCTION public.notifier_paiement()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_locataire_user_id UUID;
    v_proprietaire_user_id UUID;
BEGIN
    -- Get user IDs
    SELECT user_id INTO v_locataire_user_id 
    FROM public.locataires WHERE id = NEW.locataire_id;
    
    SELECT p.user_id INTO v_proprietaire_user_id 
    FROM public.proprietaires p
    JOIN public.contrats_location c ON c.proprietaire_id = p.id
    WHERE c.id = NEW.contrat_id;
    
    -- Notify locataire
    IF NEW.statut = 'paye' AND v_locataire_user_id IS NOT NULL THEN
        INSERT INTO public.notifications_systeme (
            destinataire_id, type, titre, message, lien
        ) VALUES (
            v_locataire_user_id,
            'paiement_recu',
            'Paiement confirmé',
            'Votre paiement de ' || NEW.montant_paye || ' ' || NEW.devise || ' a été reçu.',
            '/locataire/paiements'
        );
    END IF;
    
    -- Notify proprietaire
    IF NEW.statut = 'paye' AND v_proprietaire_user_id IS NOT NULL THEN
        INSERT INTO public.notifications_systeme (
            destinataire_id, type, titre, message, lien
        ) VALUES (
            v_proprietaire_user_id,
            'paiement_recu',
            'Loyer reçu',
            'Un paiement de ' || NEW.montant_paye || ' ' || NEW.devise || ' a été reçu.',
            '/proprietaire/paiements'
        );
    END IF;
    
    RETURN NEW;
END; $$;

CREATE TRIGGER on_paiement_update
    AFTER UPDATE ON public.paiements
    FOR EACH ROW 
    WHEN (OLD.statut IS DISTINCT FROM NEW.statut)
    EXECUTE FUNCTION public.notifier_paiement();

-- Notify on new ticket
CREATE OR REPLACE FUNCTION public.notifier_nouveau_ticket()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_ids UUID[];
BEGIN
    -- Notify all admins
    SELECT ARRAY_AGG(id) INTO v_admin_ids 
    FROM public.profiles WHERE role = 'admin';
    
    FOR i IN 1..COALESCE(array_length(v_admin_ids, 1), 0) LOOP
        INSERT INTO public.notifications_systeme (
            destinataire_id, type, titre, message, lien
        ) VALUES (
            v_admin_ids[i],
            'nouveau_ticket',
            'Nouveau ticket: ' || NEW.sujet,
            'Catégorie: ' || NEW.categorie || ' | Priorité: ' || NEW.priorite::TEXT,
            '/admin/tickets/' || NEW.id
        );
    END LOOP;
    
    RETURN NEW;
END; $$;

CREATE TRIGGER on_nouveau_ticket
    AFTER INSERT ON public.tickets_support
    FOR EACH ROW EXECUTE FUNCTION public.notifier_nouveau_ticket();

-- ============================================================
-- AUDIT LOGGING
-- ============================================================
CREATE OR REPLACE FUNCTION public.log_audit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_role user_role;
BEGIN
    SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
    
    INSERT INTO public.audit_log (
        user_id, user_role, action, table_name, record_id,
        old_data, new_data
    ) VALUES (
        auth.uid(),
        v_role,
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
    );
    
    RETURN COALESCE(NEW, OLD);
END; $$;

-- Add audit triggers to sensitive tables
CREATE TRIGGER audit_paiements AFTER INSERT OR UPDATE OR DELETE ON public.paiements
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();
CREATE TRIGGER audit_contrats AFTER INSERT OR UPDATE OR DELETE ON public.contrats_location
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();
CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON public.transactions_financieres
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();

-- ============================================================
-- PAYMENT LATE CHECK
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_paiements_retard()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Update late payments
    UPDATE public.paiements
    SET 
        statut = 'en_retard',
        jours_retard = CURRENT_DATE - date_echeance
    WHERE statut IN ('en_attente', 'partiel')
    AND date_echeance < CURRENT_DATE;
    
    -- Notify locataires with late payments
    INSERT INTO public.notifications_systeme (
        destinataire_id, type, titre, message, lien
    )
    SELECT DISTINCT
        l.user_id,
        'paiement_retard',
        'Paiement en retard',
        'Vous avez un paiement en retard. Veuillez régulariser votre situation.',
        '/locataire/paiements'
    FROM public.paiements p
    JOIN public.locataires l ON l.id = p.locataire_id
    WHERE p.statut = 'en_retard'
    AND p.updated_at > NOW() - INTERVAL '1 hour';  -- Only new late payments
END; $$;

-- ============================================================
-- DASHBOARD STATISTICS (Enhanced)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        -- Properties
        'total_proprietes', (SELECT COUNT(*) FROM public.proprietes WHERE est_actif = TRUE),
        'proprietes_disponibles', (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'disponible' AND est_actif = TRUE),
        'proprietes_louees', (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'loue'),
        'proprietes_vendues', (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'vendu'),
        
        -- Users
        'total_proprietaires', (SELECT COUNT(*) FROM public.proprietaires WHERE est_actif = TRUE),
        'total_locataires', (SELECT COUNT(*) FROM public.locataires WHERE est_actif = TRUE),
        'total_agents', (SELECT COUNT(*) FROM public.agents WHERE actif = TRUE),
        
        -- Contracts
        'contrats_actifs', (SELECT COUNT(*) FROM public.contrats_location WHERE statut = 'actif'),
        'contrats_expire_bientot', (SELECT COUNT(*) FROM public.contrats_location 
            WHERE statut = 'actif' AND date_fin <= CURRENT_DATE + INTERVAL '30 days'),
        
        -- Payments
        'paiements_en_attente', (SELECT COUNT(*) FROM public.paiements WHERE statut = 'en_attente'),
        'paiements_en_retard', (SELECT COUNT(*) FROM public.paiements WHERE statut = 'en_retard'),
        'revenus_ce_mois', (SELECT COALESCE(SUM(montant_paye), 0) FROM public.paiements 
            WHERE statut = 'paye' AND DATE_TRUNC('month', date_paiement) = DATE_TRUNC('month', CURRENT_DATE)),
        
        -- Tickets
        'tickets_ouverts', (SELECT COUNT(*) FROM public.tickets_support WHERE statut IN ('ouvert', 'en_cours')),
        'tickets_urgents', (SELECT COUNT(*) FROM public.tickets_support WHERE statut = 'ouvert' AND priorite = 'urgente'),
        
        -- Recent Activity
        'nouveaux_contacts', (SELECT COUNT(*) FROM public.contacts WHERE statut = 'nouveau'),
        'visites_ce_mois', (SELECT COUNT(*) FROM public.visites 
            WHERE DATE_TRUNC('month', date_visite) = DATE_TRUNC('month', CURRENT_DATE))
    ) INTO result;
    
    RETURN result;
END; $$;

-- ============================================================
-- PROPRIETAIRE DASHBOARD
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_proprietaire_dashboard(p_proprietaire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        -- Properties
        'mes_proprietes', (SELECT COUNT(*) FROM public.proprietes 
            WHERE proprietaire_id = p_proprietaire_id AND est_actif = TRUE),
        'proprietes_louees', (SELECT COUNT(*) FROM public.proprietes 
            WHERE proprietaire_id = p_proprietaire_id AND statut = 'loue'),
        'proprietes_disponibles', (SELECT COUNT(*) FROM public.proprietes 
            WHERE proprietaire_id = p_proprietaire_id AND statut = 'disponible'),
        
        -- Financial
        'revenus_ce_mois', (SELECT COALESCE(SUM(p.montant_paye), 0) 
            FROM public.paiements p
            JOIN public.contrats_location c ON c.id = p.contrat_id
            WHERE c.proprietaire_id = p_proprietaire_id 
            AND p.statut = 'paye'
            AND DATE_TRUNC('month', p.date_paiement) = DATE_TRUNC('month', CURRENT_DATE)),
        'paiements_en_attente', (SELECT COUNT(*) 
            FROM public.paiements p
            JOIN public.contrats_location c ON c.id = p.contrat_id
            WHERE c.proprietaire_id = p_proprietaire_id AND p.statut IN ('en_attente', 'en_retard')),
        
        -- Contracts
        'contrats_actifs', (SELECT COUNT(*) FROM public.contrats_location 
            WHERE proprietaire_id = p_proprietaire_id AND statut = 'actif'),
        
        -- Tickets
        'tickets_ouverts', (SELECT COUNT(*) FROM public.tickets_support t
            JOIN public.proprietes pr ON pr.id = t.propriete_id
            WHERE pr.proprietaire_id = p_proprietaire_id AND t.statut IN ('ouvert', 'en_cours')),
        
        -- Taux occupation
        'taux_occupation', (SELECT 
            CASE WHEN COUNT(*) > 0 
            THEN ROUND(COUNT(*) FILTER (WHERE statut = 'loue')::NUMERIC / COUNT(*) * 100, 1)
            ELSE 0 END
            FROM public.proprietes WHERE proprietaire_id = p_proprietaire_id AND est_actif = TRUE)
    ) INTO result;
    
    RETURN result;
END; $$;

-- ============================================================
-- LOCATAIRE DASHBOARD
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_locataire_dashboard(p_locataire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        -- Contract Info
        'contrat_actif', (SELECT json_build_object(
            'id', c.id,
            'reference', c.reference,
            'propriete_titre', pr.titre,
            'propriete_adresse', pr.adresse,
            'loyer_mensuel', c.loyer_mensuel,
            'date_fin', c.date_fin,
            'jours_restants', c.date_fin - CURRENT_DATE
        ) FROM public.contrats_location c
        JOIN public.proprietes pr ON pr.id = c.propriete_id
        WHERE c.locataire_id = p_locataire_id AND c.statut = 'actif'
        LIMIT 1),
        
        -- Payments
        'prochain_paiement', (SELECT json_build_object(
            'montant', montant_total,
            'date_echeance', date_echeance,
            'jours_avant', date_echeance - CURRENT_DATE
        ) FROM public.paiements 
        WHERE locataire_id = p_locataire_id 
        AND statut = 'en_attente'
        ORDER BY date_echeance LIMIT 1),
        
        'solde_du', (SELECT COALESCE(SUM(solde_restant), 0) FROM public.paiements 
            WHERE locataire_id = p_locataire_id AND statut IN ('en_attente', 'en_retard', 'partiel')),
        
        'paiements_retard', (SELECT COUNT(*) FROM public.paiements 
            WHERE locataire_id = p_locataire_id AND statut = 'en_retard'),
        
        -- Tickets
        'mes_tickets_ouverts', (SELECT COUNT(*) FROM public.tickets_support 
            WHERE createur_id = (SELECT user_id FROM public.locataires WHERE id = p_locataire_id)
            AND statut IN ('ouvert', 'en_cours')),
        
        -- Score
        'score_paiement', (SELECT score_paiement FROM public.locataires WHERE id = p_locataire_id)
    ) INTO result;
    
    RETURN result;
END; $$;

-- ============================================================
-- GENERATE MONTHLY PAYMENTS
-- ============================================================
CREATE OR REPLACE FUNCTION public.generer_paiements_mensuels()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_contrat RECORD;
    v_next_month DATE;
BEGIN
    v_next_month := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';
    
    FOR v_contrat IN 
        SELECT * FROM public.contrats_location 
        WHERE statut = 'actif' 
        AND date_fin >= v_next_month
    LOOP
        -- Check if payment already exists for next month
        IF NOT EXISTS (
            SELECT 1 FROM public.paiements 
            WHERE contrat_id = v_contrat.id 
            AND annee = EXTRACT(YEAR FROM v_next_month)
            AND mois = EXTRACT(MONTH FROM v_next_month)
        ) THEN
            INSERT INTO public.paiements (
                contrat_id, locataire_id, propriete_id,
                mois, annee, periode_debut, periode_fin,
                montant_loyer, montant_charges, montant_total,
                date_echeance, devise
            ) VALUES (
                v_contrat.id,
                v_contrat.locataire_id,
                v_contrat.propriete_id,
                EXTRACT(MONTH FROM v_next_month),
                EXTRACT(YEAR FROM v_next_month),
                v_next_month,
                (v_next_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
                v_contrat.loyer_mensuel,
                v_contrat.charges_mensuelles,
                v_contrat.loyer_mensuel + COALESCE(v_contrat.charges_mensuelles, 0),
                (v_next_month + (v_contrat.jour_paiement - 1) * INTERVAL '1 day')::DATE,
                v_contrat.devise
            );
        END IF;
    END LOOP;
END; $$;
