-- ============================================================
-- DJ·World Portaal — Schema v5: Financiële Administratie
-- Spaarpot per persoon, grootboek, uitbetalingen
--
-- Voer de blokken ÉÉN VOOR ÉÉN uit in de Supabase SQL Editor.
-- Tussen de blokken staat steeds een controle.
-- MAAK EERST EEN BACK-UP (pg_dump).
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- BLOK 1 — Tabel: uitbetalingen
-- ────────────────────────────────────────────────────────────
-- Eerst deze, want het grootboek verwijst ernaar.
-- Eén rij = één uitbetaalronde voor één persoon.

CREATE TABLE IF NOT EXISTS public.payouts (
  id               uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id        uuid          NOT NULL REFERENCES public.persons(id) ON DELETE RESTRICT,
  status           text          NOT NULL DEFAULT 'gemeld'
                                 CHECK (status IN ('gemeld','factuur_ontvangen','betaald','geannuleerd')),

  -- Saldo op het moment van melden. Bevroren: nieuwe royalty's die daarna
  -- binnenkomen veranderen dit bedrag niet.
  gemeld_bedrag    numeric(12,4) NOT NULL,
  gemeld_op        date          NOT NULL DEFAULT current_date,

  factuurnummer    text,
  factuurdatum     date,
  factuurbedrag    numeric(12,2),

  betaald_op       date,
  betaald_bedrag   numeric(12,2),
  betaalreferentie text,

  opmerking        text,
  created_at       timestamptz   NOT NULL DEFAULT now(),

  -- Een betaalde uitbetaling moet een bedrag en een datum hebben.
  -- Liever een foutmelding dan een halve betaling in de administratie.
  CONSTRAINT betaald_is_compleet CHECK (
    status <> 'betaald' OR (betaald_op IS NOT NULL AND betaald_bedrag IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS payouts_person_idx ON public.payouts (person_id);
CREATE INDEX IF NOT EXISTS payouts_status_idx ON public.payouts (status);


-- ────────────────────────────────────────────────────────────
-- BLOK 2 — Tabel: grootboek
-- ────────────────────────────────────────────────────────────
-- Elke gebeurtenis is één regel. Saldo van een persoon = som van amount.
-- Er is BEWUST geen saldoveld op persons: dat zou uit de pas kunnen lopen.

CREATE TABLE IF NOT EXISTS public.ledger_entries (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id    uuid          NOT NULL REFERENCES public.persons(id) ON DELETE RESTRICT,

  type         text          NOT NULL CHECK (type IN
                 ('beginsaldo','royalty','uitbetaling','correctie','voorschot','kosten')),

  -- Positief = erbij, negatief = eraf. 4 decimalen, net als nett_royalty:
  -- intern alle decimalen bewaren, pas bij het tonen afronden.
  amount       numeric(12,4) NOT NULL,
  entry_date   date          NOT NULL DEFAULT current_date,

  statement_id uuid          REFERENCES public.statements(id)  ON DELETE RESTRICT,
  payout_id    uuid          REFERENCES public.payouts(id)     ON DELETE RESTRICT,

  -- Alleen herkomst (van welke artiestennaam kwam dit?). Telt niet mee in het
  -- saldo — dat blijft van de persoon.
  artist_id    uuid          REFERENCES public.artists(id)     ON DELETE SET NULL,

  omschrijving text,
  created_at   timestamptz   NOT NULL DEFAULT now(),

  -- Een royaltyboeking zonder statement kun je nergens op terugvoeren.
  CONSTRAINT royalty_heeft_statement CHECK (
    type <> 'royalty' OR statement_id IS NOT NULL
  ),

  -- Tekencontrole: voorkomt dat een verkeerd teken een betaling stilzwijgend
  -- omdraait in een bijschrijving.
  CONSTRAINT teken_klopt CHECK (
    (type = 'royalty'     AND amount >= 0) OR
    (type = 'uitbetaling' AND amount <= 0) OR
    (type = 'voorschot'   AND amount <= 0) OR
    (type = 'kosten'      AND amount <= 0) OR
    (type IN ('beginsaldo','correctie'))
  )
);

-- DE belangrijkste regel: één royaltyboeking per persoon per statement.
-- Hierdoor kun je een statement zo vaak "boeken" als je wilt — al geboekte
-- personen worden overgeslagen, alleen nieuw gekoppelde komen erbij.
CREATE UNIQUE INDEX IF NOT EXISTS ledger_royalty_uniek
  ON public.ledger_entries (person_id, statement_id)
  WHERE type = 'royalty';

CREATE INDEX IF NOT EXISTS ledger_person_idx    ON public.ledger_entries (person_id);
CREATE INDEX IF NOT EXISTS ledger_statement_idx ON public.ledger_entries (statement_id);
CREATE INDEX IF NOT EXISTS ledger_type_idx      ON public.ledger_entries (type);


-- ────────────────────────────────────────────────────────────
-- BLOK 3 — Statements: welke horen buiten de administratie?
-- ────────────────────────────────────────────────────────────
-- Of een statement geboekt is, leiden we af uit het grootboek — dat slaan we
-- niet apart op. We slaan alleen de UITZONDERING op: statements die bewust
-- nooit geboekt worden, zodat ze niet eeuwig als waarschuwing blijven staan.

ALTER TABLE public.statements
  ADD COLUMN IF NOT EXISTS buiten_administratie boolean NOT NULL DEFAULT false;

-- 09-2025 en 12-2025 zijn buiten de tool afgehandeld.
UPDATE public.statements
   SET buiten_administratie = true
 WHERE period IN ('09-2025', '12-2025');

-- CONTROLE — verwacht: precies de twee statements van 2025 op true
SELECT period, filename, buiten_administratie
  FROM public.statements
 ORDER BY uploaded_at;


-- ────────────────────────────────────────────────────────────
-- BLOK 4 — Instelling: uitbetaaldrempel
-- ────────────────────────────────────────────────────────────
-- Strikt BOVEN dit bedrag (dus vanaf 25,01) komt iemand in aanmerking.

INSERT INTO public.settings (key, value)
VALUES ('payout_threshold', '25')
ON CONFLICT (key) DO NOTHING;

-- CONTROLE — verwacht: payout_threshold = 25
SELECT key, value FROM public.settings WHERE key = 'payout_threshold';


-- ────────────────────────────────────────────────────────────
-- BLOK 5 — Beveiliging (zelfde patroon als de andere tabellen)
-- ────────────────────────────────────────────────────────────

ALTER TABLE public.payouts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.payouts, public.ledger_entries FROM anon;

-- Eerst weggooien als hij al bestaat, zodat dit blok twee keer draaien geen
-- foutmelding geeft (bij de bestaande tabellen staan nu dubbele policies —
-- daar willen we er niet nog meer bij).
DROP POLICY IF EXISTS auth_only ON public.payouts;
DROP POLICY IF EXISTS auth_only ON public.ledger_entries;

CREATE POLICY auth_only ON public.payouts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY auth_only ON public.ledger_entries
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- CONTROLE — verwacht: 2 rijen, allebei rowsecurity = true
SELECT tablename, rowsecurity
  FROM pg_tables
 WHERE schemaname = 'public'
   AND tablename IN ('payouts','ledger_entries');


-- ────────────────────────────────────────────────────────────
-- BLOK 5b — Rechten voor de Data API
-- ────────────────────────────────────────────────────────────
-- In Supabase staat "Automatically expose new tables" UIT. Nieuwe tabellen
-- krijgen dus GEEN rechten mee en zijn onzichtbaar voor de site, ook al
-- bestaan ze. Daarom hier expliciet toekennen — dat werkt altijd, ongeacht
-- wat er in het Supabase-scherm aan of uit staat.
--
-- RLS blijft de echte poortwachter; dit regelt alleen dát de rol de tabel
-- überhaupt mag benaderen.

GRANT SELECT, INSERT, UPDATE, DELETE ON public.payouts        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ledger_entries TO authenticated;
GRANT SELECT                          ON public.person_balances TO authenticated;

REVOKE ALL ON public.payouts, public.ledger_entries, public.person_balances FROM anon;

-- CONTROLE — de nieuwe objecten moeten dezelfde rechten hebben als 'statements',
-- een tabel waarvan we weten dat de site hem kan lezen.
SELECT table_name, grantee,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS rechten
  FROM information_schema.role_table_grants
 WHERE table_schema = 'public'
   AND table_name IN ('statements','payouts','ledger_entries','person_balances')
   AND grantee IN ('anon','authenticated')
 GROUP BY table_name, grantee
 ORDER BY table_name, grantee;


-- ────────────────────────────────────────────────────────────
-- BLOK 6 — Overzicht: saldo per persoon
-- ────────────────────────────────────────────────────────────
-- Zodat de schermen niet zelf hoeven op te tellen. Personen zonder mutaties
-- staan er ook in, met saldo 0.
--
-- security_invoker = on : de view gebruikt de rechten van de INGELOGDE
-- gebruiker, niet die van de eigenaar. Zonder dat zou de view langs de
-- beveiliging heen kunnen lezen.

CREATE OR REPLACE VIEW public.person_balances
WITH (security_invoker = on) AS
SELECT
  p.id                                                              AS person_id,
  p.first_name,
  p.last_name,
  p.email,
  COALESCE(SUM(l.amount), 0)                                        AS saldo,
  COALESCE(SUM(l.amount) FILTER (WHERE l.type = 'royalty'), 0)      AS totaal_royalty,
  COALESCE(-SUM(l.amount) FILTER (WHERE l.type = 'uitbetaling'), 0) AS totaal_uitbetaald,
  COALESCE(SUM(l.amount) FILTER (WHERE l.type IN
      ('beginsaldo','correctie','voorschot','kosten')), 0)          AS totaal_overig,
  COUNT(l.id)                                                       AS aantal_mutaties,
  MAX(l.entry_date)                                                 AS laatste_mutatie
FROM public.persons p
LEFT JOIN public.ledger_entries l ON l.person_id = p.id
GROUP BY p.id, p.first_name, p.last_name, p.email;

-- CONTROLE — verwacht: alle personen, saldo 0, 0 mutaties
SELECT first_name, last_name, saldo, aantal_mutaties
  FROM public.person_balances
 ORDER BY last_name
 LIMIT 10;


-- ────────────────────────────────────────────────────────────
-- BLOK 7 — Schema-cache verversen
-- ────────────────────────────────────────────────────────────
-- Zonder dit kent de API de nieuwe tabellen nog niet.

NOTIFY pgrst, 'reload schema';
