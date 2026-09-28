-- Krafft — Phase 21: barcode scanning (free tier, Open Food Facts).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- 'barcode' is a new food_logs.source value, distinct from 'manual' — a
-- scanned-and-confirmed entry isn't AI-derived (so it stays free tier),
-- but it's also not hand-typed, and keeping it distinguishable is worth
-- more than the one extra enum value costs.
--
-- sugar_g is nullable and only ever populated by a barcode lookup today
-- (Open Food Facts is the only source in this app that returns sugar) —
-- no other logging path is being retrofitted to collect it.
--
-- barcode stores the scanned code on the eventual entry even when the
-- lookup fails and the user falls through to Manual Entry, so the code
-- isn't lost — there's no barcode cache table here on purpose: Open Food
-- Facts is free and has no rate limit relevant at this app's scale, so a
-- direct lookup per scan is simpler than maintaining a cache with no
-- real cost problem to solve. Revisit only if that changes.

alter table food_logs drop constraint if exists food_logs_source_check;
alter table food_logs add constraint food_logs_source_check check (
  source in ('manual', 'ai_text', 'ai_photo', 'favorite', 'common', 'barcode')
);
alter table food_logs add column if not exists sugar_g numeric;
alter table food_logs add column if not exists barcode text;
