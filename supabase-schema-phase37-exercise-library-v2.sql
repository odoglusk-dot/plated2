-- Krafft — Phase 37: exercise library format migration + expansion.
-- Run this once in the Supabase SQL Editor against the existing live
-- database. Fresh installs get it automatically from reset-schema.sql
-- instead. Run top to bottom — the format migration (section 1) is meant
-- to land before the new exercise content below it, per the task spec.

-- ══════════════════════════════════════════════════════════════════════
-- 1. FORMAT MIGRATION
-- ══════════════════════════════════════════════════════════════════════

-- experience_level: beginner/intermediate/advanced — new. Null means "no
-- strong opinion," not "unknown" — plenty of exercises (e.g. most cable
-- isolation work) don't really have a skill floor worth gatekeeping.
alter table exercises add column if not exists experience_level text;

-- category: broad exercise TYPE, new and distinct from every existing tag
-- column — movement_type (compound/isolation/plyometric) describes HOW a
-- lift trains the muscle, block_types describes which Block Builder pools
-- it's suitable for, muscle_group/muscle_map_key describe WHAT it trains.
-- category is the top-level answer to "what kind of exercise is this at
-- all": strength work, explosive/reactive plyometric work, or
-- steady-state/interval conditioning. Nothing before this migration
-- captured that distinction in one place.
alter table exercises add column if not exists category text;

-- Reference guidance for conditioning exercises, parallel to the
-- hypertrophy_* columns strength exercises already have (rep_range /
-- rest_interval / tempo / mind_muscle_cue) — conditioning work doesn't
-- have reps or a lifting tempo, so it gets its own pair of static-text
-- guidance fields instead of forcing data into fields that don't apply.
-- This is reference/glossary content only — see the note in section 3
-- below about where actual conditioning LOGGING happens (CONDITIONING_
-- DRILLS in index.html, via the existing conditioning_log table), which
-- is a separate, already-built mechanism this migration reuses rather
-- than duplicating.
alter table exercises add column if not exists conditioning_duration_guidance text;
alter table exercises add column if not exists conditioning_intensity_guidance text;

-- Backfill category for the 85 exercises that predate this column, using
-- data already on each row — no per-exercise guesswork needed since
-- movement_type already distinguishes plyometric work (phase30) from
-- everything else (the full phase17 library + the Olympic lifts).
update exercises set category = 'plyometric' where movement_type = 'plyometric' and category is null;
update exercises set category = 'strength' where category is null;

-- Backfill experience_level with a reasonable rule-based default, derived
-- from tags that already exist on each row rather than 85 individual
-- judgment calls. This is a starting point, not a final answer — flagged
-- for review, trivial to adjust row by row later since it's a single text
-- column, not a structural change.
--   - power_speed (Olympic lift family): advanced — the most technical
--     movements in the library.
--   - compound + a heavy_spinal_load or overhead avoid_flag: intermediate
--     — these ask for real technique before loading up.
--   - every other compound lift, and all plyometric work: beginner —
--     plyometric entries already carry their own 'impact' avoid_flag as
--     the real gatekeeper; a second, redundant skill gate isn't needed.
--   - isolation work: beginner — technique risk is low by nature of the
--     movement (one joint, fixed path on most of these).
update exercises set experience_level = 'advanced' where 'power_speed' = any(block_types) and experience_level is null;
update exercises set experience_level = 'intermediate' where movement_type = 'compound' and (avoid_flags && array['heavy_spinal_load','overhead']) and experience_level is null;
update exercises set experience_level = 'beginner' where experience_level is null;

