-- Plated — Phase 4 (Customer Portal / cancellation) migration.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Only adds a column — doesn't touch or drop anything else, so
-- it's safe to run without resetting. Fresh installs get this
-- automatically from reset-schema.sql instead.

alter table subscriptions add column if not exists cancel_at_period_end boolean not null default false;
