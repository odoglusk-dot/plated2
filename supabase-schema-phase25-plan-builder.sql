-- Plated (Kraft) — Phase 25: Workout Plan Builder.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- A Plan sequences multiple Training Blocks toward a longer-term goal
-- (e.g. "Add 30 lb to my bench in 4 months") using real periodization —
-- Hypertrophy -> Strength -> Deload -> Strength -> Peak, rather than the
-- same block type on repeat. One active plan per user (unique on
-- user_id), same lightweight, non-versioned philosophy as
-- training_splits — starting a new plan replaces the row.
--
-- `phases` is deliberately metadata-only (no embedded exercise plan per
-- phase): [{type, duration_weeks, reasoning, status}]. The CURRENT
-- phase's actual day-by-day plan continues to live solely in the
-- existing profiles.active_training_block column and is generated via
-- the same generateBlock() rules engine Block Builder already uses —
-- this table only decides which block type comes next and for how long,
-- it never stores exercises itself. `status` per phase is one of
-- 'upcoming' | 'active' | 'completed'.
--
-- `current_phase_started_at` is updated every time the user advances to a
-- new phase (including open_ended's wrap back to phase 0) — deliberately
-- its own column rather than derived by summing prior phases' durations
-- from `started_at`, since that math breaks once a plan wraps.
--
-- `priorities`/`days`/`equipment`/`avoid` are collected once during Plan
-- setup and carried into every phase's generateBlock() call, so the user
-- isn't re-asked per phase. `target_exercise` is optional and, when set,
-- points at an existing exercise_goals row (goal_type = 'strength_target')
-- rather than duplicating target-weight/target-date/projection logic
-- here — see projectGoalDate() in index.html. `event_date` is optional
-- and only meaningful for goal_type = 'event_prep', driving where a
-- taper phase gets inserted.
create table if not exists plans (
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

create index if not exists plans_user_idx on plans (user_id);

alter table plans enable row level security;

create policy "plans_select_own" on plans for select using (auth.uid() = user_id);
create policy "plans_insert_own" on plans for insert with check (auth.uid() = user_id);
create policy "plans_update_own" on plans for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "plans_delete_own" on plans for delete using (auth.uid() = user_id);
