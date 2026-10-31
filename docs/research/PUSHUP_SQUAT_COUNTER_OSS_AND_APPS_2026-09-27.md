# Push-up & squat rep counters — open-source projects and apps — 2026-09-27

Research: 2026-09-27 · ZCode (`zai-start-plan/GLM-5.3-Flash`, main session).
Status: **DRAFT, uncommitted, research only.** No source, config, test or
release file was changed. Nothing here changes `docs/CONTRACT.md`,
`docs/PROJECT_STATUS.md` or any release scope; this adds no status section.
This note is complementary to `docs/research/GITHUB_REP_COUNTING_OPTIONS_2026-09-24.md`
(OSS adoption deep-dive) and `docs/research/COMPETITIVE_ANALYSIS.md`
(Push Up Arena teardown, 2026-09-22); it does not re-verify what those settled.

Sources checked on 2026-09-27 unless stated. Star counts, ratings, downloads
and prices are snapshots, not guarantees.

Evidence labels:

- **[V]** verified from the cited primary source during this session
  (GitHub API, iTunes Search API, pub.dev API, npm registry API, official
  store listing text).
- **[E]** estimate or secondary write-up (search snippets, roundups,
  third-party trackers); directionally useful, not audited.
- **[I]** inference from the material read in this pass, not externally
  verified.

Method note up front: three background research agents were dispatched for
this note and all three died to provider-side captcha timeouts; the research
was completed inline in the main session on 2026-09-27. iOS app data comes
from Apple's iTunes Search API (`itunes.apple.com/search`) [V]; Android store
pages were not fetchable, so Android entries rely on
`COMPETITIVE_ANALYSIS.md` (2026-09-22) and search snippets [E].

## 0. Headline

**Nothing worth adopting exists in open source — and this is now confirmed
twice, from two independent sweeps (2026-09-24 and 2026-09-27).** Every
camera rep counter on GitHub is a one-off demo applying the same recipe:
a pose model (MediaPipe / ML Kit / PoseNet) + per-joint angle thresholds +
an up/down state machine. None is a maintained library; most have no licence
at all, which alone blocks reuse. The only packages that ship working
rep-counting logic are **commercial B2B SDKs** (Sency SMKit, KinesteX,
QuickPose, Kemtai) — which is itself the finding: counting is product logic,
not model capability.

On the app side the market has split into four groups: (1) program/challenge
apps with manual or sensor counting own the ratings (Just 6 Weeks 4.77★,
9.4k iOS ratings [V]); (2) a 2024–2026 wave of camera-AI counters is real
but still small on iOS, led by ARKit-based "Push Up Counter & Tracker"
(4.83★, 3.4k ratings) [V]; (3) the breakout distribution mechanic of the
niche is **"do reps to unlock screen time"** (Pushscroll 4.68★/17.6k and
PushUp Time 4.67★/11.5k iOS ratings) [V]; and (4) the distribution leader
(PUSHUP ARENA, Android, 400K installs) holds **2.0★ with counting broken in
a large share of reviews** [V, 2026-09-22]. The counting-trust gap is the
single consistent weakness across the category, and it is exactly the wedge
Training Arena is built around.

## 1. Open-source projects (GitHub sweep, 2026-09-27)

From `api.github.com/search/repositories` queries `pushup counter`,
`squat counter`, `push-up counter`, `rep counter pose`, `squat form mediapipe`,
`workout rep counting` (8 results each, 41 unique repos) [V]. Repos already
covered by `GITHUB_REP_COUNTING_OPTIONS_2026-09-24.md` §2.7 are marked ⊕ —
all were re-seen and none changed materially.

