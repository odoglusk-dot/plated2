# Training redesign — Phase 0 audit

Branch: `training-redesign`, based on `origin/main` — independent of the
still-unmerged `session-analysis-v2` and `paywall-live`/`small-fixes`
branches. **This matters for one specific thing below** (session
analysis).

## Missing file — flagging before anything else

`docs/krafft-training-redesign-full-mockup.html` was never uploaded —
only `krafft-training-redesign-batch.md` and
`krafft-exercise-catalog.csv` came through as files; the mockup itself
arrived as pasted rendered text in the chat message. I've copied the CSV
and the batch doc into `docs/` on this branch. I'm working from the
pasted text (it's a genuinely detailed screen-by-screen walkthrough with
exact copy, labels, and the design-token list) as the design reference
for everything below — if there's pixel-level spacing/layout detail only
the real HTML would show, I won't have it. Send the actual `.html` file
if you have it; otherwise I'll proceed from the text description, which
covers copy, states, and structure in enough detail to build from.

## Exercise library — data source and schema today

**Table:** `exercises` (`reset-schema.sql`). No separate file — this is
the only source; `state.exercises = (select('*')).data` loads it
wholesale client-side, same "load once" pattern as other reference data.

**Current count: 102** (counted directly from the SQL, correcting an
estimate of "91" from an earlier, unrelated audit this session that
undercounted).

**Columns:** `name` (unique), `muscle_group`, `body_region`,
`secondary_regions` (text[]), `equipment`, `cue_setup`, `cue_execution`,
`cue_mistake`, `cue_bracing`, `hypertrophy_rep_range`,
`hypertrophy_rest_interval`, `hypertrophy_tempo`,
`hypertrophy_mind_muscle_cue`, `movement_type`
(`compound`/`isolation`/`plyometric`), `lengthened_bias` (bool),
`avoid_flags` (text[]), `block_types` (text[]), `muscle_map_key`,
`muscle_map_secondary_keys` (text[]), `category`
(`strength`/`plyometric`), `experience_level`
(`beginner`/`intermediate`/`advanced`), `image_url`, `video_url`. No
`CHECK` constraints — free text by convention.

**No `aliases` column exists anywhere** — confirmed, this needs adding
(a new `text[]` column, same shape as `secondary_regions`/
`muscle_map_secondary_keys`) for Phase 1's alias-aware search/dedup.

**No `tracking` (input-mode) column exists** — everything today is
implicitly `weight_reps`. Needs a new column; the set-entry UI genuinely
needs 3 new input variants (bodyweight_reps, time, distance_time) that
don't exist in any form today.

**Muscle map taxonomy — 14 keys in actual use**
(`MUSCLE_MAP_KEYS` in index.html): `chest, delts, biceps, triceps,
forearms, abs, obliques, quads, calves, traps, lats, lowerback, glutes,
hamstrings`.

**The CSV's `primary_muscle`/`secondary_muscles` values don't map
1:1 — this is Decision #2's exact scenario, flagging rather than
deciding unilaterally:**

| CSV muscle | Exists in the 14-key map? | Proposed handling |
|---|---|---|
| Chest, Biceps, Triceps, Forearms, Quads, Hamstrings, Glutes, Calves, Abs, Obliques, Traps | Yes, exact match | No change needed |
| Front Delts, Side Delts, Rear Delts | **No — only one `delts` key exists** | Map all three to `delts` for the muscle-map heatmap (can't show 3 sub-regions on the current body diagram), but **keep the CSV's finer split in `exercises.muscle_group`/`secondary_muscles` text** so the library's own muscle filter chips can still say "Front Delts" distinctly from "Side Delts" even though the body-map dot is the same |
| Lats, Upper Back | **CSV splits these; current map has only `lats`** (no separate "upper back" key — rows/pulldowns already use `lats` as primary today) | Map "Upper Back" to `lats` too, same reasoning as delts above — library text keeps the distinction, heatmap doesn't |
| Lower Back | Exists as `lowerback` | Direct map |
| Adductors, Abductors, Hip Flexors | **Not in the 14-key map at all** | These need **3 new muscle_map_keys** added to `MUSCLE_MAP_KEYS` (client and the server-side twin in `session-stats.js` on the other branch, if/when that merges) — the body diagram has no inner-thigh/hip-flexor region drawn today, so a new key with no heatmap region yet is a real, visible gap: the muscle WILL be tracked and filterable, but won't show on the sculpted body map until new SVG regions are drawn. Flagging this explicitly rather than silently dropping the muscle or forcing it onto `quads`/`glutes` (which would misattribute volume) |
| Full Body, Cardio | **Not in the 14-key map** (existing cardio-ish exercises today are tagged `muscle_group: 'Full Body'` as a body_region string, not a map key) | No map key needed — these are whole-body/conditioning entries that don't contribute to the per-muscle heatmap by design; leave `muscle_map_key` null for pure-cardio rows, same as a handful of existing entries already do |

**My recommendation, pending your confirmation before Phase 1 starts:**
add `adductors`, `abductors`, `hip_flexors` as real new map keys (so
nothing is silently merged into the wrong muscle for volume-tracking
purposes), fold the delt/upper-back splits into the existing single
keys for the heatmap only, and leave Full Body/Cardio unmapped. The new
keys having no drawn body-map region yet is the one real visible gap —
tell me if you'd rather I draw 3 small new regions (front-of-hip,
inner-thigh, outer-hip) on the existing diagram as part of Phase 1, or
leave them heatmap-invisible (library-filterable, just not shown as a
colored region) for now.

