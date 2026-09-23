-- Plated (Kraft) — Phase 9: training splits (presets + custom builder).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- One active split per user (unique on user_id) — this is deliberately a
-- lightweight helper, not a program-management system: picking a new
-- preset or saving custom-builder changes replaces the row rather than
-- versioning multiple saved splits. `days` is an ordered JSON array,
-- e.g. [{"label":"Push","muscle_groups":["Push"]}, ...] — rotation length
-- is just days.length, and "today's slot" is computed client-side from
-- days-since-start_date modulo that length (see computeSplitDayIndex()
-- in index.html). muscle_groups values match the app's existing
-- MUSCLE_GROUPS categories (Legs/Push/Pull/Core/Full Body/Other) so the
-- Lifts tab can highlight exercises tagged to today's focus.

create table if not exists training_splits (
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
