BEGIN;

-- ======================================================
-- 🧠 PHASE 3.2 FIX — ENSURE override_pct IS TEXT
-- ======================================================

-- If override_pct exists but isn't text, convert it safely
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'bundles'
      AND column_name = 'override_pct'
      AND data_type != 'text'
  ) THEN
    ALTER TABLE public.bundles
      ALTER COLUMN override_pct TYPE text
      USING override_pct::text;
  END IF;
END $$;

COMMIT;
