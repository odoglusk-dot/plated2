// Scheduled function (see netlify.toml's `schedule` on this function) — not
// callable meaningfully from the browser, there's nothing here a client
// needs. Runs once/day: finds users who haven't opted out and haven't
// logged any food yet today, and emails them a one-line nudge via Resend's
// REST API (no SDK, matching the rest of this codebase).
//
// Known simplification: this runs at one fixed UTC time (see netlify.toml)
// rather than per-user local "evening", since there's no per-user timezone
// stored anywhere in the app. Good enough for "something simple," not
// pretending to be more precise than it is.
const { captureError } = require('./_shared');

async function listAllUsers() {
  const users = [];
  let page = 1;
  const perPage = 200;
  for (;;) {
    const res = await fetch(
      `${process.env.SUPABASE_URL}/auth/v1/admin/users?page=${page}&per_page=${perPage}`,
      {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    if (!res.ok) throw new Error('Could not list users: ' + (await res.text()));
    const data = await res.json();
    const batch = data.users || [];
    users.push(...batch);
    if (batch.length < perPage) break;
    page++;
  }
  return users;
}

exports.handler = async () => {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY || !process.env.RESEND_API_KEY) {
    // Not configured yet — a no-op, not an error worth alerting on.
    return { statusCode: 200, body: 'Reminder emails not configured; skipping.' };
  }

  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const [users, profilesRes] = await Promise.all([
      listAllUsers(),
      fetch(`${process.env.SUPABASE_URL}/rest/v1/profiles?email_reminders_opt_out=eq.false&select=id`, { headers: serviceHeaders }),
    ]);
    const optedInProfiles = profilesRes.ok ? await profilesRes.json() : [];
    const optedInIds = new Set(optedInProfiles.map((p) => p.id));

    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const tomorrowStart = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    let sent = 0;
    for (const user of users) {
      if (!user.email || !optedInIds.has(user.id)) continue;

      const logsRes = await fetch(
        `${process.env.SUPABASE_URL}/rest/v1/food_logs?user_id=eq.${user.id}&logged_at=gte.${todayStart.toISOString()}&logged_at=lt.${tomorrowStart.toISOString()}&select=id&limit=1`,
        { headers: serviceHeaders }
      );
      const logs = logsRes.ok ? await logsRes.json() : [];
      if (logs.length > 0) continue; // already logged today — no reminder needed

      const emailRes = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          from: process.env.RESEND_FROM_EMAIL || 'Plated <reminders@example.com>',
          to: user.email,
          subject: "Haven't logged today yet?",
          text: "Just a friendly nudge — you haven't logged any food in Plated today. A quick log now keeps your streak alive.\n\nTurn this off anytime: Plated -> Profile -> Email Reminders.",
        }),
      });
      if (emailRes.ok) sent++;
    }

    return { statusCode: 200, body: JSON.stringify({ checked: users.length, sent }) };
  } catch (err) {
    await captureError(err, { function: 'send-reminder-emails' });
    return { statusCode: 500, body: 'Error sending reminder emails.' };
  }
};
