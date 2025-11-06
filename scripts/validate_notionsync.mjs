import { Client } from "@notionhq/client";
import { execSync } from "child_process";
import dotenv from "dotenv";
dotenv.config();

const notion = new Client({ auth: process.env.NOTION_TOKEN });
const SUPABASE_DB_URL = process.env.SUPABASE_DB_URL;

// List of Notion DB names to verify
const notionDBs = [
  "Entities",
  "Offers",
  "Bundles",
  "Transactions",
  "Payouts_v2",
  "Overrides",
  "Royalty Ledger",
  "Royalty Pools",
  "Reuse Event Log",
  "Payout Audit Log"
];

async function validateNotionDatabases() {
  console.log("🔍 Checking Notion Databases...\n");

  for (const name of notionDBs) {
    try {
      const search = await notion.search({ query: name, filter: { property: "object", value: "database" } });
      if (search.results.length > 0) {
        const db = search.results[0];
        console.log(`✅ Found: ${name} | ID: ${db.id}`);
      } else {
        console.warn(`⚠️ Not Found in Notion: ${name}`);
      }
    } catch (err) {
      console.error(`❌ Error checking ${name}:`, err.message);
    }
  }

  console.log("\n📊 Checking Supabase Tables...\n");
  try {
    const result = execSync(`psql "${SUPABASE_DB_URL}" -c "\\dt"`, { encoding: "utf8" });
    console.log(result);
  } catch (err) {
    console.error("❌ Error checking Supabase:", err.message);
  }
}

validateNotionDatabases();

