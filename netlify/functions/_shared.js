// Shared helpers for Krafft's Netlify functions. No npm dependencies —
// everything talks to Supabase over plain REST (Auth + PostgREST) using the
// global `fetch` available in the Node 18+ Netlify Functions runtime, so
// there's no bundling/dependency-install step to break.

const crypto = require('crypto');

const DAILY_AI_LIMIT = 13;

// Derives the app's own base URL (scheme + host + subpath, no trailing
// slash) for building post-Stripe redirect URLs. `event.headers.origin`
// alone is only scheme+host — fine when the app is served from a site's
// root, but wrong when it's served from a subpath (e.g. this repo's
// "/plated/" deployment), since it drops the subpath entirely. The
// Referer header carries the full page URL the fetch() came from, so
// prefer parsing that; fall back to bare origin if Referer is missing.
function getAppBaseUrl(event) {
  const referer = event.headers.referer || event.headers.referrer;
  if (referer) {
    try {
      const url = new URL(referer);
      url.pathname = url.pathname.replace(/[^/]*$/, ''); // drop the filename, keep the directory
      url.search = '';
      url.hash = '';
      return url.toString().replace(/\/$/, '');
    } catch {
      // fall through to origin
    }
  }
  const origin = event.headers.origin;
  return origin ? origin.replace(/\/$/, '') : null;
}

// Reports an unexpected server-side error to Sentry, using a hand-rolled
// envelope POST rather than the @sentry/node SDK — this project has no
// npm dependencies / build step, and error reporting must never be the
// thing that breaks a deploy. No-ops silently if SENTRY_DSN isn't set, and
// never throws (a broken error-reporter must never mask the original error).
async function captureError(err, extra = {}) {
  const dsn = process.env.SENTRY_DSN;
  if (!dsn) return;
  try {
    const dsnUrl = new URL(dsn);
    const publicKey = dsnUrl.username;
    const projectId = dsnUrl.pathname.replace(/^\//, '');
    const ingestUrl = `https://${dsnUrl.host}/api/${projectId}/envelope/?sentry_key=${publicKey}&sentry_version=7`;
    const eventId = crypto.randomBytes(16).toString('hex');
    const nowIso = new Date().toISOString();

    const event = {
      event_id: eventId,
      timestamp: nowIso,
      platform: 'node',
      level: 'error',
      environment: process.env.CONTEXT || 'production',
      exception: {
        values: [{
          type: (err && err.name) || 'Error',
          value: String((err && err.message) || err),
          stacktrace: err && err.stack
            ? { frames: err.stack.split('\n').slice(1).map((line) => ({ filename: line.trim() })).reverse() }
            : undefined,
        }],
      },
      extra,
    };

    const envelope = [
      JSON.stringify({ event_id: eventId, sent_at: nowIso }),
      JSON.stringify({ type: 'event' }),
      JSON.stringify(event),
    ].join('\n');

    await fetch(ingestUrl, {
      method: 'POST',
      headers: { 'content-type': 'application/x-sentry-envelope' },
      body: envelope,
    });
  } catch {
    // Reporting the error must never itself throw.
  }
}

// Minimal Stripe REST client — no `stripe` npm SDK, matching this project's
// zero-dependency style. `params` (form-encoded, Stripe's classic format;
// supports its bracket notation for nested fields) is omitted for GET.
async function callStripe(path, { method = 'POST', params } = {}) {
  const headers = { Authorization: `Bearer ${process.env.STRIPE_SECRET_KEY}` };
  let body;
  if (params) {
    const form = new URLSearchParams();
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null) form.append(key, value);
    }
    body = form.toString();
    headers['content-type'] = 'application/x-www-form-urlencoded';
  }
  const res = await fetch(`https://api.stripe.com/v1/${path}`, { method, headers, body });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(data.error?.message || `Stripe API error (${res.status})`);
    err.stripeStatus = res.status;
    err.stripeError = data.error;
    throw err;
  }
  return data;
}

