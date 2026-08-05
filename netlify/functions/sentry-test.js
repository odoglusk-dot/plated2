// GET (or POST) — manual-trigger-only function to confirm Sentry error
// reporting works on the functions side, without touching any real
// environment variable or code path. Visit it directly in a browser or
// `curl` it: https://<your-domain>/.netlify/functions/sentry-test
//
// Does nothing except throw a caught error and report it via captureError —
// no auth, no database writes, no external API calls, so it's entirely
// inert beyond the one Sentry event it sends. Safe to leave in place or
// delete once you've confirmed the test event shows up in your functions
// Sentry project.
const { jsonResponse, captureError, withErrorReporting } = require('./_shared');

exports.handler = withErrorReporting(async () => {
  if (!process.env.SENTRY_DSN) {
    return jsonResponse(200, {
      sent: false,
      reason: 'SENTRY_DSN is not set on this Netlify site — nothing was sent to Sentry. Set it under Site settings -> Environment variables, then hit this endpoint again.',
    });
  }

  const testId = Date.now().toString(36);
  try {
    throw new Error(`Plated Sentry setup check (functions side) — test id ${testId}`);
  } catch (err) {
    await captureError(err, { function: 'sentry-test', purpose: 'manual verification, safe to ignore/resolve' });
  }

  return jsonResponse(200, {
    sent: true,
    testId,
    message: `Test error reported. Search your FUNCTIONS Sentry project for "test id ${testId}" to confirm it landed.`,
  });
}, 'sentry-test');
