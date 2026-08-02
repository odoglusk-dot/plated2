// Shared helpers for Plated's Netlify functions. No npm dependencies —
// everything talks to Supabase over plain REST (Auth + PostgREST) using the
// global `fetch` available in the Node 18+ Netlify Functions runtime, so
// there's no bundling/dependency-install step to break.

const DAILY_AI_LIMIT = 13;

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

async function callAnthropic({ system, messages, maxTokens = 500 }) {
  const model = 'claude-sonnet-5';
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
async function cacheFood(description, { food_name, calories, protein_g, carbs_g, fat_g }) {
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
      }),
    });
  } catch {
    // Cache write failure is non-fatal; proceed anyway.
  }
}

module.exports = {
  DAILY_AI_LIMIT,
  jsonResponse,
  verifyUser,
  checkAndIncrementRateLimit,
  callAnthropic,
  calculateCost,
  recordUsageCost,
  extractJSON,
  getCacheKey,
  getPhotoCacheKey,
  checkFoodCache,
  cacheFood,
};
