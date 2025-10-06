import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function test() {
  const { data, error } = await supabase.from('bundles').select('*');
  if (error) {
    console.error('Supabase error:', error);
  } else {
    console.log('Bundles data:', data);
  }
}

test();
