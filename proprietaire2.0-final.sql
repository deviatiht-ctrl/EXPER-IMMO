-- ============================================================
-- EXPER IMMO - MIGRATION FINAL (Base sou sa ki egziste)
-- Daprè check ou fè: proprietaires gen id_proprietaire kòm PK
-- ============================================================

-- ============================================================
-- 1. DROPPING PROBLEM FOREIGN KEY
-- ============================================================
-- Drop foreign key ki refere id_proprietaire ki pa egziste
ALTER TABLE IF EXISTS proprietes 
DROP CONSTRAINT IF EXISTS proprietes_proprietaire_id_fkey;

-- ============================================================
-- 2. AJOUTE KOLON id_proprietaire NAN PROPRIETAIRES SI PA EGZISTE
-- ============================================================
DO $$
BEGIN
    -- Verifye si kolon id_proprietaire egziste nan proprietaires
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietaires' AND column_name = 'id_proprietaire') THEN
        
        -- Ajoute kolon an
        ALTER TABLE proprietaires ADD COLUMN id_proprietaire UUID;
        
        -- Ranpli ak vale id genyen deja
        UPDATE proprietaires SET id_proprietaire = id;
        
        -- Fè li UNIQUE
        ALTER TABLE proprietaires ADD CONSTRAINT uq_proprietaires_id_proprietaire UNIQUE (id_proprietaire);
        
        RAISE NOTICE 'Kolon id_proprietaire ajoute e ranpli';
    END IF;
END $$;

-- ============================================================
-- 3. AJOUTE KOLON KI MANKE NAN PROPRIETES
-- ============================================================
DO $$
BEGIN
    -- images JSONB pou foto yo
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'images') THEN
        ALTER TABLE proprietes ADD COLUMN images JSONB DEFAULT '[]';
    END IF;
    
    -- documents JSONB
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'documents') THEN
        ALTER TABLE proprietes ADD COLUMN documents JSONB DEFAULT '[]';
    END IF;
    
    -- prix (pou compatibilite)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'prix') THEN
        ALTER TABLE proprietes ADD COLUMN prix DECIMAL(15,2) DEFAULT 0;
    END IF;
    
    -- statut_bien
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'statut_bien') THEN
        ALTER TABLE proprietes ADD COLUMN statut_bien VARCHAR(50);
    END IF;
    
    -- annee_construction
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'annee_construction') THEN
        ALTER TABLE proprietes ADD COLUMN annee_construction INTEGER;
    END IF;
    
    -- reference UNIQUE
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'reference') THEN
        ALTER TABLE proprietes ADD COLUMN reference VARCHAR(100);
        -- Fè li UNIQUE si pa gen doublon
        ALTER TABLE proprietes ADD CONSTRAINT uq_proprietes_reference UNIQUE (reference);
    END IF;
    
    -- est_actif
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'est_actif') THEN
        ALTER TABLE proprietes ADD COLUMN est_actif BOOLEAN DEFAULT true;
    END IF;
    
    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'updated_at') THEN
        ALTER TABLE proprietes ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- proprietaire_id si pa egziste
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'proprietaire_id') THEN
        ALTER TABLE proprietes ADD COLUMN proprietaire_id UUID;
    END IF;
END $$;

-- ============================================================
-- 4. KREYE FOREIGN KEY KORÈK
-- ============================================================
-- Kreye foreign key ki refere proprietaires.id_proprietaire
ALTER TABLE proprietes
ADD CONSTRAINT fk_proprietes_proprietaire 
FOREIGN KEY (proprietaire_id) 
REFERENCES proprietaires(id_proprietaire) 
ON DELETE CASCADE;

-- ============================================================
-- 5. LOT TAB YO (Si yo pa egziste)
-- ============================================================

-- Paiements
CREATE TABLE IF NOT EXISTS paiements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID REFERENCES proprietes(id),
    locataire_id UUID,
    contrat_id UUID,
    montant_total DECIMAL(15,2) NOT NULL,
    montant_paye DECIMAL(15,2) DEFAULT 0,
    statut VARCHAR(50) DEFAULT 'en_attente',
    mois INTEGER,
    annee INTEGER,
    jours_retard INTEGER DEFAULT 0,
    date_echeance DATE,
    date_paiement TIMESTAMP WITH TIME ZONE,
    methode_paiement VARCHAR(50),
    reference_paiement VARCHAR(255),
    notes TEXT,
    devise VARCHAR(3) DEFAULT 'HTG',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contrats
CREATE TABLE IF NOT EXISTS contrats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID REFERENCES proprietes(id),
    locataire_id UUID,
    proprietaire_id UUID REFERENCES proprietaires(id_proprietaire),
    type_contrat VARCHAR(50) NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE,
    loyer_mensuel DECIMAL(15,2),
    depot_garantie DECIMAL(15,2),
    honoraires_gestion DECIMAL(10,2),
    statut VARCHAR(50) DEFAULT 'actif',
    tacite_reconduction BOOLEAN DEFAULT false,
    document_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Operations
CREATE TABLE IF NOT EXISTS operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID REFERENCES proprietes(id),
    proprietaire_id UUID REFERENCES proprietaires(id_proprietaire),
    type_operation VARCHAR(100) NOT NULL,
    description TEXT,
    montant DECIMAL(15,2),
    date_operation DATE DEFAULT CURRENT_DATE,
    statut VARCHAR(50) DEFAULT 'en_cours',
    documents JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tickets Support
