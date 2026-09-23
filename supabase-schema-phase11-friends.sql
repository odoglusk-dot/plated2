-- Krafft — Phase 11: friend-based leaderboard.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- No `tier` column here on purpose — the free/paid split introduced this
-- phase is derived from the existing `subscriptions.status` (trialing/active
-- = paid, everything else = free), the same field the app already tracks
-- for billing. A separate tier flag would just be a second copy of that
-- same fact, with its own chance to drift out of sync with what Stripe
-- actually says; the Stripe webhook already keeps `subscriptions` current,
-- so nothing new needs to write to a `tier` field.
--
-- Request/accept model, not an instant mutual-add: friendship rows start
-- 'pending' from whoever sent the request and flip to 'accepted' only by the
-- addressee. A friend is added by their existing referral_code (profiles
-- already has this, unique per user) rather than inventing a second code —
-- one less thing to generate, display, and copy/paste.
--
-- The leaderboard itself (streak/exercises-tracked/career-volume per friend)
-- is computed server-side in get-leaderboard.js using the service-role key,
-- specifically so friends' raw lifts/food_logs rows never need their own
-- cross-user RLS policy — only the three aggregate numbers are ever
-- returned, nothing else about a friend's logged data is exposed.

create table friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friendships_no_self_friend check (requester_id <> addressee_id),
  constraint friendships_unique_pair unique (requester_id, addressee_id)
);

alter table friendships enable row level security;

create policy "friendships_select_own" on friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- Inserts still go through add-friend.js (service role) rather than a
-- direct client insert policy — the same reason redeem-referral.js doesn't
-- let the client insert into referrals directly: looking up the other
-- user's id from their referral_code requires reading across users, which
-- RLS on profiles doesn't (and shouldn't) allow the client to do itself.

create policy "friendships_update_as_addressee" on friendships for update
  using (auth.uid() = addressee_id) with check (auth.uid() = addressee_id);

create policy "friendships_delete_own" on friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);
