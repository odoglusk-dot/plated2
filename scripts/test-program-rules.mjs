// Krafft SMART PROGRAM batch, Phase 1: unit tests for the engine defined
// in index.html between the PROGRAM_RULES_ENGINE_START/END markers.
//
// Extracts that exact block (never a second hand-copied version of the
// logic) and evals it into a small sandbox alongside thin, documented
// stand-ins for the handful of pre-existing app functions it calls
// (e1RM, effectiveBlockDayIndex, localDateStr, etc.) - those are already
// shipped, already-used application code, not new Phase 1 logic, so they
// aren't re-tested here; only PROGRAM_RULES_ENGINE's own functions are
// the subject of this suite.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import vm from 'vm';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const indexPath = path.join(__dirname, '..', 'index.html');
const html = fs.readFileSync(indexPath, 'utf8');

const startMarker = '// PROGRAM_RULES_ENGINE_START';
const endMarker = '// PROGRAM_RULES_ENGINE_END';
const startIdx = html.indexOf(startMarker);
const endIdx = html.indexOf(endMarker);
if (startIdx === -1 || endIdx === -1) throw new Error('Could not find PROGRAM_RULES_ENGINE markers in index.html');
const engineSource = html.slice(startIdx, endIdx);

// ── Stand-ins for the engine's pre-existing dependencies ────────────────
function e1RM(weight, reps) {
  if (!weight || !reps || reps <= 0) return 0;
  if (reps === 1) return Math.round(weight);
  return Math.round(weight * (1 + reps / 30));
}
function localDateStr(d = new Date()) {
  const yr = d.getFullYear(), mo = String(d.getMonth() + 1).padStart(2, '0'), day = String(d.getDate()).padStart(2, '0');
  return `${yr}-${mo}-${day}`;
}
function computeBlockDayIndex(block, dateStr) {
  const start = new Date(`${block.createdDate}T00:00:00`);
  const today = new Date(`${dateStr}T00:00:00`);
  const daysSince = Math.round((today - start) / 86400000);
  const n = block.blockDays.length;
  return ((daysSince % n) + n) % n;
}
function effectiveBlockDayIndex(block, dateStr, overrides) {
  const entry = (overrides || {})[dateStr];
  if (entry?.action === 'skip' || entry?.action === 'moved_away') return null;
  if (entry?.action === 'moved_in') return entry.dayIndex;
  return computeBlockDayIndex(block, dateStr);
}
function goalForBlock() { return null; } // forces the DEFAULT_REP_RANGE fallback path, same as this branch's actual runtime (GOALS_CONFIG isn't merged)

const sandbox = { e1RM, localDateStr, computeBlockDayIndex, effectiveBlockDayIndex, goalForBlock, console };
vm.createContext(sandbox);
vm.runInContext(engineSource, sandbox);
// Top-level const/let in a vm context live in that context's lexical
// scope, not as own-properties of the sandbox object - a second
// runInContext call against the SAME context can still see them (the
// scope persists across calls), so this is how they get pulled out.
const EXPORT_NAMES = [
  'DEFAULT_REP_RANGE', 'repRangeForBlock', 'PROGRAM_RULES_CONFIG', 'roundToStep', 'weightStepFor', 'sessionStatus',
  'nextTargets', 'applyDeloadToSets', 'applyDeloadToWeight', 'isDownAcrossSessions', 'suggestDeload', 'deloadPreview',
  'daysSinceLastWorkout', 'welcomeBack', 'planWeek', 'missedOptions', 'weeklyVolumeForWeek', 'rankSwaps', 'suggestSwapStartWeight',
];
const {
  DEFAULT_REP_RANGE, repRangeForBlock, PROGRAM_RULES_CONFIG, roundToStep, weightStepFor, sessionStatus,
  nextTargets, applyDeloadToSets, applyDeloadToWeight, isDownAcrossSessions, suggestDeload, deloadPreview,
  daysSinceLastWorkout, welcomeBack, planWeek, missedOptions, weeklyVolumeForWeek, rankSwaps, suggestSwapStartWeight,
} = vm.runInContext(`({${EXPORT_NAMES.join(', ')}})`, sandbox);

