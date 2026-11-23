// Fidelity pass fixture data, shared by scripts/app-shots.js.
//
// Implementation note: rather than writing to a real Supabase project
// (which would mean creating a persistent test account and real rows in
// production just to take screenshots), this seeds the running app via
// Playwright route interception - the same mocked-Supabase-REST pattern
// used throughout this app's own manual verification all along this
// project. installMocks(page) makes the app behave, from its own point
// of view, exactly as if this data were real: same code paths, same
// render functions, same client-side logic under test. It does not
// exercise server-side RLS/migrations - those are unaffected by this
// pass. Flagged here in case real backend seeding is actually wanted.
export const FAKE_USER = { id: 'demo-user-1', email: 'demo@example.com', aud: 'authenticated', role: 'authenticated' };
export const FAKE_SESSION = {
  access_token: 'x', refresh_token: 'x', expires_in: 3600,
  expires_at: Math.floor(Date.now() / 1000) + 3600, token_type: 'bearer', user: FAKE_USER,
};

function todayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
function daysAgoStr(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

// "Upper / Lower 4-day", today = Upper A (day index 0). createdDate is
// set so (today - createdDate) days-since %% 4 === 0, i.e. createdDate
// is today's date itself - the simplest value that satisfies that for
// a freshly-seeded fixture while still presenting as "week 2" via the
// day labels/exercise reasons (the block's own rotation math has no
// separate "week number" field - see computeBlockDayIndex in index.html).
export const ACTIVE_BLOCK = {
  focus: 'Upper / Lower', priorities: [], days: 4, equipment: [], avoid: [],
  createdDate: todayStr(),
  sourceProgramId: 'demo-upper-lower', sourceProgramName: 'Upper / Lower',
  blockDays: [
    { label: 'Upper A', groups: [], exercises: [
      { name: 'Barbell Bench Press', muscle: 'chest', sets: 3, reps: '6-8', tags: [], reason: 'Primary push.' },
      { name: 'Incline Dumbbell Press', muscle: 'chest', sets: 3, reps: '8-10', tags: [], reason: 'Upper chest volume.' },
      { name: 'Lat Pulldown', muscle: 'lats', sets: 3, reps: '8-12', tags: [], reason: 'Primary pull.' },
    ] },
    { label: 'Lower A', groups: [], exercises: [
      { name: 'Leg Press', muscle: 'quads', sets: 3, reps: '10-12', tags: [], reason: 'Primary quad work.' },
    ] },
    { label: 'Upper B', groups: [], exercises: [
      { name: 'Barbell Bench Press', muscle: 'chest', sets: 3, reps: '6-8', tags: [], reason: 'Primary push.' },
      { name: 'Lat Pulldown', muscle: 'lats', sets: 3, reps: '8-12', tags: [], reason: 'Primary pull.' },
    ] },
    { label: 'Lower B', groups: [], exercises: [
      { name: 'Leg Press', muscle: 'quads', sets: 3, reps: '10-12', tags: [], reason: 'Primary quad work.' },
    ] },
  ],
};

export const FAKE_EXERCISES = [
  { id: 1, name: 'Barbell Bench Press', muscle_group: 'Push', body_region: 'chest', equipment: 'Barbell', movement_type: 'compound',
    cue_setup: 'Bench at 0°, feet flat, shoulder blades pinched back and down.', cue_execution: 'Lower to the mid chest, press up and slightly back, no hard lockout.',
    cue_mistake: 'Flared elbows, bouncing off the chest.', cue_bracing: 'Brace the core, keep glutes on the bench.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: ['triceps', 'delts'], detailed_muscle: 'Chest', aliases: ['Bench Press'], tracking: 'weight_reps' },
  { id: 2, name: 'Incline Dumbbell Press', muscle_group: 'Push', body_region: 'chest', equipment: 'Dumbbell', movement_type: 'compound',
    cue_setup: 'Bench at 30°, shoulder blades pinched back and down.', cue_execution: 'Lower to the upper chest, elbows about 45° from your body.',
    cue_mistake: 'Bench too steep (shoulders take over), flared elbows, bouncing off the chest.', cue_bracing: 'Keep ribs down, feet planted.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: ['delts'], detailed_muscle: 'Upper Chest', aliases: [], tracking: 'weight_reps' },
  { id: 3, name: 'Lat Pulldown', muscle_group: 'Pull', body_region: 'back', equipment: 'Cable', movement_type: 'compound',
    cue_setup: 'Grip just outside shoulder width, lean back slightly.', cue_execution: 'Pull to the upper chest, elbows down and back.',
    cue_mistake: 'Using momentum, pulling behind the neck.', cue_bracing: 'Keep chest up, avoid shrugging.',
    muscle_map_key: 'lats', muscle_map_secondary_keys: ['biceps'], detailed_muscle: 'Lats', aliases: [], tracking: 'weight_reps' },
  { id: 4, name: 'Leg Press', muscle_group: 'Legs', body_region: 'legs', equipment: 'Machine', movement_type: 'compound',
    cue_setup: 'Feet shoulder width, mid platform.', cue_execution: 'Lower until knees reach about 90°, press through the heels.',
    cue_mistake: 'Knees caving in, lower back rounding off the pad.', cue_bracing: 'Keep lower back flat on the pad.',
    muscle_map_key: 'quads', muscle_map_secondary_keys: ['glutes'], detailed_muscle: 'Quads', aliases: [], tracking: 'weight_reps' },
  { id: 5, name: 'Cable Fly (High-to-Low)', muscle_group: 'Push', body_region: 'chest', equipment: 'Cable', movement_type: 'isolation',
    cue_setup: 'Pulleys set high, slight forward lean.', cue_execution: 'Sweep hands down and together in an arc.',
    cue_mistake: 'Turning it into a press, bending the elbows too much.', cue_bracing: 'Soft knees, braced core.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: [], detailed_muscle: 'Chest', aliases: ['Cable Crossover'], tracking: 'weight_reps' },
  { id: 6, name: 'Barbell Overhead Press', muscle_group: 'Push', body_region: 'shoulders', equipment: 'Barbell', movement_type: 'compound',
    cue_setup: 'Bar at the collarbone, grip just outside shoulders.', cue_execution: 'Press straight up, head moves slightly back then through.',
    cue_mistake: 'Leaning back excessively, flaring elbows too wide.', cue_bracing: 'Squeeze glutes, brace like a punch is coming.',
    muscle_map_key: 'delts', muscle_map_secondary_keys: ['triceps'], detailed_muscle: 'Shoulders', aliases: [], tracking: 'weight_reps' },
  { id: 7, name: 'Triceps Pushdown (Rope)', muscle_group: 'Push', body_region: 'arms', equipment: 'Cable', movement_type: 'isolation',
    cue_setup: 'Elbows pinned to the sides.', cue_execution: 'Extend down and spread the rope apart at the bottom.',
    cue_mistake: 'Letting elbows drift forward.', cue_bracing: 'Keep torso still.',
    muscle_map_key: 'triceps', muscle_map_secondary_keys: [], detailed_muscle: 'Triceps', aliases: [], tracking: 'weight_reps' },
  { id: 8, name: 'Plank', muscle_group: 'Core', body_region: 'abs', equipment: 'Bodyweight', movement_type: 'isolation',
    cue_setup: 'Elbows under shoulders, body in a straight line.', cue_execution: 'Hold, squeezing glutes and abs.',
    cue_mistake: 'Hips sagging or piking up.', cue_bracing: 'Breathe steadily, keep ribs down.',
    muscle_map_key: 'abs', muscle_map_secondary_keys: [], detailed_muscle: 'Abs', aliases: [], tracking: 'time' },
  { id: 9, name: 'Farmer’s Carry', muscle_group: 'Core', body_region: 'full_body', equipment: 'Dumbbell', movement_type: 'conditioning',
    cue_setup: 'Stand tall, shoulders back.', cue_execution: 'Walk a set distance holding heavy dumbbells at your sides.',
    cue_mistake: 'Leaning to one side, shuffling steps.', cue_bracing: 'Brace the core the whole way.',
    muscle_map_key: 'forearms', muscle_map_secondary_keys: ['traps'], detailed_muscle: 'Forearms', aliases: [], tracking: 'distance_time' },
  { id: 10, name: 'Incline Chest Press Machine', muscle_group: 'Push', body_region: 'chest', equipment: 'Machine', movement_type: 'compound',
    cue_setup: 'Seat height so handles sit at the upper chest.', cue_execution: 'Press forward and slightly up.',
    cue_mistake: 'Flaring elbows too wide.', cue_bracing: 'Keep shoulder blades down.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: [], detailed_muscle: 'Upper Chest', aliases: [], tracking: 'weight_reps' },
  { id: 11, name: 'Incline Barbell Bench Press', muscle_group: 'Push', body_region: 'chest', equipment: 'Barbell', movement_type: 'compound',
    cue_setup: 'Bench at 30°, grip just outside shoulder width.', cue_execution: 'Lower to the upper chest, press up and slightly back.',
    cue_mistake: 'Bouncing off the chest.', cue_bracing: 'Feet planted, glutes down.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: [], detailed_muscle: 'Upper Chest', aliases: [], tracking: 'weight_reps' },
  { id: 12, name: 'Cable Fly (Low-to-High)', muscle_group: 'Push', body_region: 'chest', equipment: 'Cable', movement_type: 'isolation',
    cue_setup: 'Pulleys set low.', cue_execution: 'Sweep hands up and together.',
    cue_mistake: 'Using momentum.', cue_bracing: 'Soft knees.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: [], detailed_muscle: 'Upper Chest', aliases: [], tracking: 'weight_reps' },
  { id: 13, name: 'Incline Push-Up', muscle_group: 'Push', body_region: 'chest', equipment: 'Bodyweight', movement_type: 'compound',
    cue_setup: 'Hands on a bench or box.', cue_execution: 'Lower chest to the edge, press back up.',
    cue_mistake: 'Hips sagging.', cue_bracing: 'Brace the core.',
    muscle_map_key: 'chest', muscle_map_secondary_keys: [], detailed_muscle: 'Chest', aliases: [], tracking: 'bodyweight_reps' },
];

// "Last" numbers exactly as the mockup's sample data shows them.
export const SEED_LIFTS = [
  { exercise: 'Incline Dumbbell Press', date: daysAgoStr(4), weight: 70, sets: 3, reps_per_set: [9, 8, 8], reps: 8.3 },
  { exercise: 'Lat Pulldown', date: daysAgoStr(2), weight: 120, sets: 1, reps_per_set: [10], reps: 10 },
  { exercise: 'Leg Press', date: daysAgoStr(2), weight: 270, sets: 1, reps_per_set: [12], reps: 12 },
  { exercise: 'Barbell Bench Press', date: daysAgoStr(4), weight: 135, sets: 1, reps_per_set: [8], reps: 8 },
  // A short prior history on bench so est.-1RM trend/PR logic has something to compare against.
  { exercise: 'Barbell Bench Press', date: daysAgoStr(11), weight: 130, sets: 1, reps_per_set: [8], reps: 8 },
  { exercise: 'Barbell Bench Press', date: daysAgoStr(18), weight: 125, sets: 1, reps_per_set: [8], reps: 8 },
];

export const FAKE_PROFILE = {
  id: FAKE_USER.id, onboarding_completed_at: new Date().toISOString(),
  trial_offer_seen_at: new Date().toISOString(), payoff_coachmark_dismissed_at: new Date().toISOString(),
  active_training_block: ACTIVE_BLOCK, schedule_overrides_this_week: {},
  ai_consent_at: new Date().toISOString(),
};

// Today mockup's macro numbers exactly: 128g/180g protein, 1880/2750
// calories, 190/315 carbs, 62/84 fat.
export const FAKE_GOALS = { user_id: FAKE_USER.id, protein_g: 180, calories: 2750, carbs_g: 315, fat_g: 84 };
export const FAKE_FOOD_LOGS_TODAY = [
  { id: 1, user_id: FAKE_USER.id, logged_at: new Date().toISOString(), description: 'Seeded total', protein_g: 128, calories: 1880, carbs_g: 190, fat_g: 62 },
];

export async function installMocks(page, { subscriptionTier = 'pro' } = {}) {
  let liftsTable = [...SEED_LIFTS.map((l, i) => ({ ...l, id: 9000 + i, user_id: FAKE_USER.id, created_at: new Date().toISOString() }))];
  let nextLiftId = 9100;
  let workoutSessionRow = null;
  const subscriptionRow = subscriptionTier === 'free' ? null : { user_id: FAKE_USER.id, status: 'active', tier: 'pro' };

  await page.route('**/auth/v1/**', (r) => r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(FAKE_SESSION) }));
  await page.route('**/rest/v1/**', async (r) => {
    const req = r.request(); const u = req.url(); const method = req.method();
    const json = (body, status = 200) => r.fulfill({ status, contentType: 'application/json', body: JSON.stringify(body) });
    if (u.includes('/profiles')) {
      if (method === 'PATCH') { Object.assign(FAKE_PROFILE, JSON.parse(req.postData() || '{}')); return json([]); }
      return json([FAKE_PROFILE]);
    }
    if (u.includes('/subscriptions')) return json(subscriptionRow ? [subscriptionRow] : []);
    if (u.includes('/exercises')) return json(FAKE_EXERCISES);
    if (u.includes('/workout_sessions')) {
      if (method === 'POST') { const body = JSON.parse(req.postData() || '{}'); workoutSessionRow = { ...workoutSessionRow, ...body }; return json([workoutSessionRow], 201); }
      return json(workoutSessionRow ? [workoutSessionRow] : []);
    }
    if (u.includes('/lifts')) {
      if (method === 'POST') {
        const body = JSON.parse(req.postData() || '{}');
        const row = { ...body, id: nextLiftId++, user_id: FAKE_USER.id, created_at: new Date().toISOString() };
        liftsTable.push(row);
        return json(row, 201);
      }
      if (method === 'PATCH') {
        const idMatch = u.match(/id=eq\.(\d+)/);
        if (idMatch) { const row = liftsTable.find((l) => String(l.id) === idMatch[1]); if (row) Object.assign(row, JSON.parse(req.postData() || '{}')); }
        return json([]);
      }
      if (method === 'DELETE') {
        const idMatch = u.match(/id=eq\.(\d+)/);
        if (idMatch) liftsTable = liftsTable.filter((l) => String(l.id) !== idMatch[1]);
        return json([]);
      }
      return json(liftsTable);
    }
    if (u.includes('/food_logs')) return json(FAKE_FOOD_LOGS_TODAY);
    if (u.includes('/goals')) return json([FAKE_GOALS]);
    return json([]);
  });
  // Functions (session analysis etc.) - not under test for this pass, keep harmless.
  await page.route('**/functions/v1/**', (r) => r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) }));
  // analyze-session: a realistic, schema-accurate stand-in for the real
  // Claude call (see netlify/functions/analyze-session.js's SYSTEM_PROMPT
  // shape) so Section 4's "Finish" screenshots show the actual rendered
  // layout instead of the pre-generation empty state.
  await page.route('**/.netlify/functions/analyze-session', (r) => r.fulfill({
    status: 200, contentType: 'application/json', body: JSON.stringify({
      analysis: {
        summary: 'Strongest bench session in a while - that extra rep at 145 is a real sign of progress. Keep the rest of the week light so it banks.',
        callouts: [
          { type: 'pr', text: 'Bench Press hit a new best at 145 lb.' },
        ],
        highlightExercise: null,
      },
      remaining: 1,
    }),
  }));
}

export async function gotoApp(page, baseUrl) {
  await page.goto(baseUrl + '/index.html');
  await page.evaluate((s) => { try { localStorage.setItem('sb-putoyzpixaktjwcnrwwh-auth-token', JSON.stringify(s)); } catch (e) {} }, FAKE_SESSION);
  await page.reload();
  await page.waitForTimeout(1800);
}
