-- 20251006_create_audit_helper_function.sql
BEGIN;

-- ===========================================================
-- Purpose:
--   Create a callable version of the payout audit logger that
--   can be invoked manually inside functions (non-trigger-safe)
--   to log INSERT, UPDATE, or DELETE events on payouts_v2.
-- ===========================================================

CREATE OR REPLACE FUNCTION public.add_payout_audit_entry(
  p_action TEXT,
  p_payout_id INT,
  p_transaction_id INT,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  -- Validate action
  IF p_action NOT IN ('INSERT', 'UPDATE', 'DELETE') THEN
    RAISE NOTICE 'Invalid audit action: %', p_action;
    RETURN;
  END IF;

  -- Safely insert into audit log table
  BEGIN
    INSERT INTO public.payout_audit_log (
      action_type,
      payout_id,
      transaction_id,
      old_data,
      new_data,
      created_at
    )
    VALUES (
      p_action,
      p_payout_id,
      p_transaction_id,
      p_old_data,
      p_new_data,
      now()
    );

    -- Optional dev-time notice (comment out in prod)
    RAISE NOTICE 'Audit log added → Action: %, Txn: %, Payout ID: %', p_action, p_transaction_id, p_payout_id;

  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Audit insert failed for payout_id %: %', p_payout_id, SQLERRM;
  END;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.add_payout_audit_entry(TEXT, INT, INT, JSONB, JSONB)
IS 'Safely logs manual audit entries for payouts_v2. Callable from within payout automation functions.';

COMMIT;
