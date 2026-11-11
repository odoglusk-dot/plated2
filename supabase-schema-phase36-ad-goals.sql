-- Krafft — Phase 36 (advertising goal tracking) migration. Run this once
-- in the Supabase SQL Editor against the existing live database. Fresh
-- installs get this automatically from reset-schema.sql instead.
--
-- Three additive columns on dashboard_ad_campaigns (from phase35) so a
-- campaign can carry a forward-looking target, not just backward-looking
-- spend. goal_progress is manually updated from the dashboard, not
-- computed — there's no automatic way yet to tie a signup/conversion back
-- to the campaign that drove it (that would need UTM capture wired into
-- Krafft's own signup flow, which doesn't exist yet). impressions/clicks
-- goals, by contrast, CAN be computed automatically from the existing
-- dashboard_ad_spend_entries log — the dashboard does that math itself,
-- this column only matters for a goal metric it can't already measure.

alter table public.dashboard_ad_campaigns add column if not exists goal_metric text;
alter table public.dashboard_ad_campaigns add column if not exists goal_target numeric;
alter table public.dashboard_ad_campaigns add column if not exists goal_progress numeric;
