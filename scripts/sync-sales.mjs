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
    const bundleVaultId = sale.vault_id;

    // 2. Pull payouts for this sale
    const { data: payoutsRows, error: payoutsErr } = await supabase
      .from('payouts')
      .select('*')
      .eq('sale_id', sale.sale_id);

    if (payoutsErr) throw payoutsErr;

    // 3. Build split string (only allowed roles)
    const allowedRoles = ['creator', 'ip_holder', 'referrer'];
    const splitParts = (payoutsRows || [])
      .filter((p) => allowedRoles.includes(p.recipient_role))
      .map((p) => `${p.recipient_role}: ${Number(p.amount).toFixed(2)}`);

    const splitStr = splitParts.length ? splitParts.join(' | ') : 'no payouts';

    // 4. Push to Notion
    await notion.pages.create({
      parent: { database_id: process.env.NOTION_DB_SALES },
      properties: {
        "Offer Name": { title: [{ text: { content: sale.offer_name || '' } }] },
        "Bundle Vault ID": { rich_text: [{ text: { content: bundleVaultId || '' } }] },
        "Sale Amount": { number: Number(sale.gross_amount) || 0 },
        "Currency": { rich_text: [{ text: { content: sale.sale_currency || 'USD' } }] },
        "Sale Date": sale.sale_date ? { date: { start: sale.sale_date } } : undefined,
        "Calculated Split": { rich_text: [{ text: { content: splitStr } }] }, // ✅ added
        "Linked Sale ID": { rich_text: [{ text: { content: String(sale.sale_id) } }] }, // ✅ optional link
      },
    });
  }

  console.log('✅ Sales synced to Notion with Calculated Split');
}

main().catch(console.error);
