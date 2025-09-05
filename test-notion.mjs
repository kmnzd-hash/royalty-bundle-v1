import 'dotenv/config';
import { Client } from '@notionhq/client';

const notion = new Client({ auth: process.env.NOTION_TOKEN });

async function test() {
  try {
    const response = await notion.search({ filter: { property: 'object', value: 'database' } });
    console.log(response.results.map(db => db.title[0]?.plain_text));
  } catch (err) {
    console.error(err);
  }
}

test();


