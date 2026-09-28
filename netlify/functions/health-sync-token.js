// POST { action: 'generate' | 'revoke' }
// Auth: Authorization: Bearer <supabase access token>
//
// Issues/revokes the per-user token an Apple Health Shortcut authenticates
// with (see health-sync.js, the actual webhook it posts to). Only a
// SHA-256 hash of the token is ever stored — this function is the only
// place that ever sees or handles the plaintext value, and it's only ever
// returned to the client once, right here, at generation time. The client
// never gets to choose or influence the hash itself, which is the whole
// point of routing issuance through a server-side function instead of a
// direct client insert.
const crypto = require('crypto');
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for Health sync.' });
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const action = payload.action;
  if (action !== 'generate' && action !== 'revoke') {
    return jsonResponse(400, { error: 'action must be "generate" or "revoke".' });
  }

  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };
  const base = process.env.SUPABASE_URL;
  const userId = auth.user.id;

  try {
    if (action === 'revoke') {
      const res = await fetch(`${base}/rest/v1/health_sync_tokens?user_id=eq.${userId}`, {
        method: 'PATCH',
        headers: serviceHeaders,
        body: JSON.stringify({ revoked_at: new Date().toISOString() }),
      });
      if (!res.ok) throw new Error('Could not revoke token: ' + (await res.text()));
      return jsonResponse(200, { revoked: true });
    }

    // generate — a fresh random token every time, replacing whatever
    // existed before (health_sync_tokens.user_id is unique, so this is a
    // one-token-per-user model: generating a new one silently invalidates
    // the last one, same as most "regenerate API key" flows).
    const rawToken = crypto.randomBytes(32).toString('hex');
    const token_hash = hashToken(rawToken);
    // on_conflict=user_id is required for the upsert to target that unique
    // constraint — without it, PostgREST's merge-duplicates resolves
    // against the primary key (id) instead, which is always fresh here
    // and would just fail on the user_id unique constraint on a second
    // "generate" call instead of replacing the old token.
    const res = await fetch(`${base}/rest/v1/health_sync_tokens?on_conflict=user_id`, {
      method: 'POST',
      headers: { ...serviceHeaders, Prefer: 'resolution=merge-duplicates' },
      body: JSON.stringify({ user_id: userId, token_hash, created_at: new Date().toISOString(), last_used_at: null, revoked_at: null }),
    });
    if (!res.ok) throw new Error('Could not create token: ' + (await res.text()));
    return jsonResponse(200, { token: rawToken });
  } catch (err) {
    await captureError(err, { function: 'health-sync-token', action, userId });
    return jsonResponse(500, { error: 'Could not complete that request.' });
  }
});
