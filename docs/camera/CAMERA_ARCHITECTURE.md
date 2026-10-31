# Camera architecture and bridge protocol

Owner: task `03` · Status: implemented and host-verified at the L02 toolchain
(Flutter 3.47.5 / targetSdk 36), physical validation pending (`CAMERA_QA.md`) ·
Counter version: `1.3.0` (WP1 candidate); 2026-09-30 adds
shared preview geometry, with physical alignment still pending.

This document is the reference for the camera/counter layer: how frames are
captured, where counting happens, what crosses the Flutter/native bridge and
what is deliberately impossible. Accuracy limits and validation status live in
`CAMERA_QA.md`.

## 1. Layers and files

| Layer | Files | Responsibility |
| --- | --- | --- |
| Pose model (pure Dart) | `app/lib/camera/pose/pose_types.dart`, `pose_math.dart` | 33 ML Kit landmarks, bounds, angles, smoothing, view-mode detection |
| Counter (pure Dart) | `app/lib/camera/counter/exercise_profile.dart`, `rep_counter.dart` | framing gate, hysteresis, dwell/debounce/confidence, rep state machine |
| Public types | `app/lib/camera/camera_types.dart` | permission/tracking/phase enums, `RepEvent`, `CameraSessionSnapshot`, copy |
| Bridge seam | `app/lib/camera/bridge/camera_bridge.dart` | channel names, typed events, protocol parsing, `CameraBridge` abstraction |
| Platform bridge | `app/lib/camera/bridge/platform_camera_bridge.dart` | MethodChannel/EventChannel implementation |
| Fixture bridge | `app/lib/camera/bridge/debug_fixture.dart`, `app/lib/camera/debug/synthetic_pose.dart` | deterministic, visibly non-competitive replay |
| Session | `app/lib/camera/camera_session.dart` | permission, practice/round flow, event emission, lifecycle |
| Preview widget | `app/lib/camera/camera_preview.dart` | local texture, instruction, rep badge, demo label, skeleton toggle |
| Skeleton overlay | `app/lib/camera/pose_skeleton_overlay.dart` | draws the landmarks the counter consumes over the preview; pure mapping + `CustomPainter`, no detector |
| Debug trace (F3) | `app/lib/camera/trace/` | opt-in recorder and text export of the counter's landmark frames for the replay harness |
| Native | `app/android/app/src/main/kotlin/app/trainingarena/mobile/camera/` | CameraX capture, ML Kit inference, cues, release |
| Registration | `MainActivity.kt` | adds `ArenaCameraPlugin` to the engine |
| Manifest | `AndroidManifest.xml` | `CAMERA` permission, optional camera features |
| Gradle | `app/android/app/build.gradle` | pinned CameraX + ML Kit dependencies |

Data flow, all on device:

```
CameraX ImageAnalysis (640x480, ~15 fps analysed)
  → PoseAnalyzer (ML Kit pose-detection 18.0.0-beta5, STREAM_MODE)
  → trainingarena/pose (numeric landmarks / tracking signals only)
  → CameraSessionController (frame bus, memory only)
  → RepCounter (framing gate + push-up/squat state machine)
  → RepEvent (numbers, ids, timestamps)
  → battle feature (task 07) → arena API `rep` action
```

The same in-memory frame is exposed to the UI through `CameraSession.latestFrame`
and `CameraSession.poseFrames` and drawn by `PoseSkeletonOverlay`; the overlay
runs no detection and adds no second set of numbers.

## 2. Bridge protocol

### 2.1 `trainingarena/device` (MethodChannel, Dart → native)

| Method | Arguments | Result | Errors |
| --- | --- | --- | --- |
| `checkPermission` | — | `unknown` / `granted` / `denied` / `permanently_denied` | — |
| `requestPermission` | — | permission after the OS dialog | `camera_permission` when a request is already pending |
| `openAppSettings` | — | `bool` | — |
| `hasCamera` | — | `bool` (`FEATURE_CAMERA_ANY`) | — |
| `startPreview` | `{exercise: 'pushups'\|'squats', lens_facing: 'front'}` | Flutter texture id (`long`) | `camera_unavailable` |
| `pause` / `resume` / `stop` | — | `bool` | — |
| `setTorch` | `{enabled: bool}` | `bool` | — |
| `disposeSession` | — | `bool`; releases camera, detector, texture | — |
| `runtimeInfo` | — | detector/CameraX versions, API level, device string | — |

### 2.2 `trainingarena/pose` (EventChannel, native → Dart)

