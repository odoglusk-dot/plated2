# Plated Deployment Guide

## Overview

Plated is a macro & supplement tracker built with:
- **Frontend**: Single-file vanilla JavaScript with Supabase JS SDK (no build step)
- **Backend**: Netlify serverless functions as API gateway
- **Database**: Supabase (PostgreSQL + Auth + Row Level Security)
- **AI**: Claude via Anthropic API for macro estimation from text & photos

## Prerequisites

1. **Supabase project** — for database, auth, and storage
2. **Netlify account** — for serverless functions
3. **Anthropic API key** — for food macro estimation

## Setup Steps

### 1. Supabase Database Setup

1. Create a new Supabase project at https://supabase.com
2. Copy your `Project URL` and `anon key` (find these in Project Settings → API)
3. Run the schema creation script in SQL Editor:
   - Open `reset-schema.sql` in your Supabase SQL Editor
   - Execute the entire script to create all 11 tables with RLS policies

**Tables created:**
- `profiles` — user metadata, age-gate answer, referral code, email
  reminder preference
- `goals` — daily macro targets (calories, protein_g, carbs_g, fat_g,
  goal_mode)
- `body_stats` — height, weight, age, gender for Mifflin-St Jeor calculator
- `food_logs` — daily food entries with macros
- `food_cache` — shared cache of estimated foods (text + photo)
- `favorites` — user's saved food items
- `weight_log` — weight tracking history
- `supplement_logs` — supplement usage
- `ai_usage` — daily API call counter (13 calls/day limit per user), plus
  real token usage and estimated cost per user per day
- `subscriptions` — Stripe subscription status backing the whole-app
  paywall, including `cancel_at_period_end` for the Customer Portal
  cancellation flow; select-own RLS only, written exclusively by
  `stripe-webhook.js` via the service-role key (see "Paywall Setup" and
  "Customer Portal Setup" below)
- `referrals` — referral attribution + reward status; select-own-as-referrer
  RLS only, written exclusively by `redeem-referral.js` and
  `stripe-webhook.js` (see "Referral Program" below)

If you're adding any of this to an **existing** live database rather than
starting fresh, don't run `reset-schema.sql` (it drops everything) — run
the incremental migration files instead: `supabase-schema-phase2-paywall.sql`
for the paywall, `supabase-schema-phase3-improvements.sql` for age gate /
referrals / goal_mode / email reminder opt-out, then
`supabase-schema-phase4-portal.sql` for `cancel_at_period_end`.

### 2. Netlify Functions Setup

