-- ============================================================
-- COMPLETE PLATED SCHEMA RESET
-- Drops ALL tables and recreates them fresh from scratch.
-- Run this in Supabase SQL editor if you have schema conflicts.
-- ============================================================

-- Drop all tables in correct dependency order (reverse of creation)
drop table if exists user_achievements cascade;
drop table if exists exercises cascade;
drop table if exists training_splits cascade;
drop table if exists photos cascade;
drop table if exists monthly_recaps cascade;
drop table if exists exercise_goals cascade;
drop table if exists lifts cascade;
drop table if exists referrals cascade;
drop table if exists subscriptions cascade;
drop table if exists ai_usage cascade;
drop table if exists supplement_logs cascade;
drop table if exists water_logs cascade;
drop table if exists weight_log cascade;
drop table if exists favorites cascade;
drop table if exists food_cache cascade;
drop table if exists food_logs cascade;
drop table if exists body_stats cascade;
drop table if exists goals cascade;
drop table if exists profiles cascade;

-- ══════════════════════════════════════════════════════════════
-- CORE SCHEMA (supabase-schema.sql)
-- ══════════════════════════════════════════════════════════════

-- ── profiles ────────────────────────────────────────────────────────────
-- One row per user, created right after sign-up. Holds identity + the
-- physical stats the goal calculator needs.
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  age int,
  sex text check (sex in ('male', 'female')),
  height_cm numeric,
  activity_level text check (
    activity_level in ('sedentary', 'light', 'moderate', 'active', 'very_active')
  ),
  -- Age gate (shown at signup, not a hard block — see index.html signup form).
  age_over_18 boolean,
  age_gate_shown_at timestamptz,
  parental_consent_at timestamptz,
  -- Referrals: this user's own shareable code, generated client-side at signup.
  referral_code text unique,
  -- Daily "haven't logged yet" reminder email opt-out (see send-reminder-emails.js).
  email_reminders_opt_out boolean not null default false,
  -- Set once the first-time onboarding overlay is completed/skipped; null
  -- means "show it" (see supabase-schema-phase12-onboarding.sql).
  onboarded_at timestamptz,
  -- Distinct exercise names whose cue cards have been expanded in the
  -- Exercise Glossary — input to the Learning-category achievement.
  -- See supabase-schema-phase15-achievements.sql.
  glossary_exercises_viewed text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "profiles: select own" on profiles
  for select using (auth.uid() = id);
create policy "profiles: insert own" on profiles
  for insert with check (auth.uid() = id);
create policy "profiles: update own" on profiles
  for update using (auth.uid() = id);

-- ── goals ───────────────────────────────────────────────────────────────
-- One row per user. Either set manually or by the Mifflin-St Jeor calculator.
-- ALL macro columns use _g suffix (protein_g, carbs_g, fat_g)
create table goals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  calories int not null default 2200,
  protein_g int not null default 150,
  carbs_g int not null default 250,
  fat_g int not null default 70,
  -- Daily hydration target. Not derived by the goal calculator (nothing
  -- computes a personalized water target) — a flat, editable default.
  water_oz numeric not null default 64,
  -- Which calculator scenario these goals came from — drives the soft
  -- calorie-range shading on the dashboard ring (see calorieRangeForGoal()).
  goal_mode text not null default 'maintain' check (goal_mode in ('lose', 'maintain', 'gain')),
  -- When goal_mode last actually changed value (not stamped on every
  -- goals write) — lets the goal-adaptive nudge tell "just changed" from
  -- "has been this way for months." See supabase-schema-phase14-goal-nudges.sql.
  goal_mode_changed_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table goals enable row level security;

create policy "goals: select own" on goals
  for select using (auth.uid() = user_id);
create policy "goals: insert own" on goals
  for insert with check (auth.uid() = user_id);
create policy "goals: update own" on goals
  for update using (auth.uid() = user_id);

-- ── body_stats ──────────────────────────────────────────────────────────
-- Current body weight, used as an input to the goal calculator. Overwritten
-- in place (not a history — see weight_log below for the tracked-over-time
-- feature and its chart).
create table body_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  weight_kg numeric not null,
  updated_at timestamptz not null default now()
);

alter table body_stats enable row level security;

create policy "body_stats: select own" on body_stats
  for select using (auth.uid() = user_id);
create policy "body_stats: insert own" on body_stats
  for insert with check (auth.uid() = user_id);