**Equipment**: currently free text, values in use today: `Barbell`,
`Bodyweight`, `Cable`, `Dumbbell`, `Machine`, `Medicine Ball`. The CSV
adds `Smith Machine`, `EZ Bar`, `Trap Bar`, `Landmine`, `Kettlebell`,
`Band`, `Sled`, `Cardio`, `Other` — all additive, no conflicts, just
more values for the same free-text column.

**Cue/form text fields**: `cue_setup`, `cue_execution`, `cue_mistake`,
`cue_bracing` — 4 separate fields today. The batch's Phase 1.5 asks for
"2 short form cues + 1 common mistake line" for the 255 new exercises —
I'll write into `cue_setup`/`cue_execution` for the two cues and
`cue_mistake` for the mistake line, leaving `cue_bracing` either blank
or with a short bracing note where one's genuinely useful, matching the
existing 102 exercises' own pattern (not every exercise's bracing note
says something distinctive).

## Plan builder / Block builder — data model and where it's stored

**No separate "blocks" table.** The user's one active generated
training block lives as a single JSONB blob:
`profiles.active_training_block` — `{ focus, priorities, days,
equipment, avoid, blockDays, createdDate }`, where `blockDays` is
`[{ label, groups, exercises }]` and each exercise entry is currently
just `{ name, muscle, sets, reps, tags, reason }` — **`reps` is a
string range like `"6-8"`, there's no `rest`, no `superset` grouping
field, and no `auto_progress` toggle anywhere in this shape.**

Generated by `generateBlock()` (a deterministic-ish rules engine:
`blockSplitTemplate(days)` picks a split, `pickMainExercise()`/
`pickAccessoryExercise()` pick real catalog exercises per target
muscle, filtered by equipment/avoid). **A manual-override mechanism
already exists** — swap/add/remove/edit-sets-reps on the CURRENT
block's JSON directly (`blockSwapPickerFor`, `blockExerciseRemoveConfirm`,
`blockAddPickerForDay` state), explicitly commented as "one-off
adjustments... never touches `generateBlock()`." This is the real
precedent Phase 5c should build on, not a new system.

**`plans`** (separate table) sequences multiple blocks via `phases`
(metadata: type/duration/reasoning/status) + `current_phase_index` —
the actual exercises for whichever phase is active still live in the
SAME `active_training_block` blob. One plan per user (`unique(user_id)`).

**`training_splits`** is explicitly NOT a program manager (its own
comment says so) — a lightweight "today's focus" hint + a Lifts-tab
filter, `{name, days: jsonb, start_date}`, one per user.

**Conflict with the mockup, flagged:** Phase 5a wants ~10 **named,
pre-authored, browsable** program templates (Full Body 3x, PPL 6x,
etc.) with weeks/progression/deload text that any user can browse
before starting. Nothing like this exists today — the current system
only ever generates ONE user-specific block from THEIR chosen
focus/priorities/equipment, there's no library of fixed named
templates. This needs genuinely new data. I'll decide the exact shape
(most likely a new `program_templates` table, read-only for users, same
RLS pattern as `exercises`) when I actually reach Phase 5 — flagging
the gap now, not solving it in this audit, since Phase 5 is several
phases away and the shape should reflect whatever Phase 5c's editable
"your version" needs by then.