1. Create a new Netlify site from Git (connect your repo)
2. Go to Site Settings → Build & Deploy → Environment
3. Add these environment variables:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
   ANTHROPIC_API_KEY=sk-ant-...
   STRIPE_SECRET_KEY=sk_live_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   STRIPE_PRICE_ID=price_...
   SENTRY_DSN=https://examplePublicKey@o0.ingest.us.sentry.io/0
   RESEND_API_KEY=re_...
   RESEND_FROM_EMAIL=Plated <reminders@your-domain.com>
   ```
   `SUPABASE_SERVICE_ROLE_KEY` is the Project Settings → API "service_role"
   key — it bypasses RLS, so it's only ever read server-side, by
   `delete-account.js`, `stripe-webhook.js`, `redeem-referral.js`, and
   `send-reminder-emails.js`. **Never** put it in `index.html` or any other
   client-facing code. See "Paywall Setup" below for the three `STRIPE_*`
   values, "Error Monitoring" for `SENTRY_DSN`, and "Email Reminders" for
   the `RESEND_*` values.
4. Set Build Command to: `echo "Netlify Functions ready"`
5. Set Functions Directory to: `netlify/functions`

The functions deploy automatically on git push.

### Support email

Edit the `SUPPORT_EMAIL` constant near the top of `index.html`'s script
(next to `SUPABASE_URL`) — it's what the Profile tab's "Contact Support"
button mails to. Defaults to a placeholder that won't reach anyone.

### Paywall Setup (Stripe)

Plated is a whole-app paywall: $4.99/month, 3-day free trial, card required
up front. No page renders for a signed-in user without an active
trial/subscription.

1. In the [Stripe Dashboard](https://dashboard.stripe.com), create a
   recurring Price of $4.99/month (Product catalog → Add product). Copy its
   ID — it starts with `price_`.
2. Add a webhook endpoint (Developers → Webhooks → Add endpoint) pointed at:
   ```
   https://your-site.netlify.app/.netlify/functions/stripe-webhook
   ```
   Subscribe it to exactly these events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

   Copy the "Signing secret" Stripe shows you — that's `STRIPE_WEBHOOK_SECRET`.
3. Copy your Stripe secret key (Developers → API keys) — that's
   `STRIPE_SECRET_KEY`. Use a `sk_test_...` key against Stripe's test mode
   while developing; switch to `sk_live_...` (and a live-mode webhook +
   price) at launch.
4. Set all three `STRIPE_*` env vars plus `SUPABASE_SERVICE_ROLE_KEY` in
   Netlify (see above), then run `supabase-schema-phase2-paywall.sql` in the
   Supabase SQL Editor if you're adding this to an existing project (fresh
   installs already get the `subscriptions` table from `reset-schema.sql`).

**Testing the webhook locally**, before wiring up a real Netlify deploy, use
the [Stripe CLI](https://stripe.com/docs/stripe-cli):
```bash
stripe listen --forward-to localhost:8888/.netlify/functions/stripe-webhook
stripe trigger customer.subscription.created
```
`stripe listen` prints a `whsec_...` value for local testing — use that as
`STRIPE_WEBHOOK_SECRET` in your local `.env`, not the Dashboard's production
signing secret.

### Granting free access manually (testing / comps)

For your own testing (or comping an account), set that user's subscription
to active directly in the Supabase dashboard — Table Editor → `subscriptions`
→ find or insert their row → set `status` to `active`. This is a direct
database edit only you can do; there is deliberately no button, endpoint, or
client-writable RLS policy anywhere in the app that lets a regular user set
their own status. If you'd rather use SQL Editor:
```sql
insert into subscriptions (user_id, status)
values ('<their-auth-user-id>', 'active')
on conflict (user_id) do update set status = 'active';
```
Find `<their-auth-user-id>` under Authentication → Users.

### Customer Portal Setup (cancellation, billing, card updates)

The Profile tab's "Manage Subscription" button (`create-portal-session.js`)
sends users to Stripe's hosted Customer Portal, where they can view billing
history, update their card, and cancel — none of that UI is built here.

**You need to configure the portal in the Stripe Dashboard before this
works, and this is the one piece of setup this codebase genuinely cannot
do for you:**

1. Go to **Settings → Billing → Customer portal**
   (`https://dashboard.stripe.com/settings/billing/portal`, and the
   equivalent under Test mode).
2. **Test mode auto-provisions a default configuration** — the portal
   works immediately there. **Live mode does not.** You must open that
   settings page and click **Save** at least once (even with defaults)
   before `billing_portal/sessions` will succeed in live mode; until then,
   the API call fails and users hitting "Manage Subscription" will see an
   error.
3. **The cancellation behavior itself is a setting on that same page, not
   something this code controls.** Under "Cancellations," Stripe defaults
   to **"Cancel at end of billing period"** — matching "keep access through
   what's already been paid for," exactly what was asked for here. There's
   also an "immediately" option; if that's ever toggled on instead, users
   lose access the moment they cancel (Stripe fires `.deleted` right away
   instead of setting `cancel_at_period_end`), and this app's paywall would
   correctly (and immediately) reflect that too — it's just not the
   behavior you asked for, so leave it on the default.
4. Everything else on that settings page (which products/prices customers
   can switch to, whether to require a cancellation reason, business
   branding) is optional polish — none of it is required for the portal
   to function with this single-price setup.

No new env vars — this reuses the same `STRIPE_SECRET_KEY` already
configured for checkout.

