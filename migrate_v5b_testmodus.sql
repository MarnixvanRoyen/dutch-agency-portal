-- ============================================================
-- DJ·World Portaal — v5b: testmodus voor de financiële administratie
--
-- Voer dit uit NA migrate_v5_financiele_admin.sql.
-- Al een eerdere versie van v5b gedraaid? Dan mag dit er gewoon overheen.
-- ============================================================
--
-- ZO WERKT HET
--
--   finadmin_testmodus = 'aan'   ← nu
--       Alles mag weg. Mutaties wissen, uitbetalingen wissen — ook betaalde,
--       want in de testfase is er nog niets echt betaald. Statements kun je
--       ontboeken, verwijderen en opnieuw toevoegen zo vaak je wilt.
--
--   finadmin_testmodus = 'uit'   ← zodra Rob echt gaat betalen
--       Er kan niets meer gewist worden. Een fout herstel je met een
--       tegenboeking, een uitbetaling zet je op 'geannuleerd'.
--       Dit slot is absoluut: het kijkt niet of er al betaald is.
--
-- ⚠️ Jij zet die schakelaar om. Zolang hij op 'aan' staat is de administratie
--    niet beschermd — dat is precies de bedoeling tijdens het testen, maar
--    vergeet hem niet op het moment dat het echt wordt.
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- BLOK 1 — De schakelaar
-- ────────────────────────────────────────────────────────────

INSERT INTO public.settings (key, value)
VALUES ('finadmin_testmodus', 'aan')
ON CONFLICT (key) DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- BLOK 2 — Het slot
-- ────────────────────────────────────────────────────────────
-- Eén functie, gebruikt door twee triggers. Staat de administratie niet
-- expliciet op 'aan', dan is wissen onmogelijk. Ontbreekt de instelling
-- helemaal, dan geldt óók geblokkeerd — bij twijfel niets weggooien.

CREATE OR REPLACE FUNCTION public.blokkeer_wissen_in_productie()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  modus text;
BEGIN
  SELECT value INTO modus FROM public.settings WHERE key = 'finadmin_testmodus';

  IF COALESCE(modus, 'uit') <> 'aan' THEN
    RAISE EXCEPTION
      'De administratie staat op productie (finadmin_testmodus = uit). Wissen kan niet meer — maak een tegenboeking, of zet de uitbetaling op geannuleerd.';
  END IF;

  RETURN OLD;
END;
$$;

-- Oude versie uit een eerdere poging opruimen
DROP TRIGGER IF EXISTS geen_wissen_na_betaling ON public.ledger_entries;
DROP FUNCTION IF EXISTS public.blokkeer_wissen_na_betaling();

DROP TRIGGER IF EXISTS geen_wissen_in_productie ON public.ledger_entries;
CREATE TRIGGER geen_wissen_in_productie
  BEFORE DELETE ON public.ledger_entries
  FOR EACH ROW EXECUTE FUNCTION public.blokkeer_wissen_in_productie();

DROP TRIGGER IF EXISTS geen_wissen_in_productie ON public.payouts;
CREATE TRIGGER geen_wissen_in_productie
  BEFORE DELETE ON public.payouts
  FOR EACH ROW EXECUTE FUNCTION public.blokkeer_wissen_in_productie();


-- CONTROLE — verwacht: 'aan', en twee triggers (één per tabel)
SELECT key, value FROM public.settings WHERE key = 'finadmin_testmodus';

SELECT c.relname AS tabel, t.tgname AS trigger_naam
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
 WHERE NOT t.tgisinternal
   AND c.relname IN ('ledger_entries','payouts')
 ORDER BY c.relname;

NOTIFY pgrst, 'reload schema';


-- ============================================================
-- LATER: het slot erop doen
-- ============================================================
-- Als het testen klaar is en Rob echt gaat betalen, draai je dit ene regeltje.
-- Vanaf dat moment kan er niets meer gewist worden.
--
--   UPDATE public.settings SET value = 'uit' WHERE key = 'finadmin_testmodus';
--
-- Terugzetten kan technisch, maar doe dat niet zodra er echt betaald is.
