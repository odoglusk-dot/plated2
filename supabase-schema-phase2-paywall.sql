-- Plated — Phase 2 (paywall) schema. NOT part of the initial merge/deploy —
-- run this only when building the Stripe subscription gating described in
-- plated/README.md's "Phase 2: Paywall" section.

create table subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'free', -- 'free' | 'active' | 'canceled' | 'past_due'
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
