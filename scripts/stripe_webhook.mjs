// scripts/stripe_webhook.mjs
import 'dotenv/config';
import express from 'express';
import bodyParser from 'body-parser';
import Stripe from 'stripe';
import pkg from 'pg';
const { Client: PgClient } = pkg;

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const pg = new PgClient({ connectionString: process.env.SUPABASE_DB_URL });

const app = express();
// raw body needed for signature verification
app.use(bodyParser.raw({ type: 'application/json' }));

app.post('/stripe/webhook', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  await pg.connect();
  try {
    if (event.type === 'invoice.payment_succeeded' || event.type === 'invoice.finalized') {
      const invoice = event.data.object;
      // Map invoice to sales record fields (example)
      const gross = (invoice.amount_paid ?? invoice.amount_due ?? 0) / 100.0;
      const currency = (invoice.currency || 'AUD').toUpperCase();
      // Example vault_id / creator mapping - adapt to your metadata mapping
      const vault_id = invoice.metadata?.vault_id ?? 'VLT-UNKNOWN';
      const creator_id = invoice.metadata?.creator_id ?? null;
      const ip_holder = invoice.metadata?.ip_holder ?? null;

      const q = `INSERT INTO public.sales (offer_name, gross_amount, sale_currency, vault_id, creator_id, ip_holder, override_json, status)
                 VALUES ($1,$2,$3,$4,$5,$6,$7,'queued') RETURNING sale_id`;
      const override_json = invoice.metadata?.override_json ?? '{}';
      const vals = [invoice.description || 'Stripe Invoice', gross, currency, vault_id, creator_id, ip_holder, override_json];
      const r = await pg.query(q, vals);
      console.log('Inserted sale id', r.rows[0]?.sale_id);
    } else {
      console.log('Unhandled event type', event.type);
    }
    res.json({ received: true });
  } catch (err) {
    console.error('DB error', err);
    res.status(500).send('server error');
  } finally {
    await pg.end();
  }
});

const port = process.env.STRIPE_WEBHOOK_PORT || 8082;
app.listen(port, () => console.log(`Stripe webhook listening on ${port}`));
