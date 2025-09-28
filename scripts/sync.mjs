import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';
import crypto from 'node:crypto'; // for crypto.randomUUID()

// ----------------- Notion property mapping (single source of truth) -----------------
const NOTION_PROPS = {
  DB: {
    BUNDLES: process.env.NOTION_DB_BUNDLES || null,
    SALES: process.env.NOTION_DB_SALES || null,
    PAYOUTS: process.env.NOTION_DB_PAYOUTS || null,
    DASHBOARD: process.env.NOTION_DB_DASHBOARD || null
  },

  // Dashboard
  DASH_OFFERS: '#Offers',
  DASH_SALES: '#Sales',
  DASH_ROYALTIES_QUEUED: 'Royalties Queued',
  DASH_LAST_SYNCED: 'Last Synced',

  // Sales props
  SALES_OFFER_NAME: 'Offer Name',
  SALES_VAULT_ID: 'Bundle Vault ID',
  SALES_SALE_AMOUNT: 'Sale Amount',
  SALES_CALC_SPLIT: 'Calculated Split',
  SALES_LINKED_ID: 'Linked Sale ID',
  SALES_CURRENCY: 'Currency',
  SALES_SALE_DATE: 'Sale Date',

  // Bundle props
  BUNDLE_NAME: 'Name',
  BUNDLE_VAULT_ID: 'Vault ID',
  BUNDLE_TYPE: 'Bundle Type',
  ENTITY_FROM: 'Entity From',
  ENTITY_TO: 'Entity To',
  IP_HOLDER: 'IP Holder',
  OVERRIDE_PCT: 'Override Pct',
  CREATOR_ID: 'Creator ID',
  REFERRER_ID: 'Referrer ID',
  REUSE_EVENT: 'Reuse Event',

  // Payout props
  PAYOUT_SALE_ID: 'Sale ID',
  PAYOUT_RECIPIENT: 'Recipient',
  PAYOUT_ROLE: 'Role',
  PAYOUT_AMOUNT: 'Amount',
  PAYOUT_CURRENCY: 'Currency',
  PAYOUT_STATUS: 'Status',
  PAYOUT_PAYOUT_ID: 'Payout ID'
};
// ------------------------------------------------------------------------------------

// ENV
const {
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  NOTION_TOKEN
} = process.env;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing Supabase env vars');
}
if (!NOTION_TOKEN) {
  throw new Error('Missing Notion token');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const notion = new NotionClient({ auth: NOTION_TOKEN });

// Helpers
const text = (s) => ({ rich_text: [{ type: 'text', text: { content: String(s ?? '') } }] });
const title = (s) => ({ title: [{ type: 'text', text: { content: String(s ?? '') } }] });

function parseSplit(str) {
  if (!str) return [];
  const nums = String(str).split(/[\/|,]/).map((s) => Number(String(s).trim())).filter((n) => !isNaN(n));
  const sum = nums.reduce((a, b) => a + b, 0);
  return sum === 0 ? [] : nums.map((n) => (n / sum) * 100);
}

function calcPayouts(gross, split, recipients) {
  const cents = Math.round(Number(gross) * 100);
  const n = Math.min(split.length, recipients.length);
  let used = 0;
  const rows = [];
  for (let i = 0; i < n; i++) {
    const amt = i === n - 1 ? cents - used : Math.round((split[i] / 100) * cents);
    used += amt;
    rows.push({ ...recipients[i], amount: amt / 100 });
  }
  return rows;
}

async function findBundleByVaultId(vaultId, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const { data, error } = await supabase
        .from('bundles')
        .select('*')
        .eq('vault_id', vaultId)
        .limit(1);

      if (error) throw error;
      return data?.[0] || null;
    } catch (err) {
      console.error(`❌ findBundleByVaultId failed (attempt ${attempt}):`, err.message || err);
      if (attempt === retries) throw err;
      await new Promise(res => setTimeout(res, 1000 * attempt));
    }
  }
  return null;
}

