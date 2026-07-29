-- ============================================================
-- Plated · Macro Log — Supabase schema
-- Run this in your Supabase project: SQL Editor → New query → paste → Run
-- ============================================================
-- This relies on Supabase Auth (auth.users) for real authentication —
-- password hashing, sessions, everything — instead of anything homemade.
-- Every table below is locked down with Row-Level Security (RLS) so that,
-- at the database level, a user can only ever read or write their own rows.
-- This is what actually enforces "can't see other people's data," not
-- just the app's UI choosing not to show it.

-- ---------- profiles ----------
-- One row per user, keyed by their auth.users id.
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "profiles: select own" on profiles
  for select using (auth.uid() = id);
create policy "profiles: insert own" on profiles
  for insert with check (auth.uid() = id);
create policy "profiles: update own" on profiles
  for update using (auth.uid() = id);

-- ---------- goals ----------
-- One row per user. Upserted whenever they save/calculate goals.
create table if not exists goals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  protein int not null default 160,
  calories int not null default 2600,
  carbs int not null default 280,
  fat int not null default 80,
  updated_at timestamptz default now()
);

alter table goals enable row level security;

create policy "goals: select own" on goals
  for select using (auth.uid() = user_id);
create policy "goals: insert own" on goals
  for insert with check (auth.uid() = user_id);
create policy "goals: update own" on goals
  for update using (auth.uid() = user_id);

-- ---------- body_stats ----------
-- One row per user — inputs to the Mifflin-St Jeor goal calculator.
create table if not exists body_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  sex text,
  age int,
  height_ft int,
  height_in int,
  weight numeric,
  goal_weight numeric,
  activity numeric,
  updated_at timestamptz default now()
);

alter table body_stats enable row level security;

create policy "body_stats: select own" on body_stats
  for select using (auth.uid() = user_id);
create policy "body_stats: insert own" on body_stats
  for insert with check (auth.uid() = user_id);
create policy "body_stats: update own" on body_stats
  for update using (auth.uid() = user_id);

-- ---------- food_logs ----------
-- One row per logged food item. log_date is a plain date (not timestamp)
-- so "today's entries" and "history by day" are simple date-equality/range
-- queries instead of parsing JSON blobs.
create table if not exists food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null,
  food text not null,
  serving text,
  calories int not null default 0,
  protein int not null default 0,
  carbs int not null default 0,
  fat int not null default 0,
  source text not null default 'manual', -- 'ai' | 'cache' | 'common' | 'suggestion' | 'manual'
  created_at timestamptz default now()
);

alter table food_logs enable row level security;

create policy "food_logs: select own" on food_logs
  for select using (auth.uid() = user_id);
create policy "food_logs: insert own" on food_logs
  for insert with check (auth.uid() = user_id);
create policy "food_logs: update own" on food_logs
  for update using (auth.uid() = user_id);
create policy "food_logs: delete own" on food_logs
  for delete using (auth.uid() = user_id);

create index if not exists food_logs_user_date_idx on food_logs (user_id, log_date);

-- ---------- food_cache ----------
-- Shared across ALL users on purpose — this is generic nutrition data
-- ("grilled chicken breast" → macros), not anyone's personal log, so it's
-- fine for every signed-in user to read and contribute to it. This is what
-- keeps AI lookup costs down site-wide: once anyone estimates a food, nobody
-- pays to estimate it again.
create table if not exists food_cache (
  cache_key text primary key,
  food text not null,
  serving text,
  calories int not null,
  protein int not null,
  carbs int not null,
  fat int not null,
  created_at timestamptz default now()
);

alter table food_cache enable row level security;

create policy "food_cache: read by any signed-in user" on food_cache
  for select using (auth.role() = 'authenticated');
create policy "food_cache: insert by any signed-in user" on food_cache
  for insert with check (auth.role() = 'authenticated');

-- ============================================================
-- That's it. After running this, come back to the app — signing up
-- creates a real auth.users row automatically; the app creates the
-- matching profiles/goals rows the first time someone saves something.
-- ============================================================
