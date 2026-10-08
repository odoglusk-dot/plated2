// GET, header: Authorization: Bearer <ADMIN_DASHBOARD_PASSWORD>
// Returns { rows }
//
// Read-only list of external_purchase_log rows not yet reported to Apple
// (App Store readiness batch, item 7) — Apple's external-purchase-link
// entitlement requires reporting these on a schedule. Same password-gate
// pattern as admin-cancellation-stats.js; this app has no other "mark as
// reported" flow, by design — the task asked for a read-only list, not a
// write path, so reported_at/reported_to_apple are only ever set by hand
// (directly in Supabase) once you've actually filed the report with Apple.
const { jsonResponse, captureError, withErrorReporting } = require('./_shared');

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'GET') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.ADMIN_DASHBOARD_PASSWORD) {
    return jsonResponse(500, { error: 'Admin dashboard is not configured.' });
  }
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for admin reads.' });
  }

  const authHeader = event.headers.authorization || event.headers.Authorization || '';
  const password = authHeader.replace(/^Bearer\s+/i, '');
  if (!password || password !== process.env.ADMIN_DASHBOARD_PASSWORD) {
    return jsonResponse(401, { error: 'Incorrect password.' });
  }

  try {
    const res = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/external_purchase_log?reported_to_apple=eq.false&select=id,user_id,stripe_session_id,stripe_subscription_id,amount_cents,currency,platform,created_at&order=created_at.asc&limit=1000`,
      {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    if (!res.ok) return jsonResponse(502, { error: 'Could not read external purchase log.' });
    const rows = await res.json();
    return jsonResponse(200, { rows });
  } catch (err) {
    await captureError(err, { function: 'admin-unreported-purchases' });
    return jsonResponse(502, { error: 'Could not load unreported purchases.', detail: String(err.message || err) });
  }
}, 'admin-unreported-purchases');