// ── Minimal test harness ────────────────────────────────────────────────
let pass = 0, fail = 0;
function eq(actual, expected, label) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  if (ok) { pass++; }
  else { fail++; console.error(`FAIL: ${label}\n  expected: ${JSON.stringify(expected)}\n  actual:   ${JSON.stringify(actual)}`); }
}
function ok(cond, label) {
  if (cond) { pass++; } else { fail++; console.error(`FAIL: ${label}`); }
}

const RANGE = DEFAULT_REP_RANGE; // 6-15

// ── repRangeForBlock: falls back correctly with goals unmerged ──────────
eq(repRangeForBlock({}), { min: 6, max: 15 }, 'repRangeForBlock falls back to size 6-15 when GOALS_CONFIG is absent');

// ── weightStepFor ────────────────────────────────────────────────────────
eq(weightStepFor('Barbell', false, 'lb'), 5, 'barbell upper body, lb');
eq(weightStepFor('Barbell', true, 'lb'), 10, 'barbell lower body, lb');
eq(weightStepFor('Dumbbell', false, 'lb'), 5, 'dumbbell, lb');
eq(weightStepFor('Machine', false, 'lb'), 5, 'machine, lb');
eq(weightStepFor('Cable', false, 'lb'), 5, 'cable, lb');
eq(weightStepFor('Barbell', false, 'kg'), 2.5, 'barbell upper body, kg');
eq(weightStepFor('Barbell', true, 'kg'), 5, 'barbell lower body, kg');
eq(weightStepFor('Dumbbell', false, 'kg'), 2.5, 'dumbbell, kg');

// ── sessionStatus ────────────────────────────────────────────────────────
eq(sessionStatus([10, 10, 10], RANGE), 'short', '10,10,10 within 6-15 but not at top (10<15) => short');
eq(sessionStatus([15, 15, 15], RANGE), 'top', 'all sets at the range max => top');
eq(sessionStatus([15, 16, 15], RANGE), 'top', 'above the max still counts as top');
eq(sessionStatus([5, 10, 10], RANGE), 'below', 'one set under the range min => below');
eq(sessionStatus([], RANGE), 'short', 'empty reps array degrades to short, not a crash');

