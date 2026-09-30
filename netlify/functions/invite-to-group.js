// POST { groupId: string, friendUserId: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Invites an existing accepted friend to the caller's group. Any joined
// member can invite (not just the creator), per product spec. Service-role
// because verifying "is this an accepted friend of mine" and "is this
// person already in a different group" both require reading another
// user's rows, which friendships'/group_members' own RLS (scoped to
// auth.uid()) doesn't allow the client to do directly — same reasoning as
// add-friend.js and get-leaderboard.js.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

const GROUP_MAX_MEMBERS = 10;

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

  const groupId = (payload.groupId || '').trim();
  const friendUserId = (payload.friendUserId || '').trim();
  if (!groupId || !friendUserId) return jsonResponse(400, { error: 'Missing groupId or friendUserId.' });
  if (friendUserId === auth.user.id) return jsonResponse(400, { error: "You can't invite yourself." });

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const callerMemberRes = await fetch(
      `${base}/rest/v1/group_members?group_id=eq.${groupId}&user_id=eq.${auth.user.id}&status=eq.joined&select=id`,
      { headers: serviceHeaders }
    );
    const callerMember = callerMemberRes.ok ? await callerMemberRes.json() : [];
    if (!callerMember.length) return jsonResponse(403, { error: "You're not a member of that group." });

    const friendshipRes = await fetch(
      `${base}/rest/v1/friendships?status=eq.accepted&or=(and(requester_id.eq.${auth.user.id},addressee_id.eq.${friendUserId}),and(requester_id.eq.${friendUserId},addressee_id.eq.${auth.user.id}))&select=id`,
      { headers: serviceHeaders }
    );
    const friendship = friendshipRes.ok ? await friendshipRes.json() : [];
    if (!friendship.length) return jsonResponse(400, { error: 'You can only invite an existing friend.' });

    const alreadyGroupedRes = await fetch(
      `${base}/rest/v1/group_members?user_id=eq.${friendUserId}&status=eq.joined&select=group_id`,
      { headers: serviceHeaders }
    );
    const alreadyGrouped = alreadyGroupedRes.ok ? await alreadyGroupedRes.json() : [];
    if (alreadyGrouped.some((m) => m.group_id === groupId)) return jsonResponse(200, { status: 'already_member' });
    if (alreadyGrouped.length > 0) return jsonResponse(400, { error: 'That friend is already in a different group.' });

    const countRes = await fetch(
      `${base}/rest/v1/group_members?group_id=eq.${groupId}&status=in.(invited,joined)&select=id`,
      { headers: serviceHeaders }
    );
    const currentMembers = countRes.ok ? await countRes.json() : [];
    if (currentMembers.length >= GROUP_MAX_MEMBERS) return jsonResponse(400, { error: `Groups max out at ${GROUP_MAX_MEMBERS} members.` });

    const insertRes = await fetch(`${base}/rest/v1/group_members`, {
      method: 'POST',
      headers: serviceHeaders,
      body: JSON.stringify({ group_id: groupId, user_id: friendUserId, status: 'invited' }),
    });
    if (!insertRes.ok) {
      const detail = await insertRes.text();
      if (insertRes.status === 409 || detail.toLowerCase().includes('duplicate')) {
        return jsonResponse(200, { status: 'already_invited' });
      }
      await captureError(new Error('Could not insert group invite: ' + detail), { function: 'invite-to-group', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not send the invite.' });
    }

    return jsonResponse(200, { status: 'invited' });
  } catch (err) {
    await captureError(err, { function: 'invite-to-group', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not send the invite.', detail: String(err.message || err) });
  }
}, 'invite-to-group');
