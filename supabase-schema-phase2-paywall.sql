-- Plated — Phase 2 (paywall) schema.
-- Run this once in the Supabase SQL Editor against the existing live
-- database to add subscription gating — it only adds the `subscriptions`
-- table and does not touch any other table, so it's safe to run without
-- resetting anything. (Fresh installs get this table automatically from
-- reset-schema.sql instead.)

create table if not exists subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'free'
    check (status in ('free', 'trialing', 'active', 'canceled', 'past_due')),
  stripe_customer_id text,
  stripe_subscription_id text,
  current_period_end timestamptz,
  updated_at timestamptz not null default now()
);

alter table subscriptions enable row level security;

create policy "subscriptions: select own" on subscriptions
  for select using (auth.uid() = user_id);
-- No insert/update policy for the client — only the Stripe webhook function
-- (using the Supabase service-role key, which bypasses RLS) should ever
-- write to this table.
