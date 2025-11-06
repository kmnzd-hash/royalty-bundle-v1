BEGIN;

-- -----------------------------------------------------
-- 1. ENTITY REGISTRY TABLE
-- -----------------------------------------------------

CREATE TABLE public.entity_registry (
    entity_id TEXT PRIMARY KEY,
    entity_name TEXT UNIQUE NOT NULL,
    entity_type TEXT CHECK (entity_type IN (
        'HoldCo','Treasury','IP Holdings','DAO','Operating','Platform','Advisory','Marketing','Wellness','Chairman','Brand Umbrella'
    )),
    jurisdiction TEXT,
    registration_no TEXT,
    bank_alias TEXT,
    stripe_alias TEXT,
    tax_id TEXT,
    owner_entity TEXT REFERENCES public.entity_registry(entity_name) ON DELETE SET NULL,
    signatory TEXT,
    governance_layer TEXT CHECK (governance_layer IN (
        'Chairman','Family Office','Treasury','IP / DAO','Platform','Wellness','Brand'
    )),
    credit_role TEXT,
    notes TEXT,
    tags TEXT[],
    status TEXT DEFAULT '🟢 Active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_entity_registry_layer ON public.entity_registry (governance_layer);
CREATE INDEX idx_entity_registry_status ON public.entity_registry (status);
CREATE INDEX idx_entity_registry_owner ON public.entity_registry (owner_entity);

-- -----------------------------------------------------
-- 2. RAILS ONTOLOGY TABLE
-- -----------------------------------------------------

CREATE TABLE public.rails_ontology (
    record_id TEXT PRIMARY KEY,
    layer TEXT CHECK (layer IN (
        'OpCo','Platform','IP','DAO','Treasury','HoldCo','Wellness'
    )),
    entity_name TEXT REFERENCES public.entity_registry(entity_name) ON DELETE CASCADE,
    sku_code TEXT NOT NULL,
    sku_name TEXT,
    bundle_type TEXT CHECK (bundle_type IN (
        'Core','Continuity','Premium','Governance'
    )),
    prd_id TEXT,
    deliverable_type TEXT,
    entity_from TEXT REFERENCES public.entity_registry(entity_name) ON DELETE SET NULL,
    entity_to TEXT REFERENCES public.entity_registry(entity_name) ON DELETE SET NULL,
    price_aud NUMERIC(12,2) DEFAULT 0,
    currency TEXT DEFAULT 'AUD',
    override_delivery NUMERIC(5,2) DEFAULT 30,
    override_logic NUMERIC(5,2) DEFAULT 25,
    override_ip NUMERIC(5,2) DEFAULT 15,
    override_royalty_pool NUMERIC(5,2) DEFAULT 30,
    vault_id TEXT,
    creator_id TEXT,
    referrer_id TEXT,
    reuse_event TEXT,
    proof_links TEXT,
    status TEXT CHECK (status IN (
        '🧠 Ideation','⚙️ Verification','📜 Evidence Attached','🔒 Chairman Review','💰 Invoice Issued / Paid'
    )),
    owner TEXT,
    tags TEXT[],
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- -----------------------------------------------------
-- 3. RELATIONSHIPS
-- -----------------------------------------------------

ALTER TABLE public.rails_ontology
ADD CONSTRAINT fk_entity_registry FOREIGN KEY (entity_name)
REFERENCES public.entity_registry(entity_name) ON DELETE CASCADE;

ALTER TABLE public.rails_ontology
ADD CONSTRAINT fk_entity_from FOREIGN KEY (entity_from)
REFERENCES public.entity_registry(entity_name) ON DELETE SET NULL;

ALTER TABLE public.rails_ontology
ADD CONSTRAINT fk_entity_to FOREIGN KEY (entity_to)
REFERENCES public.entity_registry(entity_name) ON DELETE SET NULL;

-- -----------------------------------------------------
-- 4. VIEWS FOR ANALYTICS
-- -----------------------------------------------------

-- Quick reference view to see value flow and override splits
CREATE OR REPLACE VIEW public.vw_entity_value_flow AS
SELECT
    r.record_id,
    r.entity_from,
    r.entity_to,
    r.bundle_type,
    r.price_aud,
    ROUND(r.price_aud * (r.override_delivery / 100), 2) AS delivery_share,
    ROUND(r.price_aud * (r.override_logic / 100), 2) AS logic_share,
    ROUND(r.price_aud * (r.override_ip / 100), 2) AS ip_share,
    ROUND(r.price_aud * (r.override_royalty_pool / 100), 2) AS royalty_share,
    e.governance_layer,
    e.status AS entity_status
FROM public.rails_ontology r
JOIN public.entity_registry e
    ON r.entity_to = e.entity_name;

-- DAO revenue overview view
CREATE OR REPLACE VIEW public.vw_dao_royalty_summary AS
SELECT
    r.vault_id,
    COUNT(DISTINCT r.reuse_event) AS reuse_count,
    SUM(r.price_aud) AS total_value,
    SUM(r.price_aud * (r.override_royalty_pool / 100)) AS royalty_pool_value,
    ARRAY_AGG(DISTINCT r.entity_from) AS contributing_entities,
    ARRAY_AGG(DISTINCT r.entity_to) AS recipient_entities
FROM public.rails_ontology r
WHERE r.layer IN ('IP','DAO')
GROUP BY r.vault_id;

-- -----------------------------------------------------
-- 5. AUTOMATED TIMESTAMPS
-- -----------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_entity_registry_timestamp
BEFORE UPDATE ON public.entity_registry
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER update_rails_ontology_timestamp
BEFORE UPDATE ON public.rails_ontology
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- -----------------------------------------------------
-- 6. SECURITY RULES (FOR KAREN / CARLA / DJ)
-- -----------------------------------------------------

-- Owner roles
CREATE ROLE karen_rw LOGIN PASSWORD '**REDACTED**';
CREATE ROLE carla_rw LOGIN PASSWORD '**REDACTED**';
CREATE ROLE dj_admin LOGIN PASSWORD '**REDACTED**';

-- Grant read/write roles
GRANT SELECT, INSERT, UPDATE ON public.entity_registry TO karen_rw, carla_rw;
GRANT SELECT, INSERT, UPDATE ON public.rails_ontology TO karen_rw, carla_rw;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dj_admin;

COMMIT;
