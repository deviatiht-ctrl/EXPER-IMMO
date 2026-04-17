-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE public.profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name   TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  is_admin    BOOLEAN NOT NULL DEFAULT FALSE,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- AGENTS
-- ============================================================
CREATE TABLE public.agents (
  id             UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  nom            TEXT NOT NULL,
  prenom         TEXT NOT NULL,
  slug           TEXT UNIQUE NOT NULL,
  titre          TEXT DEFAULT 'Agent Immobilier',
  email          TEXT NOT NULL,
  telephone      TEXT NOT NULL,
  whatsapp       TEXT,
  photo_url      TEXT,
  biographie     TEXT,
  specialites    TEXT[] DEFAULT '{}',
  langues        TEXT[] DEFAULT '{"Créole","Français"}',
  experience_ans INTEGER DEFAULT 0,
  nb_ventes      INTEGER DEFAULT 0,
  nb_locations   INTEGER DEFAULT 0,
  actif          BOOLEAN DEFAULT TRUE,
  ordre          INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ZONES
-- ============================================================
CREATE TABLE public.zones (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  nom         TEXT NOT NULL,
  slug        TEXT UNIQUE NOT NULL,
  ville       TEXT NOT NULL DEFAULT 'Port-au-Prince',
  description TEXT,
  image_url   TEXT,
  actif       BOOLEAN DEFAULT TRUE,
  ordre       INTEGER DEFAULT 0
);

INSERT INTO public.zones (nom, slug, ville) VALUES
  ('Pétion-Ville',        'petion-ville',        'Port-au-Prince'),
  ('Delmas',              'delmas',              'Port-au-Prince'),
  ('Tabarre',             'tabarre',             'Port-au-Prince'),
  ('Kenscoff',            'kenscoff',            'Port-au-Prince'),
  ('Laboule',             'laboule',             'Port-au-Prince'),
  ('Montagne Noire',      'montagne-noire',      'Port-au-Prince'),
  ('Carrefour',           'carrefour',           'Port-au-Prince'),
  ('Croix-des-Bouquets',  'croix-des-bouquets',  'Port-au-Prince'),
  ('Cap-Haïtien',         'cap-haitien',         'Cap-Haïtien'),
  ('Jacmel',              'jacmel',              'Jacmel');

-- ============================================================
-- PROPRIETES
-- ============================================================
CREATE TABLE public.proprietes (
  id                   UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reference            TEXT UNIQUE,
  titre                TEXT NOT NULL,
  slug                 TEXT UNIQUE NOT NULL,
  description          TEXT,
  description_courte   TEXT,
  type_transaction     TEXT NOT NULL
                         CHECK (type_transaction IN ('vente','location','vente_location')),
  type_propriete       TEXT NOT NULL
                         CHECK (type_propriete IN (
                           'maison','appartement','villa','terrain',
                           'local_commercial','bureau','entrepot','hotel'
                         )),
  prix                 NUMERIC(15,2) NOT NULL CHECK (prix >= 0),
  prix_negociable      BOOLEAN DEFAULT FALSE,
  devise               TEXT NOT NULL DEFAULT 'USD',
  prix_loyer           NUMERIC(10,2),
  charges_mensuelles   NUMERIC(10,2),
  zone_id              UUID REFERENCES public.zones(id),
  adresse              TEXT,
  ville                TEXT DEFAULT 'Port-au-Prince',
  latitude             DECIMAL(10,8),
  longitude            DECIMAL(11,8),
  superficie_m2        NUMERIC(10,2),
  superficie_terrain   NUMERIC(10,2),
  nb_chambres          INTEGER DEFAULT 0,
  nb_salles_bain       INTEGER DEFAULT 0,
  nb_garages           INTEGER DEFAULT 0,
  nb_etages            INTEGER DEFAULT 0,
  annee_construction   INTEGER,
  meuble               BOOLEAN DEFAULT FALSE,
  amenagements         TEXT[] DEFAULT '{}',
  images               TEXT[] DEFAULT '{}',
  video_url            TEXT,
  visite_virtuelle_url TEXT,
  agent_id             UUID REFERENCES public.agents(id),
  statut               TEXT NOT NULL DEFAULT 'disponible'
                         CHECK (statut IN (
                           'disponible','sous_compromis',
                           'vendu','loue','indisponible'
                         )),
  tags                 TEXT[] DEFAULT '{}',
  est_vedette          BOOLEAN DEFAULT FALSE,
  est_nouveau          BOOLEAN DEFAULT TRUE,
  est_actif            BOOLEAN DEFAULT TRUE,
  vue_count            INTEGER DEFAULT 0,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prop_transaction ON public.proprietes(type_transaction);
CREATE INDEX idx_prop_type        ON public.proprietes(type_propriete);
CREATE INDEX idx_prop_zone        ON public.proprietes(zone_id);
CREATE INDEX idx_prop_prix        ON public.proprietes(prix);
CREATE INDEX idx_prop_statut      ON public.proprietes(statut);
CREATE INDEX idx_prop_actif       ON public.proprietes(est_actif);

-- ============================================================
-- CONTACTS / RENDEZ-VOUS
-- ============================================================
CREATE TABLE public.contacts (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  propriete_id    UUID REFERENCES public.proprietes(id),
  agent_id        UUID REFERENCES public.agents(id),
  nom             TEXT NOT NULL,
  email           TEXT NOT NULL,
  telephone       TEXT NOT NULL,
  message         TEXT,
  type_demande    TEXT NOT NULL DEFAULT 'information'
                    CHECK (type_demande IN (
                      'information','visite','offre',
                      'rendez_vous','general'
                    )),
  date_souhaitee  DATE,
  heure_souhaitee TEXT,
  statut          TEXT NOT NULL DEFAULT 'nouveau'
                    CHECK (statut IN ('nouveau','en_cours','traite','annule')),
  notes_admin     TEXT,
  est_lu          BOOLEAN DEFAULT FALSE,
  traite_le       TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE public.notifications (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  type            TEXT NOT NULL CHECK (type IN (
                    'nouveau_contact','nouvelle_visite',
                    'nouvelle_offre','alerte_systeme'
                  )),
  titre           TEXT NOT NULL,
  corps           TEXT,
  est_lu          BOOLEAN DEFAULT FALSE,
  reference_id    UUID,
  reference_table TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PARAMETRES
-- ============================================================
CREATE TABLE public.parametres (
  cle    TEXT PRIMARY KEY,
  valeur TEXT,
  label  TEXT,
  groupe TEXT
);

INSERT INTO public.parametres (cle, valeur, label, groupe) VALUES
  ('nom_agence',       'EXPER IMMO',                   'Nom agence',          'general'),
  ('tagline',          'Votre Bien, Notre Mission',    'Slogan',              'general'),
  ('telephone',        '+509 XXXX-XXXX',              'Téléphone',           'contact'),
  ('whatsapp',         '+509 XXXX-XXXX',              'WhatsApp',            'contact'),
  ('email',            'contact@experimmo.ht',        'Email',               'contact'),
  ('adresse',          'Pétion-Ville, Haïti',         'Adresse',             'contact'),
  ('horaires',         'Lun-Ven 8h-18h | Sam 9h-14h','Horaires',            'contact'),
  ('facebook',         '',                            'Facebook URL',        'reseaux'),
  ('instagram',        '',                            'Instagram URL',       'reseaux'),
  ('google_maps_key',  '',                            'Google Maps API Key', 'technique'),
  ('devise_defaut',    'USD',                         'Devise par défaut',   'technique'),
  ('nb_par_page',      '12',                          'Prop. par page',      'technique'),
  ('mode_maintenance', 'false',                       'Mode maintenance',    'technique');
