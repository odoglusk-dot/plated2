// Scheduled function (see netlify.toml's `schedule` on this function) —
// not callable meaningfully from the browser. Runs once nightly, after
// evaluate-groups.js, and for every user active in the last 14 days (an
// efficiency cutoff, not a feature boundary — a user who hasn't trained in
// 2+ weeks has nothing fresh for these insights to say anyway), computes
// 4 of items 3+4's 5 proposed rule-based (no AI) training insights and
// stores them in training_insights, overwriting the prior row. The 5th
// ("training load spike") turned out to already exist live in index.html —
// see the note above isOverreachedWeek() below — so it isn't duplicated
// here. The client reads the stored row and renders instantly on next app
// open, instead of recomputing any of this live on every render.
//
// All of this is pure arithmetic over already-logged data — no model call,
// no per-request cost, which is why it can run as a batch instead of
// on-demand. Several numeric thresholds below are judgment calls made
// without a human in the loop and are flagged in their own comments for
// review — they're reasonable starting points, not settled science.
const { captureError, withErrorReporting, e1RM, totalReps, summarizeExerciseTrend } = require('./_shared');

function utcDateStr(d) {
  return d.toISOString().slice(0, 10);
}

// Monday-start week key, in UTC — same Monday-start convention the client's
// getWeekStart() uses, just UTC-based instead of browser-local, matching
// this codebase's existing "fixed UTC time" approximation philosophy for
// scheduled jobs (see send-reminder-emails.js's comment on the same
// tradeoff for "evening").
function getWeekStartUTC(dateStr) {
  const d = new Date(`${dateStr}T00:00:00Z`);
  const day = d.getUTCDay();
  const diffToMonday = day === 0 ? -6 : 1 - day;
  const monday = new Date(d);
  monday.setUTCDate(d.getUTCDate() + diffToMonday);
  return utcDateStr(monday);
}

// ── "Training load spike" was NOT built as a new insight ─────────────────
// Item 4's first bullet ("compare current week's total volume against the
// trailing 4-week average, flag when it jumps sharply") already exists,
// live, in index.html: computeVolumeSpike() with VOLUME_SPIKE_THRESHOLD =
// 0.4 (40%) — shown both as a Dashboard banner and the Insights tab's
// "Consider a Deload" card. Rather than ship a second, nightly-computed
// duplicate of a feature that already works fine live (it's cheap pure
// arithmetic, nothing here needed batching), this keeps the identical
// calculation as an internal helper only — reused below by
// goodDayForPR's composite (so it doesn't suggest a PR attempt during a
// week the app already flags as a spike/deload risk elsewhere) — and
// never stores or displays it as its own separate insight.
const LOAD_SPIKE_THRESHOLD_PCT = 40; // matches VOLUME_SPIKE_THRESHOLD in index.html

function isOverreachedWeek(lifts, todayDate) {
  const currentWeekStart = getWeekStartUTC(todayDate);
  const weekVolumes = {};
  for (const l of lifts) {
    const wk = getWeekStartUTC(l.date);
    weekVolumes[wk] = (weekVolumes[wk] || 0) + l.weight * totalReps(l);
  }
  const currentWeekVolume = weekVolumes[currentWeekStart] || 0;
  const priorWeekStarts = Object.keys(weekVolumes).filter((wk) => wk < currentWeekStart).sort().slice(-4);
  if (priorWeekStarts.length < 2 || currentWeekVolume === 0) return false;
  const trailing4wkAvg = priorWeekStarts.reduce((s, wk) => s + weekVolumes[wk], 0) / priorWeekStarts.length;
  if (trailing4wkAvg <= 0) return false;
  const pctIncrease = ((currentWeekVolume - trailing4wkAvg) / trailing4wkAvg) * 100;
  return pctIncrease >= LOAD_SPIKE_THRESHOLD_PCT;
}

// ── Item 4, insight 2: "good day for a PR" ───────────────────────────────
// A conservative composite, not a prediction: for each exercise with
// enough history, flags it as PR-favorable only when (a) its own recent
// trend isn't plateaued, (b) the user isn't in a load-spike week (not
// overreached), and (c) protein goal was hit on >=2 of the last 3 logged
// days (a fueling/recovery proxy — the only "recovery signal" reliably
// available without real recovery tracking).
function computeGoodDayForPR(lifts, foodLogs, proteinGoal, overreached, todayDate) {
  const proteinByDay = {};
  for (const f of foodLogs) {
    const day = (f.logged_at || '').slice(0, 10);
    if (!day) continue;
    proteinByDay[day] = (proteinByDay[day] || 0) + (Number(f.protein_g) || 0);
  }
  const recentDays = Object.keys(proteinByDay).sort().slice(-3);
  const proteinHitDays = recentDays.filter((d) => proteinGoal && proteinByDay[d] >= proteinGoal).length;
  const fueledUp = recentDays.length >= 2 && proteinHitDays >= 2;

  const byExercise = {};
  for (const l of lifts) (byExercise[l.exercise] = byExercise[l.exercise] || []).push(l);

  const exercises = [];
  if (!overreached && fueledUp) {
    for (const [exercise, history] of Object.entries(byExercise)) {
      const trend = summarizeExerciseTrend(history.filter((l) => l.date <= todayDate));
      if (trend && !trend.plateaued) exercises.push(exercise);
    }
  }
  return { flagged: exercises.length > 0, exercises };
}

