-- Plated — Phase 3 (batch improvements) migration.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Only adds columns/tables — doesn't touch or drop anything
-- else, so it's safe to run without resetting. (Fresh installs get all of
-- this automatically from reset-schema.sql instead.)

-- ── profiles: age gate + referral code + email reminder opt-out ─────────
alter table profiles add column if not exists age_over_18 boolean;
alter table profiles add column if not exists age_gate_shown_at timestamptz;
alter table profiles add column if not exists parental_consent_at timestamptz;
alter table profiles add column if not exists referral_code text unique;
alter table profiles add column if not exists email_reminders_opt_out boolean not null default false;

-- ── goals: which calculator scenario these goals came from ──────────────
alter table goals add column if not exists goal_mode text not null default 'maintain';
alter table goals drop constraint if exists goals_goal_mode_check;
alter table goals add constraint goals_goal_mode_check check (goal_mode in ('lose', 'maintain', 'gain'));

-- ── referrals: one row per successful redemption ─────────────────────────
create table if not exists referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references auth.users(id) on delete cascade,
  referred_user_id uuid not null unique references auth.users(id) on delete cascade,
  referral_code text not null,
  status text not null default 'pending' check (status in ('pending', 'rewarded')),
  created_at timestamptz not null default now(),
  rewarded_at timestamptz
);

alter table referrals enable row level security;

create policy "referrals: select own as referrer" on referrals
  for select using (auth.uid() = referrer_user_id);
-- No insert/update policy for the client — redeem-referral.js and
-- stripe-webhook.js (both using the service-role key) are the only writers.
