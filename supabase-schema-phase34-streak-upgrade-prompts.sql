-- Krafft — Phase 34: one-time streak-based upgrade prompts for free users.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Two independent, server-persisted "shown once" flags — the existing
-- dismissedTipIds (client-only, resets on reload) isn't sufficient here
-- since both prompts must fire exactly once ever, across sessions/devices.
--
-- streak_upgrade_prompt_shown_at: set the first time a free user's logging
-- streak reaches 7 days and sees the "Pro users get AI insight into
-- patterns like this" banner. Null means "eligible to see it."
alter table profiles add column if not exists streak_upgrade_prompt_shown_at timestamptz;

-- pro_preview_used_at: set the first (and only) time a free user redeems
-- the one-time real AI photo-log preview offered at a 10-day streak. Null
-- means "eligible." This has to be server-checked at the point the preview
-- request is made (not just client-gated), since the whole point is that
-- it can only ever be used once per account.
alter table profiles add column if not exists pro_preview_used_at timestamptz;
