// scripts/insert_test_transaction.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import crypto from 'node:crypto';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function run() {
  // pick an existing bundle (or create one first). This selects one bundle/vault available.
  const { data: bundles } = await supabase.from('bundles').select('bundle_id,vault_id,offer_id').limit(1);
  if (!bundles || !bundles.length) {
    throw new Error('No bundles found. Please create or restore bundles first.');
  }
  const b = bundles[0];

  const saleUuid = crypto.randomUUID();
  const tx = {
    sale_id: saleUuid,
    bundle_id: b.bundle_id || b.id,
    offer_id: b.offer_id || null,
    sale_amount: 10000,           // test amount (match your expected currency units)
    sale_currency: 'USD',
    sale_date: new Date().toISOString(),
    metadata: { test: true, note: 'smart-payout test' }
  };

  const { data, error } = await supabase.from('transactions').insert(tx).select().single();
  if (error) throw error;
  console.log('Inserted transaction:', data);

  // Wait a bit for trigger to create payouts_v2 (if trigger runs async)
  // then fetch payouts for the sale_id
  await new Promise(r=>setTimeout(r, 1500));

  const { data: payouts, error: pErr } = await supabase.from('payouts_v2').select('*').eq('sale_id', saleUuid);
  if (pErr) throw pErr;
  console.log('payouts for sale:', payouts);
}

run().catch(e => { console.error(e); process.exit(1); });

