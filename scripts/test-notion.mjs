import 'dotenv/config';
import { Client } from '@notionhq/client';

const notion = new Client({ auth: process.env.NOTION_TOKEN });
const dbId = process.env.NOTION_DB_BUNDLES;  // test bundles DB first

async function test() {
  try {
    const resp = await notion.databases.query({
      database_id: dbId,
      page_size: 3,
    });
    console.log("✅ Notion DB query success");
    console.log(JSON.stringify(resp.results, null, 2));
  } catch (err) {
    console.error("❌ Notion error:", err.message);
  }
}

test();
