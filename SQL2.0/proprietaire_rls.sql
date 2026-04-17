-- ============================================================
-- EXPERIMMO — RLS Propriétaire
-- Politiques Row Level Security pour le portail propriétaire
-- ============================================================

-- ── PROFILES ─────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Chaque utilisateur voit et modifie uniquement son propre profil
DROP POLICY IF EXISTS "profiles_own_select" ON public.profiles;
CREATE POLICY "profiles_own_select"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_own_update" ON public.profiles;
CREATE POLICY "profiles_own_update"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ── PROPRIETES ───────────────────────────────────────────────
ALTER TABLE public.proprietes ENABLE ROW LEVEL SECURITY;

-- Lecture publique: propriétés disponibles visibles par tous
DROP POLICY IF EXISTS "proprietes_public_select" ON public.proprietes;
CREATE POLICY "proprietes_public_select"
    ON public.proprietes FOR SELECT
    USING (statut = 'disponible');

-- Propriétaire: voit toutes ses propriétés (tous statuts)
DROP POLICY IF EXISTS "proprietes_owner_select" ON public.proprietes;
CREATE POLICY "proprietes_owner_select"
    ON public.proprietes FOR SELECT
    USING (proprietaire_id = auth.uid());

-- Propriétaire: peut ajouter des propriétés
DROP POLICY IF EXISTS "proprietes_owner_insert" ON public.proprietes;
CREATE POLICY "proprietes_owner_insert"
    ON public.proprietes FOR INSERT
    WITH CHECK (proprietaire_id = auth.uid());

-- Propriétaire: peut modifier ses propres propriétés
DROP POLICY IF EXISTS "proprietes_owner_update" ON public.proprietes;
CREATE POLICY "proprietes_owner_update"
    ON public.proprietes FOR UPDATE
    USING (proprietaire_id = auth.uid())
    WITH CHECK (proprietaire_id = auth.uid());

-- Admin/gestionnaire: accès total
DROP POLICY IF EXISTS "proprietes_admin_all" ON public.proprietes;
CREATE POLICY "proprietes_admin_all"
    ON public.proprietes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire', 'assistante')
        )
    );

-- ── CONTRATS ─────────────────────────────────────────────────
ALTER TABLE public.contrats ENABLE ROW LEVEL SECURITY;

-- Propriétaire voit les contrats de ses propriétés
DROP POLICY IF EXISTS "contrats_owner_select" ON public.contrats;
CREATE POLICY "contrats_owner_select"
    ON public.contrats FOR SELECT
    USING (
        proprietaire_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.proprietes p
            WHERE p.id = contrats.propriete_id
              AND p.proprietaire_id = auth.uid()
        )
    );

-- Admin/gestionnaire voit tout
DROP POLICY IF EXISTS "contrats_admin_all" ON public.contrats;
CREATE POLICY "contrats_admin_all"
    ON public.contrats FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire', 'assistante')
        )
    );

-- ── PAIEMENTS ────────────────────────────────────────────────
ALTER TABLE public.paiements ENABLE ROW LEVEL SECURITY;

-- Propriétaire voit les paiements de ses propriétés
DROP POLICY IF EXISTS "paiements_owner_select" ON public.paiements;
CREATE POLICY "paiements_owner_select"
    ON public.paiements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.contrats c
            JOIN public.proprietes p ON p.id = c.propriete_id
            WHERE c.id = paiements.contrat_id
              AND p.proprietaire_id = auth.uid()
        )
    );

-- Admin voit et gère tout
DROP POLICY IF EXISTS "paiements_admin_all" ON public.paiements;
CREATE POLICY "paiements_admin_all"
    ON public.paiements FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire', 'assistante')
        )
    );

-- ── DOCUMENTS ────────────────────────────────────────────────
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "documents_owner_select" ON public.documents;
CREATE POLICY "documents_owner_select"
    ON public.documents FOR SELECT
    USING (
        proprietaire_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.contrats c
            JOIN public.proprietes p ON p.id = c.propriete_id
            WHERE c.id = documents.contrat_id
              AND p.proprietaire_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "documents_admin_all" ON public.documents;
CREATE POLICY "documents_admin_all"
    ON public.documents FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire')
        )
    );
