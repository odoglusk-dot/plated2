// netlify/functions/ask-data.js
//
// Template for the "Ask Your Data" feature — needs to be wired up the same
// way estimate-macros.js is: verify the caller is a signed-in Supabase user,
// then call Anthropic server-side with the real API key.
//
// NOT YET WIRED TO REAL DATA — the frontend needs to build the data summary
// (query food_logs for this user from Supabase, same shape as the
// buildDataSummary() function in the reference macro-logger.html) and pass
// it in the request body here, rather than the function querying Supabase
// itself (though that's a valid alternative approach — see notes in
// HANDOFF.md under "Ask Your Data").
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
  let question, dataSummary;
  try {
    const parsedBody = JSON.parse(event.body || '{}');
    question = parsedBody.question;
    dataSummary = parsedBody.dataSummary; // pre-built by the frontend from Supabase query results
  } catch (err) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Invalid request body' }) };
  }
  if (!question || !dataSummary) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Missing question or dataSummary' }) };
  }
  const promptText = `Here is a person's logged food-tracking history and daily goals:\n\n${dataSummary}\n\nAnswer this question directly and concisely, using only the data above. If the data doesn't actually contain enough information to answer confidently, say so honestly rather than guessing: "${question}"`;
  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-6',
        max_tokens: 600,
        messages: [{ role: 'user', content: promptText }],
      }),
    });
    if (!response.ok) {
      const errText = await response.text();
      return { statusCode: 502, body: JSON.stringify({ error: 'Anthropic API error', detail: errText }) };
    }
    const data = await response.json();
    const text = data.content.map((b) => b.text || '').join('').trim();
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ answer: text }),
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
