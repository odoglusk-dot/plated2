# Krafft SMART PROGRAM batch — Phase 0 audit

Read-only investigation, no code changed in this phase.

## Mockup availability

`docs/krafft-smart-program-mockup.html` was not uploaded to this session — same situation as the goals batch. What I have instead is the batch spec's text description of all 9 phones, written out in full (exact copy, numbers, layout order) plus the rules table and evidence table verbatim. That's enough to build correct *content* and *behavior* against, but there's no actual image/HTML to screenshot-diff for Phase 8's pixel-fidelity QA. I'll build every screen's content and structure exactly as described, using this app's already-established visual language (card/chip/banner/btn-primary/mono-caps labels, the same components validated screenshot-by-screenshot in the training-redesign and goals-batch work) rather than inventing a new style — but Phase 8's "screenshot vs. reference" step will need either the real mockup file or an explicit sign-off that content-and-structure matching is the bar for this batch instead.

## 1. Where sessions, sets, plans, and blocks live today

**Sessions/sets**: the `lifts` table (`reset-schema.sql`). One row per exercise per day — `weight numeric not null` (a single weight for the whole day, not per-set), `reps_per_set numeric[]` (the real per-set rep counts), `sets integer`, `reps numeric` (the row's average reps, used by `e1RM`/PR code), `muscle_map_keys text[]` (optional override for custom exercises, added in a later phase), `warmup_per_set boolean[]`. **No per-set weight** — every set within one exercise/day shares one weight value. This matches the mockup's own examples exactly (`70 × 10, 10, 10`, `70 × 10, 9, 8` — flat weight, varying reps), so it's not a gap for this batch's progression rules, which all operate on "the weight for this exercise this session" plus the rep spread across sets.

**Estimated 1RM**: already fully built. `e1RM(weight, reps)` (~line 9215) is the Epley formula (`reps === 1 ? weight : weight * (1 + reps/30)`), already used everywhere — PRs, session analysis, the goal card, the strength score, the e1RM chart. Phase 2.3 ("estimated 1RM ... uses the same function as session analysis") is just calling this existing function; no new math needed.

**Plans/blocks**: `profiles.active_training_block`, one `jsonb` blob (`generateBlock()`'s output: `{ focus, priorities, days, equipment, avoid, blockDays, createdDate, sourceProgramId, sourceProgramName }`). **No block-number/week-in-block/block-length fields exist today** — this is exactly the gap Phase 3.1 asks to fill, and since the whole object is one unstructured jsonb blob (`alter table profiles add column if not exists active_training_block jsonb`, phase23), adding `blockNumber`/`weekInBlock`/`blockLength` keys is free — no migration, same pattern as the goals batch's (unmerged) `goal` key addition to this same object.

**Rotation/"today's workout"**: `computeBlockDayIndex(block, dateStr)` resolves which `blockDays[i]` a date lands on, by `((daysSince % n) + n) % n` from `block.createdDate` — a continuous A/B/C/... rotation, not pinned to specific weekdays. `effectiveBlockDayIndex(block, dateStr, overrides)` layers this week's reschedules on top (see below).

## 2. "Missed" days today, and how "today's workout" is chosen

There is **no explicit "missed" state anywhere** — a day either has nothing scheduled, or `effectiveBlockDayIndex` resolves to a `blockDays` index, full stop. Nothing currently checks "was this day's workout actually logged" and flags it as missed at end of day; that's genuinely new logic for Phase 4.1, and per the spec ("derived, not stored as a failure") it should stay that way — computed by checking `state.lifts` for that date against what the rotation said was scheduled, not written to the database as a failure record.

The existing reschedule mechanism is `profiles.schedule_overrides_this_week`, a `jsonb` map keyed by date: `{ action: 'skip' | 'moved_away' | 'moved_in', dayIndex?, shortened? }`, pruned to the current week automatically (`pruneScheduleOverrides`/`currentWeekKey`). This already covers exactly two of this batch's three missed-session options:
- **Skip** → `{ action: 'skip' }` already exists verbatim.
- **Do it today** (shift the rest of the week) → the existing `move_tomorrow` action (built this session, two chats ago) already does a two-day swap via `moved_away`/`moved_in` pairs; "shift the rest of the week" is a generalization of that same mechanism across more than one day, not a new concept.
- **Fold into next day** (merge accessories into the next session) → genuinely new; there's no "merge two days' exercise lists" operation today.

So the missed-session feature can very likely reuse this same `schedule_overrides_this_week` object and its `action` vocabulary (adding `fold_into_next` as a new action value) rather than needing a new column.

## 3. Where swap exists today, and its effect on history

Two things exist under the name "swap," neither of which is the smart-swap feature this batch describes:

1. **Block Builder's day editor** (`blockSwapPickerFor`, `data-block-ex-substitute`, `blockExercisePool()`) — lets you replace one exercise in one day of **your version** of the active block, going forward only. It edits `active_training_block.blockDays[i].exercises` directly and never touches `lifts`; already future-only/history-safe by construction. Its ranking is different from this batch's spec: it filters by `muscle_map_key` + `block_types` + equipment + `avoid_flags`, not "same primary muscle, then same movement pattern, then equipment, then same tracking type."
2. **The Exercise Library's "Swaps" tab** (`liftDetailSwapsTabHtml`, `computeSwapAlternatives`) — despite having a "Swap" button, this **does not swap anything**: clicking it just navigates to the alternative exercise's own History tab (`liftsSelectedExercise = btn.dataset.swapTo`). It's a browse/jump shortcut, not a swap action.

**A genuine smart-swap (reason chips → ranked alternatives → starting-weight suggestion → "just today" vs. "replace in my version" with undo) does not exist anywhere.** This is new work for Phase 6, matching the spec's own framing. `computeSwapAlternatives` is a reasonable starting point for the ranking function but needs reordering to match this spec's exact priority (same primary muscle required → same movement pattern → available equipment → same tracking type → not already in the workout → prefer previously-done exercises) and an equipment-aware "No equipment" filter it doesn't currently have.

## 4. Files to touch, migrations, and size estimate

**No SQL migrations needed anywhere in this batch.** Every new field fits as an additional key in an existing `jsonb` column:
- `active_training_block`: `+goal` (already proposed, unmerged, from the goals batch — this batch should read it the same way if present), `+blockNumber`, `+weekInBlock`, `+blockLength`, `+deload` (the one-week overlay: `{ active: bool, startedDate, reason: 'scheduled'|'reactive' }` — storing it inside the block object rather than a new column, since it's conceptually part of "what this block is doing right now").
- `schedule_overrides_this_week`: `+fold_into_next` as a new `action` value, same shape as existing entries.
- Possibly one new small per-user flag for "welcome-back session already offered/dismissed today" and "block review already shown for block N" — these are UI-dismissal state, not training data, and could live in existing `profiles` jsonb-ish fields or just be computed fresh each time (a welcome-back banner that reappears if not acted on isn't harmful, matching "never blocks the user"). I'll default to computing these fresh (no new storage) unless Phase 4/3 implementation turns up a concrete need to persist a dismissal.

**Everything else is index.html-only**, all additive:
- `program-rules.config` (a new top-level const, same convention as `GOALS_CONFIG`/`BLOCK_SCHEME`) — Phase 1.
- `evidence.config` additions (new `EVIDENCE_CONFIG` + the shared Why-sheet UI component) — Phase 7. **Important dependency**: the goals batch's own `EVIDENCE_CONFIG`/`GOALS_CONFIG`/Why-sheet are not on `main` (that branch is unmerged, stopped on its own missing mockup). Per this spec's own instruction ("if goals is not merged yet, default to the size goal's 6-15 and say so"), I'll build `EVIDENCE_CONFIG` and the Why sheet fresh on this branch, and rep ranges will default to a hardcoded 6-15 (the size goal's range) with a clear comment marking where to switch to reading `GOALS_CONFIG`/`goalForBlock()` once the goals batch merges. When that merge eventually happens, the two `EVIDENCE_CONFIG` objects (goals batch's and this one's) will need a one-time manual union by key — flagging now so it isn't a surprise later.
- The engine (`nextTargets`, `suggestDeload`, `planWeek`, `missedOptions`, `welcomeBack`, `weeklyVolume`, `rankSwaps`) as pure functions plus unit tests — new, `scripts/test-program-rules.mjs` or similar, following the same pattern as `scripts/lint-evidence.js`.
- Reused as-is: `e1RM`, `detectPlateau` (per-exercise plateau, reused for the block-review "stalled" callout), `pruneScheduleOverrides`/`currentWeekKey`/`effectiveBlockDayIndex`/`computeBlockDayIndex`, `computeSwapAlternatives` (as a starting point for `rankSwaps`, reordered), the Block Builder's day-editing plumbing (extended, not replaced).

**Size estimate**: comparable to the training-redesign fidelity pass in screen count (9 phones vs. that pass's larger total, but each screen here is more logic-dense — deload math, block timelines, missed-session previews, weekly volume bars, a full swap flow) plus a genuinely new pure-function engine with a real unit-test suite, which the other two batches didn't need. I'd expect this to be the largest of the three batches once Phases 1–8 are all done, mostly because of Phase 1 (engine + tests for every rule and edge case) and Phase 6 (swap flow has two full screens plus a ranking rewrite).

## Status

Per the batch's own "stop after each phase and report" rule (not overridden this time, unlike the goals batch), stopping here. Phase 1 (`program-rules.config` + engine + unit tests) needs no visual mockup at all — only the rules table, which was pasted in full — so I can start that immediately on your go-ahead without waiting on the missing HTML file.
