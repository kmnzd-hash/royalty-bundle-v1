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

const tables = ['bundles','offers','sales','payouts','royalties_metadata'];
const today = new Date().toISOString().slice(0,10);
const dir = path.join(process.cwd(), 'exports', today);
fs.mkdirSync(dir, { recursive: true });

async function dump(table) {
  const { data, error } = await supabase.from(table).select('*').limit(50000);
  if (error) throw error;
  const csv = Papa.unparse(data || []);
  fs.writeFileSync(path.join(dir, `${table}.csv`), csv);
  console.log(`Wrote ${table}.csv (${(data||[]).length} rows)`);
}

(async () => {
  for (const t of tables) await dump(t);
  console.log('✅ Backup complete');
})().catch((e) => { console.error(e); process.exit(1); });