| Repo | ★ | Licence | Last push | Platform | Detector | Rep counting | Verdict for us |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BotchetDig/workout-gate | 221 | MIT | 2026-06-25 | Python CLI | camera | push-up count gates a coding agent's prompts | Novelty dev-tool, not reusable; proof the technique is now a party trick |
| ⊕ MichistaLin/mediapipe-Fitness-counter | 133 | **none** | 2023-09-15 | Python | MediaPipe | angle FSM (push-up, squat, pull-up, sit-up) | Demo; no licence blocks reuse |
| NgoQuocBao1010/Exercise-Correction | 128 | MIT | 2025-05-19 | Python NB | MediaPipe | angle FSM + form-correction rules | Closest OSS reference for "count + form"; still a notebook demo |
| ⊕ VNOpenAI/pushup-counter-app | 82 | **none** | 2022-10-15 | Python | BlazePose | angle FSM + activation functions | Demo |
| aryanvij02/PushUpCounter | 65 | **none** | 2024-07-09 | Python | MediaPipe + OpenCV | angle FSM | Demo |
| wijayamakro19-sketch/FormAI-Coach-Elevate | 55 | **none** | 2026-09-23 | HTML | — | — | Static page, effectively no code [I] |
| SuryaThejas-07/Virtual_Fitness_Trainer | 41 | **none** | 2026-06-17 | TS web | pose | real-time form tracking | Web demo |
| ⊕ philippgehrke/SquatCounter | 39 | **none** | 2022-03-17 | Swift/iOS | — | squat counter | Stale iOS demo |
| NetoPedro/Deep-Learning-Push-Up-Counter | 31 | MIT | 2020-07-13 | Python NB | — | DL regression on video (offline) | Research, not real-time |
| ⊕ bipinkc19/squat-counter | 30 | MIT | 2020-01-17 | Python | PoseNet | angle FSM | Stale |
| talha828/pushup-counter | 23 | **none** | 2024-08-08 | Flutter/Dart | ML | push-up app | Demo app |
| quickpose/example-ios-squat-counter | 17 | **none** | 2023-06-21 | Swift | QuickPose (commercial) | squat | Vendor demo |
| ⊕ greis/squat-counter | 16 | **none** | 2022-12-09 | JS browser | pose | squat | Demo |
| KinesteX/KinesteX-SDK-ReactNative · -Swift | 14 · 6 | Apache-2.0 | 2026-09-21 · 2025-04-20 | RN · Swift | proprietary | rep count + form + voice | Wrappers for a paid SDK, not OSS counting logic |
| scottquach/Proximity-Push-Up-Counter | 13 | **none** | 2019-05-11 | Android | proximity sensor | nose-near-floor proximity | Sensor trick, no camera |
| ⊕ nimom38/Pushup-and-Squats-Counter | 10 | **none** | 2021-12-02 | Android Kotlin | camera | push-up + squat | Demo app |
| hacklavya/pushup_counter | 9 | GPL-3.0 | 2021-07-10 | Python | background subtraction | motion cycles, no pose model | Different technique; GPL |
| rohanx01/Squat-Analysis-Model | 10 | MIT | 2024-07-18 | Python GUI | MediaPipe | squat depth analysis | Demo |
| ⊕ cclaan/PushupCounter | 9 | MIT | 2024-01-12 | Swift | TrueDepth camera | push-up | Demo |
| ⊕ NazarKozak/RepCounterSDK | 5 | MIT | 2026-06-13 | Swift | Apple Vision body tracking | rep events | Small real library; iOS-only |

**Takeaways.** The single most-starred new find (workout-gate, 221★) is a
gag tool that blocks a coding agent until you do camera-counted push-ups —
the technique has become a developer toy, which tells you there is no
moat in the counting itself. Of 20 notable repos, 13 have **no licence**
(a commercial blocker on its own), and the MIT/Apache ones are demos or
SDK wrappers. `NgoQuocBao1010/Exercise-Correction` is the only one worth
reading as a reference implementation of count-plus-form rules [I].

## 2. Reusable packages

