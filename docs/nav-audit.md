# Krafft Navigation Audit (Phase 0)

Scope: `plated2/index.html` (the whole app is one file; "screen" below means
one of its render functions / sub-tab states, not a separate route).
`admin.html` (Krafft HQ) is out of scope per the batch brief.

The mockup referenced in the batch brief (`krafft-layout-simplification-
options.html`) was not found in this repo or in the uploaded files for this
turn — Phase 0 doesn't need it (it's an audit of what exists today), but it
will be needed before Phase 1 starts. Flagging now so it's not a surprise
later.

---

## 1. Screen inventory

Six bottom-nav tabs today, each with its own sub-structure:

| Tab (bottom nav) | Default landing | Sub-screens inside it |
|---|---|---|
| **Home** (`dashboard`) | Protein hero + widgets | none — single scrolling screen |
| **Log** (`log`) | Describe It sub-tab | Describe It, Snap a Photo, Scan Barcode, Common Foods, Manual Entry, Favorites (6 sub-tabs) |
| **Lift** (`lifts`) | Log sub-tab | Log (today's lift + log form), Training (split/plan/block/muscle map/PRs); plus Plan Builder, Block Builder, Exercise Glossary, Lift Detail as full takeovers of this tab |
| **Group** (`group`) | Group home | Build/join a group, roster+leaderboard, settings, invite flow — all one screen, modal-ish states |
| **Athlete** (`athlete`, hidden unless Athlete Mode is on) | Athlete home | Setup, Conditioning log, Sports Psychology (+ Journal, Bank, Game Plan sub-screens), position customization |
| **Profile** (`profile`) | Settings sub-tab | Account, Settings (7 labeled sections) |

Plus a secondary nav row (**History · More · Lifts · Progress**) that
appears on every screen except Home/Profile/Group/Athlete, swapping content
by scope:
- **Nutrition scope** (on Log/History/etc.): shows **History** and **More**.
  More fans out to 3 destinations: Supplement Guide, Budget-Optimized
  Protein, Ask Your Data.
- **Training scope** (on Lift/Weight/Days/Photos/Recaps/Insights): shows
  **Lifts** and **Progress**. Progress fans out to 5 destinations: Weight
  Log, Training Days & Volume, Progress Photos, Monthly Recaps, Training
  Insights.

Insights itself has a Training / Nutrition & Social toggle (Muscle Balance,
Strength Ratios, Deload warning, nightly Flags, Progress Leaderboard, Rep
Range Distribution, Recovery, Weekly Frequency / Nutrition×Training
correlation, Friends Leaderboard, Goals Overview).

Other screens (full-screen takeovers, not tabs):
- Landing page, Sign In/Sign Up, Password reset, Email confirmation
- Onboarding (3-step, first run only)
- Paywall / upgrade screen
- User Guide, Learning Paths (list + reader)
- Apple Health Sync setup
- Cancel-subscription flow
- Exercise Glossary, Exercise Detail
- Plan Builder (3-step wizard), Block Builder (3-step wizard)

Popups/sheets (overlay, not a tab):
- Calorie breakdown (after logging food)
- Log Weight
- AI consent (new, App Store batch)
- Quick-log FAB sheet (Log Food / Log a Lift — 2 options)

---

## 2. Controls per screen

Full control inventory (229 labeled buttons/links captured, grouped by
screen). Abbreviated to what's load-bearing — purely cosmetic dismiss ✕
buttons are noted but not narrated individually.

### Home
Streak pill (topbar, always visible) · Protein hero (customize gear icon,
Pro only) · Today's Focus / Today's Plan card ("View in Lift tab") ·
Calories/Volume/Carbs/Streak/Fat/Water mini-stats · Today's Plan card ·
Streak & Water card (+8oz/+16oz/+24oz chips, custom amount + Log, delete
entry) · This Week card (Share weekly recap) · Logged Today card (delete
entry) · Protein by Meal card · spike-warning banner (dismiss) · streak
upgrade banner (See Pro Features / dismiss) · achievement unlock banner
(share / dismiss).

### Log
Sub-nav: Describe It · Snap a Photo · Scan Barcode · Common Foods · Manual
Entry · Favorites.
- **Describe It**: text field, Estimate Macros → result card (edit fields,
  Log It, Save as Favorite, Upgrade if free-preview exhausted).
- **Snap a Photo**: file input, note field, Estimate Macros → same result
  card.
- **Scan Barcode**: Start/Stop Scanner, manual code entry fallback → result
  card (Log It, Save to Quick Add, Scan Another).
- **Common Foods**: search list, ☆ favorite, Log per row.
- **Manual Entry**: full macro form, Log It, Save as Favorite.
- **Favorites**: list, Log / ✕ delete per row.
- Quick Add card (when a food was recently logged): Delete, Cancel, ✕.

### History
Per-day expandable log (today expanded, past days collapsed) · Export CSV.

### Weight *(buried — see §4)*
"+ Log Weight" button → popup (date, weight, note, Save) · trend chart ·
recent entries list.

### Supplements
Evidence-rated list, expand for source/caution, Log It per item, ✕ dismiss.

### Meals (Budget-Optimized Protein)
Ranked food list by cost-per-gram-protein, no interactive controls beyond
browsing.

### Ask Your Data (AI coach, Pro) *(buried — see §4)*
Text input, Ask button, threaded Q&A.

### More (hub)
3 cards (Supplement Guide, Budget-Optimized Protein, Ask Your Data), each
"Open".

### Lift — Log sub-tab (default)
PR banner (dismiss) · cue-of-the-day card · stale-session prompt (Still
going / End workout) · Today's Lift panel (Start/Continue/Choose workout
depending on state; Reopen Session if ended) · log-a-lift form (exercise
autocomplete + Glossary button, sets/reps/weight, warm-up ramp toggle,
suggested-exercises chips, cue card, citation footnotes) · Log · Session
Analysis card (Generate Analysis / Upgrade / Try again) · End Workout
button.

