// POST { question: string, dataSummary: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Design decision: the CLIENT builds dataSummary (querying Supabase directly,
// scoped safely by RLS to auth.uid()) and sends the formatted text here. This
// function never touches the database itself — it just verifies the caller is
// signed in, applies the shared AI rate limit, and forwards the question +
// summary to Anthropic. Kept this way (rather than having the function query
// Supabase itself) because the frontend already has the session and the
// query patterns for food_logs/goals/weight_log/supplement_logs in place for
// the Dashboard/History tabs — reusing them here avoids a second, parallel
// data-access path server-side.
const { jsonResponse, verifyUser, checkAndIncrementRateLimit, callAnthropic } = require('./_shared');

const SYSTEM_PROMPT = (dataSummary) => `You are Plated's data assistant. Answer the user's question about
their own logged nutrition/supplement/weight history using ONLY the summary below — never invent numbers
that aren't in it. Be concise and encouraging. You are not a doctor: for anything that sounds like a
medical question, suggest they talk to a doctor or registered dietitian instead of answering it yourself.
If the summary doesn't contain enough information to answer, say so plainly instead of guessing.

DATA SUMMARY:
${dataSummary}`;

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const question = (payload.question || '').trim();
  const dataSummary = (payload.dataSummary || '').trim();
  if (!question) return jsonResponse(400, { error: 'Missing "question".' });
  if (question.length > 500) return jsonResponse(400, { error: 'Question too long.' });
  if (dataSummary.length > 8000) return jsonResponse(400, { error: 'Data summary too long.' });

  const rateLimit = await checkAndIncrementRateLimit(auth.user.id, auth.token);
  if (!rateLimit.ok) return jsonResponse(rateLimit.status || 500, { error: rateLimit.message });

  try {
    const answer = await callAnthropic({
      system: SYSTEM_PROMPT(dataSummary || '(no logged data yet)'),
      messages: [{ role: 'user', content: question }],
      maxTokens: 500,
    });
    return jsonResponse(200, { answer, remaining: rateLimit.remaining });
  } catch (err) {
    return jsonResponse(502, { error: 'Could not get an answer right now.', detail: String(err.message || err) });
  }
};
