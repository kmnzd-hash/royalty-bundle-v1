BEGIN;

CREATE TABLE IF NOT EXISTS public.sales (
    sale_id SERIAL PRIMARY KEY,
    offer_id INTEGER REFERENCES public.offers(id) ON DELETE SET NULL,
    offer_name TEXT,
    gross_amount NUMERIC(12,2) NOT NULL,
    sale_currency TEXT DEFAULT 'AUD',
    vault_id TEXT,
    creator_id TEXT,
    ip_holder TEXT,
    referrer_id TEXT,
    override_json JSONB DEFAULT '{}'::jsonb,
    sale_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'queued'
);

COMMENT ON TABLE public.sales IS 'Core sales table used for payouts and JSON override-based royalty splits.';

CREATE INDEX IF NOT EXISTS idx_sales_offer_id ON public.sales (offer_id);
CREATE INDEX IF NOT EXISTS idx_sales_vault_id ON public.sales (vault_id);
CREATE INDEX IF NOT EXISTS idx_sales_status ON public.sales (status);

COMMIT;
