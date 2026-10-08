-- Krafft — Phase 40: App Store readiness batch (code side).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- NOTE: the task that requested this asked for the filename
-- "supabase-schema-phase37-app-store-readiness.sql" — phase37 is already
-- taken by supabase-schema-phase37-exercise-library-v2.sql (shipped
-- earlier), so this is phase40, the next free number after phase39's
-- customize-screen batch. Flagging the substitution rather than silently
-- renaming or overwriting an existing migration.

-- ── AI data-use consent (item 4) ────────────────────────────────────────
-- Null = AI features are off (never consented, or consent withdrawn from
-- Profile). Gates every AI Netlify function server-side (see
-- hasAiConsent() in _shared.js), not just the client-side popup.
alter table profiles add column if not exists ai_consent_at timestamptz;

-- ── External purchase log (item 7) ──────────────────────────────────────
-- One row per successful Stripe Checkout session that originated from the
-- iOS app (platform='ios' in the session's metadata — see
-- create-checkout-session.js and stripe-webhook.js's
-- checkout.session.completed handler). Apple's external-purchase-link
-- entitlement (US) requires reporting these on a schedule; this table is
-- the source list, surfaced read-only in Krafft HQ (admin.html) via
-- admin-unreported-purchases.js. reported_to_apple/reported_at are only
-- ever set by hand once you've actually filed the report — there's no
-- "mark as reported" button in this batch, by design (the task asked for
-- a read-only list).
create table if not exists external_purchase_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  stripe_session_id text not null unique,
  stripe_subscription_id text,
  amount_cents int,
  currency text,
  platform text not null default 'ios',
  created_at timestamptz not null default now(),
  reported_to_apple boolean not null default false,
  reported_at timestamptz
);

create index if not exists idx_external_purchase_log_unreported on external_purchase_log (reported_to_apple) where reported_to_apple = false;

-- Admin-only: RLS enabled with NO policies for anon/authenticated, same
-- pattern as cancellation_flow_events' missing select policy — this table
-- is written by stripe-webhook.js and read by admin-unreported-purchases.js,
-- both via the service-role key, which bypasses RLS entirely. No regular
-- user, including the row's own user_id, can read or write this table
-- through the normal client.
alter table external_purchase_log enable row level security;