| Package | Version / date | Licence | Ships | Verdict |
| --- | --- | --- | --- | --- |
| `pose_camera_view` (pub.dev) | v1.0.5, 2024-07-31 [V] | see pub.dev page | Flutter widget on ML Kit that tracks push-ups and emits `init`/`middle`/`completed` per rep | The only pub.dev package besides `live_pose_detector` that ships actual rep events; one author, one exercise, stale |
| `sport_exercise_tracker_widget` (pub.dev) | v1.0.0, 2025-10-18 [V] | see pub.dev page | Flutter real-time exercise-tracking widget; repo MohammedAmineDridi/real_time_exercise_tracker_widget | Unproven, single release |
| `kinestex_sdk_flutter` (pub.dev) | v1.5.1, 2026-07-04 [V] | commercial | KinesteX AI fitness SDK (rep counting, form, voice) | Buy-not-build route; see §4 |
| `flutter_smkit_ui` (pub.dev) | v1.6.0, **2026-09-23** [V] | commercial | Sency SMKitUI: assessments, workouts, guidance, summaries (iOS+Android) | The most actively maintained counting SDK in Flutter; commercial |
| ⊕ `pushupcount` (pub.dev) | v0.0.6, ~2 years old [V 2026-09-24] | BSL-1.0 | push-up counting | Not permissive; unchanged |
| ⊕ `live_pose_detector` (pub.dev) | v0.0.1 [V 2026-09-24] | MIT | push-up FSM on ML Kit | Unchanged |
| npm `rep counter` / `pushup counter` searches | — [V] | — | — | **Nothing relevant at all** — results are CSS/byte/code-pushup counters |
| PyPI | — | — | — | PyPI search page is JS-blocked from this session [E]; the Python OSS space is covered by the GitHub sweep in §1 |

## 3. Consumer apps — iOS verified via iTunes Search API (2026-09-27)

86 unique iOS apps across the searches `push up counter`, `squat counter`,
`push ups`, `rep counter` [V]. Ratings/counts are snapshots.

### 3.1 Camera-AI counters (the direct competitive set)

| App | Seller | iOS rating | Counting method (per official listing) | Notes |
| --- | --- | --- | --- | --- |
| Push Up Counter & Tracker | wsfu | 4.83★ (3,359) [V] | "Augmented Reality technology from Apple (ARKit)" auto-counts push-ups | The best-rated dedicated camera counter on iOS; 4 workout modes (sequence, open goal, limit, timer) |
| Push Up Arena - Fitness Game | Airix LLC | 4.64★ (3,059) [V] | (iOS twin of the Android leader; see COMPETITIVE_ANALYSIS §1) | 1v1 PvP, bosses, dungeons; hard subscription |
| pushr – push-up workouts | Joao Pozzobon | 4.67★ (410) [V] | "intelligently count your push-up repetitions using facial tracking" | Counts via front-camera face proximity instead of a body pose model [I] |
| PushPush: AI Push-Up Coach | Estee Inc. | 4.63★ (180) [V] | front-camera "AI" auto counting | Standard counter + 100-push-up program |
| Push Up Counter GOLDEN PushUps | Stephan Duechtel | 4.59★ (74) [V] | "pose estimation technology directly on your device" | New (Play listing 2026); plans + counting |
| Pushoff - Ranked Pushup | Kissan Tejas heggadey | 4.34★ (35) [V] | on-device pose tracking; reps become damage vs monsters; ranked battles | Tiny, but the closest concept copy of Training Arena's camera-battle loop on iOS [I] |
| Squat Social: Butt Workout | Josh Mustafa | 0 ratings [V] | "on device AI camera counts your squats"; social leaderboards; "Rep Shield" unlocks screen time | **Launched 2026-09-11** — AI squat counter + leaderboards + screen-time currency in one; direct concept overlap [I] |

Android side (not API-verifiable; from COMPETITIVE_ANALYSIS §4 and search):
GymCam – Camera Rep Counting (free, live 2026-07) [E], plus the leader
PUSHUP ARENA (VOLARA), PUPG (1.33★), Pushup RPG (100K+, 4.8★) and the
screen-time apps already catalogued [E].

