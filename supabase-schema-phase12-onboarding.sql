-- Krafft — Phase 12: first-time onboarding flow.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- `onboarded_at` is null for every existing account until this phase ships
-- — that's intentional, not a bug: an existing user opening the app after
-- this update will see the onboarding overlay once, same as a brand new
-- signup. It's a one-time thing per account, not per session, so that's a
-- reasonable trade rather than something worth a backfill migration.

alter table profiles add column if not exists onboarded_at timestamptz;