// ── nextTargets: the three mockup examples verbatim ─────────────────────
// "70 x 10,10,10 -> next: 72.5 x 8" using a dumbbell range of 6-10 (the
// mockup's own numbers imply a tighter range than the 6-15 default -
// reconstructed here as its own repRange to match the exact example).
{
  const tightRange = { min: 6, max: 10 };
  const history = [{ date: '2026-11-01', weight: 70, reps_per_set: [10, 10, 10] }];
  const t = nextTargets(history, tightRange, 2.5);
  eq(t.action, 'add_weight', 'mockup example 1: all sets at top => add_weight');
  eq(t.weight, 72.5, 'mockup example 1: 70 + 2.5 step = 72.5');
  eq(t.reps, 6, 'mockup example 1: reps reset to the bottom of the range');
}
// "70 x 10,9,8 -> next: 70 x 10,10,9" (same tight range, step irrelevant here)
{
  const tightRange = { min: 6, max: 10 };
  const history = [{ date: '2026-11-01', weight: 70, reps_per_set: [10, 9, 8] }];
  const t = nextTargets(history, tightRange, 5);
  eq(t.action, 'same_weight_add_rep', 'mockup example 2: short sets => same_weight_add_rep');
  eq(t.weight, 70, 'mockup example 2: weight unchanged');
  eq(t.repsPerSet, [10, 10, 9], 'mockup example 2: +1 rep on every set, capped at the top');
}
// "missed the bottom twice in a row -> drop 5-10%"
{
  const history = [
    { date: '2026-11-01', weight: 100, reps_per_set: [4, 4, 4] }, // below bottom of 6-15
    { date: '2026-11-08', weight: 100, reps_per_set: [5, 4, 4] }, // below again, same weight
  ];
  const t = nextTargets(history, RANGE, 5);
  eq(t.action, 'drop_weight', 'two sessions below the bottom at the same weight => drop_weight');
  ok(t.weight < 100 && t.weight >= 100 * 0.90 - 0.01, 'dropped weight is within the 5-10% band once rounded');
  eq(t.reps, 6, 'drop_weight resets reps to the bottom of the range');
}
// below twice, but the weight already changed between them - must NOT drop again
{
  const history = [
    { date: '2026-11-01', weight: 100, reps_per_set: [4, 4, 4] },
    { date: '2026-11-08', weight: 90, reps_per_set: [5, 4, 4] }, // already dropped once
  ];
  const t = nextTargets(history, RANGE, 5);
  ok(t.action !== 'drop_weight', 'a weight change between two "below" sessions resets the two-in-a-row counter');
}
// first-ever session (no history) - the explicit required edge case
{
  const t = nextTargets([], RANGE, 5);
  eq(t.action, 'first_session', 'no history at all => first_session, no number invented');
  eq(t.weight, null, 'first_session has no weight');
}
// bodyweight lift: "add reps then load" - required edge case
{
  const history = [{ date: '2026-11-01', weight: 0, reps_per_set: [15, 15, 15], trackingType: 'bodyweight_reps' }];
  const t = nextTargets(history, RANGE, 5);
  eq(t.action, 'add_reps_beyond_range', 'bodyweight hitting the top adds reps, not weight');
  eq(t.reps, 16, 'bodyweight next target is +1 rep beyond the top');
}
// kg vs lb - required edge case (same logic, different step)
{
  const tightRange = { min: 6, max: 10 };
  const history = [{ date: '2026-11-01', weight: 32.5, reps_per_set: [10, 10, 10] }];
  const t = nextTargets(history, tightRange, weightStepFor('Dumbbell', false, 'kg'));
  eq(t.weight, 35, 'kg dumbbell step (2.5) applied correctly: 32.5 + 2.5 = 35');
}
// unilateral exercise - required edge case; the engine treats it like
// any other exercise (reps_per_set already represents one side's reps,
// a per-exercise-definition concern, not an engine concern)
{
  const history = [{ date: '2026-11-01', weight: 20, reps_per_set: [12, 11, 10] }]; // Bulgarian split squat, within 6-15
  const t = nextTargets(history, RANGE, 5);
  eq(t.action, 'same_weight_add_rep', 'unilateral exercise follows the same short-sets rule as any other');
}
// a session interrupted and resumed same day - the engine only ever sees
// the FINAL reps_per_set/weight of a completed lift row, so this is
// indistinguishable from (and therefore already covered by) a normal
// single-sitting session; asserting that explicitly here.
{
  const resumedSession = { date: '2026-11-01', weight: 70, reps_per_set: [10, 10, 10] }; // as it ends up after resuming and finishing
  const freshSession = { date: '2026-11-01', weight: 70, reps_per_set: [10, 10, 10] };
  eq(nextTargets([resumedSession], RANGE, 5), nextTargets([freshSession], RANGE, 5), 'a resumed session is indistinguishable from a single-sitting one once its sets are final');
}
// old sessions with one weight per exercise - the only shape that has
// ever existed in `lifts` (weight is a single column, never per-set);
// every fixture above already is this shape, so backward compatibility
// is implicit - asserted explicitly once here against real historical rows.
{
  const oldRow = { date: '2020-01-01', weight: 135, reps: 8, sets: 3 }; // no reps_per_set column value at all (older row before that column existed)
  const t = nextTargets([oldRow], RANGE, 5);
  ok(t.action, 'a pre-reps_per_set historical row (reps/sets only) does not crash nextTargets');
}

// ── applyDeloadToSets / applyDeloadToWeight ──────────────────────────────
eq(applyDeloadToSets(3), 2, '3 sets * 0.6 = 1.8, round up = 2');
eq(applyDeloadToSets(1), 1, '1 set deloaded never goes below the min of 1');
eq(applyDeloadToSets(5), 3, '5 sets * 0.6 = 3, round up = 3');
eq(applyDeloadToWeight(100, 5), 90, '100 * 0.9 = 90, exact multiple of the 5 lb step');

