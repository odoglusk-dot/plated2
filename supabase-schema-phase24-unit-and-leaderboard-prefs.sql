-- Krafft — Phase 24: weight unit preference + friend-leaderboard opt-in.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- weight_unit is a display-only preference — every table keeps storing
-- weight exactly as it always has (lifts.weight and
-- exercise_goals.target_weight in lb, weight_log.weight_lb in lb,
-- body_stats.weight_kg in kg). The client converts for display/input only;
-- this column never changes what's actually stored.
--
-- leaderboard_opt_in defaults to true (not false) because the friend
-- leaderboard already shows a user's stats to their friends today with no
-- toggle at all — defaulting it off would silently hide existing users
-- from a leaderboard they can already see themselves on.

alter table profiles add column if not exists weight_unit text not null default 'lb' check (weight_unit in ('lb', 'kg'));
alter table profiles add column if not exists leaderboard_opt_in boolean not null default true;
