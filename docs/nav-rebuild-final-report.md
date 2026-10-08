# Krafft Navigation Rebuild — Final Report

Covers Phases 0–7 of the "One Today screen + universal +" batch. All phases shipped to `plated2` `main`:

| Phase | Commit |
|---|---|
| 0 — Audit | `ab482e8` |
| 1+3 — Nav chrome, + sheet | `5fa2a62` |
| 2+4 — Today, Progress | `4914d96` |
| 5 — You | `d69304f` |
| 6 — Cleanup | `6798342` |

## 1. Tap-count table (before → after)

Tap counts are from Home/the app's default landing screen, counting each screen transition as one tap (matching `docs/nav-audit.md`'s own convention).

| Feature | Before | After | Change |
|---|---|---|---|
| Log food (any method) | 1 | 2 (+ → Food tile) | +1 — now behind the universal + instead of a dedicated Log tab, per spec |
| Barcode scan | 2 | 2 (+ → barcode icon) | same |
| Photo log | 2 | 2 (+ → camera icon) | same |
| Water | 1 | 1 (Today card chip) | same |
| **Weight log** | **3 to screen, 4 to popup** | **1** (Today card tap) | **−2 / −3** |
| Log a set / workout tracker | 1 | 1 (Today's Lift card) | same |
| Blocks/Plans (summary) | 2 | 2 (Progress → Plans & Blocks row) | same |
| Blocks/Plans (open builder) | 3 | 3 | same |
| Exercise library | 2 | 2 (Progress → Tools row) | same |
| Muscle map | 2 | 2 (Progress → Muscle Map row) | same |
| PRs | 2 | 1 (shown directly on Progress Overview) | −1 |
| **AI coach (Ask Your Data)** | **3** | **1** (Today → Coach card) | **−2** |
| Friends (add/manage) | 2 | 2 (You → Friends & Groups) | same |
| **Friends leaderboard (stats)** | **4** | **2** (Progress → Insights) | **−2** |
| Groups | 1 (dedicated bottom-nav icon) | 3 (You → Friends & Groups → Your Group) | **+2** — see note below |
| Streaks | 0 | 0 (topbar pill, always visible) | same |
| Reminders | 1 (Profile, same screen) | 2 (You → Reminders row) | +1 |
| Goals | 1 | 2 (You → Goals row) | +1 |
| Units | 1 | 2 (You → Goals row, same content) | +1 |
| Billing/Pro status | 1 (pinned card) | 2 (You → Account & Pro) | +1 |
| Delete account | 1 | 2 (You → Privacy & Data) | +1 |
| Apple Health (card / setup wizard) | 1 / 2 | 2 / 3 (You → Privacy & Data → Set Up) | +1 / +1 |
| Krafft HQ admin | n/a | n/a | unchanged, not linked in-app |

**Net read:** every item the audit explicitly flagged as "buried" (Weight Log, Ask AI, Friends Leaderboard) got dramatically shallower — that was the stated goal and it's the biggest win here. The items that regressed by exactly one tap (Goals/Reminders/Units/Billing/Delete-account/Apple-Health) all moved from "already on the single long Profile/Settings scroll" to "one tap into a named row on You" — a deliberate tradeoff for a scannable 5-row screen instead of one long page, not an oversight.

**Groups going from 1 tap to 3 is the one tradeoff worth flagging explicitly**: it previously had its own 6th bottom-nav icon; the batch's hard 3-tab (4 with Athlete) cap means it no longer can. It now lives inside Friends & Groups on You. If Group engagement matters enough to want it shallower again, the cheapest fix would be surfacing an active group's streak/freeze count as its own Today module (similar to how Weight/Water got pulled out) — flagging as a follow-up, not doing it unprompted since it's a new module, not a relocation.

## 2. Requested items that didn't fit, and where they landed

Per Decision #8 ("put it in the closest location and list it in the final report instead of asking again"):

- **Weight Log, Progress Photos, Monthly Recaps** — not named in Progress's Overview or Insights spec. Placed as a "History" section at the bottom of Progress Overview (plain link rows).
- **Warm-up/1RM calculator** — the batch's Decision #4 names this as a Progress Tools destination, but no standalone calculator screen exists in the app: the warm-up ramp is inline on the Log-a-Lift form, and 1RM tracking lives on each exercise's own detail page inside the Exercise Library. Rather than build a redundant third copy, the Exercise Library row's subtitle now reads "includes 1RM tracking" and no separate calculator row was added.
- **Guide (User Guide) and Learning Paths** — not named in any of the 5 You rows. Placed under Account & Pro (closest fit: general app/account help), both reachable via the existing "Browse the Guide" button.
- **Achievements** — explicitly resolved by Decision #6, not an open item: moved out of the old inline Profile card into the new Streak & Achievements sheet, opened from the topbar streak pill (visible on every primary tab) and from the streak card at the top of You.
- **Referral code** — explicitly resolved by Decision #7: retitled "Invite & Referral Code" and moved to the top of Friends & Groups.
- **Supplements' "X of 4 taken" framing (Decision #3)** — `supplement_logs` is a free-form history log with no daily-target/checklist concept, and the batch's "no data model changes" constraint ruled out adding one. Adapted to "N logged today" (an honest count) instead of a target-based "X of 4."
- **"This Week" averages + weekly-recap-sharing** (previously a Today card) — not one of the 7 Today modules in the spec. Not yet relocated anywhere; this is the one genuine content gap left over from the rebuild. It's dormant, reachable code (`weeklySummary()`, `generateWeeklyRecapCanvas()`) with no current UI entry point. Recommend adding it to Progress Overview in a follow-up if weekly-recap-sharing is still wanted.

## 3. Anything deleted outright

**Nothing feature-level was deleted.** The only removals were dead wrapper code with zero remaining entry points after the relocations above: the `'more'` tab (`MORE_TAB_DESTINATIONS`, `renderMoreTab()`, `#panel-more`) and two orphaned CSS rules (`.tab-nav`, `.tab-btn.scope-hidden`) left over from the old secondary nav row. Every feature that wrapper pointed to (Supplements, Ask AI, Budget-Optimized Protein) is reachable from its new home; this didn't need separate approval since no user-facing feature was removed, only a now-pointless intermediate hub screen.

## 4. LOG_ANYTHING_AI_ENABLED

**Stubbed off (`const LOG_ANYTHING_AI_ENABLED = false`).** The + sheet's free-text field currently routes straight to the Food tab's existing "Describe It" AI flow (already consent-gated there) rather than parsing the entry's type itself. Building a dedicated type-detecting parser + confirm-card flow (food vs. a lift vs. water vs. weight) is new AI surface area beyond "wire only if small" — flagged as a discrete follow-up batch rather than attempted here.

## 5. Verification performed

- Playwright, against mocked Supabase/Capacitor fixtures, phone viewport (390×844, and 320×844 for the overlap check):
  - Nav chrome: tab switching, + sheet open/tile-routing, sheet open/close, Athlete Mode's 4th tab, no bar/+ overlap down to 320pt.
  - Today: all 7 modules render and wire correctly (protein breakdown sheet, meal edit/delete, lift card states, water logging, weight popup, supplements expand, coach routing).
  - Progress: Overview/Insights switch, Week/Month/Year control, all relocated rows route correctly.
  - You: all 5 rows + streak card + back navigation, with every existing field/button (goals, referral code, friends, AI consent, delete account, etc.) confirmed still wired.
  - Athlete Mode: confirmed the root is already a flat vertical-card list with every sub-screen ≤2 taps deep, with no code changes needed there.
- Confirmed the `?joinGroup=CODE` deep link still works unchanged (it calls `setActiveTab('group')`, which the new dispatch system auto-opens as a sheet).
- Every AI entry point (Describe It/Snap a Photo, Ask AI/Coach, Session Analysis) still routes through its existing, unchanged `requireAiConsent()`/`ai_consent_at` gate — none of these call sites were touched.
- `npm run sync:ios` run to refresh `www/` with the final index.html.

**Not done:** the ~65 pre-existing Playwright test files written against the old nav (`[data-bottom="log"/"lift"/"profile"/"group"]`, etc.) were not individually updated — that's a larger, separate test-maintenance pass (confirmed several fail now purely on stale selectors, not on real regressions, by spot-checking `athlete-mode-test.mjs` and `group-mode-test.mjs`). Recommend a follow-up pass to update their selectors before relying on the full suite again.

## 6. Rebuild commands

```
npm run sync:ios   # refreshes www/ from index.html + legal pages + icons
npx cap sync ios   # pulls www/ into the Xcode project
npx cap open ios   # opens Xcode to build/run on a device or simulator
```
