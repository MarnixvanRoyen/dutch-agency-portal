-- ============================================================
-- Dutch Agency Portal — Migratie v3
-- Voer dit uit in Supabase SQL Editor
-- Wat dit doet:
--   1. Bestaande tracks tabel leegmaken
--   2. Releases tabel aanmaken (CatalogNumber niveau)
--   3. Tracks tabel aanpassen (isrc + label_id → release_id)
--   4. statement_lines.track_id blijft, maar isrc verwijst nu naar release
-- ============================================================

-- ── Stap 1: bestaande data clearen ───────────────────────────
TRUNCATE public.statement_lines CASCADE;
TRUNCATE public.track_artists   CASCADE;
TRUNCATE public.tracks          CASCADE;

-- ── Stap 2: releases tabel aanmaken ──────────────────────────
CREATE TABLE IF NOT EXISTS public.releases (
  id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  catalog_number text         NOT NULL,
  label_id       uuid         REFERENCES public.labels(id) ON DELETE SET NULL,
  release_type   text         DEFAULT 'unknown',  -- 'single', 'ep', 'album', 'compilation'
  created_at     timestamptz  DEFAULT now(),
  UNIQUE(catalog_number)
);

-- ── Stap 3: tracks tabel aanpassen ───────────────────────────
-- isrc en label_id verwijderen, release_id toevoegen
ALTER TABLE public.tracks DROP COLUMN IF EXISTS isrc;
ALTER TABLE public.tracks DROP COLUMN IF EXISTS label_id;
ALTER TABLE public.tracks ADD COLUMN IF NOT EXISTS release_id uuid REFERENCES public.releases(id) ON DELETE CASCADE;

-- title mag null zijn (tracks zonder naam → ⚠️ in dashboard)
ALTER TABLE public.tracks ALTER COLUMN title DROP NOT NULL;

-- ── Stap 4: RLS + rechten voor releases ──────────────────────
ALTER TABLE public.releases DISABLE ROW LEVEL SECURITY;

GRANT ALL ON public.releases TO anon;
GRANT ALL ON public.releases TO authenticated;
