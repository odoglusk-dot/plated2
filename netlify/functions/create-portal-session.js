// POST {}  (no body needed — the caller's own account opens the portal)
// Auth: Authorization: Bearer <supabase access token>
// Returns { url } — a Stripe-hosted Billing Portal URL to redirect to.
//
// The portal itself is entirely Stripe's UI: billing history, payment
// method updates, and cancellation all happen there, nothing built here.
// Requires a saved Customer Portal configuration in the Stripe Dashboard
// (Settings -> Billing -> Customer portal) — test mode auto-provisions a
// default one, live mode does not. See "Customer Portal Setup" in
// DEPLOYMENT.md, including the "cancel immediately vs. at period end"
// toggle, which lives entirely in that dashboard setting, not in this
// function or in any API parameter it sends.
const { jsonResponse, verifyUser, captureError, callStripe, getAppBaseUrl } = require('./_shared');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.STRIPE_SECRET_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for billing management.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  const baseUrl = getAppBaseUrl(event);
  if (!baseUrl) return jsonResponse(400, { error: 'Missing request origin.' });

  try {
    const subRes = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${auth.user.id}&select=stripe_customer_id`,
      {
        headers: {
          apikey: process.env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${auth.token}`,
        },
      }
    );
    if (!subRes.ok) return jsonResponse(502, { error: 'Could not look up your billing account.' });
    const rows = await subRes.json();
    const customerId = rows[0]?.stripe_customer_id;
    if (!customerId) {
      return jsonResponse(400, { error: "You don't have a billing account yet — start a subscription first." });
    }

    const session = await callStripe('billing_portal/sessions', {
      params: {
        customer: customerId,
        return_url: `${baseUrl}/`,
      },
    });

    return jsonResponse(200, { url: session.url });
  } catch (err) {
    await captureError(err, { function: 'create-portal-session', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not open billing portal.', detail: String(err.message || err) });
  }
};
