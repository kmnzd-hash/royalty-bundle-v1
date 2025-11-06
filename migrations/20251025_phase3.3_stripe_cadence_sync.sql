BEGIN;

-- ==========================================================
-- 💳 Phase 3.3: Stripe Billing Cadence + Metadata Alignment
-- ==========================================================

-- 1️⃣ Add billing cadence columns to SALES (for recurring Stripe sync)
ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS cadence text CHECK (cadence IN ('once','monthly','quarterly','annual')) DEFAULT 'monthly',
  ADD COLUMN IF NOT EXISTS term_months integer DEFAULT 12,
  ADD COLUMN IF NOT EXISTS billing_day smallint CHECK (billing_day BETWEEN 1 AND 28) DEFAULT 15,
  ADD COLUMN IF NOT EXISTS stripe_invoice_id text,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text;

COMMENT ON COLUMN public.sales.cadence IS 'Defines recurring billing cadence for Stripe sync';
COMMENT ON COLUMN public.sales.term_months IS 'Duration of billing term in months';
COMMENT ON COLUMN public.sales.billing_day IS 'Day of month billing occurs (1–28)';
COMMENT ON COLUMN public.sales.stripe_invoice_id IS 'Reference to Stripe invoice object';
COMMENT ON COLUMN public.sales.stripe_subscription_id IS 'Reference to Stripe subscription object';

-- 2️⃣ Create table for Stripe Sync Logs
CREATE TABLE IF NOT EXISTS public.stripe_sync_log (
    id serial PRIMARY KEY,
    sale_id integer REFERENCES public.sales(sale_id) ON DELETE CASCADE,
    stripe_object text CHECK (stripe_object IN ('invoice','subscription','event')),
    object_id text,
    payload jsonb,
    status text CHECK (status IN ('queued','synced','failed')) DEFAULT 'queued',
    created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.stripe_sync_log IS 'Tracks every Stripe sync payload for audit and DAO evidence';

-- 3️⃣ Create helper function to enqueue Stripe syncs
CREATE OR REPLACE FUNCTION public.enqueue_stripe_sync()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.stripe_sync_log (sale_id, stripe_object, object_id, payload, status)
  VALUES (NEW.sale_id, 'invoice', NEW.stripe_invoice_id, '{}'::jsonb, 'queued');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4️⃣ Add trigger: when sale is inserted, enqueue for Stripe sync
DROP TRIGGER IF EXISTS trg_enqueue_stripe_sync ON public.sales;
CREATE TRIGGER trg_enqueue_stripe_sync
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_stripe_sync();

COMMIT;
