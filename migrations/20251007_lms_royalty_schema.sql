-- 2025-10-07 : LMS / Royalty Ledger Schema (Phase 2 → 3)
-- Aligned with live schema: bundles(bundle_id INT), transactions(id INT), payouts_v2(id INT)

BEGIN;

CREATE TABLE IF NOT EXISTS public.reuse_event_log (
    event_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_id      integer REFERENCES bundles(bundle_id),
    transaction_id integer REFERENCES transactions(id),
    reuse_context  text,
    reuse_value    numeric(12,2),
    created_at     timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.royalty_ledger (
    ledger_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payout_id      integer REFERENCES payouts_v2(id),
    transaction_id integer REFERENCES transactions(id),
    event_id       uuid REFERENCES reuse_event_log(event_id),
    amount         numeric(12,2),
    currency       text DEFAULT 'USD',
    status         text DEFAULT 'pending',
    created_at     timestamptz DEFAULT now() NOT NULL
);

-- Function: propagate royalty entry whenever a reuse event occurs
CREATE OR REPLACE FUNCTION public.process_reuse_event()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.royalty_ledger (event_id, transaction_id, amount, currency, status)
    VALUES (NEW.event_id, NEW.transaction_id, NEW.reuse_value, 'USD', 'queued');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: fire on insert into reuse_event_log
DROP TRIGGER IF EXISTS trg_process_reuse_event ON public.reuse_event_log;
CREATE TRIGGER trg_process_reuse_event
AFTER INSERT ON public.reuse_event_log
FOR EACH ROW
EXECUTE FUNCTION public.process_reuse_event();

COMMIT;
