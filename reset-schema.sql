-- ============================================================
-- COMPLETE PLATED SCHEMA RESET
-- Drops ALL tables and recreates them fresh from scratch.
-- Run this in Supabase SQL editor if you have schema conflicts.
-- ============================================================

-- Drop all tables in correct dependency order (reverse of creation)
drop table if exists workout_sessions cascade;
drop table if exists user_achievements cascade;
drop table if exists exercises cascade;
drop table if exists group_goals cascade;
drop table if exists group_freeze_log cascade;
drop table if exists group_members cascade;
drop table if exists groups cascade;
drop table if exists plans cascade;
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
  -- Path ids from LEARNING_PATHS (index.html) this account has finished —
  -- also feeds the Learning achievement category. See
  -- supabase-schema-phase20-learning-paths.sql.
  learning_paths_completed text[] not null default '{}',
  -- The user's current generated training block (focus, filters, and the
  -- resulting day-by-day exercise plan), or null if none is active. See
  -- supabase-schema-phase23-block-builder.sql.
  active_training_block jsonb,
  -- Display-only weight unit preference — every weight column keeps
  -- storing exactly what it always has; this never changes stored data.
  -- Opting out of the friend leaderboard hides you from it entirely
  -- (including your own view), defaulting to true since the leaderboard
  -- already showed everyone with no toggle before this existed. See
  -- supabase-schema-phase24-unit-and-leaderboard-prefs.sql.
  weight_unit text not null default 'lb' check (weight_unit in ('lb', 'kg')),
  leaderboard_opt_in boolean not null default true,
  -- Group Mode notification toggles — see supabase-schema-phase26-group-mode.sql.
  group_streak_emails_opt_out boolean not null default false,
  group_freeze_emails_opt_out boolean not null default false,
  group_goal_emails_opt_out boolean not null default false,
  -- Krafft Athlete Mode — additive, not a replacement for anything else.
  -- athlete_sport/athlete_position are plain text (no check constraint);
  -- the valid-option list lives in SPORTS in index.html, not here, so a
  -- new sport is a JS change, not a migration. athlete_mode_unlocked_at
  -- is what the one-time unlock animation checks, not the enabled flag
  -- itself — see supabase-schema-phase29-athlete-mode.sql.
  athlete_mode_enabled boolean not null default false,
  athlete_mode_unlocked_at timestamptz,
  athlete_sport text,
  athlete_position text,
  athlete_game_plan jsonb,
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
  -- Target bodyweight in lb, optional. Set at onboarding or the Goal
  -- Calculator; informs the rate-of-change calorie adjustment for
  -- lose/gain and drives the "X lb to go" indicator on the Weight tab.
  -- See supabase-schema-phase31-goal-weight.sql.
  goal_weight_lb numeric,
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
    source in ('manual', 'ai_text', 'ai_photo', 'favorite', 'common', 'barcode')
  ),
  photo_path text,
  -- Only ever populated by a barcode scan (Open Food Facts) — no other
  -- logging path collects sugar today. See
  -- supabase-schema-phase21-barcode-scanning.sql.
  sugar_g numeric,
  -- The scanned code, kept even when the lookup fails and the entry gets
  -- finished manually, so it isn't lost.
  barcode text,
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
  -- 'manual' (default, unrestricted — multiple weigh-ins/day stay fine) or
  -- 'healthkit_shortcut'. See supabase-schema-phase22-apple-health-sync.sql
  -- for the partial unique index that makes only the latter idempotent
  -- per day.
  source text not null default 'manual',
  created_at timestamptz not null default now()
);

create index weight_log_user_date_idx on weight_log (user_id, logged_date desc);
create unique index weight_log_healthsync_unique
  on weight_log (user_id, logged_date) where source = 'healthkit_shortcut';

alter table weight_log enable row level security;

create policy "weight_log: select own" on weight_log
  for select using (auth.uid() = user_id);
create policy "weight_log: insert own" on weight_log
  for insert with check (auth.uid() = user_id);
create policy "weight_log: delete own" on weight_log
  for delete using (auth.uid() = user_id);

-- ── health_sync_tokens / sleep_log / steps_log (Apple Health sync) ──────
-- See supabase-schema-phase22-apple-health-sync.sql for the full
-- security rationale (hash-only token storage, no client write path).
create table health_sync_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  token_hash text not null unique,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);
alter table health_sync_tokens enable row level security;
create policy "health_sync_tokens: select own" on health_sync_tokens
  for select using (auth.uid() = user_id);

create table sleep_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_date date not null,
  hours numeric not null,
  source text not null default 'healthkit_shortcut',
  created_at timestamptz not null default now(),
  unique (user_id, logged_date)
);
alter table sleep_log enable row level security;
create policy "sleep_log: select own" on sleep_log
  for select using (auth.uid() = user_id);

create table steps_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_date date not null,
  steps integer not null,
  source text not null default 'healthkit_shortcut',
  created_at timestamptz not null default now(),
  unique (user_id, logged_date)
);
alter table steps_log enable row level security;
create policy "steps_log: select own" on steps_log
  for select using (auth.uid() = user_id);

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

-- ── groups / group_members / group_freeze_log / group_goals (Group Mode) ──
-- One active group per user, built on friendships (not a new social
-- graph) for invite-to-group.js's friend-based invites — a shareable
-- invite_code (below) is a separate, friend-agnostic join path. See
-- supabase-schema-phase26-group-mode.sql for the full rationale.
create table groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  creator_id uuid not null references auth.users(id) on delete cascade,
  -- Streak metric, leader-changeable anytime (not locked at creation) via
  -- update-group-settings.js. 'sessions' is weekly (sessions_target_per_week
  -- required), unlike 'protein'/'calories' which are daily — see
  -- supabase-schema-phase27-group-goal-metric.sql for the full rationale.
  goal_metric text not null default 'protein' check (goal_metric in ('protein', 'calories', 'sessions')),
  sessions_target_per_week int check (sessions_target_per_week is null or (sessions_target_per_week between 1 and 14)),
  current_streak int not null default 0,
  best_streak int not null default 0,
  freezes_available int not null default 0,
  last_evaluated_date date,
  last_achievement_check_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  -- Shareable join link — any member can (re)generate one, which
  -- overwrites and invalidates the previous code. 7-day expiry is set by
  -- generate-group-invite.js at generation time, not a column default.
  -- See supabase-schema-phase28-group-invite-link.sql for the full
  -- rationale.
  invite_code text unique,
  invite_code_expires_at timestamptz,
  constraint groups_sessions_target_required check (goal_metric != 'sessions' or sessions_target_per_week is not null)
);

alter table groups enable row level security;

create index groups_invite_code_idx on groups (invite_code);

create table group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'invited' check (status in ('invited', 'joined')),
  invited_at timestamptz not null default now(),
  joined_at timestamptz,
  unique (group_id, user_id)
);

alter table group_members enable row level security;

