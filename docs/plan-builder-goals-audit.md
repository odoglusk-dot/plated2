# Krafft plan builder: GOALS + "WHY" evidence — Phase 0 audit

Read-only investigation, no code changed in this phase. Scope question answered at the end.

## 1. Which code is "the plan builder"?

There are **two separate, similarly-named systems** in `index.html`. This matters because the spec's behavior description only matches one of them.

### Block Builder — this is the one the spec describes

State: `blockBuilderFocus`, `blockBuilderPriorities`, `blockBuilderDays/Equipment/Avoid`. Entry point `BLOCK_FOCUS_OPTIONS` (~12832), generator `generateBlock()` (~13069), wizard screens `blockBuilderStep1Html`/`Step2Html`/`blockBuilderStep3Html` (~14940–15260).

Current wizard: **Step 1 "Focus"** (2 live options — Hypertrophy, Strength; 3 more declared but `comingSoon`/`athleteOnly`) → **Step 2 "Priorities"** (muscle chips, max 3 — this is the "which muscles to bring up" step the spec refers to) → **Step 3** (days/equipment/avoid) → **Preview** (sets/reps shown per exercise, Start / Customize).

This matches the spec phone-for-phone: a goal step is being added *before* the existing muscle-priority step; "Start this plan and Customize still create 'your version' (copy on edit)" is exactly `blockBuilderViewingActive`/`active_training_block` copy-on-edit, which is Block Builder's own existing behavior (and what the just-merged fidelity pass spent most of its time on). **Conclusion: "the plan builder" in this spec = the Block Builder. I'm proceeding on that reading.**

### Plan Builder — a different feature, not in scope

State: `planBuilderStep`, `PLAN_GOAL_TYPES` (~15625: `strength_target` / `event_prep` / `open_ended`), `PLAN_TEMPLATES`/`PLAN_PHASE_TYPES` (~15636–15700), generator `buildPlanPhases()` (~15724). This is a long-horizon **periodization sequencer** — it lays out phases (hypertrophy → strength → deload → peak → taper) across months toward a specific lift target or event date. It has nothing to do with `size/strength/athletic/functional/conditioning/general`, doesn't select exercises itself (each phase just points `generateBlock` at a different `BLOCK_SCHEME`/`PHASE_POOL` entry), and the spec never mentions phases, tapers, or event dates. **I'm leaving this untouched.**

If this reading is wrong, stop me before Phase 1 goes further — I did not find a third candidate.

## 2. Every hardcoded number in today's generation path

| What | Where | Current value | Goal-aware today? |
|---|---|---|---|
| Sets/reps per role | `BLOCK_SCHEME` (~12863) | `strength`/`hypertrophy` only (+ 4 Plan-only phase types: deload/maintenance/peak/taper) | No — only 2 real training goals exist |
| Rest between sets | `wlsStartRestTimer(90)` (~10565), the **only** call that starts a timer from logging a set | flat 90s for every exercise, every goal | **No — not goal-aware at all.** This is the single biggest gap: there is no per-goal (or even per-exercise) rest duration anywhere in the live-workout flow. `PROGRAM_TEMPLATES`' static `rest` strings (e.g. `"2:00"`) are stored but **never read** by the rest timer — confirmed by grep, nothing references `.rest` from a template at runtime. |
| Weight progression increment | `DOUBLE_PROGRESSION_INCREMENT_LB = 5` (~9642) | flat +5 lb for *every* goal/exercise once all sets hit the top of the rep range | No — same rule for size, strength, everything |
| Emphasis chip cap | `BLOCK_MAX_PRIORITIES = 3` (~12846) | 3 | Spec wants max 2 |
| Exercise-pool filter | `blockExercisePool()` (~12964) | requires `muscle_map_key` match + `block_types` includes `poolKey` | Pool keys today are only `'hypertrophy'`/`'strength'`/`'power_speed'` — no `athletic`/`functional`/`conditioning` pool exists |
| Day templates (split shape) | `blockSplitTemplate()` (~12883) | fixed push/pull/legs or upper/lower by day count, same for every focus | Spec wants athletic to run power-block-first/strength/trunk/single-leg instead — a different day shape entirely |

**None of this reads from a config file today** — every number above is a literal in the function that uses it, exactly as the spec's Phase 0.2 suspected.

## 3. Catalog audit

Caveat up front: the live `exercises` table is in Supabase, which I can't query directly from this sandbox. What follows is from `docs/krafft-exercise-catalog.csv` (the 255-row import review doc) plus every `supabase-schema-phase*.sql` file actually committed to this repo. One gap in that record: `supabase-schema-phase29-athlete-mode.sql` and `-phase30-plyometric-exercises.sql` are referenced by name (in phase37's own comments and in `index.html`'s `EXERCISE_POSITIONAL_TAGS` comment) but **do not exist in this repo** — they were evidently run directly against the live DB. Phase 37's comment claims Box Jump/Depth Jump/Broad Jump/Lateral Bound/Single-Leg Bound/both Medicine Ball throws already exist from that migration; I can't independently verify the DB still matches that claim, only that the CSV review doc (which predates phase37) doesn't list several of them.

