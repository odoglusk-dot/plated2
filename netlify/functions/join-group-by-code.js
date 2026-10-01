// POST { code: string, confirm?: boolean }
// Auth: Authorization: Bearer <supabase access token>
//
// Looks up a group by its shareable invite code (see
// generate-group-invite.js) and, with confirm:true, joins the caller to
// it directly — no existing in-app friendship required, unlike
// invite-to-group.js. Without confirm, this is a preview-only lookup (the
// client shows "Join <Group Name>?" before actually joining); confirm:true
// re-checks everything since state can change between preview and
// confirm (e.g. the group fills up while the screen is open).
//
// Returns one of these `status` values in all cases rather than an HTTP
// error for the expected ones, so the client can render a specific
// message instead of a generic failure toast:
//   'invalid'          — no group has this code (wrong/mistyped/old code)
//   'expired'          — code existed but passed its invite_code_expires_at
//   'full'             — group is already at the 10-member cap
//   'already_member'   — caller has already joined this exact group
//   'already_in_group' — caller is in a DIFFERENT group already (one active
//                         group per user, same constraint create-group.js enforces)
//   'valid'            — preview-only (no confirm): safe to show the join screen
//   'joined'           — confirm:true succeeded
const { jsonResponse, verifyUser, hasPaidAccess, captureError, withErrorReporting } = require('./_shared');

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

  if (!(await hasPaidAccess(auth.user.id, auth.token))) {
    return jsonResponse(402, { error: 'Group Mode is a paid feature — start your free trial or subscribe to use it.', upgradeRequired: true });
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const code = (payload.code || '').trim().toUpperCase();
  const confirm = payload.confirm === true;
  if (!code) return jsonResponse(400, { error: 'Missing invite code.' });

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const groupRes = await fetch(
      `${base}/rest/v1/groups?invite_code=eq.${encodeURIComponent(code)}&select=id,name,invite_code_expires_at`,
      { headers: serviceHeaders }
    );
    if (!groupRes.ok) return jsonResponse(502, { error: 'Could not look up that invite code.' });
    const [group] = await groupRes.json();
    if (!group) return jsonResponse(200, { status: 'invalid' });
    if (!group.invite_code_expires_at || new Date(group.invite_code_expires_at).getTime() < Date.now()) {
      return jsonResponse(200, { status: 'expired' });
    }

    const membersRes = await fetch(
      `${base}/rest/v1/group_members?group_id=eq.${group.id}&status=in.(invited,joined)&select=user_id,status`,
      { headers: serviceHeaders }
    );
    const members = membersRes.ok ? await membersRes.json() : [];
    const existingRow = members.find((m) => m.user_id === auth.user.id);

    if (!existingRow && members.length >= GROUP_MAX_MEMBERS) {
      return jsonResponse(200, { status: 'full', groupName: group.name });
    }
    if (existingRow && existingRow.status === 'joined') {
      return jsonResponse(200, { status: 'already_member', groupName: group.name });
    }

    if (!confirm) {
      return jsonResponse(200, { status: 'valid', groupId: group.id, groupName: group.name, memberCount: members.length });
    }

    // Re-check "one active group per user" at confirm time, not preview
    // time — same constraint create-group.js enforces.
    if (!existingRow) {
      const myGroupsRes = await fetch(
        `${base}/rest/v1/group_members?user_id=eq.${auth.user.id}&status=eq.joined&select=group_id`,
        { headers: serviceHeaders }
      );
      const myGroups = myGroupsRes.ok ? await myGroupsRes.json() : [];
      if (myGroups.length > 0) return jsonResponse(200, { status: 'already_in_group' });
    }

    const joinedAt = new Date().toISOString();
    const writeRes = existingRow
      ? await fetch(`${base}/rest/v1/group_members?group_id=eq.${group.id}&user_id=eq.${auth.user.id}`, {
          method: 'PATCH',
          headers: { ...serviceHeaders, Prefer: 'return=minimal' },
          body: JSON.stringify({ status: 'joined', joined_at: joinedAt }),
        })
      : await fetch(`${base}/rest/v1/group_members`, {
          method: 'POST',
          headers: { ...serviceHeaders, Prefer: 'return=minimal' },
          body: JSON.stringify({ group_id: group.id, user_id: auth.user.id, status: 'joined', joined_at: joinedAt }),
        });

    if (!writeRes.ok) {
      const detail = await writeRes.text();
      await captureError(new Error('Could not join group by code: ' + detail), { function: 'join-group-by-code', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not join that group.' });
    }

    return jsonResponse(200, { status: 'joined', groupId: group.id, groupName: group.name });
  } catch (err) {
    await captureError(err, { function: 'join-group-by-code', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not join that group.', detail: String(err.message || err) });
  }
}, 'join-group-by-code');
