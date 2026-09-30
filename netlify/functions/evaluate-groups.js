// Scheduled function (see netlify.toml's `schedule` on this function) —
// not callable meaningfully from the browser. Runs once/day, shortly
// after send-reminder-emails, and for every group:
//
//   1. Checks whether every JOINED member hit their own protein-goal
//      streak yesterday (a server-side port of computeStreaks()'s exact
//      threshold in index.html — daily food_logs protein sum >=
//      goals.protein_g — deliberately NOT computeTrainingStreak(), the
//      separate lift-day streak the Friends Leaderboard already uses).
//      Everyone hit it -> group streak +1 (and +1 banked freeze every
//      7th day, capped at 3). Someone missed it -> spend a banked freeze
//      if one exists (streak survives), otherwise the streak resets.
//   2. Separately, diffs each member's user_achievements against the
//      group's last_achievement_check_at and banks a bonus freeze per
//      new unlock found (capped at 3) — this can't be real-time, since
//      achievement unlocking is 100% client-side with no server code
//      path; this daily diff is the only way to detect it at all. Same
//      known-limitation shape as this file's own "fixed UTC day" already
//      accepts for send-reminder-emails.js's "evening" timing.
//   3. If a group_goal's period just ended, that's folded into the same
//      digest.
//   4. Sends one combined digest email per member per group (via
//      Resend's REST API, matching send-reminder-emails.js), including
//      only the categories that member hasn't opted out of, and only if
//      something in an opted-in category actually happened.
//
// Uses the service-role key throughout — every read/write here is
// cross-user (another member's food_logs/goals/achievements) or a table
// with no client write policy at all (groups, group_freeze_log).
const { captureError, withErrorReporting } = require('./_shared');

const FREEZE_CAP = 3;
const MILESTONE_INTERVAL_DAYS = 7;

function utcDayBoundsFor(daysAgo) {
  const now = new Date();
  const todayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const start = new Date(todayStart.getTime() - daysAgo * 24 * 60 * 60 * 1000);
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, end, dateStr: start.toISOString().slice(0, 10) };
}

async function sendDigestEmail(email, groupName, lines) {
  if (!process.env.RESEND_API_KEY || !lines.length) return;
  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      from: process.env.RESEND_FROM_EMAIL || 'Krafft <reminders@example.com>',
      to: email,
      subject: `Group update: ${groupName}`,
      text: lines.join('\n') + '\n\nTurn these off anytime: Krafft -> Profile -> Group Notifications.',
    }),
  }).catch(() => {}); // best-effort — one member's bad email must never block the run
}

