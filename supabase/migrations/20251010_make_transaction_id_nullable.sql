-- supabase/migrations/20251010_make_transaction_id_nullable.sql
-- Make payouts_v2.transaction_id nullable for Ontology-ready payouts
-- Reversible: to revert, run the "rollback" command below (after ensuring no NULLs)

BEGIN;

ALTER TABLE public.payouts_v2
  ALTER COLUMN transaction_id DROP NOT NULL;

COMMENT ON COLUMN public.payouts_v2.transaction_id IS
  'Made nullable for Phase 3: payouts may exist without a transaction link (bundle/offer based payouts).';

COMMIT;

-- ROLLBACK (if you need to restore NOT NULL later):
-- ALTER TABLE public.payouts_v2 ALTER COLUMN transaction_id SET NOT NULL;
