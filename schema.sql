-- ============================================================
-- Dutch Agency Portal — Supabase Schema
-- Plak dit in: Supabase Dashboard → SQL Editor → New Query
-- Klik daarna op "Run"
-- ============================================================

-- Labels (bijv. "Spinnin Records", "DOORN", etc.)
CREATE TABLE IF NOT EXISTS labels (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Artiesten
CREATE TABLE IF NOT EXISTS artists (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name       TEXT NOT NULL,
  label_id   UUID REFERENCES labels(id) ON DELETE SET NULL,
  email      TEXT,
  phone      TEXT,
  notes      TEXT,
  active     BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tracks
CREATE TABLE IF NOT EXISTS tracks (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title        TEXT NOT NULL,
  isrc         TEXT,
  label_id     UUID REFERENCES labels(id) ON DELETE SET NULL,
  release_date DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Verdeling per track per artiest (splits)
CREATE TABLE IF NOT EXISTS track_artists (
  track_id         UUID REFERENCES tracks(id) ON DELETE CASCADE,
  artist_id        UUID REFERENCES artists(id) ON DELETE CASCADE,
  split_percentage NUMERIC(5,2) DEFAULT 100,
  PRIMARY KEY (track_id, artist_id)
);

-- Statement-uploads (één per Excel-bestand)
CREATE TABLE IF NOT EXISTS statements (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  filename        TEXT NOT NULL,
  period          TEXT,
  total_royalties NUMERIC(12,2) DEFAULT 0,
  line_count      INTEGER DEFAULT 0,
  uploaded_at     TIMESTAMPTZ DEFAULT NOW(),
  uploaded_by     UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Individuele royalty-regels uit de Excel (per sheet/label)
CREATE TABLE IF NOT EXISTS statement_lines (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  statement_id UUID REFERENCES statements(id) ON DELETE CASCADE,
  label_name   TEXT,
  artist_name  TEXT,
  track_title  TEXT,
  isrc         TEXT,
  nett_royalty NUMERIC(12,4),
  period       TEXT,
  raw_data     JSONB,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Row Level Security: alleen ingelogde gebruikers
-- ============================================================
ALTER TABLE labels          ENABLE ROW LEVEL SECURITY;
ALTER TABLE artists         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE track_artists   ENABLE ROW LEVEL SECURITY;
ALTER TABLE statements      ENABLE ROW LEVEL SECURITY;
ALTER TABLE statement_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "auth_only" ON labels          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_only" ON artists         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_only" ON tracks          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_only" ON track_artists   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_only" ON statements      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_only" ON statement_lines FOR ALL TO authenticated USING (true) WITH CHECK (true);
