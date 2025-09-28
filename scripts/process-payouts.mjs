// scripts/process-payouts.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { Client as NotionClient } from '@notionhq/client';
import fs from 'fs';
import path from 'path';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const notion = new NotionClient({ auth: process.env.NOTION_TOKEN });

const NOTION_DB_PAYOUTS = process.env.NOTION_DB_PAYOUTS;

// small helpers
const nowTs = () => new Date().toISOString().replace(/[:]/g, '-').replace(/\..+$/, '');
function csvSafe(v) { return `"${String(v ?? '').replace(/"/g, '""')}"`; }

async function fetchQueued(limit = 200) {
  const { data, error } = await supabase
    .from('payouts')
    .select('*')
    .eq('status', 'queued')
    .order('created_at', { ascending: true })
    .limit(limit);
  if (error) throw error;
  return data || [];
}

function writeCsv(rows, filepath) {
  const headers = ['payout_id','sale_id','recipient_id','recipient_role','amount','currency','status','created_at'];
  const lines = [headers.join(',')];
  for (const r of rows) {
    lines.push([
      csvSafe(r.payout_id),
      csvSafe(r.sale_id),
      csvSafe(r.recipient_id),
      csvSafe(r.recipient_role),
      csvSafe(r.amount),
      csvSafe(r.currency),
      csvSafe(r.status),
      csvSafe(r.created_at)
    ].join(','));
  }
  fs.mkdirSync(path.dirname(filepath), { recursive: true });
  fs.writeFileSync(filepath, lines.join('\n'));
}

async function updateSupabaseStatus(payoutIds = [], status) {
  if (!payoutIds.length) return;
  const { error } = await supabase
    .from('payouts')
    .update({ status })
    .in('payout_id', payoutIds);
  if (error) throw error;
  return true;
}

async function updateNotionStatusForPayoutId(payoutId, status, evidenceUrl) {
  // Query Notion by rich_text property "Payout ID"
  try {
    const q = await notion.databases.query({
      database_id: NOTION_DB_PAYOUTS,
      filter: { property: 'Payout ID', rich_text: { equals: String(payoutId) } },
      page_size: 1
    });
    if (q.results.length) {
      const pageId = q.results[0].id;
      const props = {
        'Status': { select: { name: status } }
      };
      if (evidenceUrl) props['Evidence'] = { rich_text: [{ text: { content: evidenceUrl } }] };
      await notion.pages.update({ page_id: pageId, properties: props });
      return true;
    } else {
      // Notion row not found — nothing to update
      return false;
    }
  } catch (err) {
    console.error('Notion update error for payout', payoutId, err?.message || err);
    return false;
  }
}

async function exportQueued({ limit = 200 }) {
  const rows = await fetchQueued(limit);
  if (!rows.length) {
    console.log('No queued payouts found.');
    return null;
  }
  const filename = `exports/payouts_export_${nowTs()}.csv`;
  writeCsv(rows, filename);
  console.log(`Wrote ${rows.length} queued payouts → ${filename}`);

  // mark them processing in Supabase
  const ids = rows.map(r => r.payout_id);
  await updateSupabaseStatus(ids, 'processing');
  console.log(`Marked ${ids.length} payouts as processing in Supabase.`);

  // update Notion to processing
  let notionSuccess = 0;
  for (const id of ids) {
    const ok = await updateNotionStatusForPayoutId(id, 'processing', null);
    if (ok) notionSuccess++;
  }
  console.log(`Updated ${notionSuccess}/${ids.length} Notion payout rows to 'processing' (if present).`);
  return filename;
}

async function finalizeFromCsv({ file, evidenceUrl }) {
  if (!fs.existsSync(file)) throw new Error(`CSV not found: ${file}`);
  const text = fs.readFileSync(file, 'utf8');
  const lines = text.split(/\r?\n/).filter(Boolean);
  if (lines.length <= 1) throw new Error('CSV has no rows to finalize.');
  const rows = lines.slice(1).map(l => {
    const cells = l.split(/,(?=(?:(?:[^"]*"){2})*[^"]*$)/).map(c => c.replace(/^"|"$/g, ''));
    return { payout_id: cells[0], sale_id: cells[1] };
  }).filter(Boolean);
  const ids = rows.map(r => r.payout_id).filter(Boolean);
  if (!ids.length) throw new Error('No payout_ids parsed from CSV.');

  // mark as paid in Supabase
  await updateSupabaseStatus(ids, 'paid');
  console.log(`Marked ${ids.length} payouts as 'paid' in Supabase.`);

  // update Notion status + attach evidence link (if provided)
  let notionSuccess = 0;
  for (const id of ids) {
    const ok = await updateNotionStatusForPayoutId(id, 'paid', evidenceUrl || null);
    if (ok) notionSuccess++;
  }
  console.log(`Updated ${notionSuccess}/${ids.length} Notion payout rows to 'paid' (if present).`);
  return ids;
}

async function finalizeList({ ids = [], evidenceUrl }) {
  if (!ids.length) throw new Error('No payout ids provided to finalize.');
  await updateSupabaseStatus(ids, 'paid');
  for (const id of ids) await updateNotionStatusForPayoutId(id, 'paid', evidenceUrl || null);
  console.log(`Marked ${ids.length} payouts as paid.`);
}

// CLI runner
async function runCli() {
  const args = process.argv.slice(2);
  const cmd = args[0] || 'export';

  try {
    if (cmd === 'export') {
      const limitArg = Number(args[1]) || 200;
      const file = await exportQueued({ limit: limitArg });
      if (file) console.log('Export complete:', file);
    } else if (cmd === 'finalize') {
      const file = args[1];
      const evidenceUrl = args[2] || null;
      if (!file) throw new Error('Usage: node scripts/process-payouts.mjs finalize <csv-file> [evidence-url]');
      const ids = await finalizeFromCsv({ file, evidenceUrl });
      console.log('Finalized payouts:', ids.length);
    } else if (cmd === 'finalize-ids') {
      // Usage: node ... finalize-ids id1,id2,id3 [evidenceUrl]
      const idsArg = (args[1] || '').split(',').map(s => s.trim()).filter(Boolean);
      const evidenceUrl = args[2] || null;
      if (!idsArg.length) throw new Error('Usage: finalize-ids id1,id2,... [evidenceUrl]');
      await finalizeList({ ids: idsArg, evidenceUrl });
    } else {
      console.log('Unknown command. Supported: export, finalize <csv>, finalize-ids <id,id,...>');
    }
  } catch (err) {
    console.error('Error:', err?.message || err);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  runCli();
}

export { fetchQueued, exportQueued, finalizeFromCsv, finalizeList };

