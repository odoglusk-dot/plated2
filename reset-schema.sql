-- ============================================================
-- COMPLETE PLATED SCHEMA RESET
-- Drops ALL tables and recreates them fresh from scratch.
-- Run this in Supabase SQL editor if you have schema conflicts.
-- ============================================================

-- Drop all tables in correct dependency order (reverse of creation)
drop table if exists subscriptions cascade;
drop table if exists ai_usage cascade;
drop table if exists supplement_logs cascade;
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
create table subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'free'
    check (status in ('free', 'trialing', 'active', 'canceled', 'past_due')),
  stripe_customer_id text,
  stripe_subscription_id text,
  current_period_end timestamptz,
  updated_at timestamptz not null default now()
);

alter table subscriptions enable row level security;

create policy "subscriptions: select own" on subscriptions
  for select using (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════════════════════
-- RESET COMPLETE
-- All tables created fresh with consistent naming:
--   - ALL macro columns: protein_g, carbs_g, fat_g (with _g suffix)
--   - ALL date columns: logged_date or logged_at (not inconsistent naming)
--   - ALL id columns: id (uuid)
--   - ALL user_id columns: user_id (uuid)
-- ══════════════════════════════════════════════════════════════════════════