// Wraps a handler so ANY uncaught exception — including ones from code paths
// that don't have their own try/catch, which is a bug, not a design choice —
// still gets reported to Sentry before the client gets a response. Handlers
// keep their own try/catch blocks for cases that want a specific status code
// or a friendlier error message; this is the backstop for everything else.
function withErrorReporting(fn, functionName) {
  return async (event, context) => {
    try {
      return await fn(event, context);
    } catch (err) {
      await captureError(err, { function: functionName });
      return jsonResponse(500, { error: 'Something went wrong. Please try again.' });
    }
  };
}

function jsonResponse(statusCode, body) {
  return {
    statusCode,
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  };
}

// Verifies the bearer token against Supabase Auth and returns the user
// object, or null if the token is missing/invalid.
async function verifyUser(event) {
  const authHeader = event.headers.authorization || event.headers.Authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length);

  const res = await fetch(`${process.env.SUPABASE_URL}/auth/v1/user`, {
    headers: {
      apikey: process.env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${token}`,
    },
  });
  if (!res.ok) return null;
  const user = await res.json();
  if (!user || !user.id) return null;
  return { user, token };
}

// Server-side gate for AI features. Never trust the client alone for this —
// a free user's browser could call these functions directly with their own
// valid session token, bypassing any client-side-only check. Mirrors the
// same trialing/active check the client uses for its own upgrade prompts
// (see hasAccess() in index.html), read via the caller's own token against
// the "select own" RLS policy on subscriptions, same pattern as the rest of
// this file's Supabase reads.
async function hasPaidAccess(userId, token) {
  const base = process.env.SUPABASE_URL;
  const res = await fetch(
    `${base}/rest/v1/subscriptions?user_id=eq.${userId}&select=status`,
    { headers: { apikey: process.env.SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` } }
  );
  if (!res.ok) return false;
  const rows = await res.json().catch(() => []);
  const status = rows[0]?.status;
  return status === 'trialing' || status === 'active';
}

// Checks + increments today's AI usage count for this user, scoped by
// user_id (not browser/device) via RLS using the user's own JWT — so
// switching devices or clearing local storage can't reset the cap.
async function checkAndIncrementRateLimit(userId, token) {
  const today = new Date().toISOString().slice(0, 10);
  const base = process.env.SUPABASE_URL;
  const headers = {
    apikey: process.env.SUPABASE_ANON_KEY,
    Authorization: `Bearer ${token}`,
    'content-type': 'application/json',
  };

  const getRes = await fetch(
    `${base}/rest/v1/ai_usage?user_id=eq.${userId}&usage_date=eq.${today}&select=count`,
    { headers }
  );
  if (!getRes.ok) return { ok: false, message: 'Could not check usage limit.' };
  const rows = await getRes.json();
  const currentCount = rows.length ? rows[0].count : 0;

  if (currentCount >= DAILY_AI_LIMIT) {
    return {
      ok: false,
      status: 429,
      message: `Daily AI limit reached (${DAILY_AI_LIMIT}/day). Try again tomorrow, or log foods manually in the meantime.`,
    };
  }

  const upsertRes = await fetch(`${base}/rest/v1/ai_usage`, {
    method: 'POST',
    headers: { ...headers, Prefer: 'resolution=merge-duplicates' },
    body: JSON.stringify({ user_id: userId, usage_date: today, count: currentCount + 1 }),
  });
  if (!upsertRes.ok) return { ok: false, message: 'Could not record usage.' };

  return { ok: true, remaining: DAILY_AI_LIMIT - (currentCount + 1) };
}

// Item 5 of the AI cost-efficiency batch: independent daily caps per AI
// feature, instead of every feature sharing DAILY_AI_LIMIT's one pool.
// Describe It (estimate-macros.js) is intentionally left on the original
// shared checkAndIncrementRateLimit()/DAILY_AI_LIMIT — nothing in that
// batch asked for it to change, so it keeps working exactly as it does
// today. Each feature here gets its own column on the same ai_usage row
// (one row per user per day already existed) rather than a new table,
// since this is the same "per-user-per-day usage ledger" the shared
// counter already is.
const FEATURE_DAILY_LIMITS = { photo: 20, analysis: 2, ask: 5 };
const FEATURE_LABELS = { photo: 'Photo logging', analysis: 'Post-session analysis', ask: 'Ask AI' };

