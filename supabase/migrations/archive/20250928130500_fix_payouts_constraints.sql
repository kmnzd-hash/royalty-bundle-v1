-- 2025-09-28_fix_payouts_constraints.sql
BEGIN;

-- Ensure payouts table has payout_id uuid column
ALTER TABLE public.payouts
  ADD COLUMN IF NOT EXISTS payout_id uuid DEFAULT gen_random_uuid();

-- Create unique index on (sale_id, recipient_role)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
      AND c.relname = 'payouts_unique_sale_role'
  ) THEN
    CREATE UNIQUE INDEX payouts_unique_sale_role
    ON public.payouts (sale_id, recipient_role);
  END IF;
END
$$;

COMMIT;

