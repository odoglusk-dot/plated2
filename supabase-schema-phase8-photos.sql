-- Plated — Phase 8 (IronLog merge, Photos tab) migration.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- Ported as-is from IronLog's own supabase/schema.sql. The
-- progress-photos Storage bucket + its policies already exist from
-- supabase-schema-phase7-ironlog.sql — this just adds the table that
-- tracks each upload's storage path.

create table if not exists photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  note text,
  date date not null,
  created_at timestamptz not null default now()
);

create index if not exists photos_user_date_idx on photos (user_id, date);

alter table photos enable row level security;

create policy "photos_select_own" on photos for select using (auth.uid() = user_id);
create policy "photos_insert_own" on photos for insert with check (auth.uid() = user_id);
create policy "photos_update_own" on photos for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "photos_delete_own" on photos for delete using (auth.uid() = user_id);