Pose frame. ML Kit reports landmark `x`/`y` as **image pixels** in the upright,
post-rotation analysis frame, whose size the event carries as
`frame_width`/`frame_height`; the Dart bridge normalises `x` by the width and
`y` by the height to the documented 0..1 space, and scales `z` by the width
(ML Kit `z` shares the x/y unit and is explicitly experimental). A pose event
without a usable frame size is dropped rather than passed on as pixels.

```json
{"type":"pose","timestamp_us":1234567,"luminance":0.42,
 "frame_width":480,"frame_height":640,
 "landmarks":[{"t":11,"x":245.2,"y":153.6,"z":-38.4,"l":0.93}, "... 33 total"]}
```

Tracking signal (no landmarks):

```json
{"type":"tracking","state":"lost","reason":"noPerson","luminance":0.55,"timestamp_us":...}
{"type":"tracking","state":"lost","reason":"lowLight","luminance":0.10,"timestamp_us":...}
{"type":"tracking","state":"paused","reason":"paused","luminance":1.0,"timestamp_us":...}
```

Preview geometry arrives before its pose frame. Width/height and crop are in
the upright preview buffer. The six affine coefficients map the normalised,
unmirrored analysis point to the normalised, cropped preview; mirroring is
applied once by both the texture and overlay. `texture_quarter_turns` accounts
for the SurfaceProducer backend's rotation handling.

```json
{"type":"preview","timestamp_us":1234567,"width":480,"height":640,
 "crop":[0,0,480,640],"texture_quarter_turns":0,"mirrored":true,
 "analysis_to_preview":[1,0,0,0,1,0]}
```

Malformed, non-finite, out-of-bounds or singular geometry is dropped. No image
crosses this seam and no preview transform is sent to the server.

Detector/camera error:

```json
{"type":"error","code":"detector_failure","message":"...","timestamp_us":...}
```

`timestamp_us` is `SystemClock.elapsedRealtimeNanos() / 1000` — a local
monotonic clock, never wall time. Unknown `type` values and malformed payloads
are ignored by the parser so the native side can add fields without breaking
older clients.

### 2.3 `trainingarena/cues` (EventChannel, native → Dart)

```json
{"code":"cameraReady","timestamp_us":...}
{"code":"cameraError","message":"...","timestamp_us":...}
```

The Dart session maps `cameraError` to a `CameraFailure` with actionable copy
and merges low-light loss from the pose channel into the reframing instruction.

### 2.4 Frames never cross the bridge

Neither direction carries an image, JPEG/PNG bytes, a `ByteBuffer`, a bitmap or
a frame path. `PoseBridgeEvent` types are sealed with numeric fields only; the
protocol tests assert that unknown payload keys (for example a hypothetical
`frame_image`) are dropped by the parser.

## 3. Counting behaviour

### 3.1 Framing gate and view detection

Counting cannot start until the signal chain is present with in-frame
likelihood ≥ 0.55 at each joint, inside the frame, with a centre inside the
middle 76 %, and framing holds continuously for 500 ms (`framingStableMs`).
The counter detects the camera placement from landmark geometry
(`detectCameraViewMode`): shoulder
width over projected torso length separates the views, and the shoulder
z-spread breaks ties inside the hysteresis band (0.35…0.75 ratio). The
detection is hysteretic and an ambiguous or incomplete frame keeps the
previous mode; it never invents one.

- **Side-view push-ups:** selected shoulder–elbow–wrist plus that side's
  shoulder–hip–ankle for the straight-body guard.
- **Side-view squats:** selected hip–knee–ankle. The bottom form guard still
  reads shoulder–hip tilt to reject torso collapse.
- **Front-view push-ups:** both shoulders, wrists and hips. The shoulder line
  remains the size proxy (minimum 0.12); a missing hand never locks framing.
- **Front-view squats** are refused with `wrongView`: the knee bends towards
  the lens, so the side-view knee signal is degenerate head-on. The copy asks
  the athlete to turn side-on.

Old → new: the side gate required all 13 head-to-ankle landmarks and rejected
body span > 0.98; the front gate also required the nose and rejected shoulder
span > 0.75. The gate now requires only the view's signal chain. Visible
in-frame body span below 0.35 (side) or shoulder span below 0.12 (front) still
reports `tooFar`; off-centre, confidence and stability checks remain. Side body span
> 0.98 and front shoulder span > 0.75 now show a move-back cue while a
readable chain stays locked and counting continues. Head, feet and ears alone
cannot block a rep. `tooClose` can therefore accompany `tracking`, without
meaning the counter is paused. The C05 replay variants in
`app/test/camera/fixture_replay_test.dart` pin partial-frame side push-ups,
squats and front push-ups, plus half depth, bounce, collapse, low confidence
and missing-joint rejection; `rep_counter_test.dart` pins loss, stall, duration,
gap and side-view behaviour.

