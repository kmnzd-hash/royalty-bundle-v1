// scripts/dao_sync.mjs (Enhanced field-type mapper for number/date consistency)
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client } from '@notionhq/client';

const {
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  NOTION_TOKEN,
  NOTION_EVIDENCE_DB_ID,
  NOTION_SALES_DB_ID
} = process.env;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) throw new Error('Missing Supabase env vars');
if (!NOTION_TOKEN) throw new Error('Missing Notion token');

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const notion = new Client({ auth: NOTION_TOKEN });

const text = (s) => ({ rich_text: [{ type: 'text', text: { content: String(s ?? '') } }] });
const title = (s) => ({ title: [{ type: 'text', text: { content: String(s ?? '') } }] });
const select = (s) => ({ select: s ? { name: String(s) } : null });
const date = (s) => ({ date: s ? { start: new Date(s).toISOString() } : null });
const number = (v) => ({ number: v ? Number(v) : null });

async function resolveDatabases() {
  const evidenceRes = { id: NOTION_EVIDENCE_DB_ID, type: 'database', name: 'Evidence Ontology' };
  const salesRes = { id: NOTION_SALES_DB_ID, type: 'database', name: 'Sales (Mirror)' };
  console.log('DEBUG resolver output:', { evidenceRes, salesRes });
  return { evidenceRes, salesRes };
}

async function checkNotionDBProps(dbId) {
  try {
    const res = await notion.databases.retrieve({ database_id: dbId });
    const props = Object.keys(res.properties);
    console.log(`🧾 ${res.title?.[0]?.plain_text || 'Untitled'} fields (database):`, props.join(', '));
    return props;
  } catch (e) {
    console.warn(`⚠️ Could not fetch Notion DB props for ${dbId}:`, e.message);
    return [];
  }
}

function mapField(k, v) {
  if (v === null || v === undefined) return undefined;
  if (['recipient_role', 'status', 'evidence_type', 'sync_status'].includes(k)) return select(v);
  if (['created_at', 'sale_date', 'updated_at', 'sent_at'].includes(k)) return date(v);
  if (['ip_holder'].includes(k)) return title(v);
  if (['transaction_id', 'offer_id', 'term_months', 'billing_day'].includes(k)) return number(v);
  if (typeof v === 'number') return number(v);
  return text(v);
}

async function pushSupabaseToNotion(dbName, table) {
  const { data, error } = await supabase.from(table).select('*').limit(50);
  if (error) throw error;
  console.log(`📦 Syncing ${table} (${data?.length || 0} records)...`);

  for (const record of data || []) {
    const props = {};
    Object.entries(record).forEach(([k, v]) => {
      const mapped = mapField(k, v);
      if (mapped) props[k] = mapped;
    });

    try {
      await notion.pages.create({ parent: { database_id: dbName }, properties: props });
    } catch (err) {
      console.warn(`⚠️ Skipped record due to sync issue:`, err.message);
    }
  }

  console.log(`✅ Completed sync for ${table}`);
}

async function main() {
  console.log('🔗 Connecting to Supabase...');
  const { evidenceRes, salesRes } = await resolveDatabases();

  console.log('🔍 Checking Notion database properties...');
  await checkNotionDBProps(evidenceRes.id);
  await checkNotionDBProps(salesRes.id);

  console.log('🚀 Pushing Supabase data to Notion...');
  await pushSupabaseToNotion(evidenceRes.id, 'payouts_v2');
  await pushSupabaseToNotion(salesRes.id, 'sales');

  console.log('🎯 DAO Ledger → Notion Evidence + Sales Mirror Sync Complete.');
}

main().catch((e) => { console.error(e); process.exit(1); });