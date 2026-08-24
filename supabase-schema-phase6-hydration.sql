-- Plated — Phase 6 (Hydration tracking) migration.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get this automatically from reset-schema.sql
-- instead.

alter table goals add column if not exists water_oz numeric not null default 64;

-- Append-only, one row per quick-add tap (e.g. "+8oz") rather than one
-- running daily total, so the dashboard can sum "today" the same way it
-- already does for food_logs — logged_at + a client-side date filter, no
-- separate daily-rollup logic to keep in sync.
create table if not exists water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_oz numeric not null,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists water_logs_user_logged_idx on water_logs (user_id, logged_at desc);

alter table water_logs enable row level security;

create policy "water_logs: select own" on water_logs
  for select using (auth.uid() = user_id);
create policy "water_logs: insert own" on water_logs
  for insert with check (auth.uid() = user_id);
create policy "water_logs: delete own" on water_logs
  for delete using (auth.uid() = user_id);
