-- ============================================================
-- DJ·World Portaal — RESET van de financiële administratie
--
-- ⚠️ WIST ALLE SPAARPOTTEN, MUTATIES EN UITBETALINGEN — ook betaalde.
-- Statements, personen, artiesten en tracks blijven ongemoeid.
--
-- Werkt alleen zolang finadmin_testmodus op 'aan' staat. Staat hij op 'uit',
-- dan blokkeert de database dit script — en terecht, want dan is er echt geld
-- gegaan.
--
-- Bewust GEEN knop in de site: één misklik en je administratie is weg.
-- Dit voer je hier uit, met opzet.
-- ============================================================


-- ── STAP 1: kijk eerst wat je gaat wissen ───────────────────
-- Draai dit alleen, en kijk of de aantallen zijn wat je verwacht.

SELECT
  (SELECT value FROM public.settings WHERE key = 'finadmin_testmodus')  AS testmodus,
  (SELECT count(*) FROM public.ledger_entries)                          AS mutaties,
  (SELECT count(*) FROM public.payouts)                                 AS uitbetalingen,
  (SELECT count(*) FROM public.payouts WHERE status = 'betaald')        AS waarvan_betaald,
  (SELECT COALESCE(sum(amount), 0) FROM public.ledger_entries)          AS totaal_in_spaarpotten;

-- Staat 'testmodus' op 'uit'? Dan is de testfase voorbij en werkt dit script
-- niet meer. Dat is geen storing, dat is het slot.


-- ── STAP 2: de reset ────────────────────────────────────────
-- Alles in één transactie: gaat er iets mis, dan gebeurt er niets.

BEGIN;

  -- Eerst de mutaties (die verwijzen naar uitbetalingen)
  DELETE FROM public.ledger_entries;

  -- Dan de uitbetalingen zelf
  DELETE FROM public.payouts;

COMMIT;


-- ── STAP 3: controleren ─────────────────────────────────────
-- Verwacht: overal 0, en alle personen op saldo 0.

SELECT
  (SELECT count(*) FROM public.ledger_entries) AS mutaties,
  (SELECT count(*) FROM public.payouts)        AS uitbetalingen;

SELECT count(*) AS personen_met_saldo_niet_nul
  FROM public.person_balances
 WHERE saldo <> 0;


-- ── OPTIONEEL: statements weer op "nog niet geboekt" ────────
-- Alleen nodig als je ook de markering "buiten administratie" wilt terugzetten.
-- Let op: hierna staan 09-2025 en 12-2025 weer als te boeken in beeld.
--
-- UPDATE public.statements SET buiten_administratie = false;
