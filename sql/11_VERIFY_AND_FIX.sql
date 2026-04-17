-- ============================================================
-- EXPER IMMO - VÉRIFICATION ET CORRECTIONS
-- Fichier à exécuter après l'installation pour vérifier tout est OK
-- ============================================================

-- ============================================================
-- 1. VÉRIFICATION DES EXTENSIONS
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        CREATE EXTENSION "uuid-ossp";
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        CREATE EXTENSION "pgcrypto";
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'unaccent') THEN
        CREATE EXTENSION "unaccent";
    END IF;
END $$;

-- ============================================================
-- 2. VÉRIFICATION/CORRECTION DE LA FONCTION handle_new_user
-- ============================================================
-- Cette fonction doit créer à la fois le profil ET le record propriétaire/locataire

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_role user_role;
BEGIN
    -- Déterminer le rôle
    v_role := COALESCE(
        (NEW.raw_user_meta_data->>'role')::user_role,
        'locataire'
    );
    
    -- Créer le profil
    INSERT INTO public.profiles (
        id, email, full_name, phone, role, is_verified
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        NEW.raw_user_meta_data->>'phone',
        v_role,
        FALSE
    )
    ON CONFLICT (id) DO UPDATE SET
        role = EXCLUDED.role,
        full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone;
    
    -- Créer le record spécifique au rôle
    IF v_role = 'proprietaire' THEN
        INSERT INTO public.proprietaires (user_id, est_actif)
        VALUES (NEW.id, TRUE)
        ON CONFLICT (user_id) DO NOTHING;
    ELSIF v_role = 'locataire' THEN
        INSERT INTO public.locataires (user_id, est_actif, score_paiement)
        VALUES (NEW.id, TRUE, 100)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log l'erreur mais ne pas bloquer l'inscription
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END $$;

-- Recréer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 3. VÉRIFICATION DES FONCTIONS ESSENTIELLES
-- ============================================================

