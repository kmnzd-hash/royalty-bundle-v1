psql "$SUPABASE_DB_URL" <<'SQL'
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ✅ Indexes
CREATE INDEX IF NOT EXISTS idx_payouts_v2_transaction_id ON public.payouts_v2 (transaction_id);
CREATE INDEX IF NOT EXISTS idx_payouts_v2_recipient_entity ON public.payouts_v2 (recipient_entity);
CREATE INDEX IF NOT EXISTS idx_payouts_v2_recipient_role ON public.payouts_v2 (recipient_role);
CREATE INDEX IF NOT EXISTS idx_payouts_v2_status ON public.payouts_v2 (status);
CREATE INDEX IF NOT EXISTS idx_payouts_v2_created_at ON public.payouts_v2 (created_at DESC);

-- ✅ Safe default & constraint updates
ALTER TABLE public.payouts_v2
  ALTER COLUMN transaction_id SET NOT NULL,
  ALTER COLUMN recipient_role SET NOT NULL,
  ALTER COLUMN amount SET DEFAULT 0,
  ALTER COLUMN currency SET DEFAULT 'USD',
  ALTER COLUMN status SET DEFAULT 'queued';

-- ✅ Drop and recreate foreign key cleanly (since it already exists)
ALTER TABLE public.payouts_v2 DROP CONSTRAINT IF EXISTS payouts_v2_transaction_id_fkey;
ALTER TABLE public.payouts_v2
  ADD CONSTRAINT payouts_v2_transaction_id_fkey
  FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;

COMMIT;

-- ✅ Create a lightweight view for summary display
CREATE OR REPLACE VIEW public.vw_payouts_summary AS
SELECT
  id,
  transaction_id,
  recipient_role,
  amount,
  currency,
  status,
  format('Txn:%s | Role:%s | Amt:%s %s',
         transaction_id,
         recipient_role,
         amount,
         currency) AS summary,
  created_at
FROM public.payouts_v2;
SQL
