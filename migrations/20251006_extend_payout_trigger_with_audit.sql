-- 20251006_extend_payout_trigger_with_audit.sql
BEGIN;

-- ===========================================================
-- Purpose:
--   Extend the payout creation trigger to call the safe audit
--   helper after each payout insert/update.
-- ===========================================================

CREATE OR REPLACE FUNCTION public.create_or_update_payouts_for_transaction()
RETURNS TRIGGER AS $$
DECLARE
  b RECORD;
  pct_array NUMERIC[];
  ip_pct NUMERIC := 0;
  creator_pct NUMERIC := 0;
  txn_amount NUMERIC := COALESCE(NEW.sale_amount, 0);
  amount_ip NUMERIC;
  amount_creator NUMERIC;
  currency_text TEXT := COALESCE(NEW.sale_currency, '');
  v_executor_id INT;
  v_ip_id INT;
  v_creator_id INT;
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

  -- Parse override percentage safely
  pct_array := ARRAY[
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 1), '')::NUMERIC, 0),
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 2), '')::NUMERIC, 0),
    COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 3), '')::NUMERIC, 0)
  ];

  -- Defensive: ensure array length = 3
  IF array_length(pct_array, 1) IS DISTINCT FROM 3 THEN
    pct_array := ARRAY[0, 0, 0];
  END IF;

  ip_pct := COALESCE(pct_array[1], 0);
  creator_pct := COALESCE(pct_array[2], 0);

  amount_ip := round(txn_amount * ip_pct / 100.0, 2);
  amount_creator := round(txn_amount * creator_pct / 100.0, 2);

  -- ============================================
  -- Executor payout
  -- ============================================
  INSERT INTO public.payouts_v2 (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES (NEW.id, NEW.sale_id, b.entity_to, 'executor', txn_amount, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role)
  DO UPDATE SET recipient_entity = EXCLUDED.recipient_entity,
                amount = EXCLUDED.amount,
                currency = EXCLUDED.currency,
                status = EXCLUDED.status,
                created_at = EXCLUDED.created_at
  RETURNING id INTO v_executor_id;

  PERFORM public.add_payout_audit_entry(
    'INSERT',
    v_executor_id,
    NEW.id,
    NULL,
    row_to_json(NEW)
  );

  -- ============================================
  -- IP holder payout
  -- ============================================
  INSERT INTO public.payouts_v2 (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES (NEW.id, NEW.sale_id, b.ip_holder, 'ip_holder', amount_ip, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role)
  DO UPDATE SET recipient_entity = EXCLUDED.recipient_entity,
                amount = EXCLUDED.amount,
                currency = EXCLUDED.currency,
                status = EXCLUDED.status,
                created_at = EXCLUDED.created_at
  RETURNING id INTO v_ip_id;

  PERFORM public.add_payout_audit_entry(
    'INSERT',
    v_ip_id,
    NEW.id,
    NULL,
    row_to_json(NEW)
  );

  -- ============================================
  -- Creator payout
  -- ============================================
  INSERT INTO public.payouts_v2 (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)
  VALUES (NEW.id, NEW.sale_id, b.entity_from, 'creator', amount_creator, currency_text, 'queued', now())
  ON CONFLICT (transaction_id, recipient_role)
  DO UPDATE SET recipient_entity = EXCLUDED.recipient_entity,
                amount = EXCLUDED.amount,
                currency = EXCLUDED.currency,
                status = EXCLUDED.status,
                created_at = EXCLUDED.created_at
  RETURNING id INTO v_creator_id;

  PERFORM public.add_payout_audit_entry(
    'INSERT',
    v_creator_id,
    NEW.id,
    NULL,
    row_to_json(NEW)
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_or_update_payouts_for_transaction()
IS 'Trigger function that creates payouts_v2 entries and logs audit entries using the safe audit helper.';

COMMIT;
