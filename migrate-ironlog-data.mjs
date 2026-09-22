#!/usr/bin/env node
// One-time data migration: copies real rows out of IronLog's Supabase
// project into Plated's, once the two schemas are unified (see
// supabase-schema-phase7-ironlog.sql and the "Bodyweight" note in
// SCHEMA-REFERENCE.md). This is a standalone admin script, NOT part of
// the deployed app or a Netlify function — run it locally, once, by hand.
// It follows this repo's existing no-npm-dependency convention (see
// netlify/functions/_shared.js): plain REST calls against Supabase's
// PostgREST + Admin Auth APIs using the global `fetch` in Node 18+.
//
// What it moves:
//   IronLog `lifts`      -> Plated `lifts`            (same column shapes)
//   IronLog `bodyweight` -> Plated `weight_log`        (weight->weight_lb, date->logged_date)
//   IronLog `goals`      -> Plated `exercise_goals`    (same column shapes, renamed table)
//
// What it deliberately does NOT move:
//   - `photos` / the progress-photos Storage bucket — the Photos tab is a
//     later phase; there's nowhere in Plated yet for these to land.
//   - `monthly_recaps` — a computed cache, not source data. Once the
//     Recaps tab ships it'll regenerate itself client-side the first time
//     each month is viewed; migrating the cache would just be extra risk
//     for zero benefit.
//
// Usage:
//   IRONLOG_SUPABASE_URL=... IRONLOG_SUPABASE_SERVICE_ROLE_KEY=... \
//   PLATED_SUPABASE_URL=...  PLATED_SUPABASE_SERVICE_ROLE_KEY=...  \
//   PLATED_TARGET_USER_ID=<plated-auth-user-uuid> \
//     node migrate-ironlog-data.mjs              # dry run — prints counts, writes nothing
//
//   ...same env...  node migrate-ironlog-data.mjs --execute   # actually writes
//
// PLATED_SUPABASE_URL / PLATED_SUPABASE_SERVICE_ROLE_KEY are the same
// values already configured as SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY
// in this site's Netlify environment — just named differently here so
// they can't be confused with IronLog's, since this script talks to both
// projects in the same run.
//
// Multi-user note: if IronLog ever has more than one distinct user_id
// across its tables, PLATED_TARGET_USER_ID (a single target) isn't enough
// — the script refuses to guess and exits with an error telling you to
// set IRONLOG_USER_MAP instead (a JSON object mapping each IronLog user_id
// to the Plated user_id it belongs to), e.g.:
//   IRONLOG_USER_MAP='{"11111111-...":"22222222-..."}' node migrate-ironlog-data.mjs

const EXECUTE = process.argv.includes('--execute');
const BATCH_SIZE = 500;

