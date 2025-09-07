// scripts/sync-to-notion.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';

// ---------------------------
// Initialize clients
// ---------------------------
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const notion = new NotionClient({ auth: process.env.NOTION_TOKEN });
const bundlesDbId = process.env.NOTION_BUNDLES_DATABASE_ID;

// ---------------------------
// Fetch bundles from Supabase
// ---------------------------
const { data: bundlesFromSupabase, error } = await supabase
  .from('bundles') // Make sure this matches your Supabase table
  .select('*');

if (error) {
  console.error('Error fetching bundles from Supabase:', error);
  process.exit(1);
}

console.log('Bundles from Supabase:', bundlesFromSupabase);

// ---------------------------
// Sync bundles to Notion
// ---------------------------
for (let bundle of bundlesFromSupabase) {
  try {
    await notion.pages.create({
      parent: { database_id: bundlesDbId },
      properties: {
        'Name': {
          title: [
            {
              text: { content: bundle.id || 'Untitled Bundle' }
            }
          ]
        },
        'Bundle Type': { 
          rich_text: [{ text: { content: bundle.bundle_type || '' } }] 
        },
        'Entity From': { 
          rich_text: [{ text: { content: bundle.entity_from || '' } }] 
        },
        'Entity To': { 
          rich_text: [{ text: { content: bundle.entity_to || '' } }] 
        },
        'IP Holder': { 
          rich_text: [{ text: { content: bundle.ip_holder || '' } }] 
        },
        'Override Pct': { 
          rich_text: [{ text: { content: bundle.override_pct || '' } }] 
        },
        'Vault ID': { 
          rich_text: [{ text: { content: bundle.vault_id || '' } }] 
        },
        'Creator ID': { 
          rich_text: [{ text: { content: bundle.creator_id || '' } }] 
        },
        'Referrer ID': { 
          rich_text: [{ text: { content: bundle.referrer_id || '' } }] 
        },
        'Reuse Event': { 
          checkbox: Boolean(bundle.reuse_event) 
        },
        'Created At': {
          date: bundle.created_at ? { start: bundle.created_at } : null
        }
      }
    });
    console.log(`✅ Bundle synced → ${bundle.id}`);
  } catch (err) {
    console.error(`❌ Failed to sync bundle ${bundle.id}:`, err.message);
  }
}

console.log('✅ All bundles synced to Notion');
