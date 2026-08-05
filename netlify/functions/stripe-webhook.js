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
const { jsonResponse, captureError, withErrorReporting, callStripe } = require('./_shared');

// Shared, idempotently-created 100%-off-once coupon used for every referral
// reward — one Stripe object reused by everyone rather than minting a new
// coupon per referral.
const REFERRAL_COUPON_ID = 'referral-1-month-free';

async function ensureReferralCoupon() {
  try {
    await callStripe(`coupons/${REFERRAL_COUPON_ID}`, { method: 'GET' });
    return;
  } catch (err) {
    if (err.stripeStatus !== 404) throw err;
  }
  await callStripe('coupons', {
    params: { id: REFERRAL_COUPON_ID, percent_off: '100', duration: 'once', name: 'Referral reward — 1 month free' },
  });
}

// Only the referrer is rewarded (never the referred user), and only once
// the referred user's trial actually converts to a real paid invoice —
// detected here as a trialing->active transition via Stripe's
// previous_attributes, which piggybacks on the customer.subscription.updated
// event this webhook already handles (no new Stripe event subscription
// needed). This ties the payout to actual revenue: a referred account that
// never converts costs nothing.
async function rewardReferrerIfConverted(stripeEvent, subscription, referredUserId) {
  if (stripeEvent.type !== 'customer.subscription.updated') return;
  if (stripeEvent.data?.previous_attributes?.status !== 'trialing' || subscription.status !== 'active') return;

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const referralRes = await fetch(
      `${base}/rest/v1/referrals?referred_user_id=eq.${referredUserId}&status=eq.pending&select=id,referrer_user_id`,
      { headers: serviceHeaders }
    );
    if (!referralRes.ok) return;
    const referral = (await referralRes.json())[0];
    if (!referral) return; // this user wasn't referred, or was already rewarded

    const referrerSubRes = await fetch(
      `${base}/rest/v1/subscriptions?user_id=eq.${referral.referrer_user_id}&select=stripe_subscription_id`,
      { headers: serviceHeaders }
    );
    if (!referrerSubRes.ok) return;
    const referrerSub = (await referrerSubRes.json())[0];
    // Referrer has no live Stripe subscription to discount (e.g. never
    // subscribed themselves, or already canceled) — nothing to apply.
    // Leaves the referral row 'pending' so it stays visible for a manual
    // look rather than silently disappearing.
    if (!referrerSub?.stripe_subscription_id) return;

    await ensureReferralCoupon();
    await callStripe(`subscriptions/${referrerSub.stripe_subscription_id}`, {
      params: { coupon: REFERRAL_COUPON_ID },
    });

    await fetch(`${base}/rest/v1/referrals?id=eq.${referral.id}`, {
      method: 'PATCH',
      headers: serviceHeaders,
      body: JSON.stringify({ status: 'rewarded', rewarded_at: new Date().toISOString() }),
    });
  } catch (err) {
    // Bonus logic — must never affect the primary subscription upsert's response.
    await captureError(err, { function: 'stripe-webhook:referral-reward', referredUserId });
  }
}

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

exports.handler = withErrorReporting(async (event) => {
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

  // Canceling via the Customer Portal doesn't move status off 'active'
  // right away — Stripe sets cancel_at_period_end=true and keeps
  // status='active' until the paid period actually ends, only then firing
  // .deleted (status='canceled'). So the existing status-only access check
  // in index.html's hasAccess() already grants access through the paid
  // period correctly, with no special-casing needed here. This column is
  // stored purely so the app can *display* "canceling, access until
  // <date>" instead of a plain "active".
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
      cancel_at_period_end: Boolean(subscription.cancel_at_period_end),
      updated_at: new Date().toISOString(),
    }),
  });

  if (!upsertRes.ok) {
    const detail = await upsertRes.text();
    await captureError(new Error('Could not upsert subscription: ' + detail), { function: 'stripe-webhook', userId, eventType: stripeEvent.type });
    // Non-2xx tells Stripe to retry this delivery later.
    return jsonResponse(500, { error: 'Could not record subscription update.', detail });
  }

  await rewardReferrerIfConverted(stripeEvent, subscription, userId);

  return jsonResponse(200, { received: true });
}, 'stripe-webhook');
