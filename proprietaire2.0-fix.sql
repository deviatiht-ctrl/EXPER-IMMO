-- ============================================================
-- EXPER IMMO - MIGRATION FIX (Adaptive)
-- Sa a verifye sa ki egziste deja e adapte ak li
-- ============================================================

-- ============================================================
-- 1. DETECTE AK ADAPTE TAB EXISTANT YO
-- ============================================================

-- Premye, ann wè ki kolon ki egziste nan tab proprietes
DO $$
DECLARE
    has_id_propriete BOOLEAN;
    has_id UUID;
    pk_column TEXT;
BEGIN
    -- Verifye si kolon id_propriete egziste
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'proprietes' AND column_name = 'id_propriete'
    ) INTO has_id_propriete;
    
    -- Verifye si kolon id senp egziste
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'proprietes' AND column_name = 'id'
    ) INTO has_id;
    
    -- DETERMINE ki kolon PRIMARY KEY la
    SELECT column_name INTO pk_column
    FROM information_schema.key_column_usage kcu
    JOIN information_schema.table_constraints tc ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'proprietes' 
    AND tc.constraint_type = 'PRIMARY KEY'
    LIMIT 1;
    
    RAISE NOTICE 'PK column found: %', pk_column;
    
    -- Si pa gen tab ditou, kreye li avèk id_propriete
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'proprietes') THEN
        CREATE TABLE proprietes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            id_propriete UUID DEFAULT gen_random_uuid(),
            titre VARCHAR(255) NOT NULL,
            reference VARCHAR(100) UNIQUE,
            type_propriete VARCHAR(50) NOT NULL,
            type_transaction VARCHAR(50) NOT NULL,
            statut VARCHAR(50) DEFAULT 'disponible',
            statut_bien VARCHAR(50),
            adresse TEXT NOT NULL,
            ville VARCHAR(100) NOT NULL,
            zone_id UUID,
            superficie_m2 DECIMAL(10,2),
            nb_chambres INTEGER,
            nb_salles_bain INTEGER,
            nb_etages INTEGER,
            annee_construction INTEGER,
            prix_vente DECIMAL(15,2),
            prix_location DECIMAL(15,2),
            prix DECIMAL(15,2) DEFAULT 0,
            devise VARCHAR(3) DEFAULT 'HTG',
            description TEXT,
            proprietaire_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            est_actif BOOLEAN DEFAULT true,
            images JSONB DEFAULT '[]',
            documents JSONB DEFAULT '[]',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Table proprietes kreye avèk id (UUID) + id_propriete';
        
    ELSE
        -- Tab egziste, ajoute kolon ki manke selman
        RAISE NOTICE 'Table proprietes deja egziste, ajoute kolon ki manke...';
        
        -- Ajoute id_propriete si li pa egziste
        IF NOT has_id_propriete THEN
            ALTER TABLE proprietes ADD COLUMN id_propriete UUID DEFAULT gen_random_uuid();
            RAISE NOTICE 'Kolon id_propriete ajoute';
        END IF;
        
        -- Ajoute lot kolon yo si yo pa egziste
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'images') THEN
            ALTER TABLE proprietes ADD COLUMN images JSONB DEFAULT '[]';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'documents') THEN
            ALTER TABLE proprietes ADD COLUMN documents JSONB DEFAULT '[]';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'prix') THEN
            ALTER TABLE proprietes ADD COLUMN prix DECIMAL(15,2) DEFAULT 0;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'statut_bien') THEN
            ALTER TABLE proprietes ADD COLUMN statut_bien VARCHAR(50);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'annee_construction') THEN
            ALTER TABLE proprietes ADD COLUMN annee_construction INTEGER;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'reference') THEN
            ALTER TABLE proprietes ADD COLUMN reference VARCHAR(100) UNIQUE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'est_actif') THEN
            ALTER TABLE proprietes ADD COLUMN est_actif BOOLEAN DEFAULT true;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'updated_at') THEN
            ALTER TABLE proprietes ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        END IF;
        
        RAISE NOTICE 'Kolon ajoute avek siksè';
    END IF;
END $$;

