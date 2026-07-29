-- Plated — core schema
-- Run this first in the Supabase SQL editor, then supabase-schema-additions.sql.
-- Every personal table is scoped to auth.uid() via Row Level Security so one
-- account can never read or write another account's rows.

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