// Find a Notion Payout page by Sale ID + Role (returns page or null)
async function findNotionPayoutPageBySaleAndRole(notionClient, saleId, role) {
  if (!NOTION_PROPS.DB.PAYOUTS) return null;
  try {
    const res = await notionClient.databases.query({
      database_id: NOTION_PROPS.DB.PAYOUTS,
      filter: {
        and: [
          { property: NOTION_PROPS.PAYOUT_SALE_ID, rich_text: { equals: String(saleId) } },
          { property: NOTION_PROPS.PAYOUT_ROLE, select: { equals: role } }
        ]
      },
      page_size: 1
    });
    return res.results?.[0] || null;
  } catch (err) {
    console.error('findNotionPayoutPageBySaleAndRole error', err);
    return null;
  }
}

/**
 * upsertSale
 * - ensures sale row exists in Supabase
 * - creates/updates payouts in Supabase (skips referrer when missing)
 */
async function upsertSale({ offerName, vaultId, saleAmount, currency = 'USD', saleDate }) {
  const bundle = await findBundleByVaultId(vaultId);
  if (!bundle) throw new Error(`Bundle not found for vault_id=${vaultId}`);

  // ensure offer exists or create one
  let offerId;
  {
    const { data: offer, error: offerErr } = await supabase
      .from('offers')
      .select('offer_id')
      .eq('bundle_id', bundle.bundle_id)
      .eq('offer_name', offerName)
      .maybeSingle();
    if (offerErr) throw offerErr;

    if (offer?.offer_id) {
      offerId = offer.offer_id;
    } else {
      const { data: ins, error: insErr } = await supabase
        .from('offers')
        .insert({ bundle_id: bundle.bundle_id, offer_name: offerName, price: saleAmount, currency })
        .select('offer_id')
        .single();
      if (insErr) throw insErr;
      offerId = ins.offer_id;
    }
  }

  // 1) Find existing sale
  const { data: salesRows, error: findSaleErr } = await supabase
    .from('sales')
    .select('*')
    .eq('vault_id', vaultId)
    .eq('offer_id', offerId)
    .eq('gross_amount', saleAmount)
    .order('sale_date', { ascending: false })
    .limit(1);

  if (findSaleErr) throw findSaleErr;
  let sale = (salesRows && salesRows[0]) || null;

  // 2) If not found, insert
  if (!sale) {
    const { data: newSale, error: saleErr } = await supabase
      .from('sales')
      .insert({
        offer_id: offerId,
        offer_name: offerName,
        gross_amount: saleAmount,
        sale_currency: currency,
        sale_date: saleDate ?? new Date().toISOString(),
        vault_id: vaultId,
        bundle_id: bundle.bundle_id,
        creator_id: bundle.creator_id,
        referrer_id: bundle.referrer_id,
        ip_holder: bundle.ip_holder,
        override_pct: bundle.override_pct,
      })
      .select('*')
      .single();
    if (saleErr) throw saleErr;
    sale = newSale;
  }

  // === PAYOUTS ===
  // compute split recipients from bundle override pct (creator/ip_holder/referrer if present)
  const split = parseSplit(bundle.override_pct || sale.override_pct);
  const splitRecipients = [];
  if (bundle.creator_id) splitRecipients.push({ id: bundle.creator_id, role: 'creator' });
  if (bundle.ip_holder) splitRecipients.push({ id: bundle.ip_holder, role: 'ip_holder' });
  if (bundle.referrer_id) splitRecipients.push({ id: bundle.referrer_id, role: 'referrer' });

  const splitPayoutRows = calcPayouts(Number(sale.gross_amount), split, splitRecipients);

  // executor must always use sale.gross_amount (per SOP)
  const executorPayout = bundle.entity_to
    ? [{ id: bundle.entity_to, role: 'executor', amount: Number(sale.gross_amount) }]
    : [];

  const allPayouts = [...executorPayout, ...splitPayoutRows];

  for (const p of allPayouts) {
    // Defensive: skip referrer if recipient id missing (we also avoid adding it above)
    if (p.role === 'referrer' && !p.id) continue;

    // If recipient id missing for other roles, skip creating payout (avoid 'N/A' insertion).
    if (!p.id) {
      console.warn(`Skipping payout for role=${p.role} because recipient id is missing. sale=${sale.sale_id}`);
      continue;
    }

    const { data: existing, error: findErr } = await supabase
      .from('payouts')
      .select('status, payout_id')
      .eq('sale_id', sale.sale_id)
      .eq('recipient_role', p.role)
      .maybeSingle();

    if (findErr) throw findErr;

    if (existing) {
      const { error: updateErr } = await supabase
        .from('payouts')
        .update({ amount: p.amount, currency: sale.sale_currency })
        .eq('sale_id', sale.sale_id)
        .eq('recipient_role', p.role);
      if (updateErr) throw updateErr;
    } else {
      const insertObj = {
        payout_id: crypto.randomUUID(),
        sale_id: sale.sale_id,
        recipient_id: p.id,
        recipient_role: p.role,
        amount: p.amount,
        currency: sale.sale_currency,
        status: 'queued',
      };
      const { data: inserted, error: insertErr } = await supabase
        .from('payouts')
        .insert(insertObj)
        .select()
        .single();

      if (insertErr) {
        // try graceful resolution for unique conflicts
        if (String(insertErr.message || insertErr.code).includes('duplicate') || String(insertErr.code).includes('23505')) {
          await supabase.from('payouts').update({
            amount: p.amount,
            currency: sale.sale_currency
          }).match({ sale_id: sale.sale_id, recipient_role: p.role });
        } else {
          throw insertErr;
        }
      } else {
        // inserted successfully
      }
    }
  }

  return sale;
}

