-- Entities are optional (names/emails/IDs of companies/departments/people)
create table if not exists entities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

-- Bundles (the “rails” config & metadata)
create table if not exists bundles (
  id uuid primary key default gen_random_uuid(),
  bundle_type text check (bundle_type in ('Core','Lead','Continuity','Premium')) not null,
  entity_from text not null,                 -- who pays
  entity_to text not null,                   -- who receives/delivers
  ip_holder text not null default 'Vault IP LLC',
  override_pct text not null,                -- flexible split string like "20/20/60" or "50,30,20"
  vault_id text not null unique,             -- unique config or contract ID
  creator_id text not null,                  -- who built the offer (free-form identifier for MVP)
  referrer_id text,                          -- optional
  reuse_event boolean default false,
  created_at timestamptz default now()
);

-- Offers (live things you sell under a bundle)
create table if not exists offers (
  id uuid primary key default gen_random_uuid(),
  bundle_id uuid references bundles(id) on delete cascade,
  name text not null,
  description text,
  price numeric,                             -- optional reference price
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Sales (each purchase)
create table if not exists sales (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid references offers(id) on delete cascade,
  sale_date timestamptz not null default now(),
  gross_amount numeric not null,
  currency text default 'USD',
  created_at timestamptz default now()
);

-- Payouts (computed from sale + split)
create table if not exists payouts (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid references sales(id) on delete cascade,
  recipient text not null,                   -- e.g. creator_id / entity_to / ip_holder / referrer_id
  role text,                                 -- creator | executor | ip_holder | referrer
  amount numeric not null,
  currency text default 'USD',
  status text default 'queued',              -- queued | sent | failed
  created_at timestamptz default now(),
  sent_at timestamptz
);
