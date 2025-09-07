import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const notion = new NotionClient({ auth: process.env.NOTION_TOKEN });

async function main() {
  // 1. Pull sales from Supabase
  const { data: sales, error } = await supabase.from('sales').select('*');
  if (error) throw error;

  for (const sale of sales) {
   // console.log(sale);
    // 2. Find bundle in Notion by vault_id
    const bundleVaultId = sale.bundle_vault_id; // Make sure this column exists in Supabase
    
    await notion.pages.create({
      parent: { database_id: process.env.NOTION_SALES_DATABASE_ID },
      properties: {
        "Offer Name": { title: [{ text: { content: sale.offer_name } }] },
        "Bundle Vault ID": { rich_text: [{ text: { content: bundleVaultId } }] },
        "Sale Amount": { number: Number(sale.sale_amount) },
        "Currency": { rich_text: [{ text: { content: sale.sale_currency || 'PHP' } }] },
        "Sale Date": { date: { start: sale.sale_date } } 
      },
    });
  }

  console.log('✅ Sales synced to Notion');
}

main().catch(console.error);

