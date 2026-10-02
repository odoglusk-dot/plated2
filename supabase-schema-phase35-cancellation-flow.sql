-- Krafft — Phase 35: custom in-app cancellation flow (items 9+10 of the
-- conversion-surface-area batch). Run this once in the Supabase SQL Editor
-- against the existing live database. Fresh installs get it automatically
-- from reset-schema.sql instead.
--
-- Cancellation used to happen entirely inside Stripe's hosted Billing
-- Portal — zero Krafft-side code, zero visibility into why anyone left.
-- This table backs a custom in-app flow (optional one-tap reason, then an
-- offer to stay at the current price or pause via Stripe's native
-- pause_collection) and is what the new minimal admin page reads from.
--
-- user_id is "on delete set null" rather than cascade, same reasoning as
-- group_freeze_log.member_id elsewhere in this app — this is a log table,
-- and a row documenting why someone left the product; it should outlive the
-- account itself (anonymized to a null user_id) rather than vanish with it.
create table if not exists cancellation_flow_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  -- One of a fixed set of single-tap reasons (see CANCELLATION_REASONS in
  -- index.html) or null — the prompt is explicitly optional.
  reason text,
  -- What the user actually did after seeing the stay/pause offer.
  outcome text not null check (outcome in ('canceled', 'paused', 'stayed')),
  created_at timestamptz not null default now()
);

alter table cancellation_flow_events enable row level security;

-- Users can log their own cancellation-flow event (the flow calls this with
-- the user's own session, not a service-role key). No select/update/delete
-- policy — nobody needs to read these back from the client; the admin page
-- reads across all users via the service-role key in its own Netlify
-- function, which bypasses RLS entirely, same pattern as get-group.js.
create policy "cancellation_flow_events: insert own" on cancellation_flow_events
  for insert with check (auth.uid() = user_id);