async function checkAndIncrementFeatureLimit(userId, token, feature) {
  const dailyLimit = FEATURE_DAILY_LIMITS[feature];
  const column = `${feature}_count`;
  const today = new Date().toISOString().slice(0, 10);
  const base = process.env.SUPABASE_URL;
  const headers = {
    apikey: process.env.SUPABASE_ANON_KEY,
    Authorization: `Bearer ${token}`,
    'content-type': 'application/json',
  };

  const getRes = await fetch(
    `${base}/rest/v1/ai_usage?user_id=eq.${userId}&usage_date=eq.${today}&select=${column}`,
    { headers }
  );
  if (!getRes.ok) return { ok: false, message: 'Could not check usage limit.' };
  const rows = await getRes.json();
  const currentCount = rows.length ? rows[0][column] : 0;

  if (currentCount >= dailyLimit) {
    return {
      ok: false,
      status: 429,
      capped: true,
      message: `${FEATURE_LABELS[feature]} limit reached (${dailyLimit}/day) — resets tomorrow.`,
    };
  }

  const upsertRes = await fetch(`${base}/rest/v1/ai_usage`, {
    method: 'POST',
    headers: { ...headers, Prefer: 'resolution=merge-duplicates' },
    body: JSON.stringify({ user_id: userId, usage_date: today, [column]: currentCount + 1 }),
  });
  if (!upsertRes.ok) return { ok: false, message: 'Could not record usage.' };

  return { ok: true, remaining: dailyLimit - (currentCount + 1) };
}

