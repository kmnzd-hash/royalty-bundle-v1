-- sql/verification_queries.sql
-- Entities
SELECT entity_name, owner_entity, governance_layer, tags FROM public.entity_registry ORDER BY entity_name;

-- Rails ontology
SELECT sku_code, bundle_type, entity_from, entity_to, price_aud, tags
FROM public.rails_ontology ORDER BY sku_code;

-- Ensure no missing entity references
SELECT COUNT(*) AS missing_entities
FROM public.rails_ontology r
WHERE NOT EXISTS (
  SELECT 1 FROM public.entity_registry e WHERE e.entity_name = r.entity_name
);

-- Minimal counts
SELECT (SELECT COUNT(*) FROM public.entity_registry) AS total_entities,
       (SELECT COUNT(*) FROM public.rails_ontology) AS total_rails_records;