function requireEnv(name) {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing required env var: ${name}`);
    process.exit(1);
  }
  return v;
}

const ironlogUrl = requireEnv('IRONLOG_SUPABASE_URL').replace(/\/$/, '');
const ironlogKey = requireEnv('IRONLOG_SUPABASE_SERVICE_ROLE_KEY');
const platedUrl = requireEnv('PLATED_SUPABASE_URL').replace(/\/$/, '');
const platedKey = requireEnv('PLATED_SUPABASE_SERVICE_ROLE_KEY');

const ironlogHeaders = {
  apikey: ironlogKey,
  Authorization: `Bearer ${ironlogKey}`,
  'content-type': 'application/json',
};
const platedHeaders = {
  apikey: platedKey,
  Authorization: `Bearer ${platedKey}`,
  'content-type': 'application/json',
};

// ── REST helpers ─────────────────────────────────────────────────────

async function restGetAll(base, headers, table, params = '') {
  const rows = [];
  let offset = 0;
  const limit = 1000;
  for (;;) {
    const sep = params ? '&' : '';
    const res = await fetch(
      `${base}/rest/v1/${table}?${params}${sep}order=id&limit=${limit}&offset=${offset}`,
      { headers }
    );
    if (!res.ok) {
      throw new Error(`GET ${table} failed (${res.status}): ${await res.text()}`);
    }
    const page = await res.json();
    rows.push(...page);
    if (page.length < limit) break;
    offset += limit;
  }
  return rows;
}

async function restInsertBatched(base, headers, table, rows) {
  let inserted = 0;
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const res = await fetch(`${base}/rest/v1/${table}`, {
      method: 'POST',
      headers: { ...headers, Prefer: 'return=minimal' },
      body: JSON.stringify(batch),
    });
    if (!res.ok) {
      throw new Error(`INSERT ${table} failed (${res.status}): ${await res.text()}`);
    }
    inserted += batch.length;
  }
  return inserted;
}

async function restUpsertBatched(base, headers, table, rows, onConflict) {
  let upserted = 0;
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const res = await fetch(`${base}/rest/v1/${table}?on_conflict=${onConflict}`, {
      method: 'POST',
      headers: { ...headers, Prefer: 'resolution=merge-duplicates,return=minimal' },
      body: JSON.stringify(batch),
    });
    if (!res.ok) {
      throw new Error(`UPSERT ${table} failed (${res.status}): ${await res.text()}`);
    }
    upserted += batch.length;
  }
  return upserted;
}

async function platedUserExists(userId) {
  const res = await fetch(`${platedUrl}/auth/v1/admin/users/${userId}`, { headers: platedHeaders });
  return res.ok;
}

// ── User-id mapping ──────────────────────────────────────────────────

function resolveUserMap(ironlogUserIds) {
  const rawMap = process.env.IRONLOG_USER_MAP;
  if (rawMap) {
    let parsed;
    try {
      parsed = JSON.parse(rawMap);
    } catch (err) {
      console.error(`IRONLOG_USER_MAP is not valid JSON: ${err.message}`);
      process.exit(1);
    }
    const missing = ironlogUserIds.filter((id) => !parsed[id]);
    if (missing.length) {
      console.error(`IRONLOG_USER_MAP is missing an entry for: ${missing.join(', ')}`);
      process.exit(1);
    }
    return new Map(Object.entries(parsed));
  }

  const single = process.env.PLATED_TARGET_USER_ID;
  if (single) {
    if (ironlogUserIds.length > 1) {
      console.error(
        `IronLog data spans ${ironlogUserIds.length} distinct user_ids ` +
        `(${ironlogUserIds.join(', ')}), but only PLATED_TARGET_USER_ID (a single ` +
        `target) was set. Set IRONLOG_USER_MAP instead — a JSON object mapping ` +
        `each IronLog user_id to the Plated user_id it belongs to.`
      );
      process.exit(1);
    }
    const map = new Map();
    for (const id of ironlogUserIds) map.set(id, single);
    return map;
  }

  console.error('Set either PLATED_TARGET_USER_ID (single-user migration) or IRONLOG_USER_MAP (multi-user migration).');
  process.exit(1);
}

// ── Main ─────────────────────────────────────────────────────────────

async function main() {
  console.log(EXECUTE ? '=== EXECUTE MODE — this will write to Plated\'s database ===' : '=== DRY RUN — pass --execute to actually write ===');
  console.log('');

  console.log('Fetching IronLog data...');
  const [ironlogLifts, ironlogBodyweight, ironlogGoals] = await Promise.all([
    restGetAll(ironlogUrl, ironlogHeaders, 'lifts'),
    restGetAll(ironlogUrl, ironlogHeaders, 'bodyweight'),
    restGetAll(ironlogUrl, ironlogHeaders, 'goals'),
  ]);
  console.log(`  lifts: ${ironlogLifts.length}, bodyweight: ${ironlogBodyweight.length}, goals: ${ironlogGoals.length}`);

  const ironlogUserIds = Array.from(new Set([
    ...ironlogLifts.map((r) => r.user_id),
    ...ironlogBodyweight.map((r) => r.user_id),
    ...ironlogGoals.map((r) => r.user_id),
  ]));
  if (ironlogUserIds.length === 0) {
    console.log('No IronLog data found — nothing to migrate.');
    return;
  }

  const userMap = resolveUserMap(ironlogUserIds);
  console.log('');
  console.log('User mapping:');
  for (const [from, to] of userMap) console.log(`  ${from} -> ${to}`);

  console.log('');
  console.log('Verifying target Plated user(s) exist...');
  for (const platedId of new Set(userMap.values())) {
    const exists = await platedUserExists(platedId);
    if (!exists) {
      console.error(`Plated user ${platedId} not found (checked via the Admin Auth API) — aborting.`);
      process.exit(1);
    }
  }
  console.log('  ok');

  // Existing Plated rows for the target user(s), to make re-runs safe —
  // lifts and weight_log have no unique constraint to lean on, so dedup
  // is done here instead. exercise_goals is unique on (user_id, exercise)
  // already, so it's upserted natively and needs no manual dedup.
  console.log('');
  console.log('Fetching existing Plated rows for dedup...');
  const targetUserIds = Array.from(new Set(userMap.values()));
  const inFilter = `in.(${targetUserIds.join(',')})`;
  const [existingLifts, existingWeightLog] = await Promise.all([
    restGetAll(platedUrl, platedHeaders, 'lifts', `select=user_id,exercise,date,weight,reps_per_set&user_id=${inFilter}`),
    restGetAll(platedUrl, platedHeaders, 'weight_log', `select=user_id,logged_date&user_id=${inFilter}`),
  ]);
  const existingLiftSigs = new Set(
    existingLifts.map((l) => `${l.user_id}|${l.exercise}|${l.date}|${l.weight}|${JSON.stringify(l.reps_per_set)}`)
  );
  const existingWeightDates = new Set(existingWeightLog.map((w) => `${w.user_id}|${w.logged_date}`));

  // ── lifts ──
  const liftsToInsert = [];
  let liftsSkippedDup = 0;
  for (const l of ironlogLifts) {
    const targetUser = userMap.get(l.user_id);
    const sig = `${targetUser}|${l.exercise}|${l.date}|${l.weight}|${JSON.stringify(l.reps_per_set)}`;
    if (existingLiftSigs.has(sig)) { liftsSkippedDup++; continue; }
    existingLiftSigs.add(sig); // guard against duplicates within IronLog's own data too
    liftsToInsert.push({
      user_id: targetUser,
      exercise: l.exercise,
      muscle_group: l.muscle_group,
      weight: l.weight,
      sets: l.sets,
      reps_per_set: l.reps_per_set,
      reps: l.reps,
      date: l.date,
      superset_group: l.superset_group,
      body_region: l.body_region,
    });
  }

  // ── bodyweight -> weight_log ──
  // Skipped (not overwritten) when the target user already has a Plated
  // weight_log entry for that date — an existing same-day entry logged
  // directly in Plated is treated as the source of truth for that day.
  const weightLogToInsert = [];
  let weightSkippedExisting = 0;
  for (const b of ironlogBodyweight) {
    const targetUser = userMap.get(b.user_id);
    const key = `${targetUser}|${b.date}`;
    if (existingWeightDates.has(key)) { weightSkippedExisting++; continue; }
    existingWeightDates.add(key);
    weightLogToInsert.push({
      user_id: targetUser,
      weight_lb: b.weight,
      logged_date: b.date,
      note: 'Migrated from IronLog',
    });
  }

  // ── goals -> exercise_goals (native upsert, no manual dedup needed) ──
  const goalsToUpsert = ironlogGoals.map((g) => ({
    user_id: userMap.get(g.user_id),
    exercise: g.exercise,
    target_weight: g.target_weight,
    target_date: g.target_date,
  }));

  console.log('');
  console.log('Summary:');
  console.log(`  lifts:       ${liftsToInsert.length} to insert, ${liftsSkippedDup} already present (skipped)`);
  console.log(`  weight_log:  ${weightLogToInsert.length} to insert, ${weightSkippedExisting} dates already logged in Plated (skipped)`);
  console.log(`  exercise_goals: ${goalsToUpsert.length} to upsert`);

  if (!EXECUTE) {
    console.log('');
    console.log('Dry run only — nothing written. Re-run with --execute to apply.');
    return;
  }

  console.log('');
  console.log('Writing...');
  const liftsInserted = await restInsertBatched(platedUrl, platedHeaders, 'lifts', liftsToInsert);
  console.log(`  lifts: inserted ${liftsInserted}`);
  const weightInserted = await restInsertBatched(platedUrl, platedHeaders, 'weight_log', weightLogToInsert);
  console.log(`  weight_log: inserted ${weightInserted}`);
  const goalsUpserted = await restUpsertBatched(platedUrl, platedHeaders, 'exercise_goals', goalsToUpsert, 'user_id,exercise');
  console.log(`  exercise_goals: upserted ${goalsUpserted}`);
  console.log('');
  console.log('Done.');
}

main().catch((err) => {
  console.error('');
  console.error('Migration failed:', err.message || err);
  process.exit(1);
});
