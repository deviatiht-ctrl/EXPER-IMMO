-- ============================================================
-- EXPERIMMO — Mise à jour table profiles
-- Ajout des colonnes nécessaires pour l'inscription complète
-- À exécuter dans Supabase SQL Editor
-- ============================================================

-- ── Nouvelles colonnes profil personnel ──────────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS adresse             TEXT,
    ADD COLUMN IF NOT EXISTS date_naissance      DATE,
    ADD COLUMN IF NOT EXISTS nationalite         TEXT DEFAULT 'Haïtienne',
    ADD COLUMN IF NOT EXISTS genre               TEXT CHECK (genre IN ('homme','femme','autre')),
    ADD COLUMN IF NOT EXISTS profession          TEXT,
    ADD COLUMN IF NOT EXISTS employeur           TEXT;

-- ── Pièce d'identité ─────────────────────────────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS piece_identite_type      TEXT
        CHECK (piece_identite_type IN ('carte_nationale','permis','passeport','autre')),
    ADD COLUMN IF NOT EXISTS piece_identite_numero    TEXT,
    ADD COLUMN IF NOT EXISTS piece_identite_recto_url TEXT,
    ADD COLUMN IF NOT EXISTS piece_identite_verso_url TEXT;

-- ── Colonnes propriétaire ─────────────────────────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS type_proprietaire   TEXT
        CHECK (type_proprietaire IN ('particulier','entreprise','syndic')),
    ADD COLUMN IF NOT EXISTS nom_entreprise      TEXT;

-- ── Statut dossier (validation admin) ────────────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS statut_dossier      TEXT DEFAULT 'en_attente'
        CHECK (statut_dossier IN ('en_attente','valide','rejete','incomplet'));

-- ── Timestamps ───────────────────────────────────────────────
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ DEFAULT NOW();

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- SUPABASE STORAGE — Bucket documents-identite
-- ============================================================

-- Créer le bucket (privé par défaut)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'documents-identite',
    'documents-identite',
    false,
    5242880,  -- 5 Mo
    ARRAY['image/jpeg','image/jpg','image/png','image/webp','application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit    = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ── Policies Storage ─────────────────────────────────────────
-- Utilisateur peut uploader ses propres documents (path = {userId}/...)
DROP POLICY IF EXISTS "identite_user_upload" ON storage.objects;
CREATE POLICY "identite_user_upload"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents-identite'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Utilisateur peut voir ses propres documents
DROP POLICY IF EXISTS "identite_user_select" ON storage.objects;
CREATE POLICY "identite_user_select"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'documents-identite'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR EXISTS (
                SELECT 1 FROM public.profiles p
                WHERE p.id = auth.uid()
                  AND p.role IN ('admin', 'gestionnaire')
            )
        )
    );

-- Admin/gestionnaire peut tout voir et supprimer
DROP POLICY IF EXISTS "identite_admin_all" ON storage.objects;
CREATE POLICY "identite_admin_all"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'documents-identite'
        AND public.get_my_role() IN ('admin', 'gestionnaire')
    );

-- ============================================================
-- RLS policy : chaque utilisateur peut upsert son propre profil
-- (nécessaire pour le upsert depuis auth.js après inscription)
-- ============================================================
DROP POLICY IF EXISTS "profiles_own_insert" ON public.profiles;
CREATE POLICY "profiles_own_insert"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_own_upsert" ON public.profiles;
CREATE POLICY "profiles_own_upsert"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- Vue admin pour suivre les dossiers en attente
-- ============================================================
CREATE OR REPLACE VIEW public.dossiers_inscription AS
SELECT
    p.id,
    p.full_name,
    p.email,
    p.phone,
    p.role,
    p.adresse,
    p.date_naissance,
    p.piece_identite_type,
    p.piece_identite_numero,
    p.piece_identite_recto_url,
    p.piece_identite_verso_url,
    p.statut_dossier,
    p.created_at
FROM public.profiles p
ORDER BY p.created_at DESC;