**Conflict with the mockup, flagged:** Phase 5c wants per-exercise
`rest`, `superset_group`, and `auto_progress`, plus a real "Reset to
original" — the current exercise-entry shape has none of these. This is
an additive JSON-shape extension (new optional fields on the existing
blob), not a new table — consistent with "reuse the existing plan and
block data model... do not create a parallel system." "Reset to
original" can likely reuse the already-stored `{focus, priorities, days,
equipment, avoid}` generation params to regenerate a fresh block, though
I'll need to check whether `pickMainExercise()`/`pickAccessoryExercise()`
are fully deterministic or have any randomness before promising an exact
byte-for-byte reset.

## Workout tracker — screens, set saving, timer, resume

**This is the single biggest architectural gap in the whole batch, and
I want it confirmed before Phase 2 starts building around it.**

Today: `index.html`'s Lifts tab → Log sub-tab has a **single form**
(`liftForm` state object) for one exercise at a time — pick exercise,
type one weight, type reps per set (or a rep count + set count), hit
**"Add lift"** (`addLiftFromForm()` → one `lifts` row inserted). This is
a **retrospective batch-log action**, not a live, set-by-set session:
- No per-set real-time save — the whole exercise's sets are submitted
  together when the form is submitted.
- No rest timer exists anywhere in the current app (the mockup's pinned
  rest timer with a stored end-timestamp has no current equivalent to
  extend — it's new).
- No live elapsed-session-time tracking exists.
- `workout_sessions` (used by Session Analysis) only has
  `date, ended_at, analysis, analysis_generated_at` — no started-at,
  no per-exercise progress state, nothing to resume mid-workout from.
- Screen-wake-lock: not implemented anywhere.

**`lifts` table itself**: `weight numeric not null` is **one weight for
the whole row** — `reps_per_set numeric[]` varies per set, but weight
doesn't. `warmup_per_set` (bool[]), `muscle_map_keys` (text[] override),
`superset_group` (text — sibling rows sharing `(user_id, date,
superset_group)` are grouped) all already exist and fit the mockup's
superset concept directly.

**Conflict with the mockup, flagged:** the exercise screen's sets table
shows an editable weight+reps input per set row, which COULD imply
varying weight set-to-set. The current schema can't represent that (one
weight per logged row). **My default plan**: keep one weight per
exercise per session (matches how PR detection/e1RM/volume already
work everywhere, zero schema change, and matches how the vast majority
of real workouts are actually logged — same weight across working
sets). The input field pre-fills with that one weight and editing it
updates the whole row, same as today. Tell me now if you actually want
true per-set weight variation — that's a real (if small) schema
addition (`weights_per_set numeric[]` paralleling `reps_per_set`) I'd
rather add deliberately than retrofit later.

**What Phase 2 needs to build, concretely**: a live
`workout_sessions`-scoped in-progress state (per-set local persistence
with a sync queue, same "local first, then sync" the Water/food logging
already does elsewhere in this app, extended to real-time per-set
granularity instead of per-form-submit); a rest timer keyed to a stored
end timestamp (not a `setInterval` countdown) so it survives
backgrounding; Capacitor's keep-awake plugin for screen-sleep
prevention during an active session. None of this is a small patch —
it's new, foundational plumbing Phase 3's whole exercise screen sits on
top of. This is why the batch correctly orders Phase 2 before any
visual work, and I'll treat it with the same weight.

## PRs and estimated 1RM

`e1RM(weight, reps)` — Epley (`reps===1 ? round(weight) : round(weight *
(1 + reps/30))`), duplicated client (index.html) and server
(`_shared.js`), by design (no shared-module system between the
single-file client and the zero-dependency Netlify functions — this
codebase's established convention, confirmed across several unrelated
batches this session). `computeLiftPRs(lifts)` — all-time best weight
per exercise name, used for PR flags.

**Note on branch divergence**: a separate, unmerged branch
(`session-analysis-v2`) added a 12-rep-capped e1RM variant and a whole
new stats module for the post-workout AI analysis rebuild. **This
branch (`training-redesign`) does not have that work** — it's based on
`origin/main`, independent of it, per how every batch this session has
been kept isolated. Phase 3.8 says "do not rebuild session analysis in
this batch," so I'll leave the **current main-branch session analysis**
(the older summary/callouts/highlightExercise version, via
`buildSessionAnalysisSummary()` in `_shared.js`) completely alone and
just confirm Finish still navigates to it. If `session-analysis-v2`
merges before this branch does, reconciling the two will need a look at
merge time — flagging now so it isn't a surprise later.

## Session analysis entry point (today, on main)

`endWorkoutSession()` → `generateSessionAnalysis()` (if a baseline of
prior sessions is met + Pro access) → `analyze-session.js` →
`buildSessionAnalysisSummary()` (prose summary) → one Anthropic call →
cached in `workout_sessions.analysis` jsonb. Rendered by
`sessionAnalysisHtml()` in the Lifts tab's Log sub-view when
`ctx.ended` is true. This batch only needs Finish to keep reaching this
unchanged — confirmed straightforward, no action needed in Phase 3
beyond "don't break it."

## Library search and filters today

**Screen**: "Exercise Glossary" (`showExerciseGlossary`,
`renderExerciseGlossary()`), reached from Progress → Tools → Exercise
Library, or the Lifts tab's 📖 button. **Search**: name only
(`glossaryFilter.search`, simple substring match) — no alias matching.
**Filter**: a single muscle-group chip row (`glossaryFilter.muscleGroup`)
— no equipment filter, no type filter, no combining two dimensions.
This is the exact gap Phase 1.6 asks to close.

## What Phase 0 resolves vs. what it flags for your decision

**Resolved, no decision needed:**
- Exercise count today: 102.
- Cue fields: reuse the 4 existing columns as-is for the 255 new
  entries.
- Equipment: free text, new CSV values are purely additive.
- Dedup policy: fill genuinely missing fields only, never overwrite an
  existing non-null value on the 102 current exercises (protects
  hand-tuned data from a blind "merge" overwrite) — I'll report this as
  "merged N / skipped N / added N" with specifics per Phase 1's own
  request.

**Flagged, want your confirmation before Phase 1/2/5 start:**
1. **Muscle map compact/highlight feasibility** (Decision #1's own ask
   — see below, this is the big one).
2. Delt/upper-back sub-region folding + 3 new map keys
   (adductors/abductors/hip_flexors) with no drawn body-map region yet
   — acceptable, or draw 3 new regions now?
3. One weight per exercise per session (current, recommended) vs. true
   per-set weight variation (new column) — which do you want?
4. Program templates (Phase 5a) need new data not yet shaped — fine to
   decide the exact schema when Phase 5 actually starts?

## Muscle map: can it be highlighted per-muscle in a compact size
## without changes? (Decision #1)

**Short answer: yes, with one small additive change — not a rewrite,
and not blocked.** Specifics:

- **Geometry/assets**: `muscleMapBodySvg()`/`muscleMapPartSvg()`
  (index.html) draw a pure, resolution-independent SVG
  (`viewBox="0 0 200 420"`) — the same front/back body outline + 9-14
  muscle-region paths used by the existing full-size Muscle Map on the
  Lifts/Training sub-tab. Nothing about the paths themselves needs to
  change for a compact size — SVGs scale by CSS alone.
- **Front/back view selection already exists** — `MUSCLE_MAP_FRONT_PARTS`
  and `MUSCLE_MAP_BACK_PARTS` are already two separate datasets, picked
  by a `viewName` argument. Choosing front-or-back from an exercise's
  primary muscle is a one-line lookup table (chest/abs/quads/delts/
  biceps → front; lats/traps/glutes/hamstrings/triceps/lowerback →
  back), not a code change to the map itself.
- **Highlighting is the one real gap, and it's small**: today, every
  muscle's fill color comes from `muscleMapHeatColor(totals[key])` — a
  5-step heat gradient driven by weekly set volume. There's no path
  today to say "this one muscle is brass, that one is lighter brass,
  everything else is neutral" — the function only knows how to compute
  a heat-gradient color, not accept an explicit color per muscle.
  **Fix**: add one new optional parameter to `muscleMapPartSvg()`/
  `muscleMapBodySvg()` — an explicit `{primaryKey, secondaryKeys}` (or a
  precomputed color map) that, when passed, skips the heat-gradient
  lookup and uses brass/lighter-brass/neutral directly. The path data,
  shading gradient, and stroke treatment stay byte-for-byte identical —
  only the fill-color SOURCE branches.
- **Compact sizing, one real wrinkle to flag**: the natural aspect ratio
  of the existing viewBox is 200:420 ≈ 1:2.1 (full body including legs,
  quite tall and narrow). The mockup's placeholder dimensions (≈76×104pt,
  ≈1:1.37) imply a SHORTER, wider crop than the full-body figure
  naturally is. Two honest options, your call:
  (a) **Scale the full body down to fit the given width** — ends up
  closer to ~76×160pt than 76×104pt (taller than the mockup's exact
  numbers, but zero geometry change, true to "reuse exactly").
  (b) **Crop the viewBox** to just the torso+arms (or torso+legs,
  depending which half has the highlighted muscle) to hit something
  closer to the mockup's aspect ratio — this only changes the `viewBox`
  window, not any path's coordinates, so it's still "the same asset,"
  but it is a real decision about what's visible, not a pure CSS resize.
  I'd lean toward (a) for the exercise header (simpler, still reads
  fine at thumbnail size) and a much smaller icon-only treatment for
  the superset mini-version (where (a) vs (b) stops mattering — it's
  tiny either way). Tell me if you want (b) instead for either spot.

Nothing here blocks starting Phase 1. The muscle-map work itself only
becomes relevant starting Phase 3 (exercise header) — I'm flagging it
now, ahead of when it's needed, exactly as Decision #1 asks, not
touching the component yet.

## Next step

Per your own instructions, I'm stopping here for your review before
starting Phase 1. Four things would help before I start:
1. Confirm (or correct) the muscle-map approach above.
2. Confirm the delt/upper-back folding + new hip/adductor/abductor keys
   plan (and whether you want new body-map regions drawn now or later).
3. Confirm one-weight-per-session (recommended) vs. per-set weight.
4. Send the real mockup `.html` if you have it, or confirm the pasted
   text description is enough to build from.
