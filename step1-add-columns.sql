-- ============================================================
-- STEP 1: SELMAN AJOUTE KOLON YO
-- Egzekite sa anvan tout lòt bagay
-- ============================================================

-- 1. AJOUTE proprietaire_id NAN PROPRIETES
ALTER TABLE proprietes 
ADD COLUMN IF NOT EXISTS proprietaire_id UUID;

-- 2. AJOUTE lot kolon yo
ALTER TABLE proprietes 
ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS documents JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS prix DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS statut_bien VARCHAR(50),
ADD COLUMN IF NOT EXISTS annee_construction INTEGER,
ADD COLUMN IF NOT EXISTS reference VARCHAR(100),
ADD COLUMN IF NOT EXISTS est_actif BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS type_propriete VARCHAR(50),
ADD COLUMN IF NOT EXISTS type_transaction VARCHAR(50);

-- 3. AJOUTE id_proprietaire NAN PROPRIETAIRES (si tab egziste)
ALTER TABLE proprietaires 
ADD COLUMN IF NOT EXISTS id_proprietaire UUID;

-- 4. Ranpli id_proprietaire ak vale id si li NULL
UPDATE proprietaires 
SET id_proprietaire = id 
WHERE id_proprietaire IS NULL;

-- 5. Verifye kolon yo kreye
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'proprietes' 
ORDER BY ordinal_position;
