-- ============================================================
-- Migration v4 — Persons als eigenaar van artiesten
-- Voer uit in Supabase SQL Editor
-- ============================================================

-- 1. Nieuwe tabel: personen (NAW + email + bankgegevens)
CREATE TABLE IF NOT EXISTS public.persons (
  id           uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name   text         NOT NULL,
  last_name    text         NOT NULL,
  street       text,                      -- Straat + huisnummer
  postal_code  text,                      -- Postcode
  city         text,                      -- Woonplaats
  country      text         DEFAULT 'NL',
  email        text,
  iban         text,                      -- Bankrekeningnummer
  notes        text,
  created_at   timestamptz  DEFAULT now()
);

-- 2. Koppel artists aan een persoon
ALTER TABLE public.artists
  ADD COLUMN IF NOT EXISTS person_id uuid REFERENCES public.persons(id) ON DELETE SET NULL;

-- 3. Email weghalen uit artists
--    Voer dit pas uit nadat je bestaande email-data hebt overgezet!
--    Stap 3a: controleer eerst of er email-data in artists zit:
--      SELECT id, name, email FROM artists WHERE email IS NOT NULL;
--    Stap 3b: daarna:
--      ALTER TABLE public.artists DROP COLUMN email;

-- 4. RLS + rechten voor nieuwe tabel
ALTER TABLE public.persons DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.persons TO anon;
