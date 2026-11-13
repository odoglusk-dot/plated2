# Cues review — Krafft training redesign Phase 1

Draft coaching cues for the 167 newly-added exercises (from `docs/krafft-exercise-catalog.csv`), grouped by primary muscle. Please skim before these ship — the migration SQL (`docs/migration-phase1-exercise-catalog.sql`) uses the exact text below.

Each exercise gets setup, execution, a common-mistake line, and a bracing/breathing cue (the real `exercises` table requires `cue_bracing` as non-null — this 4th field was missing from the first version of this migration and caused the insert to fail; it's included now), matching the voice of the existing exercises already in the catalog.

---

## Chest (21)

### Barbell Floor Press
- **Setup:** Lie on the floor with knees bent, barbell at arm's length above your chest, grip just outside shoulder width.
- **Execution:** Lower until your upper arms touch the floor, pause briefly, then press back up without bouncing off the ground.
- **Common mistake:** Using the floor to bounce the bar back up. Pause fully until the stretch reflex is gone, then press — that's the point of the floor press.
- **Bracing:** Take a breath and brace your abs before unracking — the floor changes the range, not the need to stay tight through the press.

### Decline Dumbbell Press
- **Setup:** Secure your legs on a decline bench, dumbbells at your lower-chest line, elbows under the bells.
- **Execution:** Press the dumbbells up and slightly together, then lower under control to the same lower-chest line.
- **Common mistake:** Letting the dumbbells drift toward your face instead of your lower chest. Keep the path over your lower sternum, not your collarbone.
- **Bracing:** Brace your core and keep your feet locked under the pads so the drive comes from your upper body, not from squirming on the bench.

### Dumbbell Floor Press
- **Setup:** Lie on the floor, knees bent, holding dumbbells at your chest with elbows resting lightly on the ground.
- **Execution:** Press the dumbbells straight up, then lower with control until your triceps touch the floor again.
- **Common mistake:** Flaring the elbows out to 90° at the bottom. The floor limits your range on purpose — use it to protect the shoulder, not to force extra stretch.
- **Bracing:** Take a breath into your belly before each rep and hold it through the press — the floor limits range, not how tight you should be.

### Dumbbell Hex Press
- **Setup:** Lie on a flat bench holding two dumbbells pressed together over your chest, palms facing each other.
- **Execution:** Lower the dumbbells to your chest while squeezing them together, then press back up, keeping that inward squeeze the whole rep.
- **Common mistake:** Letting the dumbbells separate mid-rep. The constant squeeze is what makes this a chest-focused press — don't let it turn into a normal press.
- **Bracing:** Keep your core lightly braced and your upper back pulled into the bench so the squeeze stays in your chest, not your shoulders.

### Incline Dumbbell Fly
- **Setup:** Set an incline bench to 30–45°, dumbbells held above your chest with a slight bend in the elbows.
- **Execution:** Lower the dumbbells out to the sides in a wide arc until you feel a stretch across the upper chest, then bring them back together over your chest.
- **Common mistake:** Bending and straightening the elbows during the rep. Lock the elbow angle in from the start — the movement should come from the shoulder joint, not the elbow.
- **Bracing:** Brace your core gently and keep your shoulder blades pulled back and down so the stretch loads your chest, not your shoulder joints.

### Dumbbell Pullover
- **Setup:** Lie across a flat bench with just your shoulders supported, holding one dumbbell with both hands straight above your chest.
- **Execution:** Lower the dumbbell in an arc behind your head until you feel a stretch in your lats and chest, then pull it back over your chest.
- **Common mistake:** Dropping too low, too fast, with heavy weight. This is a stretch-focused move — go only as far as a controlled shoulder range allows.
- **Bracing:** Brace your core hard before lowering the weight behind you — a loose torso here is how the lower back takes the stretch instead of the lats.

### Incline Push-Up
- **Setup:** Place your hands on a bench or box higher than your feet, body in a straight line from head to heels.
- **Execution:** Lower your chest to just above the surface, then press back up while keeping your core braced.
- **Common mistake:** Letting the hips sag or pike up. Keep the straight-line brace the whole rep — the incline is there to adjust difficulty, not to let your form slip.
- **Bracing:** Brace your abs and glutes like a plank the entire rep — the incline doesn't excuse a sagging midsection.

### Decline Push-Up
- **Setup:** Place your feet on a bench or box, hands on the floor slightly wider than shoulder width.
- **Execution:** Lower your chest toward the floor under control, then press back up to full arm extension.
- **Common mistake:** Letting the lower back arch as the feet go higher. Brace your abs and keep the glutes slightly squeezed to protect the lower back at this angle.
- **Bracing:** Squeeze your glutes and brace your abs to protect your lower back at this steeper angle.

### Weighted Push-Up
- **Setup:** Have a partner place a plate on your upper back, or wear a weighted vest, then set up in a standard push-up position.
- **Execution:** Lower your chest to the floor under control, then press back up without letting the added weight pull your hips down.
- **Common mistake:** Rushing the rep because of the extra load. Added weight makes form breakdown more costly, not less important — slow the tempo down.
- **Bracing:** Brace harder than you would unweighted — the added load punishes any looseness in your core immediately.

### Chest Press Machine
- **Setup:** Adjust the seat so the handles line up with mid-chest height, back flat against the pad.
- **Execution:** Press the handles forward until your arms are extended but not locked out, then return under control.
- **Common mistake:** Letting the shoulder blades round forward off the pad. Keep them pinned back throughout so the chest does the work, not the front delts.
- **Bracing:** Exhale through the press and keep your shoulder blades pinned to the pad the whole set.

### Incline Chest Press Machine
- **Setup:** Adjust the seat so the handles align with your upper chest, back flat against the pad.
- **Execution:** Press the handles up and forward until near full extension, then return under control to the stretch position.
- **Common mistake:** Shrugging the shoulders up toward the ears on the press. Keep them down and back the whole set so the upper chest takes the load.
- **Bracing:** Keep your shoulder blades down and back against the pad, and exhale through the hardest part of the press.

### Decline Chest Press Machine
- **Setup:** Adjust the seat so the handles align with your lower chest, back flat against the pad.
- **Execution:** Press the handles forward and slightly down, then return under control to the stretch position.
- **Common mistake:** Pressing in a straight line instead of following the machine's downward arc. Follow the handle path the machine is built for.
- **Bracing:** Brace your core against the seat and exhale through the press rather than holding your breath the whole set.

### Smith Machine Bench Press
- **Setup:** Lie on a flat bench under the bar, unrack it, and position it over your lower chest.
- **Execution:** Lower the bar to your chest under control, then press back up to just short of lockout.
- **Common mistake:** Letting the fixed bar path dictate an unnatural shoulder position. Set your bench position so the fixed vertical path still lines up with your natural press line.
- **Bracing:** Take a breath and brace before unracking, the same as you would with a free barbell — the fixed bar doesn't mean you can relax.

### Smith Machine Incline Press
- **Setup:** Set an incline bench under the Smith bar, unrack it over your upper chest.
- **Execution:** Lower the bar to your upper chest, then press back up along the fixed vertical path.
- **Common mistake:** Setting the incline too steep, turning it into a shoulder press. Keep the bench between 30–45° so the chest stays the primary mover.
- **Bracing:** Pull your shoulder blades back and down into the bench and brace your core before each rep.

### Smith Machine Decline Press
- **Setup:** Set a decline bench under the Smith bar, secure your legs, and unrack the bar over your lower chest.
- **Execution:** Lower the bar to your lower chest, then press back up along the fixed path.
- **Common mistake:** Un-securing your legs mid-set. Make sure the leg hold is locked before you unrack — sliding on a decline is a real fall risk.
- **Bracing:** Brace your core and keep your legs locked under the hold the whole set — on a decline, a loose brace shows up as sliding.

### Cable Fly (High-to-Low)
- **Setup:** Set both pulleys above shoulder height, step forward with a slight stagger, handles starting high and out to the sides.
- **Execution:** Pull the handles down and together in front of your lower chest, following a diagonal path, then return to the stretch under control.
- **Common mistake:** Turning it into a press by bending the elbows more as you go. Keep a soft, fixed elbow bend and let the shoulder do the moving.
- **Bracing:** Brace your core and keep a slight forward lean fixed — don't let the cables pull your torso around mid-rep.

### Cable Fly (Low-to-High)
- **Setup:** Set both pulleys at or below hip height, handles starting low and out to the sides.
- **Execution:** Pull the handles up and together toward upper-chest height along a diagonal path, then return under control.
- **Common mistake:** Using the low pulley position to turn this into a front raise. Keep the path diagonal across the chest, not straight up in front of the shoulders.
- **Bracing:** Keep your core braced and your stance fixed so the cables move your arms, not your whole body.

### Standing Cable Chest Press
- **Setup:** Set the pulley at chest height, face away from the machine in a staggered stance, handle at your chest.
- **Execution:** Press the handle forward to full extension, then return under control without letting the cable yank you backward.
- **Common mistake:** Letting the torso rotate or lean back to help the press. Keep the core braced and the movement isolated to the arm and chest.
- **Bracing:** Brace your core hard in the staggered stance — that's what stops the cable from rotating you as you press.

### Single-Arm Cable Chest Press
- **Setup:** Set the pulley at chest height, staggered stance, one hand on the handle, the other free for balance.
- **Execution:** Press the handle forward to full extension while resisting rotation, then return under control.
- **Common mistake:** Letting the torso twist toward the working arm. Brace the core hard — resisting that rotation is half the point of doing it one arm at a time.
- **Bracing:** Brace your obliques on both sides to resist rotation — that resistance is the actual point of doing this one arm at a time.

### Plate Press
- **Setup:** Hold a weight plate between both palms at chest height, pressing the plate edges together.
- **Execution:** Press the plate straight out to arm's length while maintaining the inward squeeze, then return to your chest.
- **Common mistake:** Letting the squeeze relax between reps. The constant plate-pinch is what makes this work the chest — don't let it go slack.
- **Bracing:** Keep a steady exhale through the press and maintain the plate squeeze the entire rep, not just at the top.

### Resistance Band Chest Press
- **Setup:** Anchor the band behind you at chest height, step forward to create tension, one handle in each hand.
- **Execution:** Press both handles forward to full extension, then return under control without letting the band snap you back.
- **Common mistake:** Letting the band do the deceleration for you on the way back. Control the return the same way you'd control a weight — don't just let go.
- **Bracing:** Brace your core so the band's pull doesn't yank your shoulders forward between reps.

## Triceps (13)

### Diamond Push-Up
- **Setup:** Get into a push-up position with your hands together under your chest, thumbs and index fingers forming a diamond shape.
- **Execution:** Lower your chest to your hands under control, then press back up to full extension.
- **Common mistake:** Letting the elbows flare wide to make it easier. Keep them tracking back close to your ribs — that's what shifts the load onto the triceps.
- **Bracing:** Brace your core like a plank — the narrow hand position already stresses the wrists and elbows more, so don't add a sagging torso on top.

### Assisted Dip Machine
- **Setup:** Kneel or stand on the assist platform, grip the dip handles, and set the assist weight so you can complete your target reps with control.
- **Execution:** Lower your body until your upper arms are roughly parallel to the floor, then press back up to full extension.
- **Common mistake:** Setting the assist weight too high and skipping real effort. Dial the assist down over time — the goal is to work toward unassisted dips, not stay propped up.
- **Bracing:** Brace your core and keep your torso fairly upright — leaning too far forward shifts load off the triceps and onto the shoulders.

### Triceps Pushdown (Rope)
- **Setup:** Attach a rope to the high pulley, grip both ends with palms facing each other, elbows pinned to your sides.
- **Execution:** Push the rope down until your arms are fully extended, spreading the rope ends apart slightly at the bottom, then return under control.
- **Common mistake:** Letting the elbows drift forward away from the torso. Keep them locked at your sides so the triceps — not the shoulders — drive the movement.
- **Bracing:** Keep your torso still and braced — lean on the triceps to move the weight, not your bodyweight rocking forward.

### Triceps Pushdown (V-Bar)
- **Setup:** Attach a V-bar to the high pulley, grip with palms facing each other, elbows pinned to your sides.
- **Execution:** Push the bar down to full extension, then return under control without letting the elbows drift forward.
- **Common mistake:** Using body weight to lean into the pushdown. Keep your torso upright and still — let the arms do all the work.
- **Bracing:** Brace your core and keep your chest up; don't let your shoulders roll forward to help the push.

### Reverse-Grip Triceps Pushdown
- **Setup:** Attach a straight bar to the high pulley, grip with palms facing up (underhand), elbows pinned to your sides.
- **Execution:** Push the bar down to full extension, then return under control, keeping the underhand grip throughout.
- **Common mistake:** Letting the wrists bend back under load. Keep them neutral and firm — the underhand grip changes elbow stress, so wrist control matters more here.
- **Bracing:** Keep your wrists firm and your torso still — this grip adds forearm demand, so don't also ask your core to stabilize sloppy form.

### Single-Arm Triceps Pushdown
- **Setup:** Attach a single handle to the high pulley, stand side-on, elbow pinned to your side.
- **Execution:** Push the handle down to full extension on one side, then return under control before switching arms.
- **Common mistake:** Letting the torso rotate to assist the push. Keep your shoulders square — this variation is meant to isolate each side without help from body English.
- **Bracing:** Brace your obliques to keep your shoulders square — that's what isolates the working arm instead of letting your torso help.

### Overhead Cable Triceps Extension
- **Setup:** Attach a rope to a low pulley, face away from the machine, and raise the rope overhead with elbows pointing forward.
- **Execution:** Extend your arms until your elbows are straight, then lower back down until your hands are behind your head.
- **Common mistake:** Letting the elbows flare outward as you extend. Keep them pointed forward and close together through the whole range.
- **Bracing:** Brace your core to keep your ribs down — flaring them as you extend overhead is how the lower back takes over.

### Dumbbell Skull Crusher
- **Setup:** Lie on a flat bench holding a dumbbell in each hand above your chest, palms facing each other.
- **Execution:** Bend only at the elbows to lower the dumbbells toward your temples, then extend back up.
- **Common mistake:** Letting the upper arms drift backward toward your face. Keep them vertical and still — only the forearms should move.
- **Bracing:** Keep your core lightly braced and your upper arms vertical and still — all the movement should be at the elbow.

### JM Press
- **Setup:** Lie on a flat bench with a barbell above your chest, grip just inside shoulder width.
- **Execution:** Lower the bar in a hybrid path toward your upper chest/neck by bending the elbows, then press back up to full extension.
- **Common mistake:** Treating it exactly like a close-grip bench press. The bar path angles lower toward the neck, not straight down to the chest — that's what makes it a hybrid skull-crusher/press.
- **Bracing:** Brace your core and keep your elbows tracking the same path every rep — this hybrid movement punishes inconsistent elbow position.

### Cable Triceps Kickback
- **Setup:** Set the pulley low, hinge forward at the hips, upper arm parallel to the floor and pinned at your side, elbow bent.
- **Execution:** Extend your arm straight back until it's fully locked out, then return under control.
- **Common mistake:** Swinging the upper arm to generate momentum. Pin it in place — only the forearm should travel.
- **Bracing:** Brace your core and keep your hips still — swinging the torso is the easiest way to fake extra range here.

### Bench Dip
- **Setup:** Sit on the edge of a bench, hands gripping the edge beside your hips, legs extended out in front of you.
- **Execution:** Lower your hips toward the floor by bending the elbows, then press back up to full extension.
- **Common mistake:** Letting the shoulders roll forward and down at the bottom. Keep the descent shallow enough that your shoulders stay in a safe, stable position.
- **Bracing:** Brace your core and keep the descent shallow — this protects your shoulders more than any amount of bracing alone can.

### Triceps Extension Machine
- **Setup:** Adjust the seat so your elbows line up with the machine's pivot point, grip the handles with upper arms against the pads.
- **Execution:** Extend your arms fully against the resistance, then return under control to the starting bend.
- **Common mistake:** Letting the upper arms lift off the pads to help the extension. Keep them pinned — that's what isolates the triceps instead of the shoulders.
- **Bracing:** Keep your upper arms pinned to the pads and breathe out through the extension.

### Dip Machine
- **Setup:** Grip the handles with your arms set at the machine's starting position, torso upright or slightly forward-leaning.
- **Execution:** Press down until your arms are extended, then return under control to the starting bend.
- **Common mistake:** Leaning too far forward, turning it into more of a chest press. Stay more upright if you want the triceps emphasis this variation is for.
- **Bracing:** Brace your core and keep your torso position consistent rep to rep — leaning changes which muscles do the work.

## Front Delts (12)

### Landmine Press
- **Setup:** Set a barbell in a landmine attachment, hold the loaded end at shoulder height with one hand, staggered stance.
- **Execution:** Press the bar up and slightly forward along its natural arc until your arm is extended, then lower under control.
- **Common mistake:** Pressing straight up like an overhead press. Let the bar travel its natural arc forward and up — fighting that path strains the shoulder.
- **Bracing:** Brace your core in the staggered stance — that's what keeps the bar's natural arc from pulling you off balance.

### Seated Barbell Overhead Press
- **Setup:** Sit on a bench with back support, barbell racked at shoulder height, grip just outside shoulder width.
- **Execution:** Press the bar straight overhead until your arms lock out, then lower back to shoulder height.
- **Common mistake:** Arching the lower back off the pad to get the bar overhead. If you can't press without arching, the weight is too heavy for this seated, back-supported variation.
- **Bracing:** Brace your abs hard against the seat back — without a standing base, your core is the only thing stopping an arch.

### Push Press
- **Setup:** Set up as for a standing overhead press, bar racked at the shoulders, knees slightly bent.
- **Execution:** Dip the knees slightly, then drive up through the legs while pressing the bar overhead in one continuous motion.
- **Common mistake:** Turning it into a slow leg-drive-then-press in two separate phases. The dip and the press should blend into one fast, continuous motion.
- **Bracing:** Take a breath and brace before the dip — the leg drive only transfers cleanly into the bar if your torso stays rigid.

### Dumbbell Shoulder Press (Standing)
- **Setup:** Stand with feet hip-width apart, dumbbells at shoulder height, core braced.
- **Execution:** Press the dumbbells overhead until your arms lock out, then lower back to shoulder height.
- **Common mistake:** Leaning back excessively to press the weight up. Keep the ribs down and core tight — if you're arching hard, the load is too heavy for standing strict form.
- **Bracing:** Brace your abs and squeeze your glutes before pressing — that's what keeps you from arching to finish the rep.

### Single-Arm Dumbbell Press
- **Setup:** Stand or sit with one dumbbell at shoulder height, the other arm relaxed or braced on your hip.
- **Execution:** Press the dumbbell overhead to full extension while resisting side-bending, then lower under control.
- **Common mistake:** Letting the torso lean away from the working side. Brace your obliques on the non-working side to keep the spine neutral.
- **Bracing:** Brace your obliques on the non-working side hard — that's the whole stabilization challenge of this variation.

### Shoulder Press Machine
- **Setup:** Adjust the seat so the handles start at shoulder height, back flat against the pad.
- **Execution:** Press the handles up until your arms are extended but not locked, then return under control.
- **Common mistake:** Letting the seat height put the handles too low, turning the first inches into a shrug. Set the seat so the handles start level with your shoulders.
- **Bracing:** Keep your back flat against the pad and exhale through the press rather than holding your breath.

### Smith Machine Shoulder Press
- **Setup:** Sit on a bench under the Smith bar, unrack it at shoulder height, grip just outside shoulder width.
- **Execution:** Press the bar up along the fixed vertical path to near lockout, then lower back to shoulder height.
- **Common mistake:** Positioning the bench too far forward or back for the fixed bar path. Adjust your seat position first so the vertical path matches your natural press line.
- **Bracing:** Brace your core before each rep — the fixed bar path removes balance demands but not the need for a tight torso.

### Kettlebell Overhead Press
- **Setup:** Clean a kettlebell to your shoulder (rack position), forearm vertical, elbow tucked.
- **Execution:** Press the kettlebell straight overhead until your arm locks out, then lower back to the rack position.
- **Common mistake:** Letting the kettlebell drift away from your forearm line, forcing a wrist bend. Keep the bell stacked directly over your forearm through the whole press.
- **Bracing:** Brace your core and keep your ribs stacked over your hips — don't let the bell's offset weight pull you into an arch.

### Pike Push-Up
- **Setup:** Start in a downward-dog position, hips high, hands and feet on the floor, forming an inverted V.
- **Execution:** Bend your elbows to lower the top of your head toward the floor between your hands, then press back up.
- **Common mistake:** Letting the hips drop during the press, turning it back into a regular push-up. Keep the hips high throughout to keep the shoulder emphasis.
- **Bracing:** Brace your core to keep your hips high throughout — that position is what shifts the load onto your shoulders.

### Handstand Push-Up
- **Setup:** Kick up into a handstand against a wall, hands shoulder-width apart, body stacked straight.
- **Execution:** Lower your head toward the floor under control by bending the elbows, then press back up to full lockout.
- **Common mistake:** Losing core and glute tightness partway down, causing the lower back to arch. Keep the whole body braced like a plank, just upside down.
- **Bracing:** Brace your whole body like a rigid plank, just upside down — any slack in the midsection shows up as an arching lower back.

### Cable Front Raise
- **Setup:** Set the pulley low behind you, grip the handle with one or both hands in front of your thighs.
- **Execution:** Raise your arm(s) forward to about shoulder height, keeping a slight elbow bend, then lower under control.
- **Common mistake:** Using the hips to swing the weight up. Keep the movement slow and strict — the cable's constant tension does the work, momentum shouldn't.
- **Bracing:** Keep your core braced and still — the cable makes it easy to sneak hip momentum into the raise if you're not paying attention.

### Plate Front Raise
- **Setup:** Hold a weight plate with both hands at the edges, arms extended down in front of your thighs.
- **Execution:** Raise the plate forward to about shoulder height, then lower under control.
- **Common mistake:** Shrugging the shoulders up as the plate rises. Keep them down and back — the front delts should do the lifting, not the traps.
- **Bracing:** Brace your core and keep your ribs down — leaning back to help the raise just shifts the work off your shoulders.

## Lats (16)

### Underhand Barbell Row
- **Setup:** Hinge at the hips with a flat back, barbell in hand with an underhand (supinated) grip just outside hip width.
- **Execution:** Pull the bar up to your lower ribs, driving the elbows back, then lower under control.
- **Common mistake:** Letting the underhand grip pull the elbows wide. Keep them tracking back close to the body — the supinated grip is for biceps/lat recruitment, not for changing the pull path.
- **Bracing:** Brace your core and keep your back flat throughout — the underhand grip changes which arm muscles help, not your hip-hinge position.

### Meadows Row
- **Setup:** Set a barbell in a landmine attachment, stand alongside it, hinge forward, and grip the loaded end with one hand.
- **Execution:** Pull the bar up toward your hip, driving the elbow back and up, then lower under control.
- **Common mistake:** Standing too square to the bar instead of slightly angled. A slight stance rotation toward the bar lets you get a fuller range of motion on each rep.
- **Bracing:** Brace your core hard in the angled stance — that's what keeps the pull from twisting your lower back.

### Machine Row (Seated)
- **Setup:** Sit with chest against the pad, grip the handles at a comfortable width, arms extended.
- **Execution:** Pull the handles back toward your torso, squeezing the shoulder blades together, then return under control.
- **Common mistake:** Pulling with the arms before the back engages. Lead the pull with your elbows and shoulder blades, not your hands.
- **Bracing:** Keep your chest against the pad and exhale through the pull rather than yanking with your arms.

### High Row Machine
- **Setup:** Sit with chest against the pad, grip the handles above shoulder height, arms extended forward and up.
- **Execution:** Pull the handles back and down toward your upper chest, then return under control.
- **Common mistake:** Shrugging the shoulders toward the ears during the pull. Keep them depressed so the lats and upper back do the work, not the traps.
- **Bracing:** Keep your core braced against the seat and pull with your elbows, not your hands.

### Iso-Lateral Low Row Machine
- **Setup:** Sit or kneel against the chest pad, grip each handle independently at a low angle, arms extended.
- **Execution:** Pull each handle back toward your hip, letting each side move independently, then return under control.
- **Common mistake:** Letting one side lag and do less work. Since each arm moves independently, consciously match the effort and range on both sides.
- **Bracing:** Brace your core to keep your torso square even though each arm is moving independently.

### Single-Arm Cable Row
- **Setup:** Set the pulley at chest height, sit or stand with one hand on the handle, torso braced.
- **Execution:** Pull the handle to your ribs while driving the elbow back, resisting torso rotation, then return under control.
- **Common mistake:** Letting the torso rotate toward the working side to help the pull. Brace the core and keep the shoulders square the whole rep.
- **Bracing:** Brace your core hard to resist rotation — that resistance is most of what makes this variation worthwhile.

### Close-Grip Lat Pulldown
- **Setup:** Grip a V-bar or close handles with palms facing each other, arms extended overhead.
- **Execution:** Pull the handles down to your upper chest, driving the elbows down and back, then return under control.
- **Common mistake:** Leaning back excessively to use body weight. A slight lean is fine, but don't turn it into a swinging row — keep the pull controlled.
- **Bracing:** Brace your core and keep any backward lean small and consistent — don't let it grow rep to rep.

### Neutral-Grip Lat Pulldown
- **Setup:** Grip neutral (palms-facing) handles shoulder-width apart, arms extended overhead.
- **Execution:** Pull the handles down to your upper chest, elbows tracking down and slightly forward, then return under control.
- **Common mistake:** Pulling the handles too far down toward your stomach. Stop around upper-chest height — overshooting just adds momentum, not muscle work.
- **Bracing:** Keep your core braced and ribs down so you're not using a back arch to help the pull.

### Underhand Lat Pulldown
- **Setup:** Grip the bar underhand (supinated), hands shoulder-width apart, arms extended overhead.
- **Execution:** Pull the bar down to your upper chest, driving the elbows down and back, then return under control.
- **Common mistake:** Letting the underhand grip turn this into a biceps curl. Initiate the pull with the elbows and back, with the biceps assisting, not leading.
- **Bracing:** Brace your core and keep your chest lifted — don't let the underhand grip turn this into a shrug-and-yank.

### Single-Arm Lat Pulldown
- **Setup:** Attach a single handle to the high pulley, grip with one hand, the other braced on your thigh or the frame.
- **Execution:** Pull the handle down toward your hip on that side, then return under control before switching arms.
- **Common mistake:** Letting the torso twist to generate pulling force. Keep your shoulders square and isolate the pull to the working arm and lat.
- **Bracing:** Brace your obliques to keep your shoulders square — resisting the twist is the point of doing one arm at a time.

### Plate-Loaded Pulldown Machine
- **Setup:** Adjust the knee pad and seat so you're locked in, grip the handles with arms extended overhead.
- **Execution:** Pull the handles down to your upper chest, then return under control to full stretch.
- **Common mistake:** Using too much weight and only completing a partial range. Dial the plates back until you can get the full stretch-to-contraction range.
- **Bracing:** Keep your core braced and chest up through the full stretch-to-contraction range.

### Neutral-Grip Pull-Up
- **Setup:** Grip parallel, palms-facing handles (or a neutral-grip bar) with arms fully extended, hanging freely.
- **Execution:** Pull your chin above the handles by driving the elbows down, then lower under control to full extension.
- **Common mistake:** Using a kipping swing to get over the bar. Keep the movement strict and controlled unless you're deliberately training the kipping version.
- **Bracing:** Brace your core and glutes to keep your legs from swinging — a stable midline makes every rep count.

### Wide-Grip Pull-Up
- **Setup:** Grip a bar wider than shoulder width, arms fully extended, hanging freely.
- **Execution:** Pull your chest toward the bar, driving the elbows out and down, then lower under control.
- **Common mistake:** Only pulling halfway up because the wide grip limits range. If you can't get your chin over the bar, narrow the grip until you can complete full reps.
- **Bracing:** Brace your core hard — the wider grip already shortens your range, so don't lose more of it to a loose torso.

### Weighted Pull-Up
- **Setup:** Attach a weight belt or hold a dumbbell between your feet, then grip the bar with arms fully extended.
- **Execution:** Pull your chin over the bar under control, then lower back to full extension.
- **Common mistake:** Adding weight before bodyweight pull-ups are clean and controlled. Build a strict bodyweight base first — added load just amplifies any form breakdown.
- **Bracing:** Brace harder than you would unweighted — added load makes any swing or sag far more costly.

### Assisted Pull-Up Machine
- **Setup:** Kneel or stand on the assist platform, grip the bar, and set the assist weight so you can complete your target reps with control.
- **Execution:** Pull your chin above the bar, then lower under control to full extension.
- **Common mistake:** Relying on the assist platform's bounce at the bottom. Control the descent fully — the eccentric is where a lot of the pulling strength is built.
- **Bracing:** Brace your core even with the assistance — the point is to build the same tight-body habits you'll need unassisted.

### Band-Assisted Pull-Up
- **Setup:** Loop a resistance band around the bar and under one foot or knee, then grip the bar with arms extended.
- **Execution:** Pull your chin above the bar, then lower under control to full extension.
- **Common mistake:** Using a band so thick it removes all the challenge. Size the band down over time so you're still doing real work, not just riding the band.
- **Bracing:** Keep your core braced through the whole rep — the band should help your pulling strength, not replace your control.

## Upper Back (7)

### Seal Row
- **Setup:** Lie face-down on a raised bench with a barbell or trap bar beneath you, arms extended down.
- **Execution:** Pull the weight up to your chest, squeezing the shoulder blades together, then lower under control.
- **Common mistake:** Using momentum since the bench removes the ability to cheat with the hips. Without hip drive available, let it slow down — don't yank the weight.
- **Bracing:** Brace your core against the bench and pull with your back, not momentum — there's no hip drive to fall back on here.

### Chest-Supported Dumbbell Row
- **Setup:** Lie chest-down on an incline bench, dumbbells hanging straight down, arms extended.
- **Execution:** Pull the dumbbells up toward your hips, driving the elbows back, then lower under control.
- **Common mistake:** Lifting the chest off the pad to add momentum. The support is there to remove lower-back involvement — keep your chest planted the whole set.
- **Bracing:** Keep your chest pressed into the pad and brace your core — that support only works if you don't fight it.

### Landmine Row
- **Setup:** Set a barbell in a landmine attachment, straddle it, hinge forward, and grip the loaded end with both hands or an attachment.
- **Execution:** Pull the bar up toward your torso, driving the elbows back, then lower under control.
- **Common mistake:** Standing up out of the hinge to help the pull. Keep the hip hinge locked in and let the back do the work.
- **Bracing:** Brace your core and keep the hip hinge locked in — standing up mid-set turns this back into a deadlift variation.

### Chest-Supported T-Bar Row
- **Setup:** Lie chest-down on the T-bar row's support pad, grip the handles, arms extended toward the weight.
- **Execution:** Pull the handles up toward your torso, squeezing the shoulder blades, then lower under control.
- **Common mistake:** Not setting the pad height correctly, forcing an awkward reach. Adjust it so your arms start fully extended without rounding your back to reach the handles.
- **Bracing:** Keep your chest on the pad and brace your core so the pull comes from your back, not your lower body.

### Machine Row (Chest-Supported)
- **Setup:** Sit or kneel with your chest against the pad, grip the handles, arms extended.
- **Execution:** Pull the handles back toward your torso, squeezing the shoulder blades together, then return under control.
- **Common mistake:** Letting the chest come off the pad to generate extra pull. Keep it pinned — that's what isolates the back instead of letting the hips help.
- **Bracing:** Keep your chest pinned to the pad and exhale through each pull.

### Wide-Grip Seated Cable Row
- **Setup:** Sit at a low pulley row station, grip a wide bar with an overhand grip, knees slightly bent.
- **Execution:** Pull the bar to your upper abdomen, elbows flaring out and back, then return under control.
- **Common mistake:** Rounding the lower back to extend the pull range. Keep a neutral spine and let the shoulder blades, not the lower back, create the range.
- **Bracing:** Brace your core to keep your spine neutral — let your shoulder blades create the range, not your lower back.

### Inverted Row
- **Setup:** Set a bar at hip height, lie beneath it, grip it with hands shoulder-width, body straight from head to heels.
- **Execution:** Pull your chest up to the bar by driving the elbows back, then lower under control.
- **Common mistake:** Letting the hips sag toward the floor. Keep the whole body braced in a straight line, the same way you would in a plank.
- **Bracing:** Brace your whole body like a plank from head to heels — a sagging midsection is the most common breakdown here.

## Hamstrings (5)

### Dumbbell Romanian Deadlift
- **Setup:** Stand holding dumbbells in front of your thighs, feet hip-width apart, slight knee bend.
- **Execution:** Hinge at the hips, pushing them back while lowering the dumbbells along your legs, then drive the hips forward to stand back up.
- **Common mistake:** Bending the knees more to lower further. This is a hip-hinge movement — keep the knee bend fixed and let the hips do the traveling.
- **Bracing:** Brace your core before you hinge — that brace is what keeps the load in your hamstrings instead of your lower back.

### Single-Leg Romanian Deadlift
- **Setup:** Stand on one leg holding a dumbbell in the opposite hand, slight bend in the standing knee.
- **Execution:** Hinge forward at the hip while extending the free leg straight back for balance, then return to standing.
- **Common mistake:** Rotating the hips open as you hinge. Keep both hip points square to the floor — rotation is usually a sign the hamstring flexibility or balance needs more work at a shallower range first.
- **Bracing:** Brace your core hard — balance and bracing work together here, and losing either one shows up immediately.

### Standing Leg Curl
- **Setup:** Stand at a standing leg curl machine, back brace against the pad, ankle against the lower roller pad.
- **Execution:** Curl your heel up toward your glute by bending the knee, then lower under control.
- **Common mistake:** Letting the hips rotate or the standing leg lose its brace. Keep the pelvis square and stable so the hamstring does the isolated work.
- **Bracing:** Brace your core and keep your standing hip stable — the goal is an isolated curl, not a rocking torso.

### Glute-Ham Raise
- **Setup:** Set your feet against the footplate of a GHD, knees on the pad, torso upright and braced.
- **Execution:** Lower your torso forward under control by letting the knees extend slightly, then pull yourself back up using the hamstrings.
- **Common mistake:** Using the hip flexors to yank back up instead of the hamstrings. Think about pulling your heels down into the pad as you rise.
- **Bracing:** Brace your core and glutes throughout — that's what keeps the movement in your hamstrings instead of your lower back.

### Sled Pull
- **Setup:** Attach a strap or harness to a loaded sled, face the sled, and get into an athletic stance with the rope or strap taut.
- **Execution:** Pull the sled toward you by driving your hips back and extending, hand-over-hand or leaning back, in a controlled, repeated motion.
- **Common mistake:** Yanking with the arms instead of driving with the legs and hips. Let the lower body generate the pulling force; the arms just transmit it.
- **Bracing:** Brace your core and keep your back flat as you lean into the pull — this is a full-body drive, not an arms-only tug.

## Traps (5)

### Rack Pull
- **Setup:** Set safety pins or blocks so the bar sits just below or at knee height, grip the bar as you would a deadlift.
- **Execution:** Drive through the floor to stand the bar up, locking out the hips, then lower back to the pins under control.
- **Common mistake:** Treating it like a full deadlift and rounding the back to reach lower. The partial range is the point — keep the back flat and only move through the set range.
- **Bracing:** Take a breath and brace your torso before the pull, the same as a full deadlift — the shorter range doesn't mean less tension.

### Dumbbell Shrug
- **Setup:** Stand holding dumbbells at your sides, arms straight, shoulders relaxed.
- **Execution:** Elevate your shoulders straight up toward your ears, pause briefly, then lower under control.
- **Common mistake:** Rolling the shoulders forward or backward during the lift. Keep the motion a straight vertical shrug — rolling adds nothing and can irritate the shoulder joint.
- **Bracing:** Brace your core lightly and keep your arms straight — all the work should be at your shoulders, not your elbows or back.

### Smith Machine Shrug
- **Setup:** Stand under the Smith bar with it resting at arm's length against your thighs, grip just outside hip width.
- **Execution:** Elevate your shoulders straight up, pause, then lower under control.
- **Common mistake:** Bending the elbows to help lift the bar. Keep the arms straight — the traps should be the only thing moving the weight.
- **Bracing:** Keep your core braced and your arms straight the whole set — don't let your elbows bend to help lift the bar.

### Machine Shrug
- **Setup:** Stand or sit at the shrug machine, grip the handles with arms extended down.
- **Execution:** Elevate your shoulders straight up against the resistance, pause, then lower under control.
- **Common mistake:** Using the legs to help drive the weight up. Isolate the movement to the shoulders — let the traps do the full work the machine is set up for.
- **Bracing:** Brace your core and isolate the movement to your shoulders — don't let your legs sneak into the lift.

### Cable Shrug
- **Setup:** Stand over a low pulley with a straight bar or handle attachment, arms extended down in front of or beside you.
- **Execution:** Elevate your shoulders straight up toward your ears, pause, then lower under control.
- **Common mistake:** Letting the cable's angle pull your arms forward or back out of a natural shrug path. Stand close enough to the pulley that the pull stays vertical.
- **Bracing:** Keep your core braced and stand close enough to the pulley that the pull stays vertical, not forward.

## Lower Back (3)

### Back Extension (45-Degree)
- **Setup:** Position your hips on the pad of a 45-degree hyperextension bench, ankles secured, body forming a straight line.
- **Execution:** Lower your torso forward under control to about 45°, then extend back up to a straight line without hyperextending.
- **Common mistake:** Hyperextending past straight at the top. Stop when your body forms a straight line — going further just loads the spine without adding benefit.
- **Bracing:** Brace your abs and glutes as you extend — a true brace, not just the hip hinge, is what protects your lower back here.

### Back Extension Machine
- **Setup:** Adjust the pad so it sits at your hip crease, secure your legs, torso upright to start.
- **Execution:** Lower your torso forward under control, then extend back to the upright starting position.
- **Common mistake:** Using momentum to snap back upright. Control both directions — the lowering phase is just as valuable as the extension.
- **Bracing:** Brace your core through both the lowering and the extension — control matters in both directions.

### Bird Dog
- **Setup:** Start on hands and knees, spine neutral, core lightly braced.
- **Execution:** Extend one arm forward and the opposite leg back simultaneously, hold briefly, then return and switch sides.
- **Common mistake:** Letting the hips rotate or the lower back sag as the limbs extend. Keep the pelvis level the whole time — that stability is the actual point of the exercise.
- **Bracing:** Brace your core hard enough that your hips don't rock as the opposite arm and leg extend — that stillness is the actual exercise.

## Glutes (8)

### Reverse Hyperextension
- **Setup:** Lie face-down on a reverse hyper machine or bench, hips at the edge, legs hanging and secured to the lever.
- **Execution:** Extend your legs back and up until they're in line with your torso, then lower under control.
- **Common mistake:** Using back hyperextension to assist the lift. Keep the torso still and let the glutes and hamstrings swing the legs.
- **Bracing:** Keep your core braced and let your glutes and hamstrings swing your legs — don't recruit your lower back to help.

### Hip Thrust Machine
- **Setup:** Sit against the machine's pad with the pad across your hips, feet planted, knees bent.
- **Execution:** Drive your hips up by extending through them, squeezing the glutes at the top, then lower under control.
- **Common mistake:** Pushing through the toes and extending the knees to help. Keep the push driven by the hips, not by straightening the legs.
- **Bracing:** Brace your abs and squeeze your glutes hard at the top — a strong exhale through the top of the rep reinforces the right muscles.

### Single-Leg Hip Thrust
- **Setup:** Set up as a standard hip thrust with shoulders on a bench, then lift one foot off the ground, extending that leg.
- **Execution:** Drive through the planted heel to extend the hips, squeezing the glute at the top, then lower under control.
- **Common mistake:** Letting the hips rotate toward the lifted leg. Keep both hip points level — rotation means the working glute isn't doing all the work it should.
- **Bracing:** Brace your core to keep both hip points level — rotation here usually means the working glute isn't doing all the work.

### Cable Pull-Through
- **Setup:** Face away from a low pulley, straddle the cable, hinge forward to grip the rope between your legs.
- **Execution:** Drive your hips forward to stand up, squeezing the glutes at the top, then hinge back down under control.
- **Common mistake:** Turning it into a squat by bending the knees heavily. Keep the knees softly bent and let the hip hinge do almost all the work.
- **Bracing:** Brace your core before the hip hinge — that's what keeps the pull in your glutes and hamstrings, not your lower back.

### Glute Kickback Machine
- **Setup:** Position yourself in the machine with one foot on the platform/pad, torso braced on the support.
- **Execution:** Extend your leg back by driving through the glute, then return under control.
- **Common mistake:** Arching the lower back to add range. Keep the torso braced and stop the movement where the lower back would otherwise start to take over.
- **Bracing:** Brace your torso against the support and keep your lower back still — let the hip joint do all the moving.

### Donkey Kick
- **Setup:** Start on hands and knees, one knee bent at 90°, core braced.
- **Execution:** Drive that foot up toward the ceiling by extending through the hip, squeezing the glute, then lower under control.
- **Common mistake:** Arching the lower back to kick higher. Keep the range limited to what the hip alone can produce without the spine moving.
- **Bracing:** Brace your core hard enough to keep your lower back from arching as you kick — the range should come only from the hip.

### 45-Degree Hip Extension
- **Setup:** Position your hips on the pad of a 45-degree bench, legs straight, body forming a straight line, arms crossed or holding weight at the chest.
- **Execution:** Lower your torso forward under control, then extend back up through the hips to a straight line.
- **Common mistake:** Rounding through the lower back instead of hinging from the hips. Keep the spine neutral and let the hip joint be the only thing that moves.
- **Bracing:** Brace your abs and keep your spine neutral — the hip joint should do the moving, not your lower back.

### Kettlebell Swing
- **Setup:** Stand with feet shoulder-width apart, kettlebell on the floor ahead of you, hinge down to grip it.
- **Execution:** Hike the bell back between your legs, then snap your hips forward explosively to swing it up to chest height, letting it float back down into the next rep.
- **Common mistake:** Squatting the weight up with the arms and legs instead of snapping the hips. This is a hip-hinge power move — the arms are just along for the ride.
- **Bracing:** Take a sharp exhale as you snap your hips forward, and brace your core hard at the top of each swing.

## Rear Delts (3)

### Cable Rear Delt Fly
- **Setup:** Set both pulleys at chest height, cross the cables, and grip the opposite-side handle with each hand.
- **Execution:** Pull your arms out and back in a wide arc until they're in line with your torso, then return under control.
- **Common mistake:** Bending the elbows more to turn it into a row. Keep a slight, fixed elbow bend and let the rear delts drive the arc, not the back.
- **Bracing:** Keep your core braced and torso still — the arc should come from your shoulders, not a rocking upper body.

### Incline Y Raise
- **Setup:** Lie face-down on an incline bench, light dumbbells hanging straight down, thumbs pointed up.
- **Execution:** Raise your arms up and out in a Y shape until roughly in line with your ears, then lower under control.
- **Common mistake:** Using weight heavy enough to force the traps to take over. This exercise only works at light loads — if your shoulders shrug up, drop the weight.
- **Bracing:** Keep your core lightly braced against the bench — this one works best light and controlled, not rushed.

### Cuban Press
- **Setup:** Hold dumbbells at your sides with elbows bent 90° and raised to shoulder height, palms facing down.
- **Execution:** Rotate your forearms up until they point to the ceiling, then press the dumbbells overhead, reversing the sequence to return.
- **Common mistake:** Rushing through the rotation phase to get to the press. The external rotation is the whole point of this exercise — slow that part down even if you speed up the press.
- **Bracing:** Brace your core and keep your torso upright through the whole combined rotation-and-press sequence.

## Side Delts (3)

### Upright Row (Cable)
- **Setup:** Stand facing a low pulley with a straight bar attached, grip just inside shoulder width, arms extended down.
- **Execution:** Pull the bar straight up along your torso to about chest height, leading with the elbows, then lower under control.
- **Common mistake:** Pulling the bar too high, past shoulder height. Stop around chest/collarbone height to keep the stress on the delts and traps, not the shoulder joint.
- **Bracing:** Brace your core and keep your torso still — let your elbows lead the pull rather than your lower back.

### Single-Arm Cable Lateral Raise
- **Setup:** Stand side-on to a low pulley, grip the handle with the far hand across your body, arm extended down.
- **Execution:** Raise your arm out to the side to about shoulder height, then lower under control before switching sides.
- **Common mistake:** Shrugging the shoulder up to assist the raise. Keep it down and relaxed — the side delt should be doing the lifting, not the traps.
- **Bracing:** Brace your obliques on the working side to keep your shoulder from shrugging up to assist.

### Machine Lateral Raise
- **Setup:** Sit in the machine with the pads against your upper arms, elbows slightly bent.
- **Execution:** Raise your arms out to shoulder height by pressing against the pads, then lower under control.
- **Common mistake:** Using momentum from the hips or torso to kick the weight up. Keep the lift slow and controlled — the machine removes the need for any body English.
- **Bracing:** Keep your core braced against the seat and avoid rocking your torso to help lift the pads.

## Biceps (9)

### EZ-Bar Curl
- **Setup:** Stand holding an EZ-curl bar with an underhand grip on the angled portions, arms extended down.
- **Execution:** Curl the bar up toward your shoulders by bending the elbows, then lower under control.
- **Common mistake:** Swinging the hips to help the bar up. Keep the torso still — if you need hip momentum, the weight is too heavy for strict curls.
- **Bracing:** Brace your core and keep your torso still — any hip sway is extra weight sneaking into the curl.

### Cross-Body Hammer Curl
- **Setup:** Stand holding a dumbbell at your side with a neutral grip, palm facing your thigh.
- **Execution:** Curl the dumbbell up and across your body toward the opposite shoulder, then lower back along the same path.
- **Common mistake:** Curling straight up instead of across the body. The diagonal path is what distinguishes this from a regular hammer curl — don't skip it.
- **Bracing:** Brace your core lightly so your torso stays square as the dumbbell travels across your body.

### Preacher Curl Machine
- **Setup:** Sit with your upper arms resting on the preacher pad, grip the handles with arms extended.
- **Execution:** Curl the handles up toward your shoulders, then lower under control to full extension.
- **Common mistake:** Letting the upper arms lift off the pad at the top of the curl. Keep them pinned — that's what removes momentum and isolates the biceps.
- **Bracing:** Keep your upper arms pinned to the pad and exhale through the curl rather than rocking your shoulders.

### Dumbbell Preacher Curl
- **Setup:** Sit at a preacher bench, upper arm resting on the pad, dumbbell held with an underhand grip, arm extended.
- **Execution:** Curl the dumbbell up toward your shoulder, then lower under control to full extension.
- **Common mistake:** Letting the elbow lift off the pad near the top. Keep it pinned down the whole rep to keep the tension on the biceps instead of letting the shoulder help.
- **Bracing:** Keep your elbow pinned to the pad and brace lightly — the pad does most of the stabilizing work here.

### Bayesian Curl
- **Setup:** Stand facing away from a low cable pulley, arm extended behind your torso, slight forward lean.
- **Execution:** Curl the handle up and forward toward your shoulder, then return under control to the stretched position behind you.
- **Common mistake:** Standing too close to the pulley, losing the behind-the-body stretch that makes this variation valuable. Step forward enough to feel a real stretch at the bottom.
- **Bracing:** Brace your core and hold the forward lean steady — that lean is what keeps the behind-the-body stretch honest.

### Cable Curl (Single Arm)
- **Setup:** Stand facing a low pulley, grip the handle with an underhand grip, elbow at your side.
- **Execution:** Curl the handle up toward your shoulder, then lower under control to full extension.
- **Common mistake:** Letting the elbow drift forward away from your torso. Keep it pinned at your side so the biceps do the isolated work.
- **Bracing:** Brace your core to keep your torso square — don't let the working arm pull your shoulder forward.

### Machine Biceps Curl
- **Setup:** Sit with your upper arms resting on the machine's pad, grip the handles with arms extended.
- **Execution:** Curl the handles up toward your shoulders, then lower under control to full extension.
- **Common mistake:** Rushing the eccentric (lowering) phase. Slow the return down — the machine's fixed path makes it easy to just let gravity drop the weight instead of controlling it.
- **Bracing:** Keep your upper arms on the pad and control the lowering phase as carefully as the lift.

### Zottman Curl
- **Setup:** Stand holding dumbbells with an underhand grip, arms extended down.
- **Execution:** Curl the dumbbells up with an underhand grip, rotate your wrists to an overhand grip at the top, then lower with that overhand grip before rotating back.
- **Common mistake:** Skipping the wrist rotation and just doing a normal curl. The rotation is what loads the forearms on the way down — don't shortcut it.
- **Bracing:** Brace your core lightly and keep the wrist rotation deliberate — rushing it defeats the point of the exercise.

### Drag Curl
- **Setup:** Stand holding a barbell or EZ-bar with an underhand grip, arms extended down close to your torso.
- **Execution:** Curl the bar up while dragging it along your torso, keeping the elbows traveling back rather than staying fixed, then lower the same way.
- **Common mistake:** Curling the bar away from the body like a standard curl. Keep it brushing your torso and let the elbows drift back — that's what shifts the emphasis onto the biceps' peak contraction.
- **Bracing:** Keep your torso upright and braced as the bar drags up your body — don't lean back to help it along.

## Forearms (5)

### Reverse Curl
- **Setup:** Stand holding a barbell or EZ-bar with an overhand (pronated) grip, arms extended down.
- **Execution:** Curl the bar up toward your shoulders keeping the overhand grip, then lower under control.
- **Common mistake:** Using lighter weight expectations like a normal curl, then swinging to compensate. The overhand grip makes this genuinely harder on the forearms/brachialis — drop the weight and keep it strict.
- **Bracing:** Brace your core and keep your torso still — this grip is already harder, don't add body English on top of it.

### Wrist Curl
- **Setup:** Sit holding a barbell or dumbbells with an underhand grip, forearms resting on your thighs or a bench, wrists just past your knees.
- **Execution:** Curl your wrists up by flexing them, then lower under control to let the wrists extend back down.
- **Common mistake:** Using the whole forearm to swing the weight instead of isolating the wrist joint. Keep the forearms still and let only the wrist hinge move.
- **Bracing:** Keep your forearms still and braced against your thighs — only the wrist joint should move.

### Reverse Wrist Curl
- **Setup:** Sit holding a barbell or dumbbells with an overhand grip, forearms resting on your thighs or a bench.
- **Execution:** Extend your wrists up by lifting the back of your hands, then lower under control.
- **Common mistake:** Using too much weight, since this movement is much weaker than a regular wrist curl. Start lighter than you'd expect — the wrist extensors are a small muscle group.
- **Bracing:** Keep your forearms braced against your thighs and use light weight — this is a small-muscle movement.

### Barbell Wrist Curl
- **Setup:** Sit holding a barbell with an underhand grip, forearms resting on your thighs, wrists just past your knees.
- **Execution:** Curl your wrists up by flexing them, then lower under control to full wrist extension.
- **Common mistake:** Gripping the bar so tight that the forearm flexors take over from the wrist flexors doing isolated work. Use a grip firm enough to hold the bar, not a death grip.
- **Bracing:** Keep your forearms pinned to your thighs and let only your wrists move.

### Dead Hang
- **Setup:** Grip a pull-up bar with hands shoulder-width or slightly wider, feet off the ground.
- **Execution:** Hang with arms fully extended, shoulders relaxed down away from the ears, for the target duration.
- **Common mistake:** Shrugging the shoulders up toward the ears to take tension off the grip. Let the shoulders hang passively — that's part of what this exercise is meant to train.
- **Bracing:** Breathe normally and let your shoulders relax down away from your ears — the point is a passive, not braced, hang.

## Quads (14)

### Smith Machine Squat
- **Setup:** Position the bar across your upper back under the Smith machine, feet set slightly forward of the bar's fixed vertical path.
- **Execution:** Squat down until your thighs are at least parallel to the floor, then drive back up along the fixed path.
- **Common mistake:** Keeping your feet directly under the bar like a free-weight squat. Because the path is fixed vertical, step your feet slightly forward so the descent doesn't push your knees too far over your toes.
- **Bracing:** Take a breath and brace your core before descending, the same as a free-weight squat — the fixed bar doesn't lessen that need.

### Hack Squat Machine
- **Setup:** Position your shoulders and back against the pads, feet shoulder-width on the platform.
- **Execution:** Bend your knees to lower the platform until your thighs are at least parallel, then press back up.
- **Common mistake:** Letting the knees cave inward as you press up. Keep them tracking in line with your feet throughout the whole range.
- **Bracing:** Brace your core against the pads and keep your knees tracking your feet through the whole range.

### Pendulum Squat
- **Setup:** Position your shoulders under the pads, feet shoulder-width on the platform, following the machine's arcing path.
- **Execution:** Bend your knees to lower along the arc until your thighs are at least parallel, then press back up.
- **Common mistake:** Fighting the machine's natural arc with your own path. Let your body follow the pendulum's arc rather than trying to move in a straight line.
- **Bracing:** Brace your core and let your body follow the machine's arc rather than fighting it with a stiff torso.

### Belt Squat
- **Setup:** Attach the belt around your hips, step onto the platform, feet shoulder-width apart.
- **Execution:** Squat down until your thighs are at least parallel to the floor, then stand back up, with the load pulling only on your hips.
- **Common mistake:** Rounding the upper back since there's no bar on it to keep you honest. Keep the same upright, braced torso you'd use in a back squat.
- **Bracing:** Brace your core and keep your torso as upright as you would with a bar on your back — there's no bar to keep you honest here.

### Horizontal Leg Press
- **Setup:** Sit in the horizontal leg press with your back against the pad, feet shoulder-width on the platform.
- **Execution:** Push the platform away until your legs are extended but not locked, then return under control.
- **Common mistake:** Locking the knees out hard at the top of every rep. Stop just short of lockout to keep tension on the quads instead of resting on the joint.
- **Bracing:** Brace your core against the seat and exhale through the press rather than holding your breath the whole set.

### Single-Leg Leg Press
- **Setup:** Sit in the leg press with one foot centered on the platform, the other foot off to the side or braced.
- **Execution:** Push the platform away with the working leg until nearly extended, then return under control.
- **Common mistake:** Letting the knee drift inward under the single-leg load. Keep it tracking in line with your foot the whole rep.
- **Bracing:** Brace your core to keep your hips level — the single-leg load wants to rotate your pelvis if you let it.

### Split Squat
- **Setup:** Take a long split stance, front foot flat, back heel raised, torso upright.
- **Execution:** Lower your back knee toward the floor by bending both knees, then push back up through the front heel.
- **Common mistake:** Taking too short a stance, forcing the front knee way out past the toes. Lengthen the stance until the front shin stays close to vertical at the bottom.
- **Bracing:** Brace your core and keep your torso upright — leaning forward shifts load off your quads and onto your lower back.

### Forward Lunge
- **Setup:** Stand tall, feet together, core braced.
- **Execution:** Step forward into a lunge, lowering your back knee toward the floor, then push back off the front foot to return to standing.
- **Common mistake:** Letting the front knee cave inward or shoot past the toes. Step far enough forward that the front shin stays close to vertical at the bottom.
- **Bracing:** Brace your core before stepping forward — that stability is what keeps the front knee tracking correctly.

### Sissy Squat
- **Setup:** Hold onto a stable support, rise onto your toes, and lean back slightly with knees pointed forward.
- **Execution:** Lower your torso back while bending the knees deeply, keeping a straight line from knees to shoulders, then rise back up.
- **Common mistake:** Bending at the hips instead of leaning back from the knees. Keep the torso and thighs in one straight line — this is a knee-dominant, not hip-dominant, movement.
- **Bracing:** Brace your core hard as you lean back — that brace is what keeps the movement at your knees instead of your lower back.

### Bodyweight Squat
- **Setup:** Stand with feet shoulder-width apart, toes slightly out, arms extended forward or crossed at the chest.
- **Execution:** Bend your knees and hips to squat down until your thighs are at least parallel, then stand back up.
- **Common mistake:** Letting the heels lift off the floor. Keep weight through the whole foot — if your heels keep rising, work on ankle mobility before adding load.
- **Bracing:** Brace your core and keep your chest up — don't let your torso collapse forward as you descend.

### Pistol Squat
- **Setup:** Stand on one leg, extend the other leg straight out in front of you, arms forward for counterbalance.
- **Execution:** Lower yourself down on the standing leg until your hips are below knee height, then press back up to standing.
- **Common mistake:** Letting the standing knee cave inward near the bottom. Actively push the knee out in line with your foot — losing that alignment is the most common pistol squat failure point.
- **Bracing:** Brace your core hard for balance — losing the brace here shows up immediately as a loss of balance, not just form.

### Wall Sit
- **Setup:** Lean your back against a wall, slide down until your thighs are roughly parallel to the floor, feet shoulder-width apart.
- **Execution:** Hold the position for the target duration, keeping your back flat against the wall and knees over your ankles.
- **Common mistake:** Letting the knees drift forward past the toes. Walk the feet out further from the wall until the knee stays stacked over the ankle.
- **Bracing:** Keep your core braced and breathe normally — holding your breath will make the hold feel harder than it needs to.

### Single-Leg Extension
- **Setup:** Sit at a leg extension machine with the pad against one shin, hands gripping the side handles for stability.
- **Execution:** Extend that leg until straight, then lower under control before switching legs.
- **Common mistake:** Using momentum to kick the weight up. Keep the movement slow and controlled on both the lift and the return.
- **Bracing:** Brace your core lightly and grip the handles for stability rather than momentum.

### Sled Push
- **Setup:** Load the sled, grip the handles at a height that lets you lean into it, athletic stance behind it.
- **Execution:** Drive forward through the balls of your feet in short, powerful steps, keeping your back flat and chest over the handles.
- **Common mistake:** Standing too upright and pushing with the arms. Lean into the sled and drive with the legs — the arms are just there to transmit force, not generate it.
- **Bracing:** Brace your core and keep your back flat as you lean into the sled — drive through your legs, not your lower back.

## Adductors (3)

### Lateral Lunge
- **Setup:** Stand with feet together, core braced.
- **Execution:** Step one foot out to the side, bending that knee and pushing your hips back while the other leg stays straight, then push off to return to standing.
- **Common mistake:** Letting the bending knee cave inward. Push it out in line with that foot, and keep the straight leg's foot flat to feel the stretch through the inner thigh.
- **Bracing:** Brace your core before shifting your weight sideways — that's what keeps the bending knee tracking correctly.

### Cossack Squat
- **Setup:** Take a wide stance, toes turned slightly out.
- **Execution:** Shift your weight to one side, bending that knee deeply while the other leg stays straight with the heel lifted, then push back to center and repeat on the other side.
- **Common mistake:** Letting the straight leg's knee twist instead of staying long and stable. Keep that leg fully extended and let the hip, not the knee, absorb the stretch.
- **Bracing:** Brace your core hard through the deep side bend — this range demands more core stability than it looks like.

### Copenhagen Plank
- **Setup:** Lie on your side with your top foot propped on a bench, bottom leg extended beneath, forearm on the floor for support.
- **Execution:** Lift your bottom leg and hips off the floor into a side-plank line, hold briefly, then lower under control.
- **Common mistake:** Starting with the full version before you're ready. Regress by bending the top knee against the bench until you can hold the full straight-leg version with good form.
- **Bracing:** Brace your whole side like a standard plank — this is an active hold, not a passive stretch.

## Abductors (2)

### Banded Lateral Walk
- **Setup:** Place a resistance band around your ankles or just above your knees, feet hip-width apart, slight squat position.
- **Execution:** Step sideways, maintaining tension on the band and a slight squat, for the target number of steps, then repeat in the other direction.
- **Common mistake:** Standing too tall and letting the steps get small. Stay low in the squat and take deliberate, controlled steps to keep constant band tension.
- **Bracing:** Brace your core and stay low in the squat — standing up tall is the easiest way to lose band tension.

### Clamshell
- **Setup:** Lie on your side with knees bent and stacked, feet together, hips stacked vertically.
- **Execution:** Keeping your feet together, rotate your top knee open like a clamshell, then lower under control.
- **Common mistake:** Rolling the hips backward to get more range. Keep the hips stacked and stationary — the movement should come only from the hip joint rotating.
- **Bracing:** Brace your core lightly and keep your hips stacked and stationary — the movement should come only from the hip joint.

## Calves (5)

### Smith Machine Calf Raise
- **Setup:** Position the bar across your upper back under the Smith machine, balls of your feet on a small block, heels free to drop.
- **Execution:** Rise onto your toes as high as possible, pause, then lower your heels below the block for a full stretch.
- **Common mistake:** Bouncing at the bottom instead of pausing. Let the stretch fully settle before driving back up — bouncing just uses elastic rebound instead of muscle contraction.
- **Bracing:** Brace your core lightly and let the stretch settle fully at the bottom before driving back up — don't bounce.

### Donkey Calf Raise
- **Setup:** Hinge forward at the hips with support in front of you, balls of your feet on a raised platform, torso roughly parallel to the floor.
- **Execution:** Rise onto your toes as high as possible, pause, then lower for a full stretch.
- **Common mistake:** Rounding the back to compensate for the bent-over position. Keep the spine neutral — the hinge angle changes calf loading, not your spinal position rules.
- **Bracing:** Keep your spine neutral in the bent-over position — the hinge changes calf loading, not your bracing rules.

### Single-Leg Calf Raise
- **Setup:** Stand on one foot on a raised edge or block, holding support if needed, other foot lifted.
- **Execution:** Rise onto your toes as high as possible, pause, then lower under control for a full stretch.
- **Common mistake:** Rushing through reps without full range. Pause at the top and let the heel drop fully at the bottom — single-leg calf work rewards strict tempo more than most exercises.
- **Bracing:** Brace your core lightly for balance and keep the tempo strict — this one rewards patience more than most.

### Dumbbell Calf Raise
- **Setup:** Stand holding dumbbells at your sides, balls of your feet on a raised platform or block.
- **Execution:** Rise onto your toes as high as possible, pause, then lower under control for a full stretch.
- **Common mistake:** Letting the ankles roll in or out during the raise. Keep the motion straight up and down through a stable ankle.
- **Bracing:** Keep your core lightly braced and your ankles tracking straight through the full range.

### Tibialis Raise
- **Setup:** Lean your back against a wall or sit with heels on the floor, toes pointed up.
- **Execution:** Lift your toes up toward your shins as high as possible, pause, then lower under control.
- **Common mistake:** Treating it as a throwaway warm-up and rushing the reps. This small muscle responds well to slow, controlled tempo — don't just flick through it.
- **Bracing:** Keep your core relaxed but stable — this is a small, controlled movement, not one that needs a hard brace.

## Abs (14)

### Ab Crunch Machine
- **Setup:** Sit with your chest against the pad (or hands on the handles above), hips stable against the seat.
- **Execution:** Crunch forward by flexing your spine, squeezing the abs, then return under control.
- **Common mistake:** Pulling with the arms on the handles instead of flexing the spine. Let the abs do the crunching — the handles are just there to brace, not to pull.
- **Bracing:** Exhale hard through the crunch and let your abs, not your arms on the handles, do the flexing.

### Crunch
- **Setup:** Lie on your back, knees bent, feet flat, hands lightly behind your head or crossed on your chest.
- **Execution:** Curl your shoulders up off the floor by flexing your spine, then lower under control.
- **Common mistake:** Pulling on the neck with your hands. Keep the hands light and let the abs do the lifting — your neck should just follow along passively.
- **Bracing:** Exhale as you curl up and keep your lower back pressed toward the floor the whole rep.

### Reverse Crunch
- **Setup:** Lie on your back, knees bent to 90°, shins roughly parallel to the floor, hands at your sides or under your lower back.
- **Execution:** Curl your hips up off the floor by flexing through the lower abs, then lower under control.
- **Common mistake:** Swinging the legs to generate momentum instead of curling the pelvis. Keep the knee angle fixed and focus on tilting the hips, not kicking the legs.
- **Bracing:** Keep your lower back pressed into the floor and exhale as you tilt your hips up.

### Sit-Up
- **Setup:** Lie on your back, knees bent, feet flat (anchored if needed), hands crossed on your chest or lightly behind your head.
- **Execution:** Curl your torso all the way up until your chest nears your thighs, then lower back down under control.
- **Common mistake:** Using momentum or a jerking motion to get up. Control both the lift and the lowering — the eccentric is where a lot of the ab work happens.
- **Bracing:** Exhale as you curl up and control the descent just as carefully as the lift.

### Decline Sit-Up
- **Setup:** Secure your feet on a decline bench, torso starting flat along the bench, hands crossed on your chest.
- **Execution:** Curl your torso up and forward until upright, then lower back down under control.
- **Common mistake:** Letting the hip flexors do most of the work by swinging up fast. Slow the rep down and focus on the spine curling, not just the torso hinging at the hip.
- **Bracing:** Brace your core before curling up — resist the urge to let your hip flexors do the first part of the movement.

### Weighted Crunch
- **Setup:** Lie on your back holding a plate or dumbbell against your chest, knees bent, feet flat.
- **Execution:** Crunch your shoulders up off the floor, then lower under control.
- **Common mistake:** Pulling the weight away from the chest to create momentum. Keep it pressed to your chest — that keeps the resistance directly in line with the ab contraction.
- **Bracing:** Exhale hard through the crunch and keep the weight pressed to your chest throughout.

### Hanging Knee Raise
- **Setup:** Hang from a pull-up bar with arms fully extended, legs straight down.
- **Execution:** Raise your knees up toward your chest by flexing the hips and curling the pelvis, then lower under control.
- **Common mistake:** Swinging the body to launch the knees up. Keep the swing to a minimum and control the lift with the abs, not momentum.
- **Bracing:** Brace your core before you raise your knees — keeping the swing to a minimum starts with a tight midline.

### Captain's Chair Leg Raise
- **Setup:** Position your forearms on the pads of a captain's chair, back against the support, legs hanging.
- **Execution:** Raise your knees (or straight legs) up toward your chest, then lower under control.
- **Common mistake:** Letting the lower back arch away from the pad as the legs lower. Keep the lower back pressed against the support the whole set.
- **Bracing:** Keep your lower back pressed against the support pad the entire set.

### Toes-to-Bar
- **Setup:** Hang from a pull-up bar with arms fully extended, legs straight down.
- **Execution:** Raise your legs up until your toes touch the bar, keeping them as straight as you can manage, then lower under control.
- **Common mistake:** Using a big, uncontrolled swing to get the toes up. Build toward this from hanging knee raises — the swing should be minimal, not the main driver.
- **Bracing:** Brace your core hard before initiating the raise — minimal swing starts with a tight midline.

### Dead Bug
- **Setup:** Lie on your back, arms extended toward the ceiling, knees bent 90° above your hips.
- **Execution:** Extend one arm and the opposite leg toward the floor without letting your lower back arch, then return and switch sides.
- **Common mistake:** Letting the lower back lift off the floor as the limbs extend. Keep it pressed flat the entire time — that's the actual skill this exercise is training.
- **Bracing:** Keep your lower back pressed flat into the floor the entire time — that's the actual skill this exercise trains.

### Bicycle Crunch
- **Setup:** Lie on your back, hands lightly behind your head, knees bent and lifted, shoulders curled slightly off the floor.
- **Execution:** Rotate to bring one elbow toward the opposite knee while extending the other leg, then switch sides in a pedaling motion.
- **Common mistake:** Pulling on the head/neck to generate the rotation. Let the obliques drive the twist — the hands should stay light, not yanking.
- **Bracing:** Exhale sharply with each rotation and keep your lower back pressed down, not arched.

### V-Up
- **Setup:** Lie flat on your back, arms extended overhead, legs straight.
- **Execution:** Simultaneously raise your legs and torso to form a V shape, reaching your hands toward your feet, then lower back down under control.
- **Common mistake:** Using momentum to rock up instead of a controlled fold. Keep both halves of the movement — the leg lift and the torso curl — deliberate and controlled.
- **Bracing:** Exhale as you fold into the V and keep the movement controlled on both the way up and the way down.

### Hollow Hold
- **Setup:** Lie on your back, arms extended overhead, legs extended, lower back pressed into the floor.
- **Execution:** Lift your shoulders and legs slightly off the floor, holding the lower-back-flat position for the target duration.
- **Common mistake:** Letting the lower back arch off the floor to hold the position longer. Raise the legs to whatever height keeps the back flat — height isn't the goal, control is.
- **Bracing:** Breathe steadily through the hold — holding your breath will make the position feel harder than it is.

### Mountain Climber
- **Setup:** Start in a high plank position, hands under shoulders, body in a straight line.
- **Execution:** Drive one knee toward your chest, then quickly switch legs in a running-like motion, keeping the hips level.
- **Common mistake:** Letting the hips pike up or sag as the pace increases. Keep the plank line stable — slow down if speed is breaking your form.
- **Bracing:** Brace your core to keep your hips level as the pace increases — slow down if speed starts breaking your plank line.

## Obliques (5)

### Side Plank
- **Setup:** Lie on your side, forearm on the floor under your shoulder, legs stacked or staggered.
- **Execution:** Lift your hips off the floor into a straight line from head to feet, holding for the target duration.
- **Common mistake:** Letting the hips sag toward the floor or pike up toward the ceiling. Keep a dead-straight line the whole hold.
- **Bracing:** Brace your whole side hard — a side plank is an active hold, not a passive lean.

### Cable Woodchop (High-to-Low)
- **Setup:** Set the pulley high, stand side-on, grip the handle with both hands, arms extended up and across your body.
- **Execution:** Rotate your torso and pull the handle down and across to the opposite hip, then return under control.
- **Common mistake:** Bending the arms to pull instead of rotating the torso. Keep the arms relatively fixed and let the obliques drive the rotation.
- **Bracing:** Brace your core and let the rotation come from your trunk, not your arms pulling the cable.

### Cable Woodchop (Low-to-High)
- **Setup:** Set the pulley low, stand side-on, grip the handle with both hands, arms extended down and across your body.
- **Execution:** Rotate your torso and pull the handle up and across to the opposite shoulder, then return under control.
- **Common mistake:** Using the arms to lift instead of rotating through the trunk. Let the torso rotation generate the movement, with the arms just along for the ride.
- **Bracing:** Brace your core and rotate through your trunk — keep your arms relatively fixed relative to your torso.

### Landmine Rotation
- **Setup:** Set a barbell in a landmine attachment, grip the loaded end with both hands, arms extended in front of you.
- **Execution:** Rotate the bar from one side to the other by twisting through your torso, keeping your arms relatively fixed.
- **Common mistake:** Letting the lower body swing along with the rotation. Keep your hips and feet relatively stable so the obliques, not momentum, drive the rotation.
- **Bracing:** Brace your core and keep your hips and feet stable so the obliques, not momentum, drive the rotation.

### Suitcase Carry
- **Setup:** Stand holding a single dumbbell or kettlebell at your side like a suitcase, the other arm relaxed at your side.
- **Execution:** Walk forward for the target distance or time, resisting the urge to lean away from the weight.
- **Common mistake:** Leaning toward the loaded side to make it easier. Stay upright — resisting that lean with the obliques is the entire point of the carry.
- **Bracing:** Brace your obliques on the loaded side hard — resisting the lean is the entire point of this carry.

## Full Body (4)

### Hang Clean
- **Setup:** Start standing with a barbell at mid-thigh, knees slightly bent, grip just outside shoulder width.
- **Execution:** Explosively extend your hips and knees, shrug the bar up, then pull yourself under it to catch it in a front-rack position with knees bent.
- **Common mistake:** Pulling with the arms too early. Let the legs and hips finish the explosive extension first — the arms only start pulling once that extension is nearly complete.
- **Bracing:** Take a breath and brace your torso before the pull — a loose torso here bleeds power out of the whole lift.

### Turkish Get-Up
- **Setup:** Lie on your back holding a kettlebell overhead in one arm, that same-side knee bent, foot flat.
- **Execution:** Work through the sequence — rolling to an elbow, then a hand, bridging the hips, sweeping the leg through, and standing up — while keeping the kettlebell locked out overhead the whole time.
- **Common mistake:** Rushing through the sequence instead of treating each step as a distinct checkpoint. Move slowly and deliberately — speed is not the goal of this exercise.
- **Bracing:** Brace your core at every checkpoint of the sequence — each position should feel stable before you move to the next.

### Burpee
- **Setup:** Stand with feet shoulder-width apart.
- **Execution:** Drop into a squat, place your hands down, kick your feet back into a plank, perform a push-up, jump your feet back in, then explode up into a jump.
- **Common mistake:** Letting the hips sag in the plank/push-up portion as fatigue sets in. Hold the plank brace even when you're tired — that's usually where form breaks down first.
- **Bracing:** Brace your core through the plank/push-up portion — that's usually where form breaks down first as fatigue sets in.

### Battle Ropes
- **Setup:** Stand in an athletic stance holding one end of each rope, arms extended toward the anchor point.
- **Execution:** Alternate driving each arm up and down rapidly to create waves through the ropes, keeping your core braced the whole time.
- **Common mistake:** Using only the arms and shoulders while standing stiff-legged. Stay in an athletic stance and let the legs and core share the work — it shouldn't be an arms-only exercise.
- **Bracing:** Brace your core in the athletic stance — let your legs and trunk share the work instead of standing stiff-legged.

## Cardio (10)

### Treadmill
- **Setup:** Set your target speed and incline before stepping onto the belt, hands light on the rails only if needed for balance.
- **Execution:** Maintain an upright posture and natural stride for the target duration or distance.
- **Common mistake:** Gripping the front rails and leaning on them for support. That reduces the real workload and can strain the shoulders — let your legs and core do the work unsupported.
- **Bracing:** Breathe naturally and keep a tall, relaxed posture — there's no bracing needed here, just steady rhythm.

### Stationary Bike
- **Setup:** Adjust the seat height so your knee has a slight bend at the bottom of the pedal stroke, feet secured in the pedals or straps.
- **Execution:** Pedal at your target cadence and resistance for the target duration.
- **Common mistake:** Setting the seat too low, forcing excessive knee bend. A seat that's too low adds unnecessary knee stress — set it so your leg is almost, but not fully, extended at the bottom.
- **Bracing:** Keep your core lightly engaged to support an upright posture rather than slumping over the handlebars.

### Elliptical
- **Setup:** Step onto the pedals, grip the moving handles if using them, set your target resistance and incline.
- **Execution:** Move through the elliptical stride for the target duration, keeping a tall, relaxed posture.
- **Common mistake:** Hunching forward over the console. Keep an upright posture — leaning on the machine reduces the workload and can strain the lower back over time.
- **Bracing:** Keep an upright, relaxed posture and breathe naturally through the stride.

### Ski Erg
- **Setup:** Stand facing the machine, grip the handles overhead, feet set in an athletic stance.
- **Execution:** Pull the handles down and back by hinging at the hips and engaging the lats and core, then let them return smoothly overhead.
- **Common mistake:** Pulling with the arms alone instead of hinging through the hips. The power should come from the hip hinge and lats, with the arms finishing the pull.
- **Bracing:** Brace your core as you hinge into the pull — the power comes from your hips and lats, not just your arms.

### Jump Rope
- **Setup:** Hold the handles lightly, rope behind your heels, elbows close to your sides.
- **Execution:** Jump just high enough to clear the rope using small wrist rotations to turn it, landing softly on the balls of your feet.
- **Common mistake:** Jumping too high with big, stomping landings. Keep the jumps low and the landings soft — the rope should clear with inches, not a big leap.
- **Bracing:** Keep your core lightly braced and breathe rhythmically with the jumps rather than holding your breath.

### Outdoor Run
- **Setup:** Choose a route and target pace or distance, warm up with an easy walk or jog first.
- **Execution:** Maintain a steady, sustainable pace for the target duration or distance, adjusting effort for terrain.
- **Common mistake:** Starting too fast and fading hard later. Settle into your target pace in the first few minutes rather than sprinting out of the gate.
- **Bracing:** Keep a relaxed, tall posture and breathe rhythmically — tension in your shoulders wastes energy over distance.

### Outdoor Walk
- **Setup:** Choose a route and target pace or distance.
- **Execution:** Maintain a brisk, purposeful walking pace for the target duration or distance.
- **Common mistake:** Letting the pace drift too slow to count as meaningful cardio. If the goal is a training effect, keep the pace brisk enough that conversation takes some effort.
- **Bracing:** Keep an upright posture and breathe naturally at a pace that still lets you hold a conversation with effort.

### Outdoor Cycling
- **Setup:** Check your bike and helmet, choose a route and target duration or distance.
- **Execution:** Maintain a steady cadence and effort appropriate to the terrain for the target duration or distance.
- **Common mistake:** Coasting on flats and descents instead of maintaining effort. If this is a training ride rather than a recovery ride, keep pedaling with purpose through the easy sections too.
- **Bracing:** Keep your core lightly engaged to support your posture, especially on longer climbs or descents.

### Swimming
- **Setup:** Choose your stroke and target distance or duration, warm up with a few easy lengths first.
- **Execution:** Maintain steady, efficient stroke mechanics for the target duration or distance.
- **Common mistake:** Letting the head lift too high to breathe, which drags the hips down and wastes energy. Rotate the head to the side to breathe rather than lifting it forward.
- **Bracing:** Exhale steadily underwater and breathe to the side rather than lifting your head, which drags your hips down.

### Hiking
- **Setup:** Choose a route and check pack weight, footwear, and water before setting out.
- **Execution:** Maintain a sustainable pace suited to the terrain and elevation for the target duration or distance.
- **Common mistake:** Setting a pace on climbs that isn't sustainable for the whole hike. Slow down on the uphill sections rather than burning out before the hike is done.
- **Bracing:** Keep your core lightly engaged for stability on uneven terrain, and breathe at a pace you can sustain on the climbs.

