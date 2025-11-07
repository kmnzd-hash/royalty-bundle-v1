// scripts/cadence_runner.mjs (DRY-RUN capable, Phase 6 aligned)
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

// Initialize clients
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const stripe = new Stripe(
  process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET_KEY_TEST,
  { apiVersion: '2024-11-01' }
);

const DRY = process.env.DRY_RUN === '1' || process.argv.includes('--dry');
console.log(DRY ? '💤 Running in DRY MODE (no live charges)...' : '⚡ LIVE mode enabled.');

// ---------------------------------------------
// STEP 1 — Get due offers based on cadence + billing_day
// ---------------------------------------------
async function getDueOffers(asOfDate = new Date()) {
  const day = asOfDate.getUTCDate();
  console.log(`🔍 Checking offers due for billing day: ${day}`);

  const { data: offers, error } = await supabase
    .from('offers')
    .select('id, offer_name, offer_type, description, default_price, cadence, term_months, billing_day')
    .or(`billing_day.eq.${day},cadence.eq.once`)
    .limit(500);

  if (error) throw new Error(`Supabase query error: ${error.message}`);
  if (!offers || !offers.length) {
    console.log('⚠️ No offers found for this billing day or cadence criteria.');
    return [];
  }

  console.log(`✅ Found ${offers.length} offers due today.`);
  return offers;
}

// ---------------------------------------------
// STEP 2 — Simulate billing or create invoice
// ---------------------------------------------
async function processOffer(offer) {
  const payload = {
    offerId: offer.id,
    offerName: offer.offer_name || '(unnamed offer)',
    amount: Number(offer.default_price || 0),
    currency: 'AUD', // default currency
    cadence: offer.cadence,
    billingDay: offer.billing_day,
    offerType: offer.offer_type || 'core'
  };

  console.log(DRY ? '[DRY]' : '[LIVE]', 'Processing offer:', payload);

  if (!DRY) {
    try {
      const idempotencyKey = `${offer.id}:${new Date().toISOString().slice(0, 10)}`;

      // Placeholder for Stripe logic — safe to skip until Phase 7
      const invoice = await stripe.invoices.create(
        {
          customer: 'cus_xxx_replace_later',
          collection_method: 'send_invoice',
          days_until_due: 7,
          description: `Billing for offer ${offer.name}`,
        },
        { idempotencyKey }
      );

      console.log(`✅ Created Stripe invoice for ${offer.name}: ${invoice.id}`);
    } catch (err) {
      console.error(`❌ Stripe error for offer ${offer.name}:`, err.message);
    }
  }
}

// ---------------------------------------------
// STEP 3 — Runner entrypoint
// ---------------------------------------------
async function run() {
  console.log('🚀 Starting cadence runner...');
  const offers = await getDueOffers();

  if (!offers.length) {
    console.log('✅ Nothing to process. Exiting.');
    return;
  }

  for (const offer of offers) {
    await processOffer(offer);
  }

  console.log(DRY ? '🧾 [DRY RUN COMPLETE] No live charges made.' : '💰 [LIVE RUN COMPLETE] Invoices processed.');
}

run().catch((e) => {
  console.error('Fatal Error:', e.message);
  process.exit(1);
});
