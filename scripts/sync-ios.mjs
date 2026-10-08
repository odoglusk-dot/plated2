#!/usr/bin/env node
// Copies the web app's pages/assets into www/ — the Capacitor iOS wrapper's
// web dir — before `npx cap sync ios` picks them up. Run via `npm run
// sync:ios`, never by hand; add a new path here whenever a page gains a
// new asset reference, same rule as updating index.html's own <link>/<img>
// tags.
import { cpSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url))); // plated/
const www = join(root, 'www');

const FILES = ['index.html', 'manifest.json'];
const DIRS = ['icons'];

mkdirSync(www, { recursive: true });

for (const file of FILES) {
  const src = join(root, file);
  if (!existsSync(src)) { console.warn(`sync:ios — skipping missing file: ${file}`); continue; }
  cpSync(src, join(www, file));
  console.log(`copied ${file}`);
}

for (const dir of DIRS) {
  const src = join(root, dir);
  if (!existsSync(src)) { console.warn(`sync:ios — skipping missing dir: ${dir}`); continue; }
  cpSync(src, join(www, dir), { recursive: true });
  console.log(`copied ${dir}/`);
}

console.log('www/ is up to date.');