-- groups' own select policy depends on group_members existing, so it's
-- created here rather than right after `groups` above.
create policy "groups_select_member" on groups for select
  using (id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

create policy "group_members_select_fellow_members" on group_members for select
  using (user_id = auth.uid() or group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

create policy "group_members_update_own" on group_members for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "group_members_delete_own" on group_members for delete
  using (user_id = auth.uid());

-- Earn/spend ledger — member_id set only for achievement_earned (a
-- compliment, not blame); left null for spent/milestone_earned so the log
-- never singles out who missed a day.
create table group_freeze_log (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  kind text not null check (kind in ('milestone_earned', 'achievement_earned', 'spent')),
  member_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index group_freeze_log_group_idx on group_freeze_log (group_id, created_at desc);

alter table group_freeze_log enable row level security;

create policy "group_freeze_log_select_member" on group_freeze_log for select
  using (group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

-- Separate from the streak mechanic. Progress computed live (like every
-- other progress bar in this app), never stored on this row.
create table group_goals (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  description text not null,
  target_type text not null check (target_type in ('total_sessions')),
  target_value numeric not null,
  period_start date not null,
  period_end date not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table group_goals enable row level security;

create policy "group_goals_select_member" on group_goals for select
  using (group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

create policy "group_goals_insert_member" on group_goals for insert
  with check (created_by = auth.uid() and group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

-- ── conditioning_log / athlete_journal_entries / athlete_confidence_entries
-- (Krafft Athlete Mode) ─────────────────────────────────────────────────
-- Speed/agility work doesn't fit lifts' weight/sets/reps_per_set shape
-- (all NOT NULL there), so it gets its own table rather than loosening
-- those constraints for every existing row. Journal/confidence entries
-- are adapted from the standalone "Show Up Ready" app's data model
-- (github.com/odoglusk-dot/showup-ready) — see
-- supabase-schema-phase29-athlete-mode.sql for the full rationale.
create table conditioning_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  drill text not null,
  metric_type text not null check (metric_type in ('distance', 'time', 'completion')),
  distance_m numeric,
  duration_s numeric,
  completed boolean,
  notes text,
  date date not null,
  created_at timestamptz not null default now()
);

create index conditioning_log_user_date_idx on conditioning_log (user_id, date desc);

alter table conditioning_log enable row level security;

create policy "conditioning_log_select_own" on conditioning_log for select using (auth.uid() = user_id);
create policy "conditioning_log_insert_own" on conditioning_log for insert with check (auth.uid() = user_id);
create policy "conditioning_log_update_own" on conditioning_log for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "conditioning_log_delete_own" on conditioning_log for delete using (auth.uid() = user_id);

create table athlete_journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  what_went_well text,
  one_thing_to_improve text,
  mood int check (mood between 1 and 5),
  entry_date date not null default current_date,
  created_at timestamptz not null default now()
);

create index athlete_journal_entries_user_idx on athlete_journal_entries (user_id, entry_date desc);

alter table athlete_journal_entries enable row level security;

create policy "athlete_journal_entries_select_own" on athlete_journal_entries for select using (auth.uid() = user_id);
create policy "athlete_journal_entries_insert_own" on athlete_journal_entries for insert with check (auth.uid() = user_id);
create policy "athlete_journal_entries_update_own" on athlete_journal_entries for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "athlete_journal_entries_delete_own" on athlete_journal_entries for delete using (auth.uid() = user_id);

create table athlete_confidence_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  source text not null default 'self' check (source in ('self', 'coach', 'teammate', 'other')),
  entry_date date not null default current_date,
  created_at timestamptz not null default now()
);

create index athlete_confidence_entries_user_idx on athlete_confidence_entries (user_id, entry_date desc);

alter table athlete_confidence_entries enable row level security;

create policy "athlete_confidence_entries_select_own" on athlete_confidence_entries for select using (auth.uid() = user_id);
create policy "athlete_confidence_entries_insert_own" on athlete_confidence_entries for insert with check (auth.uid() = user_id);
create policy "athlete_confidence_entries_update_own" on athlete_confidence_entries for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "athlete_confidence_entries_delete_own" on athlete_confidence_entries for delete using (auth.uid() = user_id);

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
  -- Parallel to reps_per_set (same length/index alignment) — true where
  -- that set was a warm-up. Default '{}' means "nothing flagged," so
  -- every set counts as working, same as before this column existed. See
  -- supabase-schema-phase19-warmup-sets.sql. Feeds the weekly
  -- hard-sets-per-muscle feature only; PR detection, career volume, and
  -- the muscle map heatmap are unchanged and still count every set.
  warmup_per_set boolean[] not null default '{}',
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

-- ── plans (Workout Plan Builder — sequences multiple Training Blocks) ───
-- One active plan per user. `phases` is metadata-only (type/duration/
-- reasoning/status) — the current phase's actual exercise plan continues
-- to live in profiles.active_training_block, generated by the same
-- generateBlock() rules engine Block Builder already uses. See
-- supabase-schema-phase25-plan-builder.sql for the full rationale.
create table plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  goal_description text not null,
  goal_type text not null,
  target_exercise text,
  event_date date,
  phases jsonb not null,
  current_phase_index int not null default 0,
  current_phase_started_at date not null,
  priorities jsonb not null default '[]',
  days int not null,
  equipment jsonb not null default '[]',
  avoid jsonb not null default '[]',
  started_at date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index plans_user_idx on plans (user_id);

alter table plans enable row level security;

create policy "plans_select_own" on plans for select using (auth.uid() = user_id);
create policy "plans_insert_own" on plans for insert with check (auth.uid() = user_id);
create policy "plans_update_own" on plans for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "plans_delete_own" on plans for delete using (auth.uid() = user_id);

-- ── exercises (reference data: cue cards, muscle map, split builder,
--    glossary) ──────────────────────────────────────────────────────────
-- See supabase-schema-phase13-exercises.sql for the original rationale,
-- supabase-schema-phase17-exercise-hypertrophy.sql for the hypertrophy
-- columns and the full ~75-exercise dataset below, and
-- supabase-schema-phase18-exercise-tags.sql for the tag/muscle-map-key
-- columns (populated further down via per-row updates, not inline here,
-- to avoid retyping the whole dataset a second time).

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
  -- Static hypertrophy guidance (rep range, rest interval, tempo, a
  -- one-line mind-muscle-connection cue). The rep-range citation lives in
  -- CITATION_LIBRARY in index.html, not a column here, since it's the same
  -- citation reused across every exercise. Rest interval and tempo show
  -- with no citation attached — a hypertrophy-specific rest-interval
  -- source is still unverified; do not attribute it to Grgic et al. 2018,
  -- which covers strength outcomes, not hypertrophy.
  hypertrophy_rep_range text,
  hypertrophy_rest_interval text,
  hypertrophy_tempo text,
  hypertrophy_mind_muscle_cue text,
  -- Tags for the weekly-sets-per-muscle feature and the Block Builder.
  -- muscle_map_key/muscle_map_secondary_keys use a more granular 14-key
  -- taxonomy than body_region above (splits "shoulders" into delts,
  -- "back" into lats/traps/lowerback, adds obliques) — see phase18 for
  -- the full key list and the judgment calls behind a few mappings.
  -- avoid_flags/block_types values in current use are documented in
  -- phase18; 'impact' and the mobility/functional_athletic block types
  -- are declared but unused until that exercise content exists.
  movement_type text,
  lengthened_bias boolean not null default false,
  avoid_flags text[] not null default '{}',
  block_types text[] not null default '{}',
  muscle_map_key text,
  muscle_map_secondary_keys text[] not null default '{}',
  image_url text,
  video_url text,
  created_at timestamptz not null default now()
);

alter table exercises enable row level security;

create policy "exercises_select_all" on exercises for select using (true);

insert into exercises (name, muscle_group, body_region, secondary_regions, equipment, cue_setup, cue_execution, cue_mistake, cue_bracing, hypertrophy_rep_range, hypertrophy_rest_interval, hypertrophy_tempo, hypertrophy_mind_muscle_cue) values

-- ── Chest ──────────────────────────────────────────────────────────────
('Bench Press', 'Push', 'chest', '{triceps,shoulders}', 'Barbell',
  'Set up with eyes under the bar, feet flat and driving into the floor, shoulder blades pulled back and down.',
  'Lower the bar to your lower chest under control, then press up and slightly back toward your face.',
  'Flaring the elbows straight out to the sides instead of tucking them ~45° — it stresses the shoulder more and gives you less pressing power.',
  'Take a breath into your belly before unracking, and hold it through the hardest part of each rep.',
  '6–12 reps', '2–3 min', '2-1-1 tempo — lower for 2 seconds, brief pause on the chest, drive up',
  'Think about pushing yourself away from the bar, not just pushing the bar away from you.'),
('Incline Bench Press', 'Push', 'chest', '{shoulders,triceps}', 'Barbell',
  'Set the bench to a 30–45° incline — steeper shifts the work to shoulders, flatter shifts it back to chest.',
  'Lower the bar to your upper chest, just below the collarbone, then press up and slightly back.',
  'Setting the incline too steep turns this into an overhead press with extra shoulder strain instead of an upper-chest exercise.',
  'Keep your feet planted and glutes on the bench — don''t let your lower back arch off the pad to chase more range.',
  '8–12 reps', '2 min', '2-1-1 tempo',
  'Focus on driving through your upper chest, not just your shoulders.'),
('Decline Bench Press', 'Push', 'chest', '{triceps}', 'Barbell',
  'Secure your feet in the decline bench''s foot pads, lie back with eyes under the bar.',
  'Lower the bar to your lower chest, then press up and slightly back.',
  'Bouncing the bar off the chest to use momentum instead of controlling the full range.',
  'Keep your shoulder blades pulled back and down against the bench throughout.',
  '8–12 reps', '2 min', '2-1-1 tempo',
  'Focus on squeezing the lower chest at the top of the press.'),
('Dumbbell Bench Press', 'Push', 'chest', '{triceps,shoulders}', 'Dumbbell',
  'Lie on a flat bench with a dumbbell in each hand at chest level, elbows bent.',
  'Press the dumbbells up until your arms are extended, then lower under control back to chest level.',
  'Letting the dumbbells drift too far apart or together at the top, losing tension on the chest.',
  'Keep your feet flat on the floor and glutes on the bench for a stable base to press from.',
  '8–12 reps', '90 sec–2 min', '2-1-2 tempo',
  'Squeeze your chest together at the top like you''re hugging a barrel.'),
('Incline Dumbbell Press', 'Push', 'chest', '{shoulders,triceps}', 'Dumbbell',
  'Set the bench to a 30–45° incline, dumbbells at shoulder height.',
  'Press the dumbbells up and slightly in, then lower under control.',
  'Setting the incline too steep, which shifts the work to the shoulders instead of the upper chest.',
  'Keep your lower back flat against the bench, not arched off it.',
  '8–12 reps', '90 sec', '2-1-2 tempo',
  'Picture pressing up and slightly toward the ceiling above your opposite eye.'),
('Dumbbell Fly', 'Push', 'chest', '{shoulders}', 'Dumbbell',
  'Lie on a flat bench with dumbbells held above your chest, a slight bend in the elbows.',
  'Lower the dumbbells out to the sides in a wide arc until you feel a stretch in the chest, then bring them back together.',
  'Bending the elbows more as the weight gets heavy, which turns the fly into a press.',
  'Keep that slight elbow bend fixed throughout — don''t let it change between reps.',
  '10–15 reps', '60–90 sec', '3-1-1 tempo — slow, controlled stretch down',
  'Imagine wrapping your arms around a large barrel, feeling the stretch across your chest.'),
('Cable Fly', 'Push', 'chest', '{shoulders}', 'Cable',
  'Set both pulleys to chest height (or adjust for upper/lower chest emphasis), grip the handles with a slight forward lean.',
  'Bring your hands together in front of your chest in a hugging motion, then return under control.',
  'Using too much weight and turning the movement into a press by bending the elbows more.',
  'Keep a stable, slight forward lean and don''t let your torso rock to help move the weight.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Focus on squeezing your chest together at the peak, holding briefly before releasing.'),
('Pec Deck', 'Push', 'chest', '{shoulders}', 'Machine',
  'Sit with your back flat against the pad, forearms or hands on the arm pads at chest height.',
  'Bring the pads together in front of your chest, then let them return under control.',
  'Letting the weight stack slam down between reps instead of controlling the stretch.',
  'Keep your back pressed into the pad throughout — don''t let it round forward as you squeeze.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Squeeze and hold for a full second at the point your hands are closest together.'),
('Push-Up', 'Push', 'chest', '{triceps,abs}', 'Bodyweight',
  'Hands slightly wider than shoulders, body in a straight line from head to heels.',
  'Lower your chest to just above the floor with elbows at roughly 45°, then press back up.',
  'Letting the hips sag or pike up breaks the straight-line position and shifts load away from the chest.',
  'Brace your abs and squeeze your glutes throughout — treat it like a moving plank, not just an arm exercise.',
  '10–20 reps (add weight or elevate feet once bodyweight gets easy)', '60–90 sec', '2-1-1 tempo',
  'Think about pushing the floor away from you rather than just straightening your arms.'),
('Dip (Chest-Focused)', 'Push', 'chest', '{triceps,shoulders}', 'Bodyweight',
  'Grip the bars with arms straight, lean your torso forward to bias the chest over the triceps.',
  'Lower until you feel a stretch in the chest, then press back up, keeping the forward lean.',
  'Staying too upright, which shifts the emphasis to triceps instead of chest.',
  'Keep your core braced and shoulders down — a forward lean should come from the hips, not a rounded back.',
  '8–15 reps (add weight once bodyweight gets easy)', '90 sec–2 min', '2-1-1 tempo',
  'Lead with your chest on the way down, like you''re diving forward into the stretch.'),

-- ── Back ───────────────────────────────────────────────────────────────
('Deadlift', 'Pull', 'back', '{hamstrings,glutes}', 'Barbell',
  'Bar over mid-foot, shins close to the bar, grip just outside your knees, hips higher than the knees, chest up.',
  'Drive through the floor with your legs while keeping the bar close to your body until you''re standing tall.',
  'Letting the bar drift away from your shins/thighs turns the lift into a lower-back grinder instead of a leg-and-hip drive.',
  'Take a big breath and brace your entire torso like a weightlifting belt before the bar leaves the floor.',
  '5–10 reps', '2–3 min', 'controlled down (2-3 sec), no bounce off the floor on the next rep',
  'Think about pushing the floor away with your legs first, then finishing tall with your hips.'),
('Romanian Deadlift', 'Legs', 'hamstrings', '{glutes,back}', 'Barbell',
  'Start standing with the bar at hip height, soft bend in the knees that stays fixed through the rep.',
  'Push your hips back, lowering the bar along your legs until you feel a stretch in your hamstrings, then drive your hips forward to stand.',
  'Bending the knees more as the bar lowers turns it into a squat and takes tension off the hamstrings — the actual target.',
  'Keep your back flat and core braced — the movement is a hip hinge, not a spinal round.',
  '8–12 reps', '90 sec–2 min', '3-1-1 tempo — slow lowering to really feel the stretch',
  'Focus on feeling a deep stretch in your hamstrings before you reverse the movement.'),
('Barbell Row', 'Pull', 'back', '{biceps,forearms}', 'Barbell',
  'Hinge at the hips to roughly a 45° torso angle, grip just outside shoulder width.',
  'Pull the bar to your lower ribcage, squeezing your shoulder blades together at the top.',
  'Standing up more with each rep (turning it into a mini deadlift) as fatigue sets in instead of holding the hinge.',
  'Keep your core braced and back flat throughout — this is a hip-hinge position, not just an arm pull.',
  '8–12 reps', '90 sec–2 min', '1-1-2 tempo — control the lowering more than the pull',
  'Pull with your elbows, not your hands — imagine driving your elbows toward the ceiling.'),
('Pendlay Row', 'Pull', 'back', '{biceps,forearms}', 'Barbell',
  'Bar on the floor, hinge over to a flat-back, near-horizontal torso position, grip just outside shoulder width.',
  'Pull the bar explosively off the floor to your lower chest/upper abs, then lower it back to a dead stop each rep.',
  'Using body English (a hip heave) to start the pull instead of pulling with the back.',
  'Keep your torso locked in that horizontal position throughout the set — it shouldn''t rise as you fatigue.',
  '6–10 reps', '90 sec–2 min', 'explosive up, controlled down, dead stop each rep',
  'Reset your brace fully between every rep — treat each one as its own lift.'),
('Dumbbell Row', 'Pull', 'back', '{biceps,forearms}', 'Dumbbell',
  'One knee and hand on a bench for support, other foot on the floor, dumbbell hanging in your free hand.',
  'Pull the dumbbell up to your hip, driving your elbow back, then lower under control.',
  'Rotating your torso to help heave the weight up instead of keeping it square.',
  'Keep your supporting arm locked and your back flat, not rounded, throughout the set.',
  '8–12 reps', '90 sec', '1-1-2 tempo',
  'Imagine trying to touch your elbow to the ceiling at the top of each rep.'),
('T-Bar Row', 'Pull', 'back', '{biceps,forearms}', 'Barbell',
  'Straddle the bar with a chest pad or hinge over it, grip the handles with a neutral or wide grip.',
  'Pull the weight up to your torso, squeezing your shoulder blades together, then lower under control.',
  'Using a short, jerky range of motion instead of a full stretch-to-squeeze pull.',
  'Keep your chest against the pad (if using one) or your hinge position fixed throughout.',
  '8–12 reps', '90 sec–2 min', '1-1-2 tempo',
  'Focus on pulling your shoulder blades together, not just bending your elbows.'),
('Seated Cable Row', 'Pull', 'back', '{biceps,forearms}', 'Cable',
  'Sit with knees slightly bent, back tall, grip the handle with arms extended.',
  'Pull the handle to your torso, squeezing your shoulder blades together, then extend back out under control.',
  'Rounding your lower back to add a few extra inches of pull range instead of keeping a tall, stable torso.',
  'Keep your torso upright and braced throughout — the movement should come from your arms and shoulder blades, not your spine rocking.',
  '10–12 reps', '90 sec', '1-1-2 tempo',
  'Lead the pull with your chest moving toward the handle, not just your arms bending.'),
('Lat Pulldown', 'Pull', 'back', '{biceps}', 'Cable',
  'Grip slightly wider than shoulder width, sit tall with thighs secured under the pad.',
  'Pull the bar to your upper chest, driving your elbows down and back, then control it back up.',
  'Leaning back excessively and using body weight instead of your back muscles to move the bar.',
  'Keep your chest up and core braced — a small, controlled lean is fine, but a big swing is momentum, not strength.',
  '10–12 reps', '90 sec', '1-1-2 tempo',
  'Think about pulling your elbows down toward your back pockets.'),
('Pull-Up', 'Pull', 'back', '{biceps,forearms}', 'Bodyweight',
  'Grip just outside shoulder width, palms facing away, hang with arms fully extended.',
  'Pull your chin over the bar leading with your chest, then lower back to a full hang under control.',
  'Only doing the top half of the rep (partial range) trains less muscle and builds strength you can''t actually use.',
  'Keep a slight hollow-body brace so you''re not using an uncontrolled kip or swing to gain momentum.',
  '6–12 reps (add weight once bodyweight gets easy)', '90 sec–2 min', '1-1-2 tempo',
  'Drive your elbows down and back rather than just pulling with your hands.'),
('Chin-Up', 'Pull', 'back', '{biceps}', 'Bodyweight',
  'Grip shoulder width, palms facing you, hang with arms fully extended.',
  'Pull yourself up until your chin clears the bar, then lower back down under control.',
  'Turning it into a chest-up crunch instead of a straight vertical pull reduces the actual back/bicep work.',
  'Keep your ribs down and core tight to avoid an excessive arch through your lower back.',
  '6–12 reps', '90 sec–2 min', '1-1-2 tempo',
  'Feel your lats stretch fully at the bottom before initiating the next pull.'),
('Straight-Arm Pulldown', 'Pull', 'back', '{abs}', 'Cable',
  'Stand facing a high cable pulley, grip a straight bar or rope with arms extended overhead.',
  'Keeping your arms mostly straight, pull the bar down in an arc to your thighs, then let it return.',
  'Bending the elbows significantly, which turns this into a tricep pushdown instead of a lat isolation move.',
  'Keep a slight forward hinge at the hips and brace your core so the movement comes from the shoulder, not the back.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Imagine pulling an imaginary bar down and back toward your hips in a wide arc.'),
('Face Pull', 'Pull', 'shoulders', '{back}', 'Cable',
  'Set the cable at roughly face height, grip the rope with palms facing in.',
  'Pull the rope toward your face, flaring your elbows out wide and rotating your hands back.',
  'Pulling with too much weight and turning it into a row instead of a high-elbow rear-delt/rotator cuff movement.',
  'Keep your upper back tight and shoulders down away from your ears throughout the pull.',
  '12–20 reps', '60 sec', '2-1-2 tempo',
  'Aim the rope toward your forehead and really flare your elbows wide at the end.'),

-- ── Shoulders ──────────────────────────────────────────────────────────
('Overhead Press', 'Push', 'shoulders', '{triceps,abs}', 'Barbell',
  'Grip just outside shoulder width, bar resting on your front delts, elbows slightly in front of the bar.',
  'Press straight up, moving your head back slightly to let the bar pass, then push your head through at the top.',
  'Leaning back excessively to help the bar clear your face turns this into an incline press and stresses the lower back.',
  'Squeeze your glutes and brace your abs like you''re about to be punched in the stomach — a loose torso leaks power.',
  '6–10 reps', '2 min', 'controlled 2 sec down, drive up with intent',
  'Push your head through at the top like you''re trying to look through a window above you.'),
('Seated Dumbbell Press', 'Push', 'shoulders', '{triceps}', 'Dumbbell',
  'Sit on a bench with back support, dumbbells at shoulder height, palms facing forward.',
  'Press the dumbbells up until arms are extended, then lower under control.',
  'Arching the lower back excessively to help push the weight overhead.',
  'Keep your back flat against the bench pad and core braced throughout.',
  '8–12 reps', '90 sec–2 min', '2-1-2 tempo',
  'Press the dumbbells up and slightly together, imagining you''re pressing through a narrow tube.'),
('Arnold Press', 'Push', 'shoulders', '{triceps}', 'Dumbbell',
  'Sit with dumbbells in front of your shoulders, palms facing you.',
  'As you press up, rotate your palms to face forward, finishing with arms extended overhead; reverse the rotation on the way down.',
  'Rushing the rotation instead of timing it smoothly with the press.',
  'Keep your core tight so the rotation doesn''t pull you off balance.',
  '8–12 reps', '90 sec', '2-1-2 tempo',
  'Feel the rotation take your front delt through a longer range than a standard press.'),
('Lateral Raise', 'Push', 'shoulders', '{}', 'Dumbbell',
  'Stand with a slight forward lean, dumbbells at your sides with a soft bend in the elbows.',
  'Raise the dumbbells out to the sides until roughly shoulder height, leading with your elbows.',
  'Using momentum to swing the weight up trains your traps more than your side delts — the target muscle.',
  'Keep your core braced so you''re not using a body swing to substitute for shoulder strength.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Lead with your elbows, not your hands, like you''re pouring water out of a jug at the top.'),
('Front Raise', 'Push', 'shoulders', '{}', 'Dumbbell',
  'Stand holding dumbbells at your thighs, palms facing your body or each other.',
  'Raise one or both dumbbells straight in front of you to shoulder height, then lower under control.',
  'Swinging the weight up using momentum from the hips and lower back.',
  'Keep your core braced and avoid leaning back to help lift the weight.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Focus on lifting with your front delt, not swinging from your torso.'),
('Rear Delt Fly', 'Pull', 'shoulders', '{back}', 'Dumbbell',
  'Hinge forward at the hips, dumbbells hanging below your shoulders, slight bend in the elbows.',
  'Raise the dumbbells out to the sides, squeezing your shoulder blades together, then lower under control.',
  'Standing too upright, which shifts the work to the upper traps instead of the rear delts.',
  'Keep your hinge position fixed and your core braced so you''re not using body momentum.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Imagine pulling your shoulder blades toward each other, not just raising your arms.'),
('Cable Lateral Raise', 'Push', 'shoulders', '{}', 'Cable',
  'Stand side-on to a low cable pulley, grip the handle across your body.',
  'Raise your arm out to the side to shoulder height, then lower under control.',
  'Using body lean to help swing the weight up instead of isolating the shoulder.',
  'Keep your torso upright and stable — the cable''s constant tension means less momentum is available to cheat with.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Feel constant tension through the whole range, especially at the bottom where dumbbells usually lose it.'),
('Upright Row', 'Pull', 'shoulders', '{back}', 'Barbell',
  'Stand holding a bar or dumbbells in front of your thighs, hands shoulder width or slightly closer.',
  'Pull the weight straight up along your body to roughly chest height, leading with your elbows, then lower under control.',
  'Pulling the bar too high or with a very narrow grip, which can aggravate the shoulder joint for some lifters.',
  'Keep your core braced and avoid using a big body heave to start the pull.',
  '10–15 reps', '60–90 sec', '2-1-2 tempo',
  'Think about leading the pull with your elbows staying above your hands throughout.'),
('Shrug', 'Pull', 'back', '{forearms}', 'Barbell',
  'Stand holding a bar or dumbbells at your sides, arms straight.',
  'Elevate your shoulders straight up toward your ears, pause briefly, then lower under control.',
  'Rolling the shoulders in a circular motion instead of a straight up-and-down path.',
  'Keep your arms straight and core braced — the movement should come entirely from the shoulders.',
  '10–15 reps', '60–90 sec', '1-1-2 tempo — pause at the top',
  'Try to touch your shoulders to your ears, holding the squeeze for a full second.'),

-- ── Legs: Quads/Glutes ─────────────────────────────────────────────────
('Back Squat', 'Legs', 'quads', '{glutes,hamstrings}', 'Barbell',
  'Bar on your upper traps (high bar) or rear delts (low bar), feet roughly shoulder width.',
  'Break at the hips and knees together, descending until your hip crease is at or below knee level, then drive back up.',
  'Letting the knees cave inward on the way up, especially on a heavy last rep — it''s a common sign of fatigue or weak hips.',
  'Take a big breath and brace your abs hard before descending — hold that brace through the bottom of the rep.',
  '6–12 reps', '2–3 min', 'controlled 2-3 sec down, drive up with intent',
  'Think about spreading the floor apart with your feet as you stand up.'),
('Front Squat', 'Legs', 'quads', '{abs,glutes}', 'Barbell',
  'Bar racked across your front delts with elbows high, grip can be clean-style or crossed-arm.',
  'Squat down keeping your torso more upright than a back squat, then drive up through your heels/mid-foot.',
  'Letting the elbows drop lowers the bar off your shoulders and pitches your torso forward, losing the position.',
  'Brace your abs hard — an upright torso here depends more on core strength than on the back squat.',
  '6–10 reps', '2–3 min', 'controlled down, no bounce at the bottom',
  'Keep your elbows up and chest tall — imagine balancing a cup of water on your chest.'),
('Goblet Squat', 'Legs', 'quads', '{glutes}', 'Dumbbell',
  'Hold a dumbbell or kettlebell vertically against your chest, feet shoulder width.',
  'Squat down between your knees until your thighs are at least parallel, then drive back up.',
  'Letting the weight pull your torso forward and rounding your upper back.',
  'Keep the weight held tight against your chest and your torso upright throughout.',
  '10–15 reps', '90 sec', '2-1-2 tempo',
  'Use your elbows to gently push your knees out as you descend.'),
('Leg Press', 'Legs', 'quads', '{glutes,hamstrings}', 'Machine',
  'Feet shoulder width on the platform, lower back flat against the pad.',
  'Lower the platform until your knees reach roughly 90°, then press back up without locking your knees hard at the top.',
  'Letting your lower back round off the pad as the weight gets heavy — usually a sign the range of motion is too deep for the load.',
  'Keep your core braced and lower back pinned to the pad throughout the set.',
  '10–15 reps', '90 sec–2 min', '2-1-2 tempo',
  'Focus on pushing through your whole foot, not just your toes.'),
('Bulgarian Split Squat', 'Legs', 'quads', '{glutes}', 'Dumbbell',
  'Rear foot elevated on a bench, front foot far enough forward that your front shin stays close to vertical.',
  'Lower straight down until your back knee is near the floor, then drive up through your front foot.',
  'Placing the front foot too close to the bench forces the front knee too far forward and shifts the emphasis away from the glutes/hamstrings.',
  'Keep your torso tall and core tight — this is a balance-heavy movement, and a loose core makes it worse.',
  '8–12 reps per leg', '90 sec', '2-1-2 tempo',
  'Feel the stretch in your front-leg glute at the bottom before driving up.'),
('Walking Lunge', 'Legs', 'quads', '{glutes,hamstrings}', 'Dumbbell',
  'Stand tall holding dumbbells at your sides or a bar on your back.',
  'Step forward into a lunge, lowering your back knee toward the floor, then drive through your front foot to step into the next rep.',
  'Taking too short a step turns it into a knee-dominant exercise and adds unnecessary knee stress.',
  'Keep your torso upright and core braced — leaning forward shifts the work away from your legs and onto your lower back.',
  '10–15 reps per leg', '90 sec', 'controlled 2 sec descent per step',
  'Push the ground away from you with your front foot rather than pushing off your back foot.'),
('Reverse Lunge', 'Legs', 'quads', '{glutes}', 'Dumbbell',
  'Stand tall holding dumbbells at your sides or a bar on your back.',
  'Step backward into a lunge, lowering your back knee toward the floor, then drive through your front foot to return to standing.',
  'Letting the front knee cave inward as you drive back up.',
  'Keep your torso upright and core braced throughout the step.',
  '10–15 reps per leg', '90 sec', '2-1-2 tempo',
  'Think about driving through your front heel to stand back up, not pushing off your back foot.'),
('Leg Extension', 'Legs', 'quads', '{}', 'Machine',
  'Sit with the pad resting just above your ankles, back against the seat.',
  'Extend your knees until your legs are straight, then lower back under control.',
  'Using momentum to kick the weight up at the top instead of a controlled extension through the full range.',
  'Keep your back against the pad and grip the seat handles to keep your upper body still.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Squeeze and hold at the top for a full second before lowering.'),
('Hip Thrust', 'Legs', 'glutes', '{hamstrings}', 'Barbell',
  'Upper back braced against a bench, bar across your hips, feet flat roughly shoulder width.',
  'Drive your hips up until your torso is roughly in line with your thighs, squeezing your glutes hard at the top.',
  'Overextending the lower back at the top to gain a few extra inches instead of stopping at a straight hip-to-shoulder line.',
  'Tuck your chin slightly and brace your abs at the top of each rep to avoid an exaggerated lower-back arch.',
  '8–15 reps', '90 sec–2 min', '1-2-1 tempo — pause and squeeze at the top',
  'Squeeze your glutes as hard as you can at the top, holding for a full second.'),
('Step-Up', 'Legs', 'quads', '{glutes}', 'Dumbbell',
  'Stand facing a box or bench roughly knee height, dumbbells at your sides.',
  'Step up onto the box leading with one foot, driving through that leg to stand fully on top, then step back down under control.',
  'Pushing off the bottom leg to help you up instead of driving through the top leg.',
  'Keep your torso upright and place your whole foot on the box, not just your toes.',
  '10–15 reps per leg', '90 sec', 'controlled 2 sec down',
  'Focus all the driving effort through the leg that''s on the box.'),

-- ── Legs: Hamstrings/Posterior Chain ────────────────────────────────────
('Stiff-Leg Deadlift', 'Legs', 'hamstrings', '{glutes,back}', 'Barbell',
  'Similar to a Romanian deadlift but with straighter (though not locked) knees, bar at hip height.',
  'Lower the bar along your legs by hinging at the hips until you feel a deep hamstring stretch, then drive your hips forward to stand.',
  'Locking the knees completely, which can strain the lower back and reduce hamstring involvement.',
  'Keep a flat back and braced core throughout — the range of motion is often shorter than an RDL since the legs stay straighter.',
  '8–12 reps', '90 sec–2 min', '3-1-1 tempo',
  'Focus on the stretch in your hamstrings as the primary signal, not how low the bar goes.'),
('Leg Curl', 'Legs', 'hamstrings', '{}', 'Machine',
  'Lie face down (or seated, depending on the machine) with the pad positioned just above your heels.',
  'Curl your heels toward your glutes, then lower back under control without letting the weight stack slam.',
  'Using a big hip lift to help the weight up instead of isolating the hamstrings — keep your hips pinned down.',
  'Keep your hips pressed into the pad/bench throughout the movement.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Curl your heels toward your glutes and squeeze hard at the top.'),
('Good Morning', 'Legs', 'hamstrings', '{glutes,back}', 'Barbell',
  'Bar on your upper back like a squat, feet shoulder width, soft bend in the knees.',
  'Hinge forward at the hips, keeping your back flat, until your torso is near parallel to the floor, then drive your hips forward to stand.',
  'Rounding the lower back as you hinge forward instead of keeping it flat and neutral.',
  'Brace your core hard before descending — this is one of the least forgiving lifts for a loose back.',
  '8–12 reps (start light — this movement has a steep learning curve)', '90 sec–2 min', 'controlled 2-3 sec hinge down',
  'Feel your hamstrings load up as you hinge, treating your hips as the hinge point, not your spine.'),
('Nordic Curl', 'Legs', 'hamstrings', '{}', 'Bodyweight',
  'Kneel with your ankles secured (partner holding them or under a pad), torso upright.',
  'Lower your torso toward the floor as slowly as possible by resisting with your hamstrings, catching yourself with your hands at the bottom, then use your hamstrings and hands to return.',
  'Letting the hips pike or bend forward instead of keeping a straight line from knees to head.',
  'Brace your core and glutes to keep your body in one straight line as you lower.',
  '3–8 reps (an advanced, eccentric-only movement for most lifters)', '90 sec–2 min', 'as slow as possible on the way down',
  'Fight the fall the entire way down — the slower you resist, the more it''s working.'),
('Glute Bridge', 'Legs', 'glutes', '{hamstrings}', 'Bodyweight',
  'Lie on your back, knees bent, feet flat on the floor close to your glutes.',
  'Drive your hips up until your body forms a straight line from shoulders to knees, squeeze, then lower under control.',
  'Overarching the lower back at the top instead of stopping at a straight hip-to-shoulder line.',
  'Brace your abs at the top of each rep to avoid compensating with your lower back.',
  '12–20 reps', '60 sec', '1-2-1 tempo — pause and squeeze at the top',
  'Squeeze your glutes, not your lower back, to lift your hips.'),

-- ── Calves ─────────────────────────────────────────────────────────────
('Standing Calf Raise', 'Legs', 'calves', '{}', 'Machine',
  'Stand on a raised edge or platform with your heels hanging off, balls of your feet planted.',
  'Rise up onto your toes as high as possible, pause briefly, then lower your heels below the platform for a full stretch.',
  'Using short, bouncy reps instead of a full stretch at the bottom and a full contraction at the top — most of the benefit is in that full range.',
  'Keep your knees roughly straight (soft, not locked) so the calves — not the knees — are doing the work.',
  '12–20 reps', '60 sec', '2-1-2 tempo — full stretch, full contraction',
  'Rise as high onto your toes as possible and hold the squeeze briefly.'),
('Seated Calf Raise', 'Legs', 'calves', '{}', 'Machine',
  'Sit with the balls of your feet on the platform, pad resting across your lower thighs.',
  'Rise up onto your toes as high as possible, pause, then lower your heels for a full stretch.',
  'Using a short, bouncy range of motion instead of the full stretch-to-contraction range.',
  'Keep your knees still under the pad — the movement should be isolated to your ankles.',
  '12–20 reps', '60 sec', '2-1-2 tempo',
  'The bent-knee position targets the soleus underneath the calf — focus on that deeper muscle working.'),
('Leg Press Calf Raise', 'Legs', 'calves', '{}', 'Machine',
  'In the leg press machine, place just the balls of your feet on the lower edge of the platform, legs extended.',
  'Push through your toes to extend your ankles, then lower your heels for a full stretch.',
  'Bending the knees to help push the weight instead of isolating the ankle movement.',
  'Keep your knees locked in a fixed, slightly-bent position throughout — only your ankles should move.',
  '12–20 reps', '60 sec', '2-1-2 tempo',
  'Focus on pointing your toes as far as possible at the top of each rep.'),

-- ── Arms: Biceps ───────────────────────────────────────────────────────
('Barbell Curl', 'Pull', 'biceps', '{forearms}', 'Barbell',
  'Stand tall, grip shoulder width, elbows pinned to your sides.',
  'Curl the bar up by bending your elbows, keeping your upper arms still, then lower under control.',
  'Swinging the hips and leaning back to heave the weight up — it takes the tension off the biceps entirely.',
  'Keep your core tight and elbows locked in place so the only thing moving is your forearms.',
  '8–12 reps', '60–90 sec', '2-1-2 tempo',
  'Squeeze your bicep hard at the top rather than just reaching the top position.'),
('Dumbbell Curl', 'Pull', 'biceps', '{forearms}', 'Dumbbell',
  'Stand or sit with dumbbells at your sides, palms facing forward or neutral.',
  'Curl one or both dumbbells up, optionally rotating to a full supination at the top, then lower under control.',
  'Letting the elbow drift forward as the weight gets heavy, which lets the front delt take over the movement.',
  'Keep your upper arm pinned against your torso throughout the rep.',
  '10–12 reps', '60–90 sec', '2-1-2 tempo',
  'Rotate your palm fully up as you curl to get a full bicep contraction.'),
('Hammer Curl', 'Pull', 'biceps', '{forearms}', 'Dumbbell',
  'Stand or sit with dumbbells at your sides, palms facing your body (neutral grip).',
  'Curl the dumbbells up keeping the neutral grip throughout, then lower under control.',
  'Letting the elbows drift forward as the weight gets heavy, reducing bicep/forearm tension.',
  'Keep your upper arms pinned to your sides throughout the movement.',
  '10–12 reps', '60–90 sec', '2-1-2 tempo',
  'This grip emphasizes the brachialis and forearm — focus on the outer arm working, not just the bicep peak.'),
('Preacher Curl', 'Pull', 'biceps', '{forearms}', 'Barbell',
  'Rest your upper arms on the preacher bench pad, grip the bar or dumbbells with arms extended.',
  'Curl the weight up, then lower under control until your arms are nearly straight.',
  'Not lowering all the way, cutting off the stretch portion where preacher curls are most valuable.',
  'Keep your chest against the pad and avoid lifting your upper arms off it to cheat the weight up.',
  '10–12 reps', '60–90 sec', '3-1-1 tempo — slow on the stretch',
  'Focus on the deep stretch at the bottom — that''s what makes this variation valuable.'),
('Cable Curl', 'Pull', 'biceps', '{forearms}', 'Cable',
  'Stand facing a low cable pulley, grip the bar or handle with arms extended.',
  'Curl the handle up toward your shoulders, then lower under control.',
  'Leaning back to use body momentum instead of isolating the biceps.',
  'Keep your torso upright and elbows pinned to your sides — the cable''s constant tension makes cheating more obvious.',
  '10–15 reps', '60 sec', '2-1-2 tempo',
  'Notice the constant tension through the whole range, especially at the bottom where dumbbells lose it.'),
('Incline Dumbbell Curl', 'Pull', 'biceps', '{forearms}', 'Dumbbell',
  'Sit on an incline bench (45–60°), let your arms hang straight down, palms forward.',
  'Curl the dumbbells up without letting your elbows drift forward, then lower under control.',
  'Letting the shoulders round forward to shorten the range instead of getting the full stretch.',
  'Keep your shoulders pinned back against the bench throughout.',
  '10–12 reps', '60–90 sec', '3-1-1 tempo',
  'The behind-the-torso arm position maximizes the stretch — focus on feeling that deep stretch at the bottom.'),
('Concentration Curl', 'Pull', 'biceps', '{}', 'Dumbbell',
  'Sit on a bench, brace your elbow against the inside of your thigh, dumbbell hanging below.',
  'Curl the dumbbell up toward your shoulder, then lower under control.',
  'Letting the elbow drift off the thigh, which lets other muscles assist the lift.',
  'Keep your elbow locked against your thigh throughout the entire set.',
  '10–15 reps', '60 sec', '2-1-2 tempo',
  'With the arm fully isolated, this is the easiest exercise to really feel the bicep working — pay attention to that.'),

-- ── Arms: Triceps ──────────────────────────────────────────────────────
('Close-Grip Bench Press', 'Push', 'triceps', '{chest}', 'Barbell',
  'Grip just inside shoulder width, elbows tucked close to your sides.',
  'Lower the bar to your lower chest keeping elbows tracking straight back, then press up.',
  'Gripping too narrow (hands touching) puts unnecessary strain on the wrists without adding tricep benefit.',
  'Same full-body brace as a regular bench — feet driving down, upper back tight against the bench.',
  '8–12 reps', '90 sec–2 min', '2-1-1 tempo',
  'Keep your elbows tucked and think about pressing straight up, not out.'),
('Tricep Pushdown', 'Push', 'triceps', '{}', 'Cable',
  'Grip the bar or rope with elbows pinned to your sides, standing tall.',
  'Extend your forearms down until your arms are straight, then control the weight back up.',
  'Letting the elbows drift forward or flare out turns this into a shoulder/chest movement instead of isolating the triceps.',
  'Keep your torso still — using body momentum to help the weight down is the most common way to cheat this exercise.',
  '10–15 reps', '60 sec', '2-1-2 tempo',
  'Squeeze and fully extend your arms at the bottom, holding briefly.'),
('Overhead Tricep Extension', 'Push', 'triceps', '{}', 'Dumbbell',
  'Sit or stand holding a dumbbell with both hands overhead, elbows pointed forward.',
  'Lower the dumbbell behind your head by bending the elbows, then extend back to straight arms.',
  'Letting the elbows flare out wide instead of staying pointed forward throughout.',
  'Keep your core braced and ribs down so you''re not overarching your lower back to compensate.',
  '10–15 reps', '60–90 sec', '3-1-1 tempo',
  'Focus on the stretch in your triceps at the bottom of the movement.'),
('Skull Crusher', 'Push', 'triceps', '{}', 'Barbell',
  'Lie on a flat bench, bar held with arms extended straight up over your chest.',
  'Bend your elbows to lower the bar toward your forehead (or just behind it), then extend back up.',
  'Letting the elbows flare out or drift back over the face, increasing shoulder strain.',
  'Keep your upper arms vertical and stationary — only your forearms should move.',
  '10–12 reps', '60–90 sec', '2-1-1 tempo',
  'Keep the movement isolated to your elbow joint, feeling the stretch as the bar lowers.'),
('Dip (Tricep-Focused)', 'Push', 'triceps', '{chest}', 'Bodyweight',
  'Grip the bars with arms straight, keep your torso upright rather than leaning forward.',
  'Lower until your elbows reach about 90°, then press back up, keeping the upright torso.',
  'Leaning forward, which shifts emphasis to the chest instead of the triceps.',
  'Keep your core braced and torso as vertical as possible throughout.',
  '8–15 reps (add weight once bodyweight gets easy)', '90 sec', '2-1-1 tempo',
  'Keep your elbows tracking straight back, close to your body, throughout the movement.'),
('Kickback', 'Push', 'triceps', '{}', 'Dumbbell',
  'Hinge forward at the hips, upper arm parallel to the floor, elbow bent at 90°, dumbbell in hand.',
  'Extend your arm straight back until it''s fully extended, then return to the bent position.',
  'Swinging the weight using shoulder momentum instead of isolating the elbow extension.',
  'Keep your upper arm pinned parallel to the floor throughout — only your forearm should move.',
  '12–15 reps', '60 sec', '2-1-2 tempo',
  'Squeeze and hold the full extension for a full second before returning.'),

-- ── Core ───────────────────────────────────────────────────────────────
('Plank', 'Core', 'abs', '{}', 'Bodyweight',
  'Forearms on the floor under your shoulders, body in a straight line from head to heels.',
  'Hold the position, breathing normally, keeping your hips level — neither sagging nor piking up.',
  'Letting the hips sag toward the floor as fatigue sets in, which shifts the load onto the lower back instead of the abs.',
  'Actively squeeze your abs and glutes throughout — a plank is an active brace, not just a static hold.',
  '30–60 sec holds, 2–4 sets', '45–60 sec', 'n/a — isometric hold',
  'Actively brace and squeeze the entire time — don''t just "rest" in the position.'),
('Hanging Leg Raise', 'Core', 'abs', '{forearms}', 'Bodyweight',
  'Hang from a bar with a full grip, legs extended or knees bent depending on your level.',
  'Curl your hips up and raise your legs (or knees) toward your chest, then lower under control without swinging.',
  'Using momentum from a swing to fling the legs up instead of a controlled hip curl driven by the abs.',
  'Keep your ribs pulled down toward your pelvis throughout — an arched lower back means the hip flexors are taking over from the abs.',
  '10–15 reps', '60–90 sec', '2-1-2 tempo',
  'Focus on curling your pelvis up, not just swinging your legs forward.'),
('Cable Crunch', 'Core', 'abs', '{}', 'Cable',
  'Kneel below a high cable pulley, rope held beside your head, hips stacked over knees.',
  'Crunch your torso down and in, bringing your elbows toward your thighs, then return under control.',
  'Bending only at the hips instead of actually flexing/crunching the spine.',
  'Keep your hips relatively still — the movement should come from spinal flexion, not a hip hinge.',
  '12–20 reps', '60 sec', '2-1-2 tempo',
  'Think about rounding your spine and bringing your ribcage toward your hips.'),
('Ab Wheel Rollout', 'Core', 'abs', '{shoulders}', 'Bodyweight',
  'Kneel on a pad, hands gripping the wheel directly under your shoulders.',
  'Roll forward as far as you can control, keeping your core braced, then pull back to the start using your abs, not your arms.',
  'Letting the lower back sag as you roll out — that''s usually the sign you''ve gone further than your current core strength supports.',
  'Brace your abs hard through the entire rollout — imagine trying to keep a flat line from your shoulders to your knees.',
  '8–15 reps', '60–90 sec', 'controlled, as slow as you can manage',
  'Brace hard the entire time — imagine trying to keep a flat line from shoulders to knees.'),
('Russian Twist', 'Core', 'abs', '{}', 'Bodyweight',
  'Sit with knees bent, lean back slightly to engage your core, feet can be lifted for more difficulty.',
  'Rotate your torso side to side, touching the floor (or a weight) beside your hip each time.',
  'Moving fast and using momentum instead of controlled rotation.',
  'Keep your core braced throughout — this should feel like controlled rotation, not a flailing twist.',
  '16–24 total reps (8–12 per side)', '45–60 sec', 'controlled, 1-2 sec per side',
  'Focus on rotating from your ribcage, not just swinging your arms.'),
('Weighted Sit-Up', 'Core', 'abs', '{}', 'Dumbbell',
  'Lie on your back, knees bent, feet anchored if needed, weight held at your chest.',
  'Sit all the way up by flexing your spine and hips, then lower back down under control.',
  'Using momentum to fling yourself up instead of controlling the movement.',
  'Keep the weight close to your chest throughout to avoid straining your lower back.',
  '10–15 reps', '60 sec', '2-1-2 tempo',
  'Lead with your chest curling toward your knees, not your head jerking forward.'),
('Pallof Press', 'Core', 'abs', '{}', 'Cable',
  'Stand sideways to a cable pulley at chest height, hold the handle at your chest with both hands.',
  'Press the handle straight out in front of you, resisting the cable''s pull to rotate you, then bring it back.',
  'Letting your torso rotate toward the machine instead of resisting the pull.',
  'Brace your core hard to keep your hips and shoulders square the entire time.',
  '10–15 reps per side', '45–60 sec', '2-1-2 tempo',
  'This is an anti-rotation exercise — the goal is to feel your core working to prevent movement, not create it.'),

-- ── Full Body / Compound-Adjacent ────────────────────────────────────────
('Clean', 'Full Body', null, '{back,quads,shoulders}', 'Barbell',
  'Bar over mid-foot, grip just outside shoulder width, hips higher than knees, chest up.',
  'Pull the bar explosively from the floor, extending fully through the hips, then drop under it to catch it in a front-rack position on your shoulders.',
  'Pulling with the arms too early instead of driving the explosive extension through the hips first.',
  'Brace hard off the floor, then reset that brace quickly to absorb the catch.',
  '3–5 reps (technique/power focused, not typically programmed for hypertrophy)', '2–3 min', 'explosive — this is a power movement, not a slow-tempo one',
  'Focus on explosive hip extension — this lift is about speed and technique, not a muscle-feel cue.'),
('Power Clean', 'Full Body', null, '{back,quads,shoulders}', 'Barbell',
  'Bar over mid-foot, same starting position as a deadlift, grip just outside shoulder width.',
  'Pull the bar explosively from the floor, extending through the hips as it passes your thighs, then drop under it to catch it on your front delts.',
  'Muscling the bar up with your arms early instead of using an explosive hip extension — the arms should stay relatively passive until the very end of the pull.',
  'Brace hard off the floor just like a deadlift, then reset that brace quickly to catch the bar in the front-rack position.',
  '3–5 reps (technique/power focused)', '2–3 min', 'explosive pull, controlled catch',
  'Same as the full Clean — the priority is explosive hip extension, not muscle feel.'),
('Clean and Jerk', 'Full Body', null, '{back,quads,shoulders}', 'Barbell',
  'Same starting position as a Clean; after catching the clean in the front rack, reset for the jerk.',
  'Complete the clean into the front rack, then dip slightly and drive the bar overhead, splitting or squatting your feet to catch it locked out.',
  'Pressing the bar up with the arms during the jerk instead of driving it up with a leg dip-and-drive.',
  'Re-brace fully between the clean and the jerk — treat them as two separate, fully-braced efforts.',
  '1–3 reps (a technical, high-skill lift; not a hypertrophy-focused exercise)', '3 min+', 'explosive throughout',
  'This is a technique and power lift — prioritize the movement pattern over any muscle-feel cue.'),
('Snatch', 'Full Body', null, '{back,shoulders,quads}', 'Barbell',
  'Wide grip, bar over mid-foot, similar starting position to a deadlift/clean but with hands further apart.',
  'Pull the bar explosively from the floor directly overhead in one motion, dropping under it to catch in a full overhead squat position.',
  'Muscling the bar up with the arms instead of using an explosive hip extension to give it upward speed.',
  'This requires a strong, stable overhead position — brace your entire torso hard on the catch.',
  '1–3 reps (highly technical; requires coaching before adding load)', '3 min+', 'explosive',
  'Like the Clean, this is about speed and timing, not a hypertrophy muscle-feel cue.'),
('Farmer''s Carry', 'Full Body', null, '{forearms,back,abs}', 'Dumbbell',
  'Stand between two heavy dumbbells or a trap bar, grip firmly, stand up tall.',
  'Walk forward for a set distance or time, keeping your torso upright and shoulders back.',
  'Letting the shoulders round forward or the weight pull you into a lean as you fatigue.',
  'Brace your core like you''re about to be hit, and keep your grip locked in throughout.',
  '20–40 sec (or 20–40 yards) per set', '60–90 sec', 'steady, controlled walking pace',
  'Focus on staying tall and stable — this is as much a bracing/grip exercise as it is a leg/conditioning one.'),
('Thruster', 'Full Body', null, '{quads,shoulders}', 'Barbell',
  'Bar in a front-rack position (like a front squat), feet shoulder width.',
  'Squat down, then use the upward drive out of the squat to press the bar overhead in one continuous motion.',
  'Pausing between the squat and the press instead of using the leg drive to help the press.',
  'Brace hard before descending — you''ll need that same brace to support the overhead press right after.',
  '8–15 reps (often used for conditioning/metabolic work more than pure hypertrophy)', '60–90 sec', 'continuous — squat and press blend into one fluid motion',
  'Feel the momentum from your legs carrying directly into the press — it shouldn''t feel like two separate movements.');


-- Exercise tag data (movement type, lengthened-bias, avoid-flags,
-- block-type suitability, muscle-map keys) — see
-- supabase-schema-phase18-exercise-tags.sql for the full rationale.

update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,delts}' where name = 'Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts,triceps}' where name = 'Incline Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps}' where name = 'Decline Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,delts}' where name = 'Dumbbell Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts,triceps}' where name = 'Incline Dumbbell Press';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts}' where name = 'Dumbbell Fly';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts}' where name = 'Cable Fly';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts}' where name = 'Pec Deck';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,abs}' where name = 'Push-Up';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,delts}' where name = 'Dip (Chest-Focused)';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{hamstrings,glutes}' where name = 'Deadlift';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{heavy_spinal_load}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{glutes,lowerback}' where name = 'Romanian Deadlift';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Barbell Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Pendlay Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Dumbbell Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'T-Bar Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Seated Cable Row';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps}' where name = 'Lat Pulldown';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Pull-Up';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps}' where name = 'Chin-Up';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{abs}' where name = 'Straight-Arm Pulldown';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{traps}' where name = 'Face Pull';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead,heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{triceps,abs}' where name = 'Overhead Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{triceps}' where name = 'Seated Dumbbell Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{triceps}' where name = 'Arnold Press';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{}' where name = 'Lateral Raise';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{}' where name = 'Front Raise';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{traps}' where name = 'Rear Delt Fly';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{}' where name = 'Cable Lateral Raise';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{traps}' where name = 'Upright Row';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'traps', muscle_map_secondary_keys = '{forearms}' where name = 'Shrug';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes,hamstrings}' where name = 'Back Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{abs,glutes}' where name = 'Front Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Goblet Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes,hamstrings}' where name = 'Leg Press';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Bulgarian Split Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes,hamstrings}' where name = 'Walking Lunge';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Reverse Lunge';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{}' where name = 'Leg Extension';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'glutes', muscle_map_secondary_keys = '{hamstrings}' where name = 'Hip Thrust';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Step-Up';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{heavy_spinal_load}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{glutes,lowerback}' where name = 'Stiff-Leg Deadlift';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{}' where name = 'Leg Curl';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{heavy_spinal_load}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{glutes,lowerback}' where name = 'Good Morning';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{}' where name = 'Nordic Curl';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'glutes', muscle_map_secondary_keys = '{hamstrings}' where name = 'Glute Bridge';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'calves', muscle_map_secondary_keys = '{}' where name = 'Standing Calf Raise';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'calves', muscle_map_secondary_keys = '{}' where name = 'Seated Calf Raise';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'calves', muscle_map_secondary_keys = '{}' where name = 'Leg Press Calf Raise';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Barbell Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Dumbbell Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Hammer Curl';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Preacher Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Cable Curl';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Incline Dumbbell Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{}' where name = 'Concentration Curl';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{chest}' where name = 'Close-Grip Bench Press';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Tricep Pushdown';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Overhead Tricep Extension';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Skull Crusher';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{chest}' where name = 'Dip (Tricep-Focused)';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Kickback';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{}' where name = 'Plank';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{forearms}' where name = 'Hanging Leg Raise';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{}' where name = 'Cable Crunch';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{delts}' where name = 'Ab Wheel Rollout';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'obliques', muscle_map_secondary_keys = '{}' where name = 'Russian Twist';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{}' where name = 'Weighted Sit-Up';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'obliques', muscle_map_secondary_keys = '{}' where name = 'Pallof Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{quads,delts}' where name = 'Clean';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{quads,delts}' where name = 'Power Clean';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead,heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{quads,delts}' where name = 'Clean and Jerk';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead,heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{delts,quads}' where name = 'Snatch';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'forearms', muscle_map_secondary_keys = '{lowerback,abs}' where name = 'Farmer''s Carry';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{delts}' where name = 'Thruster';