### Lift — Training sub-tab
Training split card (edit/custom builder) · Plan Builder summary card
(Build a Plan / End Plan) · Block Builder summary card (Build a block / End
block / View block) · Muscle map (tap to expand) · Weekly hard sets per
muscle · PRs horizontal scroll (tap opens Lift Detail) · Recent sessions
list.

### Lift Detail (per exercise)
Back · goal card (set/edit/remove a numeric target) · full lift history
(edit/cancel/delete per entry) · trend chart.

### Plan Builder / Block Builder (3-step wizards)
Each: Next/Back/Cancel per step, final Build button, preview step.

### Exercise Glossary
Search + filter chips, Close.

### Days (Training Days & Volume)
Heatmap (tap a day to expand), weekly volume by muscle group — no other
controls.

### Photos (Progress Photos)
Upload, per-photo Cancel/delete.

### Recaps (Monthly)
Single Month / Compare toggle, ← Older / Newer → pagination.

### Insights
Training / Nutrition & Social toggle → 8 + 3 cards respectively (see §1),
mostly read-only charts; Friends Leaderboard here specifically (distinct
from the friends list in Profile).

### Progress (hub)
5 cards (Weight Log, Training Days & Volume, Progress Photos, Monthly
Recaps, Training Insights), each "Open".

### Group
Build/Join a Group entry card (Pro-gated: Upgrade — Unlock Group Mode) ·
join-by-code flow (confirm card: Accept/Decline a pending invite, or
Join/Not Now for a code) · roster + leaderboard (This Week/Month/All-Time
toggle) · Copy invite Link · group goal (Set/Save/Cancel) · Leave Group.

### Athlete (hidden tab, opt-in)
Dashboard (Change Sport/Position, Set Up, Log Conditioning Work, Open
Sports Psychology — each Pro-gated individually) · Setup wizard (Next/Back/
Finish) · Conditioning log form · Sports Psychology (player, Journal, Bank,
Game Plan sub-screens, each with its own Back).

### Profile — Account sub-tab
Display name + Save · Achievements grid (share) · Friend request
Accept/Decline · Add friend by code · Referral code (Copy, Generate) ·
Sign Out.

