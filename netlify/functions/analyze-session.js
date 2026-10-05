// POST { weightUnit: 'lb'|'kg', todayDate: string, todayLifts: [...], priorLifts: [...], nutritionYesterday: {...}|null }
// Auth: Authorization: Bearer <supabase access token>
//
// Item 2 of the AI cost-efficiency batch: the CLIENT still owns data access
// (state.lifts/state.historyLogs, already fetched and RLS-scoped — this
// function still never queries Supabase itself, same reasoning as
// ask-data.js), but now sends raw-ish structured lift/nutrition rows
// instead of a pre-formatted prose summary. The SERVER computes the actual
// data summary (PR flags, a numeric 1RM trend %, a volume-vs-recent-average
// comparison, plateau detection) via buildSessionAnalysisSummary() in
// _shared.js before calling Anthropic — replacing what used to be up to 5
// raw historical rows per exercise enumerated as text with a few computed
// lines, which cuts tokens sent to the model without losing any of the
// analytical coverage the old prose carried (if anything it's a bit
// richer: the old version never compared today's volume against anything).
//
// Training-only, no open-ended chat — unlike ask-data.js this never takes
// a free-text question. It's always "analyze this specific session," and
// always returns strict JSON (summary + callouts + which exercise, if any,
// is worth a trend chart) so the client can render structured cards and
// charts instead of a wall of prose. The client renders every chart itself
// from real logged data; this function only decides what's worth
// highlighting and writes the explanation, never generates a chart image.
const { jsonResponse, verifyUser, hasPaidAccess, checkAndIncrementFeatureLimit, callAnthropic, recordUsageCost, extractJSON, buildSessionAnalysisSummary, captureError, withErrorReporting } = require('./_shared');

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

  const { weightUnit, todayDate, todayLifts, priorLifts, nutritionYesterday } = payload;
  if (typeof todayDate !== 'string' || !todayDate) return jsonResponse(400, { error: 'Missing "todayDate".' });
  if (!Array.isArray(todayLifts) || todayLifts.length === 0) return jsonResponse(400, { error: 'Missing "todayLifts".' });
  if (todayLifts.length > 100) return jsonResponse(400, { error: 'Too many lifts in today\'s session.' });
  if (priorLifts !== undefined && (!Array.isArray(priorLifts) || priorLifts.length > 5000)) {
    return jsonResponse(400, { error: 'Invalid "priorLifts".' });
  }
  const isValidLift = (l) => l && typeof l.exercise === 'string' && l.exercise.length <= 100 && typeof l.weight === 'number';
  if (!todayLifts.every(isValidLift) || !(priorLifts || []).every(isValidLift)) {
    return jsonResponse(400, { error: 'Invalid lift data.' });
  }

  const dataSummary = buildSessionAnalysisSummary({
    weightUnit: weightUnit === 'kg' ? 'kg' : 'lb',
    todayDate,
    todayLifts,
    priorLifts: priorLifts || [],
    nutritionYesterday: nutritionYesterday || null,
  });

  // Item 5 of the AI cost-efficiency batch: capped at 2/day, but a soft cap
  // rather than a hard block — ending/reopening/re-ending the same day's
  // workout past the 2nd analysis must NOT error or wipe out whichever
  // analysis was last generated that day. Returns 200 with capped:true
  // instead of an error status so the client knows to leave the existing
  // analysis exactly as it is and just show a small fine-print note,
  // distinct from Photo/Ask AI's hard-block pattern above.
  const rateLimit = await checkAndIncrementFeatureLimit(auth.user.id, auth.token, 'analysis');
  if (!rateLimit.ok) {
    if (rateLimit.capped) return jsonResponse(200, { capped: true, message: rateLimit.message });
    return jsonResponse(rateLimit.status || 500, { error: rateLimit.message });
  }

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
