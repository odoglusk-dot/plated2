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
