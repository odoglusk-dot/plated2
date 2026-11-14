-- Krafft training redesign: Phase 5e (Reschedule, this-week-only)
-- One small additive column, nullable, defaulting to an empty object.
-- Holds this week's "move to tomorrow / shorten / skip" overrides —
-- never mutates active_training_block or any plan/program data, and is
-- pruned back to empty by the client once a stored date falls outside
-- the current week (see pruneScheduleOverrides() in index.html).
-- Safe to run twice.

alter table profiles add column if not exists schedule_overrides_this_week jsonb not null default '{}'::jsonb;
