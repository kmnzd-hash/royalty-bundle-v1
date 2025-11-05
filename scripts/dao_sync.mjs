// scripts/dao_sync.mjs
import 'dotenv/config';
import { Client } from '@notionhq/client';
import pkg from 'pg';
import { resolveWritableDatabase } from './lib/notionResolver.mjs';

// --- Initialize clients ---
const { Client: PgClient } = pkg;
const notion = new Client({ auth: process.env.NOTION_TOKEN });
const pg = new PgClient({ connectionString: process.env.SUPABASE_DB_URL });

// --- Environment variable fallbacks ---
const EVIDENCE_SOURCE_ID =
  process.env.NOTION_EVIDENCE_DB_ID ||
  process.env.NOTION_DB_EVIDENCE ||
  process.env.NOTION_EVIDENCE ||
  null;

const SALES_SOURCE_ID =
  process.env.NOTION_SALES_DB_ID ||
  process.env.NOTION_DB_SALES ||
  process.env.NOTION_SALES ||
  null;

if (!EVIDENCE_SOURCE_ID || !SALES_SOURCE_ID) {
  console.error(
    '❌ Missing Notion DB IDs. Please check your environment variables:\n' +
      'Expected NOTION_EVIDENCE_DB_ID and NOTION_SALES_DB_ID (or legacy NOTION_DB_EVIDENCE / NOTION_DB_SALES).'
  );
  process.exit(1);
}