-- Tempo/rep-range/rest-interval notation audit: checked all 75 phase17
-- entries for consistency before writing anything here. They're already
-- uniform — hypertrophy_rep_range and hypertrophy_rest_interval always
-- use an en dash ("6–12 reps", "2–3 min"), hypertrophy_tempo is always
-- "{eccentric}-{pause}-{concentric} tempo" with plain hyphens between the
-- three numbers. The only variation is whether a short explanatory clause
-- follows (e.g. "2-1-1 tempo — lower for 2 seconds, brief pause on the
-- chest, drive up" vs. a bare "2-1-1 tempo"), which is an editorial
-- choice, not a format bug — rewriting ~75 rows of working, accurate
-- coaching copy to force one style wasn't done here. Flagged for review:
-- say which way to standardize (always explain, or always bare) if either
-- is wanted, and it's a mechanical find/append pass from here.

-- No muscle-tagging junction table in this migration — muscle_map_key +
-- muscle_map_secondary_keys (array) already provide multi-muscle support
-- and are read by the Block Builder, weekly hard-sets-per-muscle, the
-- muscle map, and the logging form's default-tag lookup. Converting to a
-- real junction table would mean rewriting every one of those call sites
-- for a feature that already works — decided against per explicit review.

-- ══════════════════════════════════════════════════════════════════════
-- 2. NEW EXERCISES — squat/deadlift variations + isolation/accessory
-- ══════════════════════════════════════════════════════════════════════
-- Matching the existing cue/hypertrophy format exactly. The plyometric/
-- speed/agility exercises requested alongside these turned out to already
-- exist — see the note at the end of this file instead of here.
insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake, cue_bracing,
  hypertrophy_rep_range, hypertrophy_rest_interval, hypertrophy_tempo, hypertrophy_mind_muscle_cue,
  movement_type, lengthened_bias, avoid_flags, block_types,
  muscle_map_key, muscle_map_secondary_keys, category, experience_level
) values

('Box Squat', 'Legs', 'quads', '{glutes}', 'Barbell',
 'Set a box or bench at or just below parallel height behind you, then set up under the bar exactly as you would for a back squat.',
 'Squat down under control until you sit lightly on the box, pause briefly without relaxing your hips, then drive back up.',
 'Crashing down onto the box and losing tension, or using it to bounce back up. Touch and go under control — the box marks depth, it''s not a resting point.',
 'Keep full-body tension through the pause on the box — a relaxed brace there is a common way to tweak the lower back.',
 '5–8 reps', '2–3 min', '3-1-1 tempo — slow, controlled descent to the box',
 'Focus on sitting your hips back and down onto the box, not folding forward to reach it.',
 'compound', false, '{heavy_spinal_load}', '{strength,hypertrophy}', 'quads', '{glutes}', 'strength', 'intermediate'),

('Pause Squat', 'Legs', 'quads', '{glutes}', 'Barbell',
 'Set up exactly as you would for a standard back squat.',
 'Squat down to depth, pause motionless for 2–3 seconds at the bottom, then drive up without any bounce out of the hole.',
 'Letting tension bleed out during the pause, or using a quick rebound to escape the bottom. Stay braced and still, then drive up from a dead stop.',
 'Re-confirm your brace the instant you hit the bottom position, before the pause even starts.',
 '4–6 reps', '2–3 min', '2-3-1 tempo — 3-second pause at the bottom',
 'Use the pause to feel your quads and glutes under full load before driving up.',
 'compound', false, '{heavy_spinal_load}', '{strength,hypertrophy}', 'quads', '{glutes}', 'strength', 'intermediate'),

('Sumo Deadlift', 'Pull', 'back', '{quads}', 'Barbell',
 'Stand with a wide stance, toes pointed out, gripping the bar inside your knees.',
 'Drive through the floor with your knees pushing out, extending your hips and knees together to stand the bar up.',
 'Letting your knees cave inward as you pull. Actively push your knees out against the floor throughout the pull.',
 'Brace hard before the pull and keep your chest tall — a wide stance makes it easy to let the torso collapse forward if the brace slips.',
 '5–8 reps', '2–3 min', '1-1-2 tempo — pause at the top',
 'Feel the pull through your inner thighs and glutes more than your lower back.',
 'compound', false, '{heavy_spinal_load}', '{strength,hypertrophy}', 'glutes', '{hamstrings,quads,lowerback}', 'strength', 'intermediate'),

('Deficit Deadlift', 'Pull', 'back', '{hamstrings}', 'Barbell',
 'Stand on a 1–2 inch plate or platform, feet hip-width apart, bar on the floor in front of you.',
 'Deadlift the bar from this slightly lower starting position, keeping the same hip-hinge pattern as a standard deadlift.',
 'Rounding the lower back to reach the extra range. If you can''t keep a neutral spine from the deficit, the deficit is too high — reduce it.',
 'Brace extra hard before the pull — the longer range means more time under load before lockout.',
 '5–8 reps', '2–3 min', '1-1-2 tempo',
 'Focus on holding the same back position you''d use for a normal-height pull, just from lower.',
 'compound', true, '{heavy_spinal_load}', '{hypertrophy}', 'hamstrings', '{glutes,lowerback}', 'strength', 'advanced'),

