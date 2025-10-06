-- 20251004_create_smart_payout_trigger.sql
BEGIN;

-- 1️⃣ Drop old function if exists
DROP FUNCTION IF EXISTS public.handle_after_transaction_insert CASCADE;

-- 2️⃣ Create new dynamic payout function
CREATE OR REPLACE FUNCTION public.handle_after_transaction_insert()
RETURNS TRIGGER AS $$
DECLARE
  v_royalty_pool_id INTEGER;
  v_distribution RECORD;
  v_tx_amount NUMERIC(12,2);
BEGIN
  -- Get the transaction amount
  v_tx_amount := NEW.sale_amount;

  -- Get the royalty pool linked to this bundle
  SELECT royalty_pool_id
    INTO v_royalty_pool_id
  FROM public.bundles
  WHERE bundle_id = NEW.bundle_id;

  -- If no royalty pool is linked, skip payouts
  IF v_royalty_pool_id IS NULL THEN
    RAISE NOTICE 'No royalty pool found for bundle %, skipping payout', NEW.bundle_id;
    RETURN NEW;
  END IF;

  -- Loop through all royalty recipients and insert proportional payouts
  FOR v_distribution IN
    SELECT rd.entity_id, rd.percentage
    FROM public.royalty_distributions rd
    WHERE rd.royalty_pool_id = v_royalty_pool_id
  LOOP
    INSERT INTO public.payouts_v2 (
      transaction_id,
      sale_id,
      recipient_entity,
      recipient_role,
      amount,
      currency,
      status,
      created_at
    )
    VALUES (
      NEW.id,
      NEW.sale_id,
      v_distribution.entity_id,
      'royalty_recipient',
      ROUND(v_tx_amount * (v_distribution.percentage / 100.0), 2),
      NEW.sale_currency,
      'queued',
      NOW()
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3️⃣ Create the trigger to run after each transaction insert
DROP TRIGGER IF EXISTS trg_after_transaction_insert ON public.transactions;

CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.handle_after_transaction_insert();

COMMIT;

