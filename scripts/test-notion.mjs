import 'dotenv/config';
import { Client } from '@notionhq/client';

const notion = new Client({ auth: process.env.NOTION_TOKEN });

async function main() {
  const result = await notion.databases.query({
    database_id: process.env.NOTION_DASHBOARD_DATABASE_ID,
    page_size: 1
  });
  console.log('Query OK:', result.results.length, 'rows found');
}

main().catch(console.error);

