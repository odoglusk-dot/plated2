# Privacy Policy — Krafft

**Last updated:** 2026-09-23

*This is a starting draft, not legal advice. Have a lawyer review it —
especially the children's-privacy section — before you let strangers sign
up.*

## 1. What we collect

- **Account info**: email address and a display name you choose.
- **Logged data you enter**: food logs, favorites, weight entries,
  supplement logs, lifts, training splits, and the goals/profile fields you
  fill in (age, sex, height, activity level, weight) — these are used to
  power the goal calculator and are entirely optional beyond what's needed
  for core tracking.
- **AI-related content**: text descriptions and photos you submit for macro
  estimation, and questions you ask Ask AI, are sent to Anthropic's API (via
  our server, never directly from your browser) to generate a response. We
  don't use this content to train models, and Anthropic's own data-handling
  terms govern how they process an API request (see anthropic.com's privacy
  policy for their side of this). These features require an active
  subscription; if you're on the free tier, nothing you log is ever sent to
  Anthropic.
- **Basic usage counters**: a per-day count of AI calls per account, used
  only to enforce the daily free-usage limit.
- **Referral and friend codes**: your referral code, and — if you choose to
  add a friend or accept a friend request — the resulting connection
  between your account and theirs (see Section 2 for exactly what a friend
  can see as a result).

## 2. What we don't do

- We don't sell your data.
- We don't share your raw logged data (individual food logs, lifts, weight
  entries, etc.) with other users, ever — full stop. Every account's data
  is technically walled off from every other account at the database level
  (Row Level Security), not just hidden by the app's interface.
- **The one exception**: if you add a friend and they accept (or vice
  versa), that person can see three summary numbers about your training —
  your current streak, how many distinct exercises you've logged, and your
  all-time lift volume — on the shared leaderboard. That's it: no dates,
  no individual lifts, no food/weight/supplement data, no photos. This is
  opt-in on both sides (a request has to be sent and separately accepted),
  and removing a friend from your Profile immediately stops sharing those
  numbers with them.
- We don't use your food/supplement/weight/lift logs for advertising.

## 3. How your data is stored

Data is stored in a Supabase-hosted Postgres database. Photos submitted for
macro estimation are sent to our serverless function and to Anthropic's API
for processing; we don't retain a separate copy of submitted photos beyond
what's needed to complete that single request. The friend leaderboard's
three summary numbers (Section 2) are computed by a serverless function at
request time from your and your friends' raw data — that function is the
only code path that ever reads across accounts, and it returns only those
three numbers, never the underlying rows.

## 4. Your controls

- You can edit or delete any logged entry (food, weight, supplement, lift)
  at any time from within the app.
- You can export your food-logging history as a CSV from the History tab.
- You can remove a friend at any time from your Profile, which immediately
  stops sharing your leaderboard numbers with them (and theirs with you).
- You can permanently delete your account and all associated data from the
  Profile tab. This is irreversible and removes your profile, goals, body
  stats, food logs, favorites, weight log, supplement logs, lifts, training
  splits, and friend connections.

## 5. Children's privacy

Krafft is not directed at children under 13, and we don't knowingly collect
data from users under 13. Because Krafft's target users skew toward
teenage athletes, if you are a parent or guardian and believe your child
under 13 has created an account, contact us (see below) and we will delete
it. **This section in particular needs real legal review** — requirements
around minors' data (e.g. COPPA in the US, or equivalent rules elsewhere)
are jurisdiction-specific and stricter than this draft reflects.

## 6. Third parties involved in processing your data

- **Supabase** — hosts our database and handles authentication.
- **Netlify** — hosts the app and serverless functions.
- **Anthropic** — processes AI-estimation and Ask AI requests sent through
  our serverless functions (paid tier only).
- **Stripe** — processes subscription payments. We never see or store your
  card details ourselves; Stripe handles that directly and shares back only
  what we need to manage your subscription (status, renewal date).

We don't add analytics or advertising trackers beyond what's needed to run
the app.

## 7. Changes to this policy

We may update this Privacy Policy as the app changes. Material changes
will be noted with an updated "Last updated" date above.

## 8. Contact

Questions about this policy or a data-deletion request can be directed to
odoglusk+platedsupport@gmail.com.
