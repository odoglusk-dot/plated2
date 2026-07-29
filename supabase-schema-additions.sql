-- ============================================================
-- Plated — additional tables for features built AFTER the Supabase
-- version was forked from the reference HTML file: favorites, weight
-- tracking, and supplement logging. Run this in the same Supabase
-- project, after supabase-schema.sql.
-- ============================================================
-- ---------- favorites ----------
-- Saved foods for one-tap re-logging. Not date-based like food_logs —
-- just a personal list per user.
create table if not exists favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  food text not null,
  serving text,
  calories int not null default 0,
  protein int not null default 0,
  carbs int not null default 0,
  fat int not null default 0,
  created_at timestamptz default now()
);
alter table favorites enable row level security;
create policy "favorites: select own" on favorites
  for select using (auth.uid() = user_id);
create policy "favorites: insert own" on favorites
  for insert with check (auth.uid() = user_id);
create policy "favorites: delete own" on favorites
  for delete using (auth.uid() = user_id);
-- ---------- weight_log ----------
-- One row per weigh-in. log_date is unique per user (one entry per day —
-- logging again on the same date should overwrite, not duplicate).
create table if not exists weight_log (
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null,
  weight numeric not null,
  created_at timestamptz default now(),
  primary key (user_id, log_date)
);
alter table weight_log enable row level security;
create policy "weight_log: select own" on weight_log
  for select using (auth.uid() = user_id);
create policy "weight_log: insert own" on weight_log
  for insert with check (auth.uid() = user_id);
create policy "weight_log: update own" on weight_log
  for update using (auth.uid() = user_id);
create policy "weight_log: delete own" on weight_log
  for delete using (auth.uid() = user_id);
-- ---------- supplement_logs ----------
-- Mirrors food_logs' shape (per-row, per-date) but for supplements/vitamins.
create table if not exists supplement_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null,
  name text not null,
  dose text,
  taken_at text, -- display-friendly time string, e.g. "8:32 AM"
  created_at timestamptz default now()
);
alter table supplement_logs enable row level security;
create policy "supplement_logs: select own" on supplement_logs
  for select using (auth.uid() = user_id);
create policy "supplement_logs: insert own" on supplement_logs
  for insert with check (auth.uid() = user_id);
create policy "supplement_logs: delete own" on supplement_logs
  for delete using (auth.uid() = user_id);
create index if not exists supplement_logs_user_date_idx on supplement_logs (user_id, log_date);
create index if not exists weight_log_user_date_idx on weight_log (user_id, log_date);
