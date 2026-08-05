// POST {}  (no body needed — the caller's own account is deleted)
// Auth: Authorization: Bearer <supabase access token>
//
// Deleting an auth.users row requires Supabase's admin API, which requires
// the service-role key — that's why this can't be a direct client call.
// Every table's foreign key is `on delete cascade`, so this one call removes
// the user's profile/goals/food_logs/favorites/weight_log/supplement_logs
// along with the auth record itself.
const { jsonResponse, verifyUser, captureError, withErrorReporting } = require('./_shared');

exports.handler = withErrorReporting(async (event) => {
  if (event.httpMethod !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const auth = await verifyUser(event);
  if (!auth) return jsonResponse(401, { error: 'Sign in required.' });

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: 'Server is not configured for account deletion.' });
  }

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