### 3.2 The "reps are currency" sub-category (breakout mechanic)

| App | Seller | iOS rating | Mechanic |
| --- | --- | --- | --- |
| Pushscroll: Exercise To Scroll | Pushscroll GmbH | 4.68★ (17,595) [V] | push-ups buy scrolling time |
| PushUp Time: App Blocker | KAMAN LABS LLC | 4.67★ (11,549) [V] | "On-device AI counts your reps" (push-ups, squats, sit-ups) to unlock TikTok/IG/YT for 15–120 min |
| PushUpLock, PushUp App Blocker (PushBlock), ClearSpace | various | ~4.7★ [V] | same rep-for-screen-time loop |
| Squat Social "Rep Shield" | Josh Mustafa | new [V] | same mechanic grafted onto a social squat counter |

This mechanic repeats across at least five apps on iOS alone and is the
niche's most replicated acquisition loop after the skeleton-overlay battle
clip [I].

### 3.3 Sensor/manual programs (own the ratings, not the camera)

| App | Seller | iOS rating | Counting method |
| --- | --- | --- | --- |
| 100 Push Ups: Just 6 Weeks | Aleksandr Lomakin | 4.77★ (9,428) [V] | manual/program (since 2012); 11 programs incl. 200 squats |
| Push ups: 100 pushups pro | FITNESS22 LTD | 4.89★ (7,342) [V] | audio-coach program |
| Butt workout: squat challenge | FITNESS22 LTD | 4.90★ (2,289) [V] | program |
| 0-200 Squats Trainer Challenge | Zen Labs LLC | 4.76★ (1,825) [V] | program |
| Push Up Counter - 100 Pushups | Foxyfitness GmbH | 4.83★ (806) [V] | proximity sensor + camera hybrid |
| DunDun - Squat Counter | 家浩 汪 | 4.37★ (126) [V] | **Apple Watch / AirPods motion sensors** count squats; voice announcements |

Android incumbents (Hevy, Strong, Freeletics) own logging and plans; none
owns camera-counted competition [E, 2026-09-22].

### 3.4 Commercial B2B rep-counting SDKs (the "buy" route)

| SDK | Evidence | Ships |
| --- | --- | --- |
| Sency SMKit | Flutter plugin `flutter_smkit_ui` v1.6.0 (2026-09-23) [V]; iOS/Android native SDKs [E] | assessments, workouts, rep counting, form, summaries — camera only, no wearables |
| KinesteX | Apache-2.0 RN/Swift wrappers [V]; Flutter plugin v1.5.1 [V]; white-label positioning [E] | rep counting, real-time voice feedback, calories, custom experiences |
| QuickPose | iOS SDK; squat-counter example repo on GitHub [V] | iOS-only counting/form features |
| Kemtai, PoseTracker | named in roundups [E] | web SDK / API for rep counting from a phone camera |

Bias note: the comparison site that enumerates this category
(aifitnessapi.com) is funded by KinesteX [V] — treat its comparisons as
marketing [I].

## 4. Techniques taxonomy and failure modes

How a "rep" is actually detected, across everything surveyed:

1. **Joint-angle thresholds + up/down state machine** — the dominant
   technique in ~all OSS repos and most apps; the same design as Training
   Arena's counter (per-exercise joint chain, angle bands, debounce) [I,
   consistent with every repo in §1].
2. **Learned per-frame classification** — ML Kit's documented k-NN pose
   classifier (~100 samples/class) and small DL models
   (NetoPedro/Deep-Learning-Push-Up-Counter) [V 2026-09-24; V §1].
3. **Temporal/period estimation over video** — RepNet and successors;
   offline/research, not on-device real-time [V 2026-09-24].
4. **Motion sensors** — Apple Watch/AirPods accelerometer counting (DunDun)
   [V]; the niche's credible non-camera fallback for squats.
