-- ============================================================
-- EXPERIMMO — RLS Locataire
-- Politiques Row Level Security pour le portail locataire
-- ============================================================

-- ── CONTRATS ─────────────────────────────────────────────────
-- (la table doit déjà avoir RLS activé — voir proprietaire_rls.sql)

-- Locataire voit uniquement son propre contrat
DROP POLICY IF EXISTS "contrats_tenant_select" ON public.contrats;
CREATE POLICY "contrats_tenant_select"
    ON public.contrats FOR SELECT
    USING (locataire_id = auth.uid());

-- ── PAIEMENTS ────────────────────────────────────────────────
-- Locataire voit ses propres paiements
DROP POLICY IF EXISTS "paiements_tenant_select" ON public.paiements;
CREATE POLICY "paiements_tenant_select"
    ON public.paiements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.contrats c
            WHERE c.id = paiements.contrat_id
              AND c.locataire_id = auth.uid()
        )
    );

-- ── FACTURES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.factures (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contrat_id      UUID REFERENCES public.contrats(id) ON DELETE CASCADE,
    locataire_id    UUID REFERENCES public.profiles(id),
    montant         NUMERIC(12,2) NOT NULL,
    date_emission   DATE DEFAULT CURRENT_DATE,
    date_echeance   DATE,
    statut          TEXT DEFAULT 'impayée' CHECK (statut IN ('payée','impayée','en_retard','annulée')),
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.factures ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "factures_tenant_select" ON public.factures;
CREATE POLICY "factures_tenant_select"
    ON public.factures FOR SELECT
    USING (locataire_id = auth.uid());

DROP POLICY IF EXISTS "factures_admin_all" ON public.factures;
CREATE POLICY "factures_admin_all"
    ON public.factures FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire', 'assistante')
        )
    );

-- ── ÉCHÉANCES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.echeances (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contrat_id      UUID REFERENCES public.contrats(id) ON DELETE CASCADE,
    date_echeance   DATE NOT NULL,
    montant         NUMERIC(12,2) NOT NULL,
    statut          TEXT DEFAULT 'à_venir' CHECK (statut IN ('à_venir','payée','en_retard')),
    mois_concerne   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.echeances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "echeances_tenant_select" ON public.echeances;
CREATE POLICY "echeances_tenant_select"
    ON public.echeances FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.contrats c
            WHERE c.id = echeances.contrat_id
              AND c.locataire_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "echeances_admin_all" ON public.echeances;
CREATE POLICY "echeances_admin_all"
    ON public.echeances FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire', 'assistante')
        )
    );

-- ── DOCUMENTS ────────────────────────────────────────────────
-- Locataire voit ses propres documents
DROP POLICY IF EXISTS "documents_tenant_select" ON public.documents;
CREATE POLICY "documents_tenant_select"
    ON public.documents FOR SELECT
    USING (
        locataire_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.contrats c
            WHERE c.id = documents.contrat_id
              AND c.locataire_id = auth.uid()
        )
    );

-- ── MESSAGES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id   UUID REFERENCES public.profiles(id),
    receiver_id UUID REFERENCES public.profiles(id),
    contenu     TEXT NOT NULL,
    lu          BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Si la table existait déjà sans ces colonnes, on les ajoute
ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS sender_id   UUID REFERENCES public.profiles(id),
    ADD COLUMN IF NOT EXISTS receiver_id UUID REFERENCES public.profiles(id),
    ADD COLUMN IF NOT EXISTS contenu     TEXT,
    ADD COLUMN IF NOT EXISTS lu          BOOLEAN DEFAULT false;

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "messages_participant_select" ON public.messages;
CREATE POLICY "messages_participant_select"
    ON public.messages FOR SELECT
    USING (sender_id = auth.uid() OR receiver_id = auth.uid());

DROP POLICY IF EXISTS "messages_sender_insert" ON public.messages;
CREATE POLICY "messages_sender_insert"
    ON public.messages FOR INSERT
    WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "messages_receiver_update" ON public.messages;
CREATE POLICY "messages_receiver_update"
    ON public.messages FOR UPDATE
    USING (receiver_id = auth.uid());

DROP POLICY IF EXISTS "messages_admin_all" ON public.messages;
CREATE POLICY "messages_admin_all"
    ON public.messages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role IN ('admin', 'gestionnaire', 'assistante')
        )
    );
