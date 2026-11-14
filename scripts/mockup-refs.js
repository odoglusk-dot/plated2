// Fidelity pass, Step 0: extracts one reference PNG per phone in the
// mockup HTML, scaled from its 290x600 (274x584 inner .scr) mockup frame
// up to real iPhone scale (390/274 = 1.4234), via CSS zoom on .ph (which,
// unlike transform:scale, actually changes the element's layout box, so
// screenshotting .scr afterward captures it at the scaled-up size).
import { chromium } from 'playwright';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const mockupPath = path.join(repoRoot, 'docs/krafft-training-redesign-full-mockup.html');
const outDir = path.join(repoRoot, 'docs/mockup-ref');
const SCALE = 390 / 274;

const SECTION_FOR_HEADING = (h2) => {
  const t = h2.trim();
  if (t.startsWith('3b.')) return '3b';
  const m = t.match(/^(\d+)\./);
  return m ? m[1] : 'x';
};

function slugify(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);
}

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 2 });
  await page.goto('file://' + mockupPath);

  // Walk the DOM in document order: each h2 starts a section; each
  // following .phones block (until the next h2) holds that section's
  // phones, each phone being one <div><div class="ph">...</div></div>
  // <div class="cap">caption</div> triple.
  const manifest = await page.evaluate(() => {
    const items = [];
    let section = null;
    let n = 0;
    for (const el of document.querySelectorAll('h2, .phones')) {
      if (el.tagName === 'H2') { section = el.textContent; n = 0; continue; }
      // .phones block
      for (const wrap of el.children) {
        const ph = wrap.querySelector(':scope > .ph');
        const cap = wrap.querySelector(':scope > .cap');
        if (!ph) continue;
        n += 1;
        const id = `ph-${items.length}`;
        ph.setAttribute('data-ref-id', id);
        items.push({ id, section, n, caption: cap ? cap.textContent.trim() : '' });
      }
    }
    return items;
  });

  console.log(`Found ${manifest.length} phones.`);

  const results = [];
  for (const item of manifest) {
    const sectionSlug = SECTION_FOR_HEADING(item.section);
    const capSlug = slugify(item.caption) || 'untitled';
    const fileName = `${sectionSlug}-${item.n}-${capSlug}.png`;
    const filePath = path.join(outDir, fileName);

    const phHandle = await page.$(`[data-ref-id="${item.id}"]`);
    await phHandle.evaluate((el) => { el.style.zoom = String(390 / 274); });
    const scrHandle = await phHandle.$('.scr');
    await scrHandle.screenshot({ path: filePath });
    await phHandle.evaluate((el) => { el.style.zoom = '1'; }); // reset so later elements aren't affected by layout shift

    results.push({ file: fileName, section: sectionSlug, n: item.n, caption: item.caption });
    console.log(`  ${fileName}  <-  "${item.caption}"`);
  }

  await browser.close();

  fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(results, null, 2));
  console.log(`\nWrote ${results.length} reference PNGs + manifest.json to ${outDir}`);
})();