**Access during the "canceling but still paid for" window:** Stripe does
not flip a subscription's `status` to `canceled` the moment someone cancels
via the portal — it sets `cancel_at_period_end = true` and leaves
`status = 'active'` until the paid period actually ends, only then firing
`customer.subscription.deleted`. Since the paywall gate
(`index.html`'s `hasAccess()`) checks `status`, not `cancel_at_period_end`,
it already grants access through the paid period correctly with no special
casing. `subscriptions.cancel_at_period_end` is stored anyway so the
Profile tab can show "Canceling — access until `<date>`" instead of a
plain "Active", which would otherwise hide that a cancellation was even
received.

### Referral Program

Each user gets a unique code (`profiles.referral_code`, generated client-side
at signup) they can share as `https://your-site/?ref=THEIRCODE`. Signing up
with a code attributes the referral (`redeem-referral.js`, tracked in the
`referrals` table) — but **only the referrer is rewarded, and only once the
referred user's trial actually converts to a paid invoice**, not at signup.
`stripe-webhook.js` detects that conversion (a trialing→active transition on
`customer.subscription.updated`) and applies a shared, idempotently-created
Stripe coupon (`referral-1-month-free`, 100% off, one billing cycle) to the
referrer's existing subscription. If the referrer has no live subscription
of their own to discount, the referral row is left `pending` rather than
silently dropped, so it's still visible for a manual look.

No extra setup needed beyond the `STRIPE_SECRET_KEY` you already configured
above — the coupon is created automatically on first use. Query current
referral activity any time:
```sql
select referrer_user_id, referred_user_id, status, created_at, rewarded_at
from referrals
order by created_at desc;
```

### Error Monitoring (Sentry)

Two separate Sentry projects are used — one for the frontend, one for the
Netlify functions — so client and server errors don't land in the same
stream. A single project also works fine (just reuse its DSN in both spots
below) if you'd rather not split them.

1. Create a free account at [sentry.io](https://sentry.io) and one **browser
   JavaScript** project (frontend) plus one **Node** project (functions).
2. Frontend: copy the browser project's DSN (Project Settings → Client Keys)
   and paste it into the `SENTRY_DSN` constant near the top of `index.html`
   (it's a public identifier, safe to ship client-side — same as the
   Supabase anon key already there).
3. Functions: copy the Node project's DSN and set it as the `SENTRY_DSN`
   environment variable in Netlify (Site settings → Environment variables) —
   consumed by `_shared.js`'s `captureError()`. Never put this one in
   `index.html` or any other client-facing code.
4. That's it — no SDK/build step on the functions side (a hand-rolled
   envelope POST, to keep this project dependency-free); the frontend loads
   Sentry's official browser SDK from their CDN. Leaving either `SENTRY_DSN`
   blank just no-ops that side.
5. Every function handler is wrapped in `withErrorReporting()` (`_shared.js`),
   which is a backstop that reports ANY uncaught exception — not just the
   ones with an explicit `try/catch` around `captureError()` — so a bug in
   a code path nobody thought to wrap still gets reported instead of silently
   producing a raw 500.
6. To confirm the functions side is actually reporting, hit
   `sentry-test.js` directly — visit `<your-domain>/.netlify/functions/sentry-test`
   in a browser or `curl` it. No auth, no DB writes, no external API calls;
   it just throws a caught error and reports it, and tells you plainly if
   `SENTRY_DSN` isn't set instead of a silent no-op. Safe to leave in place
   or delete once you've confirmed the test event lands in your functions
   Sentry project.

Only failures judged operationally worth knowing about are explicitly
reported via `captureError()`/`reportError()` (AI calls, checkout, account
deletion, webhook processing) — routine input validation (wrong password,
"type DELETE to confirm") isn't, to keep the signal-to-noise ratio sane.
Anything else that throws unexpectedly is still caught by the safety nets
above: `withErrorReporting()` on the functions side, and Sentry's automatic
`window.onerror`/`unhandledrejection` capture on the frontend side.

### Email Reminders (Resend)

Optional daily nudge for users who haven't logged any food yet today,
opt-out via a Profile tab toggle (on by default). Backed by a Netlify
**scheduled function** (`send-reminder-emails.js`, cron in `netlify.toml`),
not something the frontend calls directly.

1. Create a free [Resend](https://resend.com) account and verify a sending
   domain (Resend won't send from an unverified domain).
2. Set env vars: `RESEND_API_KEY` (Resend dashboard → API Keys) and
   `RESEND_FROM_EMAIL` (e.g. `Plated <reminders@your-domain.com>`, must be
   on the verified domain).
3. Nothing else to configure — `netlify.toml` already schedules the
   function daily at 01:00 UTC. Leaving the Resend env vars unset makes the
   function a no-op (checked explicitly, not a silent failure).

Two known simplifications, both deliberate given "something simple, not
elaborate": it runs at one fixed UTC time rather than per-user local
evening (no per-user timezone is stored anywhere), and the free Resend tier
caps out at 100 emails/day / 3,000/month — fine at small scale, worth
knowing about before it isn't.

### 3. Update Frontend Configuration

Edit `/index.html` and replace the Supabase credentials:

```javascript
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGc...';
```

Deploy the frontend:
- For **Netlify**: Commit and push (auto-deploys)
- For **other hosting**: Run `npm install -g http-server && http-server`

## API Endpoints

### POST `/api/estimate-macros`

Estimate macros from a text description.

**Request:**
```json
{
  "description": "grilled chicken breast 6oz with brown rice"
}
```

**Response:**
```json
{
  "food_name": "Grilled chicken breast (6oz, cooked) with brown rice (1 cup)",
  "calories": 445,
  "protein_g": 58,
  "carbs_g": 45,
  "fat_g": 4,
  "confidence": "high",
  "remaining": 19,
  "cached": false
}
```

**Rate limit:** 13 calls per day per user (shared cache reduces usage)

### POST `/api/estimate-macros-photo`

Estimate macros from a food photo.

**Request:**
```json
{
  "imageBase64": "iVBORw0KG...",
  "mediaType": "image/jpeg",
  "note": "about 6oz chicken with rice"
}
```

**Response:** Same as `estimate-macros` + `cached` flag

**Cache:** Uses hash of image + note; same photo returns instantly

### POST `/api/create-checkout-session`

Starts a Stripe Checkout session for the $4.99/mo plan with a 3-day trial.

**Request:** `{}` (empty body — uses the caller's own Supabase session)

**Response:**
```json
{ "url": "https://checkout.stripe.com/c/pay/cs_test_..." }
```

Redirect the browser to `url`. Returns 400 if the caller already has an
active or trialing subscription.

### POST `/api/create-portal-session`

Opens Stripe's hosted Customer Portal for the caller's own billing account
— viewing invoices, updating a card, and canceling all happen there, none
of it built in this app. Requires a saved Customer Portal configuration in
the Stripe Dashboard (see "Customer Portal Setup" above) — will fail in
live mode until you've saved one at least once.

**Request:** `{}` (empty body — uses the caller's own Supabase session)

**Response:**
```json
{ "url": "https://billing.stripe.com/p/session/..." }
```

Redirect the browser to `url`. Returns 400 if the caller has no Stripe
customer on file yet (i.e. never started a subscription).

### POST `/api/stripe-webhook`

Called by Stripe, not the app — configure this URL as a webhook endpoint in
the Stripe Dashboard (see "Paywall Setup" above). Verifies the
`Stripe-Signature` header and upserts the `subscriptions` table from
`customer.subscription.created`/`.updated`/`.deleted` events using the
service-role key. Also fires the referral reward (see "Referral Program")
when one of those events represents a trial converting to paid.

### POST `/api/redeem-referral`

Attributes a referral code to the caller (the just-signed-up user).

**Request:** `{ "code": "ABC123" }`

**Response:** `{ "redeemed": true }`, or `{ "redeemed": false, "reason": "already redeemed" }`
if this account already has a referral on file. Returns 404 for an unknown
code, 400 for a self-referral attempt.

## Food Database

**373 foods** available for instant lookup (zero API calls):

- Poultry (12)
- Fish & Seafood (22)
- Beef & Pork (22)
- Eggs & Dairy (32)
- Alternative Proteins (10)
- Legumes & Beans (10)
- Grains & Starches (47)
- Vegetables (44)
- Potatoes & Tubers (9)
- Fruits (34)
- Nuts & Seeds (20)
- Nut Butters & Spreads (11)
- Healthy Fats & Oils (11)
- Beverages (13)
- Fast Food & Chains (23)
- Snacks & Bars (21)
- Soups & Broths (8)
- Condiments & Sauces (12)

**Lookup:** Exact match, case-insensitive, using Ctrl+F or search inputs

## Features

### Dashboard
- Ring-based progress toward daily goals (calories, protein, carbs, fat)
- Soft calorie-range shading: the calorie ring mutes to a neutral gray when
  today's total falls outside a healthy zone for the selected goal type
  (see `calorieRangeForGoal()`) — not red, not an alert, not blocking
- Streak calculation (consecutive days hitting protein target)
- Quick add buttons for common meal times

### Log Food
1. **Common Foods** — Instant lookup (373 options)
2. **AI Text Estimate** — "grilled chicken breast 6oz" → auto-filled macros
3. **AI Photo Estimate** — Take a photo → estimate macros
4. **Manual Entry** — Type food name + macros directly
5. **Favorites** — Save frequently-logged foods

### History
- List of last 90 days of food logs
- Streak calculations
- CSV export for external analysis

### Weight Tracking
- Log weight daily
- SVG line chart (trend visualization)
- Compare to goal weight

### Supplements
- Log supplement usage
- 10-item guide (common vitamins, minerals, herbs)
- Dosage + timing notes

### Ask Your Data
- "How much protein have I logged this week?"
- Query your own logs (runs against your data only)

### Profile
- **Goal Calculator** — Mifflin-St Jeor TDEE calculator
  - Input: Height (ft/in), Weight (lb), Age, Gender
  - Output: Maintenance TDEE + surplus/deficit targets
  - Also set explicit goal weight for deficit/surplus calculation
  - Macro split shifts by goal (`MACRO_SPLIT_BY_GOAL`): higher protein/lb
    when cutting (1.1 g/lb, protects muscle in a deficit), lower when
    gaining (0.85 g/lb, surplus calories already help preserve muscle),
    fat% and carbs shift accordingly
- **Subscription** — plain-language status (trial, active, canceling with
  the date access ends, payment failed, etc.) and a "Manage Subscription"
  button opening Stripe's Customer Portal for billing history, card
  updates, and cancellation
- **Refer a Friend** — your unique code + shareable link, referral count
- **Email Reminders** — opt-out toggle for the daily "haven't logged yet" nudge
- **Support** — mailto link to `SUPPORT_EMAIL`
- **Account Settings** — Change password, delete account

## Calorie & Macro Calculation

**Mifflin-St Jeor Formula:**

For men:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
```

For women:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
```

Then multiply by activity factor:
- **Maintenance** (1.0) — BMR × 1.55 (assuming light activity)
- **Surplus** (+500 kcal) — for muscle gain
- **Deficit** (-500 kcal) — for weight loss

Or if goal weight is set: calculate deficit/surplus based on weight difference.

## Daily AI Budget

**13 API calls per day per user** (shared cache):

- Estimate from text = 1 call
- Estimate from photo = 1 call
- If food already cached (previous estimate) = 0 calls ✓

Example:
- Day 1: User A logs "chicken" → 1 call, cached
- Day 1: User B logs "chicken" → 0 calls (User A's cache hit) ✓

## Security

**Row Level Security (RLS):**
- Users only see/modify their own data
- Verified via Supabase JWT token
- No manual SQL queries in frontend

**Authentication:**
- Supabase Auth (email + password)
- Session stored in browser localStorage
- Auto-logout on sign-out

**Credentials:**
- No API keys in frontend (only anon key, which is safe)
- Anthropic API key stored in Netlify env vars (never exposed)
- Supabase JWT tokens verified server-side

## Monitoring

### Check API Usage
In Supabase SQL Editor:
```sql
SELECT user_id, usage_date, count 
FROM ai_usage 
WHERE usage_date = current_date 
ORDER BY count DESC;
```

### Migrating an existing database for cost tracking

If your `ai_usage` table was created before real token/cost tracking was
added, `reset-schema.sql` will DROP and recreate every table — don't run it
against a live database with real user data. Instead, run this one-time
migration in the Supabase SQL Editor to add the new columns in place:

```sql
alter table ai_usage add column if not exists input_tokens bigint not null default 0;
alter table ai_usage add column if not exists output_tokens bigint not null default 0;
alter table ai_usage add column if not exists estimated_cost_usd numeric(10, 6) not null default 0;
```

### Real AI cost per user per month (admin-only)

`ai_usage` now logs the actual `input_tokens`/`output_tokens` Anthropic
returns on every call, priced against the model that really served the
request (see `getPricingTable()` in `netlify/functions/_shared.js`) and
accumulated into `estimated_cost_usd` per user per day. This is for your
own cost monitoring — there's no in-app UI for it, just run this in the
Supabase SQL Editor whenever you want to check real margin against the
$4.99/month subscription price:

```sql
SELECT
  user_id,
  date_trunc('month', usage_date) AS month,
  sum(count) AS ai_calls,
  sum(input_tokens) AS input_tokens,
  sum(output_tokens) AS output_tokens,
  round(sum(estimated_cost_usd), 4) AS estimated_cost_usd,
  round(4.99 - sum(estimated_cost_usd), 4) AS estimated_margin_usd
FROM ai_usage
GROUP BY user_id, date_trunc('month', usage_date)
ORDER BY month DESC, estimated_cost_usd DESC;
```

Costs are estimates based on Anthropic's published per-model $/MTok rates
at the time each call was made — they won't include Anthropic's own
prompt-caching discounts if those are ever turned on for these calls, and
Sonnet 5's introductory pricing (through 2026-08-31) is baked into
`getPricingTable()` with an automatic switch to standard pricing after that
date. Treat this as a close approximation, not an invoice-exact figure.

### Basic analytics: signups, trials, conversions (admin-only)

No third-party analytics tool — `subscriptions` already has what's needed
for the numbers that actually matter early on. Run these in the Supabase
SQL Editor whenever you want a check-in.

**Note the limitation up front:** `subscriptions` holds current state per
user, not a history of events, so these are point-in-time snapshots (e.g.
"how many people are trialing right now"), not a true historical funnel
(e.g. "how many people started a trial in June"). If you outgrow that,
the next step would be an append-only events log — not built here, since
it's more than "lightweight" calls for.

Total signups and current funnel stage:
```sql
SELECT
  (SELECT count(*) FROM profiles) AS total_signups,
  count(*) FILTER (WHERE status = 'trialing') AS currently_trialing,
  count(*) FILTER (WHERE status = 'active') AS currently_paying,
  count(*) FILTER (WHERE status = 'canceled') AS canceled,
  count(*) FILTER (WHERE status = 'past_due') AS past_due
FROM subscriptions;
```

A true conversion rate needs care: `status` only holds the *current* state,
not history, so a `canceled` row could mean either "canceled during the
trial" or "paid for months, then churned" — those look identical here.
Don't compute a single "conversion %" from this table as-is, it'll quietly
conflate the two. What you *can* get reliably is "how many people are
paying or have ever had a failed payment right now" against total signups:
```sql
SELECT
  (SELECT count(*) FROM profiles) AS total_signups,
  count(*) FILTER (WHERE status IN ('active', 'past_due')) AS currently_active_or_past_due
FROM subscriptions;
```
If you want a real historical conversion funnel later, that needs an
append-only events log (e.g. record every `stripe-webhook.js` status
transition instead of overwriting) — a reasonable next step, not built here
since it's more than "lightweight" calls for.

Signups per day (from `profiles.created_at`):
```sql
SELECT date_trunc('day', created_at) AS day, count(*) AS signups
FROM profiles
GROUP BY day
ORDER BY day DESC
LIMIT 30;
```

### Check Food Cache Hits
```sql
SELECT description_key, food_name, created_at 
FROM food_cache 
ORDER BY created_at DESC 
LIMIT 20;
```

### Check Error Logs
- Netlify: Logs → Functions
- Browser console: Open DevTools (F12)

## Troubleshooting

### "Sign in required" but logged in
- Check browser localStorage for `sb-auth-token`
- Try signing out and back in
- Clear browser cache (Ctrl+Shift+Delete)

### "Could not estimate macros"
- Check remaining API calls (shown on Log tab)
- Check Netlify function logs for errors
- Verify Anthropic API key is set in Netlify env vars

### Macros not syncing to database
- Open browser DevTools (F12) → Network tab
- Check response from POST `/api/` calls
- Verify Supabase auth RLS policies are correct

### Foods not appearing in search
- Exact match only — type full name from database
- Example: "Chicken breast (6oz, cooked)" not "chicken"
- Use browser Find (Ctrl+F) to see all options

## Future Enhancements

- [ ] Fuzzy search for food lookup
- [ ] Barcode scanning (UPC → nutrition database)
- [ ] Social features (share meals, compete on streaks)
- [ ] Custom meal templates (pre-built combos)
- [ ] Export to Apple Health / Google Fit
- [ ] Mobile native app (React Native)