-- Plyometric exercises (Krafft Athlete Mode) — fills the
-- power_speed/functional_athletic pools with real content for the first
-- time. See supabase-schema-phase30-plyometric-exercises.sql for the
-- full rationale; cues are written for explosive/reactive movement with
-- landing mechanics called out as their own cue line.
insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake, cue_bracing,
  movement_type, lengthened_bias, avoid_flags, block_types,
  muscle_map_key, muscle_map_secondary_keys
) values
('Box Jump', 'Legs', 'legs', '{}', 'Bodyweight',
 'Stand arm''s length from a sturdy, stable box or platform, feet shoulder-width apart, knees soft.',
 'Swing your arms back, then drive them forward and up explosively while extending through the hips, knees, and ankles to jump onto the box.',
 'Landing with stiff, locked knees. Absorb the landing by bending your hips and knees the instant your feet touch down — don''t let your legs stay straight through impact.',
 'Brace your core before takeoff and keep it braced through landing, so the impact loads your legs and hips, not a collapsing lower back.',
 'plyometric', false, '{impact}', '{functional_athletic,power_speed}', 'quads', '{glutes,calves}'),

('Depth Jump', 'Legs', 'legs', '{}', 'Bodyweight',
 'Stand on a low box (roughly 12-18 inches), feet hip-width apart, near the front edge.',
 'Step off the box — don''t jump off — land on both feet, and the instant your feet touch the ground, explode straight up into a maximal vertical jump.',
 'Pausing on the ground before jumping back up. This turns one reactive movement into two separate ones — the point is a near-instant rebound, not a stop-and-go squat.',
 'Keep your torso tall and braced through the landing so the rebound is driven by your legs and hips snapping into the ground, not a trunk that folds forward.',
 'plyometric', false, '{impact}', '{functional_athletic,power_speed}', 'quads', '{glutes,hamstrings}'),

