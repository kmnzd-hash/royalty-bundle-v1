/**
 * FINAL PRODUCTION VERSION (Slack + Discord Alerts)
 * -------------------------------------------------
 * ✅ Notion → Supabase Reverse Sync
 * ✅ Auto-detects data_source / database
 * ✅ Fallbacks for invalid_request_url
 * ✅ JSON logging
 * ✅ Slack + Discord notifications
 */

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import fetch from 'node-fetch';
import chalk from 'chalk';
import pkg from 'pg';
const { Client: PgClient } = pkg;

const NOTION_TOKEN = process.env.NOTION_TOKEN;
const SUPABASE_DB_URL = process.env.SUPABASE_DB_URL;
const DRY_RUN = process.env.DRY_RUN === 'true';
const SALES_ID = process.env.NOTION_SALES_DS_ID || process.env.NOTION_SALES_DB_ID;
const SLACK_WEBHOOK = process.env.SLACK_WEBHOOK_URL || process.env.SLACK_WEBHOOK;
const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK_URL;

const LOG_DIR = path.resolve('./logs');
const LOG_FILE = path.join(LOG_DIR, 'sync-report.json');
if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

const notionHeaders = {
  Authorization: `Bearer ${NOTION_TOKEN}`,
  'Notion-Version': '2025-09-03',
  'Content-Type': 'application/json',
};

// Helper: Log report to JSON
function logReport(data) {
  const existing = fs.existsSync(LOG_FILE)
    ? JSON.parse(fs.readFileSync(LOG_FILE, 'utf-8'))
    : [];
  existing.push(data);
  fs.writeFileSync(LOG_FILE, JSON.stringify(existing, null, 2));
}

// Helper: Post Slack or Discord alert
async function sendWebhook(summary) {
  const mention = process.env.SLACK_USER_ID
    ? `<@${process.env.SLACK_USER_ID}>`
    : '@channel';

  const alertEmoji = summary.errors > 0 ? '🚨' : '✅';
  const mode = summary.mode.toUpperCase();
  const text = `${alertEmoji} *DAO Sync Report* (${mode})\n
🕒 ${new Date(summary.time).toLocaleString()}
📦 Total: ${summary.total}
✅ Synced: ${summary.synced}
⚠️ Errors: ${summary.errors}
📋 Status: ${summary.message || 'Completed successfully.'}
${summary.errors > 0 ? `\n${mention} — please check the logs.` : ''}`;

  const payload = { text };

  try {
    if (SLACK_WEBHOOK) {
      await fetch(SLACK_WEBHOOK, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      console.log(chalk.cyan('📢 Slack alert sent.'));
    }

    if (DISCORD_WEBHOOK) {
      await fetch(DISCORD_WEBHOOK, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: text.replace(/\*/g, '**') }),
      });
      console.log(chalk.cyan('📢 Discord alert sent.'));
    }
  } catch (e) {
    console.warn(chalk.yellow('⚠️ Failed to send webhook alert:'), e.message);
  }
}

// Helper: Identify Notion type
async function resolveNotionType(id) {
  const endpoints = [
    { url: `https://api.notion.com/v1/data_sources/${id}`, type: 'data_source' },
    { url: `https://api.notion.com/v1/databases/${id}`, type: 'database' },
  ];

  for (const ep of endpoints) {
    const res = await fetch(ep.url, { headers: notionHeaders });
    if (res.ok) {
      const json = await res.json();
      console.log(chalk.green(`🧩 Detected ${ep.type} → ${json.id}`));
      return ep.type;
    }
  }

  throw new Error(`❌ Notion ID ${id} not found as either data_source or database.`);
}

