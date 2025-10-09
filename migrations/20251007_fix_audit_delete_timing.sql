-- 20251007_fix_audit_delete_timing.sql
BEGIN;

-- 1️⃣ Drop the AFTER DELETE trigger first
DROP TRIGGER IF EXISTS trg_payouts_delete_audit ON public.payouts_v2;

-- 2️⃣ Recreate it as a BEFORE DELETE trigger (so audit logs insert before row removal)
CREATE TRIGGER trg_payouts_delete_audit
BEFORE DELETE ON public.payouts_v2
FOR EACH ROW
EXECUTE FUNCTION public.trg_audit_payouts_delete();

-- 3️⃣ Optional safety: explicitly ensure FK constraint is deferrable immediate
ALTER TABLE public.payout_audit_log
    DROP CONSTRAINT IF EXISTS payout_audit_log_payout_id_fkey,
    ADD CONSTRAINT payout_audit_log_payout_id_fkey
    FOREIGN KEY (payout_id)
    REFERENCES public.payouts_v2(id)
    DEFERRABLE INITIALLY IMMEDIATE;

COMMIT;