create policy "body_stats: update own" on body_stats
  for update using (auth.uid() = user_id);

-- ── food_logs ───────────────────────────────────────────────────────────
-- ALL macro columns use _g suffix (protein_g, carbs_g, fat_g)
create table food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  food_name text not null,
  calories numeric not null,
  protein_g numeric not null,
  carbs_g numeric not null,
  fat_g numeric not null,
  source text not null default 'manual' check (
    source in ('manual', 'ai_text', 'ai_photo', 'favorite', 'common')
  ),
  photo_path text,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index food_logs_user_logged_idx on food_logs (user_id, logged_at desc);

alter table food_logs enable row level security;

create policy "food_logs: select own" on food_logs
  for select using (auth.uid() = user_id);
create policy "food_logs: insert own" on food_logs
  for insert with check (auth.uid() = user_id);
create policy "food_logs: update own" on food_logs
  for update using (auth.uid() = user_id);
create policy "food_logs: delete own" on food_logs
  for delete using (auth.uid() = user_id);

-- ── food_cache ──────────────────────────────────────────────────────────
-- Shared across every signed-in user on purpose — it's generic nutrition
-- data (not personal), so caching AI estimates here cuts duplicate API
-- spend when two users log the same common food.
-- ALL macro columns use _g suffix (protein_g, carbs_g, fat_g)
create table food_cache (
  description_key text primary key,
  food_name text not null,
  calories numeric not null,
  protein_g numeric not null,
  carbs_g numeric not null,
  fat_g numeric not null,
  created_at timestamptz not null default now()
);

alter table food_cache enable row level security;

create policy "food_cache: select all signed-in" on food_cache
  for select using (auth.role() = 'authenticated');
create policy "food_cache: insert all signed-in" on food_cache
  for insert with check (auth.role() = 'authenticated');

-- ══════════════════════════════════════════════════════════════════════════
-- ADDITIONS SCHEMA (supabase-schema-additions.sql)
-- ══════════════════════════════════════════════════════════════════════════

-- ── favorites ───────────────────────────────────────────────────────────
-- Saved foods for quick re-logging.
-- ALL macro columns use _g suffix (protein_g, carbs_g, fat_g)
create table favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  food_name text not null,
  calories numeric not null,
  protein_g numeric not null,
  carbs_g numeric not null,
  fat_g numeric not null,
  created_at timestamptz not null default now()
);

alter table favorites enable row level security;

create policy "favorites: select own" on favorites
  for select using (auth.uid() = user_id);
create policy "favorites: insert own" on favorites
  for insert with check (auth.uid() = user_id);
create policy "favorites: delete own" on favorites
  for delete using (auth.uid() = user_id);

-- ── weight_log ──────────────────────────────────────────────────────────
-- Append-only history for the weight-over-time chart (distinct from
-- body_stats, which just holds the current value for the goal calculator).
create table weight_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_date date not null default current_date,
  weight_lb numeric not null,
  note text,
  created_at timestamptz not null default now()
);

create index weight_log_user_date_idx on weight_log (user_id, logged_date desc);

alter table weight_log enable row level security;

create policy "weight_log: select own" on weight_log
  for select using (auth.uid() = user_id);
create policy "weight_log: insert own" on weight_log
  for insert with check (auth.uid() = user_id);
create policy "weight_log: delete own" on weight_log
  for delete using (auth.uid() = user_id);

-- ── supplement_logs ─────────────────────────────────────────────────────
-- Per-date supplement logging.
create table supplement_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  supplement_name text not null,
  dose text,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index supplement_logs_user_logged_idx on supplement_logs (user_id, logged_at desc);

alter table supplement_logs enable row level security;

create policy "supplement_logs: select own" on supplement_logs
  for select using (auth.uid() = user_id);
create policy "supplement_logs: insert own" on supplement_logs
  for insert with check (auth.uid() = user_id);
create policy "supplement_logs: delete own" on supplement_logs
  for delete using (auth.uid() = user_id);

-- ── water_logs ──────────────────────────────────────────────────────────
-- Append-only, one row per quick-add tap (e.g. "+8oz") rather than one
-- running daily total, so the dashboard can sum "today" the same way it
-- already does for food_logs — logged_at + a client-side date filter,
-- no separate daily-rollup logic to keep in sync.
create table water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_oz numeric not null,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index water_logs_user_logged_idx on water_logs (user_id, logged_at desc);

