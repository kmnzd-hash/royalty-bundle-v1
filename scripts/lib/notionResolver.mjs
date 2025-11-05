// scripts/lib/notionResolver.mjs
import fetch from "node-fetch";
import "dotenv/config";

const notionVersion = "2025-09-03";
const token = process.env.NOTION_TOKEN;

async function fetchJson(url, headers) {
  const res = await fetch(url, { headers });
  if (!res.ok) return { ok: false, status: res.status, body: await res.text().catch(()=>'') };
  const json = await res.json();
  return { ok: true, json };
}

export async function resolveWritableDatabase(id) {
  const headers = {
    Authorization: `Bearer ${token}`,
    "Notion-Version": notionVersion,
    "Content-Type": "application/json",
  };

  // Try data_source first
  const ds = await fetchJson(`https://api.notion.com/v1/data_sources/${id}`, headers);
  if (ds.ok && ds.json?.id) {
    return { id: ds.json.id, type: "data_source", name: ds.json.title?.[0]?.plain_text ?? "Unknown" };
  }

  // Fallback to database
  const db = await fetchJson(`https://api.notion.com/v1/databases/${id}`, headers);
  if (db.ok && db.json?.id) {
    return { id: db.json.id, type: "database", name: db.json.title?.[0]?.plain_text ?? "Unknown" };
  }

  // If neither worked, return a consistent error object
  const err = {
    message: `Could not resolve writable Notion DB for ID ${id}`,
    reasons: {
      data_source: ds.ok ? 'ok' : `failed (${ds.status}) ${ds.body?.slice?.(0,200)}`,
      database: db.ok ? 'ok' : `failed (${db.status}) ${db.body?.slice?.(0,200)}`
    }
  };
  throw new Error(JSON.stringify(err));
}
