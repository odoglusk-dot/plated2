# Plated — Macro & Supplement Tracker

A macro/nutrition and supplement tracker with an "Iron & Chalk" gym aesthetic,
built on Supabase (auth + Postgres + RLS) and Netlify serverless functions.
No build step — `index.html` is a single static file that talks directly to
Supabase and to the functions in `netlify/functions/`.

## Architecture

- **Frontend**: `plated/index.html` — vanilla JS, loads `@supabase/supabase-js`
  from esm.sh. No bundler, no npm install needed for the frontend.
- **Auth + database**: Supabase. Every personal table is scoped to
  `auth.uid()` via Row Level Security — the app never has a broader "logged
  in" concept than "this row belongs to this account."
- **AI calls**: routed through Netlify functions (`netlify/functions/*.js`).
  The Anthropic API key never reaches the browser. Every function verifies
  the caller's Supabase session token before doing anything, and shares a
  per-user daily rate limit (`ai_usage` table) so one account can't rack up
  unlimited API spend by switching browsers/devices.

## 1. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL editor, run `supabase-schema.sql`, then
   `supabase-schema-additions.sql`, in that order.
3. Under Authentication → Providers, email/password is enabled by default —
   that's all this app uses. Decide whether you want email confirmation on
   sign-up (Authentication → Settings); the frontend handles either case.
4. Grab your Project URL and anon/public key from Project Settings → API.

## 2. Configure the frontend

Open `plated/index.html` and fill in the two placeholders near the top of
the `<script type="module">` block:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

The anon key is safe to ship in client-side code — RLS is what actually
enforces privacy, not secrecy of this key.

## 3. Deploy to Netlify

The repo root already has `netlify.toml` pointing Netlify at
`netlify/functions`. Connect the repo (or `netlify deploy`) and set these
environment variables in Site settings → Environment variables:

| Variable | Where to get it | Used by |
|---|---|---|
| `ANTHROPIC_API_KEY` | console.anthropic.com | all AI functions |
| `SUPABASE_URL` | Supabase → Project Settings → API | all functions |
| `SUPABASE_ANON_KEY` | Supabase → Project Settings → API | all functions |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API (**server-side only, never in frontend code**) | `delete-account.js` only |

The app itself is served at `/plated/` on whatever domain the site is
deployed to (Netlify serves `plated/index.html` automatically for requests
to `/plated/`). The existing `saltflow-v5.html` at the repo root is
untouched.

## 4. Smoke test

1. Sign up with a real email, confirm if your project requires it, sign in.
2. Log a food manually (Log Food → Manual Entry) and confirm it shows up on
   the Dashboard and persists after a refresh.
3. Try an AI text estimate (Log Food → Describe It) — this is the function
   that proves the Netlify → Anthropic proxy works end-to-end.
4. Create a second test account and confirm it cannot see the first
   account's logs, goals, or favorites — that's the actual guarantee the
   whole Supabase migration exists for. Do this before letting anyone else
   use the app.

## Rate limiting

`ai_usage` caps each account at 20 AI calls/day (text estimate + photo
estimate + Ask Your Data share one counter). Enforced server-side inside
`netlify/functions/_shared.js`, scoped to `user_id` via RLS using the
caller's own JWT — not per-browser, so it can't be bypassed by switching
devices. Adjust `DAILY_AI_LIMIT` in `_shared.js` if you want a different cap.

## Phase 2: Paywall (not built yet)

`supabase-schema-phase2-paywall.sql` has the `subscriptions` table schema.
Building the paywall means:

1. Run that schema file.
2. Add `netlify/functions/create-checkout-session.js` (verifies the Supabase
   session, creates a Stripe Checkout Session, returns the redirect URL).
3. Add `netlify/functions/stripe-webhook.js` (verifies the Stripe signature,
   writes to `subscriptions` using `SUPABASE_SERVICE_ROLE_KEY` since it must
   write regardless of RLS).
4. Gate AI-powered features behind `status = 'active'` (or the existing free
   daily cap for everyone else); keep manual entry, common foods, and basic
   logging free for everyone.

Additional env vars needed at that point: `STRIPE_SECRET_KEY`,
`STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ID`.

## Pre-launch checklist

- [x] Terms of Service + Privacy Policy drafts (`TERMS_OF_SERVICE.md`,
      `PRIVACY_POLICY.md`) — **get real legal review before publishing**,
      especially the age and children's-privacy sections, since this app's
      target users skew toward teenagers. These were drafted by an AI
      assistant, not a lawyer.
- [x] Account deletion — Profile tab → Delete My Account, backed by
      `netlify/functions/delete-account.js` using the service-role key.
- [x] Rate limiting scoped per `user_id`, not per browser.
- [ ] Set a spend alert in the Anthropic console.
- [ ] Wire up error monitoring (e.g. Sentry free tier) for both the
      frontend and the Netlify functions.
- [ ] Test on an actual phone browser before calling this launch-ready.
- [x] Sign-up screen links the Terms and Privacy Policy with a consent
      checkbox required before account creation.

## Known content notes (intentional, don't "clean up")

- The pre-workout/caffeine entry in the Supplements guide carries a
  deliberate caution about stimulant-heavy products, aimed at a teenage
  athlete audience. Preserve that framing.
- The goal calculator has a hard safety floor: it never recommends a
  calorie target below resting metabolic rate (BMR) or 1500 kcal, whichever
  is higher. Don't let this get optimized away.
- Meal-suggestion costs in the Meals tab are rough grocery-price
  approximations, not live pricing.
