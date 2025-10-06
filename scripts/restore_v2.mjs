// scripts/restore_v2.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import Papa from 'papaparse';

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// default dir: exports/<today>
const argDir = process.argv[2];
const dir = argDir || path.join(process.cwd(), 'exports', new Date().toISOString().slice(0,10));

function loadCsv(file) {
  const p = path.join(dir, file);
  if (!fs.existsSync(p)) {
    console.warn('CSV not found, skipping:', p);
    return [];
  }
  const txt = fs.readFileSync(p, 'utf8');
  const parsed = Papa.parse(txt, { header: true, skipEmptyLines: true });
  // Normalize empty -> null and numeric strings to numbers if possible
  return parsed.data.map(row => {
    for (const k of Object.keys(row)) {
      if (row[k] === '') row[k] = null;
      // numeric-looking -> number
      if (row[k] != null && /^[+-]?\d+(\.\d+)?$/.test(String(row[k]))) {
        // keep large numeric strings as string if needed; this is a best-effort
        const n = Number(row[k]);
        if (!Number.isNaN(n)) row[k] = n;
      }
    }
    return row;
  });
}

async function insertChunked(table, rows, opts = {}) {
  if (!rows || rows.length === 0) {
    console.log(` - ${table}: nothing to insert`);
    return { count:0 };
  }
  const chunkSize = 200;
  let inserted = 0;
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);
    // Use upsert when possible by primary/unique keys (safe if CSV contains those columns)
    const q = await supabase.from(table).upsert(chunk, { onConflict: opts.onConflict || undefined }).select();
    if (q.error) {
      console.error(`Error inserting into ${table}:`, q.error.message || q.error);
      throw q.error;
    }
    inserted += (q.data || []).length;
    console.log(`Inserted chunk to ${table}: ${ (q.data||[]).length } rows`);
  }
  console.log(`✔ ${table}: inserted/updated ${inserted} rows`);
  return { count: inserted };
}

async function run() {
  console.log('Restore dir:', dir);

  // load in FK-safe order
  const entities = loadCsv('entities.csv');
  const offers = loadCsv('offers.csv');
  const royalty_pools = loadCsv('royalty_pools.csv');
  const bundles = loadCsv('bundles.csv');                    // note: may reference royalty_pools, offers, entities
  const royalty_distributions = loadCsv('royalty_distributions.csv');
  const transactions = loadCsv('transactions.csv');
  const payouts_v2 = loadCsv('payouts_v2.csv');

  // Insert parents first
  await insertChunked('entities', entities, { onConflict: 'id' }).catch(e=>{throw e});
  await insertChunked('offers', offers, { onConflict: 'id' }).catch(e=>{throw e});
  await insertChunked('royalty_pools', royalty_pools, { onConflict: 'id' }).catch(e=>{throw e});

  // Now bundles (some deployments use 'id' or 'bundle_id' — try both)
  // If your bundles table primary key is bundle_id, the CSV should have bundle_id column
  await insertChunked('bundles', bundles, { onConflict: 'bundle_id' }).catch(async (err) => {
    console.warn('bundles upsert with bundle_id failed, trying id fallback:', err?.message || err);
    await insertChunked('bundles', bundles, { onConflict: 'id' });
  });

  await insertChunked('royalty_distributions', royalty_distributions, { onConflict: 'id' }).catch(e=>{throw e});

  // Transactions -- caution: may include sale_id uuid (keeps legacy mapping)
  await insertChunked('transactions', transactions, { onConflict: 'id' }).catch(e=>{throw e});

  // payouts_v2
  await insertChunked('payouts_v2', payouts_v2, { onConflict: 'payout_uuid' }).catch(e=>{throw e});

  console.log('✅ Restore complete');
}

run().catch((err) => {
  console.error('Restore failed:', err?.message || err);
  process.exit(1);
});

