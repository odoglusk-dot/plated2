-- Plated (Kraft) — Phase 10: persist food-log photos.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Previously, a photo used to AI-estimate a meal's macros was only ever
-- sent to the estimation function and discarded — food_logs had no image
-- column, so the collapsible daily log's photo-thumbnail support
-- (historyMealRowHtml) had nothing to show. This adds a private
-- food-photos bucket (same pattern as progress-photos: folder-scoped to
-- auth.uid(), signed URLs generated client-side, never a public link) and
-- the column that tracks each upload's path.

alter table food_logs add column if not exists photo_path text;

insert into storage.buckets (id, name, public)
values ('food-photos', 'food-photos', false)
on conflict (id) do nothing;

create policy "food_photos_select_own" on storage.objects for select
  using (bucket_id = 'food-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "food_photos_insert_own" on storage.objects for insert
  with check (bucket_id = 'food-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "food_photos_delete_own" on storage.objects for delete
  using (bucket_id = 'food-photos' and auth.uid()::text = (storage.foldername(name))[1]);
