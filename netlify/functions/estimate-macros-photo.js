// POST { imageBase64: string, mediaType: "image/jpeg" | "image/png" | "image/webp", note?: string }
// Auth: Authorization: Bearer <supabase access token>
// Returns { food_name, calories, protein_g, carbs_g, fat_g, confidence }
// Checks food_cache first using a hash of image + note; if hit, returns immediately without using API budget.
const { jsonResponse, verifyUser, checkAndIncrementRateLimit, callAnthropic, recordUsageCost, extractJSON, getPhotoCacheKey, checkFoodCache, cacheFood, captureError, withErrorReporting, DAILY_AI_LIMIT } = require('./_shared');

const SYSTEM_PROMPT = `You are the nutrition-estimation engine for Plated, a macro-tracking app.
You will be shown a photo of a food or meal. Estimate its nutritional content from what's visible —
portion sizes, visible ingredients, and typical preparation. If an optional text note accompanies the
photo, use it to refine the estimate (e.g. it may state an ingredient or portion the photo doesn't show).
Respond with ONLY a JSON object, no markdown fences, no prose, in exactly this shape:
{"food_name": string, "calories": number, "protein_g": number, "carbs_g": number, "fat_g": number, "confidence": "high" | "medium" | "low"}
Set "confidence" to "low" if the photo makes portion size or ingredients genuinely hard to judge.
All numeric fields are grams or kcal with no units attached.`;

const ALLOWED_MEDIA_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif']);

exports.handler = withErrorReporting(async (event) => {
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

  const { imageBase64, mediaType, note } = payload;
  if (!imageBase64) return jsonResponse(400, { error: 'Missing "imageBase64".' });
  if (!ALLOWED_MEDIA_TYPES.has(mediaType)) {
    return jsonResponse(400, { error: 'Unsupported or missing "mediaType".' });
  }
  // Rough sanity cap: base64 is ~4/3 the raw byte size, keep uploads under ~8MB raw.
  if (imageBase64.length > 11 * 1024 * 1024) {
    return jsonResponse(400, { error: 'Image is too large.' });
  }

  // Check cache first using image + note hash — if found, return immediately without using AI budget.
  const cacheKey = getPhotoCacheKey(imageBase64, note);
  const cached = await checkFoodCache(cacheKey, true);
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
    const remaining = Math.max(0, DAILY_AI_LIMIT - currentCount);
    return jsonResponse(200, {
      food_name: cached.food_name,
      calories: cached.calories,
      protein_g: cached.protein_g,
      carbs_g: cached.carbs_g,
      fat_g: cached.fat_g,
      confidence: cached.confidence || 'high',
      cached: true,
      remaining,
    });
  }

  const rateLimit = await checkAndIncrementRateLimit(auth.user.id, auth.token);
  if (!rateLimit.ok) return jsonResponse(rateLimit.status || 500, { error: rateLimit.message });

  const userContent = [
    {
      type: 'image',
      source: { type: 'base64', media_type: mediaType, data: imageBase64 },
    },
    { type: 'text', text: note ? `Note from the user: ${note}` : 'Estimate the macros for this meal.' },
  ];

  try {
    const { text, model, inputTokens, outputTokens } = await callAnthropic({
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: userContent }],
      maxTokens: 1000,
    });
    await recordUsageCost(auth.user.id, auth.token, { model, inputTokens, outputTokens });

    const parsed = extractJSON(text);
    // Cache the result using the photo cache key.
    // We need to modify cacheFood to accept a custom cache key, or do it inline.
    const photoCacheKey = getPhotoCacheKey(imageBase64, note);
    try {
      await fetch(`${process.env.SUPABASE_URL}/rest/v1/food_cache`, {
        method: 'POST',
        headers: {
          apikey: process.env.SUPABASE_ANON_KEY,
          'content-type': 'application/json',
          Prefer: 'resolution=merge-duplicates',
        },
        body: JSON.stringify({
          description_key: photoCacheKey,
          food_name: parsed.food_name,
          calories: parsed.calories,
          protein_g: parsed.protein_g,
          carbs_g: parsed.carbs_g,
          fat_g: parsed.fat_g,
        }),
      });
    } catch {
      // Cache write failure is non-fatal.
    }
    return jsonResponse(200, { ...parsed, remaining: rateLimit.remaining });
  } catch (err) {
    await captureError(err, { function: 'estimate-macros-photo', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not estimate macros from that photo.', detail: String(err.message || err) });
  }
}, 'estimate-macros-photo');
