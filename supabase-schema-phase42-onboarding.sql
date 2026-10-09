-- Krafft — Phase 42: first-run onboarding flow (Part B).
-- The user asked for this file as "phase38", but phase38
-- (goal-nudges) and phase39 (customize-screen-layout) are already taken —
-- next free number is 42, flagged here per the established precedent (see
-- supabase-schema-phase40-app-store-readiness.sql's own header).
--
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.

-- ── Onboarding progress/gating ──────────────────────────────────────────
-- onboarding_completed_at: null means "show the first-run flow"; set once
-- the user reaches the real Today screen (end of Screen 5 / start of
-- Screen 6 in the flow spec) — see showOnboarding()/finishFirstRunFlow()
-- in index.html. Superseded by, but does not replace, the older
-- onboarded_at column (supabase-schema-phase12-onboarding.sql) — that
-- column stays in place unused rather than being dropped, consistent with
-- every other migration in this app being additive-only.
alter table profiles add column if not exists onboarding_completed_at timestamptz;

-- onboarding_step: which of the new flow's screens to resume at (1=Goal,
-- 2=Body weight, 3=Plan, 4=First log) if the user quits mid-flow. New
-- signups default to 1 (Screen 1/Welcome itself is the pre-existing auth
-- screen and isn't tracked here — there's no profile row yet at that
-- point). Irrelevant once onboarding_completed_at is set.
alter table profiles add column if not exists onboarding_step int not null default 1;

-- trial_offer_seen_at: Screen 7 (trial offer) shows at most once ever,
-- right after the payoff screen or on the user's next app open if they
-- skipped logging — see the trial-offer check in enterApp().
alter table profiles add column if not exists trial_offer_seen_at timestamptz;

-- payoff_coachmark_dismissed_at: one extra column beyond the three the
-- request named, flagged here rather than silently added. The flow spec
-- requires the Screen 6 coach mark ("Tap + to log anything else") to
-- "dismiss on tap and never return" — that has to survive app relaunch
-- and a different device on the same account, which rules out
-- localStorage (this app's usual "seen once" mechanism for things that
-- only need to not reappear on this one device/browser — see
-- krafft_last_log_tile). A real "never returns" guarantee needs a
-- server-persisted flag, the same reasoning already used for
-- streak_upgrade_prompt_shown_at (supabase-schema-phase34).
alter table profiles add column if not exists payoff_coachmark_dismissed_at timestamptz;

-- No new column for Screen 2's "target weight" — goals.goal_weight_lb
-- already serves this exact purpose (supabase-schema-phase31-goal-weight.sql),
-- reused as-is by the new flow and by the existing Goal Calculator /
-- Weight tab "X lb to go" indicator.

-- ── Backfill: nobody already using the app should see the new flow ──────
-- payoff_coachmark_dismissed_at is backfilled in the same statement —
-- renderDashboard() shows the coach mark to anyone with
-- onboarding_completed_at set and this still null, which would otherwise
-- mean every existing user sees it forever (they've obviously already seen
-- Today many times).
update profiles set onboarding_completed_at = now(), payoff_coachmark_dismissed_at = now()
  where onboarding_completed_at is null;
