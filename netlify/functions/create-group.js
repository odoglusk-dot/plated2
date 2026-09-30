// POST { name: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Creates a new Group (Group Mode) and adds the caller as its first
// ('joined') member, in one call. One active group per user — enforced
// here, not a DB constraint, same style as BLOCK_MAX_PRIORITIES being
// enforced in index.html rather than SQL.
//
// Uses the service-role key so the creator's own group_members row can be
// inserted server-side — there is deliberately no client insert policy on
// group_members at all (even for your own row), since allowing any
// client-direct insert there would let a malicious client join/rejoin an
// arbitrary group_id, bypassing invite-to-group.js's friendship check
// entirely. Same reasoning as add-friend.js keeping friendships inserts
// service-role only.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for groups.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const name = (payload.name || '').trim().slice(0, 60);
  if (!name) return jsonResponse(400, { error: 'Give your group a name.' });

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const existingRes = await fetch(
      `${base}/rest/v1/group_members?user_id=eq.${auth.user.id}&status=eq.joined&select=group_id`,
      { headers: serviceHeaders }
    );
    const existing = existingRes.ok ? await existingRes.json() : [];
    if (existing.length > 0) return jsonResponse(400, { error: "You're already in a group — leave it first to create a new one." });

    const groupRes = await fetch(`${base}/rest/v1/groups`, {
      method: 'POST',
      headers: { ...serviceHeaders, Prefer: 'return=representation' },
      body: JSON.stringify({ name, creator_id: auth.user.id }),
    });
    if (!groupRes.ok) {
      const detail = await groupRes.text();
      await captureError(new Error('Could not insert group: ' + detail), { function: 'create-group', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not create the group.' });
    }
    const [group] = await groupRes.json();

    const memberRes = await fetch(`${base}/rest/v1/group_members`, {
      method: 'POST',
      headers: serviceHeaders,
      body: JSON.stringify({ group_id: group.id, user_id: auth.user.id, status: 'joined', joined_at: new Date().toISOString() }),
    });
    if (!memberRes.ok) {
      const detail = await memberRes.text();
      // The group row now exists with no members — clean it up rather than
      // leaving an orphaned, unjoinable group behind.
      await fetch(`${base}/rest/v1/groups?id=eq.${group.id}`, { method: 'DELETE', headers: serviceHeaders }).catch(() => {});
      await captureError(new Error('Could not insert creator membership: ' + detail), { function: 'create-group', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not create the group.' });
    }

    return jsonResponse(200, { status: 'created', groupId: group.id, name: group.name });
  } catch (err) {
    await captureError(err, { function: 'create-group', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not create the group.', detail: String(err.message || err) });
  }
}, 'create-group');
