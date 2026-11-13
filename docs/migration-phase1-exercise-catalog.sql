-- Krafft training redesign: Phase 1 schema additions
-- Adds: per-exercise aliases, tracking type, and detailed (pre-fold) muscle
-- data, alongside the existing muscle_map_key/_secondary_keys (which stay
-- as the FOLDED 14-region set used only for body-map diagram highlighting).
-- Safe to run twice (IF NOT EXISTS on every column).

alter table exercises add column if not exists aliases text[] default '{}';
alter table exercises add column if not exists tracking text default 'weight_reps';
alter table exercises add column if not exists detailed_muscle text;
alter table exercises add column if not exists detailed_secondary text[] default '{}';

comment on column exercises.tracking is 'weight_reps | bodyweight_reps | time | distance_time';
comment on column exercises.detailed_muscle is 'Original catalog muscle name (pre-fold), e.g. "Front Delts" or "Adductors". Used for search filters, weekly-sets-per-muscle math, and swap logic. muscle_map_key stays the folded 14-region set used only for diagram highlighting.';
comment on column exercises.detailed_secondary is 'Original catalog secondary muscles (pre-fold), parallel to detailed_muscle.';

-- Phase 1 catalog import: MERGE statements for 88 exercises
-- that already existed. Each existing row keeps its name/ID unchanged;
-- only the 4 brand-new columns above are filled in (they are null on every
-- existing row pre-migration, so this cannot overwrite real data).
-- Idempotent: running this twice sets the same values again.

update exercises set
  aliases = '{"Barbell Bench Press","Flat Bench"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Triceps","Front Delts"}'
where name = 'Bench Press';
-- (matched CSV row: "Barbell Bench Press", via alias:"Bench Press")

update exercises set
  aliases = '{"CGBP"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Triceps',
  detailed_secondary = '{"Chest","Front Delts"}'
where name = 'Close-Grip Bench Press';
-- (matched CSV row: "Close-Grip Bench Press", via name)

update exercises set
  aliases = '{"DB Bench"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Triceps","Front Delts"}'
where name = 'Dumbbell Bench Press';
-- (matched CSV row: "Dumbbell Bench Press", via name)

update exercises set
  aliases = '{"Incline DB Press"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Front Delts","Triceps"}'
where name = 'Incline Dumbbell Press';
-- (matched CSV row: "Incline Dumbbell Press", via name)

update exercises set
  aliases = '{"DB Fly","Flat Fly"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Front Delts"}'
where name = 'Dumbbell Fly';
-- (matched CSV row: "Dumbbell Fly", via name)

update exercises set
  aliases = '{"Pushup"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Triceps","Front Delts","Abs"}'
where name = 'Push-Up';
-- (matched CSV row: "Push-Up", via name)

update exercises set
  aliases = '{"Machine Fly","Pec Fly Machine"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Front Delts"}'
where name = 'Pec Deck';
-- (matched CSV row: "Pec Deck", via name)

update exercises set
  aliases = '{"Bent-Over Row"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Upper Back","Biceps","Rear Delts","Lower Back"}'
