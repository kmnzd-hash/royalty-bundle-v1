// scripts/sync-dashboard.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client } from '@notionhq/client';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const notion = new Client({ auth: process.env.NOTION_TOKEN });

const dashboardDbId = process.env.NOTION_DASHBOARD_DATABASE_ID;

async function getMetrics() {
  // Offers count
  const { count: offersCount } = (await supabase.from('offers').select('id', { count: 'exact', head: true })) || {};
  // Sales count
  const { count: salesCount } = (await supabase.from('sales').select('id', { count: 'exact', head: true })) || {};
  // Sum queued payouts
  const { data: queued } = await supabase.from('payouts').select('amount').eq('status', 'queued');
  const queuedSum = (queued || []).reduce((s, r) => s + Number(r.amount || 0), 0);
  return { offersNum: offersCount || 0, salesNum: salesCount || 0, queuedSum };
}

async function upsertDashboard({ offersNum, salesNum, queuedSum }) {
  // find any existing "Live" or first row
  const q = await notion.databases.query({ database_id: dashboardDbId, page_size: 1 });
  const page = q.results?.[0];

  const props = {
    'Name': { title: [{ text: { content: 'Live' } }] },
    'Offers': { number: Number(offersNum) },
    'Sales': { number: Number(salesNum) },
    'Royalties Queued': { number: Math.round(queuedSum * 100) / 100 }
  };

  if (!page) {
    await notion.pages.create({ parent: { database_id: dashboardDbId }, properties: props });
    console.log('Created dashboard Live row.');
  } else {
    await notion.pages.update({ page_id: page.id, properties: props });
    console.log('Updated dashboard Live row.');
  }
}

async function main() {
  const metrics = await getMetrics();
  console.log('Metrics computed:', metrics);
  await upsertDashboard(metrics);
  console.log('✅ Dashboard updated in Notion');
}

main().catch(err => { console.error(err); process.exit(1); });

