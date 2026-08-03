// POST — called by Stripe, not the app. Configure this URL as a webhook
// endpoint in the Stripe Dashboard, subscribed to at least:
//   customer.subscription.created, customer.subscription.updated,
//   customer.subscription.deleted
//
// Verifies the Stripe-Signature header itself (HMAC-SHA256 over the raw
// body, using Node's built-in crypto) rather than pulling in the `stripe`
// SDK, matching the rest of this codebase's zero-npm-dependency style.
// Writes to `subscriptions` using the service-role key — this is the ONLY
// place in the app allowed to write to that table (see reset-schema.sql):
// RLS gives every user select-own but no insert/update policy at all.
const crypto = require('crypto');
const { jsonResponse } = require('./_shared');

// 5 minutes, matching Stripe's own recommended replay-attack tolerance.
const SIGNATURE_TOLERANCE_SECONDS = 300;

function verifyStripeSignature(rawBody, sigHeader, secret) {
  if (!sigHeader) return false;
  const parts = {};
  for (const kv of sigHeader.split(',')) {
    const [key, value] = kv.split('=');
    parts[key] = value;
  }
  const { t: timestamp, v1: signature } = parts;
  if (!timestamp || !signature) return false;

  const expected = crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${rawBody}`, 'utf8')
    .digest('hex');

  const expectedBuf = Buffer.from(expected, 'utf8');
  const signatureBuf = Buffer.from(signature, 'utf8');
  if (expectedBuf.length !== signatureBuf.length) return false;
  if (!crypto.timingSafeEqual(expectedBuf, signatureBuf)) return false;

  const ageSeconds = Math.abs(Date.now() / 1000 - Number(timestamp));
  return ageSeconds <= SIGNATURE_TOLERANCE_SECONDS;
}

const SUBSCRIPTION_EVENTS = new Set([
  'customer.subscription.created',
  'customer.subscription.updated',
  'customer.subscription.deleted',
]);

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.STRIPE_WEBHOOK_SECRET || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for Stripe webhooks.' });
  }

  const rawBody = event.isBase64Encoded
    ? Buffer.from(event.body || '', 'base64').toString('utf8')
    : event.body || '';
  const sigHeader = event.headers['stripe-signature'] || event.headers['Stripe-Signature'];

  if (!verifyStripeSignature(rawBody, sigHeader, process.env.STRIPE_WEBHOOK_SECRET)) {
    return jsonResponse(400, { error: 'Invalid signature.' });
  }

  let stripeEvent;
  try {
    stripeEvent = JSON.parse(rawBody);
  } catch {
    return jsonResponse(400, { error: 'Invalid payload.' });
  }

  if (!SUBSCRIPTION_EVENTS.has(stripeEvent.type)) {
    // We don't care about this event type — ack it so Stripe stops retrying.
    return jsonResponse(200, { received: true });
  }

  const subscription = stripeEvent.data?.object || {};
  const userId = subscription.metadata?.supabase_user_id;
  if (!userId) {
    // Set at checkout time (subscription_data.metadata) — should always be
    // present for subscriptions this app created. Nothing we can do without
    // it, but ack anyway so Stripe doesn't retry forever.
    return jsonResponse(200, { received: true, skipped: 'no supabase_user_id metadata' });
  }

  const status = stripeEvent.type === 'customer.subscription.deleted' ? 'canceled' : subscription.status;
  const currentPeriodEnd = subscription.current_period_end
    ? new Date(subscription.current_period_end * 1000).toISOString()
    : null;

  const upsertRes = await fetch(`${process.env.SUPABASE_URL}/rest/v1/subscriptions`, {
    method: 'POST',
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      'content-type': 'application/json',
      Prefer: 'resolution=merge-duplicates',
    },
    body: JSON.stringify({
      user_id: userId,
      status,
      stripe_customer_id: subscription.customer,
      stripe_subscription_id: subscription.id,
      current_period_end: currentPeriodEnd,
      updated_at: new Date().toISOString(),
    }),
  });

  if (!upsertRes.ok) {
    const detail = await upsertRes.text();
    // Non-2xx tells Stripe to retry this delivery later.
    return jsonResponse(500, { error: 'Could not record subscription update.', detail });
  }

  return jsonResponse(200, { received: true });
};