('Trap Bar Deadlift', 'Pull', 'back', '{quads}', 'Barbell',
 'Stand inside the trap bar, feet hip-width apart, gripping the handles at your sides.',
 'Drive through the floor and extend your hips and knees together to lift the bar, keeping it close to your body throughout.',
 'Squatting it up with an upright torso and letting the hips rise first. Keep the same hip-hinge pattern as a conventional deadlift — hips and shoulders rising together.',
 'Brace before you break the weight off the floor, same as any other deadlift variation.',
 '6–10 reps', '2–3 min', '1-1-2 tempo',
 'A good entry point for deadlift patterning — the neutral grip and higher handle position make it the most back-friendly of the deadlift variations.',
 'compound', false, '{heavy_spinal_load}', '{strength,hypertrophy}', 'hamstrings', '{glutes,quads}', 'strength', 'beginner'),

('Zercher Squat', 'Legs', 'quads', '{abs}', 'Barbell',
 'Cradle the bar in the crooks of your elbows, held tight against your torso, feet shoulder-width apart.',
 'Squat down keeping the bar close to your body and your torso as upright as the hold allows, then drive back up.',
 'Letting the bar drift away from your torso, which pitches you forward and loads the lower back more than the legs. Keep it pulled in tight the whole rep.',
 'Brace your core hard — the front-loaded position demands more trunk stability than a back squat.',
 '6–10 reps', '2 min', '2-1-1 tempo',
 'Focus on staying upright and keeping the bar glued to your chest.',
 'compound', false, '{heavy_spinal_load}', '{hypertrophy}', 'quads', '{abs,glutes}', 'strength', 'advanced'),

('Reverse Pec Deck', 'Pull', 'shoulders', '{back}', 'Machine',
 'Sit facing into the pec deck machine (reversed from the chest-fly setup), chest against the pad, grip the handles in front of you.',
 'With a slight bend in the elbows, pull the handles out and back in an arc until your arms are in line with your torso.',
 'Using momentum to fling the handles back. Keep it slow and controlled — this is a small muscle group that fatigues fast under strict form.',
 'Keep your chest pressed into the pad throughout so the rear delts, not your back, are doing the pulling.',
 '12–20 reps', '60–90 sec', '2-1-2 tempo — full stretch, full contraction',
 'Think about squeezing your shoulder blades together at the back of the movement.',
 'isolation', true, '{}', '{hypertrophy}', 'delts', '{traps}', 'strength', 'beginner'),

('Cable Kickback', 'Legs', 'glutes', '{hamstrings}', 'Cable',
 'Attach an ankle cuff to a low cable pulley, clip it to one ankle, and face the machine holding on for balance.',
 'Keeping a slight bend in your knee, kick your leg straight back and up by squeezing your glute, then return under control.',
 'Arching the lower back to generate extra range. The movement should come from the hip, not from hyperextending the spine.',
 'Brace your core to keep your pelvis stable — a stable base is what isolates the glute instead of the lower back taking over.',
 '12–20 reps', '60–90 sec', '1-2-1 tempo — pause and squeeze at the top',
 'Focus on squeezing the glute hard at the top of each rep, not on how far your leg travels.',
 'isolation', true, '{}', '{hypertrophy}', 'glutes', '{hamstrings}', 'strength', 'beginner'),

('Hip Abduction Machine', 'Legs', 'glutes', '{}', 'Machine',
 'Sit in the machine with the outside of your thighs against the pads, knees together at the start.',
 'Push your knees apart against the pads'' resistance, then return under control to the starting position.',
 'Leaning the torso to one side to generate momentum. Keep your back flat against the pad and let the glutes do the work.',
 'Keep your core braced and torso still so the movement stays isolated to the hips.',
 '15–20 reps', '60–90 sec', '2-1-2 tempo',
 'Feel the outside of your glutes (glute medius) doing the work, not your quads.',
 'isolation', false, '{}', '{hypertrophy}', 'glutes', '{}', 'strength', 'beginner'),

