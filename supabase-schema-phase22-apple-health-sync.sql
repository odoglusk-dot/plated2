-- Krafft — Phase 22: Apple Health sync (beta, iOS Shortcut -> webhook).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Route chosen (see the product decision this implements): an iOS
-- Shortcut posts to a webhook Netlify function, authenticated by a
-- per-user token rather than a Supabase session — HealthKit is only
-- reachable from a Shortcut/native context, which can't hold a normal
-- Supabase login session. A native app with the HealthKit SDK
-- (Capacitor) is the possible later upgrade; this is the free, no-App-
-- Store-required version.
--
-- Security shape, per the explicit requirements this was approved under:
--  - Only a SHA-256 hash of the token is ever stored — health_sync_tokens
--    has no plaintext column. The raw token is generated and returned
--    exactly once, by health-sync-token.js, at creation time.
--  - The webhook (health-sync.js) authenticates by token hash, not a
--    Supabase JWT — it uses the service-role key server-side to resolve
--    the token to a user_id and to write that user's rows. No admin
--    credential is ever sent to or stored in the Shortcut itself; the
--    Shortcut only ever holds the one per-user sync token.
--  - No insert/update/delete RLS policy on health_sync_tokens for the
--    client — token issuance and revocation go through
--    health-sync-token.js (which the client calls with its normal
--    Supabase session), never a direct client write. This keeps the
--    hashing logic authoritative server-side; a client can't inject an
--    unhashed or attacker-chosen hash value.
--  - sleep_log/steps_log have no client insert policy either, since the
--    only writer today is the health-sync webhook — there's no manual
--    logging UI for either metric yet.

create table health_sync_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  token_hash text not null unique,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);

alter table health_sync_tokens enable row level security;

create policy "health_sync_tokens: select own" on health_sync_tokens
  for select using (auth.uid() = user_id);

-- ── sleep_log ──────────────────────────────────────────────────────────
-- One row per day, upserted by the health-sync webhook on
-- (user_id, logged_date) — that's what makes a Shortcut run twice for the
-- same day idempotent rather than creating duplicates.
create table sleep_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_date date not null,
  hours numeric not null,
  source text not null default 'healthkit_shortcut',
  created_at timestamptz not null default now(),
  unique (user_id, logged_date)
);

alter table sleep_log enable row level security;

create policy "sleep_log: select own" on sleep_log
  for select using (auth.uid() = user_id);

-- ── steps_log ──────────────────────────────────────────────────────────
create table steps_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_date date not null,
  steps integer not null,
  source text not null default 'healthkit_shortcut',
  created_at timestamptz not null default now(),
  unique (user_id, logged_date)
);

alter table steps_log enable row level security;

create policy "steps_log: select own" on steps_log
  for select using (auth.uid() = user_id);

-- ── weight_log: tag health-synced rows, keep manual multi-entry intact ──
-- Manual logging still allows multiple weigh-ins a day (no constraint
-- change for source='manual'); the partial unique index only applies to
-- health-synced rows, so THOSE are idempotent per day without touching
-- existing manual-entry behavior at all.
alter table weight_log add column if not exists source text not null default 'manual';
create unique index if not exists weight_log_healthsync_unique
  on weight_log (user_id, logged_date) where source = 'healthkit_shortcut';
