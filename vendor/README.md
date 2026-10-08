# vendor/

Self-hosted replacements for what used to be loaded live from esm.sh,
jsdelivr, and Google Fonts at runtime. Loading those from a CDN broke true
offline use in the iOS wrapper after first launch and sent the user's IP
to each of those hosts on every cold start — this directory fixes both.

These files are build output, not hand-written, and not npm-managed in
this repo (the project intentionally has no bundler/build step — see
`netlify/functions/_shared.js`'s header comment). They were produced once
with `esbuild` from the real npm packages and are committed directly.
`scripts/sync-ios.mjs` copies this whole directory into `www/` like any
other static asset.

## vendor/js/

| File | Source package | How it was built |
|---|---|---|
| `supabase-js.js` | `@supabase/supabase-js@2` | `esbuild` bundle, ESM, `export * from '@supabase/supabase-js'` |
| `capacitor-core.js` | `@capacitor/core@6` | same, ESM |
| `capacitor-app.js` | `@capacitor/app@6` | same, ESM |
| `capacitor-browser.js` | `@capacitor/browser@6` | same, ESM |
| `zxing-library.js` | `@zxing/library@0.21.3` | `esbuild` minify of the package's own `umd/index.min.js` (attaches `window.ZXing`, unchanged) |
| `chart.js` | `chart.js@4.4.4` | `esbuild` minify of the package's own `dist/chart.umd.js` (attaches `window.Chart`, unchanged) |

`index.html` imports the four ESM files directly (`import { createClient } from './vendor/js/supabase-js.js'`, etc.) and loads the two UMD files via a plain `<script src>` injected lazily on first use, exactly as it did with the CDN URLs — only the `src` changed.

## vendor/fonts/

Self-hosted Fraunces/Inter/IBM Plex Mono, replacing the
`fonts.googleapis.com` `<link>`. Extracted from the `@fontsource` npm
packages (latin subset only — this app's UI is English-only):

| File | Package | Covers |
|---|---|---|
| `fraunces-latin-standard-normal.woff2` | `@fontsource-variable/fraunces@5` | Variable font, weight 100–900 (the app uses 500/600/700); `font-optical-sizing: auto` (default) handles the opsz axis the old Google Fonts URL requested explicitly |
| `inter-latin-{400,500,600,700}-normal.woff2` | `@fontsource/inter@5` | Static weights, matching the old URL's `Inter:wght@400;500;600;700` |
| `ibm-plex-mono-latin-{400,600}-normal.woff2` | `@fontsource/ibm-plex-mono@5` | Static weights, matching the old URL's `IBM+Plex+Mono:wght@400;600` |

The `@font-face` rules are in `index.html`'s `<style>` block, right above `:root`. Font family names match exactly what the app's `--font-display`/`--font-body`/`--font-mono` CSS variables already reference (`'Fraunces'`, `'Inter'`, `'IBM Plex Mono'`) — no other CSS changed.

## Regenerating

If a version ever needs bumping:

```bash
mkdir /tmp/krafft-vendor-build && cd /tmp/krafft-vendor-build
echo '{"name":"krafft-vendor-build","private":true}' > package.json
npm install esbuild @supabase/supabase-js@2 @capacitor/core@6 @capacitor/app@6 \
  @capacitor/browser@6 @zxing/library@0.21.3 chart.js@4.4.4 \
  @fontsource-variable/fraunces@5 @fontsource/inter@5 @fontsource/ibm-plex-mono@5

echo "export * from '@supabase/supabase-js';" > e-supabase.mjs
echo "export * from '@capacitor/core';" > e-core.mjs
echo "export * from '@capacitor/app';" > e-app.mjs
echo "export * from '@capacitor/browser';" > e-browser.mjs
npx esbuild e-supabase.mjs --bundle --format=esm --minify --outfile=supabase-js.js
npx esbuild e-core.mjs --bundle --format=esm --minify --outfile=capacitor-core.js
npx esbuild e-app.mjs --bundle --format=esm --minify --outfile=capacitor-app.js
npx esbuild e-browser.mjs --bundle --format=esm --minify --outfile=capacitor-browser.js
npx esbuild node_modules/@zxing/library/umd/index.min.js --bundle --minify --outfile=zxing-library.js
npx esbuild node_modules/chart.js/dist/chart.umd.js --minify --outfile=chart.js

# then copy the *.js output into vendor/js/, and the relevant woff2 files
# out of node_modules/@fontsource*/*/files/ into vendor/fonts/ (see the
# table above for exactly which files).
```
