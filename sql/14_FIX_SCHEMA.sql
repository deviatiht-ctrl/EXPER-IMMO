-- ============================================================
-- EXPER IMMO - FIX SCHEMA COMPLET (v14)
-- Corrige tous les décalages entre le JS et la base de données
-- Sûr et idempotent - peut être exécuté plusieurs fois
-- ============================================================

-- ============================================================
-- 1. TABLE ZONES - colonnes manquantes pour home.js
--    home.js : .eq('actif', true).order('ordre')
-- ============================================================
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS actif BOOLEAN DEFAULT TRUE;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS ordre INTEGER DEFAULT 1;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.zones ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================================
-- 2. TABLE AGENTS - colonnes manquantes pour agents.js
--    agents.js : actif, ordre, whatsapp, specialites,
--                experience_ans, nb_ventes, nb_locations
-- ============================================================
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS whatsapp TEXT;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS specialites TEXT[] DEFAULT '{}';
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS experience_ans INTEGER DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS nb_ventes INTEGER DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS nb_locations INTEGER DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
-- actif et ordre existent déjà dans 13, au cas où :
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS actif BOOLEAN DEFAULT TRUE;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS ordre INTEGER DEFAULT 1;

-- ============================================================
-- 3. TABLE PROFILES - date_naissance manquante pour locataires.js
-- ============================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_naissance DATE;

-- ============================================================
-- 4. TABLE PROPRIETES - corrections complètes
--    home.js  : est_vedette, type_transaction, superficie_m2, slug, prix
--    propriete.js : nb_garages, amenagements, slug, vue_count
--    propriete-form.js : prix_location, prix_vente, type_transaction,
--                        superficie_m2, nb_garages, est_vedette, slug
-- ============================================================
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS type_transaction TEXT DEFAULT 'location';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS prix_vente DECIMAL(15,2);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS prix_location DECIMAL(15,2);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS superficie_m2 DECIMAL(10,2);
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS nb_garages INTEGER DEFAULT 0;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS est_vedette BOOLEAN DEFAULT FALSE;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS amenagements TEXT[] DEFAULT '{}';
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS proprietaire_id UUID;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS vue_count INTEGER DEFAULT 0;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS reference TEXT;
ALTER TABLE public.proprietes ADD COLUMN IF NOT EXISTS type_propriete TEXT DEFAULT 'appartement';

-- Assurer unicité de slug (si pas déjà fait)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE tablename = 'proprietes' AND indexname = 'idx_proprietes_slug'
    ) THEN
        CREATE UNIQUE INDEX idx_proprietes_slug ON public.proprietes(slug) WHERE slug IS NOT NULL;
    END IF;
END $$;

-- ============================================================
-- 5. TABLE LOCATAIRES - colonnes manquantes pour locataires.js
-- ============================================================
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_urgence_nom TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_urgence_phone TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS contact_urgence_relation TEXT;
ALTER TABLE public.locataires ADD COLUMN IF NOT EXISTS nb_personnes INTEGER DEFAULT 1;

-- ============================================================
-- 6. TABLE CONTRATS_LOCATION - corrections pour contrats.js
--    - proprietaire_id était NOT NULL mais le form ne l'envoie pas
--    - clauses: le JS envoie 'clauses' mais la table avait 'conditions_speciales'
-- ============================================================
ALTER TABLE public.contrats_location ADD COLUMN IF NOT EXISTS clauses TEXT;
-- Rendre proprietaire_id optionnel
ALTER TABLE public.contrats_location ALTER COLUMN proprietaire_id DROP NOT NULL;

-- ============================================================
-- 7. TABLE PAIEMENTS - corrections pour paiements.js
--    - methode_paiement: JS envoie ce nom, table avait mode_paiement
--    - Plusieurs colonnes NOT NULL que le form simplifié n'envoie pas
-- ============================================================
ALTER TABLE public.paiements ADD COLUMN IF NOT EXISTS methode_paiement TEXT;

