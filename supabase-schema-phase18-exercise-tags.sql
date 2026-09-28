-- Krafft — Phase 18: exercise tags (movement type, lengthened-bias,
-- avoid-flags, block-type suitability) + muscle-map key mapping + empty
-- visual-asset columns.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead.
--
-- muscle_map_key/muscle_map_secondary_keys use a more granular 14-key
-- taxonomy than the existing body_region column (splits "shoulders" into
-- delts, splits "back" into lats/traps/lowerback, adds obliques) to match
-- the Option B muscle map rebuild and the weekly-sets-per-muscle feature.
-- body_region is left as-is for existing features (the simple muscle map,
-- DEFAULT_BODY_REGION fallback) that already depend on its coarser values.
-- Every one of the 75 exercises mapped cleanly onto the 14 keys — no
-- unmappable cases — though a handful were judgment calls worth knowing
-- about: Deadlift/Clean/Power Clean/Clean and Jerk/Snatch are keyed to
-- lowerback (not glutes/hamstrings) as their single primary muscle-map
-- key, matching their existing body_region='back'; Farmer's Carry is keyed
-- to forearms (grip-dominant) rather than a back/core key.
--
-- avoid_flags values in use: 'overhead', 'heavy_spinal_load'. The third
-- documented flag, 'impact', has no matching exercises yet — nothing in
-- this library is a jumping/plyometric movement, so it's reserved for a
-- later phase rather than force-fit onto anything here.
--
-- block_types values in use: 'strength' (compound barbell/bodyweight
-- lifts suitable as a Strength-block main lift), 'hypertrophy' (nearly
-- everything — this library was built hypertrophy-first), 'power_speed'
-- (the Olympic-lift-family movements). 'mobility' and 'functional_athletic'
-- are declared but unused for the same reason as 'impact' above — that
-- content doesn't exist in the library yet (see the Block Builder's
-- Phase 1/Phase 2 split).
--
-- image_url/video_url are empty for now — added so a future visual-assets
-- pass doesn't need another full table restructure.

alter table exercises add column if not exists movement_type text;
alter table exercises add column if not exists lengthened_bias boolean not null default false;
alter table exercises add column if not exists avoid_flags text[] not null default '{}';
alter table exercises add column if not exists block_types text[] not null default '{}';
alter table exercises add column if not exists muscle_map_key text;
alter table exercises add column if not exists muscle_map_secondary_keys text[] not null default '{}';
alter table exercises add column if not exists image_url text;
alter table exercises add column if not exists video_url text;

-- Targeted per-exercise updates (no truncate/reinsert needed here — this
-- phase only adds new tag data onto rows phase17 already seeded).

update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,delts}' where name = 'Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts,triceps}' where name = 'Incline Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps}' where name = 'Decline Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,delts}' where name = 'Dumbbell Bench Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts,triceps}' where name = 'Incline Dumbbell Press';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts}' where name = 'Dumbbell Fly';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts}' where name = 'Cable Fly';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{delts}' where name = 'Pec Deck';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,abs}' where name = 'Push-Up';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'chest', muscle_map_secondary_keys = '{triceps,delts}' where name = 'Dip (Chest-Focused)';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{hamstrings,glutes}' where name = 'Deadlift';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{heavy_spinal_load}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{glutes,lowerback}' where name = 'Romanian Deadlift';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Barbell Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Pendlay Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Dumbbell Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'T-Bar Row';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Seated Cable Row';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps}' where name = 'Lat Pulldown';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps,forearms}' where name = 'Pull-Up';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{biceps}' where name = 'Chin-Up';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'lats', muscle_map_secondary_keys = '{abs}' where name = 'Straight-Arm Pulldown';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{traps}' where name = 'Face Pull';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead,heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{triceps,abs}' where name = 'Overhead Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{triceps}' where name = 'Seated Dumbbell Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{triceps}' where name = 'Arnold Press';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{}' where name = 'Lateral Raise';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{}' where name = 'Front Raise';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{traps}' where name = 'Rear Delt Fly';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{}' where name = 'Cable Lateral Raise';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'delts', muscle_map_secondary_keys = '{traps}' where name = 'Upright Row';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'traps', muscle_map_secondary_keys = '{forearms}' where name = 'Shrug';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes,hamstrings}' where name = 'Back Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{abs,glutes}' where name = 'Front Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Goblet Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes,hamstrings}' where name = 'Leg Press';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Bulgarian Split Squat';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes,hamstrings}' where name = 'Walking Lunge';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Reverse Lunge';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{}' where name = 'Leg Extension';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'glutes', muscle_map_secondary_keys = '{hamstrings}' where name = 'Hip Thrust';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{glutes}' where name = 'Step-Up';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{heavy_spinal_load}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{glutes,lowerback}' where name = 'Stiff-Leg Deadlift';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{}' where name = 'Leg Curl';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{heavy_spinal_load}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{glutes,lowerback}' where name = 'Good Morning';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'hamstrings', muscle_map_secondary_keys = '{}' where name = 'Nordic Curl';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'glutes', muscle_map_secondary_keys = '{hamstrings}' where name = 'Glute Bridge';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'calves', muscle_map_secondary_keys = '{}' where name = 'Standing Calf Raise';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'calves', muscle_map_secondary_keys = '{}' where name = 'Seated Calf Raise';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'calves', muscle_map_secondary_keys = '{}' where name = 'Leg Press Calf Raise';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Barbell Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Dumbbell Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Hammer Curl';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Preacher Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Cable Curl';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{forearms}' where name = 'Incline Dumbbell Curl';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'biceps', muscle_map_secondary_keys = '{}' where name = 'Concentration Curl';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{strength,hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{chest}' where name = 'Close-Grip Bench Press';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Tricep Pushdown';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Overhead Tricep Extension';
update exercises set movement_type = 'isolation', lengthened_bias = true, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Skull Crusher';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{chest}' where name = 'Dip (Tricep-Focused)';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'triceps', muscle_map_secondary_keys = '{}' where name = 'Kickback';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{}' where name = 'Plank';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{forearms}' where name = 'Hanging Leg Raise';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{}' where name = 'Cable Crunch';
update exercises set movement_type = 'compound', lengthened_bias = true, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{delts}' where name = 'Ab Wheel Rollout';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'obliques', muscle_map_secondary_keys = '{}' where name = 'Russian Twist';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'abs', muscle_map_secondary_keys = '{}' where name = 'Weighted Sit-Up';
update exercises set movement_type = 'isolation', lengthened_bias = false, avoid_flags = '{}', block_types = '{hypertrophy}', muscle_map_key = 'obliques', muscle_map_secondary_keys = '{}' where name = 'Pallof Press';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{quads,delts}' where name = 'Clean';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{quads,delts}' where name = 'Power Clean';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead,heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{quads,delts}' where name = 'Clean and Jerk';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead,heavy_spinal_load}', block_types = '{power_speed}', muscle_map_key = 'lowerback', muscle_map_secondary_keys = '{delts,quads}' where name = 'Snatch';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{heavy_spinal_load}', block_types = '{strength,hypertrophy}', muscle_map_key = 'forearms', muscle_map_secondary_keys = '{lowerback,abs}' where name = 'Farmer''s Carry';
update exercises set movement_type = 'compound', lengthened_bias = false, avoid_flags = '{overhead}', block_types = '{hypertrophy}', muscle_map_key = 'quads', muscle_map_secondary_keys = '{delts}' where name = 'Thruster';
