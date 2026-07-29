# Plated — Macro & Supplement Tracker — Handoff to Claude Code

## What this is

"Plated" is a macro/nutrition and supplement tracking web app, built for an athlete's own use (soccer training schedule, protein-focused goals) and intended to eventually go live on SaltFlow's Netlify hosting as a public tool. It uses Claude (via the Anthropic API) to estimate macros from a typed food description or a food photo, and to answer natural-language questions about a person's own logged history.

It was prototyped entirely inside a Claude.ai chat conversation, iterating on a single HTML file. That prototyping environment has some quirks that do **not** apply to a real deployment (explained below) — please read that section before assuming anything in the reference file reflects deployment-ready behavior.

**Your job:** take the full feature set that was built (in `macro-logger.html`) and merge it onto the real backend architecture (Supabase auth + database, Netlify serverless functions) that was already scaffolded in an earlier, less-feature-complete version. Then deploy it for real.

---

## Design language (keep this)

"Iron & Chalk" gym aesthetic — dark rubber-floor background, hazard-stripe accents, a "plate scoreboard" where protein/calories/carbs/fat each show as a colored weight-plate disc with a progress ring. Fonts: Bebas Neue (display), Inter (body), IBM Plex Mono (numbers/data). Keep this visual identity; it's intentional and already well-tuned.

---

## ⚠️ Critical: there are two versions of this file, and neither is "done" on its own

### `macro-logger.html` — the reference file, full feature set, WRONG architecture for production

This has every feature that's been built, but was tested inside Claude.ai's chat preview, which has two abnormal behaviors baked in that must be removed/replaced for a real deployment:

1. **`window.storage`** — a fake persistence layer that only exists in Claude.ai's sandbox. The file has a 3-tier fallback (`window.storage` → `localStorage` → in-memory) because none of Claude's storage worked reliably in that preview context. **None of this fallback logic should exist in the real app.** All of it needs to be replaced with real Supabase queries (see the "Data model" section below) so that data is actually private per-account and syncs across devices.

2. **Direct browser calls to `api.anthropic.com`** — the AI estimate functions (`estimateMacros`, `estimateMacrosFromPhoto`) and the Ask Your Data feature call `https://api.anthropic.com/v1/messages` directly from client-side JavaScript with **no API key attached**. This only ever worked (inconsistently) because of special sandbox behavior in Claude.ai's preview. **In a real browser, this will fail outright or expose no working credentials.** Every one of these calls must be routed through a Netlify serverless function instead, the same way `estimate-macros.js` (below) already does it correctly for the plain text estimate. This is the single most important architectural fix.

### `netlify-deploy/macros.html` (+ `netlify.toml`, `netlify/functions/estimate-macros.js`, `supabase-schema.sql`) — correct architecture, INCOMPLETE features

This is an earlier snapshot that has the *right* pattern:
- Real Supabase Auth (sign up / sign in / sign out), not a fake local login
- Real Postgres tables with Row-Level Security, so users' data is genuinely private (not just hidden by the UI)
- The AI text-estimate call correctly proxied through a Netlify function (`estimate-macros.js`) that holds the real Anthropic API key server-side and verifies the caller is a signed-in Supabase user before spending any API budget

