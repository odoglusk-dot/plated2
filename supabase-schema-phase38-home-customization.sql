-- Krafft — Phase 38: Pro-only Home screen personalization.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.

-- home_background_path points into the new home-backgrounds storage
-- bucket below (same private/folder-per-user pattern as progress-photos
-- and food-photos); null means "use the default hero background."
alter table profiles add column if not exists home_background_path text;

-- A permutation of DEFAULT_HOME_WIDGET_ORDER's keys (index.html); null or
-- missing keys fall back to default placement, so this never needs a
-- migration when a new widget is added later.
alter table profiles add column if not exists home_widget_order text[];

-- One background per user at a time: a new upload replaces the old
-- object client-side (delete-then-insert), and home_background_path
-- tracks the current path.
insert into storage.buckets (id, name, public)
values ('home-backgrounds', 'home-backgrounds', false)
on conflict (id) do nothing;

create policy "home_backgrounds_select_own" on storage.objects for select
  using (bucket_id = 'home-backgrounds' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "home_backgrounds_insert_own" on storage.objects for insert
  with check (bucket_id = 'home-backgrounds' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "home_backgrounds_delete_own" on storage.objects for delete
  using (bucket_id = 'home-backgrounds' and auth.uid()::text = (storage.foldername(name))[1]);