// === Notion helpers ===
async function upsertDashboardMetrics() {
  const { count: offersNum } = await supabase.from('offers').select('*', { count: 'exact', head: true });
  const { count: salesNum } = await supabase.from('sales').select('*', { count: 'exact', head: true });
  const { data: queuedSales } = await supabase.from('sales').select('gross_amount, sale_id');

  const queuedSum = (queuedSales || []).reduce((a, b) => a + Number(b.gross_amount || 0), 0);
  const lastSynced = new Date().toISOString().replace('T', ' ').slice(0, 19);

  const props = {
    [NOTION_PROPS.DASH_OFFERS]: { number: offersNum ?? 0 },
    [NOTION_PROPS.DASH_SALES]: { number: salesNum ?? 0 },
    [NOTION_PROPS.DASH_ROYALTIES_QUEUED]: { number: Math.round(queuedSum * 100) / 100 },
    [NOTION_PROPS.DASH_LAST_SYNCED]: { rich_text: [{ text: { content: lastSynced } }] },
  };

  if (!NOTION_PROPS.DB.DASHBOARD) {
    console.warn('No NOTION dashboard DB configured in env; skipping dashboard update');
    return;
  }

  const list = await notion.databases.query({ database_id: NOTION_PROPS.DB.DASHBOARD, page_size: 1 });

  if (!list.results.length) {
    await notion.pages.create({ parent: { database_id: NOTION_PROPS.DB.DASHBOARD }, properties: props });
    console.log('✅ Dashboard row created');
  } else {
    await notion.pages.update({ page_id: list.results[0].id, properties: props });
    console.log('✅ Dashboard row updated');
  }
}

