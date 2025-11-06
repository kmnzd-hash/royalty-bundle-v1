-- dao_seed_inserts.sql (TEMPLATE)
-- Replace values below with DJ-approved canonical dataset rows.
-- This file contains example INSERTs for sales, payouts_v2, stripe_sync_log.
-- Adjust columns to match your schema if required.

-- Example: sales (one canonical row)
INSERT INTO public.sales (
  sale_id,
  offer_name,
  cadence,
  billing_day,
  sale_currency,
  creator_id,
  gross_amount,
  created_at
) VALUES (
  1001,
  'Premium Automation Seat',
  'monthly',
  15,
  'AUD',
  'creator::12345',
  99.00,
  now()
);

-- Example: stripe_sync_log (mark queued so sync will pick it up)
INSERT INTO public.stripe_sync_log (
  sale_id,
  stripe_object,
  object_id,
  status,
  created_at
) VALUES (
  1001,
  'invoice.payment_succeeded',
  'evt_test_1001',
  'queued',
  now()
);

-- Example: payouts_v2 rows
INSERT INTO public.payouts_v2 (
  recipient_role,
  recipient_entity,
  amount,
  currency,
  status,
  created_at
) VALUES
('creator', 'entity::creator-1', 59.4, 'AUD', 'pending', now()),
('referrer', 'entity::referrer-1', 10.0, 'AUD', 'pending', now());
