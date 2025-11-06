BEGIN;

-- 1) Add override_json to sales and bundles
ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS override_json jsonb;

UPDATE public.sales
SET override_json = (
  CASE
    WHEN override_pct IS NULL OR trim(override_pct) = '' THEN '{}'::jsonb
    WHEN override_pct ~ '^\s*\{.*\}\s*$' THEN override_pct::jsonb
    ELSE jsonb_build_object(
      'ip',       COALESCE(NULLIF(split_part(override_pct,'/',1),'')::numeric,0) / 100.0,
      'creator',  COALESCE(NULLIF(split_part(override_pct,'/',2),'')::numeric,0) / 100.0,
      'referrer', COALESCE(NULLIF(split_part(override_pct,'/',3),'')::numeric,0) / 100.0
    )
  END
);

ALTER TABLE public.sales DROP COLUMN IF EXISTS override_pct;

ALTER TABLE public.bundles
  ADD COLUMN IF NOT EXISTS override_json jsonb;

UPDATE public.bundles
SET override_json = (
  CASE
    WHEN override_pct IS NULL OR trim(override_pct) = '' THEN '{}'::jsonb
    WHEN override_pct ~ '^\s*\{.*\}\s*$' THEN override_pct::jsonb
    ELSE jsonb_build_object(
      'ip',       COALESCE(NULLIF(split_part(override_pct,'/',1),'')::numeric,0) / 100.0,
      'creator',  COALESCE(NULLIF(split_part(override_pct,'/',2),'')::numeric,0) / 100.0,
      'referrer', COALESCE(NULLIF(split_part(override_pct,'/',3),'')::numeric,0) / 100.0
    )
  END
);

ALTER TABLE public.bundles DROP COLUMN IF EXISTS override_pct;

-- 2) Add cadence to offers
ALTER TABLE public.offers
  ADD COLUMN IF NOT EXISTS cadence text CHECK (cadence IN ('once','monthly','quarterly','annual')) DEFAULT 'monthly',
  ADD COLUMN IF NOT EXISTS term_months integer,
  ADD COLUMN IF NOT EXISTS billing_day smallint CHECK (billing_day BETWEEN 1 AND 28) DEFAULT 15;

-- 3) Create / replace payout creation trigger that uses override_json
CREATE OR REPLACE FUNCTION public.create_payouts_for_sale()
RETURNS TRIGGER AS $$
DECLARE
  ip_pct numeric := COALESCE((NEW.override_json->>'ip')::numeric, 0);
  creator_pct numeric := COALESCE((NEW.override_json->>'creator')::numeric, 0);
  referrer_pct numeric := COALESCE((NEW.override_json->>'referrer')::numeric, 0);
BEGIN
  IF ip_pct > 0 THEN
    INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)
    VALUES (NEW.sale_id, 'ip_holder', NEW.ip_holder, ip_pct, ROUND(NEW.gross_amount * ip_pct, 2), 'queued', now());
  END IF;

  IF creator_pct > 0 THEN
    INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)
    VALUES (NEW.sale_id, 'creator', NEW.creator_id, creator_pct, ROUND(NEW.gross_amount * creator_pct, 2), 'queued', now());
  END IF;

  IF referrer_pct > 0 AND NEW.referrer_id IS NOT NULL THEN
    INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)
    VALUES (NEW.sale_id, 'referrer', NEW.referrer_id, referrer_pct, ROUND(NEW.gross_amount * referrer_pct, 2), 'queued', now());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger (after insert on sales)
DROP TRIGGER IF EXISTS trg_create_payouts ON public.sales;
CREATE TRIGGER trg_create_payouts
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.create_payouts_for_sale();

COMMIT;
