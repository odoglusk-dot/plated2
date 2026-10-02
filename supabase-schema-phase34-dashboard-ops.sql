-- Krafft — Phase 34 (dashboard operational tooling) migration. Run this
-- once in the Supabase SQL Editor against the existing live database.
-- Fresh installs get this automatically from reset-schema.sql instead.
--
-- Three small tables for the founder dashboard, all following the
-- admin_users/dashboard_infra_costs pattern from phase32/33: zero RLS
-- policies for authenticated/anon, so they're unreachable through the
-- public API in either direction — only the dashboard's Netlify functions
-- (service role key, itself gated behind requireAdmin()) can read or
-- write them. Plus two columns on `subscriptions` so a manually-granted
-- comp (e.g. a trainer partnership) is distinguishable from a real
-- Stripe-paying subscriber in the dashboard's own revenue reporting.

create table if not exists public.dashboard_changelog (
  id uuid primary key default gen_random_uuid(),
  entry_date date not null default current_date,
  description text not null,
  created_at timestamptz not null default now()
);

alter table public.dashboard_changelog enable row level security;

-- Append-only by convention (no delete/update code path is built on top of
-- this) — a simple record of who-did-what-when for the founder's own
-- tracking, and groundwork for if a second admin is ever added.
create table if not exists public.dashboard_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references auth.users (id) on delete set null,
  admin_email text,
  action text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.dashboard_audit_log enable row level security;

create table if not exists public.dashboard_feedback (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz not null default now()
);

alter table public.dashboard_feedback enable row level security;

-- `granted_by`/`granted_at` are set only when the dashboard's tier-grant
-- panel manually flips someone's status (e.g. comping a trainer partner)
-- rather than Stripe's webhook doing it from a real payment. Nullable and
-- additive — the webhook's existing upsert never touches these columns,
-- so real paying subscribers are unaffected.
alter table public.subscriptions add column if not exists granted_by uuid references auth.users (id) on delete set null;
alter table public.subscriptions add column if not exists granted_at timestamptz;
