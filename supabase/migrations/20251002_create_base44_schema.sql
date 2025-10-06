-- 20251002_create_base44_schema.sql
BEGIN;

-- ============================================
-- 1️⃣ ENTITIES
-- ============================================
CREATE TABLE IF NOT EXISTS public.entities (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  domain TEXT,
  mbti_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2️⃣ OFFERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.offers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  offer_type TEXT CHECK (offer_type IN ('core','lead_gen','continuity','premium')),
  description TEXT,
  default_price NUMERIC(12,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3️⃣ ROYALTY POOLS + DISTRIBUTIONS
-- (Must come before bundles)
-- ============================================
CREATE TABLE IF NOT EXISTS public.royalty_pools (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  creator_id INTEGER REFERENCES public.entities(id),
  base_percentage NUMERIC(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.royalty_distributions (
  id SERIAL PRIMARY KEY,
  royalty_pool_id INTEGER REFERENCES public.royalty_pools(id),
  entity_id INTEGER REFERENCES public.entities(id),
  percentage NUMERIC(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4️⃣ BUNDLES
-- ============================================
CREATE TABLE IF NOT EXISTS public.bundles (
  bundle_id SERIAL PRIMARY KEY,  -- renamed to match legacy schema
  offer_id INTEGER REFERENCES public.offers(id),
  entity_from INTEGER REFERENCES public.entities(id),
  entity_to INTEGER REFERENCES public.entities(id),
  ip_holder INTEGER REFERENCES public.entities(id),
  bundle_type TEXT,
  asset_class TEXT CHECK (asset_class IN ('IP','Logic','Secret')),
  override_pct NUMERIC(5,2),
  vault_id TEXT UNIQUE,
  royalty_pool_id INTEGER REFERENCES public.royalty_pools(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5️⃣ OVERRIDES
-- ============================================
CREATE TABLE IF NOT EXISTS public.overrides (
  id SERIAL PRIMARY KEY,
  bundle_id INTEGER REFERENCES public.bundles(bundle_id),
  tier INTEGER CHECK (tier BETWEEN 1 AND 3),
  override_pct NUMERIC(5,2),
  recipient_role TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6️⃣ TRANSACTIONS (SALES)
-- ============================================
CREATE TABLE IF NOT EXISTS public.transactions (
  id SERIAL PRIMARY KEY,
  sale_id uuid UNIQUE, -- link back to legacy sales.sale_id if exists
  bundle_id INTEGER REFERENCES public.bundles(bundle_id),
  offer_id INTEGER REFERENCES public.offers(id),
  sale_amount NUMERIC(12,2),
  sale_currency TEXT,
  sale_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 7️⃣ PAYOUTS_V2 (mapped to transactions)
-- ============================================
CREATE TABLE IF NOT EXISTS public.payouts_v2 (
  id SERIAL PRIMARY KEY,
  payout_uuid uuid DEFAULT gen_random_uuid() UNIQUE,
  transaction_id INTEGER REFERENCES public.transactions(id),
  sale_id uuid, -- mirror original sale id for easy lookup
  recipient_entity INTEGER REFERENCES public.entities(id),
  recipient_role TEXT,
  amount NUMERIC(12,2),
  currency TEXT,
  status TEXT CHECK (status IN ('queued','processing','paid','failed')),
  notion_page_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_at TIMESTAMP WITH TIME ZONE
);

COMMIT;