But it was forked from `macro-logger.html` **before** these features were added, so it's missing all of them:
- Photo-based logging (snap a photo, estimate macros from the image)
- Personal favorites (save any logged food for one-tap re-logging)
- Weight tracking over time (with a line chart)
- Streaks (current/best consecutive days hitting protein goal)
- CSV export of logged history
- The Supplements & Vitamins tab (logging + an educational benefits/drawbacks guide for 10 common supplements)
- Budget-optimized meal suggestions (sort by cost-per-gram-of-protein, not just protein)
- Ask Your Data (natural-language Q&A grounded in the user's own logged history)
- The Profile tab restructure (goals editor + Mifflin-St Jeor-based personalized goal calculator with a safety floor against unsafe calorie targets)

### The actual task

**Merge them.** Take the UI/UX and feature logic from `macro-logger.html` (it's the source of truth for what the app should do and look like) and reimplement its data layer against Supabase instead of `window.storage`/localStorage, and reimplement all AI calls to go through Netlify functions instead of direct browser fetches. The Supabase-wired file is your architectural template for *how* to do that (see how `food_logs`, `goals`, `body_stats`, and `profiles` are already queried there) — extend that same pattern to cover favorites, weight_log, and supplement_logs (schema for these three is provided in `supabase-schema-additions.sql`, already written and ready to run).

---

## Files in this handoff

| File | What it is |
|---|---|
| `macro-logger.html` | **Reference file — full feature set.** Source of truth for UI, features, copy, and logic. Uses the wrong storage/API architecture (see above) — don't ship this as-is. |
| `netlify-deploy/macros.html` | **Architectural template — Supabase auth/DB wired correctly, AI calls proxied correctly, but missing the newer features.** Study the patterns here (how Supabase queries are structured, how the Netlify function is called with an auth token) and extend them. |
| `netlify-deploy/netlify.toml` | Tells Netlify where the serverless functions live. Needed at the project root. |
| `netlify-deploy/netlify/functions/estimate-macros.js` | Working serverless function for the text-based macro estimate. Verifies the Supabase session token, then calls Anthropic server-side. **Use this as the template for the other AI-powered features** (photo estimate, Ask Your Data) — they need their own functions (or this one extended) following the same auth-verification pattern. |
| `netlify-deploy/supabase-schema.sql` | Original schema: `profiles`, `goals`, `body_stats`, `food_logs`, `food_cache` — all with RLS policies scoping every row to `auth.uid()`, except `food_cache` which is intentionally shared across all signed-in users (it's just generic nutrition data, not personal). |
| `supabase-schema-additions.sql` | **New** — schema for the features that came after the Supabase fork: `favorites`, `weight_log`, `supplement_logs`. Same RLS pattern. Run this after the original schema in the same Supabase project. |
| `ask-data.js` | **Template, not finished** — a serverless function skeleton for Ask Your Data, following the same auth pattern as `estimate-macros.js`. Needs a decision (see below) on where the data-summarization step happens. |

---

## Open design decision: where should "Ask Your Data" build its summary?

In the reference file, `buildDataSummary()` runs client-side, pulling from local storage and formatting a text summary of the user's logged history before sending it to the AI. In the real architecture, there are two reasonable approaches:

1. **Client builds the summary** — frontend queries Supabase directly (it already has the session and RLS scopes it safely), formats the summary text, and POSTs it to the `ask-data` function alongside the question. `ask-data.js` as provided assumes this approach — it just forwards `dataSummary` to Anthropic.
2. **Function builds the summary** — the `ask-data` function itself queries Supabase (using a service-role key or the user's forwarded token) to pull `food_logs`/`goals` server-side, so the frontend only ever sends the raw question.

Either works. (1) is less work to wire up given the existing patterns; (2) keeps a bit more logic server-side. Pick whichever fits the rest of the codebase's conventions better.

---

## Environment variables needed on Netlify

- `ANTHROPIC_API_KEY` — from console.anthropic.com. Never exposed to the browser, only used inside serverless functions.
- `SUPABASE_URL` — from Supabase project settings → API.
- `SUPABASE_ANON_KEY` — same location. Safe to also expose client-side (that's by design — RLS is what actually enforces privacy, not secrecy of this key).

---

## Suggested order of work

1. Set up the Supabase project (or connect to whichever one already exists), run `supabase-schema.sql` then `supabase-schema-additions.sql`.
2. Get `netlify-deploy/macros.html` running locally/deployed as-is first, to confirm the auth + AI-proxy pattern genuinely works end-to-end (sign up, sign in, log a food, see it persist).
3. Port each missing feature from `macro-logger.html` one at a time, replacing its storage calls with Supabase queries and (for AI-powered ones) routing through a Netlify function:
   - Favorites (straightforward CRUD against the new `favorites` table)
   - Weight tracking (CRUD against `weight_log`, port the SVG line chart as-is — it's plain JS/SVG, no dependency on storage internals)
   - Streaks (pure computation over `food_logs` data already being fetched for history — logic can likely be ported almost unchanged)
   - CSV export (pure client-side computation over already-fetched data — should port with minimal changes)
   - Supplements tab (new `supplement_logs` table, mirrors the `food_logs` CRUD pattern closely)
   - Budget suggestions (pure client-side sort/display change — no storage dependency, should port unchanged)
   - Photo logging (port `estimateMacrosFromPhoto`'s prompt, but build a new Netlify function for it — image data will need to go in the POST body, base64-encoded, same as it's currently sent to Anthropic directly)
   - Ask Your Data (resolve the open design decision above, then wire `ask-data.js`)
   - Profile tab restructure + goal calculator (mostly UI + pure computation — low risk to port)
4. Remove all `window.storage` fallback code and the storage-backend-probe logic entirely — it has no purpose once real Supabase persistence exists.
5. QA pass: create two separate test accounts, confirm neither can see the other's logs/goals/favorites — this is the actual privacy guarantee the whole Supabase migration exists for.

---

## Known content notes

- The 10-item supplement guide includes deliberately balanced benefits/drawbacks copy, including a specific caution about stimulant-heavy pre-workout products given the target user is a teenage athlete. Preserve that framing — it's intentional, not filler.
- The personalized goal calculator has a hard safety floor (never recommends a calorie target below resting metabolic rate or 1500, whichever is higher) — preserve this when porting; don't let it get optimized away.
- Meal suggestion cost estimates are rough grocery-price approximations, not live pricing — fine to keep as static data unless there's appetite to wire up a real pricing source later.

---

## Phase 2: Paywall

Not part of the initial merge — build this after the core app is live and working. Architecture:

**New Supabase table** — `subscriptions`:
```sql
create table subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'free', -- 'free' | 'active' | 'canceled' | 'past_due'
  stripe_customer_id text,
  stripe_subscription_id text,
  current_period_end timestamptz,
  updated_at timestamptz default now()
);
alter table subscriptions enable row level security;
create policy "subscriptions: select own" on subscriptions for select using (auth.uid() = user_id);
-- No insert/update policy for the client — only the Stripe webhook function
-- (using the Supabase service-role key, which bypasses RLS) should ever write here.
```

**Two new Netlify functions:**
1. `create-checkout-session.js` — verifies the Supabase session (same pattern as `estimate-macros.js`), creates a Stripe Checkout Session for the signed-in user, returns the session URL for the frontend to redirect to.
2. `stripe-webhook.js` — receives Stripe webhook events (`checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`), verifies the Stripe signature, and updates the `subscriptions` row accordingly using the Supabase **service-role key** (not the anon key — this function needs to write regardless of RLS).

**Frontend gating:**
- On load, query the user's `subscriptions` row alongside profile/goals.
- Decide what's free vs. paid — a reasonable default split: unlimited manual entry, common-foods, and basic logging stay free forever; AI-powered features (text/photo estimate, Ask Your Data) get a daily free cap (the rate-limiting pattern already exists in the reference file) and unlimited access for `status = 'active'` users.
- Add an "Upgrade" button/screen that calls `create-checkout-session.js` and redirects to Stripe.

**Env vars needed:** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ID` (or equivalent for whatever pricing model is chosen), plus a `SUPABASE_SERVICE_ROLE_KEY` (different from the anon key — keep this one server-side only, in Netlify env vars, never in frontend code).

---

## Pre-launch checklist

Beyond the feature merge itself, these are worth doing before real strangers start signing up:

- [ ] **Terms of Service + Privacy Policy** — starter drafts included in this handoff (`TERMS_OF_SERVICE.md`, `PRIVACY_POLICY.md`). These are genuinely usable starting points but were drafted by Claude, not a lawyer — get real legal review before publishing, especially the age-requirement and children's-privacy sections, since this app's target users skew toward teenagers.
- [ ] **Account deletion UI** — the database schema already cascades deletes correctly (`on delete cascade` on every foreign key), but there's no frontend button for a user to actually trigger their own account deletion yet. Add one (Profile tab is the natural home) — calling `supabase.auth.admin.deleteUser()` requires the service-role key, so this needs a small Netlify function, not a direct client call.
- [ ] **Rate limiting scoped to the real user** — the daily AI-lookup cap in the reference file was written for a single-browser context. Once ported to Supabase, make sure the count is queried per `user_id`, not per browser/device, or one account could bypass it by switching browsers.
- [ ] **Billing alerts** — set a spend alert in the Anthropic console (console.anthropic.com) so unexpected usage spikes surface as a notification, not a surprise invoice.
- [ ] **Basic error monitoring** — Sentry's free tier (or similar) wired into both the frontend and the Netlify functions, so broken features show up in a dashboard instead of only being discovered via user complaints.
- [ ] **Real mobile device testing** — test on an actual phone browser (not an in-app preview or simulator) before calling this launch-ready. Several bugs during prototyping turned out to be specific to unusual rendering contexts — worth ruling that class of issue out on the real deployed site too.
- [ ] **Link the ToS/Privacy Policy** from the sign-up screen, with a simple "By creating an account, you agree to our Terms and Privacy Policy" line and links — standard practice, and expected by most users at this point.
