import 'dotenv/config';
import fetch from 'node-fetch';

const NOTION_TOKEN = process.env.NOTION_TOKEN;
// ✅ Your verified Base44 Hub page ID
const HUB_PAGE_ID = "28ac1f60cd018054a2c9cab2f6521ac2";

async function searchNotion(query) {
  console.log(`🔍 Searching Notion for "${query}" within Base44 Hub (ID: ${HUB_PAGE_ID})...\n`);

  const res = await fetch("https://api.notion.com/v1/search", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${NOTION_TOKEN}`,
      "Notion-Version": "2025-09-03",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      query,
      // ✅ FIX: “data_source” replaces old “database”
      filter: { value: "data_source", property: "object" },
      sort: { direction: "ascending", timestamp: "last_edited_time" },
    }),
  });

  // 🧠 Step 1: Handle network or token errors
  if (!res.ok) {
    console.error(`❌ Request failed with status ${res.status}`);
    const err = await res.text();
    console.error(err);
    return;
  }

  const data = await res.json();

  if (!data.results || !Array.isArray(data.results)) {
    console.error("⚠️ No valid data sources found in Notion response:");
    console.log(JSON.stringify(data, null, 2));
    return;
  }

  // 🧩 Step 2: Filter only items inside the Base44 Hub
  const filtered = data.results.filter((d) => {
    const parentId = d.database_parent?.page_id || d.parent?.page_id;
    const title = d.title?.[0]?.plain_text || "(Untitled)";
    return parentId === HUB_PAGE_ID && title.toLowerCase().includes("ontology");
  });

  if (filtered.length === 0) {
    console.log("⚠️ No matching Ontology data sources found under Base44 Hub.");
    console.log("🔎 Check if your integration is connected to the Ontology Database or sub-pages.");
    return;
  }

  // 🧠 Step 3: Display results
  console.log("✅ Found Base44 Ontology Data Sources:\n");
  console.table(
    filtered.map((d) => ({
      title: d.title?.[0]?.plain_text,
      id: d.id,
      parent: d.database_parent?.page_id || d.parent?.page_id,
    }))
  );

  console.log("\n💡 Tip: Add these to your .env file as:");
  console.log("NOTION_EVIDENCE_DB_ID=...");
  console.log("NOTION_SALES_DB_ID=...");
  console.log("NOTION_ENTITY_DB_ID=...");
  console.log("NOTION_TREASURY_DB_ID=...");
}

await searchNotion("Ontology");
