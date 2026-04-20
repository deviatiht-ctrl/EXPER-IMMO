-- ============================================================
-- EXPER IMMO - MIGRATION PROPRIETAIRE 2.0
-- Fix tout tab pou pwopriyetè a mache kòrèkteman
-- ============================================================

-- ============================================================
-- 1. TABLE: proprietes (Verifye ak Ajoute Kolon ki Manke)
-- ============================================================
DO $$
BEGIN
    -- Verifye si tab 'proprietes' egziste, si non kreye li
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'proprietes') THEN
        CREATE TABLE proprietes (
            id_propriete UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            titre VARCHAR(255) NOT NULL,
            reference VARCHAR(100) UNIQUE,
            type_propriete VARCHAR(50) NOT NULL, -- maison, appartement, villa, terrain, local_commercial, entrepot
            type_transaction VARCHAR(50) NOT NULL, -- location, vente, lesion_bail, co_propriete
            statut VARCHAR(50) DEFAULT 'disponible', -- disponible, loue, vendu, sous_compromis, en_construction, gestion
            statut_bien VARCHAR(50), -- gestion, construction, disponible
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
            proprietaire_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            est_actif BOOLEAN DEFAULT true,
            images JSONB DEFAULT '[]', -- Array of image URLs
            documents JSONB DEFAULT '[]', -- Array of document URLs
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table proprietes kreye';
    ELSE
        -- Verifye ak ajoute kolon ki manke
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'images') THEN
            ALTER TABLE proprietes ADD COLUMN images JSONB DEFAULT '[]';
            RAISE NOTICE 'Kolon images ajoute';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'documents') THEN
            ALTER TABLE proprietes ADD COLUMN documents JSONB DEFAULT '[]';
            RAISE NOTICE 'Kolon documents ajoute';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'prix') THEN
            ALTER TABLE proprietes ADD COLUMN prix DECIMAL(15,2) DEFAULT 0;
            RAISE NOTICE 'Kolon prix ajoute';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'statut_bien') THEN
            ALTER TABLE proprietes ADD COLUMN statut_bien VARCHAR(50);
            RAISE NOTICE 'Kolon statut_bien ajoute';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietes' AND column_name = 'annee_construction') THEN
            ALTER TABLE proprietes ADD COLUMN annee_construction INTEGER;
            RAISE NOTICE 'Kolon annee_construction ajoute';
        END IF;
    END IF;
END $$;

-- ============================================================
-- 2. TABLE: proprietaires (Verifye ak kreye si nesesè)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'proprietaires') THEN
        CREATE TABLE proprietaires (
            id_proprietaire UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
            type_proprietaire VARCHAR(50), -- particulier, entreprise, syndic
            nom_entreprise VARCHAR(255),
            siret VARCHAR(100),
            nombre_biens INTEGER DEFAULT 0,
            est_actif BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table proprietaires kreye';
    ELSE
        -- Verifye ak ajoute kolon ki manke
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietaires' AND column_name = 'type_proprietaire') THEN
            ALTER TABLE proprietaires ADD COLUMN type_proprietaire VARCHAR(50);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'proprietaires' AND column_name = 'nom_entreprise') THEN
            ALTER TABLE proprietaires ADD COLUMN nom_entreprise VARCHAR(255);
        END IF;
    END IF;
END $$;

