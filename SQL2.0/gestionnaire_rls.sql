-- ============================================================
-- EXPERIMMO — RLS Gestionnaire
-- Le gestionnaire supervise les propriétés, contrats, locataires
-- et opérations qui lui sont assignés
-- ============================================================

-- ── HELPER : évite la récursion infinie dans les policies profiles ──
-- Cette fonction tourne avec les droits du propriétaire (SECURITY DEFINER)
-- et contourne le RLS pour lire le rôle de l'utilisateur courant.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

-- ── PROPRIETES ───────────────────────────────────────────────
-- Gestionnaire: accès complet à toutes les propriétés actives
DROP POLICY IF EXISTS "proprietes_gest_all" ON public.proprietes;
CREATE POLICY "proprietes_gest_all"
    ON public.proprietes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role = 'gestionnaire'
        )
    );

-- ── CONTRATS ─────────────────────────────────────────────────
-- Gestionnaire voit tous les contrats
DROP POLICY IF EXISTS "contrats_gest_select" ON public.contrats;
CREATE POLICY "contrats_gest_select"
    ON public.contrats FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role = 'gestionnaire'
        )
    );

-- Gestionnaire peut créer et modifier des contrats
DROP POLICY IF EXISTS "contrats_gest_write" ON public.contrats;
CREATE POLICY "contrats_gest_write"
    ON public.contrats FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role = 'gestionnaire'
        )
    );

DROP POLICY IF EXISTS "contrats_gest_update" ON public.contrats;
CREATE POLICY "contrats_gest_update"
    ON public.contrats FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire')
        )
    );

-- ── PAIEMENTS ────────────────────────────────────────────────
-- Gestionnaire voit et enregistre tous les paiements
DROP POLICY IF EXISTS "paiements_gest_all" ON public.paiements;
CREATE POLICY "paiements_gest_all"
    ON public.paiements FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role = 'gestionnaire'
        )
    );

-- ── PROFILES (locataires & propriétaires) ────────────────────
-- Gestionnaire peut lire les profils des locataires et propriétaires
-- Utilise get_my_role() pour éviter la récursion infinie
DROP POLICY IF EXISTS "profiles_gest_read_others" ON public.profiles;
CREATE POLICY "profiles_gest_read_others"
    ON public.profiles FOR SELECT
    USING (
        role IN ('locataire', 'proprietaire')
        AND public.get_my_role() IN ('admin', 'gestionnaire')
    );

-- ── OPÉRATIONS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.operations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gestionnaire_id UUID REFERENCES public.profiles(id),
    propriete_id    UUID REFERENCES public.proprietes(id),
    contrat_id      UUID REFERENCES public.contrats(id),
    type_operation  TEXT NOT NULL,
    description     TEXT,
    montant         NUMERIC(12,2),
    statut          TEXT DEFAULT 'en_cours' CHECK (statut IN ('en_cours','terminé','annulé')),
    date_operation  DATE DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.operations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "operations_gest_all" ON public.operations;
CREATE POLICY "operations_gest_all"
    ON public.operations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire')
        )
    );

-- ── DOCUMENTS ────────────────────────────────────────────────
-- Gestionnaire gère tous les documents
DROP POLICY IF EXISTS "documents_gest_all" ON public.documents;
CREATE POLICY "documents_gest_all"
    ON public.documents FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire')
        )
    );

-- ── MESSAGES ─────────────────────────────────────────────────
-- Gestionnaire peut lire tous les messages dans son scope
DROP POLICY IF EXISTS "messages_gest_all" ON public.messages;
CREATE POLICY "messages_gest_all"
    ON public.messages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire')
        )
    );