### Profile — Settings sub-tab (default landing)
**Goals & Macros**: calorie/macro/water/goal-weight fields + Save, Goal
Calculator (age/sex/height/activity/target → Calculate, Apply to My
Goals).
**Units & Display**: lb/kg toggle.
**Notifications**: Email Reminders checkbox.
**Data & Privacy**: Export My Data · **AI Features** card (Turn On/Off,
new) · Delete Account (type-DELETE confirm, Cancel, new) · legal links
(now `privacy.html`/`terms.html`/`support.html`, just fixed).
**Krafft Athlete Mode**: on/off checkbox.
**Social**: Refer a Friend (code + copy).
**Krafft Athlete Mode position/sport** card if enabled.
**Help & Support**: Guide (Browse the Guide), Apple Health Sync (Set
Up/Manage), Support (mailto).
Always-visible top-of-page: Tier status card (Upgrade or Manage
Subscription + Cancel Subscription, both sub-tabs).

### Standalone flows
- **User Guide**: browsable topic list, Close.
- **Learning Paths**: list → reader (←Paths, ←Back, Next→, Finish path).
- **Apple Health Sync setup**: instructions, Copy Token, Revoke Access,
  ←Back.
- **Cancel flow**: reason picker → Stay at $4.99/Pause Billing 30
  Days/Continue (cancel) → Done.
- **Onboarding**: 3 steps (tier explainer → quick goals → tour), Skip
  available.
- **Paywall**: Start 3-Day Free Trial / Maybe Later.

---

## 3. Tap count from Home (landing screen) — requested features

| Feature | Taps from Home | Path |
|---|---|---|
| Log food (any method) | 1 | Log tab (Describe It is default) |
| Barcode scan | 2 | Log → Scan Barcode |
| Photo log | 2 | Log → Snap a Photo |
| Water | 1 | Home's Streak & Water card, quick-add chip, directly on screen |
| **Weight log** | **3 to screen, 4 to the actual Log-Weight popup** | Lift(1) → Progress(2) → Weight Log "Open"(3) → "+ Log Weight"(4) |
| Log a set / workout tracker | 1 | Lift tab (Log sub-tab is default, form is right there) |
| Blocks/Plans | 2 to summary card, 3 to open builder | Lift(1) → Training(2) → Build a Plan/Block(3) |
| Exercise library (Glossary) | 2 | Lift(1) → Glossary button on Log sub-tab(2) |
| Muscle map | 2 | Lift(1) → Training(2), rendered directly, no extra tap |
| PRs | 2 | Lift(1) → Training(2), rendered directly |
| **AI coach (Ask Your Data)** | **3** | Log(1) → More(2) → Ask Your Data "Open"(3) |
| Friends (add/manage) | 2 | Profile(1) → Account sub-tab(2) |
| Friends leaderboard (stats) | 4 | Lift(1) → Progress(2) → Insights(3) → Nutrition & Social(4) |
| Groups | 1 | Group tab |
| Streaks | 0 | Always visible (topbar pill + Home card) |
| Reminders | 1 | Profile (Settings default, same screen) |
| Goals | 1 | Profile (Settings default, same screen, first section) |
| Units | 1 | Profile (Settings, same screen, scrolled) |
| Billing/Pro status | 1 | Profile (tier card always at top) |
| Delete account | 1 | Profile (Settings, same screen, scrolled) |
| Apple Health | 1 to card, 2 to setup wizard | Profile(1) → Set Up Apple Health Sync(2) |
| Krafft HQ admin | n/a | Not linked in-app by design (direct URL only) |

---

## 4. Duplicates, dead ends, and 3+-taps-deep findings

**Buried (3+ taps):**
- **Weight Log** — 3 taps to the screen, 4 to actually log a weight. This
  was already flagged once this session ("hard to find") and partially
  fixed by moving it from the nutrition hub into the training hub, but the
  training hub itself (Progress) is still 2 taps deep before Weight Log's
  own "Open" tap. This is the single clearest case for the new "Water and
  Weight as two half-width cards on Today" change in the brief — it would
  take this straight to 0–1 taps.
- **Ask Your Data (AI coach)** — 3 taps (Log → More → Open). The brief's
  "Coach card" on Today directly addresses this.
- **Friends Leaderboard** — 4 taps (Lift → Progress → Insights →
  Nutrition & Social). The friend-adding flow itself is only 2 taps
  (Profile → Account) — it's specifically the *leaderboard stats view*
  that's deep. Worth deciding whether this stays a secondary view under
  Progress or needs its own shortcut.