Reasons are surfaced as `TrackingPauseReason`: `noPerson`, `lowLight`,
`partialBody`, `tooClose`, `heelsLifted`, `tooFar`, `offCenter`,
`lowConfidence`, `detectorStalled`, `wrongView`, `cameraUnavailable`,
`cameraBusy`, `permissionBlocked`, `paused`. Each reason maps to explicit
player copy, and the push-up copy describes both placements (side view stays
best for depth; head-on is supported for push-ups).

`heelsLifted` is a squat-only coaching cue (2026-09-27, ported from the
Squat-Analysis-Model reference, MIT): the heel-to-toe inclination of the
counting side (`pose_math.dart heelToToeAngleDegrees`, folded to 0–90° so
either facing measures the same) is re-baselined on every standing frame
(knee angle ≥ 160°) and the cue fires when it exceeds the baseline by
`heelsLiftedDeviationDeg` (12°, candidate until F3 replays real traces; the
reference gates at +3° on pixel-space landmarks). It never blocks or rejects
a rep — like `tooClose`, it can accompany `tracking` — and it is disabled
when either foot landmark drops below the framing likelihood.

### 3.2 Thresholds

All counter thresholds in `exercise_profile.dart` are **candidate, tuned on SYNTHETIC data only**. No real-device validation has been performed. WP1 is BLOCKED: protected legacy assertions conflict with full-chain side selection / named shallow outcomes, and noise seed 4 has an unreported descent. Camera counting stays opt-in with the release hold unchanged.

| Rule | Push-ups | Squats |
| --- | --- | --- |
| Primary angle (side view) | elbow (shoulder–elbow–wrist) | knee (hip–knee–ankle) |
| Bottom band entry | ≤ 105° | ≤ 105° |
| Rep completes at | ≥ 145° | ≥ 155° |
| Raw-band dwell | 60 ms | 60 ms |
| Minimum bottom-entry-to-lockout duration (not whole rep) | 250 ms | 250 ms |
| Debounce between reps | 350 ms | 400 ms |
| Tracking confidence | 0.60 mean likelihood | 0.60 |
| Framing confidence | 0.55 | 0.55 |
| Form guard at the bottom | hip line (shoulder–hip–ankle) ≥ 150° | torso lean ≤ 60° |
| Loss grace before reset | 300 ms | 300 ms |
| Stall gap reset | 600 ms | 600 ms |

Front-view (head-on) push-up rows. Every value is a **candidate**: synthetic
fixtures support them, and F3 replays real device traces before any of them is
claimed as measured.

| Rule | Front-view push-ups |
| --- | --- |
| Primary signal | shoulder height above the hands / shoulder width |
| Bottom band entry | ≤ 0.60 |
| Rep completes at | ≥ 0.90 |
| Framing size proxy | shoulder width ≥ 0.12; > 0.75 prompts move-back cue |
| Form guard at the bottom | projected shoulder-to-hip offset within 0.30 shoulder widths of the top reference (recorded once per framing episode) |

Jitter protection: the primary signal (angle or front ratio) is exponentially
smoothed with `alpha = 1 - exp(-dt / tau)` (`tau = 60 ms`) for band transitions, while the dwell is measured on the
raw signal so a bounce that barely touches the bottom cannot bank a rep. A rep
is rejected with a diagnostic reason (`dwellTooShort`, `repTooFast`,
`debounce`, `bodyNotStraight`, `torsoCollapsed`, `lowConfidence`, `lockoutMissed`, `notDeepEnough`).

Additional candidate thresholds: lockout timeout 5000 ms; near-bottom band 25°; re-descent requires rising above enter+20° then crossing enter again; front near-bottom band 0.15; side-switch confidence margin 0.12 (a visibility failure also permits switching); centre margin 0.12; low-light luminance 0.18. Front/side shoulder ratios are 0.75/0.35, with depth tie-break spreads 0.06/0.12. These values remain in the profile. Raw dwell begins when the smoothed bottom phase starts and samples the raw bottom band.

`PoseFrame.aspectRatio` is upright width/height. Geometry uses `(x * aspectRatio, y)` for isotropic angles, distances, torso lean and view detection; per-axis 0..1 framing bounds remain unchanged. Side confidence uses the full visibility signal chain. Trace exports optionally append aspect to the frame header and depth to landmarks, preserving old fixture defaults. Replay diagnostics and physical-phone instructions are in `qa/camera/TRACE_RUNBOOK.md`.

