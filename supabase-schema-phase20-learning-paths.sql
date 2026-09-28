-- Krafft — Phase 20: learning paths (mini-courses) completion tracking.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Path *content* (titles, card copy) lives in LEARNING_PATHS in
-- index.html — static, not AI-generated, same pattern as TIP_LIBRARY, the
-- exercises table's cue cards, and ACHIEVEMENT_LIBRARY. This column only
-- records which path ids a given account has finished, mirroring how
-- glossary_exercises_viewed already tracks Exercise Glossary engagement
-- for the Learning achievement category.

alter table profiles add column if not exists learning_paths_completed text[] not null default '{}';
