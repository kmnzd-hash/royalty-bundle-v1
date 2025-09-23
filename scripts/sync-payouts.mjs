// scripts/sync-payouts.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);
const notion = new NotionClient({ auth: process.env.NOTION_TOKEN });

const payoutsDbId = process.env.NOTION_DB_PAYOUTS;

// helpers
const text = (s) => ({ rich_text: [{ type: 'text', text: { content: String(s ?? '') } }] });
const title = (s) => ({ title: [{ type: 'text', text: { content: String(s ?? '') } }] });

async function syncPayouts() {
  // 1. Pull payouts from Supabase
  const { data: payouts, error } = await supabase.from('payouts').select('*');
  if (error) throw error;

  for (const p of payouts || []) {
    // build Notion properties aligned with sync.mjs schema
    const props = {
      'Payout ID': text(String(p.payout_id || '')),   // ✅ new field
      'Sale ID': title(String(p.sale_id)),            // Title
      'Recipient': text(String(p.recipient_id || '')),// Rich Text
      'Role': p.recipient_role
        ? { select: { name: p.recipient_role } }
        : undefined,                                  // Select
      'Amount': { number: Number(p.amount) },
      'Currency': text(p.currency || 'USD'),
      'Status': { select: { name: p.status || 'queued' } },
    };

    // 2. Check if a payout already exists in Notion (by Sale ID + Role)
    const q = await notion.databases.query({
      database_id: payoutsDbId,
      filter: {
        and: [
          { property: 'Sale ID', title: { equals: String(p.sale_id) } },
          { property: 'Role', select: { equals: p.recipient_role } },
        ],
      },
      page_size: 1,
    });

    if (q.results.length) {
      // update
      await notion.pages.update({
        page_id: q.results[0].id,
        properties: props,
      });
    } else {
      // insert
      await notion.pages.create({
        parent: { database_id: payoutsDbId },
        properties: props,
      });
    }
  }

  console.log(`✅ Synced ${payouts?.length || 0} payouts to Notion`);
}

syncPayouts().catch((err) => {
  console.error(err);
  process.exit(1);
});
