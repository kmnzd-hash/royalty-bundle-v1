import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import Papa from 'papaparse';

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing Supabase env vars');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// ✅ Updated to new schema (Base44 + Smart Payout)
const tables = [
  'bundles',
  'offers',
  'entities',
  'transactions',
  'payouts_v2',
  'royalty_pools',
  'royalty_distributions'
];

// Organize backups by date
const today = new Date().toISOString().slice(0, 10);
const dir = path.join(process.cwd(), 'exports', today);
fs.mkdirSync(dir, { recursive: true });

// Dump a single table
async function dump(table) {
  const { data, error } = await supabase.from(table).select('*').limit(50000);
  if (error) {
    console.error(`⚠️ Error exporting ${table}:`, error.message);
    return;
  }

  const csv = Papa.unparse(data || []);
  fs.writeFileSync(path.join(dir, `${table}.csv`), csv);
  console.log(`✅ Wrote ${table}.csv (${(data || []).length} rows)`);
}

// Execute sequentially
(async () => {
  for (const t of tables) await dump(t);
  console.log('\n🎉 Backup complete and saved to:', dir);
})().catch((e) => {
  console.error('❌ Backup failed:', e.message);
  process.exit(1);
});