alter table water_logs enable row level security;

create policy "water_logs: select own" on water_logs
  for select using (auth.uid() = user_id);
create policy "water_logs: insert own" on water_logs
  for insert with check (auth.uid() = user_id);
create policy "water_logs: delete own" on water_logs
  for delete using (auth.uid() = user_id);

-- ── ai_usage ────────────────────────────────────────────────────────────
-- Backs the daily free-AI-call cap. Scoped per user_id (not per browser/
-- device) and enforced server-side inside the Netlify functions, so
-- switching browsers can't reset a user's count. One row per user per day.
create table ai_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default current_date,
  count int not null default 0,
  input_tokens bigint not null default 0,
  output_tokens bigint not null default 0,
  estimated_cost_usd numeric(10, 6) not null default 0,
  primary key (user_id, usage_date)
);

alter table ai_usage enable row level security;

create policy "ai_usage: select own" on ai_usage
  for select using (auth.uid() = user_id);
create policy "ai_usage: insert own" on ai_usage
  for insert with check (auth.uid() = user_id);
create policy "ai_usage: update own" on ai_usage
  for update using (auth.uid() = user_id);

-- ── subscriptions ───────────────────────────────────────────────────────
-- Backs the whole-app paywall (Stripe: $4.99/mo, 3-day trial). One row per
-- user. Only the Stripe webhook (using the service-role key, which bypasses
-- RLS) ever writes to this table — there's deliberately no insert/update
-- policy for the client, only select-own.
--
-- Canceling via the Customer Portal does NOT flip `status` away from
-- 'active' right away — Stripe keeps status='active' with
-- cancel_at_period_end=true until the paid period actually ends, then
-- fires customer.subscription.deleted (status becomes 'canceled'). That
-- means the existing status-only paywall check (index.html's hasAccess())
-- already grants access through the paid period correctly, with no special
-- casing needed. `cancel_at_period_end` is stored anyway so the app can
-- *show* "canceling, access until <date>" instead of just "active" —
-- mirroring Stripe's own data model rather than inventing a third status.
create table subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'free'
    check (status in ('free', 'trialing', 'active', 'canceled', 'past_due')),
  stripe_customer_id text,
  stripe_subscription_id text,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table subscriptions enable row level security;

create policy "subscriptions: select own" on subscriptions
  for select using (auth.uid() = user_id);

-- ── referrals ───────────────────────────────────────────────────────────
-- One row per successful referral redemption. Written only by
-- redeem-referral.js (at signup) and stripe-webhook.js (when marking a
-- reward paid out) — both use the service-role key. There's deliberately
-- no insert/update policy for the client, same reasoning as subscriptions:
-- this drives a real money discount, so only server code should ever touch it.
create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references auth.users(id) on delete cascade,
  referred_user_id uuid not null unique references auth.users(id) on delete cascade,
  referral_code text not null,
  status text not null default 'pending' check (status in ('pending', 'rewarded')),
  created_at timestamptz not null default now(),
  rewarded_at timestamptz
);

alter table referrals enable row level security;

create policy "referrals: select own as referrer" on referrals
  for select using (auth.uid() = referrer_user_id);

-- ── friendships (friend-based leaderboard) ──────────────────────────────
-- Request/accept model; a friend is added by their existing referral_code
-- rather than a second code. No client insert policy — add-friend.js looks
-- up the other user by referral_code with the service-role key, same
-- reasoning as redeem-referral.js above. See
-- supabase-schema-phase11-friends.sql for the full rationale, including why
-- there's no separate `tier` column (derived from subscriptions.status).
create table friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friendships_no_self_friend check (requester_id <> addressee_id),
  constraint friendships_unique_pair unique (requester_id, addressee_id)
);

alter table friendships enable row level security;

create policy "friendships_select_own" on friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "friendships_update_as_addressee" on friendships for update
  using (auth.uid() = addressee_id) with check (auth.uid() = addressee_id);

create policy "friendships_delete_own" on friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ══════════════════════════════════════════════════════════════════════════
-- IRONLOG MERGE (supabase-schema-phase7-ironlog.sql)
-- ══════════════════════════════════════════════════════════════════════════
-- Bodyweight tracking is NOT a separate table here — IronLog's bodyweight
-- (weight, date) is the same shape as weight_log (weight_lb, logged_date)
-- above, so it's unified into that existing table rather than duplicated.

