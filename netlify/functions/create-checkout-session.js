// POST {}  (no body needed — the caller's own account starts the checkout)
// Auth: Authorization: Bearer <supabase access token>
// Returns { url } — a Stripe-hosted Checkout URL to redirect the browser to.
//
// Creates a $4.99/mo subscription Checkout Session with a 3-day free trial.
// Stripe still collects a card up front (payment_method_collection: 'always')
// so the trial converts automatically at day 3 without the user coming back.
// No local DB write happens here — stripe-webhook.js is the only writer to
// the `subscriptions` table, driven by Stripe's subscription lifecycle
// events, so this function can't drift out of sync with what Stripe thinks
// the subscription state actually is.
const { jsonResponse, verifyUser } = require('./_shared');

async function callStripe(path, params) {
  const body = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null) body.append(key, value);
  }
  const res = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.STRIPE_SECRET_KEY}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error?.message || `Stripe API error (${res.status})`);
  }
  return data;
}

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.STRIPE_SECRET_KEY || !process.env.STRIPE_PRICE_ID) {
    return jsonResponse(500, { error: 'Server is not configured for checkout.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  // Origin is set by the browser on same-origin fetch() calls and can't be
  // spoofed by page JS, so it's safe to build the post-checkout redirect
  // URLs from it without hardcoding a deployment domain.
  const origin = (event.headers.origin || event.headers.referer || '').replace(/\/$/, '');
  if (!origin) return jsonResponse(400, { error: 'Missing request origin.' });

  // Reuse the existing Stripe customer (if any) instead of creating a
  // duplicate every time someone revisits the paywall, and block starting a
  // second checkout while one is already active.
  let existingCustomerId;
  try {
    const subRes = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${auth.user.id}&select=status,stripe_customer_id`,
      {
        headers: {
          apikey: process.env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${auth.token}`,
        },
      }
    );
    if (subRes.ok) {
      const rows = await subRes.json();
      const existing = rows[0];
      if (existing && (existing.status === 'active' || existing.status === 'trialing')) {
        return jsonResponse(400, { error: 'You already have an active subscription.' });
      }
      existingCustomerId = existing?.stripe_customer_id || undefined;
    }
  } catch {
    // Non-fatal — worst case Stripe creates a fresh customer below.
  }

  try {
    const session = await callStripe('checkout/sessions', {
      mode: 'subscription',
      ...(existingCustomerId ? { customer: existingCustomerId } : { customer_email: auth.user.email }),
      client_reference_id: auth.user.id,
      'line_items[0][price]': process.env.STRIPE_PRICE_ID,
      'line_items[0][quantity]': '1',
      payment_method_collection: 'always',
      'subscription_data[trial_period_days]': '3',
      'subscription_data[metadata][supabase_user_id]': auth.user.id,
      success_url: `${origin}/?checkout=success`,
      cancel_url: `${origin}/?checkout=cancel`,
    });

    return jsonResponse(200, { url: session.url });
  } catch (err) {
    return jsonResponse(502, { error: 'Could not start checkout.', detail: String(err.message || err) });
  }
};
