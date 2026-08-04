# Plated — Macro & Supplement Tracker

A macro/nutrition and supplement tracker with an "Iron & Chalk" gym aesthetic,
built on Supabase (auth + Postgres + RLS) and Netlify serverless functions.
No build step — `index.html` is a single static file that talks directly to
Supabase and to the functions in `netlify/functions/`.

**373 foods in instant lookup** — zero API calls for common meals.
**Smart caching** — shared cache means once any user estimates a food, all subsequent
users get it free.

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** — Deploy and run in 10 minutes
- **[DEPLOYMENT.md](DEPLOYMENT.md)** — Complete technical setup guide
- **[COMMON_FOODS_DATABASE_CURRENT.md](COMMON_FOODS_DATABASE_CURRENT.md)** — Full food database (373 items across 18 categories)
- **[SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md)** — Database schema & RLS policies
- **[TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)** — Legal
- **[PRIVACY_POLICY.md](PRIVACY_POLICY.md)** — Privacy

## Architecture

- **Frontend**: `index.html` — vanilla JS, loads `@supabase/supabase-js`
  from esm.sh. No bundler, no npm install needed for the frontend.
- **Auth + database**: Supabase. Every personal table is scoped to
  `auth.uid()` via Row Level Security — the app never has a broader "logged
  in" concept than "this row belongs to this account."
- **AI calls**: routed through Netlify functions (`netlify/functions/*.js`).
  The Anthropic API key never reaches the browser. Every function verifies
  the caller's Supabase session token before doing anything, and shares a
  per-user daily rate limit (`ai_usage` table) so one account can't rack up
  unlimited API spend by switching browsers/devices.
- **Smart food caching**: Text descriptions and photo hashes are cached in
  `food_cache` with merge-duplicates strategy. Repeat lookups return instantly
  (zero API calls). Users share the cache — popular foods become free for everyone.

## Installable on phones (Add to Home Screen)

Plated ships a web app manifest (`manifest.json`) and icons (`icons/`), so
visiting the site on a phone and choosing "Add to Home Screen" (iOS Safari)
or the install prompt (Android Chrome) drops a Plated icon on the home
screen that opens full-screen, no browser chrome. This is just the
manifest + icons + meta tags — there's no service worker, so it isn't an
offline-capable PWA, just an installable shortcut. Requires HTTPS, which
Netlify provides by default.

## Quick Setup

**See [QUICKSTART.md](QUICKSTART.md) for a 10-minute deploy guide.**

### Setup Overview

1. **Supabase**: Create project, run `reset-schema.sql` in SQL editor
2. **Netlify**: Connect GitHub repo, add 3 environment variables
3. **Frontend**: Update `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `index.html`
4. **Done**: App is live

### Detailed Setup

See [DEPLOYMENT.md](DEPLOYMENT.md) for the full technical guide, including:
- Database schema explanation (9 tables, RLS policies)
- All required environment variables
- API endpoint documentation
- Monitoring and troubleshooting

### Two settings people forget: password reset URLs

"Forgot password?" calls `supabase.auth.resetPasswordForEmail()`, which asks
Supabase to email a link back to wherever the app is deployed. Supabase only
honors that request if the URL matches an entry on its allow-list —
**otherwise it silently falls back to the project's Site URL, which every
new Supabase project defaults to `http://localhost:3000`.** If you skip this
step, the emailed link will open `localhost` on the recipient's device
instead of your real site (this is not a bug in the app — the app is
already asking for the right URL, Supabase is just rejecting it).

Fix both in the Supabase dashboard under **Authentication → URL
Configuration**:
1. **Site URL** — change it from the `localhost` default to your actual
   deployed URL (e.g. `https://your-site.netlify.app`).
2. **Redirect URLs** — add that same domain with a wildcard (e.g.
   `https://your-site.netlify.app/*`).

This is a one-time setup step per deployment. Any reset email sent *before*
you save these settings has the broken localhost link already baked in —
send a fresh one afterward.

## Food Database

