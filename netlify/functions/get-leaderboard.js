// POST {}
// Auth: Authorization: Bearer <supabase access token>
//
// Returns everything the Profile "Friends" card and the Insights leaderboard
// need in one call: { entries, incomingRequests, outgoingCount }. `entries`
// covers the caller plus every accepted friend (streak/exercisesTracked/
// careerVolume, sorted by streak desc); `incomingRequests` are pending
// requests sent TO the caller (with the requester's display name so there's
// something to show besides a bare user id — profiles' own RLS won't let
// the client look that up itself, same reasoning as add-friend.js).
//
// Uses the service-role key to read friends' `lifts` rows — there's no
// cross-user RLS policy on lifts (and shouldn't be; it's still each
// person's private log), so this function is the only place that ever
// looks past a friend's own three aggregate numbers. It never returns a
// friend's actual lift rows, food logs, or anything else — just the
// leaderboard stats.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

// Mirrors computeTrainingStreak() in index.html — consecutive days (from the
// most recent trained day backward) with at least one lift.
function computeTrainingStreak(lifts) {
  const trainedDates = new Set(lifts.map((l) => l.date));
  if (trainedDates.size === 0) return 0;
  const sortedDates = Array.from(trainedDates).sort((a, b) => b.localeCompare(a));
  let count = 0;
  let cursorDate = new Date(`${sortedDates[0]}T00:00:00`);
  for (const ds of sortedDates) {
    const d = new Date(`${ds}T00:00:00`);
    const diff = Math.round((cursorDate - d) / 86400000);
    if (diff === 0) {
      count++;
      cursorDate = new Date(cursorDate.getTime() - 86400000);
    } else break;
  }
  return count;
}

// Mirrors totalReps() in index.html.
function totalReps(l) {
  if (Array.isArray(l.reps_per_set) && l.reps_per_set.length) {
    return l.reps_per_set.reduce((s, r) => s + (Number(r) || 0), 0);
  }
  return (Number(l.reps) || 0) * (Number(l.sets) || 1);
}

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for the leaderboard.' });
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
    const friendshipsRes = await fetch(
      `${base}/rest/v1/friendships?status=eq.accepted&or=(requester_id.eq.${auth.user.id},addressee_id.eq.${auth.user.id})&select=requester_id,addressee_id`,
      { headers: serviceHeaders }
    );
    if (!friendshipsRes.ok) return jsonResponse(502, { error: 'Could not load friends.' });
    const friendships = await friendshipsRes.json();
    const friendIds = friendships.map((f) => (f.requester_id === auth.user.id ? f.addressee_id : f.requester_id));

    const incomingRes = await fetch(
      `${base}/rest/v1/friendships?status=eq.pending&addressee_id=eq.${auth.user.id}&select=id,requester_id`,
      { headers: serviceHeaders }
    );
    const incoming = incomingRes.ok ? await incomingRes.json() : [];

    const outgoingRes = await fetch(
      `${base}/rest/v1/friendships?status=eq.pending&requester_id=eq.${auth.user.id}&select=id`,
      { headers: serviceHeaders }
    );
    const outgoing = outgoingRes.ok ? await outgoingRes.json() : [];

    const leaderboardUserIds = [auth.user.id, ...friendIds];
    const allNamedIds = [...leaderboardUserIds, ...incoming.map((r) => r.requester_id)];
    const profilesRes = await fetch(
      `${base}/rest/v1/profiles?id=in.(${allNamedIds.join(',')})&select=id,display_name`,
      { headers: serviceHeaders }
    );
    const profiles = profilesRes.ok ? await profilesRes.json() : [];
    const nameById = Object.fromEntries(profiles.map((p) => [p.id, p.display_name || 'Athlete']));

    const incomingRequests = incoming.map((r) => ({ id: r.id, requesterId: r.requester_id, displayName: nameById[r.requester_id] || 'Athlete' }));

    const entries = await Promise.all(leaderboardUserIds.map(async (userId) => {
      const liftsRes = await fetch(
        `${base}/rest/v1/lifts?user_id=eq.${userId}&select=date,weight,reps,sets,reps_per_set,exercise`,
        { headers: serviceHeaders }
      );
      const lifts = liftsRes.ok ? await liftsRes.json() : [];
      const careerVolume = lifts.reduce((sum, l) => sum + (Number(l.weight) || 0) * totalReps(l), 0);
      return {
        userId,
        displayName: nameById[userId] || 'Athlete',
        isSelf: userId === auth.user.id,
        streak: computeTrainingStreak(lifts),
        exercisesTracked: new Set(lifts.map((l) => l.exercise)).size,
        careerVolume: Math.round(careerVolume),
      };
    }));

    entries.sort((a, b) => b.streak - a.streak || b.careerVolume - a.careerVolume);
    return jsonResponse(200, { entries, incomingRequests, outgoingCount: outgoing.length });
  } catch (err) {
    await captureError(err, { function: 'get-leaderboard', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not load the leaderboard.', detail: String(err.message || err) });
  }
}, 'get-leaderboard');
