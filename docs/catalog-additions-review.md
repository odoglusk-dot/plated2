# Catalog additions for review — Krafft plan builder GOALS batch, Phase 3.1

Nothing in this file has been applied to the database. Per the spec's own instruction, these are proposed rows/changes for Owen to review before any SQL runs. See `docs/plan-builder-goals-audit.md` section 3 for how this list was derived (the live `exercises` table couldn't be queried directly from this sandbox — this is built from `docs/krafft-exercise-catalog.csv` and the committed `supabase-schema-phase*.sql` files).

## 1. Proposed new column

```sql
alter table exercises add column if not exists athletic_tags text[] not null default '{}';
```

Additive, nullable-equivalent (defaults to empty array), matches the existing `avoid_flags`/`block_types` array-column pattern (`supabase-schema-phase18-exercise-tags.sql`) rather than overloading either of those columns. Reasoning: `block_types` answers "which Block Builder pool can select this exercise" (a different axis); `athletic_tags` answers "which goals.config selection rule this exercise satisfies" (`power`, `plyo`, `carry`, `sprint`, `unilateral`, `trunk` — the six values the spec asks for). Values are independent — an exercise can carry both a `block_types` pool membership and one or more `athletic_tags`.

## 2. Proposed tag values for existing exercises

All of these already exist in the catalog (confirmed against the CSV) — no new rows, just proposed `athletic_tags` values:

| Exercise | Proposed tags | Why |
|---|---|---|
| Farmer's Carry | `carry` | Named carry exercise |
| Suitcase Carry | `carry`, `unilateral` | Carry, and one-sided load |
| Sled Push | `power` | Explosive, loaded drive |
| Sled Pull | `power` | Explosive, loaded pull |
| Box Jump | `plyo`, `power` | Reactive jump |
| Jump Squat | `plyo`, `power` | Reactive jump |
| Bulgarian Split Squat | `unilateral` | Single-leg-dominant |
| Split Squat | `unilateral` | Single-leg-dominant |
| Step-Up | `unilateral` | Single-leg-dominant |
| Pallof Press | `trunk` | Anti-rotation core work |
| Plank | `trunk` | Core stability |
| Ab Wheel Rollout | `trunk` | Core stability |
| Russian Twist | `trunk` | Core rotation |
| Clean | `power` | Olympic-lift-family, explosive |
| Power Clean | `power` | Olympic-lift-family, explosive |
| Clean and Jerk | `power` | Olympic-lift-family, explosive |
| Snatch | `power` | Olympic-lift-family, explosive |
| Trap Bar Deadlift | — (none) | Compound strength lift, no athletic characteristic beyond that |

Separately, `index.html`'s existing `EXERCISE_POSITIONAL_TAGS` (~line 17348) already tags Box Jump, Depth Jump, Broad Jump, Lateral Bound, Single-Leg Bound, Tuck Jump, Squat Jump, and both Medicine Ball throws with a *different* vocabulary (`power`/`reactive`/`lateral`/`agility`/`acceleration`/`endurance`) for the separate, gated Krafft Athlete Mode sport/position feature. If those exercises exist in the live DB (per phase37's comment — unverified from this sandbox), they should get `athletic_tags` too: Depth Jump/Broad Jump/Lateral Bound/Tuck Jump/Squat Jump → `plyo`, `power`; Single-Leg Bound → `plyo`, `unilateral`; both Medicine Ball throws → `power`.

## 3. Proposed new exercises

Checked against the CSV and found genuinely absent — **no sprint exercise of any kind exists in the `exercises` table** (Sprint Intervals exists only in `CONDITIONING_DRILLS`, logged via the separate `conditioning_log` table, not through normal sets/reps — see the audit's point 3 for why that system can't be reused here).

```
Hill Sprint — tracking: distance_time, athletic_tags: {sprint}, equipment: Bodyweight, category: plyometric
20m Sprint — tracking: distance_time, athletic_tags: {sprint}, equipment: Bodyweight, category: plyometric
```

Full cue/hypertrophy-field content (matching the existing catalog's format — cue_setup/cue_execution/cue_mistake/cue_bracing) has not been drafted yet; flagging the need for these two rows now, content to follow once the column/tagging approach above is approved.

**Broad Jump**: phase37's own comment claims this already exists in the live DB (from an uncommitted `supabase-schema-phase30-plyometric-exercises.sql`), but it is not in the CSV review doc and that SQL file isn't in this repo to verify against. **Needs a live DB check before either adding it again or just tagging the existing row** — flagging rather than guessing, per the "do not approximate" rule.

## 4. Not proposed

Everything else in the spec's example list (med-ball throws, trap bar deadlift, split squat, suitcase/farmer carry, step-up, Pallof press) already exists in the catalog under the same or an equivalent name — adding near-duplicate rows would split one exercise into two confusing library entries, same reasoning phase37 used when it found the same thing for its own request list.

## Status

Proposed only. No SQL has been run. Waiting for Owen's review before (a) adding the `athletic_tags` column, (b) applying the tag values in section 2, (c) confirming the Broad Jump situation and adding the two genuinely-new sprint exercises in section 3 with full cue content.
