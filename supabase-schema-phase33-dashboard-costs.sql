-- Krafft — Phase 33 (dashboard manual cost tracking) migration. Run this
-- once in the Supabase SQL Editor against the existing live database.
-- Fresh installs get this automatically from reset-schema.sql instead.
--
-- Two small tables for the founder dashboard's cost/margin section, both
-- following the admin_users pattern from phase32: zero RLS policies for
-- authenticated/anon, so they're unreachable through the public API in
-- either direction — only the dashboard's Netlify functions (service role
-- key, itself gated behind requireAdmin()) can read or write them.

create table if not exists public.dashboard_infra_costs (
  month date primary key, -- first day of the month, e.g. 2026-10-01
  amount_usd numeric not null,
  note text,
  updated_at timestamptz not null default now()
);

alter table public.dashboard_infra_costs enable row level security;

create table if not exists public.dashboard_one_time_costs (
  id uuid primary key default gen_random_uuid(),
  incurred_on date not null,
  description text not null,
  amount_usd numeric not null,
  created_at timestamptz not null default now()
);

alter table public.dashboard_one_time_costs enable row level security;
