// GET, header: Authorization: Bearer <ADMIN_DASHBOARD_PASSWORD>
// Returns { rows }
//
// 7-day trial batch, item 7: Krafft HQ had no per-user subscription view
// at all before this — only the existing admin-cancellation-stats.js and
// admin-unreported-purchases.js, neither of which shows trial status.
// Read-only list of every row currently in 'trialing', with its trial end
// date (current_period_end while trialing IS the trial end, per Stripe's
// own data model — see the comment on the subscriptions table in
// reset-schema.sql), soonest-ending first. Same password-gate pattern and
// same user_id-not-email minimalism as the other two admin endpoints —
// this app has no admin user-search/email-resolution tool at all, so
// adding one here would be new scope beyond what was asked.
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
      `${process.env.SUPABASE_URL}/rest/v1/subscriptions?status=eq.trialing&select=user_id,current_period_end,cancel_at_period_end,trial_reminder_sent_at&order=current_period_end.asc&limit=500`,
      {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    if (!res.ok) return jsonResponse(502, { error: 'Could not read subscriptions.' });
    const rows = await res.json();
    return jsonResponse(200, { rows });
  } catch (err) {
    await captureError(err, { function: 'admin-trials' });
    return jsonResponse(502, { error: 'Could not load trial status.', detail: String(err.message || err) });
  }
}, 'admin-trials');
