// GET, header: Authorization: Bearer <ADMIN_DASHBOARD_PASSWORD>
// Returns { outcomeCounts, reasonCounts, recent }
//
// Item 9 of the conversion-surface-area batch: a minimal, password-gated
// admin endpoint reading cancellation_flow_events (see
// supabase-schema-phase35-cancellation-flow.sql) — the only thing that
// exists in this app resembling an "HQ dashboard." Gated on a single shared
// password (ADMIN_DASHBOARD_PASSWORD env var), not a real account system —
// deliberately minimal, per the task. Uses the service-role key since this
// reads across every user, not just the caller's own row.
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
      `${process.env.SUPABASE_URL}/rest/v1/cancellation_flow_events?select=reason,outcome,created_at&order=created_at.desc&limit=500`,
      {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    if (!res.ok) return jsonResponse(502, { error: 'Could not read cancellation events.' });
    const rows = await res.json();

    const outcomeCounts = { canceled: 0, paused: 0, stayed: 0 };
    const reasonCounts = {};
    for (const row of rows) {
      if (row.outcome in outcomeCounts) outcomeCounts[row.outcome] += 1;
      const reasonKey = row.reason || 'no_reason_given';
      reasonCounts[reasonKey] = (reasonCounts[reasonKey] || 0) + 1;
    }

    return jsonResponse(200, {
      total: rows.length,
      outcomeCounts,
      reasonCounts,
      recent: rows.slice(0, 50),
    });
  } catch (err) {
    await captureError(err, { function: 'admin-cancellation-stats' });
    return jsonResponse(502, { error: 'Could not load cancellation stats.', detail: String(err.message || err) });
  }
}, 'admin-cancellation-stats');
