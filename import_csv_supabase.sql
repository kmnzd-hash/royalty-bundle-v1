-- ======================================================
-- 🚀 CSV → SQL IMPORT SCRIPT for Nolastray Supabase
-- ======================================================
-- Safe client-side version using \copy
-- Run this from VSCode terminal (psql local client)
-- ======================================================

\echo '⚙️ Truncating tables...'
TRUNCATE TABLE public.rails_ontology, public.entity_registry RESTART IDENTITY CASCADE;

\echo '📦 Importing entity_registry_master.csv...'
\copy public.entity_registry (entity_id, entity_name, entity_type, jurisdiction, registration_no, bank_alias, stripe_alias, tax_id, owner_entity, signatory, governance_layer, credit_role, notes, tags, status) FROM './data/entity_registry_master.csv' WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

\echo '📦 Importing rails_ontology_seed.csv...'
\copy public.rails_ontology (record_id, layer, entity_name, sku_code, sku_name, bundle_type, prd_id, deliverable_type, entity_from, entity_to, price_aud, currency, override_delivery, override_logic, override_ip, override_royalty_pool, vault_id, creator_id, referrer_id, reuse_event, proof_links, status, owner, tags, notes) FROM './data/rails_ontology_seed.csv' WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

\echo '✅ Import complete. Verifying counts...'
SELECT COUNT(*) AS total_entities FROM public.entity_registry;
SELECT COUNT(*) AS total_records FROM public.rails_ontology;

\echo '🎉 All CSV data successfully loaded into Supabase!'
