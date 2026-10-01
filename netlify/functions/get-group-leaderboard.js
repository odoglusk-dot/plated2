// POST { groupId: string, window?: 'week' | 'month' | 'alltime' }
// Auth: Authorization: Bearer <supabase access token>
//
// A WITHIN-group leaderboard — separate from the shared group streak/
// freeze mechanic entirely. Ranks the group's own members by how
// consistently each one hits their OWN personal goal (the group's
// goal_metric — protein, calories, or sessions), over a selectable
// window, alongside each member's own personal streak for context. This
// is a per-member comparison, not a pass/fail gate on anything: nobody's
// group streak is affected by what this function returns.
//
// Also returns a supplementary per-member lift-goal summary (how many of
// their own exercise_goals are currently achieved). This is deliberately
// NOT folded into the percentage/streak above — lift goals are a
// milestone a user works toward over weeks (e1RM crossing a target by a
// date), not a daily event, so mixing them into a daily/weekly hit-rate
// would make that rate swing on an unrelated cadence. They're shown
// side by side instead.
//
// Nothing here is stored — every number is recomputed live from
// food_logs/lifts/exercise_goals each call, same "never store a derived
// stat" pattern as every other progress number in this app. Capped at a
// 180-day lookback (LOOKBACK_CAP_DAYS) regardless of window, both to
// bound query size and so a member's "personal streak" always means the
// same thing no matter which window tab is open.
const { jsonResponse, verifyUser, hasPaidAccess, captureError, withErrorReporting } = require('./_shared');

const LOOKBACK_CAP_DAYS = 180;
const WINDOW_DAYS = { week: 7, month: 30, alltime: LOOKBACK_CAP_DAYS };

function utcDateStr(daysAgo) {
  const now = new Date();
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()) - daysAgo * 86400000);
  return d.toISOString().slice(0, 10);
}

function daysSince(dateStr) {
  const then = new Date(dateStr.slice(0, 10) + 'T00:00:00Z').getTime();
  const today = new Date(utcDateStr(0) + 'T00:00:00Z').getTime();
  return Math.max(0, Math.round((today - then) / 86400000)) + 1; // inclusive of today and the join day
}

