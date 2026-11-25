// Krafft SMART PROGRAM batch, Phase 7: content lint for this branch's
// EVIDENCE_CONFIG in index.html. Mirrors the goals batch's
// scripts/lint-evidence.js (same rules, same reasoning) - kept as a
// separate file rather than a shared one since the two EVIDENCE_CONFIG
// objects live on different, still-unmerged branches; reconcile by
// merging the two lint scripts (they're near-identical) once both land
// on the same branch.
const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, '..', 'index.html');
const html = fs.readFileSync(indexPath, 'utf8');

function extractConst(name) {
  const marker = `const ${name} = `;
  const start = html.indexOf(marker);
  if (start === -1) throw new Error(`Could not find ${name} in index.html`);
  const bodyStart = start + marker.length;
  let depth = 0;
  let i = bodyStart;
  let started = false;
  for (; i < html.length; i++) {
    const ch = html[i];
    if (ch === '{' || ch === '[') { depth++; started = true; }
    else if (ch === '}' || ch === ']') { depth--; if (started && depth === 0) { i++; break; } }
  }
  const literal = html.slice(bodyStart, i);
  // eslint-disable-next-line no-eval
  return eval(`(${literal})`);
}

const EVIDENCE_CONFIG = extractConst('EVIDENCE_CONFIG');
const BANNED_WORDS = ['proven', 'guarantee', 'guaranteed', 'will make you', 'will build', 'will get you'];

const errors = [];
const warnings = [];

function checkBannedWords(text, where) {
  const lower = text.toLowerCase();
  for (const word of BANNED_WORDS) {
    if (lower.includes(word.toLowerCase())) errors.push(`${where}: contains banned over-claiming phrase "${word}"`);
  }
}
function checkNoNumbers(text, where) {
  if (/%/.test(text)) errors.push(`${where}: contains a percent sign - numbers belong only in citations[].finding`);
  if (/\beffect size\b/i.test(text) || /\bES\s*[\d.]/i.test(text)) errors.push(`${where}: contains an effect-size figure - numbers belong only in citations[].finding`);
}

const VALID_LABELS = new Set(['strong', 'moderate', 'limited']);

for (const [id, entry] of Object.entries(EVIDENCE_CONFIG)) {
  const where = `EVIDENCE_CONFIG.${id}`;
  if (!entry.plainAnswer) errors.push(`${where}: missing plainAnswer`);
  if (!entry.meansForYou) errors.push(`${where}: missing meansForYou`);
  if (!VALID_LABELS.has(entry.label)) errors.push(`${where}: label "${entry.label}" must be one of strong/moderate/limited`);
  if (entry.label !== 'limited' && (!entry.citations || entry.citations.length === 0)) {
    errors.push(`${where}: label "${entry.label}" requires at least one citation (only "limited" may cite none)`);
  }
  if (entry.plainAnswer) { checkBannedWords(entry.plainAnswer, `${where}.plainAnswer`); checkNoNumbers(entry.plainAnswer, `${where}.plainAnswer`); }
  if (entry.meansForYou) { checkBannedWords(entry.meansForYou, `${where}.meansForYou`); checkNoNumbers(entry.meansForYou, `${where}.meansForYou`); }
  (entry.citations || []).forEach((c, i) => {
    const cWhere = `${where}.citations[${i}]`;
    if (c.verified !== false) warnings.push(`${cWhere}: verified is ${JSON.stringify(c.verified)}, not the unverified default (false) - confirm Owen actually checked this against the paper abstract before shipping`);
    if (!c.authors || !c.year || !c.journal || !c.finding) errors.push(`${cWhere}: missing one of authors/year/journal/finding`);
  });
}

if (warnings.length) {
  console.warn(`\n${warnings.length} verification warning(s):`);
  warnings.forEach((w) => console.warn(`  - ${w}`));
}

if (errors.length) {
  console.error(`\n${errors.length} content-rule error(s):`);
  errors.forEach((e) => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`evidence lint passed: ${Object.keys(EVIDENCE_CONFIG).length} entries checked, 0 content-rule errors, ${warnings.length} verification warning(s).`);