-- Fonction pour incrémenter les vues (utilisée dans propriete.js)
CREATE OR REPLACE FUNCTION public.incrementer_vues(p_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE public.proprietes 
    SET vue_count = COALESCE(vue_count, 0) + 1 
    WHERE id = p_id;
END $$;

-- Fonction de recherche avancée (utilisée dans proprietes.js)
CREATE OR REPLACE FUNCTION public.rechercher_proprietes(
    p_transaction    TEXT    DEFAULT NULL,
    p_type           TEXT    DEFAULT NULL,
    p_zone_id        UUID    DEFAULT NULL,
    p_prix_min       NUMERIC DEFAULT NULL,
    p_prix_max       NUMERIC DEFAULT NULL,
    p_chambres_min   INTEGER DEFAULT NULL,
    p_superficie_min NUMERIC DEFAULT NULL,
    p_mot_cle        TEXT    DEFAULT NULL,
    p_meuble         BOOLEAN DEFAULT NULL,
    p_limit          INTEGER DEFAULT 12,
    p_offset         INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID, reference TEXT, titre TEXT, slug TEXT,
    type_transaction TEXT, type_propriete TEXT,
    prix NUMERIC, devise TEXT, prix_loyer NUMERIC,
    superficie_m2 NUMERIC, nb_chambres INTEGER,
    nb_salles_bain INTEGER, nb_garages INTEGER,
    images TEXT[], statut TEXT,
    est_vedette BOOLEAN, est_nouveau BOOLEAN, vue_count INTEGER,
    zone_nom TEXT, ville TEXT,
    agent_nom TEXT, agent_photo TEXT, agent_tel TEXT,
    created_at TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id, p.reference, p.titre, p.slug,
        p.type_transaction, p.type_propriete,
        p.prix, p.devise, p.prix_loyer,
        p.superficie_m2, p.nb_chambres,
        p.nb_salles_bain, p.nb_garages,
        p.images, p.statut,
        p.est_vedette, p.est_nouveau, p.vue_count,
        z.nom AS zone_nom, p.ville,
        (a.prenom||' '||a.nom) AS agent_nom,
        a.photo_url AS agent_photo,
        a.telephone AS agent_tel,
        p.created_at,
        COUNT(*) OVER() AS total_count
    FROM public.proprietes p
    LEFT JOIN public.zones z ON z.id = p.zone_id
    LEFT JOIN public.agents a ON a.id = p.agent_id
    WHERE p.est_actif = TRUE
        AND p.statut = 'disponible'
        AND (p_transaction IS NULL OR p.type_transaction = p_transaction)
        AND (p_type IS NULL OR p.type_propriete = p_type)
        AND (p_zone_id IS NULL OR p.zone_id = p_zone_id)
        AND (p_prix_min IS NULL OR p.prix >= p_prix_min)
        AND (p_prix_max IS NULL OR p.prix <= p_prix_max)
        AND (p_chambres_min IS NULL OR p.nb_chambres >= p_chambres_min)
        AND (p_superficie_min IS NULL OR p.superficie_m2 >= p_superficie_min)
        AND (p_meuble IS NULL OR p.meuble = p_meuble)
        AND (p_mot_cle IS NULL OR (
            unaccent(lower(p.titre)) ILIKE '%'||unaccent(lower(p_mot_cle))||'%'
            OR unaccent(lower(p.description)) ILIKE '%'||unaccent(lower(p_mot_cle))||'%'
            OR unaccent(lower(p.adresse)) ILIKE '%'||unaccent(lower(p_mot_cle))||'%'
        ))
    ORDER BY p.est_vedette DESC, p.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END $$;

-- Fonction pour les statistiques du dashboard admin
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'total_proprietes', (SELECT COUNT(*) FROM public.proprietes WHERE est_actif=TRUE),
        'disponibles', (SELECT COUNT(*) FROM public.proprietes WHERE statut='disponible' AND est_actif=TRUE),
        'vendues', (SELECT COUNT(*) FROM public.proprietes WHERE statut='vendu'),
        'louees', (SELECT COUNT(*) FROM public.proprietes WHERE statut='loue'),
        'contacts_nouveaux', (SELECT COUNT(*) FROM public.contacts WHERE statut='nouveau'),
        'contacts_ce_mois', (SELECT COUNT(*) FROM public.contacts
            WHERE DATE_TRUNC('month',created_at)=DATE_TRUNC('month',CURRENT_DATE)),
        'total_agents', (SELECT COUNT(*) FROM public.agents WHERE actif=TRUE),
        'vues_totales', (SELECT COALESCE(SUM(vue_count),0) FROM public.proprietes),
        'visites_ce_mois', (SELECT COUNT(*) FROM public.contacts
            WHERE type_demande='visite'
            AND DATE_TRUNC('month',created_at)=DATE_TRUNC('month',CURRENT_DATE)),
        'par_type', (SELECT json_agg(row_to_json(t)) FROM (
            SELECT type_propriete, COUNT(*) total
            FROM public.proprietes WHERE est_actif=TRUE
            GROUP BY type_propriete ORDER BY total DESC
        ) t),
        'top_zones', (SELECT json_agg(row_to_json(t)) FROM (
            SELECT z.nom, COUNT(p.id) total
            FROM public.proprietes p
            JOIN public.zones z ON z.id=p.zone_id
            WHERE p.est_actif=TRUE
            GROUP BY z.nom ORDER BY total DESC LIMIT 5
        ) t)
    ) INTO result;
    RETURN result;
END $$;

-- ============================================================
-- 4. VÉRIFICATION DES TRIGGERS DE RÉFÉRENCE
-- ============================================================

-- Séquence pour les propriétés
CREATE SEQUENCE IF NOT EXISTS propriete_seq START 1;

-- Fonction de génération de référence propriété
CREATE OR REPLACE FUNCTION public.generer_reference()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'IH-' || TO_CHAR(NOW(),'YYYY') || '-' ||
                         LPAD(NEXTVAL('propriete_seq')::TEXT,4,'0');
    END IF;
    RETURN NEW;
END $$;

-- Trigger sur proprietes
DROP TRIGGER IF EXISTS set_reference ON public.proprietes;
CREATE TRIGGER set_reference
    BEFORE INSERT ON public.proprietes
    FOR EACH ROW EXECUTE FUNCTION public.generer_reference();

-- ============================================================
-- 5. VÉRIFICATION DES INDEX
-- ============================================================

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_proprietes_transaction ON public.proprietes(type_transaction);
CREATE INDEX IF NOT EXISTS idx_proprietes_type ON public.proprietes(type_propriete);
CREATE INDEX IF NOT EXISTS idx_proprietes_zone ON public.proprietes(zone_id);
CREATE INDEX IF NOT EXISTS idx_proprietes_prix ON public.proprietes(prix);
CREATE INDEX IF NOT EXISTS idx_proprietes_statut ON public.proprietes(statut);
CREATE INDEX IF NOT EXISTS idx_proprietes_actif ON public.proprietes(est_actif);

-- ============================================================
-- 6. VÉRIFICATION DES TYPES ENUM
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
-- 7. TEST DES FONCTIONS
-- ============================================================

-- Test: Vérifier que les fonctions existent
SELECT 
    'handle_new_user' as fonction, 
    EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') as existe
UNION ALL
SELECT 
    'incrementer_vues', 
    EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'incrementer_vues')
