-- 20251006_fix_override_casting.sql
BEGIN;

-- Drop the old function safely
DROP FUNCTION IF EXISTS public.create_or_update_payouts_for_transaction() CASCADE;

-- Recreate with proper override parsing from metadata
CREATE OR REPLACE FUNCTION public.create_or_update_payouts_for_transaction()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  b RECORD;
  pct_array TEXT[];
  ip_pct NUMERIC := 0;
  creator_pct NUMERIC := 0;
  referrer_pct NUMERIC := 0;
  txn_amount NUMERIC := COALESCE(NEW.sale_amount, 0);
  amount_ip NUMERIC;
  amount_creator NUMERIC;
  amount_referrer NUMERIC;
  currency_text TEXT := COALESCE(NEW.sale_currency, 'USD');
  override_text TEXT;
BEGIN
  -- Get bundle info
  SELECT entity_from, entity_to, ip_holder, override_pct::TEXT
  INTO b
  FROM public.bundles
  WHERE bundle_id = NEW.bundle_id
  LIMIT 1;

  -- Prefer metadata override_pct if present
  override_text := COALESCE(NEW.metadata->>'override_pct', b.override_pct, '0/0/0');

  pct_array := string_to_array(override_text, '/');

  ip_pct := COALESCE(pct_array[1]::NUMERIC, 0);
  creator_pct := COALESCE(pct_array[2]::NUMERIC, 0);
  referrer_pct := COALESCE(pct_array[3]::NUMERIC, 0);

  amount_ip := round(txn_amount * ip_pct / 100.0, 2);
  amount_creator := round(txn_amount * creator_pct / 100.0, 2);
  amount_referrer := round(txn_amount * referrer_pct / 100.0, 2);

  -- Insert payouts
  INSERT INTO public.payouts_v2 (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status)
  VALUES
    (NEW.id, NEW.sale_id, b.entity_to, 'executor', txn_amount, currency_text, 'queued'),
    (NEW.id, NEW.sale_id, b.ip_holder, 'ip_holder', amount_ip, currency_text, 'queued'),
    (NEW.id, NEW.sale_id, b.entity_from, 'creator', amount_creator, currency_text, 'queued')
  ON CONFLICT (transaction_id, recipient_role)
  DO UPDATE SET amount = EXCLUDED.amount, currency = EXCLUDED.currency, status = EXCLUDED.status;

  RETURN NEW;
END;
$$;

-- Recreate trigger
CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.create_or_update_payouts_for_transaction();

COMMIT;
