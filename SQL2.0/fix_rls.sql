-- ============================================================
-- EXPERIMMO — FIX RLS (fix_rls.sql)
-- Corrige les politiques RLS cassées après renommage
-- contrats.id → id_contrat
-- À exécuter dans Supabase SQL Editor IMMÉDIATEMENT
-- ============================================================

-- ── PAIEMENTS : c.id → c.id_contrat ─────────────────────────
DROP POLICY IF EXISTS "paiements_tenant_select" ON public.paiements;
CREATE POLICY "paiements_tenant_select"
    ON public.paiements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.contrats c
            WHERE c.id_contrat = paiements.contrat_id
              AND c.locataire_id = auth.uid()
        )
    );

-- ── ECHEANCES : c.id → c.id_contrat ─────────────────────────
DROP POLICY IF EXISTS "echeances_tenant_select" ON public.echeances;
CREATE POLICY "echeances_tenant_select"
    ON public.echeances FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.contrats c
            WHERE c.id_contrat = echeances.contrat_id
              AND c.locataire_id = auth.uid()
        )
    );

-- ── DOCUMENTS : c.id → c.id_contrat ─────────────────────────
DROP POLICY IF EXISTS "documents_tenant_select" ON public.documents;
CREATE POLICY "documents_tenant_select"
    ON public.documents FOR SELECT
    USING (
        locataire_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.contrats c
            WHERE c.id_contrat = documents.contrat_id
              AND c.locataire_id = auth.uid()
        )
    );

-- ── PROFILES : s'assurer que le user voit son propre profil ──
DROP POLICY IF EXISTS "profiles_self_select" ON public.profiles;
CREATE POLICY "profiles_self_select"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles;
CREATE POLICY "profiles_self_update"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());

-- ── Recharger le cache PostgREST ─────────────────────────────
NOTIFY pgrst, 'reload schema';

SELECT 'RLS corrigé + schema rechargé ✓' AS status;
