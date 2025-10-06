// scripts/validate-sync.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

function ok(msg) { console.log('✅', msg); }
function warn(msg) { console.log('⚠️', msg); }
function err(msg) { console.error('❌', msg); }

async function runChecks() {
  console.log('Fetching most recent 20 sales...');
  const { data: sales, error: sErr } = await supabase.from('sales').select('*').order('created_at', { ascending: false }).limit(20);
  if (sErr) { err('Error fetching sales: ' + sErr.message); process.exit(2); }
  if (!sales || sales.length === 0) { warn('No sales found to validate'); return; }

  let failures = 0;
  for (const sale of sales) {
    console.log('\n--- sale', sale.sale_id, sale.offer_name, 'gross:', sale.gross_amount);
    const { data: payouts, error: pErr } = await supabase.from('payouts').select('*').eq('sale_id', sale.sale_id).order('recipient_role');
    if (pErr) { err('Error fetching payouts: ' + pErr.message); failures++; continue; }

    // executor check
    const executor = payouts.find(p => p.recipient_role === 'executor');
    if (!executor) {
      err(`sale ${sale.sale_id}: missing executor payout`);
      failures++;
    } else if (Number(executor.amount) !== Number(sale.gross_amount)) {
      err(`sale ${sale.sale_id}: executor amount mismatch: payout=${executor.amount} vs gross=${sale.gross_amount}`);
      failures++;
    } else ok(`sale ${sale.sale_id}: executor amount equals gross_amount`);

    // creator/ip_holder existence is expected only if IDs present
    if (sale.creator_id) {
      const creator = payouts.find(p => p.recipient_role === 'creator');
      if (!creator) { warn(`sale ${sale.sale_id}: creator ID present but no creator payout`); failures++; } else ok('creator payout exists');
    }

    // referrer handling: SOP allows two possible setups in codebase:
    //  - either there's NO referrer payout row when bundle.referrer_id==null
    //  - or there is a DB row with recipient_id='N/A' and amount 0 (but Notion row should be skipped)
    const ref = payouts.find(p => p.recipient_role === 'referrer');
    if (!sale.referrer_id) {
      if (!ref) {
        ok(`sale ${sale.sale_id}: no referrer payout row (fine)`);
      } else if (ref && String((ref.recipient_id||'')).toUpperCase() === 'N/A') {
        ok(`sale ${sale.sale_id}: referrer payout row present with recipient_id='N/A' (per SOP)`);
      } else {
        warn(`sale ${sale.sale_id}: referrer payout present but recipient_id is ${ref.recipient_id} (unexpected)`);
        failures++;
      }
    } else {
      // referrer_id exists — ensure payout row points to that id
      if (!ref) { err(`sale ${sale.sale_id}: missing referrer payout row (referrer_id present)`); failures++; }
      else if (String(ref.recipient_id) !== String(sale.referrer_id)) { warn(`sale ${sale.sale_id}: referrer recipient_id ${ref.recipient_id} !== sale.referrer_id ${sale.referrer_id}`); failures++; }
      else ok('referrer payout matches referrer_id');
    }

    // ensure payout_id exists for non-'N/A' rows
    for (const p of payouts) {
      if (!p.payout_id) { warn(`payout row missing payout_id for sale ${sale.sale_id} role ${p.recipient_role}`); failures++; } else ok(`payout_id present for role ${p.recipient_role}`);
    }
  }

  console.log('\nValidation complete. Failures:', failures);
  if (failures) process.exit(3);
  process.exit(0);
}

runChecks().catch(e => { console.error(e); process.exit(1); });

