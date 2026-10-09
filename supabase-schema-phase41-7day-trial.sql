-- Krafft — Phase 41: 7-day free trial batch (code side, Part A).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.

-- ── One trial per person, survives account deletion (item 2) ───────────
-- Keyed by a sha256 hash of the normalized email (see hashEmail() in
-- _shared.js), NOT user_id — deliberately has no foreign key to
-- auth.users, so deleting and recreating an account with the same email
-- still finds this row and gets no second trial. Written once, the first
-- time a subscription for that email actually reaches 'trialing' (see
-- stripe-webhook.js). Service-role only: no RLS policies for anon/
-- authenticated, same pattern as external_purchase_log.
create table if not exists trial_used (
  email_hash text primary key,
  first_used_at timestamptz not null default now()
);
alter table trial_used enable row level security;

-- ── Trial-ending reminder email idempotency (item 4) ────────────────────
-- Set once stripe-webhook.js has sent the customer.subscription.
-- trial_will_end reminder for this subscription, so a Stripe webhook
-- redelivery (or a second trial_will_end firing) can't send it twice.
alter table subscriptions add column if not exists trial_reminder_sent_at timestamptz;

-- ── 'unpaid' is a real Stripe subscription status (item 3) ──────────────
-- Set once an active subscription's payment retries are exhausted.
-- hasAccess() in index.html already excludes it from Pro access (only
-- 'trialing'/'active' grant access) — but without it in this CHECK
-- constraint, stripe-webhook.js's upsert of status='unpaid' was silently
-- rejected by Postgres, leaving the row on its last-good status
-- ('active') and the user with Pro access indefinitely despite failed
-- payment. Drop and recreate the constraint since Postgres has no
-- "alter check" — same end state as reset-schema.sql's version for fresh
-- installs.
alter table subscriptions drop constraint if exists subscriptions_status_check;
alter table subscriptions add constraint subscriptions_status_check
  check (status in ('free', 'trialing', 'active', 'canceled', 'past_due', 'unpaid'));
