-- ============================================================
-- Dutch Agency Portal — Schema v4
-- Voer dit uit in Supabase SQL Editor (lege database)
-- ============================================================

-- Labels
CREATE TABLE IF NOT EXISTS public.labels (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text          NOT NULL,
  description text,
  created_at  timestamptz   DEFAULT now()
);

-- Personen (eigenaar van 1 of meer artiesten)
CREATE TABLE IF NOT EXISTS public.persons (
  id           uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name   text         NOT NULL,
  last_name    text         NOT NULL,
  street       text,
  postal_code  text,
  city         text,
  country      text         DEFAULT 'NL',
  email        text,
  iban         text,
  notes        text,
  created_at   timestamptz  DEFAULT now()
);

-- Artiesten (gekoppeld aan een persoon)
CREATE TABLE IF NOT EXISTS public.artists (
  id         uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text          NOT NULL,
  person_id  uuid          REFERENCES public.persons(id) ON DELETE SET NULL,
  phone      text,
  notes      text,
  created_at timestamptz   DEFAULT now()
);

-- Releases (CatalogNumber niveau — kan 1 of meerdere tracks bevatten)
CREATE TABLE IF NOT EXISTS public.releases (
  id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  catalog_number text         NOT NULL,
  label_id       uuid         REFERENCES public.labels(id) ON DELETE SET NULL,
  release_type   text         DEFAULT 'unknown',  -- 'single', 'ep', 'album', 'compilation'
  created_at     timestamptz  DEFAULT now(),
  UNIQUE(catalog_number)
);

-- Tracks (individuele nummers, gekoppeld aan een release)
-- title mag null zijn → zichtbaar als ⚠️ in dashboard
CREATE TABLE IF NOT EXISTS public.tracks (
  id         uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  title      text,
  release_id uuid          REFERENCES public.releases(id) ON DELETE CASCADE,
  created_at timestamptz   DEFAULT now()
);

-- Koppeling Track <-> Artiest met split-percentage
CREATE TABLE IF NOT EXISTS public.track_artists (
  id               uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  track_id         uuid          NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
  artist_id        uuid          NOT NULL REFERENCES public.artists(id) ON DELETE CASCADE,
  split_percentage numeric(5,2)  NOT NULL DEFAULT 100,
  UNIQUE(track_id, artist_id)
);

-- Geüploade royalty statements (Excel-bestanden)
CREATE TABLE IF NOT EXISTS public.statements (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  filename        text          NOT NULL,
  period          text,
  total_royalties numeric(12,4) DEFAULT 0,
  line_count      integer       DEFAULT 0,
  uploaded_at     timestamptz   DEFAULT now()
);

-- Individuele royalty-regels
-- track_id ingevuld als catalog_number + track_title matcht
CREATE TABLE IF NOT EXISTS public.statement_lines (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  statement_id uuid          REFERENCES public.statements(id) ON DELETE CASCADE,
  track_id     uuid          REFERENCES public.tracks(id) ON DELETE SET NULL,
  label_name   text,
  artist_name  text,
  track_title  text,
  isrc         text,          -- catalog_number van de release
  usage_type   text,
  quantity     integer,
  nett_royalty numeric(12,4) DEFAULT 0,
  period       text,
  raw_data     jsonb
);

-- ── Row Level Security — alleen authenticated gebruikers ──────
ALTER TABLE public.labels          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artists         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.releases        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.track_artists   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statements      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statement_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings        ENABLE ROW LEVEL SECURITY;

-- Anon rol heeft geen directe tabelrechten
REVOKE ALL ON public.labels, public.persons, public.artists,
  public.releases, public.tracks, public.track_artists,
  public.statements, public.statement_lines, public.settings
FROM anon;

-- Alleen ingelogde gebruikers mogen lezen en schrijven
CREATE POLICY auth_only ON public.labels          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.persons         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.artists         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.releases        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.tracks          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.track_artists   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.statements      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.statement_lines FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.settings        FOR ALL TO authenticated USING (true) WITH CHECK (true);
