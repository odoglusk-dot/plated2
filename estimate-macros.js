// netlify/functions/estimate-macros.js
//
// This runs on Netlify's servers, not in the visitor's browser — so it's the only
// place your Anthropic API key should ever live. Set ANTHROPIC_API_KEY, plus
// SUPABASE_URL and SUPABASE_ANON_KEY, in Site settings > Environment variables.
//
// It also verifies the caller is a real signed-in Supabase user before spending
// any API budget — without this, anyone who finds this URL could call it directly
// (not through your page at all) and rack up charges on your Anthropic account.
async function verifySupabaseUser(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length);
  const resp = await fetch(`${process.env.SUPABASE_URL}/auth/v1/user`, {
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: process.env.SUPABASE_ANON_KEY,
    },
  });
  if (!resp.ok) return null;
  const user = await resp.json();
  return user && user.id ? user : null;
}
exports.handler = async function (event) {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }
  const user = await verifySupabaseUser(event.headers.authorization || event.headers.Authorization);
  if (!user) {
    return { statusCode: 401, body: JSON.stringify({ error: 'Sign in required' }) };
  }
  let food, serving;
  try {
    const parsedBody = JSON.parse(event.body || '{}');
    food = parsedBody.food;
    serving = parsedBody.serving;
  } catch (err) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Invalid request body' }) };
  }
  if (!food || typeof food !== 'string') {
    return { statusCode: 400, body: JSON.stringify({ error: 'Missing food' }) };
  }
  const promptText = `Estimate the nutrition for this food: "${food}"${
    serving ? ` with serving size: "${serving}"` : ' using a standard typical serving size'
  }. Respond with ONLY a raw JSON object, no markdown formatting, no code fences, no explanation, in exactly this shape: {"food":"short food name","serving":"serving description","calories":number,"protein":number,"carbs":number,"fat":number}. All numeric fields are grams except calories.`;
  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001', // cheapest current model — plenty for this task
        max_tokens: 300,
        messages: [{ role: 'user', content: promptText }],
      }),
    });
    if (!response.ok) {
      const errText = await response.text();
      return {
        statusCode: 502,
        body: JSON.stringify({ error: 'Anthropic API error', detail: errText }),
      };
    }
    const data = await response.json();
    const text = data.content.map((b) => b.text || '').join('').trim();
    const clean = text.replace(/```json|```/g, '').trim();
    const parsed = JSON.parse(clean);
    if (typeof parsed.protein !== 'number' || typeof parsed.calories !== 'number') {
      throw new Error('Unexpected response shape from model');
    }
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(parsed),
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
