-- Plated — schema additions (favorites, weight tracking, supplements, AI rate limiting)
-- Run this after supabase-schema.sql in the same Supabase project.

-- ── favorites ───────────────────────────────────────────────────────────
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
  primary key (user_id, usage_date)
);

alter table ai_usage enable row level security;

create policy "ai_usage: select own" on ai_usage
  for select using (auth.uid() = user_id);
create policy "ai_usage: insert own" on ai_usage
  for insert with check (auth.uid() = user_id);
create policy "ai_usage: update own" on ai_usage
  for update using (auth.uid() = user_id);