**373 foods** available for instant lookup (zero API calls):
- 12 poultry options (chicken, turkey, duck)
- 22 fish & seafood (salmon, tuna, shrimp, clams, etc.)
- 22 beef & pork (steaks, ground, pork chops, etc.)
- 32 eggs & dairy (eggs, milk, yogurt, cheese)
- 10 alternative proteins (tofu, tempeh, seitan, etc.)
- 10 legumes & beans (lentils, chickpeas, black beans, etc.)
- 47 grains & starches (rice, pasta, bread, quinoa, oats, etc.)
- 44 vegetables (broccoli, spinach, peppers, etc.)
- 9 potatoes & tubers (baked, sweet, fries, etc.)
- 34 fruits (bananas, apples, berries, etc.)
- 20 nuts & seeds
- 11 nut butters & spreads
- 11 healthy oils
- 13 beverages (coffee, juice, soda, etc.)
- 23 fast food chains (McDonald's, Subway, Chipotle, etc.)
- 21 snacks & bars
- 8 soups & broths
- 12 condiments & sauces

See [COMMON_FOODS_DATABASE_CURRENT.md](COMMON_FOODS_DATABASE_CURRENT.md) for the complete list with macros.

## AI Rate Limiting

`ai_usage` caps each account at **13 AI calls/day** (text estimate + photo
estimate + Ask Your Data share one counter). Enforced server-side inside
`netlify/functions/_shared.js`, scoped to `user_id` via RLS using the
caller's own JWT — not per-browser, so it can't be bypassed by switching
devices.

**Smart caching reduces API calls dramatically:**
- Food not in common database → estimate via AI (1 call)
- Same food estimated again → returned from cache (0 calls) ✓
- Multiple users estimate same food → all share the cache hit ✓

Adjust `DAILY_AI_LIMIT` in `_shared.js` if you want a different cap.

## Paywall

Plated is a whole-app paywall: **$4.99/month with a 3-day free trial**
(card required up front — Stripe handles the trial timing and auto-charges
on day 3). No part of the app — dashboard, logging, history, everything —
renders for a signed-in user without an active trial or subscription.

- **`subscriptions` table** (`user_id`, `status`, `stripe_customer_id`,
  `stripe_subscription_id`, `current_period_end`) — RLS gives every user
  select-own and nothing else. Only `netlify/functions/stripe-webhook.js`,
  using `SUPABASE_SERVICE_ROLE_KEY`, ever writes to it.
- **`netlify/functions/create-checkout-session.js`** — verifies the caller's
  Supabase session, creates a Stripe Checkout Session (subscription mode,
  3-day trial, `payment_method_collection: 'always'`), and returns the
  Checkout URL for the browser to redirect to.
- **`netlify/functions/stripe-webhook.js`** — verifies the
  `Stripe-Signature` header itself (HMAC-SHA256 via Node's `crypto`, no
  Stripe SDK, consistent with the rest of this codebase's zero-dependency
  functions) and upserts `subscriptions` from
  `customer.subscription.created` / `.updated` / `.deleted` events. The
  Supabase user id is threaded through as `subscription_data.metadata`
  at checkout time, so every subscription event carries it — no separate
  customer→user lookup table needed.
- **Frontend gate** (`index.html`, `enterApp()`) — every path into the app
  (sign-in, sign-up, password reset, page reload with an existing session)
  checks `subscriptions` before showing `#app`; anything other than
  `trialing`/`active` shows `#paywallScreen` instead, with a "Start 3-Day
  Free Trial" button. After Stripe redirects back
  (`?checkout=success`), the frontend polls briefly for the webhook to land
  before granting access, so a paying user isn't bounced back to the
  paywall while it's still in flight.

**Setup:**
1. In Stripe: create a $4.99/month recurring Price, note its ID
   (`price_...`).
2. Add a webhook endpoint in the Stripe Dashboard pointed at
   `https://your-site.netlify.app/.netlify/functions/stripe-webhook`,
   subscribed to `customer.subscription.created`, `.updated`, and
   `.deleted`. Copy the signing secret it gives you.
3. Run `supabase-schema-phase2-paywall.sql` in the Supabase SQL Editor
   (fresh installs get this table automatically from `reset-schema.sql`
   instead — no separate step needed).
4. Add env vars: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`,
   `STRIPE_PRICE_ID`.

See `DEPLOYMENT.md` for more detail, including how to test the webhook
locally with the Stripe CLI.

## Other features (see DEPLOYMENT.md for full detail on each)

- **Manage Subscription** — Profile tab button opens Stripe's Customer
  Portal (billing history, card updates, cancellation — none of it built
  here). Canceling keeps access through the already-paid period; see
  "Customer Portal Setup" in `DEPLOYMENT.md` for the one thing you need to
  configure in the Stripe Dashboard for this to work in live mode.
- **Age gate** — signup asks "Are you 18 or older?"; answering under-18
  reveals a parental-awareness explanation and a required consent checkbox
  before the form can submit. Not a hard technical block — a logged,
  good-faith checkpoint (`profiles.age_over_18` / `age_gate_shown_at` /
  `parental_consent_at`).
- **Referral program** — every user gets a shareable code
  (`?ref=CODE` pre-fills it at signup); once a referred signup's trial
  converts to paid, the *referrer* (not the referred user) gets a month
  free via an automatically-applied Stripe coupon. See "Referral Program"
  in `DEPLOYMENT.md`.
- **Error monitoring** — Sentry, wired into both `index.html` and the
  Netlify functions (hand-rolled envelope POST server-side, no SDK — see
  "Error Monitoring" in `DEPLOYMENT.md`). Needs your own `SENTRY_DSN`.
- **Email reminders** — optional daily nudge (Resend) for anyone who hasn't
  logged food yet that day; on by default, one click to opt out in Profile.
  Needs `RESEND_API_KEY` — see "Email Reminders" in `DEPLOYMENT.md`.
- **Support** — Profile tab has a mailto "Contact Support" link
  (`SUPPORT_EMAIL` constant near the top of `index.html`).
- **Basic analytics** — signups/trials/conversions, no third-party tool,
  just SQL against tables already here — see "Basic analytics" in
  `DEPLOYMENT.md`.
- **Testing access** — grant yourself (or anyone) free access by setting
  `subscriptions.status = 'active'` directly in the Supabase dashboard;
  there's no in-app way for a regular user to do this themselves (no
  client-writable RLS policy on that table at all).

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
- [x] Error monitoring (Sentry) wired into both the frontend and the
      Netlify functions — **you still need to create the Sentry project and
      set `SENTRY_DSN`** in `index.html` and Netlify's environment.
- [ ] Test on an actual phone browser before calling this launch-ready.
- [x] Sign-up screen links the Terms and Privacy Policy with a consent
      checkbox required before account creation.
- [x] Age gate at signup (soft checkpoint, logged — see "Other features" above).
- [ ] Stripe: live-mode price + webhook endpoint configured (not just test
      mode), and a real `customer.subscription.created` event confirmed to
      land in the `subscriptions` table before taking real payments.
- [ ] Stripe Customer Portal configuration saved at least once in live mode
      (Settings → Billing → Customer portal) — the "Manage Subscription"
      button fails without this; test mode doesn't need it, it auto-provisions.
      While there, confirm "Cancellations" is set to "Cancel at end of
      billing period," not "immediately."
- [ ] If using email reminders: Resend account created, sending domain
      verified, `RESEND_API_KEY`/`RESEND_FROM_EMAIL` set.
- [ ] `SUPPORT_EMAIL` in `index.html` changed from the placeholder to a
      real address you actually read.

## Known content notes (intentional, don't "clean up")

- The pre-workout/caffeine entry in the Supplements guide carries a
  deliberate caution about stimulant-heavy products, aimed at a teenage
  athlete audience. Preserve that framing.
- The goal calculator has a hard safety floor: it never recommends a
  calorie target below resting metabolic rate (BMR) or 1500 kcal, whichever
  is higher. Don't let this get optimized away.
- Meal-suggestion costs in the Meals tab are rough grocery-price
  approximations, not live pricing.