- **Training Insights sub-cards** (Deload warning, nightly Flags, Rep
  Range Distribution, Recovery, Weekly Frequency, Nutrition×Training
  correlation, Goals Overview) — all 4 taps deep (Lift → Progress →
  Insights → Training-or-Social). None of these are daily-use, so 4 taps
  may be acceptable depending on how Phase 4's Progress screen handles
  them, but it's worth naming explicitly since the brief's "nothing daily
  more than 2 taps" rule doesn't technically cover them (they're not daily
  actions) — flagging rather than assuming.

**Duplicated reach (same action, multiple paths):**
- **Log food**: reachable via the Log tab directly, AND via the existing
  Quick-Log FAB (+ → Log Food, jumps to the same Log tab). Not truly
  duplicated UI, just two doors to one room — this is exactly the pattern
  the new universal **+** is meant to formalize/replace.
- **Log a lift**: same pattern — Lift tab directly, or FAB → Log a Lift
  (which also resets Block/Plan Builder and Glossary sub-state before
  landing on the form). The reset-on-entry behavior is worth preserving
  wherever "Set" lands in the new + sheet.
- **Upgrade entry points**: at least 9 separate "Upgrade"/"See Pro
  Features" buttons exist across the app (Home streak banner, Log result
  card preview banner, Session Analysis card, Profile tier card, Athlete
  dashboard ×3, Group entry card) — all converge on the same
  `showUpgradeScreen()` paywall, so this isn't really duplication (each is
  a contextual teaser for a feature the user just bumped into), but it's
  worth knowing the number before the redesign touches Account & Pro.
- **Legal links**: Privacy/Terms/Support are now linked from the sign-in
  footer, the static page footer, and Profile's Data & Privacy card —
  three places, all pointing at the same 3 pages (just fixed the static
  footer to match, in this same session). Not a problem, just noting it
  for the "Privacy & data" row in Phase 5.

**Nothing found unused/dead** — every render function found above is
reachable from some nav path; I did not find an orphaned screen.

---

## 5. Proposed mapping to Today · Progress · You