### 3.3 Tracking loss, occlusion and stalls

- After 300 ms without a valid frame the counter resets the in-progress rep,
  drops the framing lock and reports the reason. A rep split by an occlusion
  never counts, even if the athlete resumes at the completion angle.
- A frame gap larger than 600 ms is a detector stall: the in-progress rep is
  discarded, the stall is reported once, and the athlete must reframe for 500 ms.
- Duplicate or out-of-order timestamps are ignored and reported as
  `duplicateFrame`; the rep count cannot increment twice for one frame.
- Local counting pauses while tracking is lost. The shared battle clock is not
  owned or modified by this layer, so it keeps running by design.

### 3.4 Practice and round semantics

- `startPractice()` requests permission if needed, starts the local preview and
  counts exactly one unscored rep. On completion `practiceComplete` becomes
  true, counting is disabled so no extra reps bank before the round, and the
  event carries `practice: true, competitive: false`.
- `beginRound()` fails until `practiceComplete` is true. It resets the round
  counter and sequences competitive events from 1.
- `endRound()` freezes the count and stops consuming frames. It also works
  while the local counter is paused (player pause or app background), because
  the shared battle clock keeps running; the camera stays released and the
  session ends without waiting for a resume.
- `beginRound()`, `startPractice()` and `resetPractice()` rebind the camera
  when the session was paused, so a command never runs against a released
  camera after a background/Settings return.
- `resetPractice()` throws a `StateError` during a live round and cannot touch
  the match score; practice sequences are separate from round sequences.
- There is no manual increment API anywhere in the layer, and no configuration
  flag can enable one.

### 3.5 Rep events and the server

Each counted rep creates one immutable `RepEvent`; the battle feature maps it to
the `docs/API.md` `rep` action with `match_id` added. `event_id` is a UUID v4,
`sequence` is monotonic per phase, `observed_at` is the wall-clock observation
time and `counter_version` is `1.3.0`. Retries reuse the same
event id, so the server can deduplicate. The server remains authoritative and
may reject events.

### 3.6 Skeleton overlay (F4)

`PoseSkeletonOverlay` draws the landmarks the counter already consumed. It runs
no detector and produces no numbers of its own.

- **Seam.** `CameraSession.latestFrame` returns the exact frame the counter
  processed (nulled on `dispose`), and `CameraSession.poseFrames` emits those
  frames in arrival order as a broadcast stream: no copies, no buffering, no
  replay, no image. The snapshot carries the counter's own `viewMode` and
  `countingSide` so the overlay highlights what the counter is measuring
  instead of re-detecting it.
- **Drawing.** The standard chains (arms, legs, shoulder/hip lines and the
  nose-to-shoulder lines) are dim; the counting chain is lime and thicker, with
  a ring on the primary joint, so the emphasis survives grayscale. Side view
  emphasises the selected shoulder–elbow–wrist (push-ups) or hip–knee–ankle
  (squats) chain; front view emphasises the shoulder line, the hand line and
  the torso the front signal uses. Missing or below-gate (< 0.5 likelihood)
  landmarks are skipped, so a partial body paints safely.
- **Mapping, old → new (2026-09-30).** Production formerly assumed a
  720x1280 texture, identity rotation and a front-camera mirror. CameraX now
  binds Preview and ImageAnalysis in one `UseCaseGroup` with a shared 3:4
  `ViewPort`. Native code combines the analysis/preview sensor transforms,
  actual crop, rotation and mirror metadata into `CameraPreviewGeometry`.
  `CameraPreview` and `poseOverlayPoint` use that same geometry and fit. The
  SurfaceProducer lifecycle releases/rebinds the surface, and orientation
  changes rebind the shared viewport. Production waits for metadata instead
  of drawing against guessed dimensions; 720x1280 remains only a fixture
  fallback. Bridge, preview and skeleton-overlay tests pin crop, rotation,
  mirroring, invalid metadata and lifecycle visibility. Physical alignment
  remains unverified on Redmi 10 and the second Android phone.
- **Visibility.** On by default during practice/ready/live with a live texture,
  with a one-tap hide control on the camera card; the choice lasts for the
  camera session. Tracking loss, a paused session, no texture or no landmarks
  draw nothing and leave the existing guidance card in place.
- **Cost.** The painter reuses its `Paint` objects, repaints through a
  `ValueNotifier` (no widget rebuilds per frame) and the detector already
  throttles to ~15 analysed frames per second. Host paint cost is bounded by
  `test/camera/overlay_paint_cost_test.dart` (`OVERLAY_BENCH=1`); the device
  frame-rate impact is an F3 measurement.

