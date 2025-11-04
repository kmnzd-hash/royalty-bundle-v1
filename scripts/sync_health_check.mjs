/**
 * sync_health_check.mjs
 * ---------------------
 * Weekly system audit script for DAO + Sync pipelines
 * Checks:
 *  - Notion DB connections (Sales, Bundle, Treasury, Evidence)
 *  - Supabase connection
 *  - Slack alert confirmation
 */

import 'dotenv/config';
import fetch from 'node-fetch';
import pkg from 'pg';
const { Client: PgClient } = pkg;

// Environment variables
const NOTION_TOKEN = process.env.NOTION_TOKEN;
const SUPABASE_DB_URL = process.env.SUPABASE_DB_URL;
const SLACK_WEBHOOK = process.env.SLACK_WEBHOOK;
const SLACK_USER_ID = process.env.SLACK_USER_ID;

const NOTION_SALES_DB_ID = process.env.NOTION_SALES_DB_ID;
const NOTION_BUNDLES_DB_ID = process.env.NOTION_BUNDLES_DB_ID;
const NOTION_TREASURY_DB_ID = process.env.NOTION_TREASURY_DB_ID;
const NOTION_EVIDENCE_DB_ID = process.env.NOTION_EVIDENCE_DB_ID;

const notionHeaders = {
  Authorization: `Bearer ${NOTION_TOKEN}`,
  'Notion-Version': '2025-09-03',
  'Content-Type': 'application/json',
};

const healthReport = {
  time: new Date().toISOString(),
  notion: {},
  supabase: null,
  slack: null,
  overall: 'PENDING',
};

// Helper: Test Notion Database
async function testNotionDB(id, label) {
  if (!id) {
    healthReport.notion[label] = '❌ Missing ID';
    return;
  }

  try {
    const res = await fetch(`https://api.notion.com/v1/databases/${id}`, {
      headers: notionHeaders,
    });
    if (res.ok) {
      healthReport.notion[label] = '✅ Connected';
    } else {
      const data = await res.json();
      healthReport.notion[label] = `❌ ${data.message}`;
    }
  } catch (err) {
    healthReport.notion[label] = `❌ ${err.message}`;
  }
}

// Helper: Test Supabase connection
async function testSupabase() {
  try {
    const pg = new PgClient({ connectionString: SUPABASE_DB_URL });
    await pg.connect();
    const res = await pg.query('SELECT NOW();');
    await pg.end();
    healthReport.supabase = res.rows?.[0]?.now ? '✅ Connected' : '⚠️ No response';
  } catch (err) {
    healthReport.supabase = `❌ ${err.message}`;
  }
}

// Helper: Send Slack notification
async function sendSlackReport() {
  const mention = SLACK_USER_ID ? `<@${SLACK_USER_ID}>` : '@channel';
  const failed =
    Object.values(healthReport.notion).some(v => v.startsWith('❌')) ||
    healthReport.supabase?.startsWith('❌');

  healthReport.overall = failed ? '❌ FAILED' : '✅ HEALTHY';

  const text = `
🧠 *Base44 Weekly System Health Check*
🕒 ${new Date().toLocaleString('en-PH', { timeZone: 'Asia/Manila' })}
──────────────────────────────
📦 *Supabase:* ${healthReport.supabase}
🧾 *Notion Databases:*
  • Sales → ${healthReport.notion.Sales}
  • Bundles → ${healthReport.notion.Bundles}
  • Treasury → ${healthReport.notion.Treasury}
  • Evidence → ${healthReport.notion.Evidence}
──────────────────────────────
📊 *Overall:* ${healthReport.overall}
${failed ? `${mention} — please check immediately.` : '✅ All systems nominal.'}
  `;

  if (!SLACK_WEBHOOK) {
    console.warn('⚠️ Slack webhook missing — skipping notification.');
    healthReport.slack = '⚠️ Missing webhook';
    return;
  }

  try {
    await fetch(SLACK_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });
    healthReport.slack = '✅ Sent';
  } catch (err) {
    healthReport.slack = `❌ ${err.message}`;
  }
}

// Main execution
(async () => {
  console.log('🔍 Running Weekly System Health Check...');
  await testSupabase();

  await testNotionDB(NOTION_SALES_DB_ID, 'Sales');
  await testNotionDB(NOTION_BUNDLES_DB_ID, 'Bundles');
  await testNotionDB(NOTION_TREASURY_DB_ID, 'Treasury');
  await testNotionDB(NOTION_EVIDENCE_DB_ID, 'Evidence');

  await sendSlackReport();

  console.table(healthReport);
  console.log('\n🎯 Health check completed.\n');
})();
