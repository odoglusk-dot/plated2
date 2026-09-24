// POST { sessionSummary: string, dataSummary: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Same client-builds-the-summary design as ask-data.js: the client already
// has state.lifts/state.historyLogs loaded and RLS-scoped, so it formats
// the session + comparison history + light nutrition context as text and
// sends it here rather than this function querying Supabase itself.
//
// Training-only, no open-ended chat — unlike ask-data.js this never takes
// a free-text question. It's always "analyze this specific session," and
// always returns strict JSON (summary + callouts + which exercise, if any,
// is worth a trend chart) so the client can render structured cards and
// charts instead of a wall of prose. The client renders every chart itself
// from real logged data; this function only decides what's worth
// highlighting and writes the explanation, never generates a chart image.
const { jsonResponse, verifyUser, hasPaidAccess, checkAndIncrementRateLimit, callAnthropic, recordUsageCost, extractJSON, captureError, withErrorReporting } = require('./_shared');

const SYSTEM_PROMPT = (dataSummary) => `You are Krafft's post-workout analyst. You write a short, plain-language
note about a single training session, compared against the user's own recent history for the same lifts — the
tone of a knowledgeable coach texting a quick note after practice, not a clinical report. Use ONLY the data
below; never invent numbers that aren't in it.

Respond with ONLY a JSON object in exactly this shape, no other text before or after it:
{
  "summary": "2-4 short plain-language sentences covering the session as a whole",
  "callouts": [{"type": "pr" | "plateau" | "strong" | "weak" | "nutrition", "text": "one short sentence"}],
  "highlightExercise": "exact exercise name string from the data, or null"
}

Guidelines:
- Plain language — no jargon a beginner wouldn't recognize.
- If a lift in today's session is a personal record, say so plainly and specifically (the weight, the exercise).
- If a lift is flagged as plateaued in the data, mention it gently and suggest cutting volume/intensity for a
  week rather than pushing harder — don't be alarmist about it.
- Only include a "nutrition" callout if the data actually shows something notable (e.g. protein clearly missed
  the day before this session) — omit it entirely otherwise. Don't force a nutrition comment into every session.
- "highlightExercise" should be the one exercise from today's session most worth a trend chart — normally
  whichever one drove a "pr" or "plateau" callout. Use the exact exercise name string as given below. Use null
  if nothing in the session is distinctive enough to chart.
- 0-3 callouts total. Fewer, sharper callouts beat a wall of text.

DATA:
${dataSummary}`;

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  if (!(await hasPaidAccess(auth.user.id, auth.token))) {
    return jsonResponse(402, { error: 'Post-session analysis is a paid feature — start your free trial or subscribe to use it.', upgradeRequired: true });
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const dataSummary = (payload.dataSummary || '').trim();
  if (!dataSummary) return jsonResponse(400, { error: 'Missing "dataSummary".' });
  if (dataSummary.length > 8000) return jsonResponse(400, { error: 'Data summary too long.' });

  const rateLimit = await checkAndIncrementRateLimit(auth.user.id, auth.token);
  if (!rateLimit.ok) return jsonResponse(rateLimit.status || 500, { error: rateLimit.message });

  try {
    const { text, model, inputTokens, outputTokens } = await callAnthropic({
      system: SYSTEM_PROMPT(dataSummary),
      messages: [{ role: 'user', content: 'Analyze this session.' }],
      maxTokens: 600,
    });
    await recordUsageCost(auth.user.id, auth.token, { model, inputTokens, outputTokens });

    let analysis;
    try {
      analysis = extractJSON(text);
    } catch {
      return jsonResponse(502, { error: 'Could not parse the analysis. Please try again.' });
    }

    return jsonResponse(200, { analysis, remaining: rateLimit.remaining });
  } catch (err) {
    await captureError(err, { function: 'analyze-session', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not generate the analysis right now.', detail: String(err.message || err) });
  }
}, 'analyze-session');
