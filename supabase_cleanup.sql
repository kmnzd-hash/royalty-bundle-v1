-- supabase_cleanup.sql
-- Run this against your SUPABASE_DB_URL. This truncates key tables but preserves schema.
-- IMPORTANT: double-check table list to avoid removing anything you want to keep.

BEGIN;

-- stop dependent rows reliably and reset sequences
TRUNCATE TABLE public.stripe_sync_log RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.payouts_v2 RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.sales RESTART IDENTITY CASCADE;

-- Optional: other tables you may want to clear (uncomment if you need them)
-- TRUNCATE TABLE public.royalty_ledger RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.royalty_distributions RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.transactions RESTART IDENTITY CASCADE;

COMMIT;

-- Quick counts (for human confirmation)
\echo 'Counts after truncate:'
SELECT 'sales', count(*) FROM public.sales;
SELECT 'payouts_v2', count(*) FROM public.payouts_v2;
SELECT 'stripe_sync_log', count(*) FROM public.stripe_sync_log;