// Helper: Query Notion safely
async function queryNotion(id, type) {
  const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString();
  try {
    const res =
      type === 'data_source'
        ? await fetch(`https://api.notion.com/v1/data_sources/${id}/query`, {
            method: 'POST',
            headers: notionHeaders,
            body: JSON.stringify({
              filter: {
                timestamp: 'last_edited_time',
                last_edited_time: { after: sixHoursAgo },
              },
              page_size: 50,
            }),
          })
        : await fetch(`https://api.notion.com/v1/databases/${id}/query`, {
            method: 'POST',
            headers: notionHeaders,
            body: JSON.stringify({
              filter: {
                timestamp: 'last_edited_time',
                last_edited_time: { after: sixHoursAgo },
              },
              page_size: 50,
            }),
          });

    if (res.status === 400) {
      console.log(chalk.yellow('⚠️ Invalid request URL — retrying as classic database...'));
      const fallback = await fetch(`https://api.notion.com/v1/databases/${id}/query`, {
        method: 'POST',
        headers: notionHeaders,
        body: JSON.stringify({
          filter: {
            timestamp: 'last_edited_time',
            last_edited_time: { after: sixHoursAgo },
          },
          page_size: 50,
        }),
      });
      const data = await fallback.json();
      console.log(chalk.cyan(`📄 Fallback success — found ${data.results.length} records.`));
      return data.results;
    }

    const data = await res.json();
    console.log(chalk.cyan(`📄 Found ${data.results.length} records in the last 6 hours.`));
    return data.results;
  } catch (err) {
    console.error(chalk.red('❌ Failed to query Notion:'), err);
    return [];
  }
}

(async () => {
  console.log(chalk.cyan('\n🔗 Connecting to Supabase...'));
  const pg = new PgClient({ connectionString: SUPABASE_DB_URL });
  await pg.connect();

  console.log(chalk.yellow(`🧠 Scanning recent Notion edits from ${SALES_ID}...`));
  const notionType = await resolveNotionType(SALES_ID);
  const results = await queryNotion(SALES_ID, notionType);

  const summary = {
    time: new Date().toISOString(),
    total: results.length,
    synced: 0,
    errors: 0,
    mode: DRY_RUN ? 'dry-run' : 'live',
    details: [],
  };

  if (!results.length) {
    console.log(chalk.gray('🕐 No recent edits found.'));
    summary.message = 'No recent edits found.';
    logReport(summary);
    await sendWebhook(summary);
    await pg.end();
    return;
  }

  for (const page of results) {
    try {
      const props = page.properties;
      const sale_id = props.sale_id?.number || props.sale_id?.rich_text?.[0]?.plain_text || null;
      const offer_name = props.offer_name?.title?.[0]?.plain_text || 'Untitled Offer';
      const gross_amount = props.gross_amount?.number || 0;
      const sale_currency = props.sale_currency?.rich_text?.[0]?.plain_text || 'USD';
      const vault_id = props.vault_id?.rich_text?.[0]?.plain_text || '';
      const creator_id = props.creator_id?.rich_text?.[0]?.plain_text || '';
      const ip_holder = props.ip_holder?.rich_text?.[0]?.plain_text || '';
      const referrer_id = props.referrer_id?.rich_text?.[0]?.plain_text || '';
      const sale_date = props.sale_date?.date?.start || new Date().toISOString();
      const status = props.status?.select?.name || 'queued';
      const cadence = props.cadence?.rich_text?.[0]?.plain_text || 'monthly';
      const billing_day = props.billing_day?.number || 15;

      if (DRY_RUN) {
        console.log(chalk.yellow(`🧩 DRY RUN — Sale ${sale_id || '?'}: ${offer_name}, ${status}`));
        summary.synced++;
        continue;
      }

      const query = `
        INSERT INTO public.sales (
          sale_id, offer_name, gross_amount, sale_currency,
          vault_id, creator_id, ip_holder, referrer_id,
          sale_date, status, cadence, billing_day,
          created_at, updated_at
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12, now(), now())
        ON CONFLICT (sale_id) DO UPDATE SET
          offer_name = excluded.offer_name,
          gross_amount = excluded.gross_amount,
          sale_currency = excluded.sale_currency,
          status = excluded.status,
          cadence = excluded.cadence,
          billing_day = excluded.billing_day,
          updated_at = now();
      `;
      await pg.query(query, [
        sale_id,
        offer_name,
        gross_amount,
        sale_currency,
        vault_id,
        creator_id,
        ip_holder,
        referrer_id,
        sale_date,
        status,
        cadence,
        billing_day,
      ]);

      console.log(chalk.green(`✅ Synced Sale ${sale_id || '?'} → Supabase`));
      summary.synced++;
    } catch (err) {
      console.error(chalk.red(`❌ Failed to sync ${page.id}:`), err);
      summary.errors++;
    }
  }

  summary.message = 'Sync completed.';
  logReport(summary);
  await sendWebhook(summary);
  await pg.end();

  console.log(chalk.green.bold('\n🎯 Reverse sync complete.\n'));
})();
