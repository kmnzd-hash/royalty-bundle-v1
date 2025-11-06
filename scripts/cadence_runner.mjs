// scripts/cadence_runner.mjs (DRY-RUN capable)
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2024-11-01' });
const DRY = process.env.DRY_RUN === '1' || process.argv.includes('--dry');

async function getDueOffers(asOfDate = new Date()) {
  // Query offers where cadence matches today based on billing_day
  const day = asOfDate.getUTCDate();
  const { data, error } = await supabase.from('offers')
    .select('offer_id,id,offer_name,price,currency,cadence,term_months,billing_day,bundle_id')
    .or(`billing_day.eq.${day},cadence.eq.once`)
    .limit(500);
  if (error) throw error;
  return data || [];
}

async function run() {
  const offers = await getDueOffers();
  for (const o of offers) {
    const payload = {
      offerId: o.id,
      amount: Number(o.price || 0),
      currency: o.currency || 'AUD',
      vaultId: o.vault_id || null
    };
    console.log(DRY ? '[DRY]' : '[LIVE]', 'Would charge:', payload);
    if (!DRY) {
      // create Stripe invoice/charge (idempotent key = offerId:YYYY-MM-DD)
      const idempotencyKey = `${o.id}:${new Date().toISOString().slice(0,10)}`;
      // TODO: build invoice logic by your Stripe integration model
    }
  }
}

run().catch(e => { console.error(e); process.exit(1); });