async function syncOneSale(page) {
  const props = page.properties || {};
  const offerName = props[NOTION_PROPS.SALES_OFFER_NAME]?.title?.[0]?.plain_text || 'Unnamed Offer';
  const vaultId = props[NOTION_PROPS.SALES_VAULT_ID]?.rich_text?.[0]?.plain_text;
  const saleAmount = Number(props[NOTION_PROPS.SALES_SALE_AMOUNT]?.number || 0);
  const currency = props[NOTION_PROPS.SALES_CURRENCY]?.rich_text?.[0]?.plain_text || 'USD';
  const saleDate = props[NOTION_PROPS.SALES_SALE_DATE]?.date?.start;
  if (!vaultId || !saleAmount) return;

  const sale = await upsertSale({ offerName, vaultId, saleAmount, currency, saleDate });
  return sale;
}

async function pullNewSalesFromNotion() {
  if (!NOTION_PROPS.DB.SALES) {
    console.warn('Notion Sales DB not configured, skipping pullNewSalesFromNotion');
    return;
  }
  const resp = await notion.databases.query({ database_id: NOTION_PROPS.DB.SALES, page_size: 25 });
  for (const page of resp.results) {
    await syncOneSale(page);
  }
}

async function pushSupabaseBundlesToNotion() {
  if (!NOTION_PROPS.DB.BUNDLES) {
    console.warn('Notion Bundles DB not configured, skipping pushSupabaseBundlesToNotion');
    return;
  }

  const { data: bundles, error } = await supabase
    .from('bundles')
    .select('bundle_id,bundle_type,entity_from,entity_to,ip_holder,override_pct,vault_id,creator_id,referrer_id,reuse_event,created_at');
  if (error) throw error;

  for (const b of bundles || []) {
    const q = await notion.databases.query({
      database_id: NOTION_PROPS.DB.BUNDLES,
      filter: { property: NOTION_PROPS.BUNDLE_VAULT_ID, rich_text: { equals: String(b.vault_id) } },
      page_size: 1,
    });
    const props = {
      [NOTION_PROPS.BUNDLE_NAME]: title(String(b.vault_id || b.bundle_id)),
      [NOTION_PROPS.BUNDLE_TYPE]: { select: { name: b.bundle_type } },
      [NOTION_PROPS.ENTITY_FROM]: text(b.entity_from),
      [NOTION_PROPS.ENTITY_TO]: text(b.entity_to),
      [NOTION_PROPS.IP_HOLDER]: text(b.ip_holder),
      [NOTION_PROPS.OVERRIDE_PCT]: text(b.override_pct),
      [NOTION_PROPS.BUNDLE_VAULT_ID]: text(b.vault_id),
      [NOTION_PROPS.CREATOR_ID]: text(b.creator_id),
      [NOTION_PROPS.REFERRER_ID]: text(b.referrer_id),
      [NOTION_PROPS.REUSE_EVENT]: { checkbox: !!b.reuse_event },
    };
    if (!q.results.length) {
      await notion.pages.create({ parent: { database_id: NOTION_PROPS.DB.BUNDLES }, properties: props });
    } else {
      await notion.pages.update({ page_id: q.results[0].id, properties: props });
    }
  }
}