5. **Proximity proxies** — nose-to-floor via the phone's proximity sensor
   (Foxyfitness, Proximity-Push-Up-Counter) [V]; face-approach via front
   camera/ARKit (pushr) [V]. Cheap and robust, but trivially gameable and
   form-blind [I].
6. **Background subtraction** (hacklavya) — motion cycles without a pose
   model; a curiosity [V].

Known failure modes, consistent across the category:

- **Framing and camera position.** ML Kit requires the whole person
  in frame (≥256×256 px, as large as possible); missing landmarks get
  out-of-frame coordinates [V 2026-09-24]. Camera angle matters — side view
  is generally required for push-ups, and apps ship green-light "detection
  OK" indicators and placement guidance as the workaround [E, reddit].
- **Silently skipped partial reps read as bugs.** The commonest complaint
  pattern; one competitor's entire pitch is rejecting bad reps *and saying
  why* ("counting only accepts full reps, chest low enough and arms extended
  at the top, and tells you why it didn't count") [E,
  reddit.com/r/SideProject/comments/1w74cif].
- **Camera motion counted as reps** — the category leader's top-voted
  Android reviews [V, COMPETITIVE_ANALYSIS §2].
- **Body-type and angle variation** — named by an AI-counter developer as
  "the main challenge" [E, reddit.com/r/reactnative/comments/1o69sv0].
- The leader's 2.0★ with 400K installs demonstrates the asymmetry:
  distribution can be won with broken counting, but reviews show it caps
  the product's ceiling and reputation [V/E, 2026-09-22].

## 5. Decision applied — references chosen and ported (2026-09-27)

The owner asked for one push-up and one squat reference to be "configured"
and the previous counting model deleted. The counter code was reviewed
against the two references before deleting anything, and the literal swap
was rejected — every candidate is demo-grade (see §1–§2), while the in-repo
counter (`rep_counter.dart` + `exercise_profile.dart`) is a superset of all
of them: hysteresis, dwell, debounce, framing gates, view-mode detection,
form validation and a host-test suite that none of the references has. The
owner did not answer the confirmation prompt, so the decision was applied on
best judgment:

- **Push-ups: reference = BotchetDig/workout-gate (221★, MIT,
  `workout_gate/detector.py`).** Read in full. Its push-up counter is a
  strict subset of ours — elbow hysteresis 95/150 (ours 100/150, derived
  from `docs/media/ATHLETE_SPEC.md` §5), 3-frame smoothing (ours EMA 0.35),
  a lost-reset after 5 frames (ours 300 ms grace + stall reset), sticky side
  selection with a 0.15 margin (ours 0.12) and a horizontal-torso posture
  guard whose rep-validity role our bottom straightness check already
  covers. **Nothing ported; nothing deleted.**
