  table_name  |   column_name    |        data_type         | is_nullable |               column_default               
--------------+------------------+--------------------------+-------------+--------------------------------------------
 bundles      | bundle_id        | integer                  | NO          | nextval('bundles_bundle_id_seq'::regclass)
 bundles      | offer_id         | integer                  | YES         | 
 bundles      | entity_from      | integer                  | YES         | 
 bundles      | entity_to        | integer                  | YES         | 
 bundles      | ip_holder        | integer                  | YES         | 
 bundles      | bundle_type      | text                     | YES         | 
 bundles      | asset_class      | text                     | YES         | 
 bundles      | override_pct     | numeric                  | YES         | 
 bundles      | vault_id         | text                     | YES         | 
 bundles      | royalty_pool_id  | integer                  | YES         | 
 bundles      | created_at       | timestamp with time zone | YES         | now()
 entities     | id               | integer                  | NO          | nextval('entities_id_seq'::regclass)
 entities     | name             | text                     | NO          | 
 entities     | domain           | text                     | YES         | 
 entities     | mbti_type        | text                     | YES         | 
 entities     | created_at       | timestamp with time zone | YES         | now()
 payouts_v2   | id               | integer                  | NO          | nextval('payouts_v2_id_seq'::regclass)
 payouts_v2   | payout_uuid      | uuid                     | YES         | gen_random_uuid()
 payouts_v2   | transaction_id   | integer                  | YES         | 
 payouts_v2   | sale_id          | uuid                     | YES         | 
 payouts_v2   | recipient_entity | integer                  | YES         | 
 payouts_v2   | recipient_role   | text                     | YES         | 
 payouts_v2   | amount           | numeric                  | YES         | 
 payouts_v2   | currency         | text                     | YES         | 
 payouts_v2   | status           | text                     | YES         | 
 payouts_v2   | notion_page_url  | text                     | YES         | 
 payouts_v2   | created_at       | timestamp with time zone | YES         | now()
 payouts_v2   | sent_at          | timestamp with time zone | YES         | 
 transactions | id               | integer                  | NO          | nextval('transactions_id_seq'::regclass)
 transactions | sale_id          | uuid                     | YES         | 
 transactions | bundle_id        | integer                  | YES         | 
 transactions | offer_id         | integer                  | YES         | 
 transactions | sale_amount      | numeric                  | YES         | 
 transactions | sale_currency    | text                     | YES         | 
 transactions | sale_date        | timestamp with time zone | YES         | now()
 transactions | metadata         | jsonb                    | YES         | 
 transactions | created_at       | timestamp with time zone | YES         | now()
 transactions | description      | text                     | YES         | 
(38 rows)

