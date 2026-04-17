-- ============================================================
-- EXPERIMMO — SEED DE TEST v5 (Auto-Repair + Full Fix)
-- Prérequis : exécuter après les migrations 01-19 + MASTER_FIX
-- Cleanup   : email LIKE '%@test.ht'  /  id LIKE 'eeee%'
-- Login     : admin/gestionnaire/proprietaire/locataire @test.ht
-- Mot de passe : Test@1234
-- ============================================================

-- ÉTAPE 0 : Roles
DO $$ BEGIN
    BEGIN ALTER TYPE user_role ADD VALUE 'gestionnaire'; EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN ALTER TYPE user_role ADD VALUE 'assistante';   EXCEPTION WHEN duplicate_object THEN NULL; END;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- ÉTAPE 0.5 : Colonnes manquantes + renames conditionnels (idempotent)
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

-- ÉTAPE 0.7 : Correction de TOUTES les fonctions cassées (renommages MASTER_FIX)

CREATE OR REPLACE FUNCTION public.get_proprietaire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id_proprietaire FROM public.proprietaires WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_locataire_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id_locataire FROM public.locataires WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.log_audit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_role user_role; v_row JSONB; v_record_id UUID;
BEGIN
    v_row := CASE WHEN TG_OP='DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
    v_record_id := CASE TG_TABLE_NAME
        WHEN 'contrats'      THEN (v_row->>'id_contrat')::UUID
        WHEN 'proprietes'    THEN (v_row->>'id_propriete')::UUID
        WHEN 'proprietaires' THEN (v_row->>'id_proprietaire')::UUID
        WHEN 'locataires'    THEN (v_row->>'id_locataire')::UUID
        WHEN 'paiements'     THEN (v_row->>'id_paiement')::UUID
        WHEN 'factures'      THEN (v_row->>'id_facture')::UUID
        WHEN 'operations'    THEN (v_row->>'id_operation')::UUID
        ELSE (v_row->>'id')::UUID END;
    SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
    INSERT INTO public.audit_log (utilisateur,user_role,action,table_name,record_id,ancienne_valeur,nouvelle_valeur,horodatage)
    VALUES (auth.uid(),v_role,TG_OP,TG_TABLE_NAME,v_record_id,
        CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END, NOW());
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN RETURN COALESCE(NEW, OLD); END; $$;

CREATE OR REPLACE FUNCTION public.log_audit_v3()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_row JSONB; v_record_id UUID;
BEGIN
    v_row := CASE WHEN TG_OP='DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
    v_record_id := CASE TG_TABLE_NAME
        WHEN 'contrats'      THEN (v_row->>'id_contrat')::UUID
        WHEN 'proprietes'    THEN (v_row->>'id_propriete')::UUID
        WHEN 'proprietaires' THEN (v_row->>'id_proprietaire')::UUID
        WHEN 'locataires'    THEN (v_row->>'id_locataire')::UUID
        WHEN 'paiements'     THEN (v_row->>'id_paiement')::UUID
        WHEN 'factures'      THEN (v_row->>'id_facture')::UUID
        WHEN 'operations'    THEN (v_row->>'id_operation')::UUID
        ELSE (v_row->>'id')::UUID END;
    INSERT INTO public.audit_log (utilisateur,user_role,action,table_name,record_id,ancienne_valeur,nouvelle_valeur,horodatage)
    VALUES (auth.uid(),(SELECT role FROM public.profiles WHERE id=auth.uid()),
        TG_OP,TG_TABLE_NAME,v_record_id,
        CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END, NOW());
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN RETURN COALESCE(NEW, OLD); END; $$;

CREATE OR REPLACE FUNCTION public.update_proprietaire_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.proprietaires SET
        nb_proprietes = (SELECT COUNT(*) FROM public.proprietes WHERE proprietaire_id=COALESCE(NEW.proprietaire_id,OLD.proprietaire_id)),
        revenu_total  = (SELECT COALESCE(SUM(prix_loyer),0) FROM public.proprietes WHERE proprietaire_id=COALESCE(NEW.proprietaire_id,OLD.proprietaire_id) AND statut='loue'),
        updated_at    = NOW()
    WHERE id_proprietaire = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id);
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN RETURN COALESCE(NEW, OLD); END; $$;

