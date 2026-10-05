-- Krafft — Phase 36: AI cost efficiency batch. Run this once in the
-- Supabase SQL Editor against the existing live database. Fresh installs
-- get it automatically from reset-schema.sql instead.

-- ── Item 5: per-feature daily usage caps ─────────────────────────────────
-- ai_usage already tracks one shared daily `count` (used by Describe It's
-- existing 13/day cap, unchanged by this batch) plus token/cost totals.
-- Photo logging, post-session analysis, and Ask AI now get their own
-- independent daily counters instead of sharing that pool — see
-- checkAndIncrementFeatureLimit() in _shared.js.
alter table ai_usage add column if not exists photo_count int not null default 0;
alter table ai_usage add column if not exists analysis_count int not null default 0;
alter table ai_usage add column if not exists ask_count int not null default 0;

-- ── Items 3+4: nightly rule-based training insights ──────────────────────
-- One row per user, overwritten nightly by the new compute-training-
-- insights.js scheduled function (service-role key, same cron precedent as
-- evaluate-groups.js). `insights` holds all 5 computed flags as one jsonb
-- blob — read-only from the client, never written by it, so there's no
-- insert/update policy for the client at all (same reasoning as the
-- read-only tables elsewhere in this app, e.g. referrals).
create table if not exists training_insights (
  user_id uuid primary key references auth.users(id) on delete cascade,
  computed_at timestamptz not null default now(),
  insights jsonb not null default '{}'::jsonb
);

alter table training_insights enable row level security;

create policy "training_insights: select own" on training_insights
  for select using (auth.uid() = user_id);
