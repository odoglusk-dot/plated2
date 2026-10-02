-- Krafft — Phase 33: per-ingredient calorie breakdown for AI-estimated
-- food logs. Run this once in the Supabase SQL Editor against the
-- existing live database. Fresh installs get it automatically from
-- reset-schema.sql instead.
--
-- Fills in the "By Ingredient" section of the post-log calorie breakdown
-- popup (shipped earlier as live-but-dormant code, gated on an
-- entry.ingredients array nothing populated yet). Only the AI photo
-- ("Snap a Photo") and AI text ("Describe It") logging paths can
-- meaningfully produce this — manual entry, barcode scans, and Quick Add
-- replays are each a single item with nothing to break down, so they
-- continue to log with ingredients left null, same as before this column
-- existed, and the popup's existing fallback (hide the section when
-- ingredients is empty/absent) handles that correctly already.
--
-- jsonb, not a separate table — this is a snapshot of what the AI
-- estimated for one specific log entry, never queried or joined on, the
-- same reasoning already applied to lifts.muscle_map_keys and
-- active_training_block elsewhere in this app.
--
-- Shape: an array of {"name": string, "calories": number} objects, or
-- null for a non-composite item (see the updated system prompts in
-- estimate-macros.js / estimate-macros-photo.js).
alter table food_logs add column if not exists ingredients jsonb;

-- food_cache stores the same AI response shape it always has (for repeat
-- lookups of the same photo/description to skip another AI call) — this
-- keeps that cache hit path carrying ingredients too, so a cached repeat
-- still gets the full breakdown instead of silently losing it.
alter table food_cache add column if not exists ingredients jsonb;
