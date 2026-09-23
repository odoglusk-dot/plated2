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
created_at            timestamptz
```
**Frontend reads/writes:** `id, display_name, age, sex, height_cm, activity_level, age_over_18, age_gate_shown_at, parental_consent_at, referral_code, email_reminders_opt_out`

`age_over_18`/`age_gate_shown_at`/`parental_consent_at` are set once at
signup (see the `#authForm` submit handler and `ensureProfileAndGoals()` in
`index.html`) — a soft, logged checkpoint, not an enforced technical block.
`referral_code` is generated client-side at signup (`generateReferralCode()`)
with a retry-on-collision loop; older accounts get one lazily via
`ensureReferralCode()` the first time they open the Profile tab.

---

### `goals` — Daily nutrition targets
```sql
user_id     uuid primary key
calories    int (default: 2200)
protein_g   int (default: 150)       ← WITH _g suffix
carbs_g     int (default: 250)       ← WITH _g suffix
fat_g       int (default: 70)        ← WITH _g suffix
water_oz    numeric (default: 64) — flat editable default, not calculator-derived
goal_mode   text (default: 'maintain') ('lose' | 'maintain' | 'gain')
updated_at  timestamptz
```
**Frontend reads/writes:** `user_id, calories, protein_g, carbs_g, fat_g, water_oz, goal_mode, updated_at`  
⚠️ **CRITICAL:** All macros use `_g` suffix. If your DB has `protein`, `carbs`, `fat` (without `_g`), goals won't display properly.

`goal_mode` drives two things in `index.html`: the calculator's macro split
(`MACRO_SPLIT_BY_GOAL` — protein g/lb and fat% both shift by goal) and the
dashboard's soft calorie-range shading (`calorieRangeForGoal()`) — a muted
ring color when today's total falls outside a healthy zone for that goal,
never a hard alert.

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
source      text ('manual' | 'ai_text' | 'ai_photo' | 'favorite' | 'common')
photo_path  text (optional — path within the food-photos bucket, "<user_id>/<file>.jpg")
logged_at   timestamptz (indexed)
created_at  timestamptz
```
**Frontend reads:** `logged_at, (all other columns via select(*))`, ordered by `logged_at desc`  
**Frontend writes:** `user_id, food_name, calories, protein_g, carbs_g, fat_g, source, photo_path`

`photo_path` (added in `supabase-schema-phase10-food-photos.sql`) is only
ever set when a meal was logged from the "Snap a Photo" AI-estimate flow
and the upload succeeded — every other logging path leaves it null. Same
signed-URL display pattern as `photos.storage_path`: the image lives in
the private `food-photos` bucket, this column just tracks the path.

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
created_at  timestamptz
```
**Frontend reads:** `logged_date, weight_lb, note` (via select(*), order by `logged_date desc`)  
**Frontend writes:** `user_id, logged_date, weight_lb, note`

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
created_at       timestamptz
```
**Frontend reads/writes:** `exercise, muscle_group, weight, sets,
reps_per_set, reps, date, superset_group, body_region`

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
