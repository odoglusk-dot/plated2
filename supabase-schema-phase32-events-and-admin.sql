-- Krafft — Phase 32 (events log + admin table) migration. Run this once in
-- the Supabase SQL Editor against the existing live database. Fresh
-- installs get this automatically from reset-schema.sql instead.
--
-- Built for the founder-only growth/financial dashboard (the repurposed
-- IronLog site). Two additions:
--
--   1. `events` — an append-only log, one row per user action. Existing
--      tables (profiles, subscriptions) only hold current state, not
--      history, so funnel/DAU-WAU-MAU/cohort-retention questions can't be
--      answered from them — see the "Basic analytics" section of
--      DEPLOYMENT.md, which already flagged this as the next step. This
--      is intentionally generic (event_name + a jsonb properties bag)
--      rather than one column per event type, so adding a new event kind
--      later never needs a schema change.
--
--      RLS allows a logged-in user to insert only their own user_id, or
--      anyone (including the pre-auth anon role) to insert a row with
--      user_id left null — needed for signup_started, which by definition
--      fires before an account exists, so there's no auth.uid() to match
--      against yet. Nobody, including the user who wrote a row, can
--      select/update/delete through the API. Reads only ever happen
--      server-side (the dashboard's Netlify functions) using the service
--      role key, which bypasses RLS entirely — that's a deliberate
--      security boundary, not an oversight: event history must not be
--      tamperable or readable by the client that produced it.
--
--   2. `admin_users` — the founder-only allowlist the dashboard's backend
--      checks server-side before returning anything.
--
--      Deliberately NOT a boolean column on `profiles`: that table's
--      existing "update own" RLS policy (`using (auth.uid() = id)`, no
--      column-level restriction) lets a user PATCH any column on their
--      own row — including a hypothetical is_admin flag, which would be
--      a straight privilege-escalation hole. A separate table with zero
--      policies for the authenticated/anon roles has no such gap: RLS
--      defaults to deny-all, so nobody can read or write it through the
--      public API no matter what they send, full stop. Only server-side
--      code using the service role key (which bypasses RLS) can touch it.

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists events_user_id_idx on public.events (user_id);
create index if not exists events_name_created_at_idx on public.events (event_name, created_at);
create index if not exists events_created_at_idx on public.events (created_at);

alter table public.events enable row level security;

create policy "events: insert own or anonymous" on public.events
  for insert with check (user_id is null or auth.uid() = user_id);
-- deliberately no select/update/delete policy for the authenticated role —
-- see the note above. A null-user_id row can come from anyone (anon
-- role included) but can never be attributed to someone else's account —
-- the worst case is low-value spam rows with no user_id, not a privilege
-- or integrity issue.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.admin_users enable row level security;
-- deliberately zero policies for authenticated/anon — RLS defaults to
-- deny-all, so this table is unreachable through the public API in any
-- direction. Only the service role (used exclusively by the dashboard's
-- Netlify functions) can read or write it.

-- One-time: add the founder's own account to the admin allowlist. Safe to re-run.
insert into public.admin_users (user_id)
select id from auth.users where email = 'odoglusk@gmail.com'
on conflict (user_id) do nothing;
