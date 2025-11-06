BEGIN;

-- ======================================================
-- 🧠 PHASE 3.2 PATCH — ALIGN create_payouts_for_sale() WITH payouts_v2
-- ======================================================

DROP TRIGGER IF EXISTS trg_create_payouts ON public.sales;
DROP FUNCTION IF EXISTS public.create_payouts_for_sale();

CREATE OR REPLACE FUNCTION public.create_payouts_for_sale()
RETURNS TRIGGER AS $$
DECLARE
  ip_pct numeric := COALESCE((NEW.override_json->>'ip')::numeric, 0);
  creator_pct numeric := COALESCE((NEW.override_json->>'creator')::numeric, 0);
  referrer_pct numeric := COALESCE((NEW.override_json->>'referrer')::numeric, 0);
BEGIN
  -- 🧩 IP HOLDER PAYOUT
  IF ip_pct > 0 THEN
    INSERT INTO public.payouts_v2 (transaction_id, recipient_role, recipient, percentage, payout_amount, payout_status, created_at)
    VALUES (NEW.sale_id, 'ip_holder', NEW.ip_holder, ip_pct, ROUND(NEW.gross_amount * ip_pct, 2), 'queued', now());
  END IF;

  -- 🧩 CREATOR PAYOUT
  IF creator_pct > 0 THEN
    INSERT INTO public.payouts_v2 (transaction_id, recipient_role, recipient, percentage, payout_amount, payout_status, created_at)
    VALUES (NEW.sale_id, 'creator', NEW.creator_id, creator_pct, ROUND(NEW.gross_amount * creator_pct, 2), 'queued', now());
  END IF;

  -- 🧩 REFERRER PAYOUT
  IF referrer_pct > 0 AND NEW.referrer_id IS NOT NULL THEN
    INSERT INTO public.payouts_v2 (transaction_id, recipient_role, recipient, percentage, payout_amount, payout_status, created_at)
    VALUES (NEW.sale_id, 'referrer', NEW.referrer_id, referrer_pct, ROUND(NEW.gross_amount * referrer_pct, 2), 'queued', now());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_payouts
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.create_payouts_for_sale();

COMMIT;
