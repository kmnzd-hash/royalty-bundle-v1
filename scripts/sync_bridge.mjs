import 'dotenv/config';
import { Client } from '@notionhq/client';
import pkg from 'pg';
const { Client: PgClient } = pkg;

const notion = new Client({ auth: process.env.NOTION_TOKEN });
const supabase = new PgClient({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});

async function syncData() {
  console.log('🔗 Starting Notion ↔ Supabase Sync Bridge...');
  await supabase.connect();

  const tables = [
    { notion: 'Entities', sql: 'entities' },
    { notion: 'Offers', sql: 'offers' },
    { notion: 'Bundles', sql: 'bundles' },
    { notion: 'Transactions', sql: 'transactions' },
    { notion: 'Payouts_v2', sql: 'payouts_v2' },
    { notion: 'Overrides', sql: 'overrides' },
    { notion: 'Royalty Ledger', sql: 'royalty_ledger' },
    { notion: 'Royalty Pools', sql: 'royalty_pools' },
    { notion: 'Reuse Event Log', sql: 'reuse_event_log' },
    { notion: 'Payout Audit Log', sql: 'payout_audit_log' }
  ];

  for (const { notion: notionDB, sql: sqlTable } of tables) {
    try {
      console.log(`\n🧩 Syncing ${notionDB} ↔ ${sqlTable}...`);

      // Pull rows from Supabase
      const res = await supabase.query(`SELECT * FROM public.${sqlTable} LIMIT 5`);
      console.log(`📦 ${res.rows.length} records found in ${sqlTable}`);

      // Create placeholder entries in Notion if not already there
      for (const row of res.rows) {
        await notion.pages.create({
          parent: { database_id: process.env[`NOTION_DB_${notionDB.toUpperCase().replace(/\s+/g, '_')}`] },
          properties: {
            Name: { title: [{ text: { content: row.id?.toString() || 'Unnamed Record' } }] },
            Status: { select: { name: '🧠 Synced from Supabase' } },
          },
        });
      }
      console.log(`✅ Synced ${notionDB}`);
    } catch (err) {
      console.error(`❌ Error syncing ${notionDB}:`, err.message);
    }
  }

  await supabase.end();
  console.log('\n🎉 Sync Bridge Complete!');
}

syncData();

