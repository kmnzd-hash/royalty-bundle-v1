import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client } from '@notionhq/client';
import crypto from 'crypto';

// ENV
const {
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  NOTION_TOKEN,
  NOTION_DB_BUNDLES,
  NOTION_DB_SALES,
  NOTION_DB_PAYOUTS,
  NOTION_DB_DASHBOARD,
} = process.env;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing Supabase env vars');
}
if (!NOTION_TOKEN) {
  throw new Error('Missing Notion token');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const notion = new Client({ auth: NOTION_TOKEN });

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

async function findBundleByVaultId(vaultId) {
  const { data, error } = await supabase.from('bundles').select('*').eq('vault_id', vaultId).limit(1);
  if (error) throw error;
  return data?.[0] || null;
}

/**
 * upsertSale
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
  const split = parseSplit(bundle.override_pct || sale.override_pct);
  const splitRecipients = [];
  if (bundle.creator_id) splitRecipients.push({ id: bundle.creator_id, role: 'creator' });
  if (bundle.ip_holder) splitRecipients.push({ id: bundle.ip_holder, role: 'ip_holder' });
  if (bundle.referrer_id) splitRecipients.push({ id: bundle.referrer_id, role: 'referrer' });

  const splitPayoutRows = calcPayouts(Number(sale.gross_amount), split, splitRecipients);

  const executorPayout = bundle.entity_to
    ? [{ id: bundle.entity_to, role: 'executor', amount: Number(sale.gross_amount) }]
    : [];

  const allPayouts = [...executorPayout, ...splitPayoutRows];

  for (const p of allPayouts) {
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
      const { error: insertErr } = await supabase
        .from('payouts')
        .insert({
          payout_id: crypto.randomUUID(),
          sale_id: sale.sale_id,
          recipient_id: p.id || 'N/A',
          recipient_role: p.role,
          amount: p.amount,
          currency: sale.sale_currency,
          status: 'queued',
        });
      if (insertErr) throw insertErr;
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
    '#Offers': { number: offersNum ?? 0 },
    '#Sales': { number: salesNum ?? 0 },
    'Royalties Queued': { number: Math.round(queuedSum * 100) / 100 },
    'Last Synced': { rich_text: [{ text: { content: lastSynced } }] },
  };

  const list = await notion.databases.query({ database_id: NOTION_DB_DASHBOARD, page_size: 1 });

  if (!list.results.length) {
    await notion.pages.create({ parent: { database_id: NOTION_DB_DASHBOARD }, properties: props });
    console.log('✅ Dashboard row created');
  } else {
    await notion.pages.update({ page_id: list.results[0].id, properties: props });
    console.log('✅ Dashboard row updated');
  }
}

async function createNotionPayoutRow({ saleId, recipientLabel, role, amount, currency, payoutId }) {
  const props = {
    'Sale ID': title(String(saleId)),
    'Recipient': text(recipientLabel || 'N/A'),
    'Role': role ? { select: { name: role } } : undefined,
    'Amount': { number: Number(amount) },
    'Currency': text(currency || ''),
    'Status': { select: { name: 'queued' } },
    'Payout ID': text(payoutId || ''),
  };
  await notion.pages.create({ parent: { database_id: NOTION_DB_PAYOUTS }, properties: props });
}

async function updateNotionSalesRow({ pageId, offerName, vaultId, saleAmount, saleId, splitStr, currency, saleDate }) {
  const props = {
    'Offer Name': title(offerName),
    'Bundle Vault ID': text(vaultId),
    'Sale Amount': { number: Number(saleAmount) },
    'Currency': text(currency || ''),
    'Sale Date': saleDate ? { date: { start: saleDate } } : undefined,
    'Calculated Split': text(splitStr),
    'Linked Sale ID': text(String(saleId)),
  };
  await notion.pages.update({ page_id: pageId, properties: props });
}

async function syncOneSale(page) {
  const props = page.properties;
  const offerName = props['Offer Name']?.title?.[0]?.plain_text || 'Unnamed Offer';
  const vaultId = props['Bundle Vault ID']?.rich_text?.[0]?.plain_text;
  const saleAmount = Number(props['Sale Amount']?.number || 0);
  const currency = props['Currency']?.rich_text?.[0]?.plain_text || 'USD';
  const saleDate = props['Sale Date']?.date?.start;
  if (!vaultId || !saleAmount) return;

  const sale = await upsertSale({ offerName, vaultId, saleAmount, currency, saleDate });

  const { data: payoutsRows } = await supabase.from('payouts').select('*').eq('sale_id', sale.sale_id);

  const splitParts = [];
  const executor = (payoutsRows || []).find(p => p.recipient_role === 'executor');
  if (executor) splitParts.push(`executor: ${Number(sale.gross_amount).toFixed(2)}`);

  (payoutsRows || [])
    .filter(p => ['creator', 'ip_holder', 'referrer'].includes(p.recipient_role))
    .forEach(p => {
      splitParts.push(`${p.recipient_role}: ${Number(p.amount).toFixed(2)}`);
    });

  const splitStr = `[${offerName}] ` + (splitParts.length ? splitParts.join(' | ') : 'no payouts');

  await updateNotionSalesRow({
    pageId: page.id,
    offerName,
    vaultId,
    saleAmount,
    saleId: sale.sale_id,
    splitStr,
    currency,
    saleDate,
  });

  for (const p of payoutsRows || []) {
    const q = await notion.databases.query({
      database_id: NOTION_DB_PAYOUTS,
      filter: {
        and: [
          { property: 'Sale ID', title: { equals: String(sale.sale_id) } },
          { property: 'Role', select: { equals: p.recipient_role } },
        ],
      },
      page_size: 1,
    });

    if (q.results.length) {
      await notion.pages.update({
        page_id: q.results[0].id,
        properties: {
          'Amount': { number: Number(p.amount) },
          'Currency': text(p.currency || currency),
          'Status': { select: { name: 'queued' } },
          'Recipient': text(p.recipient_id || 'N/A'),
          'Payout ID': text(p.payout_id || ''),
        },
      });
    } else {
      await createNotionPayoutRow({
        saleId: sale.sale_id,
        recipientLabel: String(p.recipient_id || 'N/A'),
        role: p.recipient_role,
        amount: p.amount,
        currency: p.currency || currency,
        payoutId: p.payout_id || '',
      });
    }
  }
}

async function pushSupabaseSalesToNotion() {
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

    const { data: payoutsRows } = await supabase.from('payouts').select('*').eq('sale_id', saleId);

    const splitParts = [];
    const executor = (payoutsRows || []).find(p => p.recipient_role === 'executor');
    if (executor) splitParts.push(`executor: ${Number(s.gross_amount).toFixed(2)}`);

    (payoutsRows || [])
      .filter(p => ['creator', 'ip_holder', 'referrer'].includes(p.recipient_role))
      .forEach(p => {
        splitParts.push(`${p.recipient_role}: ${Number(p.amount).toFixed(2)}`);
      });

    const splitStr = `[${offerName}] ` + (splitParts.join(' | ') || 'no payouts');

    const q = await notion.databases.query({
      database_id: NOTION_DB_SALES,
      filter: { property: 'Linked Sale ID', rich_text: { equals: String(saleId) } },
      page_size: 1,
    });

    const props = {
      'Offer Name': title(offerName),
      'Bundle Vault ID': text(vaultId),
      'Sale Amount': { number: Number(saleAmount) || 0 },
      'Currency': text(currency || ''),
      'Sale Date': saleDate ? { date: { start: saleDate } } : undefined,
      'Calculated Split': text(splitStr),
      'Linked Sale ID': text(String(saleId)),
    };

    if (!q.results.length) {
      await notion.pages.create({ parent: { database_id: NOTION_DB_SALES }, properties: props });
    } else {
      await notion.pages.update({ page_id: q.results[0].id, properties: props });
    }
  }
}

async function pullNewSalesFromNotion() {
  const resp = await notion.databases.query({ database_id: NOTION_DB_SALES, page_size: 25 });
  for (const page of resp.results) {
    await syncOneSale(page);
  }
}

async function pushSupabaseBundlesToNotion() {
  const { data: bundles, error } = await supabase
    .from('bundles')
    .select('bundle_id,bundle_type,entity_from,entity_to,ip_holder,override_pct,vault_id,creator_id,referrer_id,reuse_event,created_at');
  if (error) throw error;
  for (const b of bundles || []) {
    const q = await notion.databases.query({
      database_id: NOTION_DB_BUNDLES,
      filter: { property: 'Vault ID', rich_text: { equals: String(b.vault_id) } },
      page_size: 1,
    });
    const props = {
      'Name': title(String(b.vault_id || b.bundle_id)),
      'Bundle Type': { select: { name: b.bundle_type } },
      'Entity From': text(b.entity_from),
      'Entity To': text(b.entity_to),
      'IP Holder': text(b.ip_holder),
      'Override Pct': text(b.override_pct),
      'Vault ID': text(b.vault_id),
      'Creator ID': text(b.creator_id),
      'Referrer ID': text(b.referrer_id),
      'Reuse Event': { checkbox: !!b.reuse_event },
    };
    if (!q.results.length) {
      await notion.pages.create({ parent: { database_id: NOTION_DB_BUNDLES }, properties: props });
    } else {
      await notion.pages.update({ page_id: q.results[0].id, properties: props });
    }
  }
}

async function main() {
  await pullNewSalesFromNotion();
  await pushSupabaseBundlesToNotion();
  await pushSupabaseSalesToNotion();
  await upsertDashboardMetrics();
  console.log('✅ Sync complete');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
