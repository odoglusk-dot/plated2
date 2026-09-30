-- Plated (Kraft) — Phase 26: Group Mode (shared streak + freeze pool).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Groups of up to 10 friends (built on the existing friendships table,
-- not a new social graph) share a daily streak that increments only when
-- every member hits their own individual protein-goal streak that day
-- (the same definition computeStreaks() already uses in index.html —
-- daily food_logs protein sum >= goals.protein_g), protected by a
-- collective streak-freeze pool the group earns together. One active
-- group per user, same lightweight philosophy as training_splits/plans.
--
-- Cross-user reads (every member's own goal-hit status, another user's
-- friendship/achievement rows) never go through client-facing RLS —
-- exactly like the existing Friends Leaderboard, they only ever happen
-- inside a service-role Netlify function (create-group.js,
-- invite-to-group.js, get-group.js, and the scheduled evaluate-groups.js).
-- Group size cap (10) and "one active group per user" are enforced in
-- those functions' application code, not a DB trigger — matching how
-- this app already enforces limits like BLOCK_MAX_PRIORITIES in JS.

-- No client insert/update policy — a group and its creator's own
-- membership row are created together, atomically, by create-group.js.
-- Select-only, scoped to members via group_members.
create table if not exists groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  creator_id uuid not null references auth.users(id) on delete cascade,
  current_streak int not null default 0,
  best_streak int not null default 0,
  freezes_available int not null default 0,
  last_evaluated_date date,
  last_achievement_check_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table groups enable row level security;

-- Many-rows-per-user shape, modeled on user_achievements — not
-- friendships' directional-pair shape, and not training_splits'/plans'
-- one-row-per-user shape. `status` mirrors friendships' pending/accepted
-- pattern: 'invited' -> 'joined', flipped by the invitee themselves
-- (client-direct update, same as accepting a friend request), not by the
-- inviter. Invite creation is service-role only (invite-to-group.js),
-- since it requires a cross-user friendship check the client can't do.
create table if not exists group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'invited' check (status in ('invited', 'joined')),
  invited_at timestamptz not null default now(),
  joined_at timestamptz,
  unique (group_id, user_id)
);

alter table group_members enable row level security;

-- groups' own select policy depends on group_members existing, so it's
-- created here rather than right after `groups` above.
create policy "groups_select_member" on groups for select
  using (id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

create policy "group_members_select_fellow_members" on group_members for select
  using (user_id = auth.uid() or group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

create policy "group_members_update_own" on group_members for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "group_members_delete_own" on group_members for delete
  using (user_id = auth.uid());

-- Earn/spend ledger for the shared freeze pool. member_id is set only for
-- a positive achievement-earned callout (naming who earned the bonus is
-- a compliment, not blame); deliberately left null for 'spent' and
-- 'milestone_earned' so the log never singles out who missed a day —
-- the group sees "a freeze protected the streak today," nothing more.
create table if not exists group_freeze_log (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  kind text not null check (kind in ('milestone_earned', 'achievement_earned', 'spent')),
  member_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists group_freeze_log_group_idx on group_freeze_log (group_id, created_at desc);

alter table group_freeze_log enable row level security;

create policy "group_freeze_log_select_member" on group_freeze_log for select
  using (group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

-- No client insert/update/delete — only the scheduled evaluate-groups.js
-- (service role) ever writes here.

-- Separate from the streak mechanic, per product spec. Progress toward a
-- group goal is computed live from lifts each time the group is fetched
-- (same "never store a derived stat" pattern as every other progress bar
-- in this app — e.g. Training Block's Week X/4), not stored on this row.
create table if not exists group_goals (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  description text not null,
  target_type text not null check (target_type in ('total_sessions')),
  target_value numeric not null,
  period_start date not null,
  period_end date not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table group_goals enable row level security;

create policy "group_goals_select_member" on group_goals for select
  using (group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

create policy "group_goals_insert_member" on group_goals for insert
  with check (created_by = auth.uid() and group_id in (select group_id from group_members where user_id = auth.uid() and status = 'joined'));

-- profiles gains 3 notification toggles, same _opt_out / default-false
-- polarity as email_reminders_opt_out (opted in by default — a brand new
-- feature, so there's no "existing user" behavior to preserve, but
-- matching the established polarity keeps every boolean pref in this app
-- reading the same way: unchecked box -> true stored value).
alter table profiles add column if not exists group_streak_emails_opt_out boolean not null default false;
alter table profiles add column if not exists group_freeze_emails_opt_out boolean not null default false;
alter table profiles add column if not exists group_goal_emails_opt_out boolean not null default false;