-- ============================================================
-- 2. TABLE PROPRIETAIRES (verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'proprietaires') THEN
        CREATE TABLE proprietaires (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
            type_proprietaire VARCHAR(50),
            nom_entreprise VARCHAR(255),
            siret VARCHAR(100),
            nombre_biens INTEGER DEFAULT 0,
            est_actif BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Table proprietaires kreye';
    ELSE
        -- Ajoute kolon ki manke
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietaires' AND column_name = 'type_proprietaire') THEN
            ALTER TABLE proprietaires ADD COLUMN type_proprietaire VARCHAR(50);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietaires' AND column_name = 'nom_entreprise') THEN
            ALTER TABLE proprietaires ADD COLUMN nom_entreprise VARCHAR(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietaires' AND column_name = 'updated_at') THEN
            ALTER TABLE proprietaires ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        END IF;
    END IF;
END $$;

-- ============================================================
-- 3. LOT TAB YO
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
    propriete_id UUID REFERENCES proprietes(id),
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
    createur_id UUID REFERENCES auth.users(id),
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
    auteur_id UUID REFERENCES auth.users(id),
    message TEXT NOT NULL,
    est_interne BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 4. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_proprietes_proprietaire ON proprietes(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_proprietes_statut ON proprietes(statut);
CREATE INDEX IF NOT EXISTS idx_paiements_propriete ON paiements(propriete_id);
CREATE INDEX IF NOT EXISTS idx_contrats_propriete ON contrats(propriete_id);
CREATE INDEX IF NOT EXISTS idx_tickets_createur ON tickets_support(createur_id);
CREATE INDEX IF NOT EXISTS idx_operations_proprietaire ON operations(proprietaire_id);

-- ============================================================
-- 5. TRIGGERS POU updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplike trigger sou tout tab
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
-- 6. RLS - Row Level Security
-- ============================================================

-- Enable RLS
ALTER TABLE IF EXISTS proprietes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS contrats ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tickets_support ENABLE ROW LEVEL SECURITY;

-- Fonksyon pou verifye pwopriyetè
CREATE OR REPLACE FUNCTION is_property_owner(prop_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM proprietes 
        WHERE id = prop_id AND proprietaire_id = user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy pou proprietes
DROP POLICY IF EXISTS "Allow owner access" ON proprietes;
CREATE POLICY "Allow owner access" ON proprietes
    FOR ALL
    USING (proprietaire_id = auth.uid() OR EXISTS (
        SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
    ));

-- Policy pou paiements
DROP POLICY IF EXISTS "Allow owner payments" ON paiements;
CREATE POLICY "Allow owner payments" ON paiements
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM proprietes p WHERE p.id = paiements.propriete_id AND p.proprietaire_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
    ));

-- Policy pou contrats
DROP POLICY IF EXISTS "Allow owner contracts" ON contrats;
CREATE POLICY "Allow owner contracts" ON contrats
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM proprietes p WHERE p.id = contrats.propriete_id AND p.proprietaire_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
    ));

-- Policy pou tickets
DROP POLICY IF EXISTS "Allow owner tickets" ON tickets_support;
CREATE POLICY "Allow owner tickets" ON tickets_support
    FOR ALL
    USING (createur_id = auth.uid() OR EXISTS (
        SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('admin', 'gestionnaire')
    ));

-- ============================================================
-- 7. STORAGE BUCKETS
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

-- Policy pou storage
DROP POLICY IF EXISTS "Public read photos" ON storage.objects;
CREATE POLICY "Public read photos" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'proprietes-photos');

DROP POLICY IF EXISTS "Auth upload photos" ON storage.objects;
CREATE POLICY "Auth upload photos" ON storage.objects
    FOR INSERT
    WITH CHECK (bucket_id = 'proprietes-photos' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth delete photos" ON storage.objects;
CREATE POLICY "Auth delete photos" ON storage.objects
    FOR DELETE
    USING (bucket_id = 'proprietes-photos' AND auth.role() = 'authenticated');

-- ============================================================
-- 8. FONKSYON POU DASHBOARD
-- ============================================================

CREATE OR REPLACE FUNCTION get_proprietaire_stats(user_uuid UUID)
RETURNS TABLE (
    total_biens BIGINT,
    en_gestion BIGINT,
    disponibles BIGINT,
    loues BIGINT,
    contrats_actifs BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_biens,
        COUNT(*) FILTER (WHERE statut_bien = 'gestion')::BIGINT as en_gestion,
        COUNT(*) FILTER (WHERE statut = 'disponible')::BIGINT as disponibles,
        COUNT(*) FILTER (WHERE statut = 'loue')::BIGINT as loues,
        (SELECT COUNT(*) FROM contrats c JOIN proprietes p ON p.id = c.propriete_id WHERE p.proprietaire_id = user_uuid AND c.statut = 'actif')::BIGINT as contrats_actifs
    FROM proprietes
    WHERE proprietaire_id = user_uuid AND est_actif = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FIN
-- ============================================================
