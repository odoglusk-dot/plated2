# Privacy Policy — Plated

*Last updated: [DATE — fill in when published]*

**⚠️ Have a lawyer review this before publishing, particularly the children's-privacy section (Section 6) — if you know a meaningful portion of users will be under 13, U.S. law (COPPA) has specific requirements beyond what's outlined here.**

## 1. What We Collect

* **Account info:** email address, password (encrypted, never stored in plain text — handled by Supabase Auth).
* **Profile info:** display name, and if you use the goal calculator: sex, age, height, weight, activity level, goal weight.
* **Logged data:** food entries (name, serving, macros, timestamp), supplement/vitamin entries, weight history, custom goals, favorites.
* **Photos (if you use photo logging):** images are sent to Anthropic's API for analysis and are not permanently stored by us beyond what's needed to process the request. [Confirm actual retention behavior once the photo-logging Netlify function is built, and update this line to match reality exactly.]
* **Usage data:** basic technical logs (e.g., error logs) for debugging purposes.

## 2. How We Use It

* To provide the core functionality: tracking your food/supplement/weight history, estimating macros, and answering questions about your own logged data.
* To improve the free built-in food database (aggregate, non-personal nutrition facts only — never your individual logs).
* To communicate with you about your account (e.g., password resets).

We do not sell your data. We do not use your logged food or health data for advertising.

## 3. Third-Party Services We Use

* **Supabase** — hosts our database and handles authentication. See Supabase's privacy policy.
* **Anthropic (Claude API)** — processes food descriptions and photos to generate macro estimates, and powers the "Ask Your Data" feature. See Anthropic's privacy policy.
* **Netlify** — hosts the application.
* **Stripe** (if/when a paywall is added) — processes payments. We do not see or store your full payment card details; Stripe handles that directly.

## 4. Data Security

* Your data is protected using Row-Level Security at the database level, meaning even in the event of certain application bugs, other users cannot access your personal logs, goals, or account info through normal use of the App.
* Passwords are hashed and managed by Supabase Auth, not stored or handled directly by us.

## 5. Your Rights

* **Access:** you can view all your logged data within the App at any time.
* **Deletion:** you can delete your account and all associated data at any time [via Settings / by contacting X]. Deletion is permanent.
* **Correction:** you can edit or delete individual logged entries at any time within the App.

## 6. Children's Privacy

This App is intended for users 13 and older. We do not knowingly collect personal information from children under 13. If you believe a child under 13 has created an account, contact us at [email] and we will delete the account and associated data.

[If you expect a meaningful number of users under 13 — e.g., younger athletes — you likely need a COPPA-compliant consent flow, not just this notice. Confirm with a lawyer before launch if this applies to your actual user base.]

## 7. Data Retention

We retain your data for as long as your account is active. If you delete your account, your data is permanently removed within [X days — fill in based on actual technical implementation].

## 8. Changes to This Policy

We may update this policy from time to time. Material changes will be communicated via [email / in-app notice].

## 9. Contact

Questions about your data or this policy: [your contact email]