No counter threshold or false-positive protection changed in this beta slice.
The existing C05 partial-frame and rejection suites remain the counting gate
evidence; synthetic geometry cannot establish physical camera accuracy.

### 3.7 Debug landmark trace (F3)

`ARENA_FEATURE_CAMERA_TRACE` (default `false`) arms a recorder on the camera
card that consumes `CameraSession.poseFrames` — the exact frames the counter
processes — and keeps the last three minutes of them in memory. Nothing is
written until the owner taps Export on the card, which writes
`<documents>/camera-traces/trace-<exercise>-<timestamp>.txt` in the C05 text
format (`pose_trace_format.dart`, shared with the test harness so the two can
never drift) and opens the OS share sheet. Delete clears the exported files
and the in-memory window.

Privacy: numbers only, no frame, image, device identifier or account value;
the file is app-private until the owner shares it themselves. The flag is
never enabled in a release build: the release-hold check
(`tools/release/check_release_flags.mjs`) fails if it is `true` or unpinned,
and the release workflow pins it `false`. The trace text is also the input the
replay harness (`app/test/camera/fixture_replay.dart`) commits as fixtures in
`app/test/camera/fixtures/`.

## 4. Privacy and lifecycle

- **No frames leave the device.** ML Kit runs in-process on the preview
  upstream; the bridge protocol and the `RepEvent` do not contain pixels or
  landmarks. Nothing is written to storage: no thumbnails, no landmark files,
  no logs of coordinates. The only retained values are counters, timings and the
  latest landmark frame for the active session, dropped on `dispose`. The
  skeleton overlay draws that frame and forgets it: no screenshot, no export.
- **Permission in context.** `requestPermission()` is called when the player
  starts practice; copy states that processing is private and on-device. Denial
  keeps the phase at `permissionRequired` with copy that explains what the
  camera is for. Permanent denial (derived from `shouldShowRationale` after a
  stored request flag) points at Settings, and returning from Settings
  re-checks the permission and resumes practice automatically.
- **Lifecycle.** The session observes app lifecycle: backgrounding pauses the
  session and releases the camera (which also covers screen lock); returning
  resumes only when the session had been active. `CameraX` rotation is tracked
  with `OrientationEventListener` and applied to both use cases. Route exit
  calls `dispose()`, which unbinds the camera, closes the detector, releases
  the texture and shuts the analyser executor. `dispose()` is idempotent.
- **Errors.** Low light, camera busy/unavailable, missing camera and detector
  failure each produce actionable copy; a device with no camera can still
  install because the camera features are `required="false"`.

## 5. Debug fixture path

`CameraSession.debugFixture(exercise)` replays deterministic synthetic
landmarks through the same counter. It never touches native channels, exposes
`isCompetitive: false`, carries the visible label
`DEMO FIXTURE — NOT COUNTED`, and all of its events are `competitive: false`.
`CameraPreview` renders the label over the synthetic placeholder. Fixture
sessions report no preview texture, so the skeleton overlay stays hidden there
(the overlay is tested against fixture frames directly). The fixture
is for tests, UI development and labeled offline demos; it makes no accuracy
claim and cannot build a match result (`snapshot.canProduceMatchResult` is
false).

## 6. Versions

| Component | Version | Notes |
| --- | --- | --- |
| `com.google.mlkit:pose-detection` | `18.0.0-beta5` | base (fast) model, 33 landmarks, bundled ~10 MB, still beta |
| `androidx.camera:camera-core/-camera2/-lifecycle` | `1.4.1` | requires `compileSdk` ≥ 34; the L02 baseline builds with 36 |
| Flutter / Dart | 3.47.5 / 3.13.4 | pinned by the L02 toolchain migration (`docs/release/CONFIGURATION.md`) |
| minSdk / targetSdk | 24 / 36 | minSdk 24 is the platform contract; targetSdk 36 is the L02 Play 2026 requirement |
| Counter version | `1.3.0` | sent as `counter_version`; candidate WP1 engine, device evidence blocked |

## 7. Verification commands

```powershell
cd D:\TrainingArena\app
flutter analyze lib/camera test/camera
flutter test test/camera
flutter build apk --debug
aapt dump badging build\app\outputs\flutter-apk\app-debug.apk
```

Evidence copies are in `qa/camera/evidence/`. Physical-device validation and
the release-blocking threshold are in `CAMERA_QA.md`.
