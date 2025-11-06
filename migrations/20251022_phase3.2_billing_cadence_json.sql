BEGIN;

-- ========================================================
-- 🧠 PHASE 3.2 — BILLING CADENCE + JSON OVERRIDE MIGRATION
-- ========================================================

-- 1️⃣  Ensure bundles table has JSON overrides
ALTER TABLE public.bundles
  ADD COLUMN IF NOT EXISTS override_json jsonb;

UPDATE public.bundles
SET override_json = (
  CASE
    WHEN override_json IS NOT NULL THEN override_json
    WHEN override_pct ~ '^\s*\{.*\}\s*$' THEN override_pct::jsonb
    ELSE jsonb_build_object(
      'ip',       NULLIF(split_part(override_pct,'/',1),'')::numeric / 100.0,
      'creator',  NULLIF(split_part(override_pct,'/',2),'')::numeric / 100.0,
      'referrer', NULLIF(split_part(override_pct,'/',3),'')::numeric / 100.0
    )
  END
)
WHERE override_json IS NULL;

ALTER TABLE public.bundles DROP COLUMN IF EXISTS override_pct;

-- 2️⃣  Offers table — cadence and billing schedule
ALTER TABLE public.offers
  ADD COLUMN IF NOT EXISTS cadence text CHECK (cadence IN ('once','monthly','quarterly','annual')) DEFAULT 'monthly',
  ADD COLUMN IF NOT EXISTS term_months integer,
  ADD COLUMN IF NOT EXISTS billing_day smallint CHECK (billing_day BETWEEN 1 AND 28) DEFAULT 15;

COMMENT ON COLUMN public.offers.cadence IS 'Defines the billing rhythm for each offer (once, monthly, quarterly, annual).';
COMMENT ON COLUMN public.offers.term_months IS 'Defines how long the billing cycle lasts in months (e.g., 12, 24, 36).';
COMMENT ON COLUMN public.offers.billing_day IS 'Day of the month when billing occurs (1–28).';

-- 3️⃣  Create payout trigger using JSON override
CREATE OR REPLACE FUNCTION public.create_payouts_for_sale()
RETURNS TRIGGER AS $$
DECLARE
  ip_pct numeric := COALESCE((NEW.override_json->>'ip')::numeric, 0);
  creator_pct numeric := COALESCE((NEW.override_json->>'creator')::numeric, 0);
  referrer_pct numeric := COALESCE((NEW.override_json->>'referrer')::numeric, 0);
BEGIN
  IF ip_pct > 0 THEN
    INSERT INTO public.payouts_v2 (transaction_id, recipient_role, recipient_id, pct, amount, payout_status, created_at)
    VALUES (NEW.sale_id, 'ip_holder', NEW.ip_holder, ip_pct, ROUND(NEW.gross_amount * ip_pct, 2), 'queued', now());
  END IF;

  IF creator_pct > 0 THEN
    INSERT INTO public.payouts_v2 (transaction_id, recipient_role, recipient_id, pct, amount, payout_status, created_at)
    VALUES (NEW.sale_id, 'creator', NEW.creator_id, creator_pct, ROUND(NEW.gross_amount * creator_pct, 2), 'queued', now());
  END IF;

  IF referrer_pct > 0 AND NEW.referrer_id IS NOT NULL THEN
    INSERT INTO public.payouts_v2 (transaction_id, recipient_role, recipient_id, pct, amount, payout_status, created_at)
    VALUES (NEW.sale_id, 'referrer', NEW.referrer_id, referrer_pct, ROUND(NEW.gross_amount * referrer_pct, 2), 'queued', now());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_create_payouts ON public.sales;

CREATE TRIGGER trg_create_payouts
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.create_payouts_for_sale();

COMMIT;
