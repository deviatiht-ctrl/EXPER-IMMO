-- ============================================================
-- STEP 2: FOREIGN KEYS, TAB, INDEX, RLS
-- Egzekite sa APRÈ step 1 fini san erè
-- ============================================================

-- 1. DROP FOREIGN KEY KI GEN PWOBLEM (si egziste)
ALTER TABLE proprietes 
DROP CONSTRAINT IF EXISTS proprietes_proprietaire_id_fkey;

ALTER TABLE proprietes 
DROP CONSTRAINT IF EXISTS fk_proprietes_proprietaire;

-- 2. REMPLI proprietaire_id nan proprietes si li NULL
-- (Pran premye id_proprietaires disponib)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM proprietaires LIMIT 1) THEN
        UPDATE proprietes 
        SET proprietaire_id = (SELECT id_proprietaire FROM proprietaires LIMIT 1)
        WHERE proprietaire_id IS NULL;
    END IF;
END $$;

-- 3. KREYE FOREIGN KEY
ALTER TABLE proprietes
ADD CONSTRAINT fk_proprietes_proprietaire 
FOREIGN KEY (proprietaire_id) 
REFERENCES proprietaires(id_proprietaire) 
ON DELETE SET NULL;

-- 4. KREYE LOT TAB YO
CREATE TABLE IF NOT EXISTS paiements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID REFERENCES proprietes(id),
    montant_total DECIMAL(15,2) NOT NULL,
    montant_paye DECIMAL(15,2) DEFAULT 0,
    statut VARCHAR(50) DEFAULT 'en_attente',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS contrats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID REFERENCES proprietes(id),
    type_contrat VARCHAR(50),
    statut VARCHAR(50) DEFAULT 'actif',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID REFERENCES proprietes(id),
    type_operation VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tickets_support (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sujet VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    statut VARCHAR(50) DEFAULT 'ouvert',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID REFERENCES tickets_support(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. INDEXES
CREATE INDEX IF NOT EXISTS idx_proprietes_proprietaire ON proprietes(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_proprietes_statut ON proprietes(statut);

-- 6. TRIGGERS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_proprietes_updated_at 
BEFORE UPDATE ON proprietes 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. RLS (Simple pou test)
ALTER TABLE proprietes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all" ON proprietes;
CREATE POLICY "Allow all" ON proprietes FOR ALL USING (true);

-- 8. STORAGE BUCKET
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('proprietes-photos', 'proprietes-photos', true, 10485760, 
        ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;
