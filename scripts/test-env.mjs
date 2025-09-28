import 'dotenv/config';

console.log("SUPABASE_URL:", process.env.SUPABASE_URL);
console.log("SUPABASE_SERVICE_ROLE_KEY exists:", !!process.env.SUPABASE_SERVICE_ROLE_KEY);
console.log("NOTION_TOKEN exists:", !!process.env.NOTION_TOKEN);

