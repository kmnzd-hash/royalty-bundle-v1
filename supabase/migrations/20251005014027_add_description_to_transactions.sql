-- 20251004_add_description_to_transactions.sql

-- Add a human-readable description column to transactions
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS description TEXT;

COMMENT ON COLUMN public.transactions.description IS
'Optional text description for the transaction (e.g. invoice details, test logs, etc.)';