-- ── lifts ───────────────────────────────────────────────────────────────
create table lifts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise text not null,
  muscle_group text,
  weight numeric not null,
  sets integer not null,
  reps_per_set numeric[] not null,
  reps numeric not null,
  date date not null,
  -- entries sharing (user_id, date, superset_group) are bundled together as
  -- one superset/circuit on the Days view (a later phase)
  superset_group text,
  -- finer-grained region for the muscle volume map (a later phase),
  -- alongside (not replacing) muscle_group above
  body_region text,
  created_at timestamptz not null default now()
);

create index lifts_user_date_idx on lifts (user_id, date);

alter table lifts enable row level security;

create policy "lifts_select_own" on lifts for select using (auth.uid() = user_id);
create policy "lifts_insert_own" on lifts for insert with check (auth.uid() = user_id);
create policy "lifts_update_own" on lifts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "lifts_delete_own" on lifts for delete using (auth.uid() = user_id);

-- ── exercise_goals ──────────────────────────────────────────────────────
-- One live goal per exercise: target weight by a target date. Named
-- exercise_goals, not goals — that name is already taken above by the
-- per-user macro/hydration goals table; these are unrelated tables.
create table exercise_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise text not null,
  target_weight numeric not null,
  target_date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, exercise)
);

create index exercise_goals_user_idx on exercise_goals (user_id);

alter table exercise_goals enable row level security;

create policy "exercise_goals_select_own" on exercise_goals for select using (auth.uid() = user_id);
create policy "exercise_goals_insert_own" on exercise_goals for insert with check (auth.uid() = user_id);
create policy "exercise_goals_update_own" on exercise_goals for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "exercise_goals_delete_own" on exercise_goals for delete using (auth.uid() = user_id);

-- ── monthly_recaps ──────────────────────────────────────────────────────
-- Cached per-month training recap stats (Recaps tab — a later phase).
create table monthly_recaps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month date not null,
  total_volume numeric not null,
  training_days integer not null,
  most_trained_muscle_group text,
  most_trained_muscle_group_volume numeric,
  biggest_pr_exercise text,
  biggest_pr_weight numeric,
  biggest_pr_improvement numeric,
  bodyweight_start numeric,
  bodyweight_end numeric,
  computed_at timestamptz not null default now(),
  unique (user_id, month)
);

create index monthly_recaps_user_month_idx on monthly_recaps (user_id, month);

alter table monthly_recaps enable row level security;

create policy "monthly_recaps_select_own" on monthly_recaps for select using (auth.uid() = user_id);
create policy "monthly_recaps_insert_own" on monthly_recaps for insert with check (auth.uid() = user_id);
create policy "monthly_recaps_update_own" on monthly_recaps for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "monthly_recaps_delete_own" on monthly_recaps for delete using (auth.uid() = user_id);

-- ── progress-photos storage bucket + photos table (Photos tab) ─────────
insert into storage.buckets (id, name, public)
values ('progress-photos', 'progress-photos', false)
on conflict (id) do nothing;

create policy "progress_photos_select_own" on storage.objects for select
  using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "progress_photos_insert_own" on storage.objects for insert
  with check (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "progress_photos_delete_own" on storage.objects for delete
  using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create table photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  note text,
  date date not null,
  created_at timestamptz not null default now()
);

create index photos_user_date_idx on photos (user_id, date);

alter table photos enable row level security;

create policy "photos_select_own" on photos for select using (auth.uid() = user_id);
create policy "photos_insert_own" on photos for insert with check (auth.uid() = user_id);
create policy "photos_update_own" on photos for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "photos_delete_own" on photos for delete using (auth.uid() = user_id);

-- ── food-photos storage bucket (food_logs.photo_path) ───────────────────
-- Same pattern as progress-photos: private, folder-scoped to auth.uid(),
-- signed URLs generated client-side. food_logs.photo_path is added inline
-- on the food_logs table above (a fresh install doesn't need the
-- alter-table phase10 migration).
insert into storage.buckets (id, name, public)
values ('food-photos', 'food-photos', false)
on conflict (id) do nothing;

