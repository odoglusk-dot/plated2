-- Krafft — Phase 35 (dashboard config, AI quota control, ad planning)
-- migration. Run this once in the Supabase SQL Editor against the
-- existing live database. Fresh installs get this automatically from
-- reset-schema.sql instead.
--
-- Three additions for the founder dashboard, all following the
-- zero-RLS-policy pattern from phase32/33/34: unreachable through the
-- public API in either direction — only server-side code with the
-- service role key (Krafft's own Netlify functions, and the dashboard's)
-- can read or write them.

-- Generic small key/value config store — the first (and for now only)
-- use is 'ai_daily_limit', read by Krafft's own checkAndIncrementRateLimit()
-- in netlify/functions/_shared.js instead of the old hardcoded constant,
-- and writable from the dashboard's Quotas tab. A jsonb value (not a
-- plain column) so future config entries don't each need their own
-- migration.
create table if not exists public.dashboard_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.dashboard_config enable row level security;

insert into public.dashboard_config (key, value)
values ('ai_daily_limit', '{"limit": 13}'::jsonb)
on conflict (key) do nothing;

-- Advertising planning: one row per campaign/channel effort. Manual
-- tracking, not a live ad-platform integration — spend/impressions/clicks
-- are logged by hand in dashboard_ad_spend_entries below, this table is
-- just the plan (what it's called, which channel, what it's budgeted for).
create table if not exists public.dashboard_ad_campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  channel text not null check (channel in ('instagram', 'tiktok', 'referral', 'google', 'other')),
  status text not null default 'planned' check (status in ('planned', 'active', 'paused', 'completed')),
  start_date date,
  end_date date,
  monthly_budget_usd numeric,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.dashboard_ad_campaigns enable row level security;

-- Append-only log of actual spend against a campaign — one row per entry
-- (e.g. "this week's TikTok spend"), not an aggregate you overwrite, so
-- the history of how spend accumulated over a campaign's life is never
-- lost. Spent-vs-budget is computed by summing these, not stored.
create table if not exists public.dashboard_ad_spend_entries (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.dashboard_ad_campaigns (id) on delete cascade,
  entry_date date not null default current_date,
  amount_usd numeric not null,
  impressions integer not null default 0,
  clicks integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists dashboard_ad_spend_entries_campaign_idx on public.dashboard_ad_spend_entries (campaign_id);

alter table public.dashboard_ad_spend_entries enable row level security;
