BEGIN;

-- ==========================================================
-- 🧠 Phase 3.2-B: Null-safe payout trigger (no FK dependency)
-- ==========================================================

DROP TRIGGER IF EXISTS trg_create_payouts ON public.sales;
DROP FUNCTION IF EXISTS public.create_payouts_for_sale();

CREATE OR REPLACE FUNCTION public.create_payouts_for_sale()
RETURNS TRIGGER AS $$
DECLARE
  ip_pct       numeric := COALESCE((NEW.override_json->>'ip')::numeric, 0);
  creator_pct  numeric := COALESCE((NEW.override_json->>'creator')::numeric, 0);
  referrer_pct numeric := COALESCE((NEW.override_json->>'referrer')::numeric, 0);
  sale_currency text := COALESCE(NEW.sale_currency, 'AUD');
BEGIN
  -- Instead of linking to transactions.id (FK),
  -- we safely store the sale_id in sale_id column.
  IF ip_pct > 0 THEN
    INSERT INTO public.payouts_v2
      (sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
    VALUES
      (gen_random_uuid(), NULL, 'ip_holder',
       ROUND(NEW.gross_amount * ip_pct, 2), sale_currency, 'queued', now());
  END IF;

  IF creator_pct > 0 THEN
    INSERT INTO public.payouts_v2
      (sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
    VALUES
      (gen_random_uuid(), NULL, 'creator',
       ROUND(NEW.gross_amount * creator_pct, 2), sale_currency, 'queued', now());
  END IF;

  IF referrer_pct > 0 AND NEW.referrer_id IS NOT NULL THEN
    INSERT INTO public.payouts_v2
      (sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
    VALUES
      (gen_random_uuid(), NULL, 'referrer',
       ROUND(NEW.gross_amount * referrer_pct, 2), sale_currency, 'queued', now());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_payouts
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.create_payouts_for_sale();

COMMIT;