('Broad Jump', 'Legs', 'legs', '{}', 'Bodyweight',
 'Stand with feet shoulder-width apart, toes just behind a start line, knees slightly bent.',
 'Swing your arms back and load your hips, then drive forward and up explosively, extending fully through the hips and ankles to jump as far forward as possible.',
 'Landing off-balance or falling backward. Land with knees bent, absorbing through the hips, and stick the landing under control before resetting for the next rep.',
 'Brace your core on takeoff so the power comes from your hips and legs, and keep that brace through landing to control your forward momentum.',
 'plyometric', false, '{impact}', '{functional_athletic,power_speed}', 'quads', '{glutes,hamstrings}'),

('Lateral Bound', 'Legs', 'legs', '{}', 'Bodyweight',
 'Start balanced on one leg, knee slightly bent, the other leg lifted slightly off the ground.',
 'Push off hard to the side off the stance leg, driving through the hip to bound laterally, and land softly on the opposite leg with the knee tracking over the foot.',
 'Letting the landing knee cave inward toward the midline. Keep the knee aligned over the foot on landing to control the sideways force instead of absorbing it at the joint.',
 'Brace your core through each landing to stay stable on one leg before bounding back the other direction.',
 'plyometric', false, '{impact}', '{functional_athletic}', 'glutes', '{quads,calves}'),

