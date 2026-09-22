-- Plated — Phase 7 (IronLog merge) migration.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get this automatically from reset-schema.sql
-- instead.
--
-- Ported from IronLog's own supabase/schema.sql, with two deliberate
-- differences from a straight copy:
--   1. IronLog's `goals` table is renamed to `exercise_goals` here — Plated
--      already has a `goals` table (one row per user: calorie/macro/water
--      targets). IronLog's is a different shape entirely (one row per
--      exercise: target_weight + target_date). Same name, unrelated
--      tables — this collision had to be caught, not silently overwritten.
--   2. IronLog's `bodyweight` table is NOT created here. Plated's existing
--      `weight_log` (weight_lb, logged_date) is the same shape as
--      IronLog's `bodyweight` (weight, date) — same unit (lb), no
--      conversion needed — so bodyweight tracking is unified into the
--      table that already exists rather than kept as a second, parallel
--      weight log. Nothing to migrate schema-wise; only data (a later
--      step, once IronLog's service-role key is available) moves rows
--      from IronLog's `bodyweight` into this project's `weight_log`.

create table if not exists lifts (
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
  -- alongside (not replacing) muscle_group above. One primary region per
  -- exercise for v1 — nullable, no default, since an unmapped exercise
  -- just doesn't count toward the map rather than guessing wrong.
  body_region text,
  created_at timestamptz not null default now()
);

create index if not exists lifts_user_date_idx on lifts (user_id, date);

alter table lifts enable row level security;

create policy "lifts_select_own" on lifts for select using (auth.uid() = user_id);
create policy "lifts_insert_own" on lifts for insert with check (auth.uid() = user_id);
create policy "lifts_update_own" on lifts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "lifts_delete_own" on lifts for delete using (auth.uid() = user_id);

-- One live goal per exercise: target weight by a target date. Setting a
-- new goal for an exercise replaces its old one (upsert on user_id+exercise).
-- Named exercise_goals, not goals — see the note at the top of this file.
create table if not exists exercise_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise text not null,
  target_weight numeric not null,
  target_date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, exercise)
);

create index if not exists exercise_goals_user_idx on exercise_goals (user_id);

alter table exercise_goals enable row level security;

create policy "exercise_goals_select_own" on exercise_goals for select using (auth.uid() = user_id);
create policy "exercise_goals_insert_own" on exercise_goals for insert with check (auth.uid() = user_id);
create policy "exercise_goals_update_own" on exercise_goals for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "exercise_goals_delete_own" on exercise_goals for delete using (auth.uid() = user_id);

-- Cached per-month training recap stats (Recaps tab — a later phase).
-- Generated lazily client-side the first time a user views a given month,
-- then upserted here so subsequent views skip recomputation.
create table if not exists monthly_recaps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month date not null, -- first day of the recapped month, e.g. 2026-07-01
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

create index if not exists monthly_recaps_user_month_idx on monthly_recaps (user_id, month);

alter table monthly_recaps enable row level security;

create policy "monthly_recaps_select_own" on monthly_recaps for select using (auth.uid() = user_id);
create policy "monthly_recaps_insert_own" on monthly_recaps for insert with check (auth.uid() = user_id);
create policy "monthly_recaps_update_own" on monthly_recaps for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "monthly_recaps_delete_own" on monthly_recaps for delete using (auth.uid() = user_id);

-- Storage bucket for training progress photos (Photos tab — a later
-- phase). Created now alongside the rest of this migration since it's
-- cheap to have ready; kept private, the app requests short-lived signed
-- URLs to display images instead of public links.
insert into storage.buckets (id, name, public)
values ('progress-photos', 'progress-photos', false)
on conflict (id) do nothing;

-- Objects are uploaded to "<user_id>/<filename>.jpg" — these policies only
-- let a user touch objects under their own folder.
create policy "progress_photos_select_own" on storage.objects for select
  using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "progress_photos_insert_own" on storage.objects for insert
  with check (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "progress_photos_delete_own" on storage.objects for delete
  using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);
