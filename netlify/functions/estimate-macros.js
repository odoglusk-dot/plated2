// POST { description: string }
// Auth: Authorization: Bearer <supabase access token>
// Returns { food_name, calories, protein_g, carbs_g, fat_g, confidence }
// Checks food_cache first; if hit, returns immediately without using API budget.
const { jsonResponse, verifyUser, checkAndIncrementRateLimit, callAnthropic, extractJSON, checkFoodCache, cacheFood } = require('./_shared');

const SYSTEM_PROMPT = `You are the nutrition-estimation engine for Plated, a macro-tracking app.
Given a short description of a food or meal, estimate its nutritional content.
Respond with ONLY a JSON object, no markdown fences, no prose, in exactly this shape:
{"food_name": string, "calories": number, "protein_g": number, "carbs_g": number, "fat_g": number, "confidence": "high" | "medium" | "low"}
If the description omits quantity, assume one standard serving and fold that assumption into food_name
(e.g. "Grilled chicken breast (1, ~6oz)"). All numeric fields are grams or kcal with no units attached.
Use standard USDA-style nutrition data as your basis for the estimate.`;

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

  const description = (payload.description || '').trim();
  if (!description) return jsonResponse(400, { error: 'Missing "description".' });
  if (description.length > 500) return jsonResponse(400, { error: 'Description too long.' });

  // Check cache first — if found, return immediately without using AI budget.
  const cached = await checkFoodCache(description);
  if (cached) {
    // Still need to return remaining count, so fetch it without incrementing.
    const today = new Date().toISOString().slice(0, 10);
    const countRes = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/ai_usage?user_id=eq.${auth.user.id}&usage_date=eq.${today}&select=count`,
      {
        headers: {
          apikey: process.env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${auth.token}`,
          'content-type': 'application/json',
        },
      }
    );
    const countRows = await countRes.json().catch(() => []);
    const currentCount = countRows.length ? countRows[0].count : 0;
    const remaining = Math.max(0, 20 - currentCount);
    return jsonResponse(200, {
      food_name: cached.food_name,
      calories: cached.calories,
      protein_g: cached.protein_g,
      carbs_g: cached.carbs_g,
      fat_g: cached.fat_g,
      confidence: 'high',
      cached: true,
      remaining,
    });
  }

  const rateLimit = await checkAndIncrementRateLimit(auth.user.id, auth.token);
  if (!rateLimit.ok) return jsonResponse(rateLimit.status || 500, { error: rateLimit.message });

  try {
    const text = await callAnthropic({
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: description }],
      maxTokens: 1000,
    });

    const parsed = extractJSON(text);
    // Cache the result for future lookups.
    await cacheFood(description, parsed);
    return jsonResponse(200, { ...parsed, remaining: rateLimit.remaining });
  } catch (err) {
    return jsonResponse(502, { error: 'Could not estimate macros right now.', detail: String(err.message || err) });
  }
};