// --- Main execution ---
(async () => {
  console.log('🔗 Connecting to Supabase...');
  await pg.connect();

  // 1️⃣ Resolve DB targets
  const EVIDENCE_RES = await resolveWritableDatabase(EVIDENCE_SOURCE_ID);
  const SALES_RES = await resolveWritableDatabase(SALES_SOURCE_ID);

  console.log('DEBUG resolver output:', {
    evidenceRes: EVIDENCE_RES,
    salesRes: SALES_RES,
  });

  const EVIDENCE_DB = { id: EVIDENCE_RES.id, type: EVIDENCE_RES.type || 'database' };
  const SALES_DB = { id: SALES_RES.id, type: SALES_RES.type || 'database' };

  if (!EVIDENCE_DB.id || !SALES_DB.id) {
    console.error('❌ Resolver did not return valid Notion database IDs.');
    process.exit(1);
  }

  console.log(`Resolved Evidence -> ${EVIDENCE_DB.id} (${EVIDENCE_DB.type})`);
  console.log(`Resolved Sales -> ${SALES_DB.id} (${SALES_DB.type})`);
  console.log('🔍 Checking Notion database properties...');

  // --- Evidence Ontology ---
  let evidenceProps = [];
  try {
    const path =
      EVIDENCE_DB.type === 'data_source'
        ? `data_sources/${EVIDENCE_DB.id}`
        : `databases/${EVIDENCE_DB.id}`;
    const res = await notion.request({ path, method: 'GET' });
    evidenceProps = Object.keys(res.properties || {});
    console.log(`🧾 Evidence Ontology fields (${EVIDENCE_DB.type}):`, evidenceProps.join(', '));
  } catch (err) {
    console.warn('⚠️ Could not fetch Evidence Ontology props:', err.message);
  }

  // --- Sales Mirror ---
  let salesProps = [];
  try {
    const path =
      SALES_DB.type === 'data_source'
        ? `data_sources/${SALES_DB.id}`
        : `databases/${SALES_DB.id}`;
    const res = await notion.request({ path, method: 'GET' });
    salesProps = Object.keys(res.properties || {});
    console.log(`🧩 Sales Mirror fields (${SALES_DB.type}):`, salesProps.join(', '));
  } catch (err) {
    console.warn('⚠️ Could not fetch Sales Mirror props:', err.message);
  }

  // 2️⃣ Query Supabase
  const { rows: syncs } = await pg.query(`
    SELECT s.sale_id, s.stripe_object, s.object_id, s.status,
           sa.offer_name, sa.cadence, sa.billing_day, sa.sale_currency, sa.creator_id, sa.gross_amount
    FROM public.stripe_sync_log s
    JOIN public.sales sa ON s.sale_id = sa.sale_id
    WHERE s.status = 'queued'
    ORDER BY s.created_at DESC LIMIT 20;
  `);

  const { rows: payouts } = await pg.query(`
    SELECT id, recipient_role, recipient_entity, amount, currency, status, created_at
    FROM public.payouts_v2
    ORDER BY created_at DESC LIMIT 50;
  `);

  console.log(`📦 Found ${syncs.length} sync events and ${payouts.length} payouts.`);

  // 3️⃣ Sync Sales Mirror
  for (const row of syncs) {
    try {
      const props = {};

      // Correct property type handling
      if (salesProps.includes('sale_id')) props.sale_id = { number: Number(row.sale_id) };
      if (salesProps.includes('offer_name'))
        props.offer_name = { rich_text: [{ text: { content: row.offer_name || 'N/A' } }] };
      if (salesProps.includes('gross_amount'))
        props.gross_amount = { number: parseFloat(row.gross_amount || 0) };
      if (salesProps.includes('sale_currency'))
        props.sale_currency = { rich_text: [{ text: { content: row.sale_currency || 'AUD' } }] };
      if (salesProps.includes('cadence'))
        props.cadence = { rich_text: [{ text: { content: row.cadence || 'monthly' } }] };
      if (salesProps.includes('billing_day'))
        props.billing_day = { number: row.billing_day || 15 };
      if (salesProps.includes('status'))
        props.status = { select: { name: row.status || 'queued' } };
      if (salesProps.includes('creator_id'))
        props.creator_id = { rich_text: [{ text: { content: row.creator_id || 'unknown' } }] };

      // Title fallback
      const titleKey =
        salesProps.find((p) => ['title', 'name', 'sale_name'].includes(p)) || 'offer_name';
      if (!props[titleKey])
        props[titleKey] = {
          title: [
            {
              text: {
                content: `Stripe ${row.stripe_object ?? 'EVENT'} ${row.object_id ?? ''}`,
              },
            },
          ],
        };

      await notion.pages.create({
        parent:
          SALES_DB.type === 'data_source'
            ? { data_source_id: SALES_DB.id }
            : { database_id: SALES_DB.id },
        properties: props,
      });

      console.log(`✅ Synced Stripe → ${row.offer_name} (${SALES_DB.type})`);
    } catch (err) {
      console.error('❌ Failed to sync sale to Notion:', err?.body ?? err);
    }
  }

  // 4️⃣ Sync Payouts → Evidence Ontology
  for (const p of payouts) {
    try {
      const props = {};
      props['summary'] = { title: [{ text: { content: `Payout – ${p.recipient_role}` } }] };
      if (evidenceProps.includes('payout_id'))
        props.payout_id = { rich_text: [{ text: { content: String(p.id) } }] };
      if (evidenceProps.includes('processed')) props.processed = { checkbox: false };
      if (evidenceProps.includes('sync_status'))
        props.sync_status = { rich_text: [{ text: { content: p.status } }] };
      if (evidenceProps.includes('source_system'))
        props.source_system = { select: { name: 'Supabase_import' } };
      if (evidenceProps.includes('created_at'))
        props.created_at = { date: { start: p.created_at.toISOString() } };

      await notion.pages.create({
        parent:
          EVIDENCE_DB.type === 'data_source'
            ? { data_source_id: EVIDENCE_DB.id }
            : { database_id: EVIDENCE_DB.id },
        properties: props,
      });

      console.log(
        `✅ Payout – ${p.recipient_role} added to Evidence Ontology (${EVIDENCE_DB.type})`
      );
    } catch (err) {
      console.error(`❌ Failed to add payout ${p.recipient_role}:`, err?.body ?? err);
    }
  }

  console.log('🎯 DAO Ledger → Notion Evidence + Sales Mirror Sync Complete.');
  await pg.end();
})();
