# Plated Schema Reference — Complete Column Listing

**Last Updated:** 2026-07-29  
**Status:** All tables consistent with `protein_g`, `carbs_g`, `fat_g` naming

---

## Complete Table Schemas

### `profiles` — User identity & physical stats
```sql
id                    uuid primary key
display_name          text
age                   int
sex                   text ('male' | 'female')
height_cm             numeric
activity_level        text ('sedentary' | 'light' | 'moderate' | 'active' | 'very_active')
age_over_18           boolean
age_gate_shown_at     timestamptz
parental_consent_at   timestamptz
referral_code         text unique
email_reminders_opt_out boolean (default: false)
onboarded_at          timestamptz — set once the first-time onboarding overlay finishes/is skipped
glossary_exercises_viewed text[] (default: '{}') — distinct Exercise Glossary cue cards expanded
learning_paths_completed text[] (default: '{}') — path ids from LEARNING_PATHS finished (also feeds Learning achievements)
active_training_block jsonb (nullable) — the user's current generated Block Builder plan, or null if none is active; see the Block Builder section below
created_at            timestamptz
```
**Frontend reads/writes:** `id, display_name, age, sex, height_cm, activity_level, age_over_18, age_gate_shown_at, parental_consent_at, referral_code, email_reminders_opt_out, onboarded_at, glossary_exercises_viewed, learning_paths_completed, active_training_block`

`age_over_18`/`age_gate_shown_at`/`parental_consent_at` are set once at
signup (see the `#authForm` submit handler and `ensureProfileAndGoals()` in
`index.html`) — a soft, logged checkpoint, not an enforced technical block.
`referral_code` is generated client-side at signup (`generateReferralCode()`)
with a retry-on-collision loop; older accounts get one lazily via
`ensureReferralCode()` the first time they open the Profile tab.

---

### `goals` — Daily nutrition targets
```sql
user_id                uuid primary key
calories                int (default: 2200)
protein_g               int (default: 150)       ← WITH _g suffix
carbs_g                 int (default: 250)       ← WITH _g suffix
fat_g                   int (default: 70)        ← WITH _g suffix
water_oz                numeric (default: 64) — flat editable default, not calculator-derived
goal_mode                text (default: 'maintain') ('lose' | 'maintain' | 'gain')
goal_mode_changed_at     timestamptz — only stamped when goal_mode actually changes value
updated_at              timestamptz
```
**Frontend reads/writes:** `user_id, calories, protein_g, carbs_g, fat_g, water_oz, goal_mode, goal_mode_changed_at, updated_at`  
⚠️ **CRITICAL:** All macros use `_g` suffix. If your DB has `protein`, `carbs`, `fat` (without `_g`), goals won't display properly.

`goal_mode` drives two things in `index.html`: the calculator's macro split
(`MACRO_SPLIT_BY_GOAL` — protein g/lb and fat% both shift by goal) and the
dashboard's soft calorie-range shading (`calorieRangeForGoal()`) — a muted
ring color when today's total falls outside a healthy zone for that goal,
never a hard alert.

