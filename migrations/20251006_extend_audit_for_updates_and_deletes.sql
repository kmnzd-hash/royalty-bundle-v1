-- 20251006_extend_audit_for_updates_and_deletes.sql (patched)
BEGIN;

-- ===========================================================
-- PURPOSE:
--   Extend audit coverage to include UPDATE and DELETE events
--   for payouts_v2, using the safe helper add_payout_audit_entry().
-- ===========================================================

-- 1️⃣ Update the audit helper for clearer typing and defaults
CREATE OR REPLACE FUNCTION public.add_payout_audit_entry(
  p_action TEXT,
  p_payout_id INT,
  p_transaction_id INT,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.payout_audit_log (action_type, payout_id, transaction_id, old_data, new_data, created_at)
  VALUES (p_action, p_payout_id, p_transaction_id, p_old_data, p_new_data, now());
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Audit insert failed for payout_id=% with error: %', p_payout_id, SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.add_payout_audit_entry(TEXT, INT, INT, JSONB, JSONB)
IS 'Safely inserts an audit record into payout_audit_log for INSERT, UPDATE, DELETE operations.';

-- ===========================================================
-- 2️⃣ CREATE AUDIT TRIGGERS FOR payouts_v2
-- ===========================================================

-- --- Insert audit trigger
CREATE OR REPLACE FUNCTION public.trg_audit_payouts_insert()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.add_payout_audit_entry(
    'INSERT',
    NEW.id,
    NEW.transaction_id,
    NULL,
    row_to_json(NEW)::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --- Update audit trigger (cast JSON → JSONB)
CREATE OR REPLACE FUNCTION public.trg_audit_payouts_update()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.add_payout_audit_entry(
    'UPDATE',
    NEW.id,
    NEW.transaction_id,
    row_to_json(OLD)::jsonb,
    row_to_json(NEW)::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --- Delete audit trigger (BEFORE DELETE fix)
CREATE OR REPLACE FUNCTION public.trg_audit_payouts_delete()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.add_payout_audit_entry(
    'DELETE',
    OLD.id,
    OLD.transaction_id,
    row_to_json(OLD)::jsonb,
    NULL
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================================
-- 3️⃣ ATTACH THE TRIGGERS TO payouts_v2 TABLE
-- ===========================================================

-- Drop old triggers
DROP TRIGGER IF EXISTS trg_payouts_insert_audit ON public.payouts_v2;
DROP TRIGGER IF EXISTS trg_payouts_update_audit ON public.payouts_v2;
DROP TRIGGER IF EXISTS trg_payouts_delete_audit ON public.payouts_v2;

CREATE TRIGGER trg_payouts_insert_audit
AFTER INSERT ON public.payouts_v2
FOR EACH ROW
EXECUTE FUNCTION public.trg_audit_payouts_insert();

CREATE TRIGGER trg_payouts_update_audit
AFTER UPDATE ON public.payouts_v2
FOR EACH ROW
EXECUTE FUNCTION public.trg_audit_payouts_update();

CREATE TRIGGER trg_payouts_delete_audit
BEFORE DELETE ON public.payouts_v2
FOR EACH ROW
EXECUTE FUNCTION public.trg_audit_payouts_delete();

COMMIT;
