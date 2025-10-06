-- 20251005_migrate_payouts_to_v2.sql
BEGIN;

-- Ensure pgcrypto exists (payout_uuid default)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create a unique index used for ON CONFLICT upserts (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind = 'i'
        AND c.relname = 'payouts_v2_unique_txn_role'
  ) THEN
    CREATE UNIQUE INDEX payouts_v2_unique_txn_role
      ON public.payouts_v2 (transaction_id, recipient_role);
  END IF;
END
$$;

-- Drop old trigger (if any) and old legacy function to avoid conflicts
DROP TRIGGER IF EXISTS trg_after_transaction_insert ON public.transactions;
DROP FUNCTION IF EXISTS public.create_or_update_payouts_for_sale() CASCADE;

-- Create the new trigger function that writes to payouts_v2
CREATE OR REPLACE FUNCTION public.create_or_update_payouts_for_transaction()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  b RECORD;
  pct_array numeric[];
  ip_pct numeric := 0;
  creator_pct numeric := 0;
  referrer_pct numeric := 0;
  txn_amount numeric := COALESCE(NEW.sale_amount, NEW.gross_amount, 0);
  amount_ip numeric;
  amount_creator numeric;
  amount_referrer numeric;
  currency_text text := COALESCE(NEW.sale_currency, '');
BEGIN
  -- Grab bundle info (assumes bundles has bundle_id as PK)
  SELECT entity_from, entity_to, ip_holder, override_pct, COALESCE(referrer_id, NULL) AS referrer_id
    INTO b
    FROM public.bundles
   WHERE bundle_id = NEW.bundle_id
   LIMIT 1;

  IF NOT FOUND THEN
    RAISE NOTICE 'create_or_update_payouts_for_transaction: bundle % not found', NEW.bundle_id;
    RETURN NEW;
  END IF;

  -- Parse override_pct: first try bundle.override_pct, fall back to metadata.override_pct if available, else '0/0/0'
  pct_array := ARRAY[
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct, NEW.metadata->>'override_pct', '0/0/0'), '/', 1), ''), '0')::numeric,
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct, NEW.metadata->>'override_pct', '0/0/0'), '/', 2), ''), '0')::numeric,
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct, NEW.metadata->>'override_pct', '0/0/0'), '/', 3), ''), '0')::numeric
  ];

  -- sort descending so index 1 is the largest (IP typically)
  SELECT array_agg(v ORDER BY v DESC) INTO pct_array FROM unnest(pct_array) AS v;

  ip_pct      := COALESCE(pct_array[1], 0);
  creator_pct := COALESCE(pct_array[2], 0);
  referrer_pct:= COALESCE(pct_array[3], 0);

  amount_ip      := round(txn_amount * ip_pct / 100.0, 2);
  amount_creator := round(txn_amount * creator_pct / 100.0, 2);
  amount_referrer:= round(txn_amount * referrer_pct / 100.0, 2);

  -- Upsert executor: per SOP executor receives full txn_amount (recipient_entity = entity_to)
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

  -- Upsert IP holder
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

  -- Upsert Creator (here we use entity_from as creator)
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

  -- Upsert Referrer (if no referrer id, recipient_entity will be NULL -> that's OK)
  INSERT INTO public.payouts_v2
    (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES
    (NEW.id, NEW.sale_id, b.referrer_id, 'referrer', amount_referrer, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role) DO UPDATE
    SET recipient_entity = EXCLUDED.recipient_entity,
        amount = EXCLUDED.amount,
        currency = EXCLUDED.currency,
        status = EXCLUDED.status,
        created_at = EXCLUDED.created_at;

  RETURN NEW;
END;
$$;

-- Recreate the trigger to call the new function
DROP TRIGGER IF EXISTS trg_after_transaction_insert ON public.transactions;
CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.create_or_update_payouts_for_transaction();

COMMIT;

