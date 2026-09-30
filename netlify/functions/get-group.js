// POST {}
// Auth: Authorization: Bearer <supabase access token>
//
// Returns everything the Group Mode screen needs in one call: the
// caller's active group (roster with each member's own today's-goal-hit
// status, streak, freeze balance, recent freeze/achievement log, and the
// active group goal's live-computed progress) or null, plus any pending
// invites to the caller.
//
// Uses the service-role key to read every member's own food_logs/goals/
// lifts — there's no cross-user RLS policy on those (and shouldn't be),
// so this function is the only place that ever looks past a fellow
// member's own derived "did you hit your goal today" boolean. It never
// returns a member's actual food_logs/lifts rows, only that one boolean
// per member plus the group-level aggregates — same philosophy as
// get-leaderboard.js never returning a friend's raw lift rows.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

// Mirrors sumMacros(dayLogs).protein_g >= proteinGoal from computeStreaks()
// in index.html — "hit your goal today" is protein-only, not calories/
// training. today/tomorrow are fixed UTC calendar-day boundaries (no
// per-user timezone stored anywhere in this app — same documented
// approximation send-reminder-emails.js already uses).
async function hitGoalToday(base, serviceHeaders, userId, proteinGoal, todayStart, tomorrowStart) {
  if (!proteinGoal) return false;
  const res = await fetch(
    `${base}/rest/v1/food_logs?user_id=eq.${userId}&logged_at=gte.${todayStart}&logged_at=lt.${tomorrowStart}&select=protein_g`,
    { headers: serviceHeaders }
  );
  if (!res.ok) return false;
  const rows = await res.json();
  const total = rows.reduce((sum, r) => sum + (Number(r.protein_g) || 0), 0);
  return total >= proteinGoal;
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

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const myMembershipsRes = await fetch(
      `${base}/rest/v1/group_members?user_id=eq.${auth.user.id}&select=group_id,status,invited_at`,
      { headers: serviceHeaders }
    );
    if (!myMembershipsRes.ok) return jsonResponse(502, { error: 'Could not load your group.' });
    const myMemberships = await myMembershipsRes.json();
    const joined = myMemberships.find((m) => m.status === 'joined');
    const invited = myMemberships.filter((m) => m.status === 'invited');

    let pendingInvites = [];
    if (invited.length) {
      const invitedGroupIds = invited.map((m) => m.group_id);
      const invitedGroupsRes = await fetch(
        `${base}/rest/v1/groups?id=in.(${invitedGroupIds.join(',')})&select=id,name`,
        { headers: serviceHeaders }
      );
      const invitedGroups = invitedGroupsRes.ok ? await invitedGroupsRes.json() : [];
      const nameById = Object.fromEntries(invitedGroups.map((g) => [g.id, g.name]));
      pendingInvites = invited.map((m) => ({ groupId: m.group_id, groupName: nameById[m.group_id] || 'Group', invitedAt: m.invited_at }));
    }

    if (!joined) {
      return jsonResponse(200, { group: null, pendingInvites });
    }

    const groupId = joined.group_id;
    const [groupRes, membersRes] = await Promise.all([
      fetch(`${base}/rest/v1/groups?id=eq.${groupId}&select=*`, { headers: serviceHeaders }),
      fetch(`${base}/rest/v1/group_members?group_id=eq.${groupId}&select=user_id,status`, { headers: serviceHeaders }),
    ]);
    if (!groupRes.ok || !membersRes.ok) return jsonResponse(502, { error: 'Could not load your group.' });
    const [group] = await groupRes.json();
    const members = await membersRes.json();
    if (!group) return jsonResponse(200, { group: null, pendingInvites });

    const joinedMembers = members.filter((m) => m.status === 'joined');
    const allMemberIds = members.map((m) => m.user_id);

    const [profilesRes, goalsRes, freezeLogRes, groupGoalRes] = await Promise.all([
      fetch(`${base}/rest/v1/profiles?id=in.(${allMemberIds.join(',')})&select=id,display_name`, { headers: serviceHeaders }),
      fetch(`${base}/rest/v1/goals?user_id=in.(${joinedMembers.map((m) => m.user_id).join(',')})&select=user_id,protein_g`, { headers: serviceHeaders }),
      fetch(`${base}/rest/v1/group_freeze_log?group_id=eq.${groupId}&select=kind,member_id,created_at&order=created_at.desc&limit=20`, { headers: serviceHeaders }),
      fetch(`${base}/rest/v1/group_goals?group_id=eq.${groupId}&select=*&order=created_at.desc&limit=1`, { headers: serviceHeaders }),
    ]);
    const profiles = profilesRes.ok ? await profilesRes.json() : [];
    const nameById = Object.fromEntries(profiles.map((p) => [p.id, p.display_name || 'Athlete']));
    const proteinGoalById = Object.fromEntries((goalsRes.ok ? await goalsRes.json() : []).map((g) => [g.user_id, g.protein_g]));
    const freezeLog = freezeLogRes.ok ? await freezeLogRes.json() : [];
    const [groupGoal] = groupGoalRes.ok ? await groupGoalRes.json() : [];

    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const tomorrowStart = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    const roster = await Promise.all(joinedMembers.map(async (m) => ({
      userId: m.user_id,
      displayName: nameById[m.user_id] || 'Athlete',
      isSelf: m.user_id === auth.user.id,
      hitToday: await hitGoalToday(base, serviceHeaders, m.user_id, proteinGoalById[m.user_id], todayStart.toISOString(), tomorrowStart.toISOString()),
    })));

    const freezeLogOut = freezeLog.map((entry) => ({
      kind: entry.kind,
      memberName: entry.kind === 'achievement_earned' ? (nameById[entry.member_id] || 'A member') : null,
      createdAt: entry.created_at,
    }));

    let goalOut = null;
    if (groupGoal) {
      let progress = 0;
      if (groupGoal.target_type === 'total_sessions') {
        const sessionsRes = await fetch(
          `${base}/rest/v1/lifts?user_id=in.(${allMemberIds.join(',')})&date=gte.${groupGoal.period_start}&date=lte.${groupGoal.period_end}&select=user_id,date`,
          { headers: serviceHeaders }
        );
        const sessionRows = sessionsRes.ok ? await sessionsRes.json() : [];
        const distinctSessions = new Set(sessionRows.map((r) => `${r.user_id}:${r.date}`));
        progress = distinctSessions.size;
      }
      goalOut = {
        description: groupGoal.description,
        targetType: groupGoal.target_type,
        targetValue: Number(groupGoal.target_value),
        periodStart: groupGoal.period_start,
        periodEnd: groupGoal.period_end,
        progress,
      };
    }

    return jsonResponse(200, {
      group: {
        id: group.id,
        name: group.name,
        currentStreak: group.current_streak,
        bestStreak: group.best_streak,
        freezesAvailable: group.freezes_available,
        roster,
        freezeLog: freezeLogOut,
        goal: goalOut,
      },
      pendingInvites,
    });
  } catch (err) {
    await captureError(err, { function: 'get-group', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not load your group.', detail: String(err.message || err) });
  }
}, 'get-group');
