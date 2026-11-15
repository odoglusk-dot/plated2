# Krafft fidelity report

Source of truth: `docs/krafft-training-redesign-full-mockup.html`.
Live side-by-side comparisons: `docs/fidelity-report.html` (open in a browser).

## Step 0: reference + app screenshots

- `scripts/mockup-refs.js` extracts one reference PNG per phone from the mockup HTML, scaled to real iPhone size (390/274 = 1.4234x via CSS `zoom`). 25/25 phones found, matching the doc's section counts exactly (Today 2, Plans 6, Workout 6, + button 3, Finish 2, Library 6). Output: `docs/mockup-ref/`.
- `scripts/seed-demo.js` provides fixture data (Upper/Lower 4-day block, today's day, the mockup's exact last-time numbers and macros) via Playwright route mocking rather than a real Supabase test account - see the comment at the top of that file for why; flag if real backend seeding is actually wanted instead.
- `scripts/app-shots.js` drives the running app through the same 25 screens and screenshots each into `docs/app-shots/`, then builds `docs/fidelity-report.html`. 25/25 captured on this run (one intermediate step inside 1-2 failed on a pointer-event overlap with the rest-timer pill; the shot itself still landed on a usable, if not perfectly intended, state - noted inline).

### What the baseline shows (first look, not yet a line-by-line checklist pass)

Comparing the two screenshot sets directly, the dominant gap is **scale and density**, not color:

1. **Type scale is too large throughout.** The mockup's screen/section titles ("Your program", "Browse programs") are compact (19-24px-equivalent, single line). The app's equivalent headings use the same font but render much larger, wrapping to two lines where the mockup fits one.
2. **Chips are oversized.** Mockup chips are a dense 10.5px pill with 5x9px padding. The app's `.chip` class, while already pill-shaped, uses noticeably larger padding/font, so a filter row that should show "All / Beginner / Intermediate / Advanced" compactly takes much more vertical and horizontal space.
3. **Card padding is too generous.** Mockup cards use 11x12px padding; the app's `.card` (already bumped to 16px radius in an earlier pass) still uses ~20px padding, closer to the app's pre-existing default than the mockup's tight spec.
4. **A2 weight prefill gap (functional, not visual):** opening a freshly-added exercise's A2 screen shows an empty Weight field with no value, where the mockup shows it pre-filled from last session's weight (70). Current code (`resetExerciseDetailInput`) only prefills from *this live session's own* prior sets, not from exercise history - a real behavior gap to fix in the Section 3 pass, not just a style one.
5. **Figure/muscle-map tile** renders correctly but noticeably smaller and lower-contrast than the mockup's 76x104 tile with brass-highlighted primary muscle.

Shared components A-J (next step) will fix most of #1-3 and #5 at the component level, since nearly every screen reuses `.card`, `.chip`, and the figure tile. #4 is a logic fix inside the exercise-detail module, done as part of Section 3.

## Status

Per the user's "finish everything from this batch" instruction, rule 6's per-section stop-for-review was waived and every section was taken through to completion in one pass. Final state:

- **Step 0** (reference/app screenshot infra): done.
- **Shared components A-J**: done. Glass bar, set row, exercise header, stepper, progress ring, PR badge, banner, bottom sheet, week strip, and day dots all scaled to the mockup's own 390/274 ratio and reused across screens.
- **Section 3b (+ button)**: done, including the A2/quick-log weight-prefill bug fix.
- **Section 1 (Today)**: done.
- **Section 2 (Plans)**: done - Plans hub dark hero card + week strip + day dots, program preview restructured into drill-in day cards with real catalog-derived muscle/equipment data, Block Builder's "Your version" now collapsed-first, change-days-per-week preview gained a real weekly-sets-per-muscle chart, reschedule menu restyled with a working "Swap with <next day>" action.
- **Section 4 (Finish)**: done - Session Analysis restyled with stat tiles, icon-badge findings, and a real "Next session" targets card (computed client-side from logged data, never the AI response) on both tiers. Found and fixed a real crash in `exerciseGoalRepRangeFor` along the way (iterated `block.days`, a number, instead of `block.blockDays`).
- **Section 3 (Workout)**: done - quick-workout picker and in-session overview restyled to the mockup's individual-card list convention; added the "save as workout, optional" teaser banner.
- **Section 5 (Library)**: done - Exercise Glossary header flattened off its wrapping card to match the mockup.

**Known, deliberately-not-attempted gaps** (flagged rather than half-built):
- **Save as workout**: no naming/persisting-a-template flow exists; only the mockup's teaser banner text was added.
- **Superset creation UI**: no way to group two exercises mid-session into a true superset; the 3-6 screenshot is a plain A2 screen, not a real superset.
- **Finish screen's per-exercise trend chart** (`highlightExercise`) and nutrition chart render only when the AI response names them - not exercised by the current test fixture, unverified visually.
- **Program preview's "8 weeks"/deload-week copy** from the mockup isn't represented - no `weeks`/deload-schedule field exists on `PROGRAM_TEMPLATES`.

All work is committed and pushed to `training-redesign` (not yet merged to `main`).
