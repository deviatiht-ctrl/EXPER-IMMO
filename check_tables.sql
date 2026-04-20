-- ============================================================
-- CHECK TAB YO (Egzekite sa anvan migration)
-- Sa a moutre wè sa ki egziste deja
-- ============================================================

-- 1. Wè tout kolon nan tab proprietes
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'proprietes' 
ORDER BY ordinal_position;

-- 2. Wè PRIMARY KEY a
SELECT 
    kcu.column_name
FROM information_schema.key_column_usage kcu
JOIN information_schema.table_constraints tc ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'proprietes' 
AND tc.constraint_type = 'PRIMARY KEY';

-- 3. Wè tout FOREIGN KEYS
SELECT
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'proprietes' 
AND tc.constraint_type = 'FOREIGN KEY';
