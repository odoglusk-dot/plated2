// POST { token, date, bodyweight_lb?, sleep_hours?, steps? }
// No Supabase session — this is the public endpoint an iOS Shortcut posts
// to directly, authenticated by a per-user token (see health-sync-token.js,
// which issues/revokes it) rather than a login session, since a Shortcut
// has no way to hold one. The Shortcut never sees a Supabase credential of
// any kind; this function alone holds the service-role key and uses it to
// resolve the token to a user and write only that user's rows.
//
// Every requirement this was approved under lives directly in this file:
// strict field allowlist (unknown keys reject with 400), basic per-token
// rate limiting, and idempotent per-(user, date, metric) writes so a
// Shortcut that runs twice in a day doesn't create duplicates.
const crypto = require('crypto');
const { jsonResponse, captureError, withErrorReporting } = require('./_shared');

const ALLOWED_KEYS = new Set(['token', 'date', 'bodyweight_lb', 'sleep_hours', 'steps']);
const MIN_SECONDS_BETWEEN_REQUESTS = 60;

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function isValidDateStr(s) {
  return typeof s === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(s) && !Number.isNaN(new Date(`${s}T00:00:00Z`).getTime());
}

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Health sync is not configured.' });
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const unknownKeys = Object.keys(payload).filter((k) => !ALLOWED_KEYS.has(k));
  if (unknownKeys.length) {
    return jsonResponse(400, { error: `Unrecognized field(s): ${unknownKeys.join(', ')}` });
  }
  if (!payload.token || typeof payload.token !== 'string') {
    return jsonResponse(400, { error: 'Missing "token".' });
  }
  if (!isValidDateStr(payload.date)) {
    return jsonResponse(400, { error: '"date" must be an ISO date string (YYYY-MM-DD).' });
  }

  const hasBodyweight = payload.bodyweight_lb !== undefined;
  const hasSleep = payload.sleep_hours !== undefined;
  const hasSteps = payload.steps !== undefined;
  if (!hasBodyweight && !hasSleep && !hasSteps) {
    return jsonResponse(400, { error: 'Provide at least one of bodyweight_lb, sleep_hours, steps.' });
  }
  if (hasBodyweight && (typeof payload.bodyweight_lb !== 'number' || payload.bodyweight_lb < 30 || payload.bodyweight_lb > 800)) {
    return jsonResponse(400, { error: 'bodyweight_lb must be a number between 30 and 800.' });
  }
  if (hasSleep && (typeof payload.sleep_hours !== 'number' || payload.sleep_hours < 0 || payload.sleep_hours > 24)) {
    return jsonResponse(400, { error: 'sleep_hours must be a number between 0 and 24.' });
  }
  if (hasSteps && (!Number.isInteger(payload.steps) || payload.steps < 0 || payload.steps > 200000)) {
    return jsonResponse(400, { error: 'steps must be a whole number between 0 and 200000.' });
  }

  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };
  const base = process.env.SUPABASE_URL;
  const tokenHash = hashToken(payload.token);

  try {
    const tokenRes = await fetch(
      `${base}/rest/v1/health_sync_tokens?token_hash=eq.${tokenHash}&revoked_at=is.null&select=user_id,last_used_at`,
      { headers: serviceHeaders }
    );
    if (!tokenRes.ok) throw new Error('Token lookup failed: ' + (await tokenRes.text()));
    const tokenRow = (await tokenRes.json())[0];
    if (!tokenRow) return jsonResponse(401, { error: 'Invalid or revoked token.' });

    if (tokenRow.last_used_at) {
      const secondsSince = (Date.now() - new Date(tokenRow.last_used_at).getTime()) / 1000;
      if (secondsSince < MIN_SECONDS_BETWEEN_REQUESTS) {
        return jsonResponse(429, { error: `Too many requests — try again in ${Math.ceil(MIN_SECONDS_BETWEEN_REQUESTS - secondsSince)}s.` });
      }
    }

    const userId = tokenRow.user_id;
    const wrote = [];

    if (hasBodyweight) {
      // weight_log's health-sync idempotency is a PARTIAL unique index
      // (only for source='healthkit_shortcut', so manual multi-entry per
      // day stays untouched) — PostgREST's on_conflict upsert can't target
      // a partial index, so this does the select-then-write by hand
      // instead of relying on it.
      const existing = await fetch(
        `${base}/rest/v1/weight_log?user_id=eq.${userId}&logged_date=eq.${payload.date}&source=eq.healthkit_shortcut&select=id`,
        { headers: serviceHeaders }
      ).then((r) => r.json());
      if (existing[0]) {
        await fetch(`${base}/rest/v1/weight_log?id=eq.${existing[0].id}`, {
          method: 'PATCH', headers: serviceHeaders, body: JSON.stringify({ weight_lb: payload.bodyweight_lb }),
        });
      } else {
        await fetch(`${base}/rest/v1/weight_log`, {
          method: 'POST', headers: serviceHeaders,
          body: JSON.stringify({ user_id: userId, logged_date: payload.date, weight_lb: payload.bodyweight_lb, source: 'healthkit_shortcut' }),
        });
      }
      wrote.push('bodyweight_lb');
    }

    if (hasSleep) {
      await fetch(`${base}/rest/v1/sleep_log?on_conflict=user_id,logged_date`, {
        method: 'POST',
        headers: { ...serviceHeaders, Prefer: 'resolution=merge-duplicates' },
        body: JSON.stringify({ user_id: userId, logged_date: payload.date, hours: payload.sleep_hours }),
      });
      wrote.push('sleep_hours');
    }

    if (hasSteps) {
      await fetch(`${base}/rest/v1/steps_log?on_conflict=user_id,logged_date`, {
        method: 'POST',
        headers: { ...serviceHeaders, Prefer: 'resolution=merge-duplicates' },
        body: JSON.stringify({ user_id: userId, logged_date: payload.date, steps: payload.steps }),
      });
      wrote.push('steps');
    }

    await fetch(`${base}/rest/v1/health_sync_tokens?user_id=eq.${userId}`, {
      method: 'PATCH', headers: serviceHeaders, body: JSON.stringify({ last_used_at: new Date().toISOString() }),
    });

    return jsonResponse(200, { ok: true, wrote });
  } catch (err) {
    await captureError(err, { function: 'health-sync' });
    return jsonResponse(500, { error: 'Could not process that sync.' });
  }
});