CREATE OR REPLACE FUNCTION public.notifier_paiement()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_loc_uid UUID; v_prop_uid UUID;
BEGIN
    SELECT user_id INTO v_loc_uid  FROM public.locataires    WHERE id_locataire    = NEW.locataire_id;
    SELECT p.user_id INTO v_prop_uid FROM public.proprietaires p JOIN public.contrats c ON c.proprietaire_id=p.id_proprietaire WHERE c.id_contrat = NEW.contrat_id;
    IF NEW.statut='paye' AND v_loc_uid  IS NOT NULL THEN
        INSERT INTO public.notifications_systeme (destinataire_id,type,titre,message,lien) VALUES (v_loc_uid,'paiement_recu','Paiement confirmé','Paiement de '||NEW.montant_paye||' '||NEW.devise||' reçu.','/locataire/paiements');
    END IF;
    IF NEW.statut='paye' AND v_prop_uid IS NOT NULL THEN
        INSERT INTO public.notifications_systeme (destinataire_id,type,titre,message,lien) VALUES (v_prop_uid,'paiement_recu','Loyer reçu','Paiement de '||NEW.montant_paye||' '||NEW.devise||' reçu.','/proprietaire/paiements');
    END IF;
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION public.check_paiements_retard()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.paiements SET statut='en_retard', jours_retard=CURRENT_DATE-date_echeance
    WHERE statut IN ('en_attente','partiel') AND date_echeance < CURRENT_DATE;
    INSERT INTO public.notifications_systeme (destinataire_id,type,titre,message,lien)
    SELECT DISTINCT l.user_id,'paiement_retard','Paiement en retard','Vous avez un paiement en retard.','/locataire/paiements'
    FROM public.paiements p JOIN public.locataires l ON l.id_locataire=p.locataire_id
    WHERE p.statut='en_retard' AND p.updated_at > NOW()-INTERVAL'1 hour';
EXCEPTION WHEN OTHERS THEN NULL; END; $$;

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'total_proprietes',(SELECT COUNT(*) FROM public.proprietes WHERE est_actif=TRUE),
        'total_proprietaires',(SELECT COUNT(*) FROM public.proprietaires WHERE est_actif=TRUE),
        'total_locataires',(SELECT COUNT(*) FROM public.locataires WHERE est_actif=TRUE),
        'contrats_actifs',(SELECT COUNT(*) FROM public.contrats WHERE statut='actif'),
        'paiements_en_attente',(SELECT COUNT(*) FROM public.paiements WHERE statut='en_attente'),
        'paiements_en_retard',(SELECT COUNT(*) FROM public.paiements WHERE statut='en_retard'),
        'revenus_ce_mois',(SELECT COALESCE(SUM(montant_paye),0) FROM public.paiements WHERE statut='paye' AND DATE_TRUNC('month',date_paiement)=DATE_TRUNC('month',CURRENT_DATE))
    ) INTO result; RETURN result;
EXCEPTION WHEN OTHERS THEN RETURN '{}'; END; $$;

CREATE OR REPLACE FUNCTION public.get_proprietaire_dashboard(p_proprietaire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'mes_proprietes',(SELECT COUNT(*) FROM public.proprietes WHERE proprietaire_id=p_proprietaire_id AND est_actif=TRUE),
        'proprietes_louees',(SELECT COUNT(*) FROM public.proprietes WHERE proprietaire_id=p_proprietaire_id AND statut='loue'),
        'contrats_actifs',(SELECT COUNT(*) FROM public.contrats WHERE proprietaire_id=p_proprietaire_id AND statut='actif'),
        'revenus_ce_mois',(SELECT COALESCE(SUM(p.montant_paye),0) FROM public.paiements p JOIN public.contrats c ON c.id_contrat=p.contrat_id WHERE c.proprietaire_id=p_proprietaire_id AND p.statut='paye' AND DATE_TRUNC('month',p.date_paiement)=DATE_TRUNC('month',CURRENT_DATE)),
        'paiements_en_attente',(SELECT COUNT(*) FROM public.paiements p JOIN public.contrats c ON c.id_contrat=p.contrat_id WHERE c.proprietaire_id=p_proprietaire_id AND p.statut IN ('en_attente','en_retard'))
    ) INTO result; RETURN result;