('Single-Leg Bound', 'Legs', 'legs', '{}', 'Bodyweight',
 'Start in a slight single-leg athletic stance, knee soft, opposite arm back.',
 'Drive off the ground leg explosively, extending the hip fully, and bound forward to land on the same leg, absorbing through the hip and knee before bounding again.',
 'Landing flat-footed with a straight knee. Land on the ball of the foot with the knee bent to absorb the impact before the next bound.',
 'Keep your core braced and your landing leg stable under your hips on each touchdown, rather than reaching out in front of your body.',
 'plyometric', false, '{impact}', '{functional_athletic}', 'hamstrings', '{glutes,calves}'),

('Tuck Jump', 'Legs', 'legs', '{}', 'Bodyweight',
 'Stand with feet shoulder-width apart, knees soft, arms relaxed at your sides.',
 'Jump straight up as high as possible, driving your knees up toward your chest at the peak, then land softly back in the starting stance and repeat immediately.',
 'Landing with knees collapsing inward. Land with feet shoulder-width apart and knees tracking over the toes on every rep, even as fatigue sets in.',
 'Brace your core throughout to keep your trunk upright instead of leaning forward to generate the knee drive.',
 'plyometric', false, '{impact}', '{functional_athletic,power_speed}', 'quads', '{abs}'),

