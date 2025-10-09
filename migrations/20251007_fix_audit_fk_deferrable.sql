-- migrations/20251007_fix_audit_fk_deferrable.sql
BEGIN;

-- Make payout_audit_log.payout_id FK deferrable so audit inserts during deletes succeed
ALTER TABLE public.payout_audit_log
  DROP CONSTRAINT IF EXISTS payout_audit_log_payout_id_fkey;

ALTER TABLE public.payout_audit_log
  ADD CONSTRAINT payout_audit_log_payout_id_fkey
  FOREIGN KEY (payout_id)
  REFERENCES public.payouts_v2(id)
  DEFERRABLE INITIALLY DEFERRED;

COMMIT;