EXCEPTION WHEN OTHERS THEN RETURN '{}'; END; $$;

CREATE OR REPLACE FUNCTION public.get_locataire_dashboard(p_locataire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'contrat_actif',(SELECT json_build_object('id',c.id_contrat,'reference',c.reference,'propriete_titre',pr.titre,'loyer_mensuel',c.loyer_mensuel,'date_fin',c.date_fin) FROM public.contrats c JOIN public.proprietes pr ON pr.id_propriete=c.propriete_id WHERE c.locataire_id=p_locataire_id AND c.statut='actif' LIMIT 1),
        'prochain_paiement',(SELECT json_build_object('montant',montant_total,'date_echeance',date_echeance) FROM public.paiements WHERE locataire_id=p_locataire_id AND statut='en_attente' ORDER BY date_echeance LIMIT 1),
        'solde_du',(SELECT COALESCE(SUM(solde_restant),0) FROM public.paiements WHERE locataire_id=p_locataire_id AND statut IN ('en_attente','en_retard','partiel')),
        'score_paiement',(SELECT score_paiement FROM public.locataires WHERE id_locataire=p_locataire_id)
    ) INTO result; RETURN result;
EXCEPTION WHEN OTHERS THEN RETURN '{}'; END; $$;

CREATE OR REPLACE FUNCTION public.generer_paiements_mensuels()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_contrat RECORD; v_next_month DATE;
BEGIN
    v_next_month := DATE_TRUNC('month',CURRENT_DATE)+INTERVAL'1 month';
    FOR v_contrat IN SELECT * FROM public.contrats WHERE statut='actif' AND date_fin>=v_next_month LOOP
        IF NOT EXISTS (SELECT 1 FROM public.paiements WHERE contrat_id=v_contrat.id_contrat AND annee=EXTRACT(YEAR FROM v_next_month) AND mois=EXTRACT(MONTH FROM v_next_month)) THEN
            INSERT INTO public.paiements (contrat_id,locataire_id,propriete_id,mois,annee,periode_debut,periode_fin,montant_loyer,montant_charges,montant_total,date_echeance,devise)
            VALUES (v_contrat.id_contrat,v_contrat.locataire_id,v_contrat.propriete_id,
                EXTRACT(MONTH FROM v_next_month),EXTRACT(YEAR FROM v_next_month),v_next_month,
                (v_next_month+INTERVAL'1 month'-INTERVAL'1 day')::DATE,
                v_contrat.loyer_mensuel,v_contrat.charges_mensuelles,
                v_contrat.loyer_mensuel+COALESCE(v_contrat.charges_mensuelles,0),
                (v_next_month+(v_contrat.jour_paiement-1)*INTERVAL'1 day')::DATE,v_contrat.devise);
        END IF;
    END LOOP;
EXCEPTION WHEN OTHERS THEN NULL; END; $$;

-- Re-attacher triggers à 'contrats' (table renommée)
DO $$ BEGIN DROP TRIGGER IF EXISTS calc_duree_contrat    ON public.contrats_location; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DROP TRIGGER IF EXISTS calc_duree_contrat    ON public.contrats;
CREATE TRIGGER calc_duree_contrat BEFORE INSERT OR UPDATE ON public.contrats FOR EACH ROW EXECUTE FUNCTION public.calc_duree_mois();

DO $$ BEGIN DROP TRIGGER IF EXISTS set_reference_contrat ON public.contrats_location; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DROP TRIGGER IF EXISTS set_reference_contrat ON public.contrats;
CREATE TRIGGER set_reference_contrat BEFORE INSERT ON public.contrats FOR EACH ROW EXECUTE FUNCTION public.generer_reference_contrat();

