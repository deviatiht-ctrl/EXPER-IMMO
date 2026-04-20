-- ============================================================
-- EXPER IMMO - MIGRATION ADAPTIVE (Final)
-- Sa a verifye tout kolon anvan li ajoute yo
-- ============================================================

-- ============================================================
-- 1. AJOUTE KOLON MANKE NAN PROPRIETES
-- ============================================================
DO $$
BEGIN
    -- proprietaire_id (KLE ETRANGÈ)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'proprietaire_id') THEN
        ALTER TABLE proprietes ADD COLUMN proprietaire_id UUID;
        RAISE NOTICE 'Kolon proprietaire_id ajoute';
    END IF;
    
    -- images JSONB pou foto
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'images') THEN
        ALTER TABLE proprietes ADD COLUMN images JSONB DEFAULT '[]';
    END IF;
    
    -- documents JSONB
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'documents') THEN
        ALTER TABLE proprietes ADD COLUMN documents JSONB DEFAULT '[]';
    END IF;
    
    -- prix
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
    
    -- reference
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'reference') THEN
        ALTER TABLE proprietes ADD COLUMN reference VARCHAR(100);
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
    
    -- type_propriete (si pa egziste)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'type_propriete') THEN
        ALTER TABLE proprietes ADD COLUMN type_propriete VARCHAR(50);
    END IF;
    
    -- type_transaction (si pa egziste)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietes' AND column_name = 'type_transaction') THEN
        ALTER TABLE proprietes ADD COLUMN type_transaction VARCHAR(50);
    END IF;
END $$;

-- ============================================================
-- 2. AJOUTE KOLON id_proprietaire NAN PROPRIETAIRES
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'proprietaires' AND column_name = 'id_proprietaire') THEN
        
        ALTER TABLE proprietaires ADD COLUMN id_proprietaire UUID;
        UPDATE proprietaires SET id_proprietaire = id;
        ALTER TABLE proprietaires ADD CONSTRAINT uq_proprietaires_id_proprietaire UNIQUE (id_proprietaire);
        RAISE NOTICE 'id_proprietaire ajoute nan proprietaires';
    END IF;
END $$;

-- ============================================================
-- 3. DROP FOREIGN KEY KI PA KORÈK E KREYE YON LÒT
-- ============================================================
DO $$
DECLARE
    fk_exists BOOLEAN;
BEGIN
    -- Verifye si foreign key egziste
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'proprietes' 
        AND constraint_name = 'proprietes_proprietaire_id_fkey'
    ) INTO fk_exists;
    
    IF fk_exists THEN
        ALTER TABLE proprietes DROP CONSTRAINT proprietes_proprietaire_id_fkey;
        RAISE NOTICE 'Foreign key ki pa korèk DROP';
    END IF;
END $$;

-- Kreye foreign key kòrèk (si 2 tab yo gen done)
DO $$
DECLARE
    proprietaires_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO proprietaires_count FROM proprietaires;
    
    -- Selman kreye FK si gen done nan proprietaires
    IF proprietaires_count > 0 THEN
        -- Ranpli proprietaire_id si li NULL
        UPDATE proprietes 
        SET proprietaire_id = (SELECT id_proprietaire FROM proprietaires LIMIT 1)
        WHERE proprietaire_id IS NULL;
        
        -- Kreye foreign key
        ALTER TABLE proprietes
        ADD CONSTRAINT fk_proprietes_proprietaire 
        FOREIGN KEY (proprietaire_id) 
        REFERENCES proprietaires(id_proprietaire) 
        ON DELETE SET NULL;
        
        RAISE NOTICE 'Foreign key kreye';
    END IF;
END $$;

-- ============================================================
-- 4. LOT TAB YO (Create si pa egziste)
-- ============================================================

-- Paiements
CREATE TABLE IF NOT EXISTS paiements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propriete_id UUID,
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
    propriete_id UUID,
    locataire_id UUID,
    proprietaire_id UUID,
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
    propriete_id UUID,
    proprietaire_id UUID,
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
    createur_id UUID,
    type_createur VARCHAR(50),
    sujet VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    categorie VARCHAR(50),
    priorite VARCHAR(50) DEFAULT 'moyenne',
    statut VARCHAR(50) DEFAULT 'ouvert',
    reference VARCHAR(100) UNIQUE,
    assigne_a UUID,
    propriete_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ticket Messages
CREATE TABLE IF NOT EXISTS ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID REFERENCES tickets_support(id) ON DELETE CASCADE,
    auteur_id UUID,
    message TEXT NOT NULL,
    est_interne BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 5. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_proprietes_proprietaire ON proprietes(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_proprietes_statut ON proprietes(statut);
CREATE INDEX IF NOT EXISTS idx_paiements_propriete ON paiements(propriete_id);
CREATE INDEX IF NOT EXISTS idx_contrats_propriete ON contrats(propriete_id);
CREATE INDEX IF NOT EXISTS idx_tickets_createur ON tickets_support(createur_id);
CREATE INDEX IF NOT EXISTS idx_operations_proprietaire ON operations(proprietaire_id);

-- ============================================================
-- 6. TRIGGERS POU updated_at
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
-- 7. RLS - Row Level Security (Simple version)
-- ============================================================

-- Enable RLS
ALTER TABLE IF EXISTS proprietes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS contrats ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tickets_support ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow all" ON proprietes;
DROP POLICY IF EXISTS "Allow all" ON paiements;
DROP POLICY IF EXISTS "Allow all" ON contrats;
DROP POLICY IF EXISTS "Allow all" ON operations;
DROP POLICY IF EXISTS "Allow all" ON tickets_support;

-- Simple policies pou test (ou ka modifye pi ta)
CREATE POLICY "Allow all" ON proprietes FOR ALL USING (true);
CREATE POLICY "Allow all" ON paiements FOR ALL USING (true);
CREATE POLICY "Allow all" ON contrats FOR ALL USING (true);
CREATE POLICY "Allow all" ON operations FOR ALL USING (true);
CREATE POLICY "Allow all" ON tickets_support FOR ALL USING (true);

-- ============================================================
-- 8. STORAGE BUCKETS
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

-- ============================================================
-- 9. SEED DATA - Kreye yon pwopriyetè test si tab vid
-- ============================================================
DO $$
DECLARE
    proprietaires_count INTEGER;
    test_user_id UUID;
BEGIN
    SELECT COUNT(*) INTO proprietaires_count FROM proprietaires;
    
    -- Si pa gen pwopriyetè, kreye yon
    IF proprietaires_count = 0 THEN
        -- Pran premye user ki egziste
        SELECT id INTO test_user_id FROM auth.users LIMIT 1;
        
        IF test_user_id IS NOT NULL THEN
            INSERT INTO proprietaires (user_id, type_proprietaire, est_actif)
            VALUES (test_user_id, 'particulier', true);
            RAISE NOTICE 'Pwopriyetè test kreye pou user: %', test_user_id;
        END IF;
    END IF;
END $$;

-- ============================================================
-- FIN
-- ============================================================