('Hip Adduction Machine', 'Legs', 'quads', '{}', 'Machine',
 'Sit in the machine with the insides of your thighs against the pads, knees apart at the start.',
 'Squeeze your knees together against the pads'' resistance, then return under control.',
 'Using short, bouncy reps. Control the full range in both directions for the inner-thigh muscles to actually do the work.',
 'Keep your core braced and hips square in the seat throughout.',
 '15–20 reps', '60–90 sec', '2-1-2 tempo',
 'Focus on squeezing your inner thighs together, not just letting the pads bounce closed.',
 'isolation', false, '{}', '{hypertrophy}', 'quads', '{}', 'strength', 'beginner'),

('Seated Leg Curl', 'Legs', 'hamstrings', '{}', 'Machine',
 'Sit in the machine with the pad positioned against the back of your lower legs, legs extended in front of you.',
 'Curl your heels down and back toward the seat by contracting your hamstrings, then return under control.',
 'Letting the hips rise off the seat to help the curl. Keep your hips pinned down so the hamstrings do all the work.',
 'Keep your core braced and back flat against the seat pad throughout.',
 '10–15 reps', '60–90 sec', '2-1-2 tempo',
 'The seated hip angle changes the stretch on your hamstrings compared to lying — focus on feeling that stretch at the top of each rep.',
 'isolation', true, '{}', '{hypertrophy}', 'hamstrings', '{}', 'strength', 'beginner'),

('Spider Curl', 'Pull', 'biceps', '{forearms}', 'Dumbbell',
 'Lie face-down on an incline bench set to roughly 45°, arms hanging straight down holding dumbbells.',
 'Curl the weight up by flexing your elbows, squeezing at the top, then lower under control to a full stretch.',
 'Letting the upper arms drift forward off the bench. Keep them pinned to the pad throughout so the biceps do all the lifting, with zero shoulder swing.',
 'Press your chest and upper arms into the pad to lock out any body English.',
 '10–15 reps', '60–90 sec', '3-1-1 tempo — slow, controlled stretch down',
 'This angle emphasizes the stretch at the bottom more than a standing curl — don''t rush through it.',
 'isolation', true, '{}', '{hypertrophy}', 'biceps', '{forearms}', 'strength', 'intermediate'),

('Cable Rope Hammer Curl', 'Pull', 'biceps', '{forearms}', 'Cable',
 'Attach a rope handle to a low cable pulley, grip one end in each hand with palms facing each other.',
 'Curl the rope up toward your shoulders keeping your palms facing in throughout (a neutral grip), then lower under control.',
 'Letting the elbows drift forward or swinging the torso to move the weight. Keep elbows pinned at your sides.',
 'Brace your core and keep your upper arms still — only the forearms should move.',
 '10–15 reps', '60–90 sec', '2-1-2 tempo',
 'The neutral grip shifts emphasis onto the brachialis and forearms alongside the biceps — feel it on the outside of your upper arm.',
 'isolation', false, '{}', '{hypertrophy}', 'biceps', '{forearms}', 'strength', 'beginner')

on conflict (name) do nothing;

-- ══════════════════════════════════════════════════════════════════════
-- 3. NEW EXERCISES — conditioning (reference content only)
-- ══════════════════════════════════════════════════════════════════════
-- hypertrophy_* columns stay null — these aren't rep-based work, same
-- reasoning as phase30's plyometric entries. conditioning_duration_
-- guidance / conditioning_intensity_guidance (added in section 1 above)
-- carry the equivalent static guidance instead.
--
-- Actual LOGGING for these (duration/distance, not reps) reuses the
-- conditioning_log table + CONDITIONING_DRILLS list already built for
-- Krafft Athlete Mode's speed/agility drills (see supabase-schema-
-- phase29-athlete-mode.sql) — the exact "duration/intensity-based fields
-- instead of rep-based" structure this item asked to propose already
-- exists. index.html's CONDITIONING_DRILLS gets these 4 added as new
-- metricType:'time' entries alongside this migration, rather than this
-- migration inventing a second, parallel logging mechanism. That list is
-- intentionally static (not DB-seeded) for the same reason the existing
-- speed/agility drills are — flagged, same as the rest of this file, in
-- case a fuller DB-backed conditioning-logging redesign is wanted later.
insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake, cue_bracing,
  movement_type, avoid_flags, block_types,
  muscle_map_key, muscle_map_secondary_keys, category, experience_level,
  conditioning_duration_guidance, conditioning_intensity_guidance
) values

