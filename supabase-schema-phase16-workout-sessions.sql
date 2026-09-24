-- Krafft — Phase 16: End Workout flow + post-session AI analysis.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- A "session" is one calendar day of lifts — the app has no clock-time
-- session boundary today (lifts.date is a date, not a timestamp range),
-- and every existing "today's session" concept in index.html (today's
-- summary card, the Exercises list, PR detection) is already scoped this
-- way, so this table follows the same convention rather than inventing a
-- separate multi-session-per-day model. unique(user_id, date) enforces
-- that.
--
-- ended_at null = active (or reopened); set = ended. There's no separate
-- "started_at" column — the session's start is already implicit in the
-- earliest lifts.created_at for that date, and the "still training?"
-- staleness check reads lifts.created_at directly rather than duplicating
-- that timestamp here.
--
-- analysis/analysis_generated_at cache the AI writeup so it's generated at
-- most once per session (once per day, per the product decision to keep
-- this to one AI call per day) rather than re-calling Anthropic every time
-- the session-ended screen is viewed or the session is reopened and
-- re-ended.

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