exports.handler = withErrorReporting(async () => {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return { statusCode: 200, body: 'Group Mode not configured; skipping.' };
  }

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  const { start: evalStart, end: evalEnd, dateStr: evalDateStr } = utcDayBoundsFor(1); // "yesterday" UTC

  try {
    const groupsRes = await fetch(`${base}/rest/v1/groups?select=*`, { headers: serviceHeaders });
    if (!groupsRes.ok) throw new Error('Could not list groups: ' + (await groupsRes.text()));
    const groups = await groupsRes.json();

    let evaluated = 0;
    for (const group of groups) {
      if (group.last_evaluated_date === evalDateStr) continue; // already ran for this day

      const membersRes = await fetch(
        `${base}/rest/v1/group_members?group_id=eq.${group.id}&status=eq.joined&select=user_id`,
        { headers: serviceHeaders }
      );
      const members = membersRes.ok ? await membersRes.json() : [];
      if (!members.length) continue; // shouldn't happen (creator is always joined), but don't act on an empty group

      const memberIds = members.map((m) => m.user_id);
      const [profilesRes, goalsRes] = await Promise.all([
        fetch(`${base}/rest/v1/profiles?id=in.(${memberIds.join(',')})&select=id,display_name,group_streak_emails_opt_out,group_freeze_emails_opt_out,group_goal_emails_opt_out`, { headers: serviceHeaders }),
        fetch(`${base}/rest/v1/goals?user_id=in.(${memberIds.join(',')})&select=user_id,protein_g`, { headers: serviceHeaders }),
      ]);
      const profiles = profilesRes.ok ? await profilesRes.json() : [];
      const proteinGoalById = Object.fromEntries((goalsRes.ok ? await goalsRes.json() : []).map((g) => [g.user_id, g.protein_g]));
      const nameById = Object.fromEntries(profiles.map((p) => [p.id, p.display_name || 'A member']));

      const hitResults = await Promise.all(memberIds.map(async (userId) => {
        const goal = proteinGoalById[userId];
        if (!goal) return false;
        const res = await fetch(
          `${base}/rest/v1/food_logs?user_id=eq.${userId}&logged_at=gte.${evalStart.toISOString()}&logged_at=lt.${evalEnd.toISOString()}&select=protein_g`,
          { headers: serviceHeaders }
        );
        if (!res.ok) return false;
        const rows = await res.json();
        return rows.reduce((sum, r) => sum + (Number(r.protein_g) || 0), 0) >= goal;
      }));
      const everyoneHit = hitResults.every(Boolean);

      let freezesAvailable = group.freezes_available;
      let currentStreak = group.current_streak;
      let bestStreak = group.best_streak;
      const logEntries = [];
      const digestByMember = Object.fromEntries(memberIds.map((id) => [id, []]));

      if (everyoneHit) {
        currentStreak += 1;
        bestStreak = Math.max(bestStreak, currentStreak);
        for (const id of memberIds) digestByMember[id].push({ cat: 'streak', text: `Your group streak is now ${currentStreak} days — everyone hit their goal yesterday.` });
        if (currentStreak % MILESTONE_INTERVAL_DAYS === 0 && freezesAvailable < FREEZE_CAP) {
          freezesAvailable += 1;
          logEntries.push({ kind: 'milestone_earned', member_id: null });
          for (const id of memberIds) digestByMember[id].push({ cat: 'freeze', text: `Bonus: a ${currentStreak}-day streak earned the group a freeze (${freezesAvailable}/${FREEZE_CAP} banked).` });
        }
      } else if (freezesAvailable > 0) {
        freezesAvailable -= 1;
        currentStreak += 1;
        bestStreak = Math.max(bestStreak, currentStreak);
        logEntries.push({ kind: 'spent', member_id: null });
        for (const id of memberIds) digestByMember[id].push({ cat: 'freeze', text: `A freeze protected the streak today (${freezesAvailable}/${FREEZE_CAP} left) — it's still at ${currentStreak} days.` });
      } else {
        currentStreak = 0;
        for (const id of memberIds) digestByMember[id].push({ cat: 'streak', text: `The group streak reset today — no freezes left to protect it. Fresh start tomorrow.` });
      }

      // Achievement-triggered bonus freezes — independent of the
      // streak/freeze-spend decision above.
      const achievementsRes = await fetch(
        `${base}/rest/v1/user_achievements?user_id=in.(${memberIds.join(',')})&unlocked_at=gt.${group.last_achievement_check_at}&select=user_id,achievement_id,unlocked_at`,
        { headers: serviceHeaders }
      );
      const newAchievements = achievementsRes.ok ? await achievementsRes.json() : [];
      for (const ach of newAchievements) {
        if (freezesAvailable >= FREEZE_CAP) break;
        freezesAvailable += 1;
        logEntries.push({ kind: 'achievement_earned', member_id: ach.user_id });
        for (const id of memberIds) digestByMember[id].push({ cat: 'freeze', text: `${nameById[ach.user_id]} unlocked an achievement — the group earned a bonus freeze (${freezesAvailable}/${FREEZE_CAP} banked).` });
      }

      // A group goal that just concluded (its period ended yesterday).
      const goalRes = await fetch(
        `${base}/rest/v1/group_goals?group_id=eq.${group.id}&period_end=eq.${evalDateStr}&select=*&order=created_at.desc&limit=1`,
        { headers: serviceHeaders }
      );
      const [concludedGoal] = goalRes.ok ? await goalRes.json() : [];
      if (concludedGoal && concludedGoal.target_type === 'total_sessions') {
        const sessionsRes = await fetch(
          `${base}/rest/v1/lifts?user_id=in.(${memberIds.join(',')})&date=gte.${concludedGoal.period_start}&date=lte.${concludedGoal.period_end}&select=user_id,date`,
          { headers: serviceHeaders }
        );
        const sessionRows = sessionsRes.ok ? await sessionsRes.json() : [];
        const total = new Set(sessionRows.map((r) => `${r.user_id}:${r.date}`)).size;
        const met = total >= Number(concludedGoal.target_value);
        for (const id of memberIds) digestByMember[id].push({ cat: 'goal', text: `Group goal wrapped up: "${concludedGoal.description}" — ${total}/${concludedGoal.target_value}${met ? ' — hit it! 🎉' : '.'}` });
      }

      await fetch(`${base}/rest/v1/groups?id=eq.${group.id}`, {
        method: 'PATCH',
        headers: { ...serviceHeaders, Prefer: 'return=minimal' },
        body: JSON.stringify({
          current_streak: currentStreak,
          best_streak: bestStreak,
          freezes_available: freezesAvailable,
          last_evaluated_date: evalDateStr,
          last_achievement_check_at: new Date().toISOString(),
        }),
      });

      if (logEntries.length) {
        await fetch(`${base}/rest/v1/group_freeze_log`, {
          method: 'POST',
          headers: serviceHeaders,
          body: JSON.stringify(logEntries.map((e) => ({ ...e, group_id: group.id }))),
        }).catch(() => {});
      }

      // Send one digest per member, filtered to categories they haven't
      // opted out of. auth.users' email isn't reachable via PostgREST —
      // groups top out at 10 members, so fetching each one individually
      // via GoTrue's per-id admin endpoint is cheap and doesn't depend on
      // list-filter syntax support the way a batch query would.
      const emailById = {};
      await Promise.all(memberIds.map(async (id) => {
        const res = await fetch(`${base}/auth/v1/admin/users/${id}`, { headers: serviceHeaders }).catch(() => null);
        if (res && res.ok) {
          const u = await res.json().catch(() => null);
          if (u && u.email) emailById[id] = u.email;
        }
      }));

      const optOutById = Object.fromEntries(profiles.map((p) => [p.id, {
        streak: !!p.group_streak_emails_opt_out,
        freeze: !!p.group_freeze_emails_opt_out,
        goal: !!p.group_goal_emails_opt_out,
      }]));

      await Promise.all(memberIds.map(async (id) => {
        const email = emailById[id];
        if (!email) return;
        const optOut = optOutById[id] || {};
        const lines = digestByMember[id].filter((e) => !optOut[e.cat]).map((e) => e.text);
        await sendDigestEmail(email, group.name, lines);
      }));

      evaluated++;
    }

    return { statusCode: 200, body: JSON.stringify({ groupsChecked: groups.length, evaluated }) };
  } catch (err) {
    await captureError(err, { function: 'evaluate-groups' });
    return { statusCode: 500, body: 'Error evaluating groups.' };
  }
}, 'evaluate-groups');