// ── Item 4, insight 3: macro timing adherence ────────────────────────────
// No existing in-app education content defines a pre/post-workout timing
// window (checked — there isn't one), so this proposes one: protein logged
// within 2 hours before a session's first set, or within 2 hours after its
// last set. Flagged for review along with the load-spike threshold above.
const TIMING_WINDOW_HOURS = 2;

function computeMacroTimingAdherence(lifts, foodLogs) {
  const sessionsByDate = {};
  for (const l of lifts) {
    if (!l.created_at) continue;
    const d = l.date;
    const t = new Date(l.created_at).getTime();
    if (!sessionsByDate[d]) sessionsByDate[d] = { start: t, end: t };
    else {
      sessionsByDate[d].start = Math.min(sessionsByDate[d].start, t);
      sessionsByDate[d].end = Math.max(sessionsByDate[d].end, t);
    }
  }
  const sessionDates = Object.keys(sessionsByDate).sort().slice(-30);
  if (sessionDates.length < 3) return { hasEnoughData: false };

  const windowMs = TIMING_WINDOW_HOURS * 3600000;
  let preHits = 0, postHits = 0;
  for (const d of sessionDates) {
    const { start, end } = sessionsByDate[d];
    const preHit = foodLogs.some((f) => {
      const t = new Date(f.logged_at).getTime();
      return t <= start && t >= start - windowMs;
    });
    const postHit = foodLogs.some((f) => {
      const t = new Date(f.logged_at).getTime();
      return t >= end && t <= end + windowMs;
    });
    if (preHit) preHits++;
    if (postHit) postHits++;
  }
  return {
    hasEnoughData: true,
    sessionsConsidered: sessionDates.length,
    preWorkoutHitRate: Math.round((preHits / sessionDates.length) * 100),
    postWorkoutHitRate: Math.round((postHits / sessionDates.length) * 100),
    windowHours: TIMING_WINDOW_HOURS,
  };
}

// ── Item 4, insight 4: benchmark pacing ──────────────────────────────────
// A simple lookup table by experience tier (derived from months since the
// earliest logged lift, not self-reported — there's no onboarding field
// for it), not personalized AI. Tiers and "typical" %/month figures are a
// rough rule-of-thumb based on the commonly-described novice/intermediate/
// advanced progression model — flagged for review, easy to retune in the
// TYPICAL_PCT_PER_MONTH table below.
const EXPERIENCE_TIERS = [
  { id: 'beginner', maxMonths: 6, typicalPctPerMonth: 8 },
  { id: 'intermediate', maxMonths: 24, typicalPctPerMonth: 2.5 },
  { id: 'advanced', maxMonths: Infinity, typicalPctPerMonth: 0.75 },
];

function computeBenchmarkPacing(lifts, todayDate) {
  if (!lifts.length) return { hasEnoughData: false };
  const earliestDate = lifts.reduce((min, l) => (l.date < min ? l.date : min), lifts[0].date);
  const monthsTraining = Math.max(1, Math.round((new Date(todayDate) - new Date(earliestDate)) / (1000 * 60 * 60 * 24 * 30)));
  const tier = EXPERIENCE_TIERS.find((t) => monthsTraining <= t.maxMonths);

  const byExercise = {};
  for (const l of lifts) (byExercise[l.exercise] = byExercise[l.exercise] || []).push(l);

  const rates = [];
  for (const sets of Object.values(byExercise)) {
    const sorted = [...sets].sort((a, b) => a.date.localeCompare(b.date));
    const first = sorted[0], last = sorted[sorted.length - 1];
    const daysSpan = (new Date(last.date) - new Date(first.date)) / 86400000;
    if (daysSpan < 30) continue;
    const firstE1RM = e1RM(first.weight, first.reps);
    const lastE1RM = e1RM(last.weight, last.reps);
    if (firstE1RM <= 0) continue;
    const monthsSpan = daysSpan / 30;
    rates.push(((lastE1RM - firstE1RM) / firstE1RM / monthsSpan) * 100);
  }
  if (!rates.length) return { hasEnoughData: false, tier: tier.id, monthsTraining };

  const userPctPerMonth = Math.round((rates.reduce((a, b) => a + b, 0) / rates.length) * 10) / 10;
  const typical = tier.typicalPctPerMonth;
  const verdict = userPctPerMonth > typical * 1.2 ? 'faster' : userPctPerMonth < typical * 0.8 ? 'slower' : 'typical';
  return { hasEnoughData: true, tier: tier.id, monthsTraining, userPctPerMonth, typicalPctPerMonth: typical, verdict };
}

