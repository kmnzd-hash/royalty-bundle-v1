import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import Papa from 'papaparse';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function dump(name){
  const { data, error } = await supabase.from(name).select('*');
  if (error) throw error;
  fs.mkdirSync('exports', { recursive: true });
  const path = `exports/${name}_${new Date().toISOString().slice(0,10)}.csv`;
  fs.writeFileSync(path, Papa.unparse(data||[]));
  console.log('Exported', path);
}

(async () => {
  try {
    await Promise.all([
      dump('bundles'),
      dump('offers'),
      dump('sales'),
      dump('payouts'),
    ]);
    console.log('✅ Backups complete');
  } catch (err) {
    console.error('Backup failed', err);
    process.exit(1);
  }
})();
