BEGIN;

-- ============================================================
-- 🧠 Phase 3.2 Patch (v3)
-- Align create_payouts_for_sale() with live payouts_v2 schema
-- ============================================================

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
  -- 🧩 IP HOLDER PAYOUT
  IF ip_pct > 0 THEN
    INSERT INTO public.payouts_v2
      (transaction_id, recipient_entity, recipient_role, amount, currency, status, created_at)
    VALUES
      (NEW.sale_id, NULL, 'ip_holder', ROUND(NEW.gross_amount * ip_pct, 2), sale_currency, 'queued', now());
  END IF;

  -- 🧩 CREATOR PAYOUT
  IF creator_pct > 0 THEN
    INSERT INTO public.payouts_v2
      (transaction_id, recipient_entity, recipient_role, amount, currency, status, created_at)
    VALUES
      (NEW.sale_id, NULL, 'creator', ROUND(NEW.gross_amount * creator_pct, 2), sale_currency, 'queued', now());
  END IF;

  -- 🧩 REFERRER PAYOUT
  IF referrer_pct > 0 AND NEW.referrer_id IS NOT NULL THEN
    INSERT INTO public.payouts_v2
      (transaction_id, recipient_entity, recipient_role, amount, currency, status, created_at)
    VALUES
      (NEW.sale_id, NULL, 'referrer', ROUND(NEW.gross_amount * referrer_pct, 2), sale_currency, 'queued', now());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_payouts
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.create_payouts_for_sale();

COMMIT;
