// scripts/generate_treasury_report.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

// init
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// date helpers
const today = new Date();
const periodStart = process.argv.includes('--period-start')
  ? new Date(process.argv[process.argv.indexOf('--period-start') + 1])
  : new Date(today.getFullYear(), today.getMonth(), 1);
const periodEnd = process.argv.includes('--period-end')
  ? new Date(process.argv[process.argv.indexOf('--period-end') + 1])
  : today;

console.log('🧮 Generating Treasury Report for period:', periodStart.toISOString(), '→', periodEnd.toISOString());

// aggregate royalties
async function aggregateRoyalties() {
  // try main view first
  let { data, error } = await supabase
    .from('vw_dao_royalty_summary')
    .select('vault_id, total_royalties')
    .gte('created_at', periodStart.toISOString())
    .lte('created_at', periodEnd.toISOString());

  if (error || !data?.length) {
    console.warn('⚠️ View not found or empty — falling back to payouts_v2 aggregation.');
    const fallback = await supabase
      .from('payouts_v2')
      .select('vault_id, amount')
      .gte('created_at', periodStart.toISOString())
      .lte('created_at', periodEnd.toISOString());
    if (fallback.error) throw new Error(fallback.error.message);

    const map = {};
    for (const row of fallback.data) {
      const key = row.vault_id || 'unknown';
      map[key] = (map[key] || 0) + Number(row.amount || 0);
    }
    data = Object.entries(map).map(([vault_id, total_royalties]) => ({ vault_id, total_royalties }));
  }

  return data;
}

// insert summary rows
async function insertReports(aggregates) {
  if (!aggregates?.length) {
    console.log('❌ No data to insert.');
    return;
  }

  for (const row of aggregates) {
    const { vault_id, total_royalties } = row;
    const { error } = await supabase.from('treasury_reports').insert({
      period_start: periodStart.toISOString().slice(0, 10),
      period_end: periodEnd.toISOString().slice(0, 10),
      report_type: 'monthly',
      total_royalties,
    });
    if (error) console.error('Insert failed for', vault_id, error.message);
    else console.log(`✅ Inserted report for vault ${vault_id}: ${total_royalties}`);
  }
}

(async () => {
  try {
    const data = await aggregateRoyalties();
    console.log(`📊 Aggregated ${data.length} vault entries.`);
    await insertReports(data);
    console.log('🎯 Treasury report generation complete.');
  } catch (err) {
    console.error('Fatal:', err.message);
    process.exit(1);
  }
})();