async function pushSupabaseSalesToNotion() {
  if (!NOTION_PROPS.DB.SALES) {
    console.warn('Notion Sales DB not configured, skipping pushSupabaseSalesToNotion');
    return;
  }

  const { data: sales, error } = await supabase
    .from('sales')
    .select('*')
    .order('created_at', { ascending: true })
    .limit(500);
  if (error) throw error;

  for (const s of sales || []) {
    const saleId = s.sale_id;
    const offerName = s.offer_name || '';
    const vaultId = s.vault_id || '';
    const saleAmount = s.gross_amount;
    const currency = s.sale_currency;
    const saleDate = s.sale_date;

    // Build Calculated Split from payouts table for this sale
    const { data: payoutsForSale } = await supabase.from('payouts').select('*').eq('sale_id', saleId);
    const rolesOrder = ['executor', 'creator', 'ip_holder', 'referrer'];
    const parts = [];
    for (const role of rolesOrder) {
      const p = (payoutsForSale || []).find(x => x.recipient_role === role && x.recipient_id);
      if (p) parts.push(`${role}: ${Number(p.amount).toFixed(2)}`);
    }
    const splitStr = `[${offerName}] ` + (parts.length ? parts.join(' | ') : 'no payouts');

    // Find existing Notion Sales page by Linked Sale ID
    const q = await notion.databases.query({
      database_id: NOTION_PROPS.DB.SALES,
      filter: { property: NOTION_PROPS.SALES_LINKED_ID, rich_text: { equals: String(saleId) } },
      page_size: 1,
    });

    const props = {
      [NOTION_PROPS.SALES_OFFER_NAME]: title(offerName),
      [NOTION_PROPS.SALES_VAULT_ID]: text(vaultId),
      [NOTION_PROPS.SALES_SALE_AMOUNT]: { number: Number(saleAmount) || 0 },
      [NOTION_PROPS.SALES_CURRENCY]: text(currency || ''),
      [NOTION_PROPS.SALES_SALE_DATE]: saleDate ? { date: { start: saleDate } } : undefined,
      [NOTION_PROPS.SALES_CALC_SPLIT]: text(splitStr),
      [NOTION_PROPS.SALES_LINKED_ID]: text(String(saleId)),
    };

    if (!q.results.length) {
      await notion.pages.create({ parent: { database_id: NOTION_PROPS.DB.SALES }, properties: props });
    } else {
      await notion.pages.update({ page_id: q.results[0].id, properties: props });
    }

    // Ensure Payouts exist in Notion for this sale (create or update by Sale ID + Role)
    if (NOTION_PROPS.DB.PAYOUTS) {
      for (const p of (payoutsForSale || [])) {
        // skip payouts where recipient_id is null/blank (means no recipient)
        if (!p.recipient_id) continue;

        const existingPage = await findNotionPayoutPageBySaleAndRole(notion, saleId, p.recipient_role);
        const payoutProps = {
          [NOTION_PROPS.PAYOUT_SALE_ID]: title(String(p.sale_id)),
          [NOTION_PROPS.PAYOUT_RECIPIENT]: text(String(p.recipient_id)),
          [NOTION_PROPS.PAYOUT_ROLE]: { select: { name: p.recipient_role } },
          [NOTION_PROPS.PAYOUT_AMOUNT]: { number: Number(p.amount) || 0 },
          [NOTION_PROPS.PAYOUT_CURRENCY]: text(p.currency || ''),
          [NOTION_PROPS.PAYOUT_STATUS]: { select: { name: p.status || 'queued' } },
          [NOTION_PROPS.PAYOUT_PAYOUT_ID]: text(String(p.payout_id || '')),
        };

        if (existingPage) {
          await notion.pages.update({ page_id: existingPage.id, properties: payoutProps });
        } else {
          await notion.pages.create({
            parent: { database_id: NOTION_PROPS.DB.PAYOUTS },
            properties: payoutProps
          });
        }
      }
    }
  }
}

// === Sync Orchestration ===
async function main() {
  console.log('Starting sync — this will pull Sales from Notion, push Bundles, push Sales, and update Dashboard.');

  await pullNewSalesFromNotion();
  await pushSupabaseBundlesToNotion();
  await pushSupabaseSalesToNotion();
  await upsertDashboardMetrics();

  // === Summary Report ===
  const { count: offersNum } = await supabase.from('offers').select('*', { count: 'exact', head: true });
  const { count: salesNum } = await supabase.from('sales').select('*', { count: 'exact', head: true });
  const { count: payoutsNum } = await supabase.from('payouts').select('*', { count: 'exact', head: true });

  console.log('\n📊 === SUMMARY REPORT ===');
  console.log(`- Supabase offers: ${offersNum}`);
  console.log(`- Supabase sales: ${salesNum}`);
  console.log(`- Supabase payouts: ${payoutsNum}`);
  console.log('✅ Sync complete — check Notion dashboards and payouts for correctness.');
}

main().catch((e) => {
  console.error('Sync failed:', e);
  process.exit(1);
});
