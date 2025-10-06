-- 20251005_fix_smart_payout_trigger.sql
-- Fix: Adjust type casting and ref structure for smart payout trigger (v2)

BEGIN;

-- Drop old function safely (if it exists)
DROP FUNCTION IF EXISTS public.create_or_update_payouts_for_transaction() CASCADE;

-- Recreate updated version of the trigger function
CREATE OR REPLACE FUNCTION public.create_or_update_payouts_for_transaction()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  b RECORD;
  pct_array numeric[];
  ip_pct numeric := 0;
  creator_pct numeric := 0;
  txn_amount numeric := COALESCE(NEW.sale_amount, 0);
  amount_ip numeric;
  amount_creator numeric;
  currency_text text := COALESCE(NEW.sale_currency, '');
BEGIN
  -- Fetch bundle metadata
  SELECT entity_from, entity_to, ip_holder, override_pct
    INTO b
    FROM public.bundles
   WHERE bundle_id = NEW.bundle_id
   LIMIT 1;

  IF NOT FOUND THEN
    RAISE NOTICE 'Bundle % not found for transaction %', NEW.bundle_id, NEW.id;
    RETURN NEW;
  END IF;

  -- Fix: cast override_pct to text before split
  pct_array := ARRAY[
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 1), '')::numeric, 0),
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 2), '')::numeric, 0),
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 3), '')::numeric, 0)
  ];

  SELECT array_agg(v ORDER BY v DESC) INTO pct_array FROM unnest(pct_array) AS v;

  ip_pct := COALESCE(pct_array[1], 0);
  creator_pct := COALESCE(pct_array[2], 0);

  amount_ip := round(txn_amount * ip_pct / 100.0, 2);
  amount_creator := round(txn_amount * creator_pct / 100.0, 2);

  -- Upsert payouts into payouts_v2 (unified table)
  INSERT INTO public.payouts_v2
    (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES
    (NEW.id, NEW.sale_id, b.entity_to, 'executor', txn_amount, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role) DO UPDATE
    SET recipient_entity = EXCLUDED.recipient_entity,
        amount = EXCLUDED.amount,
        currency = EXCLUDED.currency,
        status = EXCLUDED.status,
        created_at = EXCLUDED.created_at;

  INSERT INTO public.payouts_v2
    (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES
    (NEW.id, NEW.sale_id, b.ip_holder, 'ip_holder', amount_ip, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role) DO UPDATE
    SET recipient_entity = EXCLUDED.recipient_entity,
        amount = EXCLUDED.amount,
        currency = EXCLUDED.currency,
        status = EXCLUDED.status,
        created_at = EXCLUDED.created_at;

  INSERT INTO public.payouts_v2
    (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES
    (NEW.id, NEW.sale_id, b.entity_from, 'creator', amount_creator, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role) DO UPDATE
    SET recipient_entity = EXCLUDED.recipient_entity,
        amount = EXCLUDED.amount,
        currency = EXCLUDED.currency,
        status = EXCLUDED.status,
        created_at = EXCLUDED.created_at;

  RETURN NEW;
END;
$$;

-- Recreate trigger link
DROP TRIGGER IF EXISTS trg_after_transaction_insert ON public.transactions;
CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.create_or_update_payouts_for_transaction();

COMMIT;
