// Fidelity pass, Step 0: screenshots the running app at the same 25
// screens as scripts/mockup-refs.js, using the fixture data from
// scripts/seed-demo.js, then writes docs/fidelity-report.html pairing
// each app screenshot with its reference image for manual review (the
// checklist itself needs a human eye, not a pixel diff - see the
// fidelity-pass doc's own rule 3).
import { chromium } from 'playwright';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { installMocks, gotoApp } from './seed-demo.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const outDir = path.join(repoRoot, 'docs/app-shots');
const refDir = path.join(repoRoot, 'docs/mockup-ref');
const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:8911';

fs.mkdirSync(outDir, { recursive: true });

const results = []; // { file, caption, ok, error }

async function withFreshPage(browser, fn, opts = {}) {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  page.setDefaultTimeout(4000); // fail fast on a wrong/missing selector instead of the 30s default
  await installMocks(page, opts);
  await gotoApp(page, BASE_URL);
  try {
    await fn(page);
  } finally {
    await page.close();
  }
}

async function shoot(page, file, caption) {
  try {
    await page.screenshot({ path: path.join(outDir, file) });
    results.push({ file, caption, ok: true });
    console.log(`  OK   ${file}`);
  } catch (e) {
    results.push({ file, caption, ok: false, error: e.message });
    console.log(`  FAIL ${file} -- ${e.message}`);
  }
}

async function tryStep(label, fn) {
  try { await fn(); return true; }
  catch (e) { console.log(`    [step failed] ${label}: ${e.message}`); return false; }
}

