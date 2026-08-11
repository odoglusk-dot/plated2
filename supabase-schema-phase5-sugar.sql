-- Plated — Phase 5 (Sugar tracking) migration.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Only adds columns — doesn't touch or drop anything else, so
-- it's safe to run without resetting. Fresh installs get this
-- automatically from reset-schema.sql instead.
--
-- Nullable, no default: existing rows genuinely don't have a sugar value
-- (it was never captured before this), and a default of 0 would falsely
-- assert "0g of sugar" for food logged before this migration. Null means
-- "unknown," which is what it actually is.

alter table food_logs add column if not exists sugar_g numeric;
alter table food_cache add column if not exists sugar_g numeric;
alter table favorites add column if not exists sugar_g numeric;