**Tracking types** — spec asks for weight_reps/bodyweight_reps/time/distance_time: **all four already exist and are already used** (182/46/9/18 rows respectively in the CSV). No new tracking type is needed anywhere in this batch; Phase 3.2's "no new tracking type unless proven necessary" condition is already satisfied — jumps → `bodyweight_reps` (+ an optional height field, which doesn't exist as a column yet — additive if wanted), sprints/carries → `distance_time`.

**Tag coverage** — `movement_type`/`block_types`/`muscle_map_key`/`avoid_flags` were backfilled for 75 exercises in phase18 (explicitly "the original 102" per a later comment — the discrepancy is in the comments, not something I can resolve without DB access) out of 255 total. That means **the large majority of the catalog is invisible to `generateBlock()`/`blockExercisePool()` today**, goals batch or not — any exercise without a `muscle_map_key` can never be picked by the generator. This is a pre-existing limitation, not something introduced by this batch, but the new goal types will hit it immediately if their target exercises (carries, unilateral work) weren't in that original 75/102.

**New tag vocabulary the spec wants** (`power`, `plyo`, `carry`, `sprint`, `unilateral`, `trunk`) — none of these exist anywhere. The closest existing thing is `EXERCISE_POSITIONAL_TAGS` (~17348, a hardcoded JS lookup, not a DB column) with a *different* vocabulary (`power`/`reactive`/`lateral`/`agility`/`acceleration`/`endurance`) used only by the separate, gated Krafft Athlete Mode feature (sport/position picker → recommended drills). **These are two different systems and I'm not merging them**: Athlete Mode's `CONDITIONING_DRILLS` + `conditioning_log` table logs sprints/agility work as standalone timed/distance drills outside the lifts pipeline, gated behind `athlete_mode_enabled`. This spec's "athletic" goal is a plain, ungated Block Builder option — its jump/sprint/carry sets need to log through the normal `lifts` table like any other exercise (per Phase 3.2's own instruction), not through `conditioning_log`. Building the new tags as plain `exercises` columns, independent of Athlete Mode, is the only reading consistent with the spec text.

**Exercise gaps against the spec's example list** (checked against the CSV — several the spec assumed missing already exist): already present — Trap Bar Deadlift, Split Squat, Bulgarian Split Squat, Step-Up, Pallof Press, Farmer's Carry, Suitcase Carry, Sled Push, Sled Pull, Box Jump, Jump Squat, Medicine Ball Slam. Genuinely absent from the CSV: **Broad Jump** (though phase37's comment claims it exists in the live DB from phase30 — needs live confirmation), and **no sprint exercise of any kind** exists in the `exercises` table (Sprint Intervals only exists in the separate `CONDITIONING_DRILLS`/`conditioning_log` system). Phase 3.1's "hill sprint, 20m sprint" additions are real, needed work.

## 4. Scope and the additive-goal-field question

**Size**: this is comparable to the training-redesign fidelity pass just finished, possibly larger — it touches the core generator (`generateBlock`, `blockExerciseEntry`, `pickMainExercise`/`pickAccessoryExercise`), the live-workout rest timer (today genuinely goal-blind), the double-progression function, introduces two new config files plus a full evidence/citation system with its own reusable bottom sheet, needs new/extended catalog tagging, and rebuilds 4 wizard screens plus 3 more (athletic day, Why sheet, goal-change diff).

**Is a `goal` field additive and nullable?** Yes, trivially — `active_training_block` is stored as a single `jsonb` column (`supabase-schema-phase23-block-builder.sql`: `alter table profiles add column if not exists active_training_block jsonb`), generated and replaced client-side, never queried by field. Adding a `goal` key needs **no SQL migration at all** — existing blocks simply won't have it, and every read site treats it as optional: `focus === 'hypertrophy' → goal 'size'`, anything else (including missing) `→ 'general'`. This mapping function is the one piece of Phase 1 plumbing that touches old data, and it's non-destructive (never writes the mapped value back onto an old block, just computes it at read time).

## Blocker before Phase 2 can start

The spec's source of truth, `docs/krafft-plan-builder-goals-mockup.html` (7 phones), **was never provided** — it isn't in this repo and nothing matching that name was uploaded to this session. Per this same spec's own rule ("the mockup wins over your judgment... stop and ask, do not approximate") and the standing rule from the training-redesign pass, I can't build or screenshot-QA Phases 2–5 without it — any screen I designed from the text description alone would be exactly the kind of guess that rule exists to prevent.

**Phase 1 (`goals.config`) does not depend on the mockup** — every value it needs is in the spec's own table — so I'm proceeding straight to it now. I'll stop after Phase 1 and wait for the mockup file before touching any screen.