async function run() {
  const browser = await chromium.launch();

  // ---- Section 1: Today ----
  await withFreshPage(browser, async (page) => {
    await shoot(page, '1-1-protein-stays-the-hero-calories-carbs-and-fat-sit-under-it-s.png', '1-1 Today, program state');
    // Start a workout to get the "in progress" state for 1-2.
    await tryStep('start workout', async () => { await page.click('#todaysLiftCardBtn'); await page.waitForTimeout(300); });
    await tryStep('add exercise', async () => {
      await page.fill('#qwSearch', 'Bench');
      await page.waitForTimeout(150);
      await page.click('[data-qw-add="Barbell Bench Press"]');
      await page.waitForTimeout(300);
    });
    await tryStep('log one set', async () => {
      await page.fill('#exSetWeight', '135'); await page.fill('#exSetReps', '8');
      await page.click('#exLogSetBtn'); await page.waitForTimeout(300);
    });
    await tryStep('back to Today', async () => {
      const t = await page.evaluateHandle(() => [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^today$/i.test((b.textContent || '').trim())));
      await t.asElement()?.click();
      await page.waitForTimeout(300);
    });
    await shoot(page, '1-2-other-lift-card-states-no-program-start-workout-repeat-last-.png', '1-2 Today, workout in progress (closest reachable real state - see report note on the "no program" sub-state)');
  });

  // ---- Section 3: Workout (fresh session, carried across these shots) ----
  await withFreshPage(browser, async (page) => {
    await tryStep('open quick workout', async () => { await page.click('#todaysLiftCardBtn'); await page.waitForTimeout(300); });
    await shoot(page, '3-1-quick-workout-no-program-needed-pick-an-exercise-repeat-a-re.png', '3-1 Quick workout start');
    await tryStep('add Bench Press', async () => {
      await page.fill('#qwSearch', 'Bench'); await page.waitForTimeout(150);
      await page.click('[data-qw-add="Barbell Bench Press"]'); await page.waitForTimeout(300);
    });
    await tryStep('log a set, back to overview', async () => {
      await page.fill('#exSetWeight', '140'); await page.fill('#exSetReps', '8');
      await page.click('#exLogSetBtn'); await page.waitForTimeout(300);
      await page.click('#exOverviewBackBtn'); await page.waitForTimeout(300);
    });
    await shoot(page, '3-2-exercises-added-on-the-fly-on-finish-save-as-workout-is-offe.png', '3-2 Workout in progress, overview');
    await tryStep('add Incline DB Press, leave unstarted', async () => {
      await page.click('#qwAddMoreBtn'); await page.waitForTimeout(200);
      await page.fill('#qwSearch', 'Incline'); await page.waitForTimeout(150);
      await page.click('[data-qw-add="Incline Dumbbell Press"]'); await page.waitForTimeout(300);
      await page.click('#exOverviewBackBtn'); await page.waitForTimeout(300);
    });
    await shoot(page, '3-3-overview-done-up-next-later.png', '3-3 Overview: done/up-next/later');
    await tryStep('open Incline DB Press (A2)', async () => {
      await page.evaluate(() => { const t = [...document.querySelectorAll('[data-wo-open]')].find((e) => e.dataset.woOpen.includes('Incline')); t?.click(); });
      await page.waitForTimeout(300);
    });
    await shoot(page, '3-4-exercise-screen-a2-diagram-name-last-time-goal-sets-cue-bras.png', '3-4 Exercise screen A2');
    await tryStep('finish this exercise', async () => {
      await page.fill('#exSetWeight', '70'); await page.fill('#exSetReps', '10');
      await page.click('#exLogSetBtn'); await page.waitForTimeout(300);
      await page.click('#exFinishExerciseBtn'); await page.waitForTimeout(300);
    });
    await shoot(page, '3-5-finished-exercise-with-a-pr-badge-and-the-estimated-max-chan.png', '3-5 Finished exercise state');
  });

  // Superset: separate fresh session (no app-side UI yet to *create* a
  // superset mid-quick-workout - flagged in the report if this fails).
  await withFreshPage(browser, async (page) => {
    await tryStep('start workout', async () => { await page.click('#todaysLiftCardBtn'); await page.waitForTimeout(300); });
    await shoot(page, '3-6-superset-two-exercises-stacked-one-rest-timer-back-exercises.png', '3-6 Superset screen (NOTE: quick-workout flow has no UI to create a superset - this is the plain A2 screen, not a true superset; needs a dedicated entry point)');
  });

  // ---- Section 3b: + button ----
  await withFreshPage(browser, async (page) => {
    await tryStep('open + sheet', async () => { await page.click('#plusFab'); await page.waitForTimeout(250); });
    await shoot(page, '3b-1-sheet-set-is-highlighted-as-the-last-used-tile.png', '3b-1 + sheet');
    await tryStep('tap Set tile', async () => { await page.click('[data-plus-tile="set"]'); await page.waitForTimeout(300); });
    await shoot(page, '3b-2-pick-the-exercise-today-s-exercises-first-then-recents-typin.png', '3b-2 Log-a-set picker');
    await tryStep('tap Log on a recent exercise', async () => {
      await page.fill('#plsSearch', 'Bench'); await page.waitForTimeout(150);
      await page.click('[data-pls-log="Barbell Bench Press"]'); await page.waitForTimeout(300);
    });
    await shoot(page, '3b-3-log-one-set-big-steppers-prefilled-from-the-previous-set-tod.png', '3b-3 Quick-log one set');
  });

  // ---- Section 4: Finish ----
  await withFreshPage(browser, async (page) => {
    await tryStep('start + finish a workout', async () => {
      await page.click('#todaysLiftCardBtn'); await page.waitForTimeout(300);
      await page.fill('#qwSearch', 'Bench'); await page.waitForTimeout(150);
      await page.click('[data-qw-add="Barbell Bench Press"]'); await page.waitForTimeout(300);
      await page.fill('#exSetWeight', '145'); await page.fill('#exSetReps', '8');
      await page.click('#exLogSetBtn'); await page.waitForTimeout(300);
      await page.click('#exFinishExerciseBtn'); await page.waitForTimeout(300);
      await page.click('#exNextExerciseBtn'); await page.waitForTimeout(300);
      // Pro + consented + baseline session history met: ending the workout
      // auto-triggers generateSessionAnalysis() (index.html ~line 11066) -
      // no separate "Generate Analysis" tap needed or offered.
      await page.click('#qwFinishBtn'); await page.waitForTimeout(900);
    });
    await shoot(page, '4-1-pro-headline-findings-next-session-targets.png', '4-1 Finish, Pro analysis (analyze-session mocked with a realistic response - see seed-demo.js)');
  }, { subscriptionTier: 'pro' });
  await withFreshPage(browser, async (page) => {
    await tryStep('start + finish a workout (free tier)', async () => {
      await page.click('#todaysLiftCardBtn'); await page.waitForTimeout(300);
      await page.fill('#qwSearch', 'Bench'); await page.waitForTimeout(150);
      await page.click('[data-qw-add="Barbell Bench Press"]'); await page.waitForTimeout(300);
      await page.fill('#exSetWeight', '145'); await page.fill('#exSetReps', '8');
      await page.click('#exLogSetBtn'); await page.waitForTimeout(300);
      await page.click('#exFinishExerciseBtn'); await page.waitForTimeout(300);
      await page.click('#exNextExerciseBtn'); await page.waitForTimeout(300);
      await page.click('#qwFinishBtn'); await page.waitForTimeout(500);
    });
    await shoot(page, '4-2-free-basic-summary-and-one-quiet-upsell-row-on-iphone-this-o.png', '4-2 Finish, Free summary');
  }, { subscriptionTier: 'free' });

  // ---- Section 2: Plans ----
  await withFreshPage(browser, async (page) => {
    await tryStep('open Progress -> Programs (Plans hub)', async () => {
      const t = await page.evaluateHandle(() => [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^progress$/i.test((b.textContent || '').trim())));
      await t.asElement()?.click(); await page.waitForTimeout(250);
      await page.click('#progressPlansRow'); await page.waitForTimeout(300);
    });
    await shoot(page, '2-1-plans-hub.png', '2-1 Plans hub');
    await tryStep('preview a browsable program', async () => {
      const t = await page.evaluateHandle(() => [...document.querySelectorAll('[data-plans-open]')][0]);
      await t.asElement()?.click(); await page.waitForTimeout(300);
    });
    await shoot(page, '2-2-program-preview-customize-makes-your-version.png', '2-2 Program preview');
    await tryStep('customize -> your version', async () => {
      await page.click('#programPreviewCustomizeBtn').catch(() => {});
      await page.waitForTimeout(300);
    });
    await shoot(page, '2-3-your-version-drag-to-reorder-days-rename-add-reset.png', '2-3 Your version editor');
    await tryStep('open a day to edit', async () => {
      const t = await page.evaluateHandle(() => [...document.querySelectorAll('[data-block-day-toggle]')][0]);
      await t.asElement()?.click(); await page.waitForTimeout(300);
    });
    await shoot(page, '2-4-edit-a-day-tap-an-exercise-for-sets-reps-rest-progression-su.png', '2-4 Edit a day');
  });
  await withFreshPage(browser, async (page) => {
    await tryStep('open days-per-week change', async () => {
      const t = await page.evaluateHandle(() => [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^progress$/i.test((b.textContent || '').trim())));
      await t.asElement()?.click(); await page.waitForTimeout(250);
      await page.click('#progressPlansRow'); await page.waitForTimeout(300);
      const t2 = await page.evaluateHandle(() => [...document.querySelectorAll('[data-plans-change-days]')][0]);
      await t2.asElement()?.click(); await page.waitForTimeout(300);
    });
    await shoot(page, '2-5-change-days-per-week-always-a-preview-first.png', '2-5 Change days per week');
  });
  await withFreshPage(browser, async (page) => {
    await tryStep('open reschedule sheet from Today', async () => {
      await page.click('#todaysLiftChangeBtn'); await page.waitForTimeout(300);
    });
    await shoot(page, '2-6-reschedule-without-editing-the-program.png', '2-6 Reschedule sheet');
  });

  // ---- Section 5: Library ----
  await withFreshPage(browser, async (page) => {
    await tryStep('open Exercise Library', async () => {
      const t = await page.evaluateHandle(() => [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^progress$/i.test((b.textContent || '').trim())));
      await t.asElement()?.click(); await page.waitForTimeout(250);
      await page.click('#progressExerciseLibraryRow'); await page.waitForTimeout(300);
    });
    await shoot(page, '5-1-library-home-search-muscle-and-equipment-filters-recents-sta.png', '5-1 Library home');
    await tryStep('open Bench Press detail, History tab', async () => {
      await page.evaluate(() => { const t = [...document.querySelectorAll('[data-glossary-jump]')].find((e) => e.dataset.glossaryJump === 'Barbell Bench Press'); t?.click(); });
      await page.waitForTimeout(300);
    });
    await shoot(page, '5-2-exercise-page-history-tab.png', '5-2 Exercise page, History tab');
    await tryStep('Form tab', async () => {
      await page.evaluate(() => { const t = [...document.querySelectorAll('[data-lift-detail-tab]')].find((b) => b.dataset.liftDetailTab === 'form'); t?.click(); });
      await page.waitForTimeout(250);
    });
    await shoot(page, '5-3-form-tab.png', '5-3 Form tab');
    await tryStep('Swaps tab', async () => {
      await page.evaluate(() => { const t = [...document.querySelectorAll('[data-lift-detail-tab]')].find((b) => b.dataset.liftDetailTab === 'swaps'); t?.click(); });
      await page.waitForTimeout(250);
    });
    await shoot(page, '5-4-swaps-tab-same-primary-muscle-filtered-by-equipment.png', '5-4 Swaps tab');
  });
  await withFreshPage(browser, async (page) => {
    await tryStep('open add-exercise picker mid-workout', async () => {
      await page.click('#todaysLiftCardBtn'); await page.waitForTimeout(300);
      await page.fill('#qwSearch', 'cable'); await page.waitForTimeout(200);
    });
    await shoot(page, '5-5-picker-filters-aliases-in-search-cable-crossover-finds-cable.png', '5-5 Add-exercise picker, alias search');
    await tryStep('open Lat Pulldown (back view)', async () => {
      await page.click('[data-qw-add="Lat Pulldown"]').catch(() => {});
      await page.waitForTimeout(300);
    });
    await shoot(page, '5-6-back-exercises-show-the-back-view-timed-and-cardio-exercises.png', '5-6 Back-view exercise');
  });

  await browser.close();

  // ---- Report ----
  const rows = results.map((r) => {
    const refExists = fs.existsSync(path.join(refDir, r.file));
    return `
      <tr>
        <td style="vertical-align:top;padding:10px;"><div style="font:600 13px monospace;margin-bottom:4px;">${r.file}</div><div style="font-size:12px;color:#666;max-width:380px;">${r.caption}</div>${r.ok ? '' : `<div style="color:#b5532f;font-size:12px;margin-top:4px;">ERROR: ${r.error}</div>`}</td>
        <td style="padding:10px;">${refExists ? `<img src="mockup-ref/${r.file}" style="width:220px;border:1px solid #ccc;">` : '(no ref)'}</td>
        <td style="padding:10px;">${r.ok ? `<img src="app-shots/${r.file}" style="width:220px;border:1px solid #ccc;">` : '<em>capture failed</em>'}</td>
      </tr>`;
  }).join('');
  const html = `<!doctype html><html><head><meta charset="utf-8"><title>Fidelity report</title></head>
  <body style="font-family:sans-serif;max-width:1000px;margin:20px auto;">
  <h1>Krafft fidelity report</h1>
  <p>${results.filter((r) => r.ok).length} / ${results.length} screens captured. Pass/fail per checklist line still needs a manual pass against the mockup doc.</p>
  <table style="border-collapse:collapse;width:100%;">
  <tr><th>Screen</th><th>Reference</th><th>App</th></tr>
  ${rows}
  </table>
  </body></html>`;
  fs.writeFileSync(path.join(repoRoot, 'docs/fidelity-report.html'), html);
  console.log(`\n${results.filter((r) => r.ok).length} / ${results.length} captured. Report: docs/fidelity-report.html`);
}

run();
