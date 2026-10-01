// POST { groupId: string, goalMetric: 'protein'|'calories'|'sessions', sessionsTargetPerWeek?: number }
// Auth: Authorization: Bearer <supabase access token>
//
// Lets a group's creator (its "leader" — there's no separate role column,
// creator_id already doubles as this) change what the shared streak
// tracks, anytime after creation. Service-role because verifying "is this
// caller the creator of this group" and writing a row with no client
// update policy both require it — same reasoning as create-group.js.
const { jsonResponse, verifyUser, hasPaidAccess, captureError, withErrorReporting } = require('./_shared');

const VALID_METRICS = ['protein', 'calories', 'sessions'];

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
  const goalMetric = (payload.goalMetric || '').trim();
  if (!groupId) return jsonResponse(400, { error: 'Missing groupId.' });
  if (!VALID_METRICS.includes(goalMetric)) return jsonResponse(400, { error: 'goalMetric must be protein, calories, or sessions.' });

  let sessionsTargetPerWeek = null;
  if (goalMetric === 'sessions') {
    sessionsTargetPerWeek = Math.round(Number(payload.sessionsTargetPerWeek));
    if (!Number.isFinite(sessionsTargetPerWeek) || sessionsTargetPerWeek < 1 || sessionsTargetPerWeek > 14) {
      return jsonResponse(400, { error: 'sessionsTargetPerWeek must be a number from 1 to 14.' });
    }
  }

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const groupRes = await fetch(`${base}/rest/v1/groups?id=eq.${groupId}&select=creator_id`, { headers: serviceHeaders });
    if (!groupRes.ok) return jsonResponse(502, { error: 'Could not load that group.' });
    const [group] = await groupRes.json();
    if (!group) return jsonResponse(404, { error: 'Group not found.' });
    if (group.creator_id !== auth.user.id) return jsonResponse(403, { error: "Only the group's creator can change its settings." });

    const updateRes = await fetch(`${base}/rest/v1/groups?id=eq.${groupId}`, {
      method: 'PATCH',
      headers: { ...serviceHeaders, Prefer: 'return=minimal' },
      body: JSON.stringify({ goal_metric: goalMetric, sessions_target_per_week: sessionsTargetPerWeek }),
    });
    if (!updateRes.ok) {
      const detail = await updateRes.text();
      await captureError(new Error('Could not update group settings: ' + detail), { function: 'update-group-settings', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not update the group settings.' });
    }

    return jsonResponse(200, { status: 'updated', goalMetric, sessionsTargetPerWeek });
  } catch (err) {
    await captureError(err, { function: 'update-group-settings', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not update the group settings.', detail: String(err.message || err) });
  }
}, 'update-group-settings');