-- ============================================================
-- 3. TABLE: paiements (Verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'paiements') THEN
        CREATE TABLE paiements (
            id_paiement UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            id_propriete UUID REFERENCES proprietes(id_propriete),
            id_locataire UUID REFERENCES locataires(id_locataire),
            id_contrat UUID REFERENCES contrats(id_contrat),
            montant_total DECIMAL(15,2) NOT NULL,
            montant_paye DECIMAL(15,2) DEFAULT 0,
            statut VARCHAR(50) DEFAULT 'en_attente', -- en_attente, paye, en_retard, annule
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
        
        RAISE NOTICE 'Table paiements kreye';
    END IF;
END $$;

-- ============================================================
-- 4. TABLE: contrats (Verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contrats') THEN
        CREATE TABLE contrats (
            id_contrat UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            id_propriete UUID REFERENCES proprietes(id_propriete),
            id_locataire UUID REFERENCES locataires(id_locataire),
            id_proprietaire UUID REFERENCES profiles(id),
            type_contrat VARCHAR(50) NOT NULL, -- location, vente, gestion
            date_debut DATE NOT NULL,
            date_fin DATE,
            loyer_mensuel DECIMAL(15,2),
            depot_garantie DECIMAL(15,2),
            honoraires_gestion DECIMAL(10,2), -- en pourcentage
            statut VARCHAR(50) DEFAULT 'actif', -- actif, expire, resilie, en_attente
            tacite_reconduction BOOLEAN DEFAULT false,
            indexation_annuelle BOOLEAN DEFAULT false,
            clause_solidarite BOOLEAN DEFAULT false,
            document_url TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table contrats kreye';
    END IF;
END $$;

-- ============================================================
-- 5. TABLE: operations (Verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'operations') THEN
        CREATE TABLE operations (
            id_operation UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            id_propriete UUID REFERENCES proprietes(id_propriete),
            id_proprietaire UUID REFERENCES profiles(id),
            type_operation VARCHAR(100) NOT NULL,
            description TEXT,
            montant DECIMAL(15,2),
            date_operation DATE DEFAULT CURRENT_DATE,
            statut VARCHAR(50) DEFAULT 'en_cours',
            documents JSONB DEFAULT '[]',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table operations kreye';
    END IF;
END $$;

-- ============================================================
-- 6. TABLE: tickets_support (Verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tickets_support') THEN
        CREATE TABLE tickets_support (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            createur_id UUID REFERENCES profiles(id),
            type_createur VARCHAR(50), -- locataire, proprietaire
            sujet VARCHAR(255) NOT NULL,
            description TEXT NOT NULL,
            categorie VARCHAR(50), -- maintenance, plomberie, electricite, paiement, bruit, securite, nettoyage, autre
            priorite VARCHAR(50) DEFAULT 'moyenne', -- basse, moyenne, haute, urgente
            statut VARCHAR(50) DEFAULT 'ouvert', -- ouvert, en_cours, resolu, ferme
            reference VARCHAR(100) UNIQUE,
            assigne_a UUID REFERENCES profiles(id),
            id_propriete UUID REFERENCES proprietes(id_propriete),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            date_resolution TIMESTAMP WITH TIME ZONE
        );
        
        RAISE NOTICE 'Table tickets_support kreye';
    END IF;
END $$;

-- ============================================================
-- 7. TABLE: ticket_messages (Verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ticket_messages') THEN
        CREATE TABLE ticket_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            ticket_id UUID REFERENCES tickets_support(id) ON DELETE CASCADE,
            auteur_id UUID REFERENCES profiles(id),
            message TEXT NOT NULL,
            est_interne BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table ticket_messages kreye';
    END IF;
END $$;

-- ============================================================
-- 8. TABLE: documents (Verifye ak kreye)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents') THEN
        CREATE TABLE documents (
            id_document UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            id_propriete UUID REFERENCES proprietes(id_propriete),
            id_contrat UUID REFERENCES contrats(id_contrat),
            id_proprietaire UUID REFERENCES profiles(id),
            type_document VARCHAR(100) NOT NULL,
            nom_fichier VARCHAR(255) NOT NULL,
            url_fichier TEXT NOT NULL,
            taille_fichier BIGINT,
            mime_type VARCHAR(100),
            est_public BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table documents kreye';
    END IF;
END $$;

-- ============================================================
-- 9. INDEXES (Pou performans)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_proprietes_proprietaire ON proprietes(proprietaire_id);
CREATE INDEX IF NOT EXISTS idx_proprietes_statut ON proprietes(statut);
CREATE INDEX IF NOT EXISTS idx_proprietes_type ON proprietes(type_propriete);
CREATE INDEX IF NOT EXISTS idx_paiements_propriete ON paiements(id_propriete);
CREATE INDEX IF NOT EXISTS idx_paiements_locataire ON paiements(id_locataire);
CREATE INDEX IF NOT EXISTS idx_contrats_propriete ON contrats(id_propriete);
CREATE INDEX IF NOT EXISTS idx_contrats_locataire ON contrats(id_locataire);
CREATE INDEX IF NOT EXISTS idx_tickets_createur ON tickets_support(createur_id);
CREATE INDEX IF NOT EXISTS idx_tickets_statut ON tickets_support(statut);
CREATE INDEX IF NOT EXISTS idx_operations_proprietaire ON operations(id_proprietaire);

-- ============================================================
-- 10. TRIGGERS pou updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pou chak tab ki gen updated_at
DO $$
DECLARE
    tables CURSOR FOR 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('proprietes', 'proprietaires', 'paiements', 'contrats', 'operations', 'tickets_support', 'documents');
BEGIN
    FOR table_record IN tables LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = table_record.table_name AND column_name = 'updated_at') THEN
            EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON %I', table_record.table_name, table_record.table_name);
            EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', table_record.table_name, table_record.table_name);
        END IF;
    END LOOP;
END $$;

-- ============================================================
-- 11. ROW LEVEL SECURITY (RLS) - Sekirite
-- ============================================================

-- Enable RLS
ALTER TABLE proprietes ENABLE ROW LEVEL SECURITY;
ALTER TABLE paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE contrats ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets_support ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Proprietaires can view their own properties" ON proprietes;
DROP POLICY IF EXISTS "Proprietaires can insert their own properties" ON proprietes;
DROP POLICY IF EXISTS "Proprietaires can update their own properties" ON proprietes;
DROP POLICY IF EXISTS "Proprietaires can delete their own properties" ON proprietes;

-- Policies for proprietes
CREATE POLICY "Proprietaires can view their own properties" 
    ON proprietes FOR SELECT 
    USING (proprietaire_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

CREATE POLICY "Proprietaires can insert their own properties" 
    ON proprietes FOR INSERT 
    WITH CHECK (proprietaire_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

CREATE POLICY "Proprietaires can update their own properties" 
    ON proprietes FOR UPDATE 
    USING (proprietaire_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

CREATE POLICY "Proprietaires can delete their own properties" 
    ON proprietes FOR DELETE 
    USING (proprietaire_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

-- Policies for paiements
DROP POLICY IF EXISTS "Proprietaires can view payments for their properties" ON paiements;
CREATE POLICY "Proprietaires can view payments for their properties" 
    ON paiements FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM proprietes WHERE proprietes.id_propriete = paiements.id_propriete 
        AND proprietes.proprietaire_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

-- Policies for contrats
DROP POLICY IF EXISTS "Proprietaires can view contracts for their properties" ON contrats;
CREATE POLICY "Proprietaires can view contracts for their properties" 
    ON contrats FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM proprietes WHERE proprietes.id_propriete = contrats.id_propriete 
        AND proprietes.proprietaire_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

-- Policies for tickets
DROP POLICY IF EXISTS "Users can view their own tickets" ON tickets_support;
DROP POLICY IF EXISTS "Users can create tickets" ON tickets_support;
CREATE POLICY "Users can view their own tickets" 
    ON tickets_support FOR SELECT 
    USING (createur_id = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'gestionnaire')
    ));

CREATE POLICY "Users can create tickets" 
    ON tickets_support FOR INSERT 
    WITH CHECK (createur_id = auth.uid());

-- ============================================================
-- 12. STORAGE BUCKETS (Pou foto ak dokiman)
-- ============================================================

-- Bucket pou foto pwopriyete
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
    'proprietes-photos',
    'proprietes-photos',
    true,
    false,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Bucket pou dokiman pwopriyete  
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
    'proprietes-documents',
    'proprietes-documents',
    false, -- Private
    false,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/jpeg', 'image/png']
)
ON CONFLICT (id) DO NOTHING;

-- Policies for storage
CREATE POLICY "Anyone can view property photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'proprietes-photos');

CREATE POLICY "Authenticated users can upload property photos"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'proprietes-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Property owners can delete their photos"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'proprietes-photos' AND auth.role() = 'authenticated');

-- ============================================================
-- 13. FUNCTIONS & RPC
-- ============================================================

-- Function: Get dashboard stats for proprietaire
CREATE OR REPLACE FUNCTION get_proprietaire_dashboard_stats(p_proprietaire_id UUID)
RETURNS TABLE (
    total_biens BIGINT,
    en_gestion BIGINT,
    en_construction BIGINT,
    disponibles BIGINT,
    loues BIGINT,
    revenus_mensuels DECIMAL,
    paiements_en_retard BIGINT,
    contrats_actifs BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_biens,
        COUNT(*) FILTER (WHERE p.statut_bien = 'gestion')::BIGINT as en_gestion,
        COUNT(*) FILTER (WHERE p.statut_bien = 'construction')::BIGINT as en_construction,
        COUNT(*) FILTER (WHERE p.statut = 'disponible')::BIGINT as disponibles,
        COUNT(*) FILTER (WHERE p.statut = 'loue')::BIGINT as loues,
        COALESCE(SUM(c.loyer_mensuel) FILTER (WHERE c.statut = 'actif'), 0) as revenus_mensuels,
        COUNT(*) FILTER (WHERE pa.statut = 'en_retard')::BIGINT as paiements_en_retard,
        COUNT(DISTINCT c.id_contrat) FILTER (WHERE c.statut = 'actif')::BIGINT as contrats_actifs
    FROM proprietes p
    LEFT JOIN contrats c ON c.id_propriete = p.id_propriete AND c.statut = 'actif'
    LEFT JOIN paiements pa ON pa.id_propriete = p.id_propriete
    WHERE p.proprietaire_id = p_proprietaire_id
    AND p.est_actif = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Generate property reference
CREATE OR REPLACE FUNCTION generate_property_reference()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reference IS NULL OR NEW.reference = '' THEN
        NEW.reference := 'PROP-' || TO_CHAR(NOW(), 'YYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and create trigger for reference generation
DROP TRIGGER IF EXISTS set_property_reference ON proprietes;
CREATE TRIGGER set_property_reference
    BEFORE INSERT ON proprietes
    FOR EACH ROW
    EXECUTE FUNCTION generate_property_reference();

-- Function: Update proprietaire nombre_biens
CREATE OR REPLACE FUNCTION update_proprietaire_biens_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.est_actif = true THEN
        UPDATE proprietaires SET nombre_biens = nombre_biens + 1 
        WHERE user_id = NEW.proprietaire_id;
    ELSIF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.est_actif = true AND NEW.est_actif = false) THEN
        UPDATE proprietaires SET nombre_biens = GREATEST(nombre_biens - 1, 0) 
        WHERE user_id = COALESCE(OLD.proprietaire_id, NEW.proprietaire_id);
    ELSIF TG_OP = 'UPDATE' AND OLD.est_actif = false AND NEW.est_actif = true THEN
        UPDATE proprietaires SET nombre_biens = nombre_biens + 1 
        WHERE user_id = NEW.proprietaire_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and create trigger
DROP TRIGGER IF EXISTS update_proprietaire_count ON proprietes;
CREATE TRIGGER update_proprietaire_count
    AFTER INSERT OR UPDATE OR DELETE ON proprietes
    FOR EACH ROW
    EXECUTE FUNCTION update_proprietaire_biens_count();

-- ============================================================
-- 14. SEED DATA (Opsyonal - pou test)
-- ============================================================

-- Insert some common zones if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'zones') THEN
        INSERT INTO zones (nom, ville, description) VALUES
            ('Pétion-Ville Centre', 'Pétion-Ville', 'Zone centrale de Pétion-Ville'),
            ('Laboule', 'Pétion-Ville', 'Zone résidentielle de Laboule'),
            ('Fermathe', 'Pétion-Ville', 'Zone de Fermathe'),
            ('Delmas 75', 'Delmas', 'Zone commerciale Delmas'),
            ('Canapé Vert', 'Port-au-Prince', 'Zone résidentielle Canapé Vert'),
            ('Morne Calvaire', 'Port-au-Prince', 'Zone de Morne Calvaire'),
            ('Torcel', 'Port-au-Prince', 'Zone de Torcel'),
            ('Cap-Haïtien Centre', 'Cap-Haïtien', 'Centre-ville Cap-Haïtien'),
            ('Berger', 'Port-au-Prince', 'Zone résidentielle Berger'),
            ('Musseau', 'Pétion-Ville', 'Zone de Musseau')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ============================================================
-- FIN MIGRATION
-- ============================================================
