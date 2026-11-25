# Krafft SMART PROGRAM — mockup content (text transcription)

No `docs/krafft-smart-program-mockup.html` file was uploaded for this batch. This is a verbatim transcription of the mockup's screen-by-screen content as pasted into the chat by the user, kept here as the working source of truth for exact copy/labels/numbers across every phase, since it won't stay in conversation history. See `docs/smart-program-audit.md` for what this does and doesn't substitute for.

## SMART PROGRAM
A program that adjusts to you
Progression, deloads, missed days, weekly volume and smart swaps. The code makes every decision from your logged sets; every decision has a Why, and the user can always override it.

## Screens
1: how targets are set. 2 to 4: blocks, deload, block review. 5 to 6: missed session and welcome back. 7: weekly volume. 8 to 9: smart swap.

### Phone 1 — How targets are set
How targets are set
Same rule for every lift. You can change any target.

- Hit the top on every set → **Add weight**. 70 × 10, 10, 10 → next: 72.5 × 8. Reps reset to the bottom of your range.
- Some sets came up short → **Same weight**. 70 × 10, 9, 8 → next: 70 × 10, 10, 9. Add one rep where you fell short.
- Missed the bottom twice in a row → **Drop 5–10%**. Then build back up.

Targets are suggestions. You can change any of them.

Caption: The progression rules in plain words. Weight steps come from equipment type (barbell, dumbbell, machine).

### Phone 2 — Block view
‹ Plans
Muscle size
YOUR VERSION
Upper / Lower · 4 days
Block 2 · Week 3 of 6
Deload in week 6
[week dots 1 2 3 4 5 6]
Week 6 is a lighter week so you come back fresh.

THIS BLOCK SO FAR
- Est. max, Bench: 150 → 158 lb
- Est. max, Squat: 215 → 224 lb
- Sessions done: 9 of 12

Block length: 6 weeks. Change it in Edit program. Why deload?
[Today / Progress / You tab bar]

Caption: Block view: where you are, when the deload lands, what moved. Length is editable (4 to 8 weeks).

### Phone 3 — Deload
‹ Back
DELOAD
Your last 2 sessions were down.
Est. max dropped on 4 of 5 main lifts. A lighter week may help. Your call.

This week as a deload
- Exercises: same
- Sets per exercise: −40%
- Weight: −10%
- Effort: 4+ reps left
- Session length: 58 → 38 min

These are our defaults. Experts agree on why to deload, not on exact numbers. Why?
[Deload this week] [Not now]

Caption: Reactive deload: a suggestion with a preview, never automatic. The scheduled one in week 6 uses the same screen.

### Phone 4 — Block review
‹ Done
BLOCK 2 REVIEW
6 weeks, 22 sessions

WENT UP
- Bench press: 150 → 163 lb
- Barbell row: 120 → 131 lb
- Leg press: 270 → 300 lb

STALLED
- Overhead press: 95 lb for 4 wks
  Try adding a set, or swap to Dumbbell Shoulder Press for the next block.

NEXT BLOCK
- Run it again with new targets
- Change goal or days
- Take a light week first

Caption: End-of-block review. Numbers come from logged sets; suggestions come from the same plateau rules as session analysis.

### Phone 5 — Missed session
WED NOV 25
Today
You missed Tuesday, Lower A
No problem. Pick what works.

Lower A, missed Tue
- **Do it today** — Shifts the rest of the week by a day. Sat becomes rest.
- **Skip it** — Targets stay. Weekly leg sets: 12 → 6 planned.
- **Fold into Thursday** — Adds about 14 min. Keeps main lifts, trims accessories.

Where you train it matters less than how many hard sets you get each week. Why?
[Apply]

Caption: Missed session sheet. Three options, each shows what it changes before you tap. No red marks, no guilt copy.

### Phone 6 — Welcome back
WED NOV 25
Welcome back
It has been 16 days since your last workout.
Ease in with one lighter session?

- Weights: 90% of last
- Sets: as planned
- Then: normal targets

Our default for 14 to 27 days away. 28+ days uses 80%. Not from a study, so you can change or skip it. Why?
[Start lighter session] [Use my normal weights]

Caption: Return after a gap. One session, then progression resumes. Never blocks the user from normal weights.

### Phone 7 — Weekly volume
Weekly volume
[This week] [Last]
Hard sets per muscle. The outlined band is the target for your goal.