// Mirrors e1RM()/the bestE1RM derivation in index.html's goalsOverviewHtml().
function e1RM(weight, reps) {
  if (!weight || !reps) return 0;
  return Math.round(weight * (1 + reps / 30));
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
  const windowKey = WINDOW_DAYS[payload.window] ? payload.window : 'week';
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

    const groupRes = await fetch(`${base}/rest/v1/groups?id=eq.${groupId}&select=goal_metric,sessions_target_per_week`, { headers: serviceHeaders });
    if (!groupRes.ok) return jsonResponse(502, { error: 'Could not load the leaderboard.' });
    const [group] = await groupRes.json();
    if (!group) return jsonResponse(404, { error: 'Group not found.' });

    const membersRes = await fetch(`${base}/rest/v1/group_members?group_id=eq.${groupId}&status=eq.joined&select=user_id,joined_at`, { headers: serviceHeaders });
    const members = membersRes.ok ? await membersRes.json() : [];
    if (!members.length) return jsonResponse(200, { window: windowKey, goalMetric: group.goal_metric, sessionsTargetPerWeek: group.sessions_target_per_week, leaderboard: [] });

    const memberIds = members.map((m) => m.user_id);
    const joinedAtById = Object.fromEntries(members.map((m) => [m.user_id, m.joined_at]));
    const windowDays = WINDOW_DAYS[windowKey];
    const lookbackStartStr = utcDateStr(LOOKBACK_CAP_DAYS - 1);

    const profilesRes = await fetch(`${base}/rest/v1/profiles?id=in.(${memberIds.join(',')})&select=id,display_name`, { headers: serviceHeaders });
    const profiles = profilesRes.ok ? await profilesRes.json() : [];
    const nameById = Object.fromEntries(profiles.map((p) => [p.id, p.display_name || 'Athlete']));

    const isSessions = group.goal_metric === 'sessions';
    let percentageById = {};
    let streakById = {};

    if (isSessions) {
      const target = group.sessions_target_per_week || 1;
      const liftsRes = await fetch(
        `${base}/rest/v1/lifts?user_id=in.(${memberIds.join(',')})&date=gte.${lookbackStartStr}&select=user_id,date`,
        { headers: serviceHeaders }
      );
      const liftRows = liftsRes.ok ? await liftsRes.json() : [];
      const datesByUser = {};
      for (const r of liftRows) (datesByUser[r.user_id] || (datesByUser[r.user_id] = new Set())).add(r.date);

      for (const userId of memberIds) {
        const dates = datesByUser[userId] || new Set();
        const bucketsSinceJoin = Math.ceil(daysSince(joinedAtById[userId]) / 7);
        const totalBuckets = Math.max(1, Math.min(Math.ceil(windowDays / 7), bucketsSinceJoin, Math.ceil(LOOKBACK_CAP_DAYS / 7)));
        let hits = 0;
        let streak = 0;
        let streakBroken = false;
        for (let b = 0; b < totalBuckets; b++) {
          let count = 0;
          for (let d = b * 7; d < b * 7 + 7; d++) {
            if (dates.has(utcDateStr(d))) count++;
          }
          const hit = count >= target;
          if (hit) hits++;
          if (!streakBroken) { if (hit) streak++; else streakBroken = true; }
        }
        percentageById[userId] = Math.round(100 * hits / totalBuckets);
        streakById[userId] = streak;
      }
    } else {
      const goalColumn = group.goal_metric === 'calories' ? 'calories' : 'protein_g';
      const goalsRes = await fetch(`${base}/rest/v1/goals?user_id=in.(${memberIds.join(',')})&select=user_id,${goalColumn}`, { headers: serviceHeaders });
      const goalByUser = Object.fromEntries((goalsRes.ok ? await goalsRes.json() : []).map((g) => [g.user_id, g[goalColumn]]));

      const logsRes = await fetch(
        `${base}/rest/v1/food_logs?user_id=in.(${memberIds.join(',')})&logged_at=gte.${lookbackStartStr}T00:00:00.000Z&select=user_id,logged_at,${goalColumn}`,
        { headers: serviceHeaders }
      );
      const logRows = logsRes.ok ? await logsRes.json() : [];
      const totalsByUserDay = {};
      for (const r of logRows) {
        const day = String(r.logged_at).slice(0, 10);
        const key = r.user_id;
        if (!totalsByUserDay[key]) totalsByUserDay[key] = {};
        totalsByUserDay[key][day] = (totalsByUserDay[key][day] || 0) + (Number(r[goalColumn]) || 0);
      }

      for (const userId of memberIds) {
        const goal = goalByUser[userId];
        const dayTotals = totalsByUserDay[userId] || {};
        const daysJoined = daysSince(joinedAtById[userId]);
        const totalDays = Math.max(1, Math.min(windowDays, daysJoined, LOOKBACK_CAP_DAYS));
        if (!goal) { percentageById[userId] = 0; streakById[userId] = 0; continue; }
        let hits = 0;
        let streak = 0;
        let streakBroken = false;
        for (let d = 0; d < totalDays; d++) {
          const hit = (dayTotals[utcDateStr(d)] || 0) >= goal;
          if (hit) hits++;
          if (!streakBroken) { if (hit) streak++; else streakBroken = true; }
        }
        percentageById[userId] = Math.round(100 * hits / totalDays);
        streakById[userId] = streak;
      }
    }

    // Lift-goal summary — supplementary, independent of goal_metric.
    const exerciseGoalsRes = await fetch(`${base}/rest/v1/exercise_goals?user_id=in.(${memberIds.join(',')})&select=user_id,exercise,target_weight`, { headers: serviceHeaders });
    const exerciseGoals = exerciseGoalsRes.ok ? await exerciseGoalsRes.json() : [];
    const liftGoalsByUser = {};
    for (const g of exerciseGoals) (liftGoalsByUser[g.user_id] || (liftGoalsByUser[g.user_id] = [])).push(g);

    const liftGoalUserIds = Object.keys(liftGoalsByUser);
    const bestE1RMByUserExercise = {};
    if (liftGoalUserIds.length) {
      const allExercises = Array.from(new Set(exerciseGoals.map((g) => g.exercise)));
      const relevantLiftsRes = await fetch(
        `${base}/rest/v1/lifts?user_id=in.(${liftGoalUserIds.join(',')})&exercise=in.(${allExercises.map((e) => encodeURIComponent(`"${e}"`)).join(',')})&select=user_id,exercise,weight,reps`,
        { headers: serviceHeaders }
      );
      const relevantLifts = relevantLiftsRes.ok ? await relevantLiftsRes.json() : [];
      for (const l of relevantLifts) {
        const key = `${l.user_id}:${l.exercise}`;
        bestE1RMByUserExercise[key] = Math.max(bestE1RMByUserExercise[key] || 0, e1RM(l.weight, l.reps));
      }
    }

    const leaderboard = memberIds.map((userId) => {
      const goals = liftGoalsByUser[userId] || [];
      const liftGoalsAchieved = goals.filter((g) => (bestE1RMByUserExercise[`${userId}:${g.exercise}`] || 0) >= g.target_weight).length;
      return {
        userId,
        displayName: nameById[userId] || 'Athlete',
        isSelf: userId === auth.user.id,
        percentage: percentageById[userId] || 0,
        personalStreak: streakById[userId] || 0,
        liftGoalsAchieved,
        liftGoalsTotal: goals.length,
      };
    });
    leaderboard.sort((a, b) => b.percentage - a.percentage || b.personalStreak - a.personalStreak || a.displayName.localeCompare(b.displayName));

    return jsonResponse(200, { window: windowKey, goalMetric: group.goal_metric, sessionsTargetPerWeek: group.sessions_target_per_week, leaderboard });
  } catch (err) {
    await captureError(err, { function: 'get-group-leaderboard', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not load the leaderboard.', detail: String(err.message || err) });
  }
}, 'get-group-leaderboard');