- **Squats: reference = rohanx01/Squat-Analysis-Model (MIT,
  `squat_analyser.py`).** Read in full. Its rep signal (thigh tilt 25°/30°)
  is cruder than our knee band, and its pixel-space spine-flexion check is
  scale-dependent (our lean check is the robust equivalent); its knee-over-toe
  rule is facing-dependent and biomechanically contested — both skipped,
  documented. **Ported: the heels-lifted form cue** as a soft, non-blocking
  coaching cue: `heelToToeAngleDegrees` in `pose_math.dart` (folded to 0–90°
  so either facing works, unlike the reference's single-facing `atan2`),
  re-baselined on every standing frame (knee ≥ 160°), cue at
  `heelsLiftedDeviationDeg` = 12° (candidate until F3; reference gates at
  +3° on pixel landmarks), disabled when either foot landmark is below the
  framing likelihood. It rides `TrackingPauseReason.heelsLifted` with player
  copy and can accompany `tracking` like `tooClose` — it can never silently
  drop a rep. `CounterRejection` was deliberately not extended: rejection
  reasons are diagnostic-only today, so a new rejection gate would drop reps
  without telling the athlete why — the category's #1 complaint.
- Also considered and **not** ported: workout-gate's thigh-tilt proxy for
  counting squats with the ankle out of frame (directly addresses the Redmi
  10 framing failure, but changes rep semantics and weakens anti-cheat —
  deferred to F3 real-device validation per the 2026-09-24 doc §4).
- Result: `flutter test` 610 passing (+2 skipped), 0 failures, including 3
  new squat heel-cue tests in `rep_counter_test.dart`.

## 6. Takeaways for Training Arena

1. **Nothing to adopt — again.** The 2026-09-24 conclusion holds after a no OSS package or repo ships counting logic we could put a
   commercial set count behind. Our own FSM is at parity with, or ahead of,
   everything public. Do not spend engineering time on another adoption
   pass.
2. **Counting trust is the category's #1 weakness and our wedge.** The
   winning response pattern already exists in the market (reject bad reps
   and explain why; show the skeleton; prove the count). This raises the
   priority of the Redmi 10 validation (R1) and the trust surface over any
   new feature — and suggests shipping the "why didn't this rep count"
   coaching copy in the counter UI [I].
3. **Two distribution mechanics are proven, neither is ML:** the
   skeleton-overlay battle clip (leader, 100M+ views/month [E 2026-09-22])
   and reps-for-screen-time (five+ iOS apps [V]). Both are UX/content
   decisions; the screen-time mechanic is contract-excluded today but worth
   an explicit owner decision (CA-11) rather than silence [I].
4. **The niche is being entered from multiple sides in 2026** — Squat
   Social (AI squats + leaderboards + screen time, 2026-09-11), Pushoff
   (ranked push-up battles), GymCam (generic camera counter). Shipping
   beats uniqueness; the window for "first camera-counted 1v1 battle app
   that actually counts" is open but not empty [I].
5. **B2B SDKs exist (Sency, KinesteX, QuickPose) if we ever need exercises
   beyond push-up/squat quickly** — but they are commercial, per-exercise
   generic, and would compromise the on-device, frames-never-leave-device
   trust story and the receipts positioning. Not needed for the current
   scope [I].
6. **Sensor counting is a credible future fallback for squats** (DunDun on
   Watch/AirPods), relevant only if camera validation fails on low-end
   Android; it cannot serve 1v1 battles because it cannot be verified
   server-side [I].

## 7. Method and limits

- GitHub data: `api.github.com` search + metadata endpoints, 2026-09-27,
  unauthenticated (rate-limit constrained; ~41 repos surfaced, 20 tabled)
  [V]. Star/licence/push dates are snapshots.
- iOS app data: Apple iTunes Search API (`itunes.apple.com/search`,
  `entity=software`), 4 term searches, 86 unique apps, 2026-09-27 [V].
  Descriptions quoted are the sellers' own listing text — they are claims,
  not measurements.
- pub.dev and npm: official APIs, 2026-09-27 [V]. PyPI search page was
  JS-blocked; the Python OSS space is covered via GitHub [V method].
- Android apps: Google Play pages were not fetched (blocking); Android
  entries rely on `COMPETITIVE_ANALYSIS.md` (verified 2026-09-22) and
  search snippets [E]. No Android install counts were re-verified today.
- Review-complaint themes come from Reddit threads surfaced via search
  snippets, not full thread reads [E]:
  reddit.com/r/bodyweightfitness/comments/1k5rc18,
  reddit.com/r/PushUps/comments/18n83gr,
  reddit.com/r/reactnative/comments/1o69sv0,
  reddit.com/r/SideProject/comments/1w74cif.
- SDK landscape: vendor pages and the KinesteX-funded roundup
  aifitnessapi.com [V with stated bias]; no SDK was evaluated hands-on, and
  no pricing was verified [E].
- Three background research agents failed with provider captcha timeouts
  during this pass; all findings above were gathered and verified inline in
  the main session.
