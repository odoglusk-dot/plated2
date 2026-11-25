// Smart Program batch, Phase 8: one canonical screenshot per phone (1-9),
// saved to docs/smart-program-shots/ for the fidelity report. Run with a
// local http-server already serving the repo root on :8911 (same
// convention as scripts/app-shots.js).
import { chromium } from 'playwright';
import { installMocks, gotoApp, FAKE_PROFILE, ACTIVE_BLOCK } from './seed-demo.js';
import fs from 'fs';

const baseUrl = 'http://localhost:8911';
const outDir = new URL('../docs/smart-program-shots/', import.meta.url).pathname;
fs.mkdirSync(outDir, { recursive: true });

function daysAgoStr(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

async function freshPage(browser, blockOverrides = {}) {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  FAKE_PROFILE.active_training_block = { ...ACTIVE_BLOCK, ...blockOverrides };
  FAKE_PROFILE.schedule_overrides_this_week = {};
  await installMocks(page);
  await gotoApp(page, baseUrl);
  return page;
}

async function openExerciseA2(page, name) {
  await page.evaluate(() => { const t = [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^today$/i.test((b.textContent || '').trim())); t?.click(); });
  await page.waitForTimeout(250);
  await page.evaluate(() => { document.querySelector('#plusFab')?.click(); });
  await page.waitForTimeout(250);
  await page.evaluate(() => { [...document.querySelectorAll('.plus-sheet button,.plus-sheet [data-plus-tile]')].find((b) => /set/i.test(b.textContent || ''))?.click(); });
  await page.waitForTimeout(250);
  await page.evaluate((n) => { document.querySelector(`[data-pls-log="${n}"]`)?.click(); }, name);
  await page.waitForTimeout(250);
  await page.evaluate(() => { document.querySelector('#plsOpenFullBtn')?.click(); });
  await page.waitForTimeout(250);
}

async function openBlockView(page) {
  await page.evaluate(() => { const t = [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^progress$/i.test((b.textContent || '').trim())); t?.click(); });
  await page.waitForTimeout(250);
  await page.evaluate(() => { document.querySelector('#progressPlansBlocksRow')?.click(); });
  await page.waitForTimeout(250);
  await page.evaluate(() => { document.querySelector('#blockBuilderViewBtn')?.click(); });
  await page.waitForTimeout(250);
}

async function run() {
  const browser = await chromium.launch();

  // Phone 1: How targets are set
  {
    const page = await freshPage(browser);
    await openExerciseA2(page, 'Barbell Bench Press');
    await page.evaluate(() => { [...document.querySelectorAll('a,span,button')].find((e) => /how targets are set/i.test(e.textContent || ''))?.click(); });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-1-how-targets-are-set.png' });
    await page.close();
  }

  // Phone 2: Block view
  {
    const page = await freshPage(browser, { blockStartDate: daysAgoStr(14), blockLength: 6, blockNumber: 2, createdDate: daysAgoStr(14) });
    await openBlockView(page);
    await page.screenshot({ path: outDir + 'phone-2-block-view.png' });
    await page.close();
  }

  // Phone 3: Deload suggestion
  {
    const page = await freshPage(browser, { blockStartDate: daysAgoStr(35), blockLength: 6, blockNumber: 1, createdDate: daysAgoStr(35) });
    await openBlockView(page);
    await page.evaluate(() => { document.querySelector('#deloadSuggestionBanner')?.click(); });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-3-deload.png' });
    await page.close();
  }

  // Phone 4: Block review
  {
    const page = await freshPage(browser, { blockStartDate: daysAgoStr(45), blockLength: 6, blockNumber: 1, createdDate: daysAgoStr(45) });
    await openBlockView(page);
    await page.screenshot({ path: outDir + 'phone-4-block-review.png' });
    await page.close();
  }

  // Phone 5: Missed session
  {
    const page = await freshPage(browser);
    await page.evaluate(() => { document.querySelector('#missedSessionBanner')?.click(); });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-5-missed-session.png' });
    await page.close();
  }

  // Phone 6: Welcome back
  {
    const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
    FAKE_PROFILE.active_training_block = { ...ACTIVE_BLOCK, createdDate: daysAgoStr(16) };
    FAKE_PROFILE.schedule_overrides_this_week = {};
    await installMocks(page);
    await page.route('**/rest/v1/lifts*', async (route) => {
      if (route.request().method() === 'GET') {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([
          { id: 1, user_id: 'demo-user-1', exercise: 'Barbell Bench Press', date: daysAgoStr(16), weight: 135, sets: 1, reps_per_set: [8], reps: 8 },
        ]) });
      }
      return route.continue();
    });
    await gotoApp(page, baseUrl);
    await page.evaluate(() => { document.querySelector('#welcomeBackBanner')?.click(); });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-6-welcome-back.png' });
    await page.close();
  }

  // Phone 7: Weekly volume
  {
    const page = await freshPage(browser, { priorities: ['quads'] });
    await page.evaluate(() => { const t = [...document.querySelectorAll('button,a,[role="tab"]')].find((b) => /^progress$/i.test((b.textContent || '').trim())); t?.click(); });
    await page.waitForTimeout(250);
    await page.evaluate(() => { document.querySelector('#progressWeeklyVolumeRow')?.click(); });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-7-weekly-volume.png' });
    await page.close();
  }

  // Phone 8: Smart swap step 1
  {
    const page = await freshPage(browser);
    await openExerciseA2(page, 'Barbell Bench Press');
    await page.evaluate(() => { document.querySelector('#exSwapBtn')?.click(); });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-8-swap-step1.png' });
    await page.close();
  }

  // Phone 9: Smart swap step 2
  {
    const page = await freshPage(browser);
    await openExerciseA2(page, 'Barbell Bench Press');
    await page.evaluate(() => { document.querySelector('#exSwapBtn')?.click(); });
    await page.waitForTimeout(250);
    await page.evaluate(() => {
      const row = [...document.querySelectorAll('[data-swap-pick]')].find((b) => b.dataset.swapPick === 'Incline Dumbbell Press');
      row?.click();
    });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outDir + 'phone-9-swap-step2.png' });
    await page.close();
  }

  await browser.close();
  console.log('done');
}

run().catch((e) => { console.error(e); process.exit(1); });