- Chest: 14/16
- Back: 15/16
- Quads: 8/12
- Hams: 6/10
- Shoulders: 11/12
- Biceps: 9/10
- Calves: 3/6
- Core: 22/24

Quads and hamstrings are under target with 2 sessions left. Lower B covers them. Core is over: consider trimming. How is this counted?
[Today / Progress / You tab bar]

Caption: Done sets so far / planned for the week, against the target band. Tap a muscle to see which exercises count.

### Phone 8 — Smart swap, step 1
‹ Back
SWAP EXERCISE
Barbell Bench Press
Chest · barbell
Change

WHY SWAP?
[Equipment taken] [No equipment] [Hurts] [Prefer another]

CLOSEST MATCHES
- 🏋️ Dumbbell Bench Press — Same movement · dumbbell — [Pick]
- ⚙️ Machine Chest Press — Same movement · machine — [Pick]
- 🤸 Push-up (weighted) — Similar · bodyweight — [Pick]

Caption: Ranked by muscle, movement and the equipment you have. Past sessions never change.

### Phone 9 — Smart swap, step 2
‹ Back
SWAP EXERCISE
Dumbbell Bench Press

Your history here: 60 × 10
Suggested start: 55 × 8–10
Based on your own sets. If you have no history on it, we suggest starting light instead of guessing.

- **Just today** — Your plan stays as it is.
- **Replace in my version** — Makes your own copy if needed. Undo available.
[Swap]

Caption: Swap, step 2: starting weight from your own data, and a choice of just today or replace in your version.

## Rules table (program-rules.config, verbatim)

| Feature | Default rule (config, editable) | Evidence label |
|---|---|---|
| Progression | Double progression inside the goal's rep range. All sets at the top → add weight and reset to the bottom. Short sets → add a rep where short. Two sessions below the bottom → drop 5 to 10%. | Limited (standard coaching practice) |
| Weight steps | Barbell 5 lb (10 lb lower body), dumbbell 5 lb, machine or cable one pin or 5 lb, bodyweight add reps, then load. kg: 2.5 / 5. | Practical defaults |
| Block | 4 to 8 weeks, default 6; last week is a deload. | Limited (expert consensus) |
| Deload week | Same exercises, sets −40% (rounded), weight −10%, 4+ reps left. Reactive suggestion if estimated max is down on 4 of 5 main lifts across 2 sessions. | Limited. Experts agree on why, not on numbers |
| Missed session | Three options with a preview: do it today (shift the week), skip (targets stay), fold into the next day (≤ +15 min, trims accessories first). Skipped is not failed and never lowers a target. | Moderate (weekly volume matters more than which day) |
| Welcome back | 14–27 days away: 90% of last weights for one session; 28+: 80%. Then normal progression. Always skippable. | Limited (our default) |
| Weekly volume | Hard sets per muscle per week. Working sets only, no warm-ups. Primary muscle counts 1, secondary counts 0.5. Target band from the goal. | Strong for the target band; counting rule is a convention |
| Smart swap | Rank: same primary muscle (required), same movement pattern, available equipment, same tracking type, not already in the workout. Start weight only from your own history; no history = no number. | Practical rule, no study claimed |

## Evidence table (verbatim)

| Claim | Source and what it found | Label |
|---|---|---|
| Deloading | Bell, Strafford, Coleman, Androulakis Korakakis, Nolan (2023), Sports Med Open 9:87. International Delphi of 21 coaches. A deload is a period of reduced training stress; at least 70% agreed it can help adherence and reduce injury and overreaching. No agreed numbers; the authors call it under-researched. | Limited (expert consensus) |
| Where you train matters less than total sets | Grgic, Schoenfeld, Latella (2019), J Sci Med Sport 22(3):361-370. Review: when weekly volume is equated, training frequency had no pronounced effect on muscle gain. | Moderate (hypertrophy; strength not covered here) |
| Weekly sets per muscle | Schoenfeld, Ogborn, Krieger (2016), J Sports Sci. Meta-analysis: more weekly sets, more growth, graded. | Strong |
| Double progression, welcome-back weights, swap ranking | Standard coaching practice. No single study cited; the app says so. | Limited |

## Rules for this feature (verbatim)

Effort check is parked for later; targets use reps only for now, and the rules file leaves room to add it without changing the rest. Suggest, preview, then let the user decide. Never change a target, a plan or a weight silently. Never touch past sessions. Never use guilt copy for a miss. Any pain swap says: if pain is sharp or does not go away, stop and check with a professional. No medical claims.
