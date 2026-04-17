-- ============================================================
-- EXPERIMMO — Table: parametres_site
-- Paramètres globaux du site gérés par l'admin
-- Un seul enregistrement autorisé (single-row settings table)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.parametres_site (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Informations entreprise
    nom_entreprise      TEXT NOT NULL DEFAULT 'EXPERIMMO',
    slogan              TEXT DEFAULT 'Votre Bien, Notre Mission',
    email               TEXT DEFAULT 'contact@experimmo.ht',
    telephone           TEXT DEFAULT '+509 3700-0000',
    whatsapp            TEXT DEFAULT '+509 3700-0000',
    adresse             TEXT DEFAULT 'Pétion-Ville, Haïti',
    description_footer  TEXT DEFAULT 'Votre partenaire de confiance pour l''achat, la vente et la location de propriétés en Haïti.',

    -- Réseaux sociaux
    facebook_url        TEXT DEFAULT '',
    instagram_url       TEXT DEFAULT '',
    twitter_url         TEXT DEFAULT '',
    linkedin_url        TEXT DEFAULT '',
    youtube_url         TEXT DEFAULT '',

    -- Commerce
    devise_defaut           TEXT DEFAULT 'USD' CHECK (devise_defaut IN ('USD', 'HTG')),
    commission_vente        NUMERIC(5,2) DEFAULT 5.00,
    commission_location     NUMERIC(5,2) DEFAULT 10.00,
    taux_change             NUMERIC(10,2) DEFAULT 132.50,
    duree_location_min      INTEGER DEFAULT 6,
    caution_mois            INTEGER DEFAULT 2,

    -- Notifications email
    notif_nouvelle_propriete    BOOLEAN DEFAULT true,
    notif_nouveau_contrat       BOOLEAN DEFAULT true,
    notif_paiement              BOOLEAN DEFAULT true,
    notif_message               BOOLEAN DEFAULT true,
    notif_inscription           BOOLEAN DEFAULT true,
    notif_loyer_retard          BOOLEAN DEFAULT true,

    -- Metadata
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Garantit qu'il n'y ait qu'une seule ligne
CREATE UNIQUE INDEX IF NOT EXISTS parametres_site_singleton
    ON public.parametres_site ((true));

-- Insérer la ligne par défaut si elle n'existe pas
INSERT INTO public.parametres_site (nom_entreprise)
VALUES ('EXPERIMMO')
ON CONFLICT DO NOTHING;

-- ── Trigger: updated_at automatique ──────────────────────────
CREATE OR REPLACE FUNCTION public.fn_update_parametres_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_parametres_site_updated ON public.parametres_site;
CREATE TRIGGER trg_parametres_site_updated
    BEFORE UPDATE ON public.parametres_site
    FOR EACH ROW EXECUTE FUNCTION public.fn_update_parametres_timestamp();

-- ── Row Level Security ────────────────────────────────────────
ALTER TABLE public.parametres_site ENABLE ROW LEVEL SECURITY;

-- Lecture publique (site-config.js sur toutes les pages)
DROP POLICY IF EXISTS "parametres_site_public_select" ON public.parametres_site;
CREATE POLICY "parametres_site_public_select"
    ON public.parametres_site FOR SELECT
    USING (true);

-- Écriture: admin seulement
DROP POLICY IF EXISTS "parametres_site_admin_write" ON public.parametres_site;
CREATE POLICY "parametres_site_admin_write"
    ON public.parametres_site FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
        )
    );
