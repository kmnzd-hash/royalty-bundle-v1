import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Initialize Notion
const notion = new NotionClient({ auth: process.env.NOTION_TOKEN });
const payoutsDbId = process.env.NOTION_DB_PAYOUTS;

async function main() {
  // Fetch payouts from Supabase
  const { data: payouts, error } = await supabase
    .from('payouts')
    .select('*');

  if (error) {
    console.error('Supabase fetch error:', error);
    return;
  }

  for (const payout of payouts) {
    try {
      await notion.pages.create({
        parent: { database_id: payoutsDbId },
        properties: {
          Sale: {
            title: [{ text: { content: payout.sale_id.toString() } }]
          },
          Recipient: {
            rich_text: [{ text: { content: payout.recipient_id } }]
          },
          Role: {
            rich_text: [{ text: { content: payout.recipient_role || '' } }]
          },
          Amount: {
            number: payout.amount
          },
          Currency: {
            rich_text: [{ text: { content: payout.currency || 'PHP' } }]
          },
          Status: {
            select: { name: payout.status || 'Pending' }
          }
        }
      });
      console.log(`Payout synced → ${payout.id}`);
    } catch (err) {
      console.error('Notion push error:', err);
    }
  }

  console.log('✅ All payouts synced to Notion');
}

main();

