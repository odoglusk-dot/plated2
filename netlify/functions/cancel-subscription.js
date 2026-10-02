// POST { action: 'cancel' | 'pause' | 'stay', reason?: string }
// Auth: Authorization: Bearer <supabase access token>
// Returns { ok: true }
//
// Items 9+10 of the conversion-surface-area batch: replaces sending every
// free-tier cancellation straight to Stripe's hosted Billing Portal (see
// create-portal-session.js, which still handles payment-method updates and
// billing history) with a custom in-app flow that can show a win-back offer
// and record why people actually leave — see cancellation_flow_events in
// supabase-schema-phase35-cancellation-flow.sql, read by the admin page.
//
// 'stay' logs the outcome only — the user backed out, nothing to tell Stripe.
// 'cancel' sets cancel_at_period_end so access continues through the paid
// period already bought, same behavior the portal always had.
// 'pause' uses Stripe's native pause_collection rather than any custom
// pause state machine (confirmed available on the Subscriptions API).
//
// Either Stripe call fires a customer.subscription.updated webhook event,
// which stripe-webhook.js already handles — this function never writes to
// the subscriptions table directly.
const { jsonResponse, verifyUser, captureError, withErrorReporting, callStripe } = require('./_shared');

const VALID_ACTIONS = new Set(['cancel', 'pause', 'stay']);

// A fixed, single-tap reason set rather than free text, so the admin page
// can show a simple breakdown instead of parsing prose. Must match
// CANCELLATION_REASONS in index.html.
const VALID_REASONS = new Set(['too_expensive', 'not_using_enough', 'missing_features', 'found_alternative', 'other']);

// Pausing suspends billing for a fixed window rather than cutting off
// access — pause_collection never moves `status` off 'active', so access
// continues through the pause (a deliberate "take a break, keep your
// streak" framing, not a second free cancellation). 30 days is a judgment
// call made without the user in the loop on this exact number — flagged
// for review, a one-line change if a different window is wanted.
const PAUSE_DAYS = 30;

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }
  if (!process.env.STRIPE_SECRET_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for billing management.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const { action, reason } = payload;
  if (!VALID_ACTIONS.has(action)) return jsonResponse(400, { error: 'Invalid action.' });
  if (reason != null && !VALID_REASONS.has(reason)) return jsonResponse(400, { error: 'Invalid reason.' });

  try {
    if (action !== 'stay') {
      const subRes = await fetch(
        `${process.env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${auth.user.id}&select=stripe_subscription_id`,
        { headers: { apikey: process.env.SUPABASE_ANON_KEY, Authorization: `Bearer ${auth.token}` } }
      );
      if (!subRes.ok) return jsonResponse(502, { error: 'Could not look up your subscription.' });
      const rows = await subRes.json();
      const subscriptionId = rows[0]?.stripe_subscription_id;
      if (!subscriptionId) return jsonResponse(400, { error: "You don't have an active subscription to cancel." });

      if (action === 'cancel') {
        await callStripe(`subscriptions/${subscriptionId}`, { params: { cancel_at_period_end: 'true' } });
      } else {
        const resumesAt = Math.floor(Date.now() / 1000) + PAUSE_DAYS * 86400;
        await callStripe(`subscriptions/${subscriptionId}`, {
          params: {
            'pause_collection[behavior]': 'mark_uncollectible',
            'pause_collection[resumes_at]': String(resumesAt),
          },
        });
      }
    }

    // Best-effort — a logging failure shouldn't undo (or fail to report
    // success for) a Stripe action that already went through.
    await fetch(`${process.env.SUPABASE_URL}/rest/v1/cancellation_flow_events`, {
      method: 'POST',
      headers: {
        apikey: process.env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${auth.token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        user_id: auth.user.id,
        reason: reason || null,
        outcome: action === 'cancel' ? 'canceled' : action === 'pause' ? 'paused' : 'stayed',
      }),
    });

    return jsonResponse(200, { ok: true });
  } catch (err) {
    await captureError(err, { function: 'cancel-subscription', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not update your subscription.', detail: String(err.message || err) });
  }
}, 'cancel-subscription');
