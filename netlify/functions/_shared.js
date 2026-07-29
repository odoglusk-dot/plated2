// Shared helpers for Plated's Netlify functions. No npm dependencies —
// everything talks to Supabase over plain REST (Auth + PostgREST) using the
// global `fetch` available in the Node 18+ Netlify Functions runtime, so
// there's no bundling/dependency-install step to break.

const DAILY_AI_LIMIT = 20;

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
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': process.env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-5',
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
  return textBlock ? textBlock.text : '';
}

module.exports = {
  DAILY_AI_LIMIT,
  jsonResponse,
  verifyUser,
  checkAndIncrementRateLimit,
  callAnthropic,
};