// Item 6 of the conversion-surface-area batch: a highly engaged free user
// (10-day logging streak, checked client-side before ever reaching this
// endpoint) gets exactly one real AI photo-log result as a preview. The
// "exactly one" part has to be enforced here, not just client-side, since
// the whole point is that it can't be replayed for unlimited free photos.
// A conditional PATCH (pro_preview_used_at=is.null) claims it atomically —
// Postgres evaluates the WHERE clause and the SET in one statement, so two
// concurrent requests can't both see it unclaimed and both win.
async function claimOneTimeProPreview(userId, token) {
  const base = process.env.SUPABASE_URL;
  const res = await fetch(
    `${base}/rest/v1/profiles?id=eq.${userId}&pro_preview_used_at=is.null`,
    {
      method: 'PATCH',
      headers: {
        apikey: process.env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${token}`,
        'content-type': 'application/json',
        Prefer: 'return=representation',
      },
      body: JSON.stringify({ pro_preview_used_at: new Date().toISOString() }),
    }
  );
  if (!res.ok) return false;
  const rows = await res.json().catch(() => []);
  return rows.length > 0;
}

// ── Lift math ─────────────────────────────────────────────────────────────
// Shared by analyze-session.js (item 2 of the AI cost-efficiency batch —
// the server now computes the session-analysis data summary itself instead
// of forwarding client-built prose) and compute-training-insights.js (items
// 3+4 — the nightly rule-based insights need the same PR/trend math).
// Ported from the equivalent client-side functions in index.html
// (e1RM/totalReps/computeLiftPRs/detectPlateau) — kept numerically
// identical to them so a lift's PR/plateau status reads the same whether
// it's shown live in the app or referenced in an AI-written analysis.
function e1RM(weight, reps) {
  if (!weight || !reps || reps <= 0) return 0;
  if (reps === 1) return Math.round(weight);
  return Math.round(weight * (1 + reps / 30));
}

function totalReps(l) {
  if (l.reps_per_set && l.reps_per_set.length) return l.reps_per_set.reduce((a, b) => a + b, 0);
  return (l.sets || 0) * (l.reps || 0);
}

function computeLiftPRs(lifts) {
  const prs = {};
  for (const l of lifts) {
    if (!prs[l.exercise] || l.weight > prs[l.exercise].weight) prs[l.exercise] = l;
  }
  return prs;
}

// Generalizes the client's detectPlateau(): same "best e1RM of the last 3
// sessions vs best of everything before that" windowing, but returns the %
// change too instead of just a boolean, so an analysis can say *how much*
// trending up/down rather than only yes/no. Returns null when there isn't
// enough history (same < 4 total entries threshold as detectPlateau).
function summarizeExerciseTrend(history) {
  if (history.length < 4) return null;
  const sorted = [...history].sort((a, b) => new Date(`${a.date}T00:00:00`) - new Date(`${b.date}T00:00:00`));
  const withE1RM = sorted.map((l) => ({ ...l, e1rm: e1RM(l.weight, l.reps) }));
  const recent = withE1RM.slice(-3);
  const prior = withE1RM.slice(0, -3);
  if (prior.length === 0) return null;
  const priorBest = Math.max(...prior.map((l) => l.e1rm));
  const recentBest = Math.max(...recent.map((l) => l.e1rm));
  const pctChange = priorBest > 0 ? Math.round(((recentBest - priorBest) / priorBest) * 100) : 0;
  return { plateaued: recentBest <= priorBest, priorBest, recentBest, pctChange };
}

function round1(n) { return Math.round(n * 10) / 10; }

// Builds the final, token-tight text sent to the Anthropic call in
// analyze-session.js. Takes raw-ish structured lift/nutrition data the
// client already fetched (RLS-scoped, same "client owns data access"
// principle as before — only the SUMMARIZATION moves server-side, not the
// querying) and computes PR flags, a numeric 1RM trend %, a volume-vs-
// recent-average comparison, and a plateau flag — instead of the client
// enumerating up to 5 raw historical rows per exercise for the model to
// infer a trend from itself. Today's own sets are kept in full (that's the
// actual subject being analyzed, not prunable history).
function buildSessionAnalysisSummary({ weightUnit, todayDate, todayLifts, priorLifts, nutritionYesterday }) {
  const unit = weightUnit === 'kg' ? 'kg' : 'lb';
  const toUnit = (lb) => (weightUnit === 'kg' ? round1(lb * 0.453592) : Math.round(lb));
  const lines = [`Session date: ${todayDate}`, '', "Today's session:"];

  const byExercise = {};
  for (const l of todayLifts) (byExercise[l.exercise] = byExercise[l.exercise] || []).push(l);
  const priorPRs = computeLiftPRs(priorLifts);

  for (const [exercise, sets] of Object.entries(byExercise)) {
    const best = sets.reduce((max, l) => Math.max(max, l.weight), 0);
    const volume = sets.reduce((sum, l) => sum + l.weight * totalReps(l), 0);
    lines.push(`- ${exercise}: ${sets.length} set(s), best weight ${toUnit(best)}${unit}, session volume ${toUnit(volume)}${unit}`);
    sets.forEach((l) => {
      const repsStr = l.reps_per_set && l.reps_per_set.length ? `${l.reps_per_set.join('/')} reps` : `${l.reps} reps × ${l.sets} sets`;
      lines.push(`    ${toUnit(l.weight)}${unit} x ${repsStr}`);
    });

    const prior = priorPRs[exercise];
    lines.push(`  PR flag: ${!prior ? 'first time this exercise has been logged' : best > prior.weight ? `yes — new best, prior best was ${toUnit(prior.weight)}${unit}` : 'no'}`);

    const history = priorLifts.filter((l) => l.exercise === exercise).sort((a, b) => a.date.localeCompare(b.date));
    if (history.length) {
      // Volume comparison against this exercise's last 5 sessions — a
      // comparison the original client-built prose never made at all.
      const recentDates = Array.from(new Set(history.slice(-5).map((l) => l.date)));
      const recentVolumes = recentDates.map((d) => history.filter((l) => l.date === d).reduce((sum, l) => sum + l.weight * totalReps(l), 0));
      const avgVolume = recentVolumes.reduce((a, b) => a + b, 0) / recentVolumes.length;
      if (avgVolume > 0) {
        const pctVsAvg = Math.round(((volume - avgVolume) / avgVolume) * 100);
        lines.push(`  Volume vs recent avg: ${pctVsAvg >= 0 ? '+' : ''}${pctVsAvg}% (recent avg ${toUnit(avgVolume)}${unit})`);
      }

      // Bounded to the last 8 prior entries for the trend/plateau calc —
      // same recency-focused spirit as the original's 5-entry window, so a
      // PR from years ago doesn't dominate "plateaued" forever.
      const recentHistory = history.slice(-8).map((l) => ({ ...l }));
      const trend = summarizeExerciseTrend([...recentHistory, ...sets.map((s) => ({ ...s, date: todayDate }))]);
      if (trend) {
        lines.push(`  Trend: estimated 1RM ${trend.pctChange >= 0 ? 'up' : 'down'} ${Math.abs(trend.pctChange)}% over the last 3 sessions vs before that (${toUnit(trend.priorBest)} -> ${toUnit(trend.recentBest)}${unit})`);
        lines.push(`  Plateau flag: ${trend.plateaued ? 'yes — best estimated 1RM in the last 3 sessions has not beaten the prior best' : 'no'}`);
      } else {
        lines.push('  Plateau flag: no (not enough history yet to tell)');
      }
    } else {
      lines.push('  No prior logged history for this exercise.');
    }
  }

  lines.push('', 'Nutrition context (the day before this session):');
  if (nutritionYesterday) {
    lines.push(`${nutritionYesterday.date}: ${Math.round(nutritionYesterday.calories)} kcal (goal ${Math.round(nutritionYesterday.calorieGoal)}), protein ${Math.round(nutritionYesterday.protein_g)}g (goal ${Math.round(nutritionYesterday.proteinGoal)}g)`);
  } else {
    lines.push('No food logged the day before this session.');
  }

  return lines.join('\n').slice(0, 7000);
}

async function callAnthropic({ system, messages, maxTokens = 500, model = 'claude-sonnet-5' }) {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': process.env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      system,
      messages,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Anthropic API error (${res.status}): ${errText}`);
  }

  const data = await res.json();
  const textBlock = (data.content || []).find((b) => b.type === 'text');
  const usage = data.usage || {};
  return {
    text: textBlock ? textBlock.text : '',
    // Echo back whatever model actually served the request (not just what we asked
    // for) so cost tracking stays correct even if that ever diverges.
    model: data.model || model,
    inputTokens: usage.input_tokens || 0,
    outputTokens: usage.output_tokens || 0,
  };
}

// $/MTok by model. Sonnet 5 has introductory pricing through 2026-08-31 —
// this table switches to standard pricing automatically after that date.
function getPricingTable() {
  const sonnetIsIntro = new Date() < new Date('2026-09-01T00:00:00Z');
  return {
    'claude-haiku-4-5': { input: 1.0, output: 5.0 },
    'claude-sonnet-5': sonnetIsIntro ? { input: 2.0, output: 10.0 } : { input: 3.0, output: 15.0 },
    'claude-opus-5': { input: 5.0, output: 25.0 },
  };
}

// Looks up the actual model returned by Anthropic (which may carry a date
// suffix) against our known-model prefixes, so cost tracking is correct per
// call even if different functions end up on different models.
function calculateCost(model, inputTokens, outputTokens) {
  const pricing = getPricingTable();
  const key = Object.keys(pricing).find((k) => model && model.startsWith(k));
  const rate = pricing[key] || pricing['claude-sonnet-5'];
  return (inputTokens / 1e6) * rate.input + (outputTokens / 1e6) * rate.output;
}

// Accumulates today's real token usage + cost onto the ai_usage row that
// checkAndIncrementRateLimit already created for this user/day. Read-then-upsert
// so repeated calls in the same day add up; `count` is omitted from the upsert
// body so merge-duplicates leaves it untouched.
async function recordUsageCost(userId, token, { model, inputTokens, outputTokens }) {
  const today = new Date().toISOString().slice(0, 10);
  const base = process.env.SUPABASE_URL;
  const headers = {
    apikey: process.env.SUPABASE_ANON_KEY,
    Authorization: `Bearer ${token}`,
    'content-type': 'application/json',
  };
  const costUsd = calculateCost(model, inputTokens, outputTokens);

  try {
    const getRes = await fetch(
      `${base}/rest/v1/ai_usage?user_id=eq.${userId}&usage_date=eq.${today}&select=input_tokens,output_tokens,estimated_cost_usd`,
      { headers }
    );
    if (!getRes.ok) return;
    const rows = await getRes.json();
    const prev = rows[0] || { input_tokens: 0, output_tokens: 0, estimated_cost_usd: 0 };

    await fetch(`${base}/rest/v1/ai_usage`, {
      method: 'POST',
      headers: { ...headers, Prefer: 'resolution=merge-duplicates' },
      body: JSON.stringify({
        user_id: userId,
        usage_date: today,
        input_tokens: prev.input_tokens + inputTokens,
        output_tokens: prev.output_tokens + outputTokens,
        estimated_cost_usd: Number((Number(prev.estimated_cost_usd) + costUsd).toFixed(6)),
      }),
    });
  } catch {
    // Cost tracking is best-effort; never fail the request over it.
  }
}

// Extracts the last complete JSON object {...} from text.
// Robust against extra text before/after the JSON (e.g. model prefacing output).
function extractJSON(text) {
  const lastBrace = text.lastIndexOf('}');
  if (lastBrace === -1) throw new Error('No JSON object found in response');

  let braceCount = 0;
  let startIdx = -1;
  for (let i = lastBrace; i >= 0; i--) {
    if (text[i] === '}') braceCount++;
    else if (text[i] === '{') {
      braceCount--;
      if (braceCount === 0) {
        startIdx = i;
        break;
      }
    }
  }

  if (startIdx === -1) throw new Error('No complete JSON object found');
  return JSON.parse(text.slice(startIdx, lastBrace + 1));
}

// Generates a normalized cache key from a food description (lowercased, trimmed).
function getCacheKey(description) {
  return description.trim().toLowerCase();
}

// Generates a cache key for photo + optional note (uses simple string hash).
function getPhotoCacheKey(imageBase64, note) {
  // Simple hash of image base64 (first 100 chars + length) + note, to make distinct cache keys.
  // Not a crypto hash, just a deterministic key.
  const imagePrefix = imageBase64.substring(0, 100);
  const imageLength = imageBase64.length;
  const noteStr = (note || '').trim().toLowerCase();
  return `photo:${imageLength}:${imagePrefix}:${noteStr}`.substring(0, 500);
}

// Checks food_cache for an exact-match description. Returns the cached entry if found, null otherwise.
// If isPreGeneratedKey is true, uses the description as-is; otherwise normalizes it with getCacheKey().
async function checkFoodCache(description, isPreGeneratedKey = false) {
  const cacheKey = isPreGeneratedKey ? description : getCacheKey(description);
  try {
    const res = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/food_cache?description_key=eq.${encodeURIComponent(cacheKey)}`,
      {
        headers: {
          apikey: process.env.SUPABASE_ANON_KEY,
          'content-type': 'application/json',
        },
      }
    );
    if (!res.ok) return null;
    const rows = await res.json();
    if (rows.length === 0) return null;
    return rows[0];
  } catch {
    return null;
  }
}

// Stores a food estimate in the shared food_cache table.
async function cacheFood(description, { food_name, calories, protein_g, carbs_g, fat_g, ingredients }) {
  const cacheKey = getCacheKey(description);
  try {
    await fetch(`${process.env.SUPABASE_URL}/rest/v1/food_cache`, {
      method: 'POST',
      headers: {
        apikey: process.env.SUPABASE_ANON_KEY,
        'content-type': 'application/json',
        Prefer: 'resolution=merge-duplicates',
      },
      body: JSON.stringify({
        description_key: cacheKey,
        food_name,
        calories,
        protein_g,
        carbs_g,
        fat_g,
        ingredients: ingredients || null,
      }),
    });
  } catch {
    // Cache write failure is non-fatal; proceed anyway.
  }
}

module.exports = {
  DAILY_AI_LIMIT,
  captureError,
  withErrorReporting,
  callStripe,
  getAppBaseUrl,
  jsonResponse,
  verifyUser,
  hasPaidAccess,
  claimOneTimeProPreview,
  checkAndIncrementRateLimit,
  checkAndIncrementFeatureLimit,
  FEATURE_DAILY_LIMITS,
  e1RM,
  totalReps,
  computeLiftPRs,
  summarizeExerciseTrend,
  buildSessionAnalysisSummary,
  callAnthropic,
  calculateCost,
  recordUsageCost,
  extractJSON,
  getCacheKey,
  getPhotoCacheKey,
  checkFoodCache,
  cacheFood,
};
