                                                        pg_get_functiondef                                                         
-----------------------------------------------------------------------------------------------------------------------------------
 CREATE OR REPLACE FUNCTION public.create_or_update_payouts_for_transaction()                                                     +
  RETURNS trigger                                                                                                                 +
  LANGUAGE plpgsql                                                                                                                +
 AS $function$                                                                                                                    +
 DECLARE                                                                                                                          +
   b RECORD;                                                                                                                      +
   pct_array numeric[];                                                                                                           +
   ip_pct numeric := 0;                                                                                                           +
   creator_pct numeric := 0;                                                                                                      +
   txn_amount numeric := COALESCE(NEW.sale_amount, 0);                                                                            +
   amount_ip numeric;                                                                                                             +
   amount_creator numeric;                                                                                                        +
   currency_text text := COALESCE(NEW.sale_currency, '');                                                                         +
 BEGIN                                                                                                                            +
   SELECT entity_from, entity_to, ip_holder, override_pct                                                                         +
     INTO b                                                                                                                       +
     FROM public.bundles                                                                                                          +
    WHERE bundle_id = NEW.bundle_id                                                                                               +
    LIMIT 1;                                                                                                                      +
                                                                                                                                  +
   IF NOT FOUND THEN                                                                                                              +
     RAISE NOTICE 'Bundle % not found for transaction %', NEW.bundle_id, NEW.id;                                                  +
     RETURN NEW;                                                                                                                  +
   END IF;                                                                                                                        +
                                                                                                                                  +
   -- ✅ FIXED TYPE CASTING HERE                                                                                                  +
   pct_array := ARRAY[                                                                                                            +
     COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 1), '')::numeric, 0),+
     COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 2), '')::numeric, 0),+
     COALESCE(NULLIF(split_part(COALESCE(b.override_pct::text, NEW.metadata->>'override_pct', '0/0/0'), '/', 3), '')::numeric, 0) +
   ];                                                                                                                             +
                                                                                                                                  +
   SELECT array_agg(v ORDER BY v DESC) INTO pct_array FROM unnest(pct_array) AS v;                                                +
                                                                                                                                  +
   ip_pct := COALESCE(pct_array[1], 0);                                                                                           +
   creator_pct := COALESCE(pct_array[2], 0);                                                                                      +
                                                                                                                                  +
   amount_ip := round(txn_amount * ip_pct / 100.0, 2);                                                                            +
   amount_creator := round(txn_amount * creator_pct / 100.0, 2);                                                                  +
                                                                                                                                  +
   INSERT INTO public.payouts_v2                                                                                                  +
     (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)                            +
   VALUES                                                                                                                         +
     (NEW.id, NEW.sale_id, b.entity_to, 'executor', txn_amount, currency_text, 'queued', now())                                   +
   ON CONFLICT (transaction_id, recipient_role) DO UPDATE                                                                         +
     SET recipient_entity = EXCLUDED.recipient_entity,                                                                            +
         amount = EXCLUDED.amount,                                                                                                +
         currency = EXCLUDED.currency,                                                                                            +
         status = EXCLUDED.status,                                                                                                +
         created_at = EXCLUDED.created_at;                                                                                        +
                                                                                                                                  +
   INSERT INTO public.payouts_v2                                                                                                  +
     (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)                            +
   VALUES                                                                                                                         +
     (NEW.id, NEW.sale_id, b.ip_holder, 'ip_holder', amount_ip, currency_text, 'queued', now())                                   +
   ON CONFLICT (transaction_id, recipient_role) DO UPDATE                                                                         +
     SET recipient_entity = EXCLUDED.recipient_entity,                                                                            +
         amount = EXCLUDED.amount,                                                                                                +
         currency = EXCLUDED.currency,                                                                                            +
         status = EXCLUDED.status,                                                                                                +
         created_at = EXCLUDED.created_at;                                                                                        +
                                                                                                                                  +
   INSERT INTO public.payouts_v2                                                                                                  +
     (transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, created_at)                            +
   VALUES                                                                                                                         +
     (NEW.id, NEW.sale_id, b.entity_from, 'creator', amount_creator, currency_text, 'queued', now())                              +
   ON CONFLICT (transaction_id, recipient_role) DO UPDATE                                                                         +
     SET recipient_entity = EXCLUDED.recipient_entity,                                                                            +
         amount = EXCLUDED.amount,                                                                                                +
         currency = EXCLUDED.currency,                                                                                            +
         status = EXCLUDED.status,                                                                                                +
         created_at = EXCLUDED.created_at;                                                                                        +
                                                                                                                                  +
   RETURN NEW;                                                                                                                    +
 END;                                                                                                                             +
 $function$                                                                                                                       +
 
 CREATE OR REPLACE FUNCTION public.update_payouts_on_sale()                                                                       +
  RETURNS trigger                                                                                                                 +
  LANGUAGE plpgsql                                                                                                                +
 AS $function$                                                                                                                    +
 BEGIN                                                                                                                            +
   -- old: NEW.sale_amount                                                                                                        +
   -- new:                                                                                                                        +
   INSERT INTO payouts (sale_id, amount)                                                                                          +
   VALUES (NEW.sale_id, NEW.gross_amount);                                                                                        +
   RETURN NEW;                                                                                                                    +
 END;                                                                                                                             +
 $function$                                                                                                                       +
 
 CREATE OR REPLACE FUNCTION public.create_payouts_for_sale()                                                                      +
  RETURNS trigger                                                                                                                 +
  LANGUAGE plpgsql                                                                                                                +
 AS $function$                                                                                                                    +
 DECLARE                                                                                                                          +
   ip_pct numeric;                                                                                                                +
   creator_pct numeric;                                                                                                           +
   referrer_pct numeric;                                                                                                          +
   amount_ip numeric;                                                                                                             +
   amount_creator numeric;                                                                                                        +
   amount_referrer numeric;                                                                                                       +
 BEGIN                                                                                                                            +
   ip_pct := COALESCE(NULLIF(split_part(NEW.override_pct, '/', 1), ''), '0')::numeric;                                            +
   creator_pct := COALESCE(NULLIF(split_part(NEW.override_pct, '/', 2), ''), '0')::numeric;                                       +
   referrer_pct := COALESCE(NULLIF(split_part(NEW.override_pct, '/', 3), ''), '0')::numeric;                                      +
                                                                                                                                  +
   amount_ip := round(NEW.gross_amount * ip_pct / 100.0, 2);                                                                      +
   amount_creator := round(NEW.gross_amount * creator_pct / 100.0, 2);                                                            +
   amount_referrer := round(NEW.gross_amount * referrer_pct / 100.0, 2);                                                          +
                                                                                                                                  +
   INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)                            +
   VALUES (NEW.sale_id, 'ip_holder', NEW.ip_holder, ip_pct, amount_ip, 'queued', now());                                          +
                                                                                                                                  +
   INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)                            +
   VALUES (NEW.sale_id, 'creator', NEW.creator_id, creator_pct, amount_creator, 'queued', now());                                 +
                                                                                                                                  +
   INSERT INTO public.payouts (sale_id, recipient_role, recipient_id, pct, amount, status, created_at)                            +
   VALUES (NEW.sale_id, 'referrer', NEW.referrer_id, referrer_pct, amount_referrer, 'queued', now());                             +
                                                                                                                                  +
   RETURN NEW;                                                                                                                    +
 END;                                                                                                                             +
 $function$                                                                                                                       +
 
(3 rows)