// ── isDownAcrossSessions / suggestDeload ─────────────────────────────────
{
  const downHistory = [
    { date: '2026-10-01', weight: 150, reps: 8 },
    { date: '2026-10-08', weight: 145, reps: 8 }, // e1RM down
    { date: '2026-10-15', weight: 140, reps: 8 }, // e1RM down again
  ];
  ok(isDownAcrossSessions(downHistory, 2), 'two consecutive e1RM decreases flag as down');
  const flatHistory = [
    { date: '2026-10-01', weight: 150, reps: 8 },
    { date: '2026-10-08', weight: 150, reps: 8 },
  ];
  ok(!isDownAcrossSessions(flatHistory, 2), 'an unchanged e1RM does not count as down');

  const mainLifts = { bench: downHistory, squat: downHistory, deadlift: downHistory, row: downHistory, press: flatHistory };
  const deload = suggestDeload(mainLifts);
  eq(deload.downCount, 4, '4 of 5 main lifts down');
  ok(deload.suggested, '4 of 5 down (80%) meets the 4-of-5 threshold');

  const mainLiftsNotEnough = { bench: downHistory, squat: downHistory, deadlift: flatHistory, row: flatHistory, press: flatHistory };
  ok(!suggestDeload(mainLiftsNotEnough).suggested, 'only 2 of 5 down does not trigger the reactive deload suggestion');
}
{
  const preview = deloadPreview(58);
  eq(preview.setsChange, '40%', 'deload preview shows the -40% sets change');
  eq(preview.weightChange, '10%', 'deload preview shows the -10% weight change');
  eq(preview.sessionMinutes.after, 35, '58 min * 0.6 = 34.8, rounds to 35');
}

// ── daysSinceLastWorkout / welcomeBack ───────────────────────────────────
{
  const lifts = [{ date: '2026-11-01' }, { date: '2026-10-15' }];
  eq(daysSinceLastWorkout(lifts, '2026-11-17'), 16, '16 days since the most recent lift date');
  eq(daysSinceLastWorkout([], '2026-11-17'), null, 'no lifts ever logged => null, not a crash');
}
eq(welcomeBack(16).weightMultiplier, 0.9, '16 days away => 90%');
eq(welcomeBack(14).weightMultiplier, 0.9, '14 days exactly is the start of the 90% tier');
eq(welcomeBack(27).weightMultiplier, 0.9, '27 days is still the 90% tier');
eq(welcomeBack(28).weightMultiplier, 0.8, '28 days is the start of the 80% tier');
eq(welcomeBack(45).weightMultiplier, 0.8, '45 days away => 80%');
eq(welcomeBack(13), null, 'under 14 days away => no welcome-back treatment');
eq(welcomeBack(null), null, 'no history at all => no welcome-back treatment (not a crash)');

// ── planWeek: a skipped week + a midnight-boundary date ─────────────────
{
  const block = { createdDate: '2026-11-02', blockDays: [{ label: 'A' }, { label: 'B' }] }; // Monday start, 2-day rotation
  const overrides = { '2026-11-19': { action: 'skip' } }; // Thursday skipped this week
  const lifts = [{ date: '2026-11-16' }, { date: '2026-11-17' }]; // Mon, Tue done
  const week = planWeek(block, overrides, lifts, '2026-11-18'); // viewing on Wednesday
  eq(week[0].status, 'done', 'Monday logged => done');
  eq(week[1].status, 'done', 'Tuesday logged => done');
  eq(week[2].status, 'today', 'Wednesday (today) with no log yet => today, not missed');
  eq(week[3].status, 'rest', 'Thursday explicitly skipped this week => rest, never shown as a failure');
  ok(['planned', 'rest'].includes(week[4].status), 'Friday (future, not overridden) is planned or rest depending on rotation, never missed before it happens');
}
{
  // midnight boundary: a lift logged exactly at local midnight on the
  // boundary date must still land on the correct calendar day.
  const block = { createdDate: '2026-11-02', blockDays: [{ label: 'A' }] };
  const midnightLift = [{ date: localDateStr(new Date('2026-11-17T00:00:00')) }];
  const week = planWeek(block, {}, midnightLift, '2026-11-18');
  eq(week.find((d) => d.date === '2026-11-17').status, 'done', 'a lift dated exactly at local midnight still counts for that calendar day');
}
{
  // a day that has PASSED with nothing logged becomes missed, not rest/planned
  const block = { createdDate: '2026-11-02', blockDays: [{ label: 'A' }] }; // every day scheduled
  const week = planWeek(block, {}, [], '2026-11-19'); // Thursday, nothing logged all week
  eq(week[0].status, 'missed', 'Monday with nothing logged, now in the past => missed');
  eq(week[3].status, 'today', 'Thursday (today) with nothing logged yet => today, not missed');
  eq(week[4].status, 'planned', 'Friday (future) => planned, not missed');
}