('Rowing Machine', 'Full Body', 'back', '{hamstrings,biceps}', 'Machine',
 'Strap your feet in, grip the handle with both hands, start with knees bent and arms extended.',
 'Drive through your legs first, then lean back slightly and pull the handle to your lower ribs, finishing with your arms — then reverse the sequence smoothly to return.',
 'Pulling with the arms and back before the legs have finished driving. The power should come from your legs first — arms and back just finish the stroke.',
 'Keep your core braced through the drive, especially during the leg-drive phase, so the force transfers cleanly through your trunk.',
 'conditioning', '{}', '{}', 'lats', '{hamstrings,biceps}', 'conditioning', 'beginner',
 '15–30 min steady-state, or 20–30 sec on / 40 sec off for intervals',
 'Steady-state: RPE 5–6, conversational pace. Intervals: RPE 8–9 on work periods.'),

('Assault Bike', 'Full Body', 'quads', '{delts,hamstrings}', 'Machine',
 'Sit on the bike with hands on the moving handles and feet on the pedals, and adjust the seat so your knee has a slight bend at full extension.',
 'Pedal and pump the handles together, using both arms and legs to drive the fan.',
 'Only pedaling with the legs and letting the arms go along for the ride. Push and pull the handles actively to work the upper body too.',
 'Keep your core engaged to stabilize your torso as you drive through both arms and legs.',
 'conditioning', '{}', '{}', 'quads', '{delts,hamstrings}', 'conditioning', 'beginner',
 '10–20 min steady-state, or 10–20 sec max-effort sprints with 1–2 min recovery for intervals',
 'Steady-state: RPE 5–6. Sprint intervals: all-out effort (RPE 9–10) on work periods.'),

('Stair Climber', 'Legs', 'quads', '{glutes,calves}', 'Machine',
 'Stand on the machine with a light grip on the side or front rails — enough for balance, not to take weight off your legs.',
 'Step continuously, driving through your full foot on each step rather than just your toes.',
 'Leaning heavily on the handrails, which lets your arms take weight that should be loading your legs. Use the rails for balance only.',
 'Keep your torso upright and core braced rather than hunching forward over the rails.',
 'conditioning', '{}', '{}', 'quads', '{glutes,calves}', 'conditioning', 'beginner',
 '10–20 min continuous',
 'RPE 5–7 — a pace you can sustain for the full duration without stopping.'),

('Incline Treadmill Walk', 'Legs', 'glutes', '{quads,calves}', 'Machine',
 'Set the treadmill to an incline (commonly 10–15%) at a brisk walking pace, holding the rails only if needed for balance.',
 'Walk continuously at the set incline and pace for the full duration, maintaining an upright posture.',
 'Gripping the handrails to reduce the workload. Walking hands-free (or with just a light touch) is what makes the incline actually work your legs and cardio system.',
 'Keep your torso upright — leaning on the rails or hunching forward reduces how much your hips and glutes work.',
 'conditioning', '{}', '{}', 'glutes', '{quads,calves}', 'conditioning', 'beginner',
 '20–45 min continuous',
 'RPE 4–6 — brisk but sustainable; a common low-impact alternative to running for steady cardio volume.')

on conflict (name) do nothing;

-- ══════════════════════════════════════════════════════════════════════
-- Note on the "Plyometrics/Speed/Agility" list from the task spec
-- ══════════════════════════════════════════════════════════════════════
-- Box Jump, Depth Jump, Broad Jump, Lateral Bound, and both Medicine Ball
-- throws already exist in the exercises table (supabase-schema-phase30-
-- plyometric-exercises.sql) under the same or an equivalent name
-- (Medicine Ball Chest Pass ~= Med Ball Chest Throw; Medicine Ball
-- Rotational Throw is an exact match). Single-Leg Hop ~= the existing
-- Single-Leg Bound. Sprint Intervals, Cone Shuttle Drill, and Ladder
-- Drill already exist too, just in a different system — CONDITIONING_
-- DRILLS in index.html (Sprint Intervals is an exact-name match; Cone
-- Drill (5-10-5 Shuttle) and Agility Ladder are the same drills under
-- slightly different names), logged via conditioning_log rather than the
-- exercises table, since they're timed/distance work like the new
-- conditioning entries above. None of the 10 requested plyo/speed/agility
-- exercises were actually missing, so nothing further was added here —
-- adding near-duplicate rows under the requested names would have split
-- one exercise into two confusing library entries.
