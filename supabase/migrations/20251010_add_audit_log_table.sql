-- 20251010_add_audit_log_table.sql
-- Purpose: audit trail for payouts_v2 (INSERT / UPDATE / DELETE)
BEGIN;

-- 1) Audit table
CREATE TABLE IF NOT EXISTS public.payout_audit_log (
  id BIGSERIAL PRIMARY KEY,
  payout_id INTEGER REFERENCES public.payouts_v2(id) ON DELETE SET NULL,
  transaction_id INTEGER,
  action_type TEXT NOT NULL CHECK (action_type IN ('INSERT','UPDATE','DELETE')),
  old_data JSONB,
  new_data JSONB,
  change_source TEXT,                 -- name of trigger or context
  changed_by TEXT DEFAULT current_user,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2) Indexes for fast lookups (non-blocking recommended after commit if needed)
-- We'll create normally; if you prefer CONCURRENTLY, run those lines after commit manually.
CREATE INDEX IF NOT EXISTS idx_payout_audit_log_created_at ON public.payout_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payout_audit_log_payout_id ON public.payout_audit_log (payout_id);
CREATE INDEX IF NOT EXISTS idx_payout_audit_log_transaction_id ON public.payout_audit_log (transaction_id);

-- 3) Trigger function to write audit rows
CREATE OR REPLACE FUNCTION public.log_payout_audit()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.payout_audit_log (
      payout_id, transaction_id, action_type, new_data, change_source, changed_by, created_at
    ) VALUES (
      NEW.id,
      NEW.transaction_id,
      'INSERT',
      row_to_json(NEW)::jsonb,
      TG_NAME,
      current_user,
      now()
    );
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO public.payout_audit_log (
      payout_id, transaction_id, action_type, old_data, new_data, change_source, changed_by, created_at
    ) VALUES (
      NEW.id,
      NEW.transaction_id,
      'UPDATE',
      row_to_json(OLD)::jsonb,
      row_to_json(NEW)::jsonb,
      TG_NAME,
      current_user,
      now()
    );
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO public.payout_audit_log (
      payout_id, transaction_id, action_type, old_data, change_source, changed_by, created_at
    ) VALUES (
      OLD.id,
      OLD.transaction_id,
      'DELETE',
      row_to_json(OLD)::jsonb,
      TG_NAME,
      current_user,
      now()
    );
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4) Attach trigger to payouts_v2
DROP TRIGGER IF EXISTS trg_payout_audit ON public.payouts_v2;
CREATE TRIGGER trg_payout_audit
AFTER INSERT OR UPDATE OR DELETE ON public.payouts_v2
FOR EACH ROW
EXECUTE FUNCTION public.log_payout_audit();

COMMIT;