('Squat Jump', 'Legs', 'legs', '{}', 'Bodyweight',
 'Stand with feet shoulder-width apart, drop into a quarter-to-half squat.',
 'Explode upward out of the squat, extending hips, knees, and ankles fully to jump as high as possible, then land softly back into the squat position.',
 'Re-bending the knees too little on landing, so the impact goes straight into the joints. Land back into the same depth of squat you jumped from to absorb the force.',
 'Keep your core braced throughout the jump and landing to keep your torso upright rather than collapsing forward.',
 'plyometric', false, '{impact}', '{functional_athletic,power_speed}', 'quads', '{glutes}'),

('Medicine Ball Chest Pass', 'Chest', 'chest', '{}', 'Medicine Ball',
 'Stand or half-kneel facing a solid wall, holding the ball at your chest with both hands.',
 'Explosively extend your arms and push the ball into the wall as hard as possible, catching it on the rebound and resetting quickly for the next rep.',
 'Pushing only with the arms. Drive the pass with a quick extension through the chest and a slight hip snap, not an arm-only shove.',
 'Brace your core to keep your torso stable as you catch the rebound, rather than getting knocked backward by the ball''s momentum.',
 'plyometric', false, '{}', '{functional_athletic}', 'chest', '{delts,triceps}'),

('Medicine Ball Overhead Slam', 'Abs', 'core', '{}', 'Medicine Ball',
 'Stand with feet shoulder-width apart, holding the ball overhead with both hands, arms extended.',
 'Explosively flex at the hips and core, slamming the ball into the ground as hard as possible in front of your feet, then catch the bounce and reset.',
 'Rounding the lower back on the slam. Hinge at the hips and brace the core through the movement rather than letting the spine flex under load.',
 'Brace your core hard right as the ball leaves your hands — that brace is what transfers the power from your hips into the slam.',
 'plyometric', false, '{}', '{functional_athletic}', 'abs', '{lowerback}'),

