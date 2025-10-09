-- 20251006_add_payout_audit_trigger.sql
BEGIN;

-- Create audit function (safe replace)
CREATE OR REPLACE FUNCTION public.log_payout_audit()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO public.payout_audit_log (payout_id, transaction_id, action_type, new_data)
    VALUES (NEW.id, NEW.transaction_id, TG_OP, row_to_json(NEW));
    RETURN NEW;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO public.payout_audit_log (payout_id, transaction_id, action_type, old_data, new_data)
    VALUES (NEW.id, NEW.transaction_id, TG_OP, row_to_json(OLD), row_to_json(NEW));
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO public.payout_audit_log (payout_id, transaction_id, action_type, old_data)
    VALUES (OLD.id, OLD.transaction_id, TG_OP, row_to_json(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trg_payout_audit ON public.payouts_v2;
CREATE TRIGGER trg_payout_audit
AFTER INSERT OR UPDATE OR DELETE ON public.payouts_v2
FOR EACH ROW EXECUTE FUNCTION public.log_payout_audit();

COMMIT;

