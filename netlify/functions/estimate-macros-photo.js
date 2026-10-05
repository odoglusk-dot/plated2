// POST { imageBase64: string, mediaType: "image/jpeg" | "image/png" | "image/webp", note?: string }
// Auth: Authorization: Bearer <supabase access token>
// Returns { food_name, calories, protein_g, carbs_g, fat_g, confidence }
// Checks food_cache first using a hash of image + note; if hit, returns immediately without using API budget.
// Gated at 20/day for paid users (item 5 of the AI cost-efficiency batch,
// checkAndIncrementFeatureLimit() in _shared.js) — independent of the one-
// time free-tier preview claim, which never touches this daily pool.
const { jsonResponse, verifyUser, hasPaidAccess, claimOneTimeProPreview, checkAndIncrementFeatureLimit, callAnthropic, recordUsageCost, extractJSON, getPhotoCacheKey, checkFoodCache, cacheFood, captureError, withErrorReporting, FEATURE_DAILY_LIMITS } = require('./_shared');

const SYSTEM_PROMPT = `You are the nutrition-estimation engine for Krafft, a macro-and-strength-tracking app.
You will be shown a photo of a food or meal. Estimate its nutritional content from what's visible —
portion sizes, visible ingredients, and typical preparation. If an optional text note accompanies the
photo, use it to refine the estimate (e.g. it may state an ingredient or portion the photo doesn't show).
Respond with ONLY a JSON object, no markdown fences, no prose, in exactly this shape:
{"food_name": string, "calories": number, "protein_g": number, "carbs_g": number, "fat_g": number, "confidence": "high" | "medium" | "low", "ingredients": [{"name": string, "calories": number}] | null}
Set "confidence" to "low" if the photo makes portion size or ingredients genuinely hard to judge.
All numeric fields are grams or kcal with no units attached.
Set "ingredients" to an array of the meal's visually distinguishable components (e.g. a bowl's rice,
protein, and toppings), each with its own calorie estimate that should roughly sum to the total
"calories" — but only when the photo genuinely shows 2 or more separable parts. Set it to null for a
single, non-composite food (e.g. a whole apple, one slice of pizza) — don't invent a breakdown where
there isn't a meaningful one.`;

const ALLOWED_MEDIA_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif']);

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let isPreview = false;
  if (!(await hasPaidAccess(auth.user.id, auth.token))) {
    // Item 6 of the conversion-surface-area batch: a highly engaged free
    // user (10-day logging streak, checked client-side) gets one real
    // preview result instead of the usual 402. claimOneTimeProPreview()
    // atomically enforces the "only once ever" part server-side, so this
    // can't be replayed by calling the endpoint directly.
    isPreview = await claimOneTimeProPreview(auth.user.id, auth.token);
    if (!isPreview) {
      return jsonResponse(402, { error: 'AI photo macro estimation is a paid feature — start your free trial or subscribe to use it.', upgradeRequired: true });
    }
  }

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
    // The one-time preview isn't on the daily photo pool at all — only
    // compute a "remaining" count for a real paid user, read without
    // incrementing since a cache hit doesn't spend any budget.
    let remaining = null;
    if (!isPreview) {
      const today = new Date().toISOString().slice(0, 10);
      const countRes = await fetch(
        `${process.env.SUPABASE_URL}/rest/v1/ai_usage?user_id=eq.${auth.user.id}&usage_date=eq.${today}&select=photo_count`,
        {
          headers: {
            apikey: process.env.SUPABASE_ANON_KEY,
            Authorization: `Bearer ${auth.token}`,
            'content-type': 'application/json',
          },
        }
      );
      const countRows = await countRes.json().catch(() => []);
      const currentCount = countRows.length ? countRows[0].photo_count : 0;
      remaining = Math.max(0, FEATURE_DAILY_LIMITS.photo - currentCount);
    }
    return jsonResponse(200, {
      food_name: cached.food_name,
      calories: cached.calories,
      protein_g: cached.protein_g,
      carbs_g: cached.carbs_g,
      fat_g: cached.fat_g,
      ingredients: cached.ingredients || null,
      confidence: cached.confidence || 'high',
      cached: true,
      preview: isPreview,
      remaining,
    });
  }

  let photoRemaining = null;
  if (!isPreview) {
    const rateLimit = await checkAndIncrementFeatureLimit(auth.user.id, auth.token, 'photo');
    if (!rateLimit.ok) return jsonResponse(rateLimit.status || 500, { error: rateLimit.message });
    photoRemaining = rateLimit.remaining;
  }

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
          ingredients: parsed.ingredients || null,
        }),
      });
    } catch {
      // Cache write failure is non-fatal.
    }
    return jsonResponse(200, { ...parsed, preview: isPreview, remaining: photoRemaining });
  } catch (err) {
    await captureError(err, { function: 'estimate-macros-photo', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not estimate macros from that photo.', detail: String(err.message || err) });
  }
}, 'estimate-macros-photo');
