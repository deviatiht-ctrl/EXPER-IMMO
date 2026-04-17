CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

SELECT extname FROM pg_extension
WHERE extname IN ('uuid-ossp','pgcrypto','unaccent');
