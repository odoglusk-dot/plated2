// POST { groupId: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Any current JOINED member (not creator-only, unlike update-group-settings.js)
// can (re)generate a shareable invite code for their group — a
// friend-agnostic join path, separate from invite-to-group.js's
// friendship-gated flow. Generating a new code immediately overwrites and
// invalidates whatever code existed before (e.g. if a link leaked
// publicly, any member can kill it by generating a fresh one). Expires
// 7 days after generation; join-group-by-code.js enforces both the code
// match and the expiry.
//
// Service-role because groups has no client write policy at all — same
// reasoning as every other write to this table.
const { jsonResponse, verifyUser, hasPaidAccess, captureError, withErrorReporting } = require('./_shared');

const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous 0/O, 1/I/L — same convention as the referral code
const CODE_LENGTH = 6;
const EXPIRY_DAYS = 7;

function generateCode() {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  return code;
}

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

  const groupId = (payload.groupId || '').trim();
  if (!groupId) return jsonResponse(400, { error: 'Missing groupId.' });

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const callerRes = await fetch(
      `${base}/rest/v1/group_members?group_id=eq.${groupId}&user_id=eq.${auth.user.id}&status=eq.joined&select=id`,
      { headers: serviceHeaders }
    );
    const caller = callerRes.ok ? await callerRes.json() : [];
    if (!caller.length) return jsonResponse(403, { error: "You're not a member of that group." });

    const expiresAt = new Date(Date.now() + EXPIRY_DAYS * 24 * 60 * 60 * 1000).toISOString();

    // Astronomically unlikely 6-char collision against another group's live
    // code — retry a few times the same way profile referral codes do.
    let lastDetail = '';
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = generateCode();
      const updateRes = await fetch(`${base}/rest/v1/groups?id=eq.${groupId}`, {
        method: 'PATCH',
        headers: { ...serviceHeaders, Prefer: 'return=minimal' },
        body: JSON.stringify({ invite_code: code, invite_code_expires_at: expiresAt }),
      });
      if (updateRes.ok) return jsonResponse(200, { inviteCode: code, expiresAt });
      lastDetail = await updateRes.text();
      if (!lastDetail.toLowerCase().includes('duplicate')) break;
    }

    await captureError(new Error('Could not generate group invite: ' + lastDetail), { function: 'generate-group-invite', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not generate an invite link — try again.' });
  } catch (err) {
    await captureError(err, { function: 'generate-group-invite', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not generate an invite link.', detail: String(err.message || err) });
  }
}, 'generate-group-invite');
