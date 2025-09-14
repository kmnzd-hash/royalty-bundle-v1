-- migration: create_payouts_trigger
BEGIN;

-- ensure uuid generator
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- drop trigger if exists so we can recreate (safe)
DROP TRIGGER IF EXISTS trg_after_sale_insert ON public.sales;

-- create or replace function that uses NEW.sale_id
CREATE OR REPLACE FUNCTION public.create_payouts_for_sale()
RETURNS trigger AS $$
DECLARE
  ip_pct numeric;
  creator_pct numeric;
  referrer_pct numeric;
  amount_ip numeric;
  amount_creator numeric;
  amount_referrer numeric;
BEGIN
  ip_pct := COALESCE(NULLIF(split_part(NEW.override_pct, '/', 1), ''), '0')::numeric;
  creator_pct := COALESCE(NULLIF(split_part(NEW.override_pct, '/', 2), ''), '0')::numeric;
  referrer_pct := COALESCE(NULLIF(split_part(NEW.override_pct, '/', 3), ''), '0')::numeric;

  amount_ip := round(NEW.gross_amount * ip_pct / 100.0, 2);
  amount_creator := round(NEW.gross_amount * creator_pct / 100.0, 2);
  amount_referrer := round(NEW.gross_amount * referrer_pct / 100.0, 2);

  INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)
  VALUES (NEW.sale_id, 'ip_holder', NEW.ip_holder, ip_pct, amount_ip, 'queued', now());

  INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)
  VALUES (NEW.sale_id, 'creator', NEW.creator_id, creator_pct, amount_creator, 'queued', now());

  INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)
  VALUES (NEW.sale_id, 'referrer', NEW.referrer_id, referrer_pct, amount_referrer, 'queued', now());

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- recreate trigger
CREATE TRIGGER trg_after_sale_insert
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.create_payouts_for_sale();

COMMIT;

