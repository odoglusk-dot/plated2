# Krafft: Training redesign batch (exercise screen, workout flow, programs, editing, library, bigger catalog)

Design reference: `docs/krafft-training-redesign-full-mockup.html` (open in a browser; it is the source of truth for layout, spacing, states and copy). Exercise data: `docs/krafft-exercise-catalog.csv` (255 exercises). Work on a branch `training-redesign`. Match the shipped V3 look (cream, brass, Fraunces / Inter / IBM Plex Mono), the 3-tab glass bar and gold + button. Do not change Stripe/RevenueCat/billing logic. Do not change the AI consent flow or Pro gating. Plans, blocks, and the exercise library stay FREE.

Work in phases, in order. **After each phase: run the app, test, and stop with a short report so I can review before you start the next.** Each phase must be shippable on its own; nothing may be left half-built behind a broken screen.

Two decisions that override anything below that seems to conflict:
- **Muscle diagrams use the app's EXISTING muscle map from the website, unchanged.** The figures in the mockup are placeholders. Do not draw new bodies or new SVG figures. Reuse the existing muscle map component and its assets and styling exactly, and add only: (a) highlighting by exercise (primary muscle = brass `#8A6A3A`, secondary muscles = lighter `#D3B988`, everything else in the map's normal neutral state), (b) a compact size variant for the exercise header (about 76x104pt) and for the small version in supersets, and (c) front or back view chosen from the exercise's primary muscle. If the existing map cannot be highlighted per muscle group in a compact size without changes, tell me what is needed before you modify it.
- **A program is never required.** A user with no program (including every brand-new user) can tap Start workout on Today and build a workout as they go. Never block, nag or redirect a new user into picking a split, and do not add a program-picking step to first-run onboarding.

Ground rules that apply to every phase:
- Never lose or alter a user's logged workout history. Past sessions keep the exercise they were logged with even if a plan or exercise changes later.
- Every set autosaves the instant it is checked (local first, then sync), including offline.
- Never hard-code numbers or copy the mockup invents (sample weights, "255 exercises", names). Counts come from data.
- Every destructive edit has an Undo toast.
- Respect safe areas, 44pt tap targets, 320pt width, no horizontal scroll; the tab bar and + never overlap.
- iOS app: no links or buttons that lead to web checkout. Pro upsell rows open the existing paywall for the platform.

---

## Phase 0 - Audit (docs/training-audit.md, then continue)

Report, briefly: current exercise library data source and schema (file/table, fields, IDs, how muscle groups map to the muscle map, how equipment is stored, any cue/form text fields); the plan builder and block builder (data model, where stored, how a plan is started); the workout tracker (screens, how sets are saved, timer implementation, how an interrupted workout resumes); where PRs and estimated 1RM are calculated; the session analysis entry point; what the library search and filters support today; how many exercises exist now. Flag anything in the mockup that conflicts with the current data model and say how you'll handle it.

## Phase 1 - Exercise catalog (255 exercises) and tracking types