('Medicine Ball Rotational Throw', 'Obliques', 'core', '{}', 'Medicine Ball',
 'Stand sideways to a solid wall, feet shoulder-width apart, holding the ball at hip height with both hands.',
 'Rotate your hips and trunk away from the wall slightly, then explosively reverse the rotation, releasing the ball into the wall at hip height, and catch the rebound.',
 'Rotating only through the arms and shoulders. The power should start from the hips turning first, with the trunk and arms following — not the other way around.',
 'Keep your core braced through the rotation so the force transfers through your trunk instead of loading your lower back at the end range.',
 'plyometric', false, '{}', '{functional_athletic}', 'obliques', '{abs}');

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

-- ── workout_sessions (End Workout flow + post-session AI analysis) ──────
-- A "session" is one calendar day of lifts — see
-- supabase-schema-phase16-workout-sessions.sql for the full rationale.
create table workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  ended_at timestamptz,
  analysis jsonb,
  analysis_generated_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, date)
);

alter table workout_sessions enable row level security;

create policy "workout_sessions_select_own" on workout_sessions for select
  using (auth.uid() = user_id);
create policy "workout_sessions_insert_own" on workout_sessions for insert
  with check (auth.uid() = user_id);
create policy "workout_sessions_update_own" on workout_sessions for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════════════════════
-- RESET COMPLETE
-- All tables created fresh with consistent naming:
--   - ALL macro columns: protein_g, carbs_g, fat_g (with _g suffix)
--   - ALL date columns: logged_date or logged_at (not inconsistent naming)
--   - ALL id columns: id (uuid)
--   - ALL user_id columns: user_id (uuid)
-- ══════════════════════════════════════════════════════════════════════════
