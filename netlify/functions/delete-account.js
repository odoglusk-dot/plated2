// POST {}  (no body needed — the caller's own account is deleted)
// Auth: Authorization: Bearer <supabase access token>
//
// Deleting an auth.users row requires Supabase's admin API, which requires
// the service-role key — that's why this can't be a direct client call.
// Every table's foreign key is `on delete cascade`, so this one call removes
// the user's profile/goals/food_logs/favorites/weight_log/supplement_logs
// along with the auth record itself.
const { jsonResponse, verifyUser, captureError, withErrorReporting, callStripe } = require('./_shared');

// Cancels any live Stripe subscription for this user BEFORE the account is
// deleted. Without this, Stripe has no way to know the account is gone —
// it keeps firing subscription.updated/deleted events (renewals, trial
// conversion) for a subscription whose user_id no longer exists once the
// auth.users row (and the cascaded subscriptions row) is deleted, and
// stripe-webhook.js's upsert then hits subscriptions_user_id_fkey. Best
// effort: never blocks account deletion on a Stripe hiccup, but does
// report one so it doesn't fail silently and often.
async function cancelStripeSubscriptionIfAny(userId) {
  if (!process.env.STRIPE_SECRET_KEY) return;
  try {
    const subRes = await fetch(
      `${process.env.SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${userId}&select=stripe_subscription_id,status`,
      {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );
    if (!subRes.ok) return;
    const sub = (await subRes.json())[0];
    if (!sub?.stripe_subscription_id || sub.status === 'canceled') return;
    await callStripe(`subscriptions/${sub.stripe_subscription_id}`, { method: 'DELETE' });
  } catch (err) {
    await captureError(err, { function: 'delete-account', step: 'cancel-stripe-subscription', userId });
  }
}

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for account deletion.' });
  }

  await cancelStripeSubscriptionIfAny(auth.user.id);

  const res = await fetch(
    `${process.env.SUPABASE_URL}/auth/v1/admin/users/${auth.user.id}`,
    {
      method: 'DELETE',
      headers: {
        apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  if (!res.ok) {
    const detail = await res.text();
    await captureError(new Error('Could not delete account: ' + detail), { function: 'delete-account', userId: auth.user.id });
    return jsonResponse(502, { error: 'Could not delete account.', detail });
  }

  return jsonResponse(200, { deleted: true });
}, 'delete-account');
