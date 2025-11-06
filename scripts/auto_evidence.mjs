/**
 * 🚀 Auto Evidence Sync Script (Notion ↔ Supabase)
 * Author: Base44 Team | Updated for Phase 3
 */

import 'dotenv/config';
import { Client as PGClient } from 'pg';
import { Client as NotionClient } from '@notionhq/client';

// ============= CONFIG ==================
const notion = new NotionClient({ auth: process.env.NOTION_TOKEN });
const supabaseUrl = process.env.SUPABASE_DB_URL;
const evidenceDB = process.env.NOTION_EVIDENCE_DB_ID;
const timezone = process.env.TIMEZONE || 'Asia/Manila';
const defaultAITool = process.env.EVIDENCE_DEFAULT_AI_TOOL || 'HeyGen';

// ============= INIT ====================
const pg = new PGClient({ connectionString: supabaseUrl, ssl: { rejectUnauthorized: false } });
await pg.connect();

console.log('🔗 Connected to Supabase');
console.log('📁 Target Notion DB:', evidenceDB);
console.log('🌏 Timezone:', timezone);
console.log('⚙️ Using AI tool:', defaultAITool);

// ============= FETCH EVENTS =============
async function fetchUnprocessedEvents() {
  const query = `
    SELECT 
      event_id AS id, 
      bundle_id, 
      transaction_id, 
      reuse_context, 
      reuse_value, 
      created_at
    FROM public.reuse_event_log
    WHERE event_id NOT IN (
      SELECT event_id FROM public.royalty_ledger
    )
    ORDER BY created_at ASC
    LIMIT 50;
  `;
  const { rows } = await pg.query(query);
  return rows;
}

// ============= CREATE NOTION PAGE =============
async function createNotionEvidencePage(event) {
  try {
    const title = `Evidence: Event ${event.id}`;
    const notionPage = await notion.pages.create({
      parent: { database_id: evidenceDB },
      properties: {
        Name: { title: [{ text: { content: title } }] },
        Source_System: { select: { name: 'Supabase' } },
        Reuse_Value: { number: parseFloat(event.reuse_value || 0) },
        Bundle_ID: { number: event.bundle_id || null },
        Transaction_ID: { number: event.transaction_id || null },
        AI_Render_Tool: { select: { name: defaultAITool } },
        Created_At: { date: { start: event.created_at } },
      },
    });

    const notionPageUrl = notionPage.url;
    console.log(`✅ Created Notion evidence page: ${notionPageUrl}`);

    // Mark as processed in Supabase
    await markEventProcessed(event.id, notionPageUrl);

  } catch (err) {
    console.error(`❌ Error creating Notion page for ${event.id}:`, err.message);
  }
}

// ============= MARK EVENT AS PROCESSED =============
async function markEventProcessed(eventId, notionPageUrl) {
  try {
    // Append processed tag to reuse_context
    await pg.query(
      `UPDATE public.reuse_event_log
       SET reuse_context = COALESCE(reuse_context, '') || ' [processed]',
           reuse_value = reuse_value,
           created_at = created_at
       WHERE event_id = $1;`,
      [eventId]
    );

    // Optionally add backlink to Notion
    if (notionPageUrl) {
      await pg.query(
        `UPDATE public.reuse_event_log
         SET reuse_context = COALESCE(reuse_context, '') || ' [linked:' || $2 || ']'
         WHERE event_id = $1;`,
        [eventId, notionPageUrl]
      );
    }

    console.log(`🔖 Marked reuse_event_log ${eventId} processed.`);
  } catch (err) {
    console.error(`❌ Error marking event ${eventId} processed:`, err.message);
  }
}

// ============= MAIN EXECUTION =============
async function main() {
  try {
    console.log('🧩 Fetching unprocessed reuse events...');
    const events = await fetchUnprocessedEvents();

    if (events.length === 0) {
      console.log('✅ No new reuse events found.');
      return;
    }

    console.log(`📦 Found ${events.length} unprocessed reuse events.`);
    for (const event of events) {
      await createNotionEvidencePage(event);
    }

    console.log('🎉 Evidence sync complete.');
  } catch (err) {
    console.error('Fatal error', err);
  } finally {
    await pg.end();
  }
}

await main();
