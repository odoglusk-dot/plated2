# Privacy Policy — Plated

**Last updated:** 2026-07-29

*This is a starting draft, not legal advice. Have a lawyer review it —
especially the children's-privacy section — before you let strangers sign
up.*

## 1. What we collect

- **Account info**: email address and a display name you choose.
- **Logged data you enter**: food logs, favorites, weight entries,
  supplement logs, and the goals/profile fields you fill in (age, sex,
  height, activity level, weight) — these are used to power the goal
  calculator and are entirely optional beyond what's needed for core
  tracking.
- **AI-related content**: text descriptions and photos you submit for macro
  estimation, and questions you ask in Ask Your Data, are sent to
  Anthropic's API (via our server, never directly from your browser) to
  generate a response. We don't use this content to train models, and
  Anthropic's own data-handling terms govern how they process an API
  request (see anthropic.com's privacy policy for their side of this).
- **Basic usage counters**: a per-day count of AI calls per account, used
  only to enforce the daily free-usage limit.

## 2. What we don't do

- We don't sell your data.
- We don't share your logged data with other users. Every account's data
  is technically walled off from every other account at the database
  level (Row Level Security), not just hidden by the app's interface — one
  account cannot query another account's rows even by trying to.
- We don't use your food/supplement/weight logs for advertising.

## 3. How your data is stored

Data is stored in a Supabase-hosted Postgres database. Photos submitted for
macro estimation are sent to our serverless function and to Anthropic's API
for processing; we don't retain a separate copy of submitted photos beyond
what's needed to complete that single request.

## 4. Your controls

- You can edit or delete any logged entry (food, weight, supplement) at any
  time from within the app.
- You can export your food-logging history as a CSV from the History tab.
- You can permanently delete your account and all associated data from the
  Profile tab. This is irreversible and removes your profile, goals, body
  stats, food logs, favorites, weight log, and supplement logs.

## 5. Children's privacy

Plated is not directed at children under 13, and we don't knowingly collect
data from users under 13. Because Plated's target users skew toward
teenage athletes, if you are a parent or guardian and believe your child
under 13 has created an account, contact us (see below) and we will delete
it. **This section in particular needs real legal review** — requirements
around minors' data (e.g. COPPA in the US, or equivalent rules elsewhere)
are jurisdiction-specific and stricter than this draft reflects.

## 6. Third parties involved in processing your data

- **Supabase** — hosts our database and handles authentication.
- **Netlify** — hosts the app and serverless functions.
- **Anthropic** — processes AI-estimation and Ask Your Data requests sent
  through our serverless functions.

We don't add analytics or advertising trackers beyond what's needed to run
the app.

## 7. Changes to this policy

We may update this Privacy Policy as the app changes. Material changes
will be noted with an updated "Last updated" date above.

## 8. Contact

Questions about this policy or a data-deletion request can be directed to
the app operator's contact address (add one here before publishing).
