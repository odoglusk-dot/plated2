// POST { code: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Sends a friend request from the CALLER to whoever holds the given
// referral code — reusing the referral code as the "add friend" code rather
// than generating a second one. Uses the service-role key because looking
// someone up by their referral_code means reading across users, which
// profiles' own RLS (scoped to auth.uid()) doesn't allow the client to do
// directly — same reasoning as redeem-referral.js.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for friends.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const code = (payload.code || '').trim().toUpperCase();
  if (!code) return jsonResponse(400, { error: 'Missing "code".' });

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const lookupRes = await fetch(
      `${base}/rest/v1/profiles?referral_code=eq.${encodeURIComponent(code)}&select=id,display_name`,
      { headers: serviceHeaders }
    );
    if (!lookupRes.ok) return jsonResponse(502, { error: 'Could not look up that code.' });
    const rows = await lookupRes.json();
    const addressee = rows[0];
    if (!addressee) return jsonResponse(404, { error: 'No one has that code.' });
    if (addressee.id === auth.user.id) return jsonResponse(400, { error: "That's your own code." });

    // If the other person already sent *us* a request, accept theirs instead
    // of creating a second, reversed row — avoids two pending rows for the
    // same pair that would otherwise both need resolving.
    const reverseRes = await fetch(
      `${base}/rest/v1/friendships?requester_id=eq.${addressee.id}&addressee_id=eq.${auth.user.id}&select=id,status`,
      { headers: serviceHeaders }
    );
    const reverseRows = reverseRes.ok ? await reverseRes.json() : [];
    if (reverseRows[0]) {
      if (reverseRows[0].status === 'accepted') return jsonResponse(200, { status: 'already_friends' });
      const acceptRes = await fetch(`${base}/rest/v1/friendships?id=eq.${reverseRows[0].id}`, {
        method: 'PATCH',
        headers: { ...serviceHeaders, Prefer: 'return=minimal' },
        body: JSON.stringify({ status: 'accepted', responded_at: new Date().toISOString() }),
      });
      if (!acceptRes.ok) return jsonResponse(502, { error: 'Could not accept their pending request.' });
      return jsonResponse(200, { status: 'accepted', friendName: addressee.display_name });
    }

    const insertRes = await fetch(`${base}/rest/v1/friendships`, {
      method: 'POST',
      headers: serviceHeaders,
      body: JSON.stringify({ requester_id: auth.user.id, addressee_id: addressee.id, status: 'pending' }),
    });
    if (!insertRes.ok) {
      const detail = await insertRes.text();
      if (insertRes.status === 409 || detail.toLowerCase().includes('duplicate')) {
        return jsonResponse(200, { status: 'already_requested' });
      }
      await captureError(new Error('Could not insert friendship: ' + detail), { function: 'add-friend', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not send friend request.' });
    }

    return jsonResponse(200, { status: 'requested', friendName: addressee.display_name });
  } catch (err) {
    await captureError(err, { function: 'add-friend', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not process that code.', detail: String(err.message || err) });
  }
}, 'add-friend');
