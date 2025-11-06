/**
 * check_notion_access.mjs
 * 
 * ✅ Verifies access for both old-style Notion databases and new-style data_sources
 * Works with modern Notion API (2025+) and prints a clean table summary.
 */

import fetch from "node-fetch";
import "dotenv/config";
import chalk from "chalk";
import Table from "cli-table3";

const notionVersion = "2025-09-03";
const token = process.env.NOTION_TOKEN;

// --- Database IDs from .env
const databases = [
  { name: "Evidence Ontology", id: process.env.NOTION_EVIDENCE_DB_ID },
  { name: "Entity Ontology", id: process.env.NOTION_ENTITY_DB_ID },
  { name: "Treasury Ontology", id: process.env.NOTION_TREASURY_DB_ID },
  { name: "Bundle Ontology", id: process.env.NOTION_BUNDLE_DB_ID },
  { name: "System Ontology", id: process.env.NOTION_SYSTEM_DB_ID },
  { name: "Rails Ontology", id: process.env.NOTION_RAILS_DB_ID },
  { name: "Sales Mirror", id: process.env.NOTION_SALES_DB_ID },
];

if (!token) {
  console.error(chalk.red("❌ Missing NOTION_TOKEN in .env"));
  process.exit(1);
}

console.log(chalk.cyan("\n🔍 Checking Notion Database Access...\n"));

// --- Helper function to fetch either data_source or database
async function checkDatabaseAccess(id) {
  const options = {
    headers: {
      Authorization: `Bearer ${token}`,
      "Notion-Version": notionVersion,
      "Content-Type": "application/json",
    },
  };

  try {
    // Try new API endpoint first
    const dataSourceRes = await fetch(`https://api.notion.com/v1/data_sources/${id}`, options);

    if (dataSourceRes.ok) {
      const json = await dataSourceRes.json();
      const propertyCount = Object.keys(json.properties || {}).length;
      return { status: "ok", type: "data_source", properties: propertyCount };
    }

    // Fallback to old /databases endpoint
    const dbRes = await fetch(`https://api.notion.com/v1/databases/${id}`, options);

    if (dbRes.ok) {
      const json = await dbRes.json();
      const propertyCount = Object.keys(json.properties || {}).length;
      return { status: "ok", type: "database", properties: propertyCount };
    }

    const err = await dataSourceRes.json().catch(() => ({}));
    return { status: "error", message: err.message || "Unknown error" };

  } catch (e) {
    return { status: "error", message: e.message };
  }
}

// --- Main Execution
(async () => {
  const table = new Table({
    head: ["Name", "ID", "Status"],
    colWidths: [25, 40, 60],
  });

  for (const db of databases) {
    if (!db.id) {
      table.push([db.name, chalk.gray("No ID in .env"), chalk.yellow("⚠️ Missing ID")]);
      continue;
    }

    const result = await checkDatabaseAccess(db.id);

    if (result.status === "ok") {
      table.push([
        chalk.white(db.name),
        chalk.gray(db.id),
        chalk.green(`✅ Accessible (${result.properties} properties, ${result.type})`),
      ]);
    } else {
      table.push([
        chalk.white(db.name),
        chalk.gray(db.id),
        chalk.red(`⚠️ ${result.message || "Not shared or inaccessible"}`),
      ]);
    }
  }

  console.log(table.toString());
  console.log(
    chalk.cyan(
      "\n📋 Tip: If any show ⚠️, open the database in Notion → Connections → Add 'Base44 Supabase Sync' → Can Edit.\n"
    )
  );
})();
