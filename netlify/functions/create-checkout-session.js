// POST {}  (no body needed — the caller's own account starts the checkout)
// Auth: Authorization: Bearer <supabase access token>
// Returns { url } — a Stripe-hosted Checkout URL to redirect the browser to.
//
// Creates a $4.99/mo subscription Checkout Session with a TRIAL_PERIOD_DAYS
// (7-day) free trial — see _shared.js for the one config constant. Stripe
// still collects a card up front (payment_method_collection: 'always') so
// the trial converts automatically at the end without the user coming back.
// No local DB write happens here — stripe-webhook.js is the only writer to
// the `subscriptions` table, driven by Stripe's subscription lifecycle
// events, so this function can't drift out of sync with what Stripe thinks
// the subscription state actually is.
//
// One trial per person (7-day trial batch, item 2): two independent checks,
// either one is enough to skip the trial —
//   (a) this Supabase account already has a Stripe customer on file with
//       ANY subscription history (active, trialing, or canceled) — covers
//       the same account resubscribing after canceling.
//   (b) this email's hash is in `trial_used` — covers a deleted-and-
//       recreated account (new user_id, but the email, and so the hash,
//       is the same). trial_used is written by stripe-webhook.js the
//       first time a subscription for an email reaches 'trialing'.
const { jsonResponse, verifyUser, captureError, withErrorReporting, callStripe, getAppBaseUrl, TRIAL_PERIOD_DAYS, hashEmail } = require('./_shared');

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.STRIPE_SECRET_KEY || !process.env.STRIPE_PRICE_ID) {
    return jsonResponse(500, { error: 'Server is not configured for checkout.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let platform = 'web';
  try {
    const body = JSON.parse(event.body || '{}');
    if (body.platform === 'ios') platform = 'ios';
  } catch {
    // Missing/invalid body — default to 'web', same as every pre-existing caller.
  }

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

  // One trial per person — check (a): this account's own Stripe customer
  // (if it has one) has prior subscription history of any status, meaning
  // they're resubscribing after a cancellation, not starting fresh.
  let priorSubscription = false;
  if (existingCustomerId) {
    try {
      const priorRes = await callStripe(`subscriptions?customer=${existingCustomerId}&status=all&limit=1`, { method: 'GET' });
      priorSubscription = Array.isArray(priorRes.data) && priorRes.data.length > 0;
    } catch (err) {
      // Non-fatal — worst case a resubscribing user gets a trial they
      // technically shouldn't; check (b) below still catches the far more
      // common "deleted and recreated the account" case.
      await captureError(err, { function: 'create-checkout-session:prior-subscription-check', userId: auth.user.id });
    }
  }

  // One trial per person — check (b): this email has already used a trial,
  // even under a different (deleted) account.
  let trialAlreadyUsed = false;
  try {
    const trialUsedRes = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/trial_used?email_hash=eq.${hashEmail(auth.user.email)}&select=email_hash`,
      {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    if (trialUsedRes.ok) {
      const rows = await trialUsedRes.json();
      trialAlreadyUsed = rows.length > 0;
    }
  } catch (err) {
    await captureError(err, { function: 'create-checkout-session:trial-used-check', userId: auth.user.id });
  }

  const eligibleForTrial = !priorSubscription && !trialAlreadyUsed;

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
        // matters for writing to `subscriptions`. trial_period_days is
        // omitted entirely (not set to '0') when the one-trial-per-person
        // checks above say this person has already had one — Stripe just
        // starts the subscription active/unpaid immediately, same as any
        // subscription with no trial.
        ...(eligibleForTrial ? { 'subscription_data[trial_period_days]': String(TRIAL_PERIOD_DAYS) } : {}),
        'subscription_data[metadata][supabase_user_id]': auth.user.id,
        'subscription_data[metadata][platform]': platform,
        // So stripe-webhook.js can send the trial-ending reminder and
        // record trial_used without a second lookup back to Supabase Auth.
        'subscription_data[metadata][email]': auth.user.email,
        // Also set on the Checkout Session itself — stripe-webhook.js's
        // checkout.session.completed handler (App Store readiness batch,
        // item 7 — external_purchase_log) reads metadata from the SESSION,
        // not the subscription, since that's the event that actually
        // carries a session id + the exact amount charged.
        'metadata[supabase_user_id]': auth.user.id,
        'metadata[platform]': platform,
        success_url: `${baseUrl}/?checkout=success`,
        cancel_url: `${baseUrl}/?checkout=cancel`,
      },
    });

    return jsonResponse(200, { url: session.url });
  } catch (err) {
    await captureError(err, { function: 'create-checkout-session', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not start checkout.', detail: String(err.message || err) });
  }
}, 'create-checkout-session');