DO $$ BEGIN DROP TRIGGER IF EXISTS audit_contrats        ON public.contrats_location; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DROP TRIGGER IF EXISTS audit_contrats        ON public.contrats;
CREATE TRIGGER audit_contrats AFTER INSERT OR UPDATE OR DELETE ON public.contrats FOR EACH ROW EXECUTE FUNCTION public.log_audit();

-- ============================================================
-- ÉTAPE 1 : Auth users
-- ============================================================
INSERT INTO auth.users (id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,confirmation_sent_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) VALUES
('eeee0000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','admin@test.ht',        crypt('Test@1234',gen_salt('bf')),NOW(),NOW(),'{"provider":"email"}','{"full_name":"Admin Test","role":"admin"}',NOW(),NOW()),
('eeee0000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','gestionnaire@test.ht', crypt('Test@1234',gen_salt('bf')),NOW(),NOW(),'{"provider":"email"}','{"full_name":"Jean Gestionnaire","role":"gestionnaire"}',NOW(),NOW()),
('eeee0000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','proprietaire@test.ht', crypt('Test@1234',gen_salt('bf')),NOW(),NOW(),'{"provider":"email"}','{"full_name":"Pierre Propriétaire","role":"proprietaire"}',NOW(),NOW()),
('eeee0000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','locataire@test.ht',    crypt('Test@1234',gen_salt('bf')),NOW(),NOW(),'{"provider":"email"}','{"full_name":"Marie Locataire","role":"locataire"}',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

-- ÉTAPE 2 : Profiles
INSERT INTO public.profiles (id,email,full_name,phone,role,is_verified,is_active,adresse,nationalite,statut_dossier) VALUES
('eeee0000-0000-0000-0000-000000000001','admin@test.ht',       'Admin Test',          '+509 3700-0001','admin',        TRUE,TRUE,'Pétion-Ville','Haïtienne','valide'),
('eeee0000-0000-0000-0000-000000000002','gestionnaire@test.ht','Jean Gestionnaire',   '+509 3700-0002','gestionnaire', TRUE,TRUE,'Delmas 31',   'Haïtienne','valide'),
('eeee0000-0000-0000-0000-000000000003','proprietaire@test.ht','Pierre Propriétaire', '+509 3700-0003','proprietaire', TRUE,TRUE,'Laboule 12',  'Haïtienne','valide'),
('eeee0000-0000-0000-0000-000000000004','locataire@test.ht',   'Marie Locataire',     '+509 3700-0004','locataire',    TRUE,TRUE,'Kenscoff',    'Haïtienne','valide')
ON CONFLICT (id) DO UPDATE SET full_name=EXCLUDED.full_name, role=EXCLUDED.role, is_verified=EXCLUDED.is_verified;

-- ÉTAPE 3 : Agent
INSERT INTO public.agents (id,nom,prenom,slug,titre,email,telephone,experience_ans,actif)
VALUES ('eeee0000-0000-0000-0000-000000000017','Gestionnaire','Jean','jean-gestionnaire-seed','Agent Senior','gestionnaire@test.ht','+509 3700-0002',5,TRUE)
ON CONFLICT (id) DO NOTHING;

-- ÉTAPE 4 : Proprietaire
INSERT INTO public.proprietaires (user_id,type_proprietaire,nom_banque,mode_paiement_prefere,commission_taux,date_debut_mandat,date_fin_mandat,est_actif,nb_proprietes)
VALUES ('eeee0000-0000-0000-0000-000000000003','particulier','BNC Haïti','virement',10.00,CURRENT_DATE-INTERVAL'6 months',CURRENT_DATE+INTERVAL'6 months',TRUE,1)
ON CONFLICT (user_id) DO UPDATE SET type_proprietaire=EXCLUDED.type_proprietaire, commission_taux=EXCLUDED.commission_taux, nb_proprietes=EXCLUDED.nb_proprietes;

-- ÉTAPE 5 : Locataire
INSERT INTO public.locataires (user_id,profession,employeur,revenu_mensuel,garant_nom,garant_telephone,score_paiement,est_actif,est_blackliste)
VALUES ('eeee0000-0000-0000-0000-000000000004','Ingénieur Informatique','Digicel Haïti',3500.00,'Paul Garant','+509 3800-0001',100,TRUE,FALSE)
ON CONFLICT (user_id) DO UPDATE SET profession=EXCLUDED.profession, revenu_mensuel=EXCLUDED.revenu_mensuel, score_paiement=EXCLUDED.score_paiement;

-- ÉTAPE 6 : Propriété (PK = id_propriete)
INSERT INTO public.proprietes (id_propriete,titre,slug,type_transaction,type_propriete,prix,prix_loyer,devise,zone_id,adresse,ville,superficie_m2,nb_chambres,nb_salles_bain,nb_garages,meuble,statut,est_actif,proprietaire_id,est_gere,agent_id)
VALUES (
  'eeee0000-0000-0000-0000-000000000007',
  'Villa Test Seed — Laboule 12','villa-test-seed-2026',
  'location','villa',0.00,2500.00,'USD',
  (SELECT id FROM public.zones WHERE slug='laboule' LIMIT 1),
  'Laboule 12, Route de Kenscoff','Port-au-Prince',
  280.00,3,2,1,TRUE,'loue',TRUE,
  (SELECT id_proprietaire FROM public.proprietaires WHERE user_id='eeee0000-0000-0000-0000-000000000003'),
  TRUE,'eeee0000-0000-0000-0000-000000000017'
) ON CONFLICT (id_propriete) DO NOTHING;

-- ÉTAPE 7 : Contrat (PK = id_contrat, reference fournie pour éviter dépendance trigger)
INSERT INTO public.contrats (id_contrat,reference,propriete_id,locataire_id,proprietaire_id,agent_id,date_debut,date_fin,loyer_mensuel,devise,charges_mensuelles,depot_garantie,depot_garantie_paye,jour_paiement,mode_paiement,statut,renouvellement_auto,montant_chiffre,montant_lettre,frais_cabinet,recurrence_frais_cabinet)
VALUES (
  'eeee0000-0000-0000-0000-000000000008',
  'CTR-SEED-2026-001',
  'eeee0000-0000-0000-0000-000000000007',
  (SELECT id_locataire    FROM public.locataires    WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
  (SELECT id_proprietaire FROM public.proprietaires WHERE user_id='eeee0000-0000-0000-0000-000000000003'),
  'eeee0000-0000-0000-0000-000000000017',
  DATE_TRUNC('month',NOW())-INTERVAL'2 months',
  DATE_TRUNC('month',NOW())+INTERVAL'10 months',
  2500.00,'USD',150.00,5000.00,TRUE,5,'virement','actif',TRUE,
  2500.00,'Deux mille cinq cents dollars américains',250.00,'mensuel'
) ON CONFLICT (id_contrat) DO NOTHING;

-- ÉTAPE 8 : Paiements (PK = id_paiement, reference fournie)
INSERT INTO public.paiements (id_paiement,reference,contrat_id,locataire_id,propriete_id,mois,annee,periode_debut,periode_fin,montant_loyer,montant_charges,montant_total,date_echeance,date_paiement,montant_paye,statut,mode_paiement,devise) VALUES
('eeee0000-0000-0000-0000-000000000009','PAY-SEED-001',
 'eeee0000-0000-0000-0000-000000000008',
 (SELECT id_locataire FROM public.locataires WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
 'eeee0000-0000-0000-0000-000000000007',
 EXTRACT(MONTH FROM NOW()-INTERVAL'2 months')::INT, EXTRACT(YEAR FROM NOW()-INTERVAL'2 months')::INT,
 DATE_TRUNC('month',NOW()-INTERVAL'2 months'),
 (DATE_TRUNC('month',NOW()-INTERVAL'2 months')+INTERVAL'1 month'-INTERVAL'1 day')::DATE,
 2500.00,150.00,2650.00,
 (DATE_TRUNC('month',NOW()-INTERVAL'2 months')+INTERVAL'5 days')::DATE,
 (DATE_TRUNC('month',NOW()-INTERVAL'2 months')+INTERVAL'3 days')::DATE,
 2650.00,'paye','virement','USD'),
('eeee0000-0000-0000-0000-000000000010','PAY-SEED-002',
 'eeee0000-0000-0000-0000-000000000008',
 (SELECT id_locataire FROM public.locataires WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
 'eeee0000-0000-0000-0000-000000000007',
 EXTRACT(MONTH FROM NOW()-INTERVAL'1 month')::INT, EXTRACT(YEAR FROM NOW()-INTERVAL'1 month')::INT,
 DATE_TRUNC('month',NOW()-INTERVAL'1 month'),
 (DATE_TRUNC('month',NOW()-INTERVAL'1 month')+INTERVAL'1 month'-INTERVAL'1 day')::DATE,
 2500.00,150.00,2650.00,
 (DATE_TRUNC('month',NOW()-INTERVAL'1 month')+INTERVAL'5 days')::DATE,
 (DATE_TRUNC('month',NOW()-INTERVAL'1 month')+INTERVAL'4 days')::DATE,
 2650.00,'paye','virement','USD'),
('eeee0000-0000-0000-0000-000000000011','PAY-SEED-003',
 'eeee0000-0000-0000-0000-000000000008',
 (SELECT id_locataire FROM public.locataires WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
 'eeee0000-0000-0000-0000-000000000007',
 EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT,
 DATE_TRUNC('month',NOW()),
 (DATE_TRUNC('month',NOW())+INTERVAL'1 month'-INTERVAL'1 day')::DATE,
 2500.00,150.00,2650.00,
 (DATE_TRUNC('month',NOW())+INTERVAL'5 days')::DATE,
 NULL,0.00,'en_attente',NULL,'USD')
ON CONFLICT (id_paiement) DO NOTHING;

-- ÉTAPE 9 : Factures (PK=id_facture, schema de 16_MASTER_UPDATE.sql)
INSERT INTO public.factures (id_facture,type_facture,id_locataire,id_propriete,periode,date_emission,date_echeance,montant,statut_facture) VALUES
('eeee0000-0000-0000-0000-000000000012',
 'eau',
 (SELECT id_locataire FROM public.locataires WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
 'eeee0000-0000-0000-0000-000000000007',
 TO_CHAR(NOW()-INTERVAL'1 month','Month YYYY'),
 DATE_TRUNC('month',NOW()-INTERVAL'1 month')::DATE,
 (DATE_TRUNC('month',NOW()-INTERVAL'1 month')+INTERVAL'20 days')::DATE,
 45.00,'paye'),
('eeee0000-0000-0000-0000-000000000013',
 'electricite',
 (SELECT id_locataire FROM public.locataires WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
 'eeee0000-0000-0000-0000-000000000007',
 TO_CHAR(NOW(),'Month YYYY'),
 CURRENT_DATE,
 (DATE_TRUNC('month',NOW())+INTERVAL'20 days')::DATE,
 85.00,'impaye')
ON CONFLICT (id_facture) DO NOTHING;

-- ÉTAPE 10 : Opération (PK=id_operation, schema de 16_MASTER_UPDATE.sql)
INSERT INTO public.operations (id_operation,id_propriete,id_proprietaire,type_operation,remarques,montant,date_operation,statut_operation)
VALUES (
  'eeee0000-0000-0000-0000-000000000014',
  'eeee0000-0000-0000-0000-000000000007',
  (SELECT id_proprietaire FROM public.proprietaires WHERE user_id='eeee0000-0000-0000-0000-000000000003'),
  'encaissement','Encaissement loyer — seed test',
  2650.00,(CURRENT_DATE-INTERVAL'1 month')::DATE,'valide'
) ON CONFLICT (id_operation) DO NOTHING;

-- ÉTAPE 11 : Messages
INSERT INTO public.messages (id_message,expediteur,destinataire,type_expediteur,type_destinataire,objet,categorie,message,statut_message,date_envoi,lu_oui_non) VALUES
('eeee0000-0000-0000-0000-000000000015',
 'eeee0000-0000-0000-0000-000000000004','eeee0000-0000-0000-0000-000000000002',
 'locataire','gestionnaire','Problème robinet cuisine','reparation',
 'Le robinet fuit depuis ce matin. Pouvez-vous envoyer un plombier ?',
 'nouveau',NOW()-INTERVAL'2 days',FALSE),
('eeee0000-0000-0000-0000-000000000016',
 'eeee0000-0000-0000-0000-000000000002','eeee0000-0000-0000-0000-000000000004',
 'gestionnaire','locataire','RE: Problème robinet cuisine','reparation',
 'Bonjour Marie, un plombier passera demain entre 9h et 12h.',
 'repondu',NOW()-INTERVAL'1 day',TRUE)
ON CONFLICT (id_message) DO NOTHING;

-- ÉTAPE 12 : Document (PK=id, schema de 06_complete_schema.sql)
INSERT INTO public.documents (id,nom,type_document,contrat_id,locataire_id,propriete_id,fichier_url,taille_octets,mime_type)
VALUES (
  'eeee0000-0000-0000-0000-000000000018',
  'Contrat de location — Seed Test','contrat',
  'eeee0000-0000-0000-0000-000000000008',
  (SELECT id_locataire FROM public.locataires WHERE user_id='eeee0000-0000-0000-0000-000000000004'),
  'eeee0000-0000-0000-0000-000000000007',
  'https://example.com/seed-contrat.pdf',250,'application/pdf'
) ON CONFLICT (id) DO NOTHING;

-- VÉRIFICATION
SELECT 'auth.users'    AS tbl, COUNT(*) AS n FROM auth.users           WHERE id::text          LIKE 'eeee%';
SELECT 'profiles'      AS tbl, COUNT(*) AS n FROM public.profiles      WHERE id::text          LIKE 'eeee%';
SELECT 'proprietaires' AS tbl, COUNT(*) AS n FROM public.proprietaires  WHERE user_id::text     LIKE 'eeee%';
SELECT 'locataires'    AS tbl, COUNT(*) AS n FROM public.locataires     WHERE user_id::text     LIKE 'eeee%';
SELECT 'proprietes'    AS tbl, COUNT(*) AS n FROM public.proprietes     WHERE id_propriete::text LIKE 'eeee%';
SELECT 'contrats'      AS tbl, COUNT(*) AS n FROM public.contrats       WHERE id_contrat::text  LIKE 'eeee%';
SELECT 'paiements'     AS tbl, COUNT(*) AS n FROM public.paiements      WHERE id_paiement::text LIKE 'eeee%';
SELECT 'factures'      AS tbl, COUNT(*) AS n FROM public.factures       WHERE id_facture::text  LIKE 'eeee%';
SELECT 'operations'    AS tbl, COUNT(*) AS n FROM public.operations     WHERE id_operation::text LIKE 'eeee%';
SELECT 'messages'      AS tbl, COUNT(*) AS n FROM public.messages       WHERE id_message::text  LIKE 'eeee%';
SELECT 'documents'     AS tbl, COUNT(*) AS n FROM public.documents      WHERE id::text          LIKE 'eeee%';

-- ============================================================
-- ⚠️  CLEANUP — Décommenter après validation
-- ============================================================
/*
DELETE FROM public.documents     WHERE id::text           LIKE 'eeee%';
DELETE FROM public.messages      WHERE id_message::text   LIKE 'eeee%';
DELETE FROM public.operations    WHERE id_operation::text LIKE 'eeee%';
DELETE FROM public.factures      WHERE id_facture::text   LIKE 'eeee%';
DELETE FROM public.paiements     WHERE id_paiement::text  LIKE 'eeee%';
DELETE FROM public.contrats      WHERE id_contrat::text   LIKE 'eeee%';
DELETE FROM public.proprietes    WHERE id_propriete::text LIKE 'eeee%';
DELETE FROM public.agents        WHERE id::text           LIKE 'eeee%';
DELETE FROM public.profiles      WHERE email              LIKE '%@test.ht';
DELETE FROM auth.users           WHERE email              LIKE '%@test.ht';
SELECT 'Seed supprimé ✓' AS status;
*/