CREATE TABLE IF NOT EXISTS tickets_support (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    createur_id UUID REFERENCES auth.users(id),
    type_createur VARCHAR(50),
    sujet VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    categorie VARCHAR(50),
    priorite VARCHAR(50) DEFAULT 'moyenne',
    statut VARCHAR(50) DEFAULT 'ouvert',
    reference VARCHAR(100) UNIQUE,
    assigne_a UUID,
    propriete_id UUID REFERENCES proprietes(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ticket Messages
CREATE TABLE IF NOT EXISTS ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID REFERENCES tickets_support(id) ON DELETE CASCADE,
    auteur_id UUID REFERENCES auth.users(id),
    message TEXT NOT NULL,
    est_interne BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 6. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_proprietes_proprietaire ON proprietes(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_proprietes_statut ON proprietes(statut);
CREATE INDEX IF NOT EXISTS idx_paiements_propriete ON paiements(propriete_id);
CREATE INDEX IF NOT EXISTS idx_contrats_propriete ON contrats(propriete_id);
CREATE INDEX IF NOT EXISTS idx_contrats_proprietaire ON contrats(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_tickets_createur ON tickets_support(createur_id);
CREATE INDEX IF NOT EXISTS idx_operations_proprietaire ON operations(proprietaire_id);

-- ============================================================
-- 7. TRIGGERS POU updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
DECLARE
    tables CURSOR FOR 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('proprietes', 'proprietaires', 'paiements', 'contrats', 'operations', 'tickets_support');
BEGIN
    FOR table_record IN tables LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = table_record.table_name AND column_name = 'updated_at') THEN
            EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON %I', table_record.table_name, table_record.table_name);
            EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', table_record.table_name, table_record.table_name);
        END IF;
    END LOOP;
END $$;

-- ============================================================
-- 8. RLS - Row Level Security
-- ============================================================

-- Enable RLS
ALTER TABLE IF EXISTS proprietes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS contrats ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tickets_support ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow owner access" ON proprietes;
DROP POLICY IF EXISTS "Allow owner payments" ON paiements;
DROP POLICY IF EXISTS "Allow owner contracts" ON contrats;
DROP POLICY IF EXISTS "Allow owner operations" ON operations;
DROP POLICY IF EXISTS "Allow owner tickets" ON tickets_support;

-- Policy pou proprietes (check si user se proprietaire via proprietaires tab)
CREATE POLICY "Allow owner access" ON proprietes
    FOR ALL
    USING (
        proprietaire_id IN (SELECT id_proprietaire FROM proprietaires WHERE user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM auth.users WHERE id = auth.uid() 
            AND (raw_user_meta_data->>'role' IN ('admin', 'gestionnaire') OR raw_user_meta_data->>'role' = 'admin')
        )
    );

-- Policy pou paiements
CREATE POLICY "Allow owner payments" ON paiements
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM proprietes p 
            JOIN proprietaires pr ON pr.id_proprietaire = p.proprietaire_id
            WHERE p.id = paiements.propriete_id AND pr.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM auth.users WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
        )
    );

-- Policy pou contrats
CREATE POLICY "Allow owner contracts" ON contrats
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM proprietaires pr 
            WHERE pr.id_proprietaire = contrats.proprietaire_id AND pr.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM auth.users WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
        )
    );

-- Policy pou operations
CREATE POLICY "Allow owner operations" ON operations
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM proprietaires pr 
            WHERE pr.id_proprietaire = operations.proprietaire_id AND pr.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM auth.users WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
        )
    );

-- Policy pou tickets
CREATE POLICY "Allow owner tickets" ON tickets_support
    FOR ALL
    USING (
        createur_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
        )
    );

-- ============================================================
-- 9. STORAGE BUCKETS
-- ============================================================

-- Kreye bucket pou foto
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'proprietes-photos',
    'proprietes-photos',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Public read photos" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload photos" ON storage.objects;
DROP POLICY IF EXISTS "Auth delete photos" ON storage.objects;

CREATE POLICY "Public read photos" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'proprietes-photos');

CREATE POLICY "Auth upload photos" ON storage.objects
    FOR INSERT
    WITH CHECK (bucket_id = 'proprietes-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Auth delete photos" ON storage.objects
    FOR DELETE
    USING (bucket_id = 'proprietes-photos' AND auth.role() = 'authenticated');

-- ============================================================
-- 10. FONKSYON POU DASHBOARD (adapte ak id_proprietaire)
-- ============================================================

CREATE OR REPLACE FUNCTION get_proprietaire_stats(user_uuid UUID)
RETURNS TABLE (
    total_biens BIGINT,
    en_gestion BIGINT,
    disponibles BIGINT,
    loues BIGINT,
    contrats_actifs BIGINT
) AS $$
DECLARE
    prop_id UUID;
BEGIN
    -- Jwenn id_proprietaire pou user sa a
    SELECT id_proprietaire INTO prop_id FROM proprietaires WHERE user_id = user_uuid;
    
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_biens,
        COUNT(*) FILTER (WHERE statut_bien = 'gestion')::BIGINT as en_gestion,
        COUNT(*) FILTER (WHERE statut = 'disponible')::BIGINT as disponibles,
        COUNT(*) FILTER (WHERE statut = 'loue')::BIGINT as loues,
        (SELECT COUNT(*) FROM contrats WHERE proprietaire_id = prop_id AND statut = 'actif')::BIGINT as contrats_actifs
    FROM proprietes
    WHERE proprietaire_id = prop_id AND est_actif = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FIN
-- ============================================================