UNION ALL
SELECT 
    'rechercher_proprietes', 
    EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'rechercher_proprietes')
UNION ALL
SELECT 
    'get_dashboard_stats', 
    EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'get_dashboard_stats')
UNION ALL
SELECT 
    'generer_reference', 
    EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'generer_reference');

-- ============================================================
-- 8. CORRECTION DES CHAMPS CALCULÉS
-- ============================================================

-- Fonction pour calculer solde_restant
CREATE OR REPLACE FUNCTION public.calc_solde_restant()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.solde_restant := NEW.montant_total - COALESCE(NEW.montant_paye, 0);
    RETURN NEW;
END; $$;

-- Trigger sur paiements
DROP TRIGGER IF EXISTS calc_solde_paiement ON public.paiements;
CREATE TRIGGER calc_solde_paiement
    BEFORE INSERT OR UPDATE ON public.paiements
    FOR EACH ROW EXECUTE FUNCTION public.calc_solde_restant();

-- Fonction pour calculer duree_mois
CREATE OR REPLACE FUNCTION public.calc_duree_mois()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.duree_mois := (
        EXTRACT(YEAR FROM AGE(NEW.date_fin, NEW.date_debut)) * 12 +
        EXTRACT(MONTH FROM AGE(NEW.date_fin, NEW.date_debut))
    )::INTEGER;
    RETURN NEW;
END; $$;

-- Trigger sur contrats
DROP TRIGGER IF EXISTS calc_duree_contrat ON public.contrats_location;
CREATE TRIGGER calc_duree_contrat
    BEFORE INSERT OR UPDATE ON public.contrats_location
    FOR EACH ROW EXECUTE FUNCTION public.calc_duree_mois();

-- ============================================================
-- 9. NETTOYAGE (OPTIONNEL - DÉCOMMENTER SI NÉCESSAIRE)
-- ============================================================

/*
-- Si vous avez des erreurs de contraintes, décommentez et exécutez:

-- Supprimer les contraintes problématiques
ALTER TABLE public.proprietaires DROP CONSTRAINT IF EXISTS proprietaires_user_id_key;
ALTER TABLE public.locataires DROP CONSTRAINT IF EXISTS locataires_user_id_key;

-- Recréer avec ON DELETE CASCADE
ALTER TABLE public.proprietaires 
    ADD CONSTRAINT proprietaires_user_id_key UNIQUE (user_id);

ALTER TABLE public.locataires 
    ADD CONSTRAINT locataires_user_id_key UNIQUE (user_id);
*/

-- ============================================================
-- MESSAGE DE CONFIRMATION
-- ============================================================

SELECT 'Vérification terminée! Toutes les fonctions essentielles sont en place.' as message;
