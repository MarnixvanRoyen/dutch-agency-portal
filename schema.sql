-- ============================================================
-- Dutch Agency Portal — Schema v3
-- Voer dit uit in Supabase SQL Editor (lege database)
-- ============================================================

-- Labels
CREATE TABLE IF NOT EXISTS public.labels (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text          NOT NULL,
  description text,
  created_at  timestamptz   DEFAULT now()
);

-- Artiesten
CREATE TABLE IF NOT EXISTS public.artists (
  id         uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text          NOT NULL,
  email      text,
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

-- ── RLS uitgeschakeld (intern portaal) ────────────────────────
ALTER TABLE public.labels          DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.artists         DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.releases        DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks          DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.track_artists   DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.statements      DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.statement_lines DISABLE ROW LEVEL SECURITY;

GRANT ALL ON public.labels          TO anon;
GRANT ALL ON public.artists         TO anon;
GRANT ALL ON public.releases        TO anon;
GRANT ALL ON public.tracks          TO anon;
GRANT ALL ON public.track_artists   TO anon;
GRANT ALL ON public.statements      TO anon;
GRANT ALL ON public.statement_lines TO anon;
