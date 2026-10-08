#!/usr/bin/env node
// Copies the web app's pages/assets into www/ — the Capacitor iOS wrapper's
// web dir — before `npx cap sync ios` picks them up. Run via `npm run
// sync:ios`, never by hand; add a new path here whenever a page gains a
// new asset reference, same rule as updating index.html's own <link>/<img>
// tags.
import { cpSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url))); // repo root
const www = join(root, 'www');

// Every page the app itself navigates to or links out to — NOT admin.html
// (a separate internal tool, never opened from inside the consumer app).
const FILES = [
  'index.html', 'manifest.json',
  'privacy.html', 'terms.html', 'support.html', 'auth-callback.html',
];
// vendor/ holds the self-hosted JS bundles and font files (pre-launch fix —
// see vendor/README.md) that used to be loaded live from esm.sh/jsdelivr/
// Google Fonts at runtime.
const DIRS = ['icons', 'vendor'];

mkdirSync(www, { recursive: true });

let missingRequired = false;
for (const file of FILES) {
  const src = join(root, file);
  if (!existsSync(src)) {
    const required = file === 'index.html';
    console[required ? 'error' : 'warn'](`sync:ios — ${required ? 'MISSING REQUIRED FILE' : 'skipping missing file'}: ${file}`);
    if (required) missingRequired = true;
    continue;
  }
  cpSync(src, join(www, file));
  console.log(`copied ${file}`);
}

for (const dir of DIRS) {
  const src = join(root, dir);
  if (!existsSync(src)) { console.warn(`sync:ios — skipping missing dir: ${dir}`); continue; }
  cpSync(src, join(www, dir), { recursive: true });
  console.log(`copied ${dir}/`);
}

// Fail loudly rather than silently syncing a stale/empty www/ into the iOS
// build — a missing index.html here means the app would ship with nothing.
if (missingRequired || !existsSync(join(www, 'index.html'))) {
  console.error('sync:ios — www/index.html is missing after copy. Aborting before `cap sync`.');
  process.exit(1);
}

console.log('www/ is up to date.');