`goal_mode_changed_at` is written by `withGoalModeTracking()`, wrapped
around every `goals` upsert that sets `goal_mode` (the Goal Calculator and
onboarding's auto-calculated step) — it only updates the timestamp when the
incoming `goal_mode` differs from what's currently loaded in
`state.goals.goal_mode`, so re-saving the same goal mode (e.g. re-running
the calculator with a new weight but the same "lose" goal) doesn't reset
the clock. The `goal_mode_changed` tip trigger (Layer 1 tips library) reads
this to give logged behavior a several-day grace period after a goal
change before nudging about a mismatch.

---

### `body_stats` — Current weight for goal calculator
```sql
user_id     uuid primary key
weight_kg   numeric
updated_at  timestamptz
```
**Frontend reads/writes:** `user_id, weight_kg, updated_at`

---

### `food_logs` — Daily food log entries
```sql
id          uuid primary key
user_id     uuid
food_name   text
calories    numeric
protein_g   numeric         ← WITH _g suffix
carbs_g     numeric         ← WITH _g suffix
fat_g       numeric         ← WITH _g suffix
source      text ('manual' | 'ai_text' | 'ai_photo' | 'favorite' | 'common' | 'barcode')
photo_path  text (optional — path within the food-photos bucket, "<user_id>/<file>.jpg")
sugar_g     numeric (optional — only ever set by a barcode scan; nullable for every other source)
barcode     text (optional — the scanned code, kept even if the lookup failed and the entry was finished manually)
logged_at   timestamptz (indexed)
created_at  timestamptz
```
**Frontend reads:** `logged_at, (all other columns via select(*))`, ordered by `logged_at desc`  
**Frontend writes:** `user_id, food_name, calories, protein_g, carbs_g, fat_g, source, photo_path, sugar_g, barcode`

`photo_path` (added in `supabase-schema-phase10-food-photos.sql`) is only
ever set when a meal was logged from the "Snap a Photo" AI-estimate flow
and the upload succeeded — every other logging path leaves it null. Same
signed-URL display pattern as `photos.storage_path`: the image lives in
the private `food-photos` bucket, this column just tracks the path.

`sugar_g`/`barcode`/the `'barcode'` source value (added in
`supabase-schema-phase21-barcode-scanning.sql`) back the barcode scanner
— no cache table for barcode lookups on purpose, since Open Food Facts is
free with no meaningful rate limit at this app's scale; a direct API call
per scan is simpler than maintaining a cache that solves no real cost
problem.

---

### `food_cache` — Shared nutrition data (all users)
```sql
description_key   text primary key
food_name         text
calories          numeric
protein_g         numeric       ← WITH _g suffix
carbs_g           numeric       ← WITH _g suffix
fat_g             numeric       ← WITH _g suffix
created_at        timestamptz
```
**Frontend reads/writes:** `food_name, calories, protein_g, carbs_g, fat_g`

---

### `favorites` — Saved foods for quick logging
```sql
id          uuid primary key
user_id     uuid
food_name   text
calories    numeric
protein_g   numeric       ← WITH _g suffix
carbs_g     numeric       ← WITH _g suffix
fat_g       numeric       ← WITH _g suffix
created_at  timestamptz
```
**Frontend reads:** `id, food_name, calories, protein_g, carbs_g, fat_g`  
**Frontend writes:** `user_id, food_name, calories, protein_g, carbs_g, fat_g`

---

### `weight_log` — Weight tracking history
```sql
id          uuid primary key
user_id     uuid
logged_date date (indexed)
weight_lb   numeric
note        text (optional)
source      text (default 'manual' | 'healthkit_shortcut' — a partial unique index on (user_id, logged_date) applies only to 'healthkit_shortcut' rows, so manual multi-entry per day is untouched)
created_at  timestamptz
```
**Frontend reads:** `logged_date, weight_lb, note` (via select(*), order by `logged_date desc`)  
**Frontend writes:** `user_id, logged_date, weight_lb, note` — `source` is only ever written by the health-sync webhook (service role), never the client directly.

---

### `health_sync_tokens` / `sleep_log` / `steps_log` — Apple Health sync (beta)
Added in `supabase-schema-phase22-apple-health-sync.sql`, backing the iOS
Shortcut → webhook Apple Health route (native HealthKit is unreachable
from a website or home-screen web app, so this is the free/no-App-Store
path; a Capacitor + HealthKit native wrapper is the possible later
upgrade — see the guide entry for the tradeoffs).
```sql
-- health_sync_tokens (one row per user)
id            uuid primary key
user_id       uuid unique
token_hash    text unique   -- SHA-256 hash only; no plaintext column, ever
created_at    timestamptz
last_used_at  timestamptz
revoked_at    timestamptz

-- sleep_log / steps_log (one row per user per day)
id           uuid primary key
user_id      uuid
logged_date  date
hours / steps numeric / integer
source       text (default 'healthkit_shortcut')
created_at   timestamptz
unique (user_id, logged_date)  -- makes a Shortcut run twice for the same day idempotent
```
**Frontend reads:** `select own` RLS only, for the Settings card's "last
synced" indicator — no client-side writes to any of these three tables.
Token issuance/regeneration/revocation goes through
`netlify/functions/health-sync-token.js` (an authenticated,
client-callable function using the caller's normal Supabase session);
actual health data is written only by `netlify/functions/health-sync.js`
(the public webhook the Shortcut posts to, authenticated by the token
hash — not a Supabase session — using the service-role key server-side).
The raw token is shown to the user exactly once, at generation time; only
its hash is ever persisted.

---

### `profiles.active_training_block` — Optional Block Builder
Added in `supabase-schema-phase23-block-builder.sql`. A single jsonb blob
rather than a relational table, since the whole plan is generated fresh
client-side from fixed rules every time and only ever fully replaced or
cleared — never queried by field:
```json
{
  "focus": "hypertrophy" | "strength",
  "priorities": ["chest", "abs"],
  "days": 4,
  "equipment": ["Barbell"],
  "avoid": ["heavy_spinal_load"],
  "blockDays": [
    { "label": "Upper A", "groups": ["push", "pull"], "exercises": [
      { "name": "Bench Press", "muscle": "chest", "sets": 3, "reps": "8-12",
        "tags": [], "reason": "Primary compound movement for Chest." }
    ] }
  ],
  "createdDate": "2026-09-28"
}
```
Generated and read entirely client-side (`generateBlock()` in
`index.html`) from the `exercises` table's existing tags
(`block_types`, `movement_type`, `muscle_map_key`, `avoid_flags`,
`lengthened_bias` — see phase18). Deliberately independent of
`training_splits`: starting or ending a block never touches the split
picker, the split's "today's focus" card, or suggested-exercises logic.
Rep/set numbers are this app's own program-writing convention, not a
research citation — Hypertrophy's main-lift rep range intentionally
reuses the same 6-12 figure already cited elsewhere
(`CITATION_LIBRARY.hypertrophy`) rather than introducing an uncited
second number for the same thing.

---

### `supplement_logs` — Supplement intake tracking
```sql
id               uuid primary key
user_id          uuid
supplement_name  text
dose             text (optional)
logged_at        timestamptz (indexed)
created_at       timestamptz
```
**Frontend reads:** `supplement_name, dose, logged_at` (via select(*), order by `logged_at desc`)  
**Frontend writes:** `user_id, supplement_name, dose`

---

### `water_logs` — Hydration quick-add entries
```sql
id          uuid primary key
user_id     uuid
amount_oz   numeric
logged_at   timestamptz (indexed)
created_at  timestamptz
```
**Frontend reads:** `amount_oz, logged_at` (via select(*), order by `logged_at desc`)  
**Frontend writes:** `user_id, amount_oz`

One row per quick-add tap (e.g. "+8oz"), not a running daily total — "today's"
and "this week's" totals are summed client-side from `logged_at`, the same
pattern `food_logs` already uses. No update policy: entries are logged or
deleted, never edited in place.

---

### `ai_usage` — Daily AI call rate limiting + real cost tracking
```sql
user_id             uuid
usage_date          date
count               int (default: 0)
input_tokens        bigint (default: 0)
output_tokens       bigint (default: 0)
estimated_cost_usd  numeric(10,6) (default: 0)
primary key         (user_id, usage_date)
```
**Backend reads/writes:** `user_id, usage_date, count, input_tokens, output_tokens, estimated_cost_usd`
(Frontend never touches this table directly)

`count` is incremented before each Anthropic call for rate limiting.
`input_tokens`/`output_tokens`/`estimated_cost_usd` are accumulated
*after* each successful call from Anthropic's real `usage` response and the
model that actually served it — see `recordUsageCost()` and
`getPricingTable()` in `netlify/functions/_shared.js`, and the admin-only
monthly cost query in `DEPLOYMENT.md`.

---

### `subscriptions` — Whole-app paywall (Stripe)
```sql
user_id                 uuid (primary key)
status                  text (default: 'free', check in free/trialing/active/canceled/past_due)
stripe_customer_id      text
stripe_subscription_id  text
current_period_end      timestamptz
cancel_at_period_end    boolean (default: false)
updated_at              timestamptz (default: now())
```
**Backend writes:** `netlify/functions/stripe-webhook.js` only, using
`SUPABASE_SERVICE_ROLE_KEY` (bypasses RLS).
**Frontend reads:** `status, current_period_end, cancel_at_period_end` —
RLS grants select-own and nothing else; there is deliberately no
insert/update policy for the `authenticated` role.

One row per user, keyed by `user_id`. `index.html`'s `enterApp()` reads this
before showing `#app` on every sign-in/reload — anything other than
`status IN ('trialing', 'active')` shows `#paywallScreen` instead. Status
transitions are driven entirely by Stripe's `customer.subscription.*`
webhook events; the app itself never writes to this table.

`cancel_at_period_end` mirrors Stripe's own field rather than inventing a
third status value: canceling via the Customer Portal sets it `true` while
`status` stays `'active'` until the paid period actually ends (only then
does Stripe fire `.deleted` and `status` becomes `'canceled'`). So the
`status`-only access check above already grants access through the paid
period correctly — this column exists purely so the Profile tab can
*display* "canceling, access until `<date>`" via `subscriptionStatusLabel()`
instead of showing a plain "active" that hides a received cancellation.

---

### `referrals` — Referral attribution + reward status
```sql
id                  uuid primary key default gen_random_uuid()
referrer_user_id    uuid
referred_user_id    uuid unique
referral_code       text
status              text (default: 'pending', check in pending/rewarded)
created_at          timestamptz
rewarded_at         timestamptz
```
**Backend writes:** `netlify/functions/redeem-referral.js` (creates the row
at signup) and `netlify/functions/stripe-webhook.js` (marks it `rewarded`),
both using `SUPABASE_SERVICE_ROLE_KEY`.
**Frontend reads:** `status` — RLS grants select-own-as-referrer only
(`auth.uid() = referrer_user_id`); there is no insert/update policy for the
client at all.

One row per *referred* user, ever (`referred_user_id` is unique — one
attribution per account, forever). `status` flips from `pending` to
`rewarded` only when `stripe-webhook.js` sees the referred user's
subscription transition from `trialing` to `active` (a real paid
conversion) — see "Referral Program" in `DEPLOYMENT.md`. Only the referrer
is ever rewarded; the referred user gets nothing extra beyond the normal
3-day trial.

---

### `lifts` — Strength-training log entries (IronLog merge)
```sql
id               uuid primary key
user_id          uuid
exercise         text
muscle_group     text (optional)
weight           numeric
sets             integer
reps_per_set     numeric[]
reps             numeric
date             date (indexed)
superset_group   text (optional — bundles entries into one superset/circuit)
body_region      text (optional — muscle-map region, e.g. 'chest', 'quads')
warmup_per_set   boolean[] (default '{}' — parallel to reps_per_set; true = that set was a warm-up)
created_at       timestamptz
```
**Frontend reads/writes:** `exercise, muscle_group, weight, sets,
reps_per_set, reps, date, superset_group, body_region, warmup_per_set`

`warmup_per_set` (added by `supabase-schema-phase19-warmup-sets.sql`) feeds
the weekly hard-sets-per-muscle feature only — an empty array means no
sets in that row are flagged, so pre-migration rows and rows where the
user never touches the warm-up toggle still count every set as working,
exactly as before this column existed. PR detection, career volume, and
the muscle map heatmap deliberately still count every set regardless of
this flag.

Ported from IronLog's own schema as-is — no naming collision with anything
in Plated's nutrition side.

---

### `exercise_goals` — One live goal per exercise (IronLog merge)
```sql
id              uuid primary key
user_id         uuid
exercise        text
target_weight   numeric
target_date     date
created_at      timestamptz
unique           (user_id, exercise)
```
**Frontend reads/writes:** `exercise, target_weight, target_date`

**Named `exercise_goals`, not `goals`** — this is IronLog's `goals` table,
renamed on the way in because Plated already has a `goals` table (the
per-user macro/hydration targets above). Same name, unrelated shape and
meaning; keeping IronLog's original name would have silently collided.
Setting a new goal for an exercise replaces the old one (upsert on
`user_id, exercise`).

---

### `monthly_recaps` — Cached monthly training recap stats (IronLog merge)
```sql
id                                 uuid primary key
user_id                            uuid
month                              date (first day of the month, e.g. 2026-07-01)
total_volume                       numeric
training_days                      integer
most_trained_muscle_group          text (optional)
most_trained_muscle_group_volume   numeric (optional)
biggest_pr_exercise                text (optional)
biggest_pr_weight                  numeric (optional)
biggest_pr_improvement             numeric (optional)
bodyweight_start                   numeric (optional)
bodyweight_end                     numeric (optional)
computed_at                        timestamptz
unique                              (user_id, month)
```
**Frontend reads/writes:** all columns above except `id`/`computed_at`.

Computed client-side from already-loaded `lifts` and `weight_log` (see
`computeMonthlyRecap()` in the Recaps tab), then cached here so a given
month is only computed once. `bodyweight_start`/`bodyweight_end` come from
`weight_log`, not a separate bodyweight table — see the note on bodyweight
unification below.

**Bodyweight note:** IronLog originally tracked bodyweight in its own
table. That table was **not** ported — Plated's existing `weight_log`
above (`weight_lb`, `logged_date`) is the same shape as IronLog's
`bodyweight` (`weight`, `date`), same unit (lb), so bodyweight tracking
was unified into the table that already existed rather than duplicated.

### `photos` — Progress photos (IronLog merge, Photos tab)
```sql
id                                 uuid primary key
user_id                            uuid
storage_path                       text (path within the progress-photos bucket, "<user_id>/<file>.jpg")
note                               text (optional)
date                               date
created_at                         timestamptz
```
**Frontend reads/writes:** `storage_path` (write-once, at upload time),
`note` (editable after the fact), `date`.

Images themselves live in the `progress-photos` Storage bucket (private,
folder-scoped to `auth.uid()`, created in
`supabase-schema-phase7-ironlog.sql`) — this table just tracks each
upload's path. Display URLs are short-lived signed URLs generated
client-side (`supabase.storage.from('progress-photos').createSignedUrl(...)`),
never a public link, since the bucket isn't public.

### `training_splits` — Active weekly training split (presets + custom)
```sql
id                                 uuid primary key
user_id                            uuid (unique — one active split per user)
name                               text
days                               jsonb (ordered array: [{"label": "Push", "muscle_groups": ["Push"]}, ...])
start_date                         date (day 1 of the rotation)
created_at                         timestamptz
updated_at                         timestamptz
```
**Frontend reads/writes:** all of `name`/`days`/`start_date` together, via
upsert — picking a preset or saving the custom builder replaces the whole
row (`onConflict: 'user_id'`) rather than versioning multiple saved splits.

Deliberately lightweight: one row per user, not a program-management
system. "Today's slot" is computed client-side —
`daysSinceStart % days.length` — from `start_date`, never stored as its
own column. `muscle_groups` values match the app's existing
`MUSCLE_GROUPS` categories (`Legs`/`Push`/`Pull`/`Core`/`Full Body`/`Other`)
so the Lifts tab can highlight exercises tagged to today's focus; this is
a hint only, never restricts logging.

---

### `plans` — Workout Plan Builder (sequences multiple Training Blocks)
```sql
id                  uuid primary key
user_id             uuid (unique — one active plan per user)
goal_description    text (free text, e.g. "Add 30 lb to my bench in 4 months")
goal_type           text ('strength_target' | 'event_prep' | 'open_ended')
target_exercise     text (optional — points at an exercise_goals row rather
                     than duplicating target/projection tracking here)
event_date          date (optional — only meaningful for 'event_prep', drives
                     taper phase placement)
phases              jsonb (ordered array, metadata only — see below)
current_phase_index int (default 0)
current_phase_started_at date (updated whenever the user advances a phase)
priorities          jsonb (default []; carried into every phase's block)
days                int
equipment           jsonb (default [])
avoid               jsonb (default [])
started_at          date
created_at          timestamptz
updated_at          timestamptz
```
**Frontend reads/writes:** the whole row via upsert (`onConflict: 'user_id'`)
— same replace-not-version philosophy as `training_splits`. `phases`:
```json
[{ "type": "hypertrophy" | "strength" | "deload" | "peak" | "maintenance" | "taper",
   "duration_weeks": 4,
   "reasoning": "Starting with hypertrophy to build a base, then shifting to strength once you've logged 4 weeks of volume.",
   "status": "upcoming" | "active" | "completed" }]
```

Deliberately stores no exercise plan per phase — only the *current* phase's
actual block lives anywhere, in the existing
`profiles.active_training_block` blob, generated by the same
`generateBlock()` rules engine Block Builder already uses (now accepting a
`schemeKey`/`poolKey` pair instead of a single `focus`, so phase types like
`deload`/`peak`/`maintenance`/`taper` can pick their own sets/reps scheme
while still drawing from the `hypertrophy`- or `strength`-tagged exercise
pool). Advancing to the next phase is user-confirmed (a "Start next phase"
button, not automatic) and regenerates `active_training_block` fresh —
completed phases leave no exercise-level history behind, matching how a
standalone Block already has none.

---

### `groups` / `group_members` / `group_freeze_log` / `group_goals` — Group Mode
```sql
-- groups: one row per group
id                          uuid primary key
name                        text
creator_id                  uuid
current_streak              int (default 0)
best_streak                 int (default 0)
freezes_available           int (default 0, capped at 3 by evaluate-groups.js)
last_evaluated_date         date
last_achievement_check_at   timestamptz
created_at                  timestamptz

-- group_members: many rows per group, one per member/invitee
id            uuid primary key
group_id      uuid
user_id       uuid (unique per (group_id, user_id))
status        text ('invited' | 'joined')
invited_at    timestamptz
joined_at     timestamptz (nullable until accepted)

-- group_freeze_log: append-only earn/spend ledger
id          uuid primary key
group_id    uuid
kind        text ('milestone_earned' | 'achievement_earned' | 'spent')
member_id   uuid (set only for achievement_earned — a compliment, not
            blame; null for spent/milestone_earned so the log never
            singles out who missed a day)
created_at  timestamptz

-- group_goals: a shared target, separate from the streak mechanic
id            uuid primary key
group_id      uuid
description   text
target_type   text ('total_sessions' — one type for v1)
target_value  numeric
period_start  date
period_end    date
created_by    uuid
created_at    timestamptz
```
**Frontend reads:** all four tables, RLS-scoped to fellow group members
(a self-referential subquery against `group_members`), via `get-group.js`.
**Frontend writes:** only `group_members.status` (accepting/declining an
invite, or leaving — self-row update/delete, same shape as accepting a
friend request) and `group_goals` inserts (any joined member). Everything
else — creating a group, inviting someone, the daily streak/freeze
evaluation — only ever happens through a service-role Netlify function;
there is no client insert policy on `groups`, `group_members`, or
`group_freeze_log` at all.

One active group per user (app-enforced in `create-group.js`/
`invite-to-group.js`, not a DB constraint — same "no DB trigger, enforce
limits in code" style as `BLOCK_MAX_PRIORITIES`). Built on the existing
`friendships` table, not a new social graph — `invite-to-group.js` only
lets a member invite someone who is already their accepted friend.

"Hit your goal" reuses the *existing* protein-goal streak definition
(`computeStreaks()` in `index.html` — daily `food_logs` protein sum `>=`
`goals.protein_g`), ported server-side in `evaluate-groups.js`. This is
deliberately **not** the same as the training-day streak the Friends
Leaderboard already shows (`computeTrainingStreak()`) — two separate,
pre-existing streak concepts in this app, and Group Mode uses the one
actually branded "streak" on the dashboard.

Bonus freezes for a member's achievement unlock can't be real-time —
achievement unlocking is 100% client-side with no server code path — so
`evaluate-groups.js` diffs `user_achievements.unlocked_at` against each
group's `last_achievement_check_at` once daily, same known-limitation
shape `send-reminder-emails.js` already accepts for its "evening" email
timing.

3 new notification toggles live as plain boolean columns on `profiles`
(`group_streak_emails_opt_out`, `group_freeze_emails_opt_out`,
`group_goal_emails_opt_out`), same `_opt_out`/default-false polarity as
`email_reminders_opt_out`.

---

### `exercises` — Exercise database (reference data, not user-scoped)
```sql
id                                 uuid primary key
name                               text (unique — e.g. "Bench Press")
muscle_group                       text (one of MUSCLE_GROUPS: Legs/Push/Pull/Core/Full Body/Other)
body_region                        text (one of BODY_REGIONS, nullable for Full Body lifts like Power Clean)
secondary_regions                  text[] (BODY_REGIONS values, not muscle groups — more informative)
equipment                          text (e.g. "Barbell", "Dumbbell", "Bodyweight", "Cable", "Machine")
cue_setup                          text
cue_execution                      text
cue_mistake                        text
cue_bracing                        text
hypertrophy_rep_range              text (e.g. "6–12 reps"; nullable)
hypertrophy_rest_interval          text (e.g. "2–3 min"; nullable)
hypertrophy_tempo                  text (e.g. "2-1-1 tempo — lower for 2 sec…"; nullable)
hypertrophy_mind_muscle_cue        text (one-line mind-muscle-connection cue; nullable)
movement_type                      text ('compound' | 'isolation'; nullable)
lengthened_bias                    boolean (default false — true if the exercise notably loads the muscle at long length, e.g. RDL, Nordic Curl)
avoid_flags                        text[] (default '{}' — values in use: 'overhead', 'heavy_spinal_load'; 'impact' reserved, unused)
block_types                        text[] (default '{}' — values in use: 'strength', 'hypertrophy', 'power_speed'; 'mobility'/'functional_athletic' reserved, unused)
muscle_map_key                     text (one of the 14 muscle-map keys — see below; nullable)
muscle_map_secondary_keys          text[] (default '{}' — same 14-key taxonomy)
image_url                          text (nullable — reserved for a future visual-assets pass)
video_url                          text (nullable — reserved for a future visual-assets pass)
created_at                         timestamptz
```
**Frontend reads:** select-only for every account (`exercises_select_all`
RLS policy, no insert/update/delete policy) — this is shared reference
content, not per-user data. Seeded once by
`supabase-schema-phase13-exercises.sql` with ~30 common compound/accessory
lifts, then replaced (truncate + reinsert — safe, since nothing references
`exercises.id` by foreign key) by
`supabase-schema-phase17-exercise-hypertrophy.sql` with the full ~75-exercise
library plus the four `hypertrophy_*` columns above, then tagged in place
(plain updates, no truncate) by `supabase-schema-phase18-exercise-tags.sql`
with the columns above; not user-editable.

**`muscle_map_key`/`muscle_map_secondary_keys` taxonomy** (14 keys, used by
the weekly-sets-per-muscle feature and the sculpted muscle map): `chest`,
`delts`, `biceps`, `triceps`, `forearms`, `abs`, `obliques`, `quads`,
`calves`, `traps`, `lats`, `lowerback`, `glutes`, `hamstrings`. This is
more granular than `body_region` above (which stays as-is for the
existing simple muscle map and `DEFAULT_BODY_REGION` fallback) — it splits
`shoulders` into `delts`, splits `back` into `lats`/`traps`/`lowerback`,
and adds `obliques`. All 75 exercises mapped cleanly; see phase18's header
comment for the handful of judgment calls (e.g. Deadlift and the
Olympic-lift family are keyed to `lowerback` as their single primary key,
matching their existing `body_region`; Farmer's Carry is keyed to
`forearms` as grip-dominant).

**Build once, reuse across features** — this single table powers:
- **Cue cards**: the first time a user logs an exercise (or after a long
  gap), the app shows its 4 cue bullets (setup/execution/common mistake/
  bracing) — static copy, not AI-generated, same spirit as the Layer 1
  tips library.
- **Hypertrophy guidance**: rep range/rest interval/tempo/mind-muscle cue,
  shown alongside the cue card. The citation backing rep-range guidance
  (Schoenfeld et al. 2017) lives in a static `CITATION_LIBRARY` object in
  index.html, not a column here — it's the same citation reused across
  every exercise, so a column would just duplicate the same string ~75
  times. Rest interval and tempo show as general coaching guidance with no
  citation attached (the source originally cited for rest interval — Grgic
  et al. 2018 — covers strength outcomes, not hypertrophy, and was removed
  rather than misapplied; a hypertrophy-specific rest-interval source is
  still unverified). A separate citation (Schoenfeld et al. 2016, on
  ≥2x/week training frequency) isn't per-exercise at all and surfaces once,
  next to the Training Split card, where frequency actually gets decided.
- **Muscle Map**: `body_region` is the same taxonomy the muscle map
  already visualizes from `lifts.body_region` — a lift logged against a
  name found here can default its `body_region`/`muscle_group` from this
  table instead of the small hardcoded `DEFAULT_MUSCLE_GROUP`/
  `DEFAULT_BODY_REGION` maps.
- **Split builder**: exercise selection in the training-split builder
  reads from here instead of a separate hardcoded list.
- **Glossary**: a standalone browsable list, filterable by muscle group/
  equipment, reusing the same rows.

---

### `user_achievements` — Milestone system unlocks
```sql
id                                 uuid primary key
user_id                            uuid
achievement_id                     text (matches an id in ACHIEVEMENT_LIBRARY, index.html)
unlocked_at                        timestamptz
```
unique constraint on `(user_id, achievement_id)`.

**Frontend reads/writes:** select + insert own only — no update/delete
policy, since an unlock is meant to be permanent once earned, even if the
logged data that originally satisfied the condition changes later (e.g. a
PR-setting lift entry gets edited or deleted afterward).

Achievement *definitions* (coach-voice title/description, unlock
condition as a `check(ctx)` function) live in `ACHIEVEMENT_LIBRARY` in
`index.html`, not the database — same static-content pattern as the
Layer 1 tips library and the `exercises` table. `checkAndUnlockAchievements()`
runs the library against already-loaded state after every `renderAll()`
data refresh; anything newly satisfied that isn't already in
`state.achievements` gets inserted here and surfaces an unlock banner.
Each unlocked achievement is shareable as a downloadable image via
`generateAchievementShareCanvas()`, the same canvas-based approach as the
weekly recap card.

---

### `workout_sessions` — End Workout flow + post-session AI analysis
```sql
id                                 uuid primary key
user_id                            uuid
date                               date — one row per (user_id, date); a "session" is one calendar day
ended_at                           timestamptz — null means active (or reopened)
analysis                           jsonb — cached { summary, callouts[], highlightExercise } from analyze-session.js
analysis_generated_at              timestamptz
created_at                         timestamptz
```
unique constraint on `(user_id, date)`.

A session is one calendar day of lifts, matching every other "today's
session" concept already in `index.html` (the Lifts tab's today summary,
PR detection) — there's no separate clock-time session boundary, so this
table doesn't invent one either. There's no `started_at` column: a
session's start is already implicit in the earliest `lifts.created_at`
for that date, and the "still training?" staleness prompt (shown when a
session has been active for a while with no new set logged) reads
`lifts.created_at` directly rather than duplicating that timestamp here.

**Frontend reads/writes:** loaded once via `loadWorkoutSession()`, upserted
by `endWorkoutSession()` (sets `ended_at`) and `reopenWorkoutSession()`
(clears it). Tapping "End Workout" auto-triggers analysis generation via
the `analyze-session` Netlify function when the account is paid and the
minimum-history baseline is met (3+ prior days that included one of
today's exercises) — the result is cached in `analysis`/
`analysis_generated_at` so it's called at most once per session/day, never
regenerated on a later view or a reopen-then-re-end. Below the baseline,
ending the session still works and shows an honest placeholder instead of
a thin comparison. Charts on the analysis screen (volume/trend for
whichever exercise the writeup calls out via `highlightExercise`, plus a
small nutrition-context chart when a "nutrition" callout is present) render
with Chart.js, loaded lazily from a CDN only when this screen opens — the
one deliberate exception to the rest of the app's hand-rolled-SVG chart
convention, per the product spec for this feature specifically.

---

### `events` — Append-only activity log (founder dashboard)
```sql
id            uuid primary key
user_id       uuid, nullable
event_name    text not null
properties    jsonb (default: '{}')
created_at    timestamptz
```
**Frontend writes:** fire-and-forget inserts only (`event_name`,
`properties`) — never reads. **Backend reads:** the IronLog-repurposed
dashboard's Netlify functions, using the service role key.

Built for the founder-only growth dashboard — see
`supabase-schema-phase32-events-and-admin.sql`. Existing tables
(`profiles`, `subscriptions`) hold only current state, not history, so
funnel/DAU-WAU-MAU/cohort-retention can't be computed from them; this is
an intentionally generic log (one row per action, a jsonb properties bag
instead of per-event columns) so a new event kind never needs a
migration. RLS allows inserting your own `user_id`, or a null `user_id`
from anyone including the pre-auth anon role (needed for
`signup_started`, which fires before an account exists — there's no
`auth.uid()` yet to match against). No select/update/delete policy for
the `authenticated` role at all, so event history can't be read back or
tampered with by the client that wrote it, only by server-side code
holding the service role key.

Event names: `signup_started`, `signup_completed`, `onboarding_completed`,
`first_food_log`, `first_lift_log`, `block_builder_used`,
`plan_builder_used`, `athlete_mode_used`, `leaderboard_used` (friend
added/requested — there is deliberately no public feed in this app, see
the "No feed, no posts" copy in index.html, so that adoption metric
doesn't apply here), `group_mode_used`, and a throttled once-per-day
`app_opened` heartbeat for DAU/WAU/MAU.

Fired server-side only, from `stripe-webhook.js` using the real Stripe
event (never a client-side guess): `trial_started`, `subscribed` (trial
converting, or a direct paid signup with no trial), and for MRR-breakdown
purposes, `subscription_reactivated` (past_due/canceled → active) and
`subscription_canceled`.

---

### `admin_users` — Founder-only allowlist (founder dashboard)
```sql
user_id  uuid primary key
```
**No frontend access at all.** Zero RLS policies for `authenticated`/
`anon` — RLS defaults to deny, so this table is unreachable through the
public API in either direction, full stop. Only the service role key
(used exclusively by the dashboard's Netlify functions, never shipped to
a browser) can read or write it.

Deliberately not a boolean column on `profiles`: that table's existing
`"profiles: update own"` policy (`using (auth.uid() = id)`) has no
column-level restriction, so a hypothetical `is_admin` flag there would
let any authenticated user grant themselves admin via a direct `PATCH`
to their own row. A separate, policy-less table closes that off
entirely rather than relying on remembering to scope an RLS `with check`
correctly.

---

### `dashboard_infra_costs` / `dashboard_one_time_costs` — Manual cost tracking (founder dashboard)
```sql
-- dashboard_infra_costs: one row per month of fixed recurring costs
month        date primary key  -- first day of the month
amount_usd   numeric not null
note         text
updated_at   timestamptz

-- dashboard_one_time_costs: append-only log of irregular costs
id            uuid primary key
incurred_on   date not null
description   text not null
amount_usd    numeric not null
created_at    timestamptz
```
**No frontend access at all** — same zero-RLS-policy pattern as
`admin_users` (see `supabase-schema-phase33-dashboard-costs.sql`). Only
the dashboard's Netlify functions, themselves gated behind
`requireAdmin()`, can read or write these.

`dashboard_infra_costs` covers fixed monthly costs you enter by hand
(Supabase, Netlify, Resend, domain, Apple Developer fee) since nothing
in this app bills those automatically. `dashboard_one_time_costs` is a
simple log for non-recurring costs (LLC filing, trademark search, etc.)
— both feed into the dashboard's net-margin calculation alongside real
AI cost (`ai_usage`) and real Stripe fees.


## Naming Rules — CONSISTENT across ALL tables

| Type | Naming | Example | Notes |
|------|--------|---------|-------|
| **Macros** | `_g` suffix | `protein_g`, `carbs_g`, `fat_g` | All tables use this |
| **User ID** | `user_id` | (uuid) | Every personal table has this |
| **Primary ID** | `id` | (uuid) | Except goals & body_stats which use `user_id` as PK |
| **Dates (tracking)** | `logged_date` or `logged_at` | food_logs: `logged_at`, weight_log: `logged_date` | Consistent within table |
| **Updated/Created** | `updated_at`, `created_at` | (timestamptz) | Standard naming |

---

## How to Fix Mismatches

### If you see "protein", "carbs", "fat" (without _g) in your database:

1. **Use the reset script:**
   ```
   Run reset-schema.sql in Supabase SQL editor
   ```
   This drops and recreates ALL tables with correct naming.

2. **Or manually fix goals table:**
   ```sql
   -- If your goals table has wrong column names, recreate it:
   drop table goals cascade;
   
   create table goals (
     user_id uuid primary key references auth.users(id) on delete cascade,
     calories int not null default 2200,
     protein_g int not null default 150,  -- Note: _g suffix
     carbs_g int not null default 250,    -- Note: _g suffix
     fat_g int not null default 70,       -- Note: _g suffix
     updated_at timestamptz not null default now()
   );
   
   alter table goals enable row level security;
   create policy "goals: select own" on goals for select using (auth.uid() = user_id);
   create policy "goals: insert own" on goals for insert with check (auth.uid() = user_id);
   create policy "goals: update own" on goals for update using (auth.uid() = user_id);
   ```

### Why goals shows blank for protein/carbs/fat:

The app tries to read from `protein_g`, `carbs_g`, `fat_g` but your database has `protein`, `carbs`, `fat`. Supabase returns `null` for missing columns, so they display as blank.

---

## Verification Checklist

Run this in Supabase SQL editor to verify your schema is correct:

```sql
-- Check goals has correct column names
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'goals' AND column_name LIKE '%protein%';
-- Should return: protein_g

-- Check food_logs has correct column names
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'food_logs' AND column_name LIKE '%carbs%';
-- Should return: carbs_g

-- Check all _g columns exist
SELECT table_name, column_name FROM information_schema.columns 
WHERE column_name IN ('protein_g', 'carbs_g', 'fat_g') 
ORDER BY table_name;
-- Should show these columns in: goals, food_logs, food_cache, favorites
```

---

## Files to Run (in order)

1. **`reset-schema.sql`** — Complete reset (drops all, recreates fresh)
2. OR manually run the two incremental schemas:
   - `supabase-schema.sql` → creates core tables
   - `supabase-schema-additions.sql` → creates features

Pick **one approach**: either reset-schema.sql (easiest), or the two incremental files if you prefer to keep data and fix columns one at a time (harder, more error-prone).

Either way, if you already have a live database from before the paywall was
added, also run **`supabase-schema-phase2-paywall.sql`** — it only adds the
`subscriptions` table and is safe to run without resetting anything. Fresh
installs via `reset-schema.sql` get it automatically.

Same story for everything after the paywall — age gate, referrals,
`goal_mode`, email reminder opt-out: run **`supabase-schema-phase3-improvements.sql`**
against an existing live database (adds columns + the `referrals` table
only, nothing dropped); fresh installs get it all from `reset-schema.sql`.

And again for the Customer Portal's `cancel_at_period_end` column: run
**`supabase-schema-phase4-portal.sql`** against an existing live database;
fresh installs get it from `reset-schema.sql`.

For hydration tracking (the `water_oz` goal column and the `water_logs`
table): run **`supabase-schema-phase6-hydration.sql`** against an existing
live database; fresh installs get it from `reset-schema.sql`.

For the IronLog merge (`lifts`, `exercise_goals`, `monthly_recaps`, the
`progress-photos` Storage bucket): run
**`supabase-schema-phase7-ironlog.sql`** against an existing live database;
fresh installs get it from `reset-schema.sql`. This does **not** migrate
any actual rows out of IronLog's separate Supabase project — it only
creates the tables/bucket in Plated's project, ready to receive that data
as its own later step.

For the Photos tab (the `photos` table, tracking uploads into the
`progress-photos` bucket phase7 already created): run
**`supabase-schema-phase8-photos.sql`** against an existing live database;
fresh installs get it from `reset-schema.sql`.

For training splits (the `training_splits` table): run
**`supabase-schema-phase9-splits.sql`** against an existing live database;
fresh installs get it from `reset-schema.sql`.

For food-log photos (`food_logs.photo_path` and the `food-photos`
bucket): run **`supabase-schema-phase10-food-photos.sql`** against an
existing live database; fresh installs get it from `reset-schema.sql`.

For the friend-based leaderboard (the `friendships` table): run
**`supabase-schema-phase11-friends.sql`** against an existing live database;
fresh installs get it from `reset-schema.sql`. Free vs. paid tier reuses the
existing `subscriptions.status` field (trialing/active = paid) — no schema
change needed for that part.

For the first-time onboarding flow (`profiles.onboarded_at`): run
**`supabase-schema-phase12-onboarding.sql`** against an existing live
database; fresh installs get it from `reset-schema.sql`.

For the exercise database (cue cards, muscle map defaults, split builder,
glossary — the `exercises` table, seeded with ~30 common lifts): run
**`supabase-schema-phase13-exercises.sql`** against an existing live
database; fresh installs get it from `reset-schema.sql`.

For goal-adaptive coaching nudges (`goals.goal_mode_changed_at`): run
**`supabase-schema-phase14-goal-nudges.sql`** against an existing live
database; fresh installs get it from `reset-schema.sql`.

For the achievement/milestone system (the `user_achievements` table and
`profiles.glossary_exercises_viewed`): run
**`supabase-schema-phase15-achievements.sql`** against an existing live
database; fresh installs get it from `reset-schema.sql`.

For the End Workout flow + post-session AI analysis (the
`workout_sessions` table): run
**`supabase-schema-phase16-workout-sessions.sql`** against an existing
live database; fresh installs get it from `reset-schema.sql`.

For the exercise library expansion + hypertrophy guidance (adds
`exercises.hypertrophy_rep_range`/`hypertrophy_rest_interval`/
`hypertrophy_tempo`/`hypertrophy_mind_muscle_cue`, then truncates and
reseeds `exercises` with the full ~75-exercise library — safe, since
nothing references `exercises.id` by foreign key): run
**`supabase-schema-phase17-exercise-hypertrophy.sql`** against an existing
live database; fresh installs get it from `reset-schema.sql`. If a long
paste of that single ~580-line file into the Supabase SQL Editor produces
a syntax error partway through the VALUES list (seen on mobile — the
paste was silently truncating), run the five smaller files instead —
**`supabase-schema-phase17-part1-of-5.sql`** through **`...-part5-of-5.sql`**,
in order. They're a byte-for-byte split of the same statement (15
exercises per INSERT, part 1 also carries the ALTER/TRUNCATE) and
produce an identical result either way.

For exercise tags and the muscle-map key mapping (adds `movement_type`,
`lengthened_bias`, `avoid_flags`, `block_types`, `muscle_map_key`,
`muscle_map_secondary_keys`, `image_url`, `video_url` to `exercises`, then
updates all 75 rows in place — no truncate, since phase17's data is left
untouched): run **`supabase-schema-phase18-exercise-tags.sql`** against an
existing live database; fresh installs get it from `reset-schema.sql`.

For warm-up set tracking (adds `lifts.warmup_per_set`, feeding the weekly
hard-sets-per-muscle feature): run
**`supabase-schema-phase19-warmup-sets.sql`** against an existing live
database; fresh installs get it from `reset-schema.sql`.

For learning-path completion tracking (adds
`profiles.learning_paths_completed`): run
**`supabase-schema-phase20-learning-paths.sql`** against an existing live
database; fresh installs get it from `reset-schema.sql`.

For barcode scanning (adds the `'barcode'` value to `food_logs.source`,
plus `food_logs.sugar_g` and `food_logs.barcode`): run
**`supabase-schema-phase21-barcode-scanning.sql`** against an existing
live database; fresh installs get it from `reset-schema.sql`.

For Apple Health sync (adds `health_sync_tokens`, `sleep_log`,
`steps_log`, and `weight_log.source`): run
**`supabase-schema-phase22-apple-health-sync.sql`** against an existing
live database; fresh installs get it from `reset-schema.sql`. Also
requires the two new Netlify functions
(`health-sync-token.js`/`health-sync.js`) to be deployed — no new
environment variables beyond the `SUPABASE_SERVICE_ROLE_KEY` this repo's
other admin-style functions already need.

For the optional Block Builder (adds `profiles.active_training_block`):
run **`supabase-schema-phase23-block-builder.sql`** against an existing
live database; fresh installs get it from `reset-schema.sql`. No new
Netlify function or environment variable — the whole feature is
client-side generation plus one jsonb column, written directly from the
browser the same way `learning_paths_completed` is.

For the optional Workout Plan Builder (adds the new `plans` table, sitting
above Block Builder): run **`supabase-schema-phase25-plan-builder.sql`**
against an existing live database; fresh installs get it from
`reset-schema.sql`. No new Netlify function or environment variable — same
client-side-only pattern as Block Builder, just backed by a real table
instead of a jsonb column since it's multi-field metadata rather than a
single generated-and-replaced blob.

For the optional Group Mode (adds `groups`/`group_members`/
`group_freeze_log`/`group_goals` plus 3 notification columns on
`profiles`): run **`supabase-schema-phase26-group-mode.sql`** against an
existing live database; fresh installs get it from `reset-schema.sql`.
**Unlike every other optional feature above, this one does add new
server-side pieces**: 4 new Netlify functions (`create-group.js`,
`invite-to-group.js`, `get-group.js`, and the scheduled
`evaluate-groups.js`) and a new `[functions."evaluate-groups"]` schedule
block in `netlify.toml`, all reusing the existing `SUPABASE_SERVICE_ROLE_KEY`
and `RESEND_API_KEY` environment variables the Friends Leaderboard and
reminder emails already require — no new environment variables, but both
of those must already be configured for group notification emails and
the daily streak evaluation to actually run (both no-op safely, same as
`send-reminder-emails.js` does today, if either key is missing).
