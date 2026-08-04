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
const { jsonResponse, verifyUser, captureError, callStripe, getAppBaseUrl } = require('./_shared');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.STRIPE_SECRET_KEY || !process.env.STRIPE_PRICE_ID) {
    return jsonResponse(500, { error: 'Server is not configured for checkout.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  // Derived from the browser's own Origin/Referer headers, which page JS
  // can't spoof, so it's safe to build the post-checkout redirect URLs from
  // this without hardcoding a deployment domain (or assuming the app is
  // served from a site's root — see getAppBaseUrl()).
  const baseUrl = getAppBaseUrl(event);
  if (!baseUrl) return jsonResponse(400, { error: 'Missing request origin.' });

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
      params: {
        mode: 'subscription',
        ...(existingCustomerId ? { customer: existingCustomerId } : { customer_email: auth.user.email }),
        client_reference_id: auth.user.id,
        'line_items[0][price]': process.env.STRIPE_PRICE_ID,
        'line_items[0][quantity]': '1',
        payment_method_collection: 'always',
        // stripe-webhook.js reads metadata off the SUBSCRIPTION object (via
        // customer.subscription.* events), so this is the one that actually
        // matters for writing to `subscriptions`.
        'subscription_data[trial_period_days]': '3',
        'subscription_data[metadata][supabase_user_id]': auth.user.id,
        // Also set on the Checkout Session itself — checkout.session.completed
        // isn't currently handled by stripe-webhook.js, but if that ever
        // changes, or you inspect this event directly while debugging, the
        // metadata will actually be there instead of empty.
        'metadata[supabase_user_id]': auth.user.id,
        success_url: `${baseUrl}/?checkout=success`,
        cancel_url: `${baseUrl}/?checkout=cancel`,
      },
    });

    return jsonResponse(200, { url: session.url });
  } catch (err) {
    await captureError(err, { function: 'create-checkout-session', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not start checkout.', detail: String(err.message || err) });
  }
};
