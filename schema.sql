-- ============================================================
-- Dutch Agency Portal — Schema v2 (Track-centrisch)
-- Voer dit uit in Supabase SQL Editor (eenmalig, lege database)
-- ============================================================

-- Labels
CREATE TABLE IF NOT EXISTS public.labels (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text          NOT NULL,
  description text,
  created_at  timestamptz   DEFAULT now()
);

-- Artiesten (koppeling aan label loopt via tracks)
CREATE TABLE IF NOT EXISTS public.artists (
  id         uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text          NOT NULL,
  email      text,
  phone      text,
  notes      text,
  created_at timestamptz   DEFAULT now()
);

-- Tracks (centrale entiteit)
CREATE TABLE IF NOT EXISTS public.tracks (
  id         uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  title      text          NOT NULL,
  label_id   uuid          REFERENCES public.labels(id) ON DELETE SET NULL,
  isrc       text,
  created_at timestamptz   DEFAULT now()
);

-- Koppeling Track <-> Artiest met split-percentage
-- Splits per track tellen op tot 100%
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
-- track_id ingevuld als ISRC matcht met bekende track
CREATE TABLE IF NOT EXISTS public.statement_lines (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  statement_id uuid          REFERENCES public.statements(id) ON DELETE CASCADE,
  track_id     uuid          REFERENCES public.tracks(id) ON DELETE SET NULL,
  label_name   text,
  artist_name  text,
  track_title  text,
  isrc         text,
  usage_type   text,
  quantity     integer,
  nett_royalty numeric(12,4) DEFAULT 0,
  period       text,
  raw_data     jsonb
);

-- ── Row Level Security ──────────────────────────────────────

ALTER TABLE public.labels          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artists         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.track_artists   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statements      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statement_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY auth_only ON public.labels          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.artists         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.tracks          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.track_artists   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.statements      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_only ON public.statement_lines FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT ALL ON public.labels          TO authenticated;
GRANT ALL ON public.artists         TO authenticated;
GRANT ALL ON public.tracks          TO authenticated;
GRANT ALL ON public.track_artists   TO authenticated;
GRANT ALL ON public.statements      TO authenticated;
GRANT ALL ON public.statement_lines TO authenticated;