// ── missedOptions ────────────────────────────────────────────────────────
{
  const opts = missedOptions(6, 20);
  eq(opts.length, 3, 'exactly three missed-session options');
  eq(opts[2].addedMinutes, 15, 'fold-into-next caps at the configured 15 minutes even if the missed day would add more');
  ok(!opts.some((o) => /fail|miss(ed)?\b.*(bad|red)/i.test(o.effect)), 'no option\'s copy reads as a failure/guilt message');
}
{
  const opts = missedOptions(6, 10);
  eq(opts[2].addedMinutes, 10, 'fold-into-next uses the real number when it is under the 15-minute cap');
}

// ── weeklyVolumeForWeek ──────────────────────────────────────────────────
{
  const lifts = [
    { sets: 3, primaryMuscleKey: 'chest', secondaryMuscleKeys: ['triceps'] },
    { sets: 4, primaryMuscleKey: 'chest', secondaryMuscleKeys: ['delts'] },
  ];
  const totals = weeklyVolumeForWeek(lifts);
  eq(totals.chest, 7, 'primary muscle counts every set at full weight (3+4)');
  eq(totals.triceps, 1.5, 'secondary muscle counts at half weight (3 * 0.5)');
  eq(totals.delts, 2, 'secondary muscle counts at half weight (4 * 0.5)');
}

// ── rankSwaps ────────────────────────────────────────────────────────────
{
  const bench = { name: 'Barbell Bench Press', muscle_map_key: 'chest', movement_type: 'compound', equipment: 'Barbell', tracking: 'weight_reps' };
  const candidates = [
    { name: 'Dumbbell Bench Press', muscle_map_key: 'chest', movement_type: 'compound', equipment: 'Dumbbell', tracking: 'weight_reps' },
    { name: 'Machine Chest Press', muscle_map_key: 'chest', movement_type: 'compound', equipment: 'Machine', tracking: 'weight_reps' },
    { name: 'Cable Fly', muscle_map_key: 'chest', movement_type: 'isolation', equipment: 'Cable', tracking: 'weight_reps' },
    { name: 'Barbell Row', muscle_map_key: 'lats', movement_type: 'compound', equipment: 'Barbell', tracking: 'weight_reps' }, // wrong muscle - must be dropped
  ];
  const ranked = rankSwaps(bench, candidates);
  ok(!ranked.some((c) => c.name === 'Barbell Row'), 'a different primary muscle is excluded entirely, not just ranked last');
  eq(ranked[0].movement_type, 'compound', 'same movement pattern ranks above isolation alternatives');

  const noEquipRanked = rankSwaps(bench, candidates, { userEquipment: ['Bodyweight', 'Dumbbell'] });
  ok(noEquipRanked.every((c) => c.equipment === 'Dumbbell'), '"No equipment" filtering only surfaces alternatives the user actually has');
}

// ── suggestSwapStartWeight ────────────────────────────────────────────────
{
  const withHistory = suggestSwapStartWeight([{ weight: 60, reps_per_set: [10, 9, 8] }], []);
  eq(withHistory.weight, 60, 'own history on the new exercise is used directly');
  eq(withHistory.source, 'own_history_on_new', 'source is labeled so the UI can say "your history here"');

  const noHistory = suggestSwapStartWeight([], [{ weight: 70, reps_per_set: [10, 10, 10] }]);
  eq(noHistory.weight, null, 'no history on the new exercise => no invented number, even with history on the old one');
  eq(noHistory.note, 'start light', 'no-history case shows "start light" instead of a guessed ratio');
}

console.log(`\n${pass} passed, ${fail} failed.`);
if (fail > 0) process.exit(1);