// ── Item 4, insight 5: sleep-performance flag ────────────────────────────
// Same "co-movement" technique as index.html's existing nutrition×training
// correlation chart (findCorrelatedDips) rather than a real statistical
// correlation: bucket sessions by whether the night's sleep was below a
// threshold, then compare average session volume between buckets. 7 hours
// is a widely-cited general sleep guideline, not a personalized number —
// flagged for review, same as everything else proposed in this file.
const LOW_SLEEP_THRESHOLD_HOURS = 7;

function computeSleepPerformance(lifts, sleepLog) {
  const sleepByDate = {};
  for (const s of sleepLog) sleepByDate[s.logged_date] = s.hours;

  const volumeByDate = {};
  for (const l of lifts) volumeByDate[l.date] = (volumeByDate[l.date] || 0) + l.weight * totalReps(l);

  const lowSleepVolumes = [], normalSleepVolumes = [];
  for (const [date, volume] of Object.entries(volumeByDate)) {
    const hours = sleepByDate[date];
    if (hours == null) continue;
    (hours < LOW_SLEEP_THRESHOLD_HOURS ? lowSleepVolumes : normalSleepVolumes).push(volume);
  }
  if (lowSleepVolumes.length < 3 || normalSleepVolumes.length < 3) return { hasEnoughData: false };

  const avg = (arr) => arr.reduce((a, b) => a + b, 0) / arr.length;
  const lowAvg = avg(lowSleepVolumes), normalAvg = avg(normalSleepVolumes);
  if (normalAvg <= 0) return { hasEnoughData: false };
  const pctDiff = Math.round(((lowAvg - normalAvg) / normalAvg) * 100);
  return {
    hasEnoughData: true,
    lowSleepSessionAvgVolume: Math.round(lowAvg),
    normalSleepSessionAvgVolume: Math.round(normalAvg),
    pctDiff,
    flagged: pctDiff <= -15,
  };
}

async function listActiveUserIds(serviceHeaders, sinceDate) {
  const res = await fetch(
    `${process.env.SUPABASE_URL}/rest/v1/lifts?date=gte.${sinceDate}&select=user_id`,
    { headers: serviceHeaders }
  );
  if (!res.ok) throw new Error('Could not list active users: ' + (await res.text()));
  const rows = await res.json();
  return Array.from(new Set(rows.map((r) => r.user_id)));
}

async function fetchUserData(serviceHeaders, userId) {
  const base = process.env.SUPABASE_URL;
  const [liftsRes, foodLogsRes, goalsRes, sleepRes] = await Promise.all([
    fetch(`${base}/rest/v1/lifts?user_id=eq.${userId}&select=exercise,date,weight,reps,sets,reps_per_set,created_at`, { headers: serviceHeaders }),
    fetch(`${base}/rest/v1/food_logs?user_id=eq.${userId}&select=protein_g,logged_at`, { headers: serviceHeaders }),
    fetch(`${base}/rest/v1/goals?user_id=eq.${userId}&select=protein_g`, { headers: serviceHeaders }),
    fetch(`${base}/rest/v1/sleep_log?user_id=eq.${userId}&select=logged_date,hours`, { headers: serviceHeaders }),
  ]);
  return {
    lifts: liftsRes.ok ? await liftsRes.json() : [],
    foodLogs: foodLogsRes.ok ? await foodLogsRes.json() : [],
    proteinGoal: goalsRes.ok ? (await goalsRes.json())[0]?.protein_g || 0 : 0,
    sleepLog: sleepRes.ok ? await sleepRes.json() : [],
  };
}

exports.handler = withErrorReporting(async () => {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return { statusCode: 200, body: 'Training insights not configured; skipping.' };
  }

  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  const todayDate = utcDateStr(new Date());
  const fourteenDaysAgo = utcDateStr(new Date(Date.now() - 14 * 86400000));

  try {
    const userIds = await listActiveUserIds(serviceHeaders, fourteenDaysAgo);
    let computed = 0;
    for (const userId of userIds) {
      try {
        const { lifts, foodLogs, proteinGoal, sleepLog } = await fetchUserData(serviceHeaders, userId);
        if (!lifts.length) continue;

        const overreached = isOverreachedWeek(lifts, todayDate);
        const insights = {
          goodDayForPR: computeGoodDayForPR(lifts, foodLogs, proteinGoal, overreached, todayDate),
          macroTiming: computeMacroTimingAdherence(lifts, foodLogs),
          benchmarkPacing: computeBenchmarkPacing(lifts, todayDate),
          sleepPerformance: computeSleepPerformance(lifts, sleepLog),
        };

        await fetch(`${process.env.SUPABASE_URL}/rest/v1/training_insights`, {
          method: 'POST',
          headers: { ...serviceHeaders, Prefer: 'resolution=merge-duplicates' },
          body: JSON.stringify({ user_id: userId, computed_at: new Date().toISOString(), insights }),
        });
        computed++;
      } catch (err) {
        await captureError(err, { function: 'compute-training-insights', userId });
      }
    }
    return { statusCode: 200, body: JSON.stringify({ activeUsers: userIds.length, computed }) };
  } catch (err) {
    await captureError(err, { function: 'compute-training-insights' });
    return { statusCode: 500, body: 'Error computing training insights.' };
  }
}, 'compute-training-insights');
