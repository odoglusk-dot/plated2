-- Krafft — Phase 14: goal-adaptive coaching nudges.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- goals previously had no record of *when* goal_mode last changed, only
-- its current value — so there was no way to tell "just set a bulk goal
-- yesterday" from "has been a bulk goal for six months," which is exactly
-- the distinction a goal-adaptive nudge needs (give logged behavior a few
-- days to catch up to a new goal before nudging about a mismatch). The
-- client only stamps this column when goal_mode actually changes value,
-- not on every goals write — see withGoalModeTracking() in index.html.

alter table goals add column if not exists goal_mode_changed_at timestamptz;
