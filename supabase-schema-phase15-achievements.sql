-- Krafft — Phase 15: achievement/milestone system.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Achievement *definitions* (title, coach-voice description, unlock
-- condition) live in ACHIEVEMENT_LIBRARY in index.html, same pattern as
-- the Layer 1 tips library and the exercises table — static content, not
-- stored in the database. This table only records *when a given account
-- unlocked a given achievement id*, so an unlock is permanent (checked
-- once, recorded once, never re-derived or revoked) even if the logged
-- data that originally satisfied the condition later changes (e.g. a lift
-- entry gets edited or deleted after a PR-based achievement unlocked).
--
-- No update/delete policy on purpose — once earned, an achievement stays
-- earned; nothing in the app is meant to un-unlock or edit one.

create table user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  unlocked_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);

alter table user_achievements enable row level security;

create policy "user_achievements_select_own" on user_achievements for select
  using (auth.uid() = user_id);

create policy "user_achievements_insert_own" on user_achievements for insert
  with check (auth.uid() = user_id);

-- Tracks distinct exercise names whose cue cards the user has expanded in
-- the standalone Exercise Glossary (see renderExerciseGlossary() /
-- data-glossary-toggle in index.html) — the input to the one Learning-
-- category achievement ("engaging with a set number of science explainer
-- cards"). A plain array on profiles rather than a join table since it's
-- just a dedup set with no per-view metadata worth keeping.
alter table profiles add column if not exists glossary_exercises_viewed text[] not null default '{}';
