-- Krafft — Phase 39: Customizable Screen Layout (Pro feature).
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- This REPLACES the simpler phase38 Home-screen-only customization
-- (profiles.home_background_path / home_widget_order, the home-
-- backgrounds storage bucket) with a general system: a draggable/
-- resizable bottom nav, a drag-reorder/resize module grid applied per
-- screen (Home/nutrition_home, Today's Lift, and the top of Profile),
-- and one global background photo + blur setting.
--
-- phase38's two profiles columns and its home-backgrounds bucket are
-- left in place rather than dropped — the app stops reading/writing
-- them as of this batch, so they're just inert. Drop them yourself later
-- if you want a cleanup pass; not done here since dropping columns/
-- buckets isn't something to do automatically.

-- One row per user: the tab bar is global nav chrome, shared across
-- every screen.
create table if not exists user_navbar_prefs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  size text not null default 'standard' check (size in ('compact', 'standard', 'expanded')),
  position text not null default 'bottom' check (position in ('top', 'center', 'bottom')),
  updated_at timestamptz not null default now()
);

alter table user_navbar_prefs enable row level security;
create policy "user_navbar_prefs_select_own" on user_navbar_prefs for select using (auth.uid() = user_id);
create policy "user_navbar_prefs_upsert_own" on user_navbar_prefs for insert with check (auth.uid() = user_id);
create policy "user_navbar_prefs_update_own" on user_navbar_prefs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "user_navbar_prefs_delete_own" on user_navbar_prefs for delete using (auth.uid() = user_id);

-- One row per user: the background photo + blur amount, app-wide (not
-- per-screen) — see the batch doc's "open question," answered as global
-- for the simpler build. photo_url actually holds a private-bucket
-- storage PATH, not a public URL (same signed-URL-per-load convention as
-- every other photo feature in this app) — named photo_url to match the
-- spec's column name exactly, despite what it actually stores.
create table if not exists user_background_prefs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  photo_url text, -- null = use the default gradient hero
  blur_amount int not null default 22 check (blur_amount between 0 and 36),
  updated_at timestamptz not null default now()
);

alter table user_background_prefs enable row level security;
create policy "user_background_prefs_select_own" on user_background_prefs for select using (auth.uid() = user_id);
create policy "user_background_prefs_upsert_own" on user_background_prefs for insert with check (auth.uid() = user_id);
create policy "user_background_prefs_update_own" on user_background_prefs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "user_background_prefs_delete_own" on user_background_prefs for delete using (auth.uid() = user_id);

-- One row per module per screen per user: layout of the content cards.
-- Absence of rows for a given screen_key means "using the shipped
-- default layout for that screen" — never backfilled for existing users,
-- and what "Reset layout" deletes back down to.
create table if not exists user_screen_modules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  screen_key text not null,       -- 'nutrition_home' | 'today_lift' | 'profile'
  module_key text not null,       -- e.g. 'macros', 'logged_today', 'water', 'streak'
  sort_order int not null,
  span text not null default 'full' check (span in ('half', 'full')),
  height_size text not null default 'standard' check (height_size in ('compact', 'standard', 'expanded')),
  updated_at timestamptz not null default now(),
  unique (user_id, screen_key, module_key)
);

create index if not exists idx_screen_modules_user_screen on user_screen_modules (user_id, screen_key, sort_order);

alter table user_screen_modules enable row level security;
create policy "user_screen_modules_select_own" on user_screen_modules for select using (auth.uid() = user_id);
create policy "user_screen_modules_insert_own" on user_screen_modules for insert with check (auth.uid() = user_id);
create policy "user_screen_modules_update_own" on user_screen_modules for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "user_screen_modules_delete_own" on user_screen_modules for delete using (auth.uid() = user_id);

-- Background photo storage: private, folder-per-user, same pattern as
-- progress-photos/food-photos/home-backgrounds. One background per user
-- at a time — a new upload replaces the old object client-side.
insert into storage.buckets (id, name, public)
values ('background-photos', 'background-photos', false)
on conflict (id) do nothing;

create policy "background_photos_select_own" on storage.objects for select
  using (bucket_id = 'background-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "background_photos_insert_own" on storage.objects for insert
  with check (bucket_id = 'background-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "background_photos_delete_own" on storage.objects for delete
  using (bucket_id = 'background-photos' and auth.uid()::text = (storage.foldername(name))[1]);
