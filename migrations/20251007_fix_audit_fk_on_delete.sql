-- 20251007_fix_audit_fk_on_delete.sql
BEGIN;

-- Drop and recreate the constraint with safe nullify behavior
ALTER TABLE public.payout_audit_log
  DROP CONSTRAINT IF EXISTS payout_audit_log_payout_id_fkey,
  ADD CONSTRAINT payout_audit_log_payout_id_fkey
  FOREIGN KEY (payout_id)
  REFERENCES public.payouts_v2(id)
  ON DELETE SET NULL
  DEFERRABLE INITIALLY IMMEDIATE;

COMMIT;
