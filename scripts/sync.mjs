import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';
import crypto from 'node:crypto';

// ----------------- CONFIG -----------------
const NOTION_PROPS = {
  DB: {
    BUNDLES: process.env.NOTION_DB_BUNDLES || null,
    PAYOUTS: process.env.NOTION_DB_PAYOUTS || null,
    DASHBOARD: process.env.NOTION_DB_DASHBOARD || null
  },
  DASH_OFFERS: '#Offers',
  DASH_SALES: '#Sales',
  DASH_ROYALTIES_QUEUED: 'Royalties Queued',
  DASH_LAST_SYNCED: 'Last Synced'
};

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, NOTION_TOKEN } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) throw new Error('Missing Supabase env vars');
if (!NOTION_TOKEN) throw new Error('Missing Notion token');

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const notion = new NotionClient({ auth: NOTION_TOKEN });

// ----------------- HELPERS -----------------
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

// ----------------- PRE-FLIGHT VALIDATION -----------------
async function preflightValidateBundles() {
  if (!NOTION_PROPS.DB.BUNDLES) {
    console.warn('No Notion Bundles DB configured; skipping preflight.');
    return;
  }

  const { data: allBundles, error: bundlesErr } = await supabase.from('bundles').select('vault_id');
  if (bundlesErr) throw new Error(`Failed to fetch bundles: ${bundlesErr.message}`);

  const bundleSet = new Set((allBundles || []).map((b) => String(b.vault_id)));

  const pageSize = 100;
  let start_cursor = undefined;
  const missing = new Set();

  while (true) {
    const res = await notion.databases.query({
      database_id: NOTION_PROPS.DB.BUNDLES,
      page_size: pageSize,
      start_cursor
    });
    for (const page of res.results || []) {
      const vaultId = page.properties?.['Vault ID']?.rich_text?.[0]?.plain_text || null;
      if (vaultId && !bundleSet.has(vaultId)) missing.add(vaultId);
    }
    if (!res.has_more) break;
    start_cursor = res.next_cursor;
  }

  if (missing.size > 0) {
    throw new Error(`Missing bundles for vaults: ${[...missing].join(', ')}`);
  }

  console.log('✅ Preflight validation passed — all Notion Sales vault_ids exist in Supabase bundles.');
}

// ----------------- UPSERT OFFER & PAYOUTS (NO SALES) -----------------
async function upsertSale({ offerName, vaultId, saleAmount, currency = 'USD', notionPageId = null }) {
  // 1️⃣ find bundle
  const bundle = await findBundleByVaultId(vaultId);
  if (!bundle) throw new Error(`Bundle not found for vault_id=${vaultId}`);

  // 2️⃣ ensure offer exists or create
  let offerId;
  const { data: offer, error: offerErr } = await supabase
    .from('offers')
    .select('id')
    .eq('name', offerName)
    .maybeSingle();
  if (offerErr) throw offerErr;

  // Map bundle_type → allowed offer_type values
  let derivedOfferType = 'core';
  const bt = (bundle.bundle_type || '').toLowerCase();
  if (bt.includes('lead')) derivedOfferType = 'lead_gen';
  else if (bt.includes('continuity')) derivedOfferType = 'continuity';
  else if (bt.includes('premium')) derivedOfferType = 'premium';

  if (offer?.id) {
    offerId = offer.id;
  } else {
    const { data: ins, error: insErr } = await supabase
      .from('offers')
      .insert({
        name: offerName,
        offer_type: derivedOfferType,
        description: `Auto-created offer for bundle ${bundle.vault_id}`,
        default_price: saleAmount
      })
      .select('id')
      .single();
    if (insErr) throw insErr;
    offerId = ins.id;
  }

  // 3️⃣ determine recipients
  const split = parseSplit(bundle.override_pct || null);
  const splitCandidates = [];
  if (bundle.entity_from) splitCandidates.push({ id: bundle.entity_from, role: 'creator' });
  if (bundle.ip_holder) splitCandidates.push({ id: bundle.ip_holder, role: 'ip_holder' });
  if (bundle.entity_to) splitCandidates.push({ id: bundle.entity_to, role: 'executor' });

  const splitPayoutRows = calcPayouts(Number(saleAmount), split, splitCandidates);

  // 4️⃣ insert payouts directly
  for (const p of splitPayoutRows) {
    const insertObj = {
      payout_uuid: crypto.randomUUID(),
      transaction_id: null,
      sale_id: null,
      recipient_entity: Number(p.id),
      recipient_role: p.role,
      amount: Number(p.amount) || 0,
      currency,
      status: 'queued',
      notion_page_url: notionPageId ? String(notionPageId) : null,
      created_at: new Date().toISOString(),
      sent_at: null
    };

    const { error: insertErr } = await supabase.from('payouts_v2').insert(insertObj).select();
    if (insertErr) throw insertErr;
    console.log(`✅ Payout created: ${p.role} (${p.amount}) for vault ${vaultId}`);
  }

  return { offer_id: offerId, vault_id: vaultId, total_amount: saleAmount, currency };
}

// ----------------- DASHBOARD METRICS -----------------
async function upsertDashboardMetrics() {
  const { count: offersNum } = await supabase.from('offers').select('*', { count: 'exact', head: true });
  const { count: payoutsNum } = await supabase.from('payouts_v2').select('*', { count: 'exact', head: true });
  const { data: queuedPayouts } = await supabase.from('payouts_v2').select('amount');
  const totalQueued = (queuedPayouts || []).reduce((a, b) => a + Number(b.amount || 0), 0);
  const lastSynced = new Date().toISOString().replace('T', ' ').slice(0, 19);

  const props = {
    [NOTION_PROPS.DASH_OFFERS]: { number: offersNum ?? 0 },
    [NOTION_PROPS.DASH_SALES]: { number: 0 },
    [NOTION_PROPS.DASH_ROYALTIES_QUEUED]: { number: Math.round(totalQueued * 100) / 100 },
    [NOTION_PROPS.DASH_LAST_SYNCED]: { rich_text: [{ text: { content: lastSynced } }] }
  };

  if (!NOTION_PROPS.DB.DASHBOARD) {
    console.warn('No Notion dashboard configured; skipping update');
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

// ----------------- MAIN -----------------
async function main() {
  console.log('Starting sync — this will pull Sales from Notion, push Bundles, push Sales, and update Dashboard.');
  await preflightValidateBundles();

  // EXAMPLE manual calls (you can replace with your Notion iteration)
  await upsertSale({ offerName: 'Growth Pack', vaultId: 'vault-01', saleAmount: 10000 });
  await upsertSale({ offerName: 'Nestwell Retreat', vaultId: 'vault-02', saleAmount: 10000 });

  await upsertDashboardMetrics();

  console.log('\n📊 === SUMMARY REPORT ===');
  console.log('✅ Sync complete — check Notion dashboards and payouts for correctness.');
}

main().catch((e) => {
  console.error('Sync failed:', e);
  process.exit(1);
});
