# Phase 2 test matrix — workout reliability

Phase 2 is explicitly "before any visual work" — it ships two things:

1. **Shipped and visible now**: the existing "Add lift" form is local-first
   with an offline queue and a subtle indicator.
2. **Built, not yet visible**: a live-workout-session module (`wls*`
   functions in index.html, near `reopenWorkoutSession`) — rest timer on a
   stored end-timestamp, per-set incremental save, same-day resume, screen
   wake-lock. Nothing in the UI calls these yet; they're the foundation
   Phase 3's exercise screen will wire up once built against the mockup.
   That split is why the automated coverage below looks different for the
   two halves — #1 has a real screen to click through right now, #2 doesn't.

## 1. Offline lift save — automated, verified in a real browser

Ran via Playwright against the real `index.html` (mocked Supabase REST,
real DOM interaction — fill the actual form, click the actual button, real
`reload()` between steps to simulate a force-quit/relaunch):

| Step | Result |
|---|---|
| Save a lift while the network is down | Appears instantly in "Today's Lift" (optimistic), "⏳ 1 set saved offline" indicator shows |
| Queue persists in `localStorage` (`krafft_pending_lift_syncs_v1`) | Confirmed present after save |
| Simulated force-quit + relaunch (full page reload, still offline) | Queued lift still in the UI, still marked unsynced, indicator still showing |
| Network restored, `online` event fires | Queue flushes automatically (the module's own listener, not a test hook), indicator clears |
| Server-side row | Correct `exercise`/`weight`/`reps_per_set` landed |

Also code-reviewed: a real Postgrest error (has `.code`) is dropped from
the queue and surfaced via the existing error-message UI instead of
retrying forever — only genuine network failures stay queued.

**Not automated, needs a real device before shipping:**
- A real OS-level force-quit (not just a page reload) — reload is a strong
  proxy (it's a fresh JS context with only `localStorage` surviving,
  which is exactly what a real kill leaves behind too) but isn't identical.
- Airplane mode toggle on a physical iPhone.
- Backgrounding for 5 minutes, then returning — the 30-second periodic
  retry (`setInterval`, safety net alongside the `online` event, since
  iOS WKWebView's online/offline events aren't fully reliable) should
  still be running when the app is foregrounded again, but timer behavior
  across real iOS backgrounding should be confirmed on-device.
- Low battery / Low Power Mode — iOS can throttle background timers more
  aggressively; shouldn't affect this feature (writes are synchronous to
  localStorage, not timer-dependent) but worth a real-device check.

## 2. Live-session module (rest timer / resume / wake-lock) — code-reviewed, not yet E2E-testable

No screen calls `wlsStartExercise`/`wlsLogSet`/`wlsStartRestTimer` yet, so
there's no UI path to drive an end-to-end test from outside the app (and
these are plain module-scoped functions, not on `window`, so they can't be
called directly from a test script either — confirmed while trying).
Verified by careful code review instead:

- **Rest timer**: `wlsStartRestTimer(seconds)` stores `Date.now() +
  seconds*1000` as `endsAt`; `wlsRestTimeRemainingMs()` always recomputes
  `endsAt - Date.now()` fresh — there is no decrementing counter anywhere
  to get out of sync with reality after a background gap.
- **Resume**: `wlsResume()` reads the one `localStorage` key back on app
  boot (wired into `bootstrapApp()`), restores `currentExercise` and
  `restTimer` if the stored session is from *today*; a session from a
  prior day (app killed mid-workout and never reopened) is deliberately
  left un-resumed rather than silently bleeding into a new day's workout.
- **Per-set save**: every `wlsLogSet()` call writes to `localStorage`
  synchronously before attempting the Supabase call — same local-first
  pattern as the offline queue above, just against a single growing
  `lifts` row (tracked by its known id) instead of one row per save.
- **Wake-lock**: uses the standard `navigator.wakeLock` Web API (no new
  Capacitor plugin needed — WKWebView on iOS 16.4+ supports it directly),
  requested when an exercise starts and re-requested on `visibilitychange`
  back to visible, since browsers release wake locks automatically on
  backgrounding (expected behavior, not a bug).

**Real E2E coverage for this half lands with Phase 3**, once the exercise
screen actually calls into it — at that point the same force-quit/airplane-
mode/background-5-min/low-battery matrix above should be re-run against
the real screen.

## 3. Local notification at rest-timer zero — flagged, not built

The batch assumed an "existing permission flow" for local notifications.
There isn't one anywhere in this codebase — checked (`grep` for
`LocalNotifications`, `Notification.`, `requestPermission`,
`PushNotifications`: zero matches) before writing anything. Adding it for
real requires:

- A new native Capacitor plugin (`@capacitor/local-notifications`) —
  `npm install` + `npx cap sync ios` + an Xcode rebuild, not just a JS change.
- A genuinely new permission prompt, which the batch explicitly said not
  to add "without telling you" first.

Not built pending your go-ahead. In the meantime, once Phase 3 wires up
the real rest-timer UI, a foreground-only completion cue (sound + visual,
no OS permission needed) can cover the common case where the app is open;
tell me if you want the native notification piece added now or deferred.
