-- ============================================================
-- EXPERIMMO - MASTER ULTIMATE FIX 2026 (VERSION CORRIGÉE)
-- ALIGNEMENT 100% CDC ET RÉPARATION TOTALE
-- ============================================================

-- 1. EXTENSIONS ET TYPES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'proprietaire', 'locataire', 'gestionnaire', 'assistante');
    ELSE
        BEGIN ALTER TYPE user_role ADD VALUE 'gestionnaire'; EXCEPTION WHEN duplicate_object THEN null; END;
        BEGIN ALTER TYPE user_role ADD VALUE 'assistante'; EXCEPTION WHEN duplicate_object THEN null; END;
    END IF;
END $$;

-- 2. RÉPARATION ET RENOMMAGE SÉCURISÉ DES TABLES
DO $$ 
BEGIN
    -- Contrats
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contrats_location') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contrats') THEN
        ALTER TABLE public.contrats_location RENAME TO contrats;
    END IF;

    -- IDs Propriétaires
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietaires' AND column_name='id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietaires' AND column_name='id_proprietaire') THEN
        ALTER TABLE public.proprietaires RENAME COLUMN id TO id_proprietaire;
    END IF;

    -- IDs Locataires
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='locataires' AND column_name='id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='locataires' AND column_name='id_locataire') THEN
        ALTER TABLE public.locataires RENAME COLUMN id TO id_locataire;
    END IF;

    -- IDs Propriétés
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietes' AND column_name='id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='proprietes' AND column_name='id_propriete') THEN
        ALTER TABLE public.proprietes RENAME COLUMN id TO id_propriete;
    END IF;
    
    -- IDs Contrats
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contrats' AND column_name='id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contrats' AND column_name='id_contrat') THEN
        ALTER TABLE public.contrats RENAME COLUMN id TO id_contrat;
    END IF;

    -- IDs Paiements
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='paiements' AND column_name='id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='paiements' AND column_name='id_paiement') THEN
        ALTER TABLE public.paiements RENAME COLUMN id TO id_paiement;
    END IF;
END $$;

-- 3. RÉPARATION SÉCURISÉE DU JOURNAL D'ACTIVITÉ (Audit Log)
DO $$ 
BEGIN
    -- On ne renomme QUE si la source existe ET que la destination n'existe PAS encore
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='user_id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='utilisateur') THEN
        ALTER TABLE public.audit_log RENAME COLUMN user_id TO utilisateur;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='old_data') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='ancienne_valeur') THEN
        ALTER TABLE public.audit_log RENAME COLUMN old_data TO ancienne_valeur;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='new_data') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='nouvelle_valeur') THEN
        ALTER TABLE public.audit_log RENAME COLUMN new_data TO nouvelle_valeur;
    END IF;
END $$;

-- 4. AJOUT DES CHAMPS CDC MANQUANTS
ALTER TABLE public.proprietaires ADD COLUMN IF NOT EXISTS nif TEXT, ADD COLUMN IF NOT EXISTS cin TEXT, ADD COLUMN IF NOT EXISTS serie INTEGER;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS nif TEXT, ADD COLUMN IF NOT EXISTS cin TEXT, ADD COLUMN IF NOT EXISTS serie INTEGER;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS serie INTEGER, ADD COLUMN IF NOT EXISTS dimension TEXT, ADD COLUMN IF NOT EXISTS type_mandat TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ;

-- 5. FONCTIONS ET AUTOMATISMES (TRIGGERS)
CREATE OR REPLACE FUNCTION public.log_audit_v3() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.audit_log (utilisateur, user_role, action, table_name, record_id, ancienne_valeur, nouvelle_valeur, horodatage)
    VALUES (auth.uid(), (SELECT role FROM public.profiles WHERE id = auth.uid()), TG_OP, TG_TABLE_NAME, 
    COALESCE(NEW.id_contrat, NEW.id_propriete, NEW.id_proprietaire, NEW.id_locataire, NEW.id_paiement, NEW.id_facture, NEW.id), 
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END, CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END, NOW());
    RETURN COALESCE(NEW, OLD);
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ré-application propre des triggers
DROP TRIGGER IF EXISTS trg_audit_contrats ON public.contrats;
CREATE TRIGGER trg_audit_contrats AFTER INSERT OR UPDATE OR DELETE ON public.contrats FOR EACH ROW EXECUTE FUNCTION public.log_audit_v3();
DROP TRIGGER IF EXISTS trg_audit_paiements ON public.paiements;
CREATE TRIGGER trg_audit_paiements AFTER INSERT OR UPDATE OR DELETE ON public.paiements FOR EACH ROW EXECUTE FUNCTION public.log_audit_v3();
DROP TRIGGER IF EXISTS trg_audit_proprietes ON public.proprietes;
CREATE TRIGGER trg_audit_proprietes AFTER INSERT OR UPDATE OR DELETE ON public.proprietes FOR EACH ROW EXECUTE FUNCTION public.log_audit_v3();

-- 6. GÉNÉRATEUR DE CODES CDC (46xxx)
CREATE OR REPLACE FUNCTION generate_experimmo_code_master_v3() RETURNS TRIGGER AS $$
DECLARE
    p_prefix TEXT;
    p_seq INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'proprietaires' THEN p_prefix := 'PR';
    ELSIF TG_TABLE_NAME = 'locataires' THEN p_prefix := 'L';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN p_prefix := 'P';
    ELSIF TG_TABLE_NAME = 'contrats' THEN p_prefix := 'C';
    ELSE p_prefix := 'GEN';
    END IF;

    EXECUTE format('SELECT COALESCE(MAX(serie), 0) + 1 FROM public.%I', TG_TABLE_NAME) INTO p_seq;
    NEW.serie := p_seq;
    
    IF TG_TABLE_NAME = 'proprietaires' THEN NEW.code_proprietaire := '46' || LPAD(p_seq::text, 3, '0') || p_prefix || '-1';
    ELSIF TG_TABLE_NAME = 'locataires' THEN NEW.code_locataire := '46' || LPAD(p_seq::text, 3, '0') || p_prefix || '-1';
    ELSIF TG_TABLE_NAME = 'proprietes' THEN NEW.code_propriete := '46' || LPAD(p_seq::text, 3, '0') || p_prefix || '-1';
    ELSIF TG_TABLE_NAME = 'contrats' THEN NEW.reference := '46' || LPAD(p_seq::text, 3, '0') || p_prefix || '-1';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gen_code_pr ON public.proprietaires;
CREATE TRIGGER trg_gen_code_pr BEFORE INSERT ON public.proprietaires FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code_master_v3();
DROP TRIGGER IF EXISTS trg_gen_code_l ON public.locataires;
CREATE TRIGGER trg_gen_code_l BEFORE INSERT ON public.locataires FOR EACH ROW EXECUTE FUNCTION generate_experimmo_code_master_v3();

-- 7. DASHBOARD DYNAMIQUE
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'total_proprietes', (SELECT COUNT(*) FROM public.proprietes),
        'total_proprietaires', (SELECT COUNT(*) FROM public.proprietaires),
        'total_locataires', (SELECT COUNT(*) FROM public.locataires),
        'contrats_actifs', (SELECT COUNT(*) FROM public.contrats WHERE statut IN ('actif', 'valide')),
        'revenus_ce_mois', (SELECT COALESCE(SUM(montant_paye), 0) FROM public.paiements WHERE statut = 'paye' AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)),
        'paiements_en_retard', (SELECT COUNT(*) FROM public.paiements WHERE statut = 'en_retard')
    ) INTO result;
    RETURN result;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;