| Current location | New location | Notes |
|---|---|---|
| Home (dashboard) | **Today** | Direct carry-over — already closest in spirit to the brief's Phase 2 layout. Needs restructuring into the 6 named modules (protein_hero, meals, todays_lift, water, weight, coach) rather than today's ad hoc widget list. |
| Log tab (6 sub-tabs) | **+ sheet** (Phase 3) | Describe It/Manual Entry → "Log anything" field (or Food tile pre-opened to search, if `LOG_ANYTHING_AI_ENABLED` stays off). Snap a Photo → Camera icon. Scan Barcode → Barcode icon. Common Foods/Favorites → fold into the Food tile's own picker (not a top-level + sheet entry — brief only names 4 tiles: Food/Set/Water/Weight). **Flagging**: Favorites and Common Foods don't map 1:1 to a tile; proposing they become sub-views reached from inside the Food tile's sheet, same as today's sub-nav, just one level in instead of a top-level tab. |
| Weight tab | **+ sheet** (Weight tile) **and** a half-width card on **Today** | Matches the brief exactly — this is the fix for the buried-3-taps finding above. |
| Lift tab → Log sub-tab | **Today**'s "Today's Lift" card + a new full-screen workout tracker | The brief wants a focused full-screen set-logging flow distinct from browsing — this doesn't exist today in that exact shape (today's Log sub-tab mixes the log form with Today's Lift panel, suggested exercises, session analysis, citations, End Workout all on one scrolling screen). **Flagging**: building the dedicated tracker view is new construction, not just relocation. |
| Lift tab → Training sub-tab (split, muscle map, PRs, weekly sets, recent sessions) | **Progress** | Split/plan/block card → "Plans & blocks" row. Muscle map → its own card (tap to expand). PRs + weekly sets → the named half-width cards. Recent sessions → folds into History (see below). |
| History tab | **Today**'s "Previous days" (collapsed) + links into **Progress** for trends | Matches the brief's Phase 2/4 split exactly. |
| Supplements, Meals (Budget-Optimized Protein) | **You** or a Library-adjacent spot? | **Flagging — doesn't fit cleanly.** Neither is mentioned anywhere in the new 3-tab + sheet structure. They're not daily actions (educational reference content), so they don't belong on Today; they're not personal settings, so they don't belong in You. Closest fit is probably alongside the Exercise Library sheet (Progress's "Library" row) as reference material, or a "Guides" sub-row under You → Goals. Need your call on this before Phase 1 starts. |
| Ask Your Data | **Today**'s Coach card (sheet) | Matches the brief directly — this is also the fix for the buried-3-taps finding. |
| More tab (hub) | **removed** | Its 3 destinations redistribute: Supplements/Meals (see above, unresolved), Ask Your Data → Coach card. |
| Progress tab (hub) | **removed as a hub, folded into Progress itself** | Its 5 destinations become Progress's own cards/sections directly, per Phase 4. |
| Insights tab | **Progress** | Training sub-cards (Muscle Balance, Strength Ratios, Deload, Flags, Rep Range, Recovery, Frequency) fold into Progress. Nutrition×Training correlation and Goals Overview are less clearly "Progress" — possible fit under You → Goals instead. Friends Leaderboard → Friends & groups row in You. **Flagging** for your review: this tab has the most content of anything in the app (11 cards across 2 sub-tabs) and the brief's Phase 4 Progress screen is comparatively short (chart + 2 half-width cards + muscle map + plans + library row) — likely needs either a "More stats" expansion sheet within Progress, or an explicit decision on what gets cut from daily visibility vs. kept one tap deeper. |
| Group tab | **You → Friends & groups** | Brief explicitly places group streaks/invites here. Group's own internal structure (roster, leaderboard, goal-setting) likely stays intact as the one-level-deep screen this row opens. |
| Athlete tab | **Doesn't fit the 3-tab structure as a 4th/hidden tab anymore** | **Flagging.** Athlete Mode currently gets its own bottom-nav slot (hidden unless enabled) with 7 sub-screens (Setup, Conditioning, Psych, Journal, Bank, Game Plan, position/sport). A strict 3-tab max has no room for a 4th hidden tab. Closest fits: conditioning logging → a tile in the + sheet (5th tile, or folded into "Set"); Sports Psychology/Journal/Bank/Game Plan → a row under You, or a toggle-revealed section on Progress. Needs your decision — this is the single biggest structural casualty of "maximum three tabs" as written. |
| Profile tab (Account + Settings) | **You** | Maps closely to the brief's 5 rows already: Goals row ← Goals & Macros + Units. Reminders row ← Notifications. Friends & groups row ← Account's friend list + Group tab. Account & Pro row ← Account's identity fields + Sign Out + tier card + billing. Privacy & data row ← Data & Privacy + Krafft Athlete Mode toggle (not the whole Athlete tab, just the on/off switch) + Apple Health + legal links. Achievements and Referral code don't map to a named row — **flagging** for your call (candidates: fold into Account & Pro, or keep as their own row if you want a 6th). |
| User Guide, Learning Paths | **You** (likely under a Help row, not named in the brief's 5) | **Flagging** — not mentioned in Phase 5's 5 rows. Smallest-impact option is probably folding into Account & Pro or Privacy & data as a "Help" link, rather than adding a 6th row. |
| Cancel flow, Apple Health setup, Plan/Block Builder wizards, Exercise Glossary/Detail | Unchanged as flows | These are already one-level-deep sheets/takeovers opened from a parent screen — the brief doesn't ask to change their internals, only where their parent screen lives. |
| Quick-Log FAB (existing 2-option sheet) | **Replaced by the new universal +** | Direct superset — new + sheet has 4 tiles instead of 2, plus the optional AI text field. |

---

## Open questions for your review (beyond what's listed above)

1. **Supplements & Budget-Optimized Protein** have no obvious home in the
   new structure — need your call.
2. **Athlete Mode** (7 sub-screens) doesn't fit as a 4th tab under "maximum
   three tabs" — need your call on where its pieces go, or whether it's
   out of scope for this redesign like Krafft HQ.
3. **Insights' 11 cards** are a lot of content for Phase 4's comparatively
   short Progress screen — need a decision on what's promoted vs. one tap
   deeper.
4. **Achievements and Referral code** don't map to any of the 5 named You
   rows.
5. **User Guide / Learning Paths** aren't mentioned in the 5 You rows
   either.
6. The mockup file wasn't attached this turn — needed before Phase 1.

Stopping here per your instruction. Let me know how you'd like the open
questions resolved (or if you'd rather I propose a default for each and
you veto) before I move to Phase 1.