-- Rendre optionnels les champs non envoyés par le form admin
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN contrat_id   DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN locataire_id  DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN propriete_id  DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN mois          DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN annee         DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN periode_debut DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN periode_fin   DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.paiements ALTER COLUMN montant_loyer DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- ============================================================
-- 8. FUNCTION : incrementer_vues
--    propriete.js : supabaseClient.rpc('incrementer_vues', { p_id: prop.id })
-- ============================================================
CREATE OR REPLACE FUNCTION public.incrementer_vues(p_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.proprietes
    SET vue_count = COALESCE(vue_count, 0) + 1
    WHERE id = p_id;
END; $$;

-- ============================================================
-- 9. FUNCTION : rechercher_proprietes
--    proprietes.js : supabaseClient.rpc('rechercher_proprietes', {
--      p_transaction, p_type, p_prix_min, p_prix_max,
--      p_chambres_min, p_meuble, p_limit, p_offset })
--    Retourne : id, titre, slug, images, type_transaction, type_propriete,
--               prix, prix_location, prix_vente, devise, superficie_m2,
--               nb_chambres, nb_salles_bain, nb_garages, meuble,
--               adresse, ville, quartier, zone_nom, statut,
--               est_vedette, vue_count, created_at, total_count
-- ============================================================
CREATE OR REPLACE FUNCTION public.rechercher_proprietes(
    p_transaction  TEXT    DEFAULT NULL,
    p_type         TEXT    DEFAULT NULL,
    p_prix_min     NUMERIC DEFAULT NULL,
    p_prix_max     NUMERIC DEFAULT NULL,
    p_chambres_min INTEGER DEFAULT NULL,
    p_meuble       BOOLEAN DEFAULT NULL,
    p_zone_id      UUID    DEFAULT NULL,
    p_limit        INTEGER DEFAULT 12,
    p_offset       INTEGER DEFAULT 0
)
RETURNS TABLE (
    id              UUID,
    titre           TEXT,
    slug            TEXT,
    images          TEXT[],
    type_transaction TEXT,
    type_propriete  TEXT,
    prix            NUMERIC,
    prix_location   NUMERIC,
    prix_vente      NUMERIC,
    devise          TEXT,
    superficie_m2   NUMERIC,
    nb_chambres     INTEGER,
    nb_salles_bain  INTEGER,
    nb_garages      INTEGER,
    meuble          BOOLEAN,
    adresse         TEXT,
    ville           TEXT,
    quartier        TEXT,
    zone_nom        TEXT,
    statut          TEXT,
    est_vedette     BOOLEAN,
    vue_count       INTEGER,
    created_at      TIMESTAMPTZ,
    total_count     BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE
    v_total BIGINT;
BEGIN
    -- Compter le total filtré
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
    SELECT
        p.id,
        p.titre,
        p.slug,
        p.images,
        p.type_transaction,
        p.type_propriete,
        COALESCE(p.prix_location, p.prix_vente, p.prix)::NUMERIC,
        p.prix_location::NUMERIC,
        p.prix_vente::NUMERIC,
        p.devise,
        p.superficie_m2::NUMERIC,
        p.nb_chambres,
        p.nb_salles_bain,
        COALESCE(p.nb_garages, 0),
        COALESCE(p.meuble, FALSE),
        p.adresse,
        p.ville,
        p.quartier,
        z.nom,
        p.statut,
        COALESCE(p.est_vedette, FALSE),
        COALESCE(p.vue_count, 0),
        p.created_at,
        v_total
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

-- ============================================================
-- 10. FUNCTION : get_locataire_dashboard
--     locataire-dashboard.js : rpc('get_locataire_dashboard', { p_locataire_id })
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_locataire_dashboard(p_locataire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_contrat       RECORD;
    v_prochain_pay  RECORD;
    v_retards       BIGINT;
    result          JSON;
BEGIN
    -- Contrat actif
    SELECT
        cl.id, cl.reference, cl.date_debut, cl.date_fin, cl.loyer_mensuel,
        cl.statut,
        pr.titre  AS propriete_titre,
        pr.adresse AS propriete_adresse,
        (cl.date_fin - CURRENT_DATE) AS jours_restants
    INTO v_contrat
    FROM public.contrats_location cl
    JOIN public.proprietes pr ON pr.id = cl.propriete_id
    WHERE cl.locataire_id = p_locataire_id
      AND cl.statut = 'actif'
    ORDER BY cl.date_debut DESC
    LIMIT 1;

    -- Prochain paiement en attente
    SELECT id, montant_total AS montant, date_echeance, statut
    INTO v_prochain_pay
    FROM public.paiements
    WHERE locataire_id = p_locataire_id
      AND statut IN ('en_attente', 'en_retard')
    ORDER BY date_echeance ASC
    LIMIT 1;

    -- Nombre de paiements en retard
    SELECT COUNT(*) INTO v_retards
    FROM public.paiements
    WHERE locataire_id = p_locataire_id AND statut = 'en_retard';

    SELECT json_build_object(
        'contrat_actif',      row_to_json(v_contrat),
        'prochain_paiement',  row_to_json(v_prochain_pay),
        'paiements_retard',   v_retards
    ) INTO result;

    RETURN result;
END; $$;

-- ============================================================
-- 11. FUNCTION : get_proprietaire_dashboard
--     proprietaire-dashboard.js : rpc('get_proprietaire_dashboard', { p_proprietaire_id })
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_proprietaire_dashboard(p_proprietaire_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_total        BIGINT;
    v_louees       BIGINT;
    v_revenus      NUMERIC;
    v_occupation   NUMERIC;
    result         JSON;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM public.proprietes
    WHERE proprietaire_id = p_proprietaire_id AND est_actif = TRUE;

    SELECT COUNT(*) INTO v_louees
    FROM public.proprietes
    WHERE proprietaire_id = p_proprietaire_id AND statut = 'loue' AND est_actif = TRUE;

    SELECT COALESCE(SUM(p.montant_paye), 0) INTO v_revenus
    FROM public.paiements p
    JOIN public.contrats_location cl ON cl.id = p.contrat_id
    WHERE cl.proprietaire_id = p_proprietaire_id
      AND p.statut = 'paye'
      AND DATE_TRUNC('month', p.date_paiement) = DATE_TRUNC('month', CURRENT_DATE);

    v_occupation := CASE WHEN v_total > 0 THEN ROUND((v_louees::NUMERIC / v_total) * 100, 1) ELSE 0 END;

    SELECT json_build_object(
        'mes_proprietes',     v_total,
        'proprietes_louees',  v_louees,
        'revenus_ce_mois',    v_revenus,
        'taux_occupation',    v_occupation
    ) INTO result;

    RETURN result;
END; $$;

-- ============================================================
-- 12. RLS GRANT pour fonctions publiques
-- ============================================================
GRANT EXECUTE ON FUNCTION public.incrementer_vues(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rechercher_proprietes(TEXT,TEXT,NUMERIC,NUMERIC,INTEGER,BOOLEAN,UUID,INTEGER,INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_locataire_dashboard(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_proprietaire_dashboard(UUID) TO authenticated;

-- ============================================================
-- 11. VÉRIFICATION FINALE
-- ============================================================
SELECT
    'zones'              AS table_name, COUNT(*) AS colonnes FROM information_schema.columns WHERE table_schema='public' AND table_name='zones'
UNION ALL SELECT 'agents',        COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='agents'
UNION ALL SELECT 'profiles',      COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles'
UNION ALL SELECT 'proprietes',    COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='proprietes'
UNION ALL SELECT 'locataires',    COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='locataires'
UNION ALL SELECT 'contrats_location', COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='contrats_location'
UNION ALL SELECT 'paiements',     COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='paiements'
ORDER BY table_name;