create policy "food_photos_select_own" on storage.objects for select
  using (bucket_id = 'food-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "food_photos_insert_own" on storage.objects for insert
  with check (bucket_id = 'food-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "food_photos_delete_own" on storage.objects for delete
  using (bucket_id = 'food-photos' and auth.uid()::text = (storage.foldername(name))[1]);

-- ── training_splits ──────────────────────────────────────────────────
-- One active split per user — a preset or custom weekly rotation used to
-- show a "today's focus" hint and filter the Lifts tab, not a program
-- manager. See supabase-schema-phase9-splits.sql for the full rationale.
create table training_splits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null,
  days jsonb not null,
  start_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table training_splits enable row level security;

create policy "training_splits_select_own" on training_splits for select using (auth.uid() = user_id);
create policy "training_splits_insert_own" on training_splits for insert with check (auth.uid() = user_id);
create policy "training_splits_update_own" on training_splits for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "training_splits_delete_own" on training_splits for delete using (auth.uid() = user_id);

-- ── exercises (reference data: cue cards, muscle map, split builder,
--    glossary) ──────────────────────────────────────────────────────────
-- See supabase-schema-phase13-exercises.sql for the full rationale.

create table exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  muscle_group text not null,
  body_region text,
  secondary_regions text[] not null default '{}',
  equipment text not null,
  cue_setup text not null,
  cue_execution text not null,
  cue_mistake text not null,
  cue_bracing text not null,
  created_at timestamptz not null default now()
);

alter table exercises enable row level security;

create policy "exercises_select_all" on exercises for select using (true);

insert into exercises (name, muscle_group, body_region, secondary_regions, equipment, cue_setup, cue_execution, cue_mistake, cue_bracing) values
('Bench Press', 'Push', 'chest', '{triceps,shoulders}', 'Barbell',
  'Set up with eyes under the bar, feet flat and driving into the floor, shoulder blades pulled back and down.',
  'Lower the bar to your lower chest under control, then press up and slightly back toward your face.',
  'Flaring the elbows straight out to the sides instead of tucking them ~45° — it stresses the shoulder more and gives you less pressing power.',
  'Take a breath into your belly before unracking, and hold it through the hardest part of each rep.'),
('Incline Bench Press', 'Push', 'chest', '{shoulders,triceps}', 'Barbell',
  'Set the bench to a 30–45° incline — steeper shifts the work to shoulders, flatter shifts it back to chest.',
  'Lower the bar to your upper chest, just below the collarbone, then press up and slightly back.',
  'Setting the incline too steep turns this into an overhead press with extra shoulder strain instead of an upper-chest exercise.',
  'Keep your feet planted and glutes on the bench — don''t let your lower back arch off the pad to chase more range.'),
('Overhead Press', 'Push', 'shoulders', '{triceps,abs}', 'Barbell',
  'Grip just outside shoulder width, bar resting on your front delts, elbows slightly in front of the bar.',
  'Press straight up, moving your head back slightly to let the bar pass, then push your head through at the top.',
  'Leaning back excessively to help the bar clear your face turns this into an incline press and stresses the lower back.',
  'Squeeze your glutes and brace your abs like you''re about to be punched in the stomach — a loose torso leaks power.'),
('Dumbbell Shoulder Press', 'Push', 'shoulders', '{triceps}', 'Dumbbell',
  'Sit or stand with dumbbells at shoulder height, palms facing forward or slightly angled in.',
  'Press the dumbbells up and slightly together without locking your elbows aggressively at the top.',
  'Letting the dumbbells drift too far forward turns the shoulders into the limiting factor before the set is actually over.',
  'Keep your ribs down and core tight — an arched lower back is usually the first thing to give out here.'),
('Push-Up', 'Push', 'chest', '{triceps,abs}', 'Bodyweight',
  'Hands slightly wider than shoulders, body in a straight line from head to heels.',
  'Lower your chest to just above the floor with elbows at roughly 45°, then press back up.',
  'Letting the hips sag or pike up breaks the straight-line position and shifts load away from the chest.',
  'Brace your abs and squeeze your glutes throughout — treat it like a moving plank, not just an arm exercise.'),
('Dip', 'Push', 'chest', '{triceps,shoulders}', 'Bodyweight',
  'Grip the bars with arms straight, shoulders down and away from your ears.',
  'Lower until your shoulders are about level with your elbows, then press back to the top.',
  'Going too deep too soon puts a lot of stress on the front of the shoulder before you''ve built the mobility for it.',
  'Lean your torso forward slightly and keep your core tight to bias the chest and protect the shoulders.'),
('Close-Grip Bench Press', 'Push', 'triceps', '{chest}', 'Barbell',
  'Grip just inside shoulder width, elbows tucked close to your sides.',
  'Lower the bar to your lower chest keeping elbows tracking straight back, then press up.',
  'Gripping too narrow (hands touching) puts unnecessary strain on the wrists without adding tricep benefit.',
  'Same full-body brace as a regular bench — feet driving down, upper back tight against the bench.'),
('Tricep Pushdown', 'Push', 'triceps', '{}', 'Cable',
  'Grip the bar or rope with elbows pinned to your sides, standing tall.',
  'Extend your forearms down until your arms are straight, then control the weight back up.',
  'Letting the elbows drift forward or flare out turns this into a shoulder/chest movement instead of isolating the triceps.',
  'Keep your torso still — using body momentum to help the weight down is the most common way to cheat this exercise.'),
('Lateral Raise', 'Push', 'shoulders', '{}', 'Dumbbell',
  'Stand with a slight forward lean, dumbbells at your sides with a soft bend in the elbows.',
  'Raise the dumbbells out to the sides until roughly shoulder height, leading with your elbows.',
  'Using momentum to swing the weight up trains your traps more than your side delts — the target muscle.',
  'Keep your core braced so you''re not using a body swing to substitute for shoulder strength.'),
('Deadlift', 'Pull', 'back', '{hamstrings,glutes}', 'Barbell',
  'Bar over mid-foot, shins close to the bar, grip just outside your knees, hips higher than the knees, chest up.',
  'Drive through the floor with your legs while keeping the bar close to your body until you''re standing tall.',
  'Letting the bar drift away from your shins/thighs turns the lift into a lower-back grinder instead of a leg-and-hip drive.',
  'Take a big breath and brace your entire torso like a weightlifting belt before the bar leaves the floor.'),
('Barbell Row', 'Pull', 'back', '{biceps,forearms}', 'Barbell',
  'Hinge at the hips to roughly a 45° torso angle, grip just outside shoulder width.',
  'Pull the bar to your lower ribcage, squeezing your shoulder blades together at the top.',
  'Standing up more with each rep (turning it into a mini deadlift) as fatigue sets in instead of holding the hinge.',
  'Keep your core braced and back flat throughout — this is a hip-hinge position, not just an arm pull.'),
('Pull-Up', 'Pull', 'back', '{biceps,forearms}', 'Bodyweight',
  'Grip just outside shoulder width, palms facing away, hang with arms fully extended.',
  'Pull your chin over the bar leading with your chest, then lower back to a full hang under control.',
  'Only doing the top half of the rep (partial range) trains less muscle and builds strength you can''t actually use.',
  'Keep a slight hollow-body brace so you''re not using an uncontrolled kip or swing to gain momentum.'),
('Chin-Up', 'Pull', 'back', '{biceps}', 'Bodyweight',
  'Grip shoulder width, palms facing you, hang with arms fully extended.',
  'Pull yourself up until your chin clears the bar, then lower back down under control.',
  'Turning it into a chest-up crunch instead of a straight vertical pull reduces the actual back/bicep work.',
  'Keep your ribs down and core tight to avoid an excessive arch through your lower back.'),
('Lat Pulldown', 'Pull', 'back', '{biceps}', 'Cable',
  'Grip slightly wider than shoulder width, sit tall with thighs secured under the pad.',
  'Pull the bar to your upper chest, driving your elbows down and back, then control it back up.',
  'Leaning back excessively and using body weight instead of your back muscles to move the bar.',
  'Keep your chest up and core braced — a small, controlled lean is fine, but a big swing is momentum, not strength.'),
('Seated Cable Row', 'Pull', 'back', '{biceps,forearms}', 'Cable',
  'Sit with knees slightly bent, back tall, grip the handle with arms extended.',
  'Pull the handle to your torso, squeezing your shoulder blades together, then extend back out under control.',
  'Rounding your lower back to add a few extra inches of pull range instead of keeping a tall, stable torso.',
  'Keep your torso upright and braced throughout — the movement should come from your arms and shoulder blades, not your spine rocking.'),
('Face Pull', 'Pull', 'shoulders', '{back}', 'Cable',
  'Set the cable at roughly face height, grip the rope with palms facing in.',
  'Pull the rope toward your face, flaring your elbows out wide and rotating your hands back.',
  'Pulling with too much weight and turning it into a row instead of a high-elbow rear-delt/rotator cuff movement.',
  'Keep your upper back tight and shoulders down away from your ears throughout the pull.'),
('Barbell Curl', 'Pull', 'biceps', '{forearms}', 'Barbell',
  'Stand tall, grip shoulder width, elbows pinned to your sides.',
  'Curl the bar up by bending your elbows, keeping your upper arms still, then lower under control.',
  'Swinging the hips and leaning back to heave the weight up — it takes the tension off the biceps entirely.',
  'Keep your core tight and elbows locked in place so the only thing moving is your forearms.'),
('Dumbbell Curl', 'Pull', 'biceps', '{forearms}', 'Dumbbell',
  'Stand or sit with dumbbells at your sides, palms facing forward or neutral.',
  'Curl one or both dumbbells up, optionally rotating to a full supination at the top, then lower under control.',
  'Letting the elbow drift forward as the weight gets heavy, which lets the front delt take over the movement.',
  'Keep your upper arm pinned against your torso throughout the rep.'),
('Back Squat', 'Legs', 'quads', '{glutes,hamstrings}', 'Barbell',
  'Bar on your upper traps (high bar) or rear delts (low bar), feet roughly shoulder width.',
  'Break at the hips and knees together, descending until your hip crease is at or below knee level, then drive back up.',
  'Letting the knees cave inward on the way up, especially on a heavy last rep — it''s a common sign of fatigue or weak hips.',
  'Take a big breath and brace your abs hard before descending — hold that brace through the bottom of the rep.'),
('Front Squat', 'Legs', 'quads', '{abs,glutes}', 'Barbell',
  'Bar racked across your front delts with elbows high, grip can be clean-style or crossed-arm.',
  'Squat down keeping your torso more upright than a back squat, then drive up through your heels/mid-foot.',
  'Letting the elbows drop lowers the bar off your shoulders and pitches your torso forward, losing the position.',
  'Brace your abs hard — an upright torso here depends more on core strength than on the back squat.'),
('Romanian Deadlift', 'Legs', 'hamstrings', '{glutes,back}', 'Barbell',
  'Start standing with the bar at hip height, soft bend in the knees that stays fixed through the rep.',
  'Push your hips back, lowering the bar along your legs until you feel a stretch in your hamstrings, then drive your hips forward to stand.',
  'Bending the knees more as the bar lowers turns it into a squat and takes tension off the hamstrings — the actual target.',
  'Keep your back flat and core braced — the movement is a hip hinge, not a spinal round.'),
('Leg Press', 'Legs', 'quads', '{glutes,hamstrings}', 'Machine',
  'Feet shoulder width on the platform, lower back flat against the pad.',
  'Lower the platform until your knees reach roughly 90°, then press back up without locking your knees hard at the top.',
  'Letting your lower back round off the pad as the weight gets heavy — usually a sign the range of motion is too deep for the load.',
  'Keep your core braced and lower back pinned to the pad throughout the set.'),
('Walking Lunge', 'Legs', 'quads', '{glutes,hamstrings}', 'Dumbbell',
  'Stand tall holding dumbbells at your sides or a bar on your back.',
  'Step forward into a lunge, lowering your back knee toward the floor, then drive through your front foot to step into the next rep.',
  'Taking too short a step turns it into a knee-dominant exercise and adds unnecessary knee stress.',
  'Keep your torso upright and core braced — leaning forward shifts the work away from your legs and onto your lower back.'),
('Bulgarian Split Squat', 'Legs', 'quads', '{glutes}', 'Dumbbell',
  'Rear foot elevated on a bench, front foot far enough forward that your front shin stays close to vertical.',
  'Lower straight down until your back knee is near the floor, then drive up through your front foot.',
  'Placing the front foot too close to the bench forces the front knee too far forward and shifts the emphasis away from the glutes/hamstrings.',
  'Keep your torso tall and core tight — this is a balance-heavy movement, and a loose core makes it worse.'),
('Leg Curl', 'Legs', 'hamstrings', '{}', 'Machine',
  'Lie face down (or seated, depending on the machine) with the pad positioned just above your heels.',
  'Curl your heels toward your glutes, then lower back under control without letting the weight stack slam.',
  'Using a big hip lift to help the weight up instead of isolating the hamstrings — keep your hips pinned down.',
  'Keep your hips pressed into the pad/bench throughout the movement.'),
('Leg Extension', 'Legs', 'quads', '{}', 'Machine',
  'Sit with the pad resting just above your ankles, back against the seat.',
  'Extend your knees until your legs are straight, then lower back under control.',
  'Using momentum to kick the weight up at the top instead of a controlled extension through the full range.',
  'Keep your back against the pad and grip the seat handles to keep your upper body still.'),
('Hip Thrust', 'Legs', 'glutes', '{hamstrings}', 'Barbell',
  'Upper back braced against a bench, bar across your hips, feet flat roughly shoulder width.',
  'Drive your hips up until your torso is roughly in line with your thighs, squeezing your glutes hard at the top.',
  'Overextending the lower back at the top to gain a few extra inches instead of stopping at a straight hip-to-shoulder line.',
  'Tuck your chin slightly and brace your abs at the top of each rep to avoid an exaggerated lower-back arch.'),
('Calf Raise', 'Legs', 'calves', '{}', 'Machine',
  'Stand on a raised edge or platform with your heels hanging off, balls of your feet planted.',
  'Rise up onto your toes as high as possible, pause briefly, then lower your heels below the platform for a full stretch.',
  'Using short, bouncy reps instead of a full stretch at the bottom and a full contraction at the top — most of the benefit is in that full range.',
  'Keep your knees roughly straight (soft, not locked) so the calves — not the knees — are doing the work.'),
('Plank', 'Core', 'abs', '{}', 'Bodyweight',
  'Forearms on the floor under your shoulders, body in a straight line from head to heels.',
  'Hold the position, breathing normally, keeping your hips level — neither sagging nor piking up.',
  'Letting the hips sag toward the floor as fatigue sets in, which shifts the load onto the lower back instead of the abs.',
  'Actively squeeze your abs and glutes throughout — a plank is an active brace, not just a static hold.'),
('Hanging Leg Raise', 'Core', 'abs', '{forearms}', 'Bodyweight',
  'Hang from a bar with a full grip, legs extended or knees bent depending on your level.',
  'Curl your hips up and raise your legs (or knees) toward your chest, then lower under control without swinging.',
  'Using momentum from a swing to fling the legs up instead of a controlled hip curl driven by the abs.',
  'Keep your ribs pulled down toward your pelvis throughout — an arched lower back means the hip flexors are taking over from the abs.'),
('Ab Wheel Rollout', 'Core', 'abs', '{shoulders}', 'Bodyweight',
  'Kneel on a pad, hands gripping the wheel directly under your shoulders.',
  'Roll forward as far as you can control, keeping your core braced, then pull back to the start using your abs, not your arms.',
  'Letting the lower back sag as you roll out — that''s usually the sign you''ve gone further than your current core strength supports.',
  'Brace your abs hard through the entire rollout — imagine trying to keep a flat line from your shoulders to your knees.'),
('Power Clean', 'Full Body', null, '{back,quads,shoulders}', 'Barbell',
  'Bar over mid-foot, same starting position as a deadlift, grip just outside shoulder width.',
  'Pull the bar explosively from the floor, extending through the hips as it passes your thighs, then drop under it to catch it on your front delts.',
  'Muscling the bar up with your arms early instead of using an explosive hip extension — the arms should stay relatively passive until the very end of the pull.',
  'Brace hard off the floor just like a deadlift, then reset that brace quickly to catch the bar in the front-rack position.');

-- ── user_achievements (milestone system) ─────────────────────────────────
-- Definitions (title, coach-voice description, unlock condition) live in
-- ACHIEVEMENT_LIBRARY in index.html, not this table — this only records
-- when a given account unlocked a given achievement id, permanently, once.
-- See supabase-schema-phase15-achievements.sql.
create table user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  unlocked_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);

alter table user_achievements enable row level security;

create policy "user_achievements_select_own" on user_achievements for select
  using (auth.uid() = user_id);
create policy "user_achievements_insert_own" on user_achievements for insert
  with check (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════════════════════
-- RESET COMPLETE
-- All tables created fresh with consistent naming:
--   - ALL macro columns: protein_g, carbs_g, fat_g (with _g suffix)
--   - ALL date columns: logged_date or logged_at (not inconsistent naming)
--   - ALL id columns: id (uuid)
--   - ALL user_id columns: user_id (uuid)
-- ══════════════════════════════════════════════════════════════════════════
