// POST { code: string }
// Auth: Authorization: Bearer <supabase access token>
//
// Records a referral attribution for the CALLER (the just-signed-up user).
// Uses the service-role key because `referrals` has no client insert
// policy — this is the only place a referrals row gets created. The actual
// reward (one month free for the referrer) doesn't happen here — it fires
// later, from stripe-webhook.js, only once the referred user's trial
// actually converts to a paid subscription.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for referrals.' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body.' });
  }

  const code = (payload.code || '').trim().toUpperCase();
  if (!code) return jsonResponse(400, { error: 'Missing "code".' });

  const base = process.env.SUPABASE_URL;
  const serviceHeaders = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };

  try {
    const lookupRes = await fetch(
      `${base}/rest/v1/profiles?referral_code=eq.${encodeURIComponent(code)}&select=id`,
      { headers: serviceHeaders }
    );
    if (!lookupRes.ok) return jsonResponse(502, { error: 'Could not look up referral code.' });
    const rows = await lookupRes.json();
    const referrer = rows[0];
    if (!referrer) return jsonResponse(404, { error: 'Referral code not found.' });
    if (referrer.id === auth.user.id) return jsonResponse(400, { error: "You can't refer yourself." });

    // One referral attribution per referred user, ever — the unique
    // constraint on referred_user_id backs this up at the DB level too, in
    // case of a race between two requests.
    const insertRes = await fetch(`${base}/rest/v1/referrals`, {
      method: 'POST',
      headers: serviceHeaders,
      body: JSON.stringify({ referrer_user_id: referrer.id, referred_user_id: auth.user.id, referral_code: code }),
    });

    if (!insertRes.ok) {
      const detail = await insertRes.text();
      // Already redeemed (unique violation) is an expected, silent no-op — not worth alerting on.
      if (insertRes.status === 409 || detail.toLowerCase().includes('duplicate')) {
        return jsonResponse(200, { redeemed: false, reason: 'already redeemed' });
      }
      await captureError(new Error('Could not insert referral: ' + detail), { function: 'redeem-referral', userId: auth.user.id });
      return jsonResponse(502, { error: 'Could not record referral.' });
    }

    return jsonResponse(200, { redeemed: true });
  } catch (err) {
    await captureError(err, { function: 'redeem-referral', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not process referral code.', detail: String(err.message || err) });
  }
}, 'redeem-referral');