where name = 'Barbell Row';
-- (matched CSV row: "Barbell Row", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Upper Back',
  detailed_secondary = '{"Lats","Biceps","Lower Back"}'
where name = 'Pendlay Row';
-- (matched CSV row: "Pendlay Row", via name)

update exercises set
  aliases = '{"One-Arm Dumbbell Row","DB Row"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Upper Back","Biceps","Rear Delts"}'
where name = 'Dumbbell Row';
-- (matched CSV row: "Dumbbell Row", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Upper Back',
  detailed_secondary = '{"Lats","Biceps","Rear Delts"}'
where name = 'T-Bar Row';
-- (matched CSV row: "T-Bar Row", via name)

update exercises set
  aliases = '{"Seated Cable Row (Close-Grip)","V-Bar Row"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Upper Back","Biceps"}'
where name = 'Seated Cable Row';
-- (matched CSV row: "Seated Cable Row (Close-Grip)", via alias:"Seated Cable Row")

update exercises set
  aliases = '{"Wide-Grip Lat Pulldown"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Biceps","Upper Back"}'
where name = 'Lat Pulldown';
-- (matched CSV row: "Lat Pulldown", via name)

update exercises set
  aliases = '{"Lat Prayer"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Triceps","Abs"}'
where name = 'Straight-Arm Pulldown';
-- (matched CSV row: "Straight-Arm Pulldown", via name)

update exercises set
  aliases = '{"Pullup"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Biceps","Upper Back","Forearms"}'
where name = 'Pull-Up';
-- (matched CSV row: "Pull-Up", via name)

update exercises set
  aliases = '{"Chinup"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Lats',
  detailed_secondary = '{"Biceps","Upper Back"}'
where name = 'Chin-Up';
-- (matched CSV row: "Chin-Up", via name)

update exercises set
  aliases = '{"Conventional Deadlift"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{"Glutes","Lower Back","Traps","Forearms"}'
where name = 'Deadlift';
-- (matched CSV row: "Conventional Deadlift", via alias:"Deadlift")

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Glutes',
  detailed_secondary = '{"Hamstrings","Quads","Adductors","Lower Back"}'
where name = 'Sumo Deadlift';
-- (matched CSV row: "Sumo Deadlift", via name)

update exercises set
  aliases = '{"Hex Bar Deadlift"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Hamstrings","Traps","Lower Back"}'
where name = 'Trap Bar Deadlift';
-- (matched CSV row: "Trap Bar Deadlift", via name)

update exercises set
  aliases = '{"RDL"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{"Glutes","Lower Back"}'
where name = 'Romanian Deadlift';
-- (matched CSV row: "Romanian Deadlift", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{"Glutes","Lower Back"}'
where name = 'Stiff-Leg Deadlift';
-- (matched CSV row: "Stiff-Leg Deadlift", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{"Lower Back","Glutes"}'
where name = 'Good Morning';
-- (matched CSV row: "Good Morning", via name)

update exercises set
  aliases = '{"Face Pull (Cable)"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Rear Delts',
  detailed_secondary = '{"Upper Back","Traps","Side Delts"}'
where name = 'Face Pull';
-- (matched CSV row: "Face Pull (Cable)", via alias:"Face Pull")

update exercises set
  aliases = '{"Rear Delt Machine","Machine Reverse Fly"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Rear Delts',
  detailed_secondary = '{"Upper Back"}'
where name = 'Reverse Pec Deck';
-- (matched CSV row: "Reverse Pec Deck", via name)

update exercises set
  aliases = '{"Upright Row (Barbell)"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Side Delts',
  detailed_secondary = '{"Traps","Biceps"}'
where name = 'Upright Row';
-- (matched CSV row: "Upright Row (Barbell)", via alias:"Upright Row")

update exercises set
  aliases = '{"Barbell Overhead Press","Military Press","OHP"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Front Delts',
  detailed_secondary = '{"Side Delts","Triceps","Abs"}'
where name = 'Overhead Press';
-- (matched CSV row: "Barbell Overhead Press", via alias:"Overhead Press")

update exercises set
  aliases = '{"Dumbbell Shoulder Press (Seated)"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Front Delts',
  detailed_secondary = '{"Side Delts","Triceps"}'
where name = 'Seated Dumbbell Press';
-- (matched CSV row: "Dumbbell Shoulder Press (Seated)", via alias:"Seated Dumbbell Press")

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Front Delts',
  detailed_secondary = '{"Side Delts","Triceps"}'
where name = 'Arnold Press';
-- (matched CSV row: "Arnold Press", via name)

update exercises set
  aliases = '{"Dumbbell Lateral Raise","Side Raise"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Side Delts',
  detailed_secondary = '{"Traps"}'
where name = 'Lateral Raise';
-- (matched CSV row: "Dumbbell Lateral Raise", via alias:"Lateral Raise")

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Side Delts',
  detailed_secondary = '{"Traps"}'
where name = 'Cable Lateral Raise';
-- (matched CSV row: "Cable Lateral Raise", via name)

update exercises set
  aliases = '{"Dumbbell Front Raise"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Front Delts',
  detailed_secondary = '{"Side Delts"}'
where name = 'Front Raise';
-- (matched CSV row: "Dumbbell Front Raise", via alias:"Front Raise")

update exercises set
  aliases = '{"Standing Barbell Curl"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Barbell Curl';
-- (matched CSV row: "Barbell Curl", via name)

update exercises set
  aliases = '{"Alternating Dumbbell Curl","DB Curl"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Dumbbell Curl';
-- (matched CSV row: "Dumbbell Curl", via name)

update exercises set
  aliases = '{"Dumbbell Hammer Curl"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Hammer Curl';
-- (matched CSV row: "Hammer Curl", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Incline Dumbbell Curl';
-- (matched CSV row: "Incline Dumbbell Curl", via name)

update exercises set
  aliases = '{"Preacher Curl (EZ Bar)"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Preacher Curl';
-- (matched CSV row: "Preacher Curl (EZ Bar)", via alias:"Preacher Curl")

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Concentration Curl';
-- (matched CSV row: "Concentration Curl", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Spider Curl';
-- (matched CSV row: "Spider Curl", via name)

update exercises set
  aliases = '{"Cable Curl (Straight Bar)"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Cable Curl';
-- (matched CSV row: "Cable Curl (Straight Bar)", via alias:"Cable Curl")

update exercises set
  aliases = '{"Cable Hammer Curl (Rope)","Rope Hammer Curl"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Biceps',
  detailed_secondary = '{"Forearms"}'
where name = 'Cable Rope Hammer Curl';
-- (matched CSV row: "Cable Hammer Curl (Rope)", via name)

update exercises set
  aliases = '{"Farmer''s Walk"}',
  tracking = 'distance_time',
  detailed_muscle = 'Forearms',
  detailed_secondary = '{"Traps","Abs","Glutes"}'
where name = 'Farmer''s Carry';
-- (matched CSV row: "Farmer's Carry", via name)

update exercises set
  aliases = '{"Barbell Back Squat","Squat"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Adductors","Lower Back","Abs"}'
where name = 'Back Squat';
-- (matched CSV row: "Barbell Back Squat", via alias:"Back Squat")

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Abs","Upper Back"}'
where name = 'Front Squat';
-- (matched CSV row: "Front Squat", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Hamstrings","Lower Back"}'
where name = 'Box Squat';
-- (matched CSV row: "Box Squat", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Abs"}'
where name = 'Goblet Squat';
-- (matched CSV row: "Goblet Squat", via name)

update exercises set
  aliases = '{"45-Degree Leg Press"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Adductors","Hamstrings"}'
where name = 'Leg Press';
-- (matched CSV row: "Leg Press", via name)

update exercises set
  aliases = '{"Rear-Foot-Elevated Split Squat"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Adductors"}'
where name = 'Bulgarian Split Squat';
-- (matched CSV row: "Bulgarian Split Squat", via name)

update exercises set
  aliases = '{"Dumbbell Walking Lunge"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Hamstrings"}'
where name = 'Walking Lunge';
-- (matched CSV row: "Walking Lunge", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Glutes',
  detailed_secondary = '{"Quads","Hamstrings"}'
where name = 'Reverse Lunge';
-- (matched CSV row: "Reverse Lunge", via name)

update exercises set
  aliases = '{"Dumbbell Step-Up"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Hamstrings"}'
where name = 'Step-Up';
-- (matched CSV row: "Step-Up", via name)

update exercises set
  aliases = '{"Jump Squat"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Calves"}'
where name = 'Squat Jump';
-- (matched CSV row: "Jump Squat", via name)

update exercises set
  aliases = '{"Machine Leg Extension"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{}'
where name = 'Leg Extension';
-- (matched CSV row: "Leg Extension", via name)

update exercises set
  aliases = '{"Hamstring Curl"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{}'
where name = 'Seated Leg Curl';
-- (matched CSV row: "Seated Leg Curl", via name)

update exercises set
  aliases = '{"Nordic Hamstring Curl"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{"Glutes"}'
where name = 'Nordic Curl';
-- (matched CSV row: "Nordic Hamstring Curl", via alias:"Nordic Curl")

update exercises set
  aliases = '{"Barbell Hip Thrust"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Glutes',
  detailed_secondary = '{"Hamstrings","Quads"}'
where name = 'Hip Thrust';
-- (matched CSV row: "Barbell Hip Thrust", via alias:"Hip Thrust")

update exercises set
  aliases = '{}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Glutes',
  detailed_secondary = '{"Hamstrings"}'
where name = 'Glute Bridge';
-- (matched CSV row: "Glute Bridge", via name)

update exercises set
  aliases = '{"Cable Glute Kickback"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Glutes',
  detailed_secondary = '{"Hamstrings"}'
where name = 'Cable Kickback';
-- (matched CSV row: "Cable Glute Kickback", via alias:"Cable Kickback")

update exercises set
  aliases = '{"Abductor Machine"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Abductors',
  detailed_secondary = '{"Glutes"}'
where name = 'Hip Abduction Machine';
-- (matched CSV row: "Hip Abduction Machine", via name)

update exercises set
  aliases = '{"Adductor Machine"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Adductors',
  detailed_secondary = '{}'
where name = 'Hip Adduction Machine';
-- (matched CSV row: "Hip Adduction Machine", via name)

update exercises set
  aliases = '{"Standing Calf Raise Machine"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Calves',
  detailed_secondary = '{}'
where name = 'Standing Calf Raise';
-- (matched CSV row: "Standing Calf Raise Machine", via alias:"Standing Calf Raise")

update exercises set
  aliases = '{"Seated Calf Raise Machine"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Calves',
  detailed_secondary = '{}'
where name = 'Seated Calf Raise';
-- (matched CSV row: "Seated Calf Raise Machine", via alias:"Seated Calf Raise")

update exercises set
  aliases = '{"Calf Press"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Calves',
  detailed_secondary = '{}'
where name = 'Leg Press Calf Raise';
-- (matched CSV row: "Leg Press Calf Raise", via name)

update exercises set
  aliases = '{"Kneeling Cable Crunch"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Abs',
  detailed_secondary = '{"Obliques"}'
where name = 'Cable Crunch';
-- (matched CSV row: "Cable Crunch", via name)

update exercises set
  aliases = '{}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Abs',
  detailed_secondary = '{"Hip Flexors","Forearms"}'
where name = 'Hanging Leg Raise';
-- (matched CSV row: "Hanging Leg Raise", via name)

update exercises set
  aliases = '{"Front Plank"}',
  tracking = 'time',
  detailed_muscle = 'Abs',
  detailed_secondary = '{"Obliques","Glutes"}'
where name = 'Plank';
-- (matched CSV row: "Plank", via name)

update exercises set
  aliases = '{"Ab Roller"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Abs',
  detailed_secondary = '{"Lats","Front Delts"}'
where name = 'Ab Wheel Rollout';
-- (matched CSV row: "Ab Wheel Rollout", via name)

update exercises set
  aliases = '{}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Obliques',
  detailed_secondary = '{"Abs"}'
where name = 'Russian Twist';
-- (matched CSV row: "Russian Twist", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Obliques',
  detailed_secondary = '{"Abs","Front Delts"}'
where name = 'Pallof Press';
-- (matched CSV row: "Pallof Press", via name)

update exercises set
  aliases = '{}',
  tracking = 'weight_reps',
  detailed_muscle = 'Full Body',
  detailed_secondary = '{"Traps","Quads","Glutes","Hamstrings"}'
where name = 'Power Clean';
-- (matched CSV row: "Power Clean", via name)

update exercises set
  aliases = '{"Barbell Thruster"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Full Body',
  detailed_secondary = '{"Quads","Front Delts","Triceps"}'
where name = 'Thruster';
-- (matched CSV row: "Barbell Thruster", via alias:"Thruster")

update exercises set
  aliases = '{}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Quads',
  detailed_secondary = '{"Glutes","Calves"}'
where name = 'Box Jump';
-- (matched CSV row: "Box Jump", via name)

update exercises set
  aliases = '{"Incline Walk"}',
  tracking = 'distance_time',
  detailed_muscle = 'Cardio',
  detailed_secondary = '{"Glutes","Calves"}'
where name = 'Incline Treadmill Walk';
-- (matched CSV row: "Incline Treadmill Walk", via name)

update exercises set
  aliases = '{"Erg"}',
  tracking = 'distance_time',
  detailed_muscle = 'Cardio',
  detailed_secondary = '{"Lats","Quads","Upper Back"}'
where name = 'Rowing Machine';
-- (matched CSV row: "Rowing Machine", via name)

update exercises set
  aliases = '{"StairMaster"}',
  tracking = 'distance_time',
  detailed_muscle = 'Cardio',
  detailed_secondary = '{"Glutes","Quads","Calves"}'
where name = 'Stair Climber';
-- (matched CSV row: "Stair Climber", via name)

update exercises set
  aliases = '{"Air Bike"}',
  tracking = 'distance_time',
  detailed_muscle = 'Cardio',
  detailed_secondary = '{"Quads","Front Delts"}'
where name = 'Assault Bike';
-- (matched CSV row: "Air Bike", via alias:"Assault Bike")

update exercises set
  aliases = '{"Incline Barbell Bench Press","Incline Bench"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Front Delts","Triceps"}'
where name = 'Incline Bench Press';
-- (matched CSV row: "Incline Barbell Bench Press", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Decline Barbell Bench Press","Decline Bench"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Triceps","Front Delts"}'
where name = 'Decline Bench Press';
-- (matched CSV row: "Decline Barbell Bench Press", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Cable Fly (Mid)","Cable Crossover"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Front Delts"}'
where name = 'Cable Fly';
-- (matched CSV row: "Cable Fly (Mid)", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Rear Delt Fly (Dumbbell)","Bent-Over Lateral Raise"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Rear Delts',
  detailed_secondary = '{"Upper Back"}'
where name = 'Rear Delt Fly';
-- (matched CSV row: "Rear Delt Fly (Dumbbell)", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Barbell Shrug"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Traps',
  detailed_secondary = '{"Forearms"}'
where name = 'Shrug';
-- (matched CSV row: "Barbell Shrug", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Lying Leg Curl","Prone Leg Curl"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Hamstrings',
  detailed_secondary = '{}'
where name = 'Leg Curl';
-- (matched CSV row: "Lying Leg Curl", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Triceps Pushdown (Bar)","Straight-Bar Pushdown"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Triceps',
  detailed_secondary = '{}'
where name = 'Tricep Pushdown';
-- (matched CSV row: "Triceps Pushdown (Bar)", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Overhead Dumbbell Triceps Extension"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Triceps',
  detailed_secondary = '{}'
where name = 'Overhead Tricep Extension';
-- (matched CSV row: "Overhead Dumbbell Triceps Extension", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Skull Crusher (EZ Bar)","Lying Triceps Extension"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Triceps',
  detailed_secondary = '{}'
where name = 'Skull Crusher';
-- (matched CSV row: "Skull Crusher (EZ Bar)", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Chest Dip","Dips"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Chest',
  detailed_secondary = '{"Triceps","Front Delts"}'
where name = 'Dip (Chest-Focused)';
-- (matched CSV row: "Chest Dip", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Triceps Dip","Parallel Bar Dip"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Triceps',
  detailed_secondary = '{"Chest","Front Delts"}'
where name = 'Dip (Tricep-Focused)';
-- (matched CSV row: "Triceps Dip", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Dumbbell Triceps Kickback"}',
  tracking = 'weight_reps',
  detailed_muscle = 'Triceps',
  detailed_secondary = '{}'
where name = 'Kickback';
-- (matched CSV row: "Dumbbell Triceps Kickback", via judgment-call (generic-name convention))

update exercises set
  aliases = '{"Medicine Ball Slam"}',
  tracking = 'bodyweight_reps',
  detailed_muscle = 'Full Body',
  detailed_secondary = '{"Abs","Lats","Front Delts"}'
where name = 'Medicine Ball Overhead Slam';
-- (matched CSV row: "Medicine Ball Slam", via judgment-call (generic-name convention))


-- Phase 1 catalog import: INSERT statements for 167 genuinely
-- new exercises. Idempotent via "where not exists" guard on name.
-- Cues (cue_setup/cue_execution/cue_mistake) are drafted in
-- docs/cues-review.md for review BEFORE this file is run against a live DB.

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Barbell Floor Press', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Barbell',
  'Lie on the floor with knees bent, barbell at arm''s length above your chest, grip just outside shoulder width.', 'Lower until your upper arms touch the floor, pause briefly, then press back up without bouncing off the ground.', 'Using the floor to bounce the bar back up. Pause fully until the stretch reflex is gone, then press — that''s the point of the floor press.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{"Floor Press"}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Barbell Floor Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Decline Dumbbell Press', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Dumbbell',
  'Secure your legs on a decline bench, dumbbells at your lower-chest line, elbows under the bells.', 'Press the dumbbells up and slightly together, then lower under control to the same lower-chest line.', 'Letting the dumbbells drift toward your face instead of your lower chest. Keep the path over your lower sternum, not your collarbone.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Decline Dumbbell Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Floor Press', 'Push', 'chest', '{"Triceps"}', 'Dumbbell',
  'Lie on the floor, knees bent, holding dumbbells at your chest with elbows resting lightly on the ground.', 'Press the dumbbells straight up, then lower with control until your triceps touch the floor again.', 'Flaring the elbows out to 90° at the bottom. The floor limits your range on purpose — use it to protect the shoulder, not to force extra stretch.',
  'compound', NULL,
  'chest', '{"triceps"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps"}'
where not exists (select 1 from exercises where name = 'Dumbbell Floor Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Hex Press', 'Push', 'chest', '{"Triceps"}', 'Dumbbell',
  'Lie on a flat bench holding two dumbbells pressed together over your chest, palms facing each other.', 'Lower the dumbbells to your chest while squeezing them together, then press back up, keeping that inward squeeze the whole rep.', 'Letting the dumbbells separate mid-rep. The constant squeeze is what makes this a chest-focused press — don''t let it turn into a normal press.',
  'compound', NULL,
  'chest', '{"triceps"}',
  '{"Squeeze Press"}', 'weight_reps', 'Chest', '{"Triceps"}'
where not exists (select 1 from exercises where name = 'Dumbbell Hex Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Incline Dumbbell Fly', 'Push', 'chest', '{"Front Delts"}', 'Dumbbell',
  'Set an incline bench to 30–45°, dumbbells held above your chest with a slight bend in the elbows.', 'Lower the dumbbells out to the sides in a wide arc until you feel a stretch across the upper chest, then bring them back together over your chest.', 'Bending and straightening the elbows during the rep. Lock the elbow angle in from the start — the movement should come from the shoulder joint, not the elbow.',
  'isolation', NULL,
  'chest', '{"delts"}',
  '{"Incline Fly"}', 'weight_reps', 'Chest', '{"Front Delts"}'
where not exists (select 1 from exercises where name = 'Incline Dumbbell Fly');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Pullover', 'Push', 'chest', '{"Lats","Triceps"}', 'Dumbbell',
  'Lie across a flat bench with just your shoulders supported, holding one dumbbell with both hands straight above your chest.', 'Lower the dumbbell in an arc behind your head until you feel a stretch in your lats and chest, then pull it back over your chest.', 'Dropping too low, too fast, with heavy weight. This is a stretch-focused move — go only as far as a controlled shoulder range allows.',
  'compound', NULL,
  'chest', '{"lats","triceps"}',
  '{"DB Pullover"}', 'weight_reps', 'Chest', '{"Lats","Triceps"}'
where not exists (select 1 from exercises where name = 'Dumbbell Pullover');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Incline Push-Up', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Bodyweight',
  'Place your hands on a bench or box higher than your feet, body in a straight line from head to heels.', 'Lower your chest to just above the surface, then press back up while keeping your core braced.', 'Letting the hips sag or pike up. Keep the straight-line brace the whole rep — the incline is there to adjust difficulty, not to let your form slip.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{}', 'bodyweight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Incline Push-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Decline Push-Up', 'Push', 'chest', '{"Front Delts","Triceps"}', 'Bodyweight',
  'Place your feet on a bench or box, hands on the floor slightly wider than shoulder width.', 'Lower your chest toward the floor under control, then press back up to full arm extension.', 'Letting the lower back arch as the feet go higher. Brace your abs and keep the glutes slightly squeezed to protect the lower back at this angle.',
  'compound', NULL,
  'chest', '{"delts","triceps"}',
  '{"Feet-Elevated Push-Up"}', 'bodyweight_reps', 'Chest', '{"Front Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Decline Push-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Weighted Push-Up', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Bodyweight',
  'Have a partner place a plate on your upper back, or wear a weighted vest, then set up in a standard push-up position.', 'Lower your chest to the floor under control, then press back up without letting the added weight pull your hips down.', 'Rushing the rep because of the extra load. Added weight makes form breakdown more costly, not less important — slow the tempo down.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Weighted Push-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Diamond Push-Up', 'Push', 'triceps', '{"Chest","Front Delts"}', 'Bodyweight',
  'Get into a push-up position with your hands together under your chest, thumbs and index fingers forming a diamond shape.', 'Lower your chest to your hands under control, then press back up to full extension.', 'Letting the elbows flare wide to make it easier. Keep them tracking back close to your ribs — that''s what shifts the load onto the triceps.',
  'compound', NULL,
  'triceps', '{"chest","delts"}',
  '{"Close-Grip Push-Up"}', 'bodyweight_reps', 'Triceps', '{"Chest","Front Delts"}'
where not exists (select 1 from exercises where name = 'Diamond Push-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Assisted Dip Machine', 'Push', 'triceps', '{"Chest","Front Delts"}', 'Machine',
  'Kneel or stand on the assist platform, grip the dip handles, and set the assist weight so you can complete your target reps with control.', 'Lower your body until your upper arms are roughly parallel to the floor, then press back up to full extension.', 'Setting the assist weight too high and skipping real effort. Dial the assist down over time — the goal is to work toward unassisted dips, not stay propped up.',
  'compound', NULL,
  'triceps', '{"chest","delts"}',
  '{"Dip Machine (Assisted)"}', 'weight_reps', 'Triceps', '{"Chest","Front Delts"}'
where not exists (select 1 from exercises where name = 'Assisted Dip Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Chest Press Machine', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Machine',
  'Adjust the seat so the handles line up with mid-chest height, back flat against the pad.', 'Press the handles forward until your arms are extended but not locked out, then return under control.', 'Letting the shoulder blades round forward off the pad. Keep them pinned back throughout so the chest does the work, not the front delts.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{"Machine Chest Press"}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Chest Press Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Incline Chest Press Machine', 'Push', 'chest', '{"Front Delts","Triceps"}', 'Machine',
  'Adjust the seat so the handles align with your upper chest, back flat against the pad.', 'Press the handles up and forward until near full extension, then return under control to the stretch position.', 'Shrugging the shoulders up toward the ears on the press. Keep them down and back the whole set so the upper chest takes the load.',
  'compound', NULL,
  'chest', '{"delts","triceps"}',
  '{"Incline Machine Press"}', 'weight_reps', 'Chest', '{"Front Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Incline Chest Press Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Decline Chest Press Machine', 'Push', 'chest', '{"Triceps"}', 'Machine',
  'Adjust the seat so the handles align with your lower chest, back flat against the pad.', 'Press the handles forward and slightly down, then return under control to the stretch position.', 'Pressing in a straight line instead of following the machine''s downward arc. Follow the handle path the machine is built for.',
  'compound', NULL,
  'chest', '{"triceps"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps"}'
where not exists (select 1 from exercises where name = 'Decline Chest Press Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Bench Press', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Smith Machine',
  'Lie on a flat bench under the bar, unrack it, and position it over your lower chest.', 'Lower the bar to your chest under control, then press back up to just short of lockout.', 'Letting the fixed bar path dictate an unnatural shoulder position. Set your bench position so the fixed vertical path still lines up with your natural press line.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Smith Machine Bench Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Incline Press', 'Push', 'chest', '{"Front Delts","Triceps"}', 'Smith Machine',
  'Set an incline bench under the Smith bar, unrack it over your upper chest.', 'Lower the bar to your upper chest, then press back up along the fixed vertical path.', 'Setting the incline too steep, turning it into a shoulder press. Keep the bench between 30–45° so the chest stays the primary mover.',
  'compound', NULL,
  'chest', '{"delts","triceps"}',
  '{}', 'weight_reps', 'Chest', '{"Front Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Smith Machine Incline Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Decline Press', 'Push', 'chest', '{"Triceps"}', 'Smith Machine',
  'Set a decline bench under the Smith bar, secure your legs, and unrack the bar over your lower chest.', 'Lower the bar to your lower chest, then press back up along the fixed path.', 'Un-securing your legs mid-set. Make sure the leg hold is locked before you unrack — sliding on a decline is a real fall risk.',
  'compound', NULL,
  'chest', '{"triceps"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps"}'
where not exists (select 1 from exercises where name = 'Smith Machine Decline Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Fly (High-to-Low)', 'Push', 'chest', '{"Front Delts"}', 'Cable',
  'Set both pulleys above shoulder height, step forward with a slight stagger, handles starting high and out to the sides.', 'Pull the handles down and together in front of your lower chest, following a diagonal path, then return to the stretch under control.', 'Turning it into a press by bending the elbows more as you go. Keep a soft, fixed elbow bend and let the shoulder do the moving.',
  'isolation', NULL,
  'chest', '{"delts"}',
  '{"High-to-Low Cable Fly"}', 'weight_reps', 'Chest', '{"Front Delts"}'
where not exists (select 1 from exercises where name = 'Cable Fly (High-to-Low)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Fly (Low-to-High)', 'Push', 'chest', '{"Front Delts"}', 'Cable',
  'Set both pulleys at or below hip height, handles starting low and out to the sides.', 'Pull the handles up and together toward upper-chest height along a diagonal path, then return under control.', 'Using the low pulley position to turn this into a front raise. Keep the path diagonal across the chest, not straight up in front of the shoulders.',
  'isolation', NULL,
  'chest', '{"delts"}',
  '{"Low-to-High Cable Fly"}', 'weight_reps', 'Chest', '{"Front Delts"}'
where not exists (select 1 from exercises where name = 'Cable Fly (Low-to-High)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Standing Cable Chest Press', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Cable',
  'Set the pulley at chest height, face away from the machine in a staggered stance, handle at your chest.', 'Press the handle forward to full extension, then return under control without letting the cable yank you backward.', 'Letting the torso rotate or lean back to help the press. Keep the core braced and the movement isolated to the arm and chest.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Standing Cable Chest Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Arm Cable Chest Press', 'Push', 'chest', '{"Triceps","Front Delts","Abs"}', 'Cable',
  'Set the pulley at chest height, staggered stance, one hand on the handle, the other free for balance.', 'Press the handle forward to full extension while resisting rotation, then return under control.', 'Letting the torso twist toward the working arm. Brace the core hard — resisting that rotation is half the point of doing it one arm at a time.',
  'compound', NULL,
  'chest', '{"triceps","delts","abs"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps","Front Delts","Abs"}'
where not exists (select 1 from exercises where name = 'Single-Arm Cable Chest Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Landmine Press', 'Push', 'shoulders', '{"Chest","Triceps"}', 'Landmine',
  'Set a barbell in a landmine attachment, hold the loaded end at shoulder height with one hand, staggered stance.', 'Press the bar up and slightly forward along its natural arc until your arm is extended, then lower under control.', 'Pressing straight up like an overhead press. Let the bar travel its natural arc forward and up — fighting that path strains the shoulder.',
  'compound', NULL,
  'delts', '{"chest","triceps"}',
  '{"Landmine Shoulder Press"}', 'weight_reps', 'Front Delts', '{"Chest","Triceps"}'
where not exists (select 1 from exercises where name = 'Landmine Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Plate Press', 'Push', 'chest', '{"Front Delts","Triceps"}', 'Other',
  'Hold a weight plate between both palms at chest height, pressing the plate edges together.', 'Press the plate straight out to arm''s length while maintaining the inward squeeze, then return to your chest.', 'Letting the squeeze relax between reps. The constant plate-pinch is what makes this work the chest — don''t let it go slack.',
  'isolation', NULL,
  'chest', '{"delts","triceps"}',
  '{"Svend Press"}', 'weight_reps', 'Chest', '{"Front Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Plate Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Resistance Band Chest Press', 'Push', 'chest', '{"Triceps","Front Delts"}', 'Band',
  'Anchor the band behind you at chest height, step forward to create tension, one handle in each hand.', 'Press both handles forward to full extension, then return under control without letting the band snap you back.', 'Letting the band do the deceleration for you on the way back. Control the return the same way you''d control a weight — don''t just let go.',
  'compound', NULL,
  'chest', '{"triceps","delts"}',
  '{}', 'weight_reps', 'Chest', '{"Triceps","Front Delts"}'
where not exists (select 1 from exercises where name = 'Resistance Band Chest Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Underhand Barbell Row', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Barbell',
  'Hinge at the hips with a flat back, barbell in hand with an underhand (supinated) grip just outside hip width.', 'Pull the bar up to your lower ribs, driving the elbows back, then lower under control.', 'Letting the underhand grip pull the elbows wide. Keep them tracking back close to the body — the supinated grip is for biceps/lat recruitment, not for changing the pull path.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{"Reverse-Grip Row"}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Underhand Barbell Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Seal Row', 'Pull', 'back', '{"Lats","Biceps","Rear Delts"}', 'Barbell',
  'Lie face-down on a raised bench with a barbell or trap bar beneath you, arms extended down.', 'Pull the weight up to your chest, squeezing the shoulder blades together, then lower under control.', 'Using momentum since the bench removes the ability to cheat with the hips. Without hip drive available, let it slow down — don''t yank the weight.',
  'compound', NULL,
  'lats', '{"biceps","delts"}',
  '{}', 'weight_reps', 'Upper Back', '{"Lats","Biceps","Rear Delts"}'
where not exists (select 1 from exercises where name = 'Seal Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Chest-Supported Dumbbell Row', 'Pull', 'back', '{"Lats","Rear Delts","Biceps"}', 'Dumbbell',
  'Lie chest-down on an incline bench, dumbbells hanging straight down, arms extended.', 'Pull the dumbbells up toward your hips, driving the elbows back, then lower under control.', 'Lifting the chest off the pad to add momentum. The support is there to remove lower-back involvement — keep your chest planted the whole set.',
  'compound', NULL,
  'lats', '{"delts","biceps"}',
  '{"Incline Bench Row"}', 'weight_reps', 'Upper Back', '{"Lats","Rear Delts","Biceps"}'
where not exists (select 1 from exercises where name = 'Chest-Supported Dumbbell Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Meadows Row', 'Pull', 'back', '{"Upper Back","Biceps"}', 'Landmine',
  'Set a barbell in a landmine attachment, stand alongside it, hinge forward, and grip the loaded end with one hand.', 'Pull the bar up toward your hip, driving the elbow back and up, then lower under control.', 'Standing too square to the bar instead of slightly angled. A slight stance rotation toward the bar lets you get a fuller range of motion on each rep.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Upper Back","Biceps"}'
where not exists (select 1 from exercises where name = 'Meadows Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Landmine Row', 'Pull', 'back', '{"Lats","Biceps"}', 'Landmine',
  'Set a barbell in a landmine attachment, straddle it, hinge forward, and grip the loaded end with both hands or an attachment.', 'Pull the bar up toward your torso, driving the elbows back, then lower under control.', 'Standing up out of the hinge to help the pull. Keep the hip hinge locked in and let the back do the work.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Upper Back', '{"Lats","Biceps"}'
where not exists (select 1 from exercises where name = 'Landmine Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Chest-Supported T-Bar Row', 'Pull', 'back', '{"Lats","Biceps","Rear Delts"}', 'Machine',
  'Lie chest-down on the T-bar row''s support pad, grip the handles, arms extended toward the weight.', 'Pull the handles up toward your torso, squeezing the shoulder blades, then lower under control.', 'Not setting the pad height correctly, forcing an awkward reach. Adjust it so your arms start fully extended without rounding your back to reach the handles.',
  'compound', NULL,
  'lats', '{"biceps","delts"}',
  '{}', 'weight_reps', 'Upper Back', '{"Lats","Biceps","Rear Delts"}'
where not exists (select 1 from exercises where name = 'Chest-Supported T-Bar Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Machine Row (Seated)', 'Pull', 'back', '{"Upper Back","Biceps"}', 'Machine',
  'Sit with chest against the pad, grip the handles at a comfortable width, arms extended.', 'Pull the handles back toward your torso, squeezing the shoulder blades together, then return under control.', 'Pulling with the arms before the back engages. Lead the pull with your elbows and shoulder blades, not your hands.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{"Seated Row Machine"}', 'weight_reps', 'Lats', '{"Upper Back","Biceps"}'
where not exists (select 1 from exercises where name = 'Machine Row (Seated)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Machine Row (Chest-Supported)', 'Pull', 'back', '{"Lats","Biceps","Rear Delts"}', 'Machine',
  'Sit or kneel with your chest against the pad, grip the handles, arms extended.', 'Pull the handles back toward your torso, squeezing the shoulder blades together, then return under control.', 'Letting the chest come off the pad to generate extra pull. Keep it pinned — that''s what isolates the back instead of letting the hips help.',
  'compound', NULL,
  'lats', '{"biceps","delts"}',
  '{"Chest-Supported Machine Row"}', 'weight_reps', 'Upper Back', '{"Lats","Biceps","Rear Delts"}'
where not exists (select 1 from exercises where name = 'Machine Row (Chest-Supported)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'High Row Machine', 'Pull', 'back', '{"Upper Back","Biceps"}', 'Machine',
  'Sit with chest against the pad, grip the handles above shoulder height, arms extended forward and up.', 'Pull the handles back and down toward your upper chest, then return under control.', 'Shrugging the shoulders toward the ears during the pull. Keep them depressed so the lats and upper back do the work, not the traps.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{"Hammer Strength High Row"}', 'weight_reps', 'Lats', '{"Upper Back","Biceps"}'
where not exists (select 1 from exercises where name = 'High Row Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Iso-Lateral Low Row Machine', 'Pull', 'back', '{"Upper Back","Biceps"}', 'Machine',
  'Sit or kneel against the chest pad, grip each handle independently at a low angle, arms extended.', 'Pull each handle back toward your hip, letting each side move independently, then return under control.', 'Letting one side lag and do less work. Since each arm moves independently, consciously match the effort and range on both sides.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{"Hammer Strength Low Row"}', 'weight_reps', 'Lats', '{"Upper Back","Biceps"}'
where not exists (select 1 from exercises where name = 'Iso-Lateral Low Row Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Wide-Grip Seated Cable Row', 'Pull', 'back', '{"Lats","Rear Delts","Biceps"}', 'Cable',
  'Sit at a low pulley row station, grip a wide bar with an overhand grip, knees slightly bent.', 'Pull the bar to your upper abdomen, elbows flaring out and back, then return under control.', 'Rounding the lower back to extend the pull range. Keep a neutral spine and let the shoulder blades, not the lower back, create the range.',
  'compound', NULL,
  'lats', '{"delts","biceps"}',
  '{}', 'weight_reps', 'Upper Back', '{"Lats","Rear Delts","Biceps"}'
where not exists (select 1 from exercises where name = 'Wide-Grip Seated Cable Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Arm Cable Row', 'Pull', 'back', '{"Upper Back","Biceps"}', 'Cable',
  'Set the pulley at chest height, sit or stand with one hand on the handle, torso braced.', 'Pull the handle to your ribs while driving the elbow back, resisting torso rotation, then return under control.', 'Letting the torso rotate toward the working side to help the pull. Brace the core and keep the shoulders square the whole rep.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Upper Back","Biceps"}'
where not exists (select 1 from exercises where name = 'Single-Arm Cable Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Close-Grip Lat Pulldown', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Cable',
  'Grip a V-bar or close handles with palms facing each other, arms extended overhead.', 'Pull the handles down to your upper chest, driving the elbows down and back, then return under control.', 'Leaning back excessively to use body weight. A slight lean is fine, but don''t turn it into a swinging row — keep the pull controlled.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Close-Grip Lat Pulldown');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Neutral-Grip Lat Pulldown', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Cable',
  'Grip neutral (palms-facing) handles shoulder-width apart, arms extended overhead.', 'Pull the handles down to your upper chest, elbows tracking down and slightly forward, then return under control.', 'Pulling the handles too far down toward your stomach. Stop around upper-chest height — overshooting just adds momentum, not muscle work.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Neutral-Grip Lat Pulldown');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Underhand Lat Pulldown', 'Pull', 'back', '{"Biceps"}', 'Cable',
  'Grip the bar underhand (supinated), hands shoulder-width apart, arms extended overhead.', 'Pull the bar down to your upper chest, driving the elbows down and back, then return under control.', 'Letting the underhand grip turn this into a biceps curl. Initiate the pull with the elbows and back, with the biceps assisting, not leading.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{"Reverse-Grip Pulldown"}', 'weight_reps', 'Lats', '{"Biceps"}'
where not exists (select 1 from exercises where name = 'Underhand Lat Pulldown');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Arm Lat Pulldown', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Cable',
  'Attach a single handle to the high pulley, grip with one hand, the other braced on your thigh or the frame.', 'Pull the handle down toward your hip on that side, then return under control before switching arms.', 'Letting the torso twist to generate pulling force. Keep your shoulders square and isolate the pull to the working arm and lat.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Single-Arm Lat Pulldown');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Plate-Loaded Pulldown Machine', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Machine',
  'Adjust the knee pad and seat so you''re locked in, grip the handles with arms extended overhead.', 'Pull the handles down to your upper chest, then return under control to full stretch.', 'Using too much weight and only completing a partial range. Dial the plates back until you can get the full stretch-to-contraction range.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Plate-Loaded Pulldown Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Neutral-Grip Pull-Up', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Bodyweight',
  'Grip parallel, palms-facing handles (or a neutral-grip bar) with arms fully extended, hanging freely.', 'Pull your chin above the handles by driving the elbows down, then lower under control to full extension.', 'Using a kipping swing to get over the bar. Keep the movement strict and controlled unless you''re deliberately training the kipping version.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'bodyweight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Neutral-Grip Pull-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Wide-Grip Pull-Up', 'Pull', 'back', '{"Upper Back","Biceps"}', 'Bodyweight',
  'Grip a bar wider than shoulder width, arms fully extended, hanging freely.', 'Pull your chest toward the bar, driving the elbows out and down, then lower under control.', 'Only pulling halfway up because the wide grip limits range. If you can''t get your chin over the bar, narrow the grip until you can complete full reps.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'bodyweight_reps', 'Lats', '{"Upper Back","Biceps"}'
where not exists (select 1 from exercises where name = 'Wide-Grip Pull-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Weighted Pull-Up', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Bodyweight',
  'Attach a weight belt or hold a dumbbell between your feet, then grip the bar with arms fully extended.', 'Pull your chin over the bar under control, then lower back to full extension.', 'Adding weight before bodyweight pull-ups are clean and controlled. Build a strict bodyweight base first — added load just amplifies any form breakdown.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Weighted Pull-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Assisted Pull-Up Machine', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Machine',
  'Kneel or stand on the assist platform, grip the bar, and set the assist weight so you can complete your target reps with control.', 'Pull your chin above the bar, then lower under control to full extension.', 'Relying on the assist platform''s bounce at the bottom. Control the descent fully — the eccentric is where a lot of the pulling strength is built.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{"Assisted Pull-Up"}', 'weight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Assisted Pull-Up Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Band-Assisted Pull-Up', 'Pull', 'back', '{"Biceps","Upper Back"}', 'Band',
  'Loop a resistance band around the bar and under one foot or knee, then grip the bar with arms extended.', 'Pull your chin above the bar, then lower under control to full extension.', 'Using a band so thick it removes all the challenge. Size the band down over time so you''re still doing real work, not just riding the band.',
  'compound', NULL,
  'lats', '{"biceps"}',
  '{}', 'bodyweight_reps', 'Lats', '{"Biceps","Upper Back"}'
where not exists (select 1 from exercises where name = 'Band-Assisted Pull-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Inverted Row', 'Pull', 'back', '{"Lats","Biceps","Rear Delts"}', 'Bodyweight',
  'Set a bar at hip height, lie beneath it, grip it with hands shoulder-width, body straight from head to heels.', 'Pull your chest up to the bar by driving the elbows back, then lower under control.', 'Letting the hips sag toward the floor. Keep the whole body braced in a straight line, the same way you would in a plank.',
  'compound', NULL,
  'lats', '{"biceps","delts"}',
  '{"Bodyweight Row"}', 'bodyweight_reps', 'Upper Back', '{"Lats","Biceps","Rear Delts"}'
where not exists (select 1 from exercises where name = 'Inverted Row');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Romanian Deadlift', 'Legs', 'hamstrings', '{"Glutes","Lower Back"}', 'Dumbbell',
  'Stand holding dumbbells in front of your thighs, feet hip-width apart, slight knee bend.', 'Hinge at the hips, pushing them back while lowering the dumbbells along your legs, then drive the hips forward to stand back up.', 'Bending the knees more to lower further. This is a hip-hinge movement — keep the knee bend fixed and let the hips do the traveling.',
  'compound', NULL,
  'hamstrings', '{"glutes","lowerback"}',
  '{"DB RDL"}', 'weight_reps', 'Hamstrings', '{"Glutes","Lower Back"}'
where not exists (select 1 from exercises where name = 'Dumbbell Romanian Deadlift');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Leg Romanian Deadlift', 'Legs', 'hamstrings', '{"Glutes","Lower Back","Abs"}', 'Dumbbell',
  'Stand on one leg holding a dumbbell in the opposite hand, slight bend in the standing knee.', 'Hinge forward at the hip while extending the free leg straight back for balance, then return to standing.', 'Rotating the hips open as you hinge. Keep both hip points square to the floor — rotation is usually a sign the hamstring flexibility or balance needs more work at a shallower range first.',
  'compound', NULL,
  'hamstrings', '{"glutes","lowerback","abs"}',
  '{"Single-Leg RDL"}', 'weight_reps', 'Hamstrings', '{"Glutes","Lower Back","Abs"}'
where not exists (select 1 from exercises where name = 'Single-Leg Romanian Deadlift');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Rack Pull', 'Pull', 'back', '{"Lower Back","Glutes","Hamstrings","Upper Back"}', 'Barbell',
  'Set safety pins or blocks so the bar sits just below or at knee height, grip the bar as you would a deadlift.', 'Drive through the floor to stand the bar up, locking out the hips, then lower back to the pins under control.', 'Treating it like a full deadlift and rounding the back to reach lower. The partial range is the point — keep the back flat and only move through the set range.',
  'compound', NULL,
  'traps', '{"lowerback","glutes","hamstrings","lats"}',
  '{}', 'weight_reps', 'Traps', '{"Lower Back","Glutes","Hamstrings","Upper Back"}'
where not exists (select 1 from exercises where name = 'Rack Pull');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Back Extension (45-Degree)', 'Core', 'core', '{"Glutes","Hamstrings"}', 'Bodyweight',
  'Position your hips on the pad of a 45-degree hyperextension bench, ankles secured, body forming a straight line.', 'Lower your torso forward under control to about 45°, then extend back up to a straight line without hyperextending.', 'Hyperextending past straight at the top. Stop when your body forms a straight line — going further just loads the spine without adding benefit.',
  'isolation', NULL,
  'lowerback', '{"glutes","hamstrings"}',
  '{"Hyperextension"}', 'bodyweight_reps', 'Lower Back', '{"Glutes","Hamstrings"}'
where not exists (select 1 from exercises where name = 'Back Extension (45-Degree)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Back Extension Machine', 'Core', 'core', '{"Glutes","Hamstrings"}', 'Machine',
  'Adjust the pad so it sits at your hip crease, secure your legs, torso upright to start.', 'Lower your torso forward under control, then extend back to the upright starting position.', 'Using momentum to snap back upright. Control both directions — the lowering phase is just as valuable as the extension.',
  'isolation', NULL,
  'lowerback', '{"glutes","hamstrings"}',
  '{}', 'weight_reps', 'Lower Back', '{"Glutes","Hamstrings"}'
where not exists (select 1 from exercises where name = 'Back Extension Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Reverse Hyperextension', 'Legs', 'glutes', '{"Lower Back","Hamstrings"}', 'Machine',
  'Lie face-down on a reverse hyper machine or bench, hips at the edge, legs hanging and secured to the lever.', 'Extend your legs back and up until they''re in line with your torso, then lower under control.', 'Using back hyperextension to assist the lift. Keep the torso still and let the glutes and hamstrings swing the legs.',
  'isolation', NULL,
  'glutes', '{"lowerback","hamstrings"}',
  '{"Reverse Hyper"}', 'weight_reps', 'Glutes', '{"Lower Back","Hamstrings"}'
where not exists (select 1 from exercises where name = 'Reverse Hyperextension');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Rear Delt Fly', 'Pull', 'shoulders', '{"Upper Back"}', 'Cable',
  'Set both pulleys at chest height, cross the cables, and grip the opposite-side handle with each hand.', 'Pull your arms out and back in a wide arc until they''re in line with your torso, then return under control.', 'Bending the elbows more to turn it into a row. Keep a slight, fixed elbow bend and let the rear delts drive the arc, not the back.',
  'isolation', NULL,
  'delts', '{"lats"}',
  '{}', 'weight_reps', 'Rear Delts', '{"Upper Back"}'
where not exists (select 1 from exercises where name = 'Cable Rear Delt Fly');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Shrug', 'Pull', 'back', '{"Forearms"}', 'Dumbbell',
  'Stand holding dumbbells at your sides, arms straight, shoulders relaxed.', 'Elevate your shoulders straight up toward your ears, pause briefly, then lower under control.', 'Rolling the shoulders forward or backward during the lift. Keep the motion a straight vertical shrug — rolling adds nothing and can irritate the shoulder joint.',
  'isolation', NULL,
  'traps', '{"forearms"}',
  '{}', 'weight_reps', 'Traps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Dumbbell Shrug');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Shrug', 'Pull', 'back', '{"Forearms"}', 'Smith Machine',
  'Stand under the Smith bar with it resting at arm''s length against your thighs, grip just outside hip width.', 'Elevate your shoulders straight up, pause, then lower under control.', 'Bending the elbows to help lift the bar. Keep the arms straight — the traps should be the only thing moving the weight.',
  'isolation', NULL,
  'traps', '{"forearms"}',
  '{}', 'weight_reps', 'Traps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Smith Machine Shrug');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Machine Shrug', 'Pull', 'back', '{"Forearms"}', 'Machine',
  'Stand or sit at the shrug machine, grip the handles with arms extended down.', 'Elevate your shoulders straight up against the resistance, pause, then lower under control.', 'Using the legs to help drive the weight up. Isolate the movement to the shoulders — let the traps do the full work the machine is set up for.',
  'isolation', NULL,
  'traps', '{"forearms"}',
  '{}', 'weight_reps', 'Traps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Machine Shrug');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Shrug', 'Pull', 'back', '{"Forearms"}', 'Cable',
  'Stand over a low pulley with a straight bar or handle attachment, arms extended down in front of or beside you.', 'Elevate your shoulders straight up toward your ears, pause, then lower under control.', 'Letting the cable''s angle pull your arms forward or back out of a natural shrug path. Stand close enough to the pulley that the pull stays vertical.',
  'isolation', NULL,
  'traps', '{"forearms"}',
  '{}', 'weight_reps', 'Traps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Cable Shrug');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Upright Row (Cable)', 'Push', 'shoulders', '{"Traps","Biceps"}', 'Cable',
  'Stand facing a low pulley with a straight bar attached, grip just inside shoulder width, arms extended down.', 'Pull the bar straight up along your torso to about chest height, leading with the elbows, then lower under control.', 'Pulling the bar too high, past shoulder height. Stop around chest/collarbone height to keep the stress on the delts and traps, not the shoulder joint.',
  'compound', NULL,
  'delts', '{"traps","biceps"}',
  '{}', 'weight_reps', 'Side Delts', '{"Traps","Biceps"}'
where not exists (select 1 from exercises where name = 'Upright Row (Cable)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Seated Barbell Overhead Press', 'Push', 'shoulders', '{"Side Delts","Triceps"}', 'Barbell',
  'Sit on a bench with back support, barbell racked at shoulder height, grip just outside shoulder width.', 'Press the bar straight overhead until your arms lock out, then lower back to shoulder height.', 'Arching the lower back off the pad to get the bar overhead. If you can''t press without arching, the weight is too heavy for this seated, back-supported variation.',
  'compound', NULL,
  'delts', '{"triceps"}',
  '{}', 'weight_reps', 'Front Delts', '{"Side Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Seated Barbell Overhead Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Push Press', 'Push', 'shoulders', '{"Triceps","Side Delts","Quads"}', 'Barbell',
  'Set up as for a standing overhead press, bar racked at the shoulders, knees slightly bent.', 'Dip the knees slightly, then drive up through the legs while pressing the bar overhead in one continuous motion.', 'Turning it into a slow leg-drive-then-press in two separate phases. The dip and the press should blend into one fast, continuous motion.',
  'compound', NULL,
  'delts', '{"triceps","quads"}',
  '{}', 'weight_reps', 'Front Delts', '{"Triceps","Side Delts","Quads"}'
where not exists (select 1 from exercises where name = 'Push Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Shoulder Press (Standing)', 'Push', 'shoulders', '{"Side Delts","Triceps","Abs"}', 'Dumbbell',
  'Stand with feet hip-width apart, dumbbells at shoulder height, core braced.', 'Press the dumbbells overhead until your arms lock out, then lower back to shoulder height.', 'Leaning back excessively to press the weight up. Keep the ribs down and core tight — if you''re arching hard, the load is too heavy for standing strict form.',
  'compound', NULL,
  'delts', '{"triceps","abs"}',
  '{"Standing Dumbbell Press"}', 'weight_reps', 'Front Delts', '{"Side Delts","Triceps","Abs"}'
where not exists (select 1 from exercises where name = 'Dumbbell Shoulder Press (Standing)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Arm Dumbbell Press', 'Push', 'shoulders', '{"Side Delts","Triceps","Obliques"}', 'Dumbbell',
  'Stand or sit with one dumbbell at shoulder height, the other arm relaxed or braced on your hip.', 'Press the dumbbell overhead to full extension while resisting side-bending, then lower under control.', 'Letting the torso lean away from the working side. Brace your obliques on the non-working side to keep the spine neutral.',
  'compound', NULL,
  'delts', '{"triceps","obliques"}',
  '{}', 'weight_reps', 'Front Delts', '{"Side Delts","Triceps","Obliques"}'
where not exists (select 1 from exercises where name = 'Single-Arm Dumbbell Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Shoulder Press Machine', 'Push', 'shoulders', '{"Side Delts","Triceps"}', 'Machine',
  'Adjust the seat so the handles start at shoulder height, back flat against the pad.', 'Press the handles up until your arms are extended but not locked, then return under control.', 'Letting the seat height put the handles too low, turning the first inches into a shrug. Set the seat so the handles start level with your shoulders.',
  'compound', NULL,
  'delts', '{"triceps"}',
  '{"Machine Shoulder Press"}', 'weight_reps', 'Front Delts', '{"Side Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Shoulder Press Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Shoulder Press', 'Push', 'shoulders', '{"Side Delts","Triceps"}', 'Smith Machine',
  'Sit on a bench under the Smith bar, unrack it at shoulder height, grip just outside shoulder width.', 'Press the bar up along the fixed vertical path to near lockout, then lower back to shoulder height.', 'Positioning the bench too far forward or back for the fixed bar path. Adjust your seat position first so the vertical path matches your natural press line.',
  'compound', NULL,
  'delts', '{"triceps"}',
  '{}', 'weight_reps', 'Front Delts', '{"Side Delts","Triceps"}'
where not exists (select 1 from exercises where name = 'Smith Machine Shoulder Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Kettlebell Overhead Press', 'Push', 'shoulders', '{"Side Delts","Triceps","Abs"}', 'Kettlebell',
  'Clean a kettlebell to your shoulder (rack position), forearm vertical, elbow tucked.', 'Press the kettlebell straight overhead until your arm locks out, then lower back to the rack position.', 'Letting the kettlebell drift away from your forearm line, forcing a wrist bend. Keep the bell stacked directly over your forearm through the whole press.',
  'compound', NULL,
  'delts', '{"triceps","abs"}',
  '{}', 'weight_reps', 'Front Delts', '{"Side Delts","Triceps","Abs"}'
where not exists (select 1 from exercises where name = 'Kettlebell Overhead Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Pike Push-Up', 'Push', 'shoulders', '{"Triceps","Side Delts"}', 'Bodyweight',
  'Start in a downward-dog position, hips high, hands and feet on the floor, forming an inverted V.', 'Bend your elbows to lower the top of your head toward the floor between your hands, then press back up.', 'Letting the hips drop during the press, turning it back into a regular push-up. Keep the hips high throughout to keep the shoulder emphasis.',
  'compound', NULL,
  'delts', '{"triceps"}',
  '{}', 'bodyweight_reps', 'Front Delts', '{"Triceps","Side Delts"}'
where not exists (select 1 from exercises where name = 'Pike Push-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Handstand Push-Up', 'Push', 'shoulders', '{"Triceps","Side Delts","Traps"}', 'Bodyweight',
  'Kick up into a handstand against a wall, hands shoulder-width apart, body stacked straight.', 'Lower your head toward the floor under control by bending the elbows, then press back up to full lockout.', 'Losing core and glute tightness partway down, causing the lower back to arch. Keep the whole body braced like a plank, just upside down.',
  'compound', NULL,
  'delts', '{"triceps","traps"}',
  '{"HSPU"}', 'bodyweight_reps', 'Front Delts', '{"Triceps","Side Delts","Traps"}'
where not exists (select 1 from exercises where name = 'Handstand Push-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Arm Cable Lateral Raise', 'Push', 'shoulders', '{"Traps"}', 'Cable',
  'Stand side-on to a low pulley, grip the handle with the far hand across your body, arm extended down.', 'Raise your arm out to the side to about shoulder height, then lower under control before switching sides.', 'Shrugging the shoulder up to assist the raise. Keep it down and relaxed — the side delt should be doing the lifting, not the traps.',
  'isolation', NULL,
  'delts', '{"traps"}',
  '{}', 'weight_reps', 'Side Delts', '{"Traps"}'
where not exists (select 1 from exercises where name = 'Single-Arm Cable Lateral Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Machine Lateral Raise', 'Push', 'shoulders', '{"Traps"}', 'Machine',
  'Sit in the machine with the pads against your upper arms, elbows slightly bent.', 'Raise your arms out to shoulder height by pressing against the pads, then lower under control.', 'Using momentum from the hips or torso to kick the weight up. Keep the lift slow and controlled — the machine removes the need for any body English.',
  'isolation', NULL,
  'delts', '{"traps"}',
  '{}', 'weight_reps', 'Side Delts', '{"Traps"}'
where not exists (select 1 from exercises where name = 'Machine Lateral Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Front Raise', 'Push', 'shoulders', '{"Side Delts"}', 'Cable',
  'Set the pulley low behind you, grip the handle with one or both hands in front of your thighs.', 'Raise your arm(s) forward to about shoulder height, keeping a slight elbow bend, then lower under control.', 'Using the hips to swing the weight up. Keep the movement slow and strict — the cable''s constant tension does the work, momentum shouldn''t.',
  'isolation', NULL,
  'delts', '{}',
  '{}', 'weight_reps', 'Front Delts', '{"Side Delts"}'
where not exists (select 1 from exercises where name = 'Cable Front Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Plate Front Raise', 'Push', 'shoulders', '{"Side Delts"}', 'Other',
  'Hold a weight plate with both hands at the edges, arms extended down in front of your thighs.', 'Raise the plate forward to about shoulder height, then lower under control.', 'Shrugging the shoulders up as the plate rises. Keep them down and back — the front delts should do the lifting, not the traps.',
  'isolation', NULL,
  'delts', '{}',
  '{}', 'weight_reps', 'Front Delts', '{"Side Delts"}'
where not exists (select 1 from exercises where name = 'Plate Front Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Incline Y Raise', 'Pull', 'shoulders', '{"Traps","Side Delts"}', 'Dumbbell',
  'Lie face-down on an incline bench, light dumbbells hanging straight down, thumbs pointed up.', 'Raise your arms up and out in a Y shape until roughly in line with your ears, then lower under control.', 'Using weight heavy enough to force the traps to take over. This exercise only works at light loads — if your shoulders shrug up, drop the weight.',
  'isolation', NULL,
  'delts', '{"traps"}',
  '{"Y Raise"}', 'weight_reps', 'Rear Delts', '{"Traps","Side Delts"}'
where not exists (select 1 from exercises where name = 'Incline Y Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cuban Press', 'Pull', 'shoulders', '{"Side Delts","Traps"}', 'Dumbbell',
  'Hold dumbbells at your sides with elbows bent 90° and raised to shoulder height, palms facing down.', 'Rotate your forearms up until they point to the ceiling, then press the dumbbells overhead, reversing the sequence to return.', 'Rushing through the rotation phase to get to the press. The external rotation is the whole point of this exercise — slow that part down even if you speed up the press.',
  'compound', NULL,
  'delts', '{"traps"}',
  '{}', 'weight_reps', 'Rear Delts', '{"Side Delts","Traps"}'
where not exists (select 1 from exercises where name = 'Cuban Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'EZ-Bar Curl', 'Pull', 'biceps', '{"Forearms"}', 'EZ Bar',
  'Stand holding an EZ-curl bar with an underhand grip on the angled portions, arms extended down.', 'Curl the bar up toward your shoulders by bending the elbows, then lower under control.', 'Swinging the hips to help the bar up. Keep the torso still — if you need hip momentum, the weight is too heavy for strict curls.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{"EZ Curl"}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'EZ-Bar Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cross-Body Hammer Curl', 'Pull', 'biceps', '{"Forearms"}', 'Dumbbell',
  'Stand holding a dumbbell at your side with a neutral grip, palm facing your thigh.', 'Curl the dumbbell up and across your body toward the opposite shoulder, then lower back along the same path.', 'Curling straight up instead of across the body. The diagonal path is what distinguishes this from a regular hammer curl — don''t skip it.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Cross-Body Hammer Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Preacher Curl Machine', 'Pull', 'biceps', '{"Forearms"}', 'Machine',
  'Sit with your upper arms resting on the preacher pad, grip the handles with arms extended.', 'Curl the handles up toward your shoulders, then lower under control to full extension.', 'Letting the upper arms lift off the pad at the top of the curl. Keep them pinned — that''s what removes momentum and isolates the biceps.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Preacher Curl Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Preacher Curl', 'Pull', 'biceps', '{"Forearms"}', 'Dumbbell',
  'Sit at a preacher bench, upper arm resting on the pad, dumbbell held with an underhand grip, arm extended.', 'Curl the dumbbell up toward your shoulder, then lower under control to full extension.', 'Letting the elbow lift off the pad near the top. Keep it pinned down the whole rep to keep the tension on the biceps instead of letting the shoulder help.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{"Single-Arm Preacher Curl"}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Dumbbell Preacher Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Bayesian Curl', 'Pull', 'biceps', '{"Forearms"}', 'Cable',
  'Stand facing away from a low cable pulley, arm extended behind your torso, slight forward lean.', 'Curl the handle up and forward toward your shoulder, then return under control to the stretched position behind you.', 'Standing too close to the pulley, losing the behind-the-body stretch that makes this variation valuable. Step forward enough to feel a real stretch at the bottom.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{"Behind-the-Body Cable Curl"}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Bayesian Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Curl (Single Arm)', 'Pull', 'biceps', '{"Forearms"}', 'Cable',
  'Stand facing a low pulley, grip the handle with an underhand grip, elbow at your side.', 'Curl the handle up toward your shoulder, then lower under control to full extension.', 'Letting the elbow drift forward away from your torso. Keep it pinned at your side so the biceps do the isolated work.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Cable Curl (Single Arm)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Machine Biceps Curl', 'Pull', 'biceps', '{"Forearms"}', 'Machine',
  'Sit with your upper arms resting on the machine''s pad, grip the handles with arms extended.', 'Curl the handles up toward your shoulders, then lower under control to full extension.', 'Rushing the eccentric (lowering) phase. Slow the return down — the machine''s fixed path makes it easy to just let gravity drop the weight instead of controlling it.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{"Biceps Curl Machine"}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Machine Biceps Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Zottman Curl', 'Pull', 'biceps', '{"Forearms"}', 'Dumbbell',
  'Stand holding dumbbells with an underhand grip, arms extended down.', 'Curl the dumbbells up with an underhand grip, rotate your wrists to an overhand grip at the top, then lower with that overhand grip before rotating back.', 'Skipping the wrist rotation and just doing a normal curl. The rotation is what loads the forearms on the way down — don''t shortcut it.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Zottman Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Drag Curl', 'Pull', 'biceps', '{"Forearms"}', 'Barbell',
  'Stand holding a barbell or EZ-bar with an underhand grip, arms extended down close to your torso.', 'Curl the bar up while dragging it along your torso, keeping the elbows traveling back rather than staying fixed, then lower the same way.', 'Curling the bar away from the body like a standard curl. Keep it brushing your torso and let the elbows drift back — that''s what shifts the emphasis onto the biceps'' peak contraction.',
  'isolation', NULL,
  'biceps', '{"forearms"}',
  '{}', 'weight_reps', 'Biceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Drag Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Reverse Curl', 'Pull', 'forearms', '{"Biceps"}', 'EZ Bar',
  'Stand holding a barbell or EZ-bar with an overhand (pronated) grip, arms extended down.', 'Curl the bar up toward your shoulders keeping the overhand grip, then lower under control.', 'Using lighter weight expectations like a normal curl, then swinging to compensate. The overhand grip makes this genuinely harder on the forearms/brachialis — drop the weight and keep it strict.',
  'isolation', NULL,
  'forearms', '{"biceps"}',
  '{"Reverse Barbell Curl"}', 'weight_reps', 'Forearms', '{"Biceps"}'
where not exists (select 1 from exercises where name = 'Reverse Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Triceps Pushdown (Rope)', 'Push', 'triceps', '{}', 'Cable',
  'Attach a rope to the high pulley, grip both ends with palms facing each other, elbows pinned to your sides.', 'Push the rope down until your arms are fully extended, spreading the rope ends apart slightly at the bottom, then return under control.', 'Letting the elbows drift forward away from the torso. Keep them locked at your sides so the triceps — not the shoulders — drive the movement.',
  'isolation', NULL,
  'triceps', '{}',
  '{"Rope Pushdown"}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Triceps Pushdown (Rope)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Triceps Pushdown (V-Bar)', 'Push', 'triceps', '{}', 'Cable',
  'Attach a V-bar to the high pulley, grip with palms facing each other, elbows pinned to your sides.', 'Push the bar down to full extension, then return under control without letting the elbows drift forward.', 'Using body weight to lean into the pushdown. Keep your torso upright and still — let the arms do all the work.',
  'isolation', NULL,
  'triceps', '{}',
  '{}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Triceps Pushdown (V-Bar)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Reverse-Grip Triceps Pushdown', 'Push', 'triceps', '{"Forearms"}', 'Cable',
  'Attach a straight bar to the high pulley, grip with palms facing up (underhand), elbows pinned to your sides.', 'Push the bar down to full extension, then return under control, keeping the underhand grip throughout.', 'Letting the wrists bend back under load. Keep them neutral and firm — the underhand grip changes elbow stress, so wrist control matters more here.',
  'isolation', NULL,
  'triceps', '{"forearms"}',
  '{"Underhand Pushdown"}', 'weight_reps', 'Triceps', '{"Forearms"}'
where not exists (select 1 from exercises where name = 'Reverse-Grip Triceps Pushdown');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Arm Triceps Pushdown', 'Push', 'triceps', '{}', 'Cable',
  'Attach a single handle to the high pulley, stand side-on, elbow pinned to your side.', 'Push the handle down to full extension on one side, then return under control before switching arms.', 'Letting the torso rotate to assist the push. Keep your shoulders square — this variation is meant to isolate each side without help from body English.',
  'isolation', NULL,
  'triceps', '{}',
  '{}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Single-Arm Triceps Pushdown');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Overhead Cable Triceps Extension', 'Push', 'triceps', '{}', 'Cable',
  'Attach a rope to a low pulley, face away from the machine, and raise the rope overhead with elbows pointing forward.', 'Extend your arms until your elbows are straight, then lower back down until your hands are behind your head.', 'Letting the elbows flare outward as you extend. Keep them pointed forward and close together through the whole range.',
  'isolation', NULL,
  'triceps', '{}',
  '{"Cable Overhead Extension"}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Overhead Cable Triceps Extension');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Skull Crusher', 'Push', 'triceps', '{}', 'Dumbbell',
  'Lie on a flat bench holding a dumbbell in each hand above your chest, palms facing each other.', 'Bend only at the elbows to lower the dumbbells toward your temples, then extend back up.', 'Letting the upper arms drift backward toward your face. Keep them vertical and still — only the forearms should move.',
  'isolation', NULL,
  'triceps', '{}',
  '{}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Dumbbell Skull Crusher');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'JM Press', 'Push', 'triceps', '{"Chest"}', 'Barbell',
  'Lie on a flat bench with a barbell above your chest, grip just inside shoulder width.', 'Lower the bar in a hybrid path toward your upper chest/neck by bending the elbows, then press back up to full extension.', 'Treating it exactly like a close-grip bench press. The bar path angles lower toward the neck, not straight down to the chest — that''s what makes it a hybrid skull-crusher/press.',
  'compound', NULL,
  'triceps', '{"chest"}',
  '{}', 'weight_reps', 'Triceps', '{"Chest"}'
where not exists (select 1 from exercises where name = 'JM Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Triceps Kickback', 'Push', 'triceps', '{}', 'Cable',
  'Set the pulley low, hinge forward at the hips, upper arm parallel to the floor and pinned at your side, elbow bent.', 'Extend your arm straight back until it''s fully locked out, then return under control.', 'Swinging the upper arm to generate momentum. Pin it in place — only the forearm should travel.',
  'isolation', NULL,
  'triceps', '{}',
  '{}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Cable Triceps Kickback');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Bench Dip', 'Push', 'triceps', '{"Chest","Front Delts"}', 'Bodyweight',
  'Sit on the edge of a bench, hands gripping the edge beside your hips, legs extended out in front of you.', 'Lower your hips toward the floor by bending the elbows, then press back up to full extension.', 'Letting the shoulders roll forward and down at the bottom. Keep the descent shallow enough that your shoulders stay in a safe, stable position.',
  'compound', NULL,
  'triceps', '{"chest","delts"}',
  '{}', 'bodyweight_reps', 'Triceps', '{"Chest","Front Delts"}'
where not exists (select 1 from exercises where name = 'Bench Dip');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Triceps Extension Machine', 'Push', 'triceps', '{}', 'Machine',
  'Adjust the seat so your elbows line up with the machine''s pivot point, grip the handles with upper arms against the pads.', 'Extend your arms fully against the resistance, then return under control to the starting bend.', 'Letting the upper arms lift off the pads to help the extension. Keep them pinned — that''s what isolates the triceps instead of the shoulders.',
  'isolation', NULL,
  'triceps', '{}',
  '{}', 'weight_reps', 'Triceps', '{}'
where not exists (select 1 from exercises where name = 'Triceps Extension Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dip Machine', 'Push', 'triceps', '{"Chest"}', 'Machine',
  'Grip the handles with your arms set at the machine''s starting position, torso upright or slightly forward-leaning.', 'Press down until your arms are extended, then return under control to the starting bend.', 'Leaning too far forward, turning it into more of a chest press. Stay more upright if you want the triceps emphasis this variation is for.',
  'compound', NULL,
  'triceps', '{"chest"}',
  '{}', 'weight_reps', 'Triceps', '{"Chest"}'
where not exists (select 1 from exercises where name = 'Dip Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Wrist Curl', 'Pull', 'forearms', '{}', 'Dumbbell',
  'Sit holding a barbell or dumbbells with an underhand grip, forearms resting on your thighs or a bench, wrists just past your knees.', 'Curl your wrists up by flexing them, then lower under control to let the wrists extend back down.', 'Using the whole forearm to swing the weight instead of isolating the wrist joint. Keep the forearms still and let only the wrist hinge move.',
  'isolation', NULL,
  'forearms', '{}',
  '{}', 'weight_reps', 'Forearms', '{}'
where not exists (select 1 from exercises where name = 'Wrist Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Reverse Wrist Curl', 'Pull', 'forearms', '{}', 'Dumbbell',
  'Sit holding a barbell or dumbbells with an overhand grip, forearms resting on your thighs or a bench.', 'Extend your wrists up by lifting the back of your hands, then lower under control.', 'Using too much weight, since this movement is much weaker than a regular wrist curl. Start lighter than you''d expect — the wrist extensors are a small muscle group.',
  'isolation', NULL,
  'forearms', '{}',
  '{}', 'weight_reps', 'Forearms', '{}'
where not exists (select 1 from exercises where name = 'Reverse Wrist Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Barbell Wrist Curl', 'Pull', 'forearms', '{}', 'Barbell',
  'Sit holding a barbell with an underhand grip, forearms resting on your thighs, wrists just past your knees.', 'Curl your wrists up by flexing them, then lower under control to full wrist extension.', 'Gripping the bar so tight that the forearm flexors take over from the wrist flexors doing isolated work. Use a grip firm enough to hold the bar, not a death grip.',
  'isolation', NULL,
  'forearms', '{}',
  '{}', 'weight_reps', 'Forearms', '{}'
where not exists (select 1 from exercises where name = 'Barbell Wrist Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dead Hang', 'Pull', 'forearms', '{"Lats","Upper Back"}', 'Bodyweight',
  'Grip a pull-up bar with hands shoulder-width or slightly wider, feet off the ground.', 'Hang with arms fully extended, shoulders relaxed down away from the ears, for the target duration.', 'Shrugging the shoulders up toward the ears to take tension off the grip. Let the shoulders hang passively — that''s part of what this exercise is meant to train.',
  'isolation', NULL,
  'forearms', '{"lats"}',
  '{"Bar Hang"}', 'time', 'Forearms', '{"Lats","Upper Back"}'
where not exists (select 1 from exercises where name = 'Dead Hang');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Squat', 'Legs', 'quads', '{"Glutes","Adductors"}', 'Smith Machine',
  'Position the bar across your upper back under the Smith machine, feet set slightly forward of the bar''s fixed vertical path.', 'Squat down until your thighs are at least parallel to the floor, then drive back up along the fixed path.', 'Keeping your feet directly under the bar like a free-weight squat. Because the path is fixed vertical, step your feet slightly forward so the descent doesn''t push your knees too far over your toes.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{}', 'weight_reps', 'Quads', '{"Glutes","Adductors"}'
where not exists (select 1 from exercises where name = 'Smith Machine Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Hack Squat Machine', 'Legs', 'quads', '{"Glutes","Adductors"}', 'Machine',
  'Position your shoulders and back against the pads, feet shoulder-width on the platform.', 'Bend your knees to lower the platform until your thighs are at least parallel, then press back up.', 'Letting the knees cave inward as you press up. Keep them tracking in line with your feet throughout the whole range.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{"Hack Squat"}', 'weight_reps', 'Quads', '{"Glutes","Adductors"}'
where not exists (select 1 from exercises where name = 'Hack Squat Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Pendulum Squat', 'Legs', 'quads', '{"Glutes"}', 'Machine',
  'Position your shoulders under the pads, feet shoulder-width on the platform, following the machine''s arcing path.', 'Bend your knees to lower along the arc until your thighs are at least parallel, then press back up.', 'Fighting the machine''s natural arc with your own path. Let your body follow the pendulum''s arc rather than trying to move in a straight line.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{}', 'weight_reps', 'Quads', '{"Glutes"}'
where not exists (select 1 from exercises where name = 'Pendulum Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Belt Squat', 'Legs', 'quads', '{"Glutes","Adductors"}', 'Machine',
  'Attach the belt around your hips, step onto the platform, feet shoulder-width apart.', 'Squat down until your thighs are at least parallel to the floor, then stand back up, with the load pulling only on your hips.', 'Rounding the upper back since there''s no bar on it to keep you honest. Keep the same upright, braced torso you''d use in a back squat.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{}', 'weight_reps', 'Quads', '{"Glutes","Adductors"}'
where not exists (select 1 from exercises where name = 'Belt Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Horizontal Leg Press', 'Legs', 'quads', '{"Glutes","Adductors"}', 'Machine',
  'Sit in the horizontal leg press with your back against the pad, feet shoulder-width on the platform.', 'Push the platform away until your legs are extended but not locked, then return under control.', 'Locking the knees out hard at the top of every rep. Stop just short of lockout to keep tension on the quads instead of resting on the joint.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{"Seated Leg Press"}', 'weight_reps', 'Quads', '{"Glutes","Adductors"}'
where not exists (select 1 from exercises where name = 'Horizontal Leg Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Leg Leg Press', 'Legs', 'quads', '{"Glutes"}', 'Machine',
  'Sit in the leg press with one foot centered on the platform, the other foot off to the side or braced.', 'Push the platform away with the working leg until nearly extended, then return under control.', 'Letting the knee drift inward under the single-leg load. Keep it tracking in line with your foot the whole rep.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{}', 'weight_reps', 'Quads', '{"Glutes"}'
where not exists (select 1 from exercises where name = 'Single-Leg Leg Press');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Split Squat', 'Legs', 'quads', '{"Glutes","Adductors"}', 'Dumbbell',
  'Take a long split stance, front foot flat, back heel raised, torso upright.', 'Lower your back knee toward the floor by bending both knees, then push back up through the front heel.', 'Taking too short a stance, forcing the front knee way out past the toes. Lengthen the stance until the front shin stays close to vertical at the bottom.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{}', 'weight_reps', 'Quads', '{"Glutes","Adductors"}'
where not exists (select 1 from exercises where name = 'Split Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Forward Lunge', 'Legs', 'quads', '{"Glutes","Hamstrings"}', 'Dumbbell',
  'Stand tall, feet together, core braced.', 'Step forward into a lunge, lowering your back knee toward the floor, then push back off the front foot to return to standing.', 'Letting the front knee cave inward or shoot past the toes. Step far enough forward that the front shin stays close to vertical at the bottom.',
  'compound', NULL,
  'quads', '{"glutes","hamstrings"}',
  '{}', 'weight_reps', 'Quads', '{"Glutes","Hamstrings"}'
where not exists (select 1 from exercises where name = 'Forward Lunge');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Lateral Lunge', 'Legs', 'quads', '{"Quads","Glutes"}', 'Dumbbell',
  'Stand with feet together, core braced.', 'Step one foot out to the side, bending that knee and pushing your hips back while the other leg stays straight, then push off to return to standing.', 'Letting the bending knee cave inward. Push it out in line with that foot, and keep the straight leg''s foot flat to feel the stretch through the inner thigh.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{"Side Lunge"}', 'weight_reps', 'Adductors', '{"Quads","Glutes"}'
where not exists (select 1 from exercises where name = 'Lateral Lunge');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cossack Squat', 'Legs', 'quads', '{"Quads","Glutes"}', 'Bodyweight',
  'Take a wide stance, toes turned slightly out.', 'Shift your weight to one side, bending that knee deeply while the other leg stays straight with the heel lifted, then push back to center and repeat on the other side.', 'Letting the straight leg''s knee twist instead of staying long and stable. Keep that leg fully extended and let the hip, not the knee, absorb the stretch.',
  'compound', NULL,
  'quads', '{"glutes"}',
  '{}', 'bodyweight_reps', 'Adductors', '{"Quads","Glutes"}'
where not exists (select 1 from exercises where name = 'Cossack Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Sissy Squat', 'Legs', 'quads', '{}', 'Bodyweight',
  'Hold onto a stable support, rise onto your toes, and lean back slightly with knees pointed forward.', 'Lower your torso back while bending the knees deeply, keeping a straight line from knees to shoulders, then rise back up.', 'Bending at the hips instead of leaning back from the knees. Keep the torso and thighs in one straight line — this is a knee-dominant, not hip-dominant, movement.',
  'isolation', NULL,
  'quads', '{}',
  '{}', 'bodyweight_reps', 'Quads', '{}'
where not exists (select 1 from exercises where name = 'Sissy Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Bodyweight Squat', 'Legs', 'quads', '{"Glutes","Abs"}', 'Bodyweight',
  'Stand with feet shoulder-width apart, toes slightly out, arms extended forward or crossed at the chest.', 'Bend your knees and hips to squat down until your thighs are at least parallel, then stand back up.', 'Letting the heels lift off the floor. Keep weight through the whole foot — if your heels keep rising, work on ankle mobility before adding load.',
  'compound', NULL,
  'quads', '{"glutes","abs"}',
  '{"Air Squat"}', 'bodyweight_reps', 'Quads', '{"Glutes","Abs"}'
where not exists (select 1 from exercises where name = 'Bodyweight Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Pistol Squat', 'Legs', 'quads', '{"Glutes","Abs"}', 'Bodyweight',
  'Stand on one leg, extend the other leg straight out in front of you, arms forward for counterbalance.', 'Lower yourself down on the standing leg until your hips are below knee height, then press back up to standing.', 'Letting the standing knee cave inward near the bottom. Actively push the knee out in line with your foot — losing that alignment is the most common pistol squat failure point.',
  'compound', NULL,
  'quads', '{"glutes","abs"}',
  '{"Single-Leg Squat"}', 'bodyweight_reps', 'Quads', '{"Glutes","Abs"}'
where not exists (select 1 from exercises where name = 'Pistol Squat');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Wall Sit', 'Legs', 'quads', '{"Glutes"}', 'Bodyweight',
  'Lean your back against a wall, slide down until your thighs are roughly parallel to the floor, feet shoulder-width apart.', 'Hold the position for the target duration, keeping your back flat against the wall and knees over your ankles.', 'Letting the knees drift forward past the toes. Walk the feet out further from the wall until the knee stays stacked over the ankle.',
  'isolation', NULL,
  'quads', '{"glutes"}',
  '{}', 'time', 'Quads', '{"Glutes"}'
where not exists (select 1 from exercises where name = 'Wall Sit');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Leg Extension', 'Legs', 'quads', '{}', 'Machine',
  'Sit at a leg extension machine with the pad against one shin, hands gripping the side handles for stability.', 'Extend that leg until straight, then lower under control before switching legs.', 'Using momentum to kick the weight up. Keep the movement slow and controlled on both the lift and the return.',
  'isolation', NULL,
  'quads', '{}',
  '{}', 'weight_reps', 'Quads', '{}'
where not exists (select 1 from exercises where name = 'Single-Leg Extension');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Standing Leg Curl', 'Legs', 'hamstrings', '{}', 'Machine',
  'Stand at a standing leg curl machine, back brace against the pad, ankle against the lower roller pad.', 'Curl your heel up toward your glute by bending the knee, then lower under control.', 'Letting the hips rotate or the standing leg lose its brace. Keep the pelvis square and stable so the hamstring does the isolated work.',
  'isolation', NULL,
  'hamstrings', '{}',
  '{"Single-Leg Curl"}', 'weight_reps', 'Hamstrings', '{}'
where not exists (select 1 from exercises where name = 'Standing Leg Curl');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Glute-Ham Raise', 'Legs', 'hamstrings', '{"Glutes","Lower Back"}', 'Bodyweight',
  'Set your feet against the footplate of a GHD, knees on the pad, torso upright and braced.', 'Lower your torso forward under control by letting the knees extend slightly, then pull yourself back up using the hamstrings.', 'Using the hip flexors to yank back up instead of the hamstrings. Think about pulling your heels down into the pad as you rise.',
  'compound', NULL,
  'hamstrings', '{"glutes","lowerback"}',
  '{"GHR"}', 'bodyweight_reps', 'Hamstrings', '{"Glutes","Lower Back"}'
where not exists (select 1 from exercises where name = 'Glute-Ham Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Hip Thrust Machine', 'Legs', 'glutes', '{"Hamstrings"}', 'Machine',
  'Sit against the machine''s pad with the pad across your hips, feet planted, knees bent.', 'Drive your hips up by extending through them, squeezing the glutes at the top, then lower under control.', 'Pushing through the toes and extending the knees to help. Keep the push driven by the hips, not by straightening the legs.',
  'compound', NULL,
  'glutes', '{"hamstrings"}',
  '{}', 'weight_reps', 'Glutes', '{"Hamstrings"}'
where not exists (select 1 from exercises where name = 'Hip Thrust Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Leg Hip Thrust', 'Legs', 'glutes', '{"Hamstrings"}', 'Bodyweight',
  'Set up as a standard hip thrust with shoulders on a bench, then lift one foot off the ground, extending that leg.', 'Drive through the planted heel to extend the hips, squeezing the glute at the top, then lower under control.', 'Letting the hips rotate toward the lifted leg. Keep both hip points level — rotation means the working glute isn''t doing all the work it should.',
  'compound', NULL,
  'glutes', '{"hamstrings"}',
  '{}', 'bodyweight_reps', 'Glutes', '{"Hamstrings"}'
where not exists (select 1 from exercises where name = 'Single-Leg Hip Thrust');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Pull-Through', 'Legs', 'glutes', '{"Hamstrings","Lower Back"}', 'Cable',
  'Face away from a low pulley, straddle the cable, hinge forward to grip the rope between your legs.', 'Drive your hips forward to stand up, squeezing the glutes at the top, then hinge back down under control.', 'Turning it into a squat by bending the knees heavily. Keep the knees softly bent and let the hip hinge do almost all the work.',
  'compound', NULL,
  'glutes', '{"hamstrings","lowerback"}',
  '{}', 'weight_reps', 'Glutes', '{"Hamstrings","Lower Back"}'
where not exists (select 1 from exercises where name = 'Cable Pull-Through');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Glute Kickback Machine', 'Legs', 'glutes', '{"Hamstrings"}', 'Machine',
  'Position yourself in the machine with one foot on the platform/pad, torso braced on the support.', 'Extend your leg back by driving through the glute, then return under control.', 'Arching the lower back to add range. Keep the torso braced and stop the movement where the lower back would otherwise start to take over.',
  'isolation', NULL,
  'glutes', '{"hamstrings"}',
  '{}', 'weight_reps', 'Glutes', '{"Hamstrings"}'
where not exists (select 1 from exercises where name = 'Glute Kickback Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Donkey Kick', 'Legs', 'glutes', '{"Hamstrings"}', 'Bodyweight',
  'Start on hands and knees, one knee bent at 90°, core braced.', 'Drive that foot up toward the ceiling by extending through the hip, squeezing the glute, then lower under control.', 'Arching the lower back to kick higher. Keep the range limited to what the hip alone can produce without the spine moving.',
  'isolation', NULL,
  'glutes', '{"hamstrings"}',
  '{}', 'bodyweight_reps', 'Glutes', '{"Hamstrings"}'
where not exists (select 1 from exercises where name = 'Donkey Kick');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Banded Lateral Walk', 'Legs', 'glutes', '{"Glutes"}', 'Band',
  'Place a resistance band around your ankles or just above your knees, feet hip-width apart, slight squat position.', 'Step sideways, maintaining tension on the band and a slight squat, for the target number of steps, then repeat in the other direction.', 'Standing too tall and letting the steps get small. Stay low in the squat and take deliberate, controlled steps to keep constant band tension.',
  'isolation', NULL,
  'glutes', '{}',
  '{"Monster Walk"}', 'distance_time', 'Abductors', '{"Glutes"}'
where not exists (select 1 from exercises where name = 'Banded Lateral Walk');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Clamshell', 'Legs', 'glutes', '{"Glutes"}', 'Band',
  'Lie on your side with knees bent and stacked, feet together, hips stacked vertically.', 'Keeping your feet together, rotate your top knee open like a clamshell, then lower under control.', 'Rolling the hips backward to get more range. Keep the hips stacked and stationary — the movement should come only from the hip joint rotating.',
  'isolation', NULL,
  'glutes', '{}',
  '{}', 'bodyweight_reps', 'Abductors', '{"Glutes"}'
where not exists (select 1 from exercises where name = 'Clamshell');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select '45-Degree Hip Extension', 'Legs', 'glutes', '{"Hamstrings","Lower Back"}', 'Machine',
  'Position your hips on the pad of a 45-degree bench, legs straight, body forming a straight line, arms crossed or holding weight at the chest.', 'Lower your torso forward under control, then extend back up through the hips to a straight line.', 'Rounding through the lower back instead of hinging from the hips. Keep the spine neutral and let the hip joint be the only thing that moves.',
  'compound', NULL,
  'glutes', '{"hamstrings","lowerback"}',
  '{}', 'weight_reps', 'Glutes', '{"Hamstrings","Lower Back"}'
where not exists (select 1 from exercises where name = '45-Degree Hip Extension');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Smith Machine Calf Raise', 'Legs', 'calves', '{}', 'Smith Machine',
  'Position the bar across your upper back under the Smith machine, balls of your feet on a small block, heels free to drop.', 'Rise onto your toes as high as possible, pause, then lower your heels below the block for a full stretch.', 'Bouncing at the bottom instead of pausing. Let the stretch fully settle before driving back up — bouncing just uses elastic rebound instead of muscle contraction.',
  'isolation', NULL,
  'calves', '{}',
  '{}', 'weight_reps', 'Calves', '{}'
where not exists (select 1 from exercises where name = 'Smith Machine Calf Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Donkey Calf Raise', 'Legs', 'calves', '{}', 'Machine',
  'Hinge forward at the hips with support in front of you, balls of your feet on a raised platform, torso roughly parallel to the floor.', 'Rise onto your toes as high as possible, pause, then lower for a full stretch.', 'Rounding the back to compensate for the bent-over position. Keep the spine neutral — the hinge angle changes calf loading, not your spinal position rules.',
  'isolation', NULL,
  'calves', '{}',
  '{}', 'weight_reps', 'Calves', '{}'
where not exists (select 1 from exercises where name = 'Donkey Calf Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Single-Leg Calf Raise', 'Legs', 'calves', '{}', 'Bodyweight',
  'Stand on one foot on a raised edge or block, holding support if needed, other foot lifted.', 'Rise onto your toes as high as possible, pause, then lower under control for a full stretch.', 'Rushing through reps without full range. Pause at the top and let the heel drop fully at the bottom — single-leg calf work rewards strict tempo more than most exercises.',
  'isolation', NULL,
  'calves', '{}',
  '{}', 'bodyweight_reps', 'Calves', '{}'
where not exists (select 1 from exercises where name = 'Single-Leg Calf Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dumbbell Calf Raise', 'Legs', 'calves', '{}', 'Dumbbell',
  'Stand holding dumbbells at your sides, balls of your feet on a raised platform or block.', 'Rise onto your toes as high as possible, pause, then lower under control for a full stretch.', 'Letting the ankles roll in or out during the raise. Keep the motion straight up and down through a stable ankle.',
  'isolation', NULL,
  'calves', '{}',
  '{}', 'weight_reps', 'Calves', '{}'
where not exists (select 1 from exercises where name = 'Dumbbell Calf Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Tibialis Raise', 'Legs', 'calves', '{}', 'Bodyweight',
  'Lean your back against a wall or sit with heels on the floor, toes pointed up.', 'Lift your toes up toward your shins as high as possible, pause, then lower under control.', 'Treating it as a throwaway warm-up and rushing the reps. This small muscle responds well to slow, controlled tempo — don''t just flick through it.',
  'isolation', NULL,
  'calves', '{}',
  '{}', 'bodyweight_reps', 'Calves', '{}'
where not exists (select 1 from exercises where name = 'Tibialis Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Ab Crunch Machine', 'Core', 'core', '{}', 'Machine',
  'Sit with your chest against the pad (or hands on the handles above), hips stable against the seat.', 'Crunch forward by flexing your spine, squeezing the abs, then return under control.', 'Pulling with the arms on the handles instead of flexing the spine. Let the abs do the crunching — the handles are just there to brace, not to pull.',
  'isolation', NULL,
  'abs', '{}',
  '{}', 'weight_reps', 'Abs', '{}'
where not exists (select 1 from exercises where name = 'Ab Crunch Machine');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Crunch', 'Core', 'core', '{}', 'Bodyweight',
  'Lie on your back, knees bent, feet flat, hands lightly behind your head or crossed on your chest.', 'Curl your shoulders up off the floor by flexing your spine, then lower under control.', 'Pulling on the neck with your hands. Keep the hands light and let the abs do the lifting — your neck should just follow along passively.',
  'isolation', NULL,
  'abs', '{}',
  '{}', 'bodyweight_reps', 'Abs', '{}'
where not exists (select 1 from exercises where name = 'Crunch');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Reverse Crunch', 'Core', 'core', '{"Hip Flexors"}', 'Bodyweight',
  'Lie on your back, knees bent to 90°, shins roughly parallel to the floor, hands at your sides or under your lower back.', 'Curl your hips up off the floor by flexing through the lower abs, then lower under control.', 'Swinging the legs to generate momentum instead of curling the pelvis. Keep the knee angle fixed and focus on tilting the hips, not kicking the legs.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'Reverse Crunch');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Sit-Up', 'Core', 'core', '{"Hip Flexors"}', 'Bodyweight',
  'Lie on your back, knees bent, feet flat (anchored if needed), hands crossed on your chest or lightly behind your head.', 'Curl your torso all the way up until your chest nears your thighs, then lower back down under control.', 'Using momentum or a jerking motion to get up. Control both the lift and the lowering — the eccentric is where a lot of the ab work happens.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'Sit-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Decline Sit-Up', 'Core', 'core', '{"Hip Flexors"}', 'Bodyweight',
  'Secure your feet on a decline bench, torso starting flat along the bench, hands crossed on your chest.', 'Curl your torso up and forward until upright, then lower back down under control.', 'Letting the hip flexors do most of the work by swinging up fast. Slow the rep down and focus on the spine curling, not just the torso hinging at the hip.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'Decline Sit-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Weighted Crunch', 'Core', 'core', '{}', 'Other',
  'Lie on your back holding a plate or dumbbell against your chest, knees bent, feet flat.', 'Crunch your shoulders up off the floor, then lower under control.', 'Pulling the weight away from the chest to create momentum. Keep it pressed to your chest — that keeps the resistance directly in line with the ab contraction.',
  'isolation', NULL,
  'abs', '{}',
  '{}', 'weight_reps', 'Abs', '{}'
where not exists (select 1 from exercises where name = 'Weighted Crunch');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Hanging Knee Raise', 'Core', 'core', '{"Hip Flexors","Forearms"}', 'Bodyweight',
  'Hang from a pull-up bar with arms fully extended, legs straight down.', 'Raise your knees up toward your chest by flexing the hips and curling the pelvis, then lower under control.', 'Swinging the body to launch the knees up. Keep the swing to a minimum and control the lift with the abs, not momentum.',
  'isolation', NULL,
  'abs', '{"quads","forearms"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors","Forearms"}'
where not exists (select 1 from exercises where name = 'Hanging Knee Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Captain''s Chair Leg Raise', 'Core', 'core', '{"Hip Flexors"}', 'Machine',
  'Position your forearms on the pads of a captain''s chair, back against the support, legs hanging.', 'Raise your knees (or straight legs) up toward your chest, then lower under control.', 'Letting the lower back arch away from the pad as the legs lower. Keep the lower back pressed against the support the whole set.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{"Roman Chair Leg Raise"}', 'bodyweight_reps', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'Captain''s Chair Leg Raise');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Toes-to-Bar', 'Core', 'core', '{"Hip Flexors","Lats","Forearms"}', 'Bodyweight',
  'Hang from a pull-up bar with arms fully extended, legs straight down.', 'Raise your legs up until your toes touch the bar, keeping them as straight as you can manage, then lower under control.', 'Using a big, uncontrolled swing to get the toes up. Build toward this from hanging knee raises — the swing should be minimal, not the main driver.',
  'compound', NULL,
  'abs', '{"quads","lats","forearms"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors","Lats","Forearms"}'
where not exists (select 1 from exercises where name = 'Toes-to-Bar');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Side Plank', 'Core', 'core', '{"Abs","Abductors"}', 'Bodyweight',
  'Lie on your side, forearm on the floor under your shoulder, legs stacked or staggered.', 'Lift your hips off the floor into a straight line from head to feet, holding for the target duration.', 'Letting the hips sag toward the floor or pike up toward the ceiling. Keep a dead-straight line the whole hold.',
  'isolation', NULL,
  'obliques', '{"abs","glutes"}',
  '{}', 'time', 'Obliques', '{"Abs","Abductors"}'
where not exists (select 1 from exercises where name = 'Side Plank');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Copenhagen Plank', 'Legs', 'quads', '{"Obliques","Abs"}', 'Bodyweight',
  'Lie on your side with your top foot propped on a bench, bottom leg extended beneath, forearm on the floor for support.', 'Lift your bottom leg and hips off the floor into a side-plank line, hold briefly, then lower under control.', 'Starting with the full version before you''re ready. Regress by bending the top knee against the bench until you can hold the full straight-leg version with good form.',
  'isolation', NULL,
  'quads', '{"obliques","abs"}',
  '{}', 'time', 'Adductors', '{"Obliques","Abs"}'
where not exists (select 1 from exercises where name = 'Copenhagen Plank');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Woodchop (High-to-Low)', 'Core', 'core', '{"Abs","Front Delts"}', 'Cable',
  'Set the pulley high, stand side-on, grip the handle with both hands, arms extended up and across your body.', 'Rotate your torso and pull the handle down and across to the opposite hip, then return under control.', 'Bending the arms to pull instead of rotating the torso. Keep the arms relatively fixed and let the obliques drive the rotation.',
  'compound', NULL,
  'obliques', '{"abs","delts"}',
  '{"Woodchop"}', 'weight_reps', 'Obliques', '{"Abs","Front Delts"}'
where not exists (select 1 from exercises where name = 'Cable Woodchop (High-to-Low)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Cable Woodchop (Low-to-High)', 'Core', 'core', '{"Abs","Front Delts"}', 'Cable',
  'Set the pulley low, stand side-on, grip the handle with both hands, arms extended down and across your body.', 'Rotate your torso and pull the handle up and across to the opposite shoulder, then return under control.', 'Using the arms to lift instead of rotating through the trunk. Let the torso rotation generate the movement, with the arms just along for the ride.',
  'compound', NULL,
  'obliques', '{"abs","delts"}',
  '{}', 'weight_reps', 'Obliques', '{"Abs","Front Delts"}'
where not exists (select 1 from exercises where name = 'Cable Woodchop (Low-to-High)');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Dead Bug', 'Core', 'core', '{"Hip Flexors"}', 'Bodyweight',
  'Lie on your back, arms extended toward the ceiling, knees bent 90° above your hips.', 'Extend one arm and the opposite leg toward the floor without letting your lower back arch, then return and switch sides.', 'Letting the lower back lift off the floor as the limbs extend. Keep it pressed flat the entire time — that''s the actual skill this exercise is training.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'Dead Bug');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Bird Dog', 'Core', 'core', '{"Glutes","Abs"}', 'Bodyweight',
  'Start on hands and knees, spine neutral, core lightly braced.', 'Extend one arm forward and the opposite leg back simultaneously, hold briefly, then return and switch sides.', 'Letting the hips rotate or the lower back sag as the limbs extend. Keep the pelvis level the whole time — that stability is the actual point of the exercise.',
  'isolation', NULL,
  'lowerback', '{"glutes","abs"}',
  '{}', 'bodyweight_reps', 'Lower Back', '{"Glutes","Abs"}'
where not exists (select 1 from exercises where name = 'Bird Dog');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Bicycle Crunch', 'Core', 'core', '{"Obliques"}', 'Bodyweight',
  'Lie on your back, hands lightly behind your head, knees bent and lifted, shoulders curled slightly off the floor.', 'Rotate to bring one elbow toward the opposite knee while extending the other leg, then switch sides in a pedaling motion.', 'Pulling on the head/neck to generate the rotation. Let the obliques drive the twist — the hands should stay light, not yanking.',
  'isolation', NULL,
  'abs', '{"obliques"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Obliques"}'
where not exists (select 1 from exercises where name = 'Bicycle Crunch');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'V-Up', 'Core', 'core', '{"Hip Flexors"}', 'Bodyweight',
  'Lie flat on your back, arms extended overhead, legs straight.', 'Simultaneously raise your legs and torso to form a V shape, reaching your hands toward your feet, then lower back down under control.', 'Using momentum to rock up instead of a controlled fold. Keep both halves of the movement — the leg lift and the torso curl — deliberate and controlled.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{}', 'bodyweight_reps', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'V-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Hollow Hold', 'Core', 'core', '{"Hip Flexors"}', 'Bodyweight',
  'Lie on your back, arms extended overhead, legs extended, lower back pressed into the floor.', 'Lift your shoulders and legs slightly off the floor, holding the lower-back-flat position for the target duration.', 'Letting the lower back arch off the floor to hold the position longer. Raise the legs to whatever height keeps the back flat — height isn''t the goal, control is.',
  'isolation', NULL,
  'abs', '{"quads"}',
  '{}', 'time', 'Abs', '{"Hip Flexors"}'
where not exists (select 1 from exercises where name = 'Hollow Hold');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Landmine Rotation', 'Core', 'core', '{"Abs","Front Delts"}', 'Landmine',
  'Set a barbell in a landmine attachment, grip the loaded end with both hands, arms extended in front of you.', 'Rotate the bar from one side to the other by twisting through your torso, keeping your arms relatively fixed.', 'Letting the lower body swing along with the rotation. Keep your hips and feet relatively stable so the obliques, not momentum, drive the rotation.',
  'compound', NULL,
  'obliques', '{"abs","delts"}',
  '{}', 'weight_reps', 'Obliques', '{"Abs","Front Delts"}'
where not exists (select 1 from exercises where name = 'Landmine Rotation');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Suitcase Carry', 'Core', 'core', '{"Forearms","Traps","Abs"}', 'Dumbbell',
  'Stand holding a single dumbbell or kettlebell at your side like a suitcase, the other arm relaxed at your side.', 'Walk forward for the target distance or time, resisting the urge to lean away from the weight.', 'Leaning toward the loaded side to make it easier. Stay upright — resisting that lean with the obliques is the entire point of the carry.',
  'compound', NULL,
  'obliques', '{"forearms","traps","abs"}',
  '{}', 'distance_time', 'Obliques', '{"Forearms","Traps","Abs"}'
where not exists (select 1 from exercises where name = 'Suitcase Carry');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Mountain Climber', 'Core', 'core', '{"Hip Flexors","Front Delts"}', 'Bodyweight',
  'Start in a high plank position, hands under shoulders, body in a straight line.', 'Drive one knee toward your chest, then quickly switch legs in a running-like motion, keeping the hips level.', 'Letting the hips pike up or sag as the pace increases. Keep the plank line stable — slow down if speed is breaking your form.',
  'compound', NULL,
  'abs', '{"quads","delts"}',
  '{}', 'time', 'Abs', '{"Hip Flexors","Front Delts"}'
where not exists (select 1 from exercises where name = 'Mountain Climber');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Hang Clean', 'Full Body', NULL, '{"Traps","Quads","Glutes","Hamstrings"}', 'Barbell',
  'Start standing with a barbell at mid-thigh, knees slightly bent, grip just outside shoulder width.', 'Explosively extend your hips and knees, shrug the bar up, then pull yourself under it to catch it in a front-rack position with knees bent.', 'Pulling with the arms too early. Let the legs and hips finish the explosive extension first — the arms only start pulling once that extension is nearly complete.',
  'compound', NULL,
  NULL, '{"traps","quads","glutes","hamstrings"}',
  '{}', 'weight_reps', 'Full Body', '{"Traps","Quads","Glutes","Hamstrings"}'
where not exists (select 1 from exercises where name = 'Hang Clean');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Kettlebell Swing', 'Legs', 'glutes', '{"Hamstrings","Lower Back","Front Delts"}', 'Kettlebell',
  'Stand with feet shoulder-width apart, kettlebell on the floor ahead of you, hinge down to grip it.', 'Hike the bell back between your legs, then snap your hips forward explosively to swing it up to chest height, letting it float back down into the next rep.', 'Squatting the weight up with the arms and legs instead of snapping the hips. This is a hip-hinge power move — the arms are just along for the ride.',
  'compound', NULL,
  'glutes', '{"hamstrings","lowerback","delts"}',
  '{}', 'weight_reps', 'Glutes', '{"Hamstrings","Lower Back","Front Delts"}'
where not exists (select 1 from exercises where name = 'Kettlebell Swing');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Turkish Get-Up', 'Full Body', NULL, '{"Front Delts","Abs","Glutes"}', 'Kettlebell',
  'Lie on your back holding a kettlebell overhead in one arm, that same-side knee bent, foot flat.', 'Work through the sequence — rolling to an elbow, then a hand, bridging the hips, sweeping the leg through, and standing up — while keeping the kettlebell locked out overhead the whole time.', 'Rushing through the sequence instead of treating each step as a distinct checkpoint. Move slowly and deliberately — speed is not the goal of this exercise.',
  'compound', NULL,
  NULL, '{"delts","abs","glutes"}',
  '{}', 'weight_reps', 'Full Body', '{"Front Delts","Abs","Glutes"}'
where not exists (select 1 from exercises where name = 'Turkish Get-Up');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Burpee', 'Full Body', NULL, '{"Chest","Quads","Front Delts"}', 'Bodyweight',
  'Stand with feet shoulder-width apart.', 'Drop into a squat, place your hands down, kick your feet back into a plank, perform a push-up, jump your feet back in, then explode up into a jump.', 'Letting the hips sag in the plank/push-up portion as fatigue sets in. Hold the plank brace even when you''re tired — that''s usually where form breaks down first.',
  'compound', NULL,
  NULL, '{"chest","quads","delts"}',
  '{}', 'bodyweight_reps', 'Full Body', '{"Chest","Quads","Front Delts"}'
where not exists (select 1 from exercises where name = 'Burpee');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Sled Push', 'Legs', 'quads', '{"Glutes","Calves"}', 'Sled',
  'Load the sled, grip the handles at a height that lets you lean into it, athletic stance behind it.', 'Drive forward through the balls of your feet in short, powerful steps, keeping your back flat and chest over the handles.', 'Standing too upright and pushing with the arms. Lean into the sled and drive with the legs — the arms are just there to transmit force, not generate it.',
  'compound', NULL,
  'quads', '{"glutes","calves"}',
  '{}', 'distance_time', 'Quads', '{"Glutes","Calves"}'
where not exists (select 1 from exercises where name = 'Sled Push');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Sled Pull', 'Legs', 'hamstrings', '{"Glutes","Upper Back"}', 'Sled',
  'Attach a strap or harness to a loaded sled, face the sled, and get into an athletic stance with the rope or strap taut.', 'Pull the sled toward you by driving your hips back and extending, hand-over-hand or leaning back, in a controlled, repeated motion.', 'Yanking with the arms instead of driving with the legs and hips. Let the lower body generate the pulling force; the arms just transmit it.',
  'compound', NULL,
  'hamstrings', '{"glutes","lats"}',
  '{}', 'distance_time', 'Hamstrings', '{"Glutes","Upper Back"}'
where not exists (select 1 from exercises where name = 'Sled Pull');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Battle Ropes', 'Full Body', NULL, '{"Front Delts","Forearms","Abs"}', 'Other',
  'Stand in an athletic stance holding one end of each rope, arms extended toward the anchor point.', 'Alternate driving each arm up and down rapidly to create waves through the ropes, keeping your core braced the whole time.', 'Using only the arms and shoulders while standing stiff-legged. Stay in an athletic stance and let the legs and core share the work — it shouldn''t be an arms-only exercise.',
  'compound', NULL,
  NULL, '{"delts","forearms","abs"}',
  '{}', 'time', 'Full Body', '{"Front Delts","Forearms","Abs"}'
where not exists (select 1 from exercises where name = 'Battle Ropes');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Treadmill', 'Full Body', 'cardio', '{"Quads","Calves"}', 'Cardio',
  'Set your target speed and incline before stepping onto the belt, hands light on the rails only if needed for balance.', 'Maintain an upright posture and natural stride for the target duration or distance.', 'Gripping the front rails and leaning on them for support. That reduces the real workload and can strain the shoulders — let your legs and core do the work unsupported.',
  'conditioning', 'conditioning',
  NULL, '{"quads","calves"}',
  '{"Treadmill Run","Treadmill Walk"}', 'distance_time', 'Cardio', '{"Quads","Calves"}'
where not exists (select 1 from exercises where name = 'Treadmill');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Stationary Bike', 'Full Body', 'cardio', '{"Quads"}', 'Cardio',
  'Adjust the seat height so your knee has a slight bend at the bottom of the pedal stroke, feet secured in the pedals or straps.', 'Pedal at your target cadence and resistance for the target duration.', 'Setting the seat too low, forcing excessive knee bend. A seat that''s too low adds unnecessary knee stress — set it so your leg is almost, but not fully, extended at the bottom.',
  'conditioning', 'conditioning',
  NULL, '{"quads"}',
  '{"Exercise Bike","Spin Bike"}', 'distance_time', 'Cardio', '{"Quads"}'
where not exists (select 1 from exercises where name = 'Stationary Bike');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Elliptical', 'Full Body', 'cardio', '{"Quads","Glutes"}', 'Cardio',
  'Step onto the pedals, grip the moving handles if using them, set your target resistance and incline.', 'Move through the elliptical stride for the target duration, keeping a tall, relaxed posture.', 'Hunching forward over the console. Keep an upright posture — leaning on the machine reduces the workload and can strain the lower back over time.',
  'conditioning', 'conditioning',
  NULL, '{"quads","glutes"}',
  '{}', 'distance_time', 'Cardio', '{"Quads","Glutes"}'
where not exists (select 1 from exercises where name = 'Elliptical');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Ski Erg', 'Full Body', 'cardio', '{"Lats","Abs","Triceps"}', 'Cardio',
  'Stand facing the machine, grip the handles overhead, feet set in an athletic stance.', 'Pull the handles down and back by hinging at the hips and engaging the lats and core, then let them return smoothly overhead.', 'Pulling with the arms alone instead of hinging through the hips. The power should come from the hip hinge and lats, with the arms finishing the pull.',
  'conditioning', 'conditioning',
  NULL, '{"lats","abs","triceps"}',
  '{}', 'distance_time', 'Cardio', '{"Lats","Abs","Triceps"}'
where not exists (select 1 from exercises where name = 'Ski Erg');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Jump Rope', 'Full Body', 'cardio', '{"Calves","Forearms"}', 'Other',
  'Hold the handles lightly, rope behind your heels, elbows close to your sides.', 'Jump just high enough to clear the rope using small wrist rotations to turn it, landing softly on the balls of your feet.', 'Jumping too high with big, stomping landings. Keep the jumps low and the landings soft — the rope should clear with inches, not a big leap.',
  'conditioning', 'conditioning',
  NULL, '{"calves","forearms"}',
  '{}', 'time', 'Cardio', '{"Calves","Forearms"}'
where not exists (select 1 from exercises where name = 'Jump Rope');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Outdoor Run', 'Full Body', 'cardio', '{"Quads","Calves","Glutes"}', 'Cardio',
  'Choose a route and target pace or distance, warm up with an easy walk or jog first.', 'Maintain a steady, sustainable pace for the target duration or distance, adjusting effort for terrain.', 'Starting too fast and fading hard later. Settle into your target pace in the first few minutes rather than sprinting out of the gate.',
  'conditioning', 'conditioning',
  NULL, '{"quads","calves","glutes"}',
  '{"Run"}', 'distance_time', 'Cardio', '{"Quads","Calves","Glutes"}'
where not exists (select 1 from exercises where name = 'Outdoor Run');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Outdoor Walk', 'Full Body', 'cardio', '{"Quads","Calves"}', 'Cardio',
  'Choose a route and target pace or distance.', 'Maintain a brisk, purposeful walking pace for the target duration or distance.', 'Letting the pace drift too slow to count as meaningful cardio. If the goal is a training effect, keep the pace brisk enough that conversation takes some effort.',
  'conditioning', 'conditioning',
  NULL, '{"quads","calves"}',
  '{"Walk"}', 'distance_time', 'Cardio', '{"Quads","Calves"}'
where not exists (select 1 from exercises where name = 'Outdoor Walk');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Outdoor Cycling', 'Full Body', 'cardio', '{"Quads","Glutes"}', 'Cardio',
  'Check your bike and helmet, choose a route and target duration or distance.', 'Maintain a steady cadence and effort appropriate to the terrain for the target duration or distance.', 'Coasting on flats and descents instead of maintaining effort. If this is a training ride rather than a recovery ride, keep pedaling with purpose through the easy sections too.',
  'conditioning', 'conditioning',
  NULL, '{"quads","glutes"}',
  '{"Bike Ride"}', 'distance_time', 'Cardio', '{"Quads","Glutes"}'
where not exists (select 1 from exercises where name = 'Outdoor Cycling');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Swimming', 'Full Body', 'cardio', '{"Lats","Front Delts","Quads"}', 'Cardio',
  'Choose your stroke and target distance or duration, warm up with a few easy lengths first.', 'Maintain steady, efficient stroke mechanics for the target duration or distance.', 'Letting the head lift too high to breathe, which drags the hips down and wastes energy. Rotate the head to the side to breathe rather than lifting it forward.',
  'conditioning', 'conditioning',
  NULL, '{"lats","delts","quads"}',
  '{}', 'distance_time', 'Cardio', '{"Lats","Front Delts","Quads"}'
where not exists (select 1 from exercises where name = 'Swimming');

insert into exercises (
  name, muscle_group, body_region, secondary_regions, equipment,
  cue_setup, cue_execution, cue_mistake,
  movement_type, category,
  muscle_map_key, muscle_map_secondary_keys,
  aliases, tracking, detailed_muscle, detailed_secondary
)
select 'Hiking', 'Full Body', 'cardio', '{"Quads","Glutes","Calves"}', 'Cardio',
  'Choose a route and check pack weight, footwear, and water before setting out.', 'Maintain a sustainable pace suited to the terrain and elevation for the target duration or distance.', 'Setting a pace on climbs that isn''t sustainable for the whole hike. Slow down on the uphill sections rather than burning out before the hike is done.',
  'conditioning', 'conditioning',
  NULL, '{"quads","glutes","calves"}',
  '{}', 'distance_time', 'Cardio', '{"Quads","Glutes","Calves"}'
where not exists (select 1 from exercises where name = 'Hiking');


-- Phase 1 catalog import: backfill detailed_muscle for the 14
-- existing exercises that had no CSV counterpart, so every row in the
-- table has a usable detailed_muscle for search/filtering (not just the
-- 255 touched directly by the CSV import).
-- Derived from each row's own muscle_map_key (or muscle_group where that
-- key isn't set) - no new information invented.

update exercises set detailed_muscle = 'Abs' where name = 'Weighted Sit-Up' and detailed_muscle is null;
update exercises set detailed_muscle = 'Full Body' where name = 'Clean' and detailed_muscle is null;
update exercises set detailed_muscle = 'Full Body' where name = 'Clean and Jerk' and detailed_muscle is null;
update exercises set detailed_muscle = 'Full Body' where name = 'Snatch' and detailed_muscle is null;
update exercises set detailed_muscle = 'Quads' where name = 'Depth Jump' and detailed_muscle is null;
update exercises set detailed_muscle = 'Quads' where name = 'Broad Jump' and detailed_muscle is null;
update exercises set detailed_muscle = 'Glutes' where name = 'Lateral Bound' and detailed_muscle is null;
update exercises set detailed_muscle = 'Hamstrings' where name = 'Single-Leg Bound' and detailed_muscle is null;
update exercises set detailed_muscle = 'Quads' where name = 'Tuck Jump' and detailed_muscle is null;
update exercises set detailed_muscle = 'Chest' where name = 'Medicine Ball Chest Pass' and detailed_muscle is null;
update exercises set detailed_muscle = 'Obliques' where name = 'Medicine Ball Rotational Throw' and detailed_muscle is null;
update exercises set detailed_muscle = 'Quads' where name = 'Pause Squat' and detailed_muscle is null;
update exercises set detailed_muscle = 'Hamstrings' where name = 'Deficit Deadlift' and detailed_muscle is null;
update exercises set detailed_muscle = 'Quads' where name = 'Zercher Squat' and detailed_muscle is null;