1. Import `docs/krafft-exercise-catalog.csv` into the exercise library with an **idempotent** migration or seed (safe to run twice). Columns: name, primary_muscle, secondary_muscles (semicolon-separated), equipment, type (compound/isolation/cardio), tracking, aliases (semicolon-separated).
2. **De-duplicate against existing exercises** by normalized name and aliases (case-insensitive, ignore punctuation and "Barbell/Dumbbell" order differences). Never create a second copy of an exercise that exists. Merge new aliases and missing muscle/equipment data into the existing record. Never change an existing exercise's ID or name. Report: how many were added, merged, and skipped, with the list.
3. Map the CSV muscle names to the app's existing muscle-map groups (Chest, Lats, Upper Back, Lower Back, Traps, Front/Side/Rear Delts, Biceps, Triceps, Forearms, Quads, Hamstrings, Glutes, Calves, Abs, Obliques, Adductors, Abductors, Hip Flexors, Full Body, Cardio). If a group does not exist in the map, add it or map to the closest one and tell me.
4. **Tracking types.** Support four input modes per exercise: weight_reps (default), bodyweight_reps (reps, optional added weight), time (seconds; planks, holds, dead hang), distance_time (cardio and carries). Build the set-entry UI for each (timer for time, distance + duration for distance_time, with units respecting the user's lb/kg and mi/km setting). PRs and volume math must handle each type correctly (time PRs = longest hold; cardio has no 1RM). Existing exercises and logged data stay weight_reps unless clearly bodyweight/time.
5. **Cues.** For every new exercise add 2 short form cues (max 14 words each) and 1 "common mistake" line, in the same fields the existing exercises use. Be accurate and conservative; no medical claims. Put all generated cues in `docs/cues-review.md` so I can skim them before release.
6. **Search and filters.** Search matches name and aliases (typing "cable crossover" finds Cable Fly (Mid); "RDL" finds Romanian Deadlift). Filters: muscle group, equipment (Barbell, Dumbbell, Machine, Cable, Smith Machine, Bodyweight, Kettlebell, Band, EZ Bar, Trap Bar, Landmine, Cardio, Other), and type. Both filters can combine. Fast on a phone with 250+ items (no jank while typing).
7. **Swaps.** For each exercise compute alternatives: same primary muscle, different equipment first, then similar movement. Used by the Swaps tab and the swap sheet in plans.
8. Custom exercises keep working; they may have no muscle data (hide the diagram in that case).
9. Verify: free vs Pro unchanged, existing plans, blocks, PRs and history untouched, muscle map still correct.

## Phase 2 - Workout reliability

Do this before any visual work. It is the biggest trust issue in this category.
1. Every set saves immediately on check (local persistence first; sync after). Kill the app mid-workout; reopening resumes exactly where the user left off (exercise, sets, elapsed time, rest timer).
2. Rest timer is based on a stored end timestamp, not an in-memory countdown. It keeps correct time if the app is backgrounded or the phone locks, and fires a local notification at zero if the user has notifications enabled (follow existing permission flow; do not add new permission prompts without telling me).
3. Prevent screen sleep during an active workout (use the Capacitor-appropriate mechanism and release it when done).
4. Offline: logging works fully offline and syncs later; show a subtle offline indicator, no blocking errors.
5. Test: background for 5 min, lock screen, force-quit, airplane mode, low battery. Report results.

## Phase 3 - Quick workout, exercise screen (A2) and workout flow (3A + A3)

Build to the mockup, sections 1 and 3:
0. **Quick workout (no program needed).** The Today "lift" card, when the user has no active program, shows: "Ready when you are", a primary Start workout button, a "Repeat last: <last workout name>" chip (only if they have a previous workout), and a small "Programs" text link. Start workout opens an empty workout: a search field, a "Repeat a recent workout" list (the user's last few sessions, tapping Use copies the exercises, not the weights), recent exercises as chips, and an Add exercise button using the Phase 4 picker. Exercises are added on the fly and appear in the same workout overview as a program workout (same autosave, timers, PRs). On Finish, offer "Save as workout" (optional, easy to dismiss) which saves it to the user's plans for reuse. The elapsed timer starts at the first logged set, not on tap. The + sheet's Set tile and Today's "Start workout" lead to the same flow. Users with a program still see the program's next workout card as in mockup section 1, with the same Start behavior and a way to start a quick workout instead.
1. **Workout overview**: Done / Up next / Later groups, progress ring per exercise (x/y sets), top progress bar, Finish button, "stalled" note only when the stats exist (do not fake it; if there is not enough history, omit the note).
2. **Exercise screen (A2)**: muscle diagram header (the app's existing muscle map, see the override at the top; front or back view chosen from the primary muscle; brass = primary, lighter = secondary; hide when there is no muscle data), name, equipment chip, sets x rep range, "Last: ..." from the previous session, one "Goal: ..." line (see 6), sets table with the last-time column, weight and reps inputs, big check. One-line cue with a "More" chip that opens the exercise page Form tab. Pinned rest timer and gold check button.
3. **PR state**: a "New PR" badge when a set beats the best weight, the best reps at that weight, or estimated max; show the estimated-max change line when it applies.
4. **Superset**: stack two exercises with a gold bracket, one shared rest timer that starts after the last exercise of the round.
5. **Time and cardio inputs** per Phase 1 tracking types.
6. **Goal line**: double progression computed in code. If every set last time hit the top of the rep range, goal = add the smallest sensible increment (2.5 or 5 lb upper body; 5 or 10 lb lower; kg equivalents for metric users); otherwise same weight, aim for +1 rep on the weakest set. If there is no previous session, no goal line.
7. Weight steppers and quick-fill: tapping the last-time cell copies it into the inputs.
8. Keep the existing Finish flow and session analysis entry point working; do not rebuild session analysis in this batch (a separate batch covers it). Just make sure Finish navigates to it as today.

## Phase 4 - Library and exercise pages (2A)

1. Library home: search, muscle chips, equipment chips, Recent (from the user's history), Needs attention (only when plateau data exists), A-Z list. Opens from Progress -> Library, from any exercise name, and from the + sheet / Add exercise picker.
2. Exercise page: header (diagram, name, chips) and three tabs: **History** (estimated-max chart over time, PR chips, recent sessions table: date, top set, volume), **Form** (cues and common mistakes), **Swaps** (alternatives; a Swap button is shown only when opened from a plan or workout context). "Add to today's workout" button.
3. History requires data: with fewer than 2 sessions show a friendly empty state, not an empty chart.
4. Add exercise picker (used in plans and mid-workout): same filters and search, with the user's last numbers shown inline and a + button.

## Phase 5 - Programs, "your version" editing, scheduling

**5a. Program templates (read-only, built from catalog exercises).** Create these programs as data (not hard-coded UI). Use only exercises from the catalog, by exact name. Order each day compound first, then accessories. Each day 5-7 exercises, 2-4 sets, with rep ranges (compounds 5-8 or 6-10, accessories 10-15). Include per program: name, description, days per week, level, goal, equipment needed, number of weeks (6-8), planned deload week, progression rule text.
1. Full Body 3x (Beginner, Size/Strength, Full gym)
2. Beginner Strength 3x (A/B alternating, 5x5 style on the main lifts)
3. Upper / Lower 4x (Intermediate, Size)
4. Upper / Lower Strength 4x (Intermediate, Strength)
5. Push / Pull / Legs 3x (Intermediate, Size)
6. Push / Pull / Legs 6x (Intermediate to Advanced, Size)
7. 5-Day Split: Chest, Back, Shoulders, Arms, Legs (Intermediate, Size)
8. Dumbbell-Only Full Body 3x (Home/Dumbbells)
9. Bodyweight and Minimal Equipment 3x (Bodyweight, bands)
10. Lower-Body Focus 4x (Glutes, quads, hamstrings, with upper maintenance)
Write the full list of days and exercises for all 10 to `docs/programs-review.md` and **stop for my review** before shipping them to users.

**5b. Plans hub (mockup 1A).** Progress -> Plans: active program card (name, week x of y, next workout, Start), week strip, Browse programs with chips (Beginner, Size, Strength, by days), program list, program preview (weeks, days, progression text, equipment chips), Start program and Customize. Today's lift card reads from the active program (states: next workout, no program yet with Quick workout from Phase 3, workout in progress, matching mockup section 1). Browsing programs is optional everywhere; a user can ignore the Plans hub forever and still log every workout.

**5c. "Your version" editing (mockup B1).** Customize (or editing any plan the user owns) works on a user-owned copy. The Krafft template is never modified. Reuse the existing plan and block data model for the copy; do not create a parallel system. Screens: program editor (rename, reorder days by drag, add a day, edit a day, Change days / week, Reset to original), day editor (drag to reorder exercises, swap using the Swaps list, remove with Undo, add via the picker, tap an exercise for sets, rep range, rest, auto-progress toggle, superset with..., "apply to all days"), autosave with a small "Saved" indicator. "Reset to original" restores the template version for a day or the whole program after confirmation.

**5d. Change days per week (B2).** Choose 3-6 days and which weekdays; show a preview screen listing what will merge, move, or be removed and a weekly sets per muscle check; nothing changes until Apply; Apply is undoable for the session. Build the merge/split logic conservatively (keep compounds, drop isolation work first, never drop a muscle group entirely) and explain the logic in the report.

**5e. Reschedule (B3).** From the Today lift card: Move to tomorrow, Swap with another day, Shorten (drop accessories to about 35 min), Skip. None of these edit the program itself; they only change this week's schedule.

**5f. Progression and deload.** Auto-progress applies double progression per exercise (as in Phase 3 goal line). Deload week uses 60% of the planned sets at the same weights. Make the block timeline visible in the program view (volume ramp and deload marker), as in mockup 1C, if time allows; otherwise list the weeks with a deload tag and tell me it was simplified.

## Phase 6 - QA and report

1. Test matrix: brand-new user (no history), user with 20+ sessions, free vs Pro, metric vs imperial, offline, long exercise names, VoiceOver labels on all new controls, dark/light if supported, iPhone SE width, large text sizes.
2. Confirm: no change to existing logged data, existing plans and blocks still open and start, PRs unchanged, muscle map unchanged, AI consent and Pro gates unchanged, free tier unchanged.
3. Run `npm run sync:ios` and tell me the exact steps to rebuild in Xcode and the Build number to use.

## Final report

Per phase: what changed, files and migrations (with the order to run them in Supabase), what you simplified or deferred, any conflicts with the mockup and how you resolved them, and counts (exercises added/merged/skipped; programs created). Then list the five riskiest things to test on a real iPhone in TestFlight.
