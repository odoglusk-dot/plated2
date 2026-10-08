// POST {}  (no body needed — the caller's own account is deleted)
// Auth: Authorization: Bearer <supabase access token>
//
// Deleting an auth.users row requires Supabase's admin API, which requires
// the service-role key — that's why this can't be a direct client call.
// Every user-owned table's foreign key is `on delete cascade`, so deleting
// the auth.users row removes every row below in one shot. As of
// reset-schema.sql, that's: profiles, goals, body_stats, food_logs,
// favorites, weight_log, health_sync_tokens, sleep_log, steps_log,
// supplement_logs, water_logs, ai_usage, subscriptions, referrals,
// friendships, groups (as creator), group_members, group_goals,
// conditioning_log, athlete_journal_entries, athlete_confidence_entries,
// lifts, exercise_goals, monthly_recaps, photos, user_navbar_prefs,
// user_background_prefs, user_screen_modules, training_splits, plans,
// user_achievements, workout_sessions, training_insights,
// external_purchase_log. Two tables deliberately do NOT cascade — they use
// `on delete set null` so the row survives, anonymized: group_freeze_log
// (member_id — a group's freeze history shouldn't vanish because one
// member left) and cancellation_flow_events (user_id — kept as anonymous
// aggregate "why do people cancel" data). Storage objects (progress-photos/
// food-photos/background-photos, one folder per user) are NOT covered by
// that cascade — object storage has no FK — so they're deleted explicitly
// below, before the auth user itself goes.
const { jsonResponse, verifyUser, captureError, withErrorReporting, callStripe } = require('./_shared');

const STORAGE_BUCKETS = ['progress-photos', 'food-photos', 'background-photos'];

// Lists then removes every object under `{userId}/` in one bucket. Supabase
// Storage has no "delete by prefix" in one call — list first, then remove
// by exact path. Best-effort per bucket: a failure here must never block
// the rest of account deletion (an orphaned file is a cleanup task, not a
// reason to leave the account itself undeleted).
async function purgeStorageFolder(bucket, userId) {
  const base = process.env.SUPABASE_URL;
  const headers = {
    apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    'content-type': 'application/json',
  };
  try {
    const listRes = await fetch(`${base}/storage/v1/object/list/${bucket}`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ prefix: `${userId}/`, limit: 1000 }),
    });
    if (!listRes.ok) return;
    const entries = await listRes.json().catch(() => []);
    const paths = (entries || []).map((e) => `${userId}/${e.name}`);
    if (!paths.length) return;
    await fetch(`${base}/storage/v1/object/${bucket}`, {
      method: 'DELETE',
      headers,
      body: JSON.stringify({ prefixes: paths }),
    });
  } catch (err) {
    await captureError(err, { function: 'delete-account', step: 'purge-storage', bucket, userId });
  }
}

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
  await Promise.all(STORAGE_BUCKETS.map((bucket) => purgeStorageFolder(bucket, auth.user.id)));

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
