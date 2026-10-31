# F4 — skeleton overlay on the camera preview: verification record

Date: 2026-09-24 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Start commit: `6c654b3` (F2) · Branch: `codex/training-arena`.

Owner request: "Can you also add skeleton tracking on the each sideways and
front head on camera too? you can just install and configure it from github so
if yes then add another prompt."

No dependency was added. The landmarks were already in memory; F4 only draws
what the counter consumes.

## Verdict

| Area | Result |
| --- | --- |
| Landmark seam (`latestFrame`, `poseFrames`, snapshot view mode/side) | PASS — same frame references, no copies, no replay |
| Pure mapping function (identity, cover, letterbox, mirror, rotation) | PASS — 7 unit cases |
| `PoseSkeletonOverlay` paints a synthetic session frame | PASS — widget + painted-pixel tests |
| Empty/partial landmark frames paint safely | PASS |
| View-mode aware highlight, grayscale-readable (dim vs. thick) | PASS — chain tests |
| Hide control, visible by default, persists for the session | PASS — widget tests |
| Side-view counter suite unchanged, no counting change | PASS — `rep_counter_test.dart` untouched |
| `flutter analyze` and the full suite | PASS — clean, **579/579 + 2 skipped** |
| No new dependency in `pubspec.yaml` or Gradle | PASS — no diff |
| Overlay cost | Host bound measured (~15–21 µs/frame); device frame rate **BLOCKED** |
| Physical Redmi 10: side + head-on alignment, screenshots | **BLOCKED** — no phone attached |

Physical-device evidence is **not** claimed. `adb devices -l` lists only two
emulators (`emulator-5554`, `emulator-5556`); the owner's Redmi 10 was not
connected (USB debugging was off in the F1/F2 sessions). The missing input is
the phone, or the owner running the delivered APK and capturing the two
screenshots.

## 1. What changed

### 1.1 The landmark seam (`camera_session.dart`, `camera_types.dart`)

- `CameraSession.latestFrame` returns the exact `PoseFrame` the counter just
  processed, or `null` before the first counted frame; it is nulled on
  `dispose`.
- `CameraSession.poseFrames` emits those same frame references in arrival order
  on a broadcast stream: no buffering, no replay, no copy, no image, no log.
  Frames are exposed only while the counter is consuming them (practice, ready,
  live); an idle session exposes nothing.
- `CameraSessionSnapshot` gained `viewMode` and `countingSide`, copied from the
  counter's own result so the overlay highlights what the counter is measuring
  instead of re-detecting anything. `RepCounterResult` gained the read-only
  `side` field. No counting logic, threshold or view-detection rule changed.

### 1.2 The overlay (`pose_skeleton_overlay.dart`, new)

- `poseOverlayPoint` — pure mapping function (see §2).
- `poseSkeletonSegments` — the standard chains: both arms, both legs, shoulder
  and hip lines, and the nose-to-shoulder lines.
- `poseCountingChain` — reuses `ExerciseCounterProfile.primaryChain` and
  `supportsFrontView` so the emphasis matches the counter: the selected
  shoulder–elbow–wrist (push-ups) or hip–knee–ankle (squats) chain with the
  elbow/knee as the ringed primary joint in a side view; the shoulder line,
  hand line and torso in a front view. Before a side-view signal exists, or in
  a front-view squat the counter refuses, nothing is emphasised.
- `PoseSkeletonPainter` — dim skeleton (quiet, 45 % alpha, 2 px) under the lime
  active chain (4 px) with lime joint dots and a soft-white ring on the primary
  joint, so the active chain reads in grayscale too. Missing landmarks and
  landmarks below 0.5 likelihood (the counter's framing gate) are skipped.
  `Paint` objects are created once and reused; repaints are driven by a
  `ValueNotifier` so incoming frames do not rebuild the widget tree.
- `PoseSkeletonOverlay` — subscribes to `poseFrames`; takes `viewMode`/`side`
  from the snapshot; supports `quarterTurns` and `mirrored` for the mapping.

### 1.3 The camera card (`camera_preview.dart`)

- `CameraPreview` is now stateful and always builds the overlay over the
  texture. It is active only with a live texture, during practice/ready/live,
  and while tracking is `framing` or `tracking`; tracking loss, a paused
  session, no texture or no landmarks draw nothing and leave the existing
  instruction card in place.
- A one-tap hide control (top-left; below the demo badge when one exists) shows
  and hides the skeleton. Visible by default, state kept in the card's `State`,
  which survives practice → counting inside the camera flow.
- Colours come only from `ArenaColors` (`quiet`, `lime`, `softWhite`,
  `charcoal`).

### 1.4 Privacy

Landmarks stay in memory: the seam exposes the counter's own frame reference,
the painter draws and forgets, and nothing is written, logged or exported. No
screenshot or recording code exists. `dispose()` clears `latestFrame` and
closes the frame stream.

## 2. Mapping rules

`poseOverlayPoint(normalised, boxSize, frameSize, fit, quarterTurns, mirrored)`:

| Input | Rule |
| --- | --- |
| Frame | Upright analysis frame, `x`/`y` in 0..1, `y` down, matching `PoseFrame` |
| `frameSize` | The size the frame content is displayed at after rotation; production passes `posePreviewFrameSize` (720x1280, the `FittedBox` child) |
| Rotation | Clockwise quarter turns, `RotatedBox` semantics: 90° `(x,y) → (1-y, x)`, 180° `(1-x, 1-y)`, 270° `(y, 1-x)` |
| Mirror | Applied after rotation, in display space: `x → 1-x` |
| Fit | `applyBoxFit` semantics with both rects centred: cover crops the overflowing axis, contain letterboxes; the point maps through the source rect into the destination rect |
| Production | Identity: back camera, texture already upright (`targetRotation` tracks the device), `BoxFit.cover` as the preview |

Unit cases cover 0 / 0.5 / 1, cover crop (including a point cropped outside the
box), letterbox bars, each quarter turn, mirror, and mirror-after-rotation.

## 3. Evidence per acceptance criterion

| Criterion | Evidence |
| --- | --- |
| Pure mapping unit-tested | `app/test/camera/pose_skeleton_overlay_test.dart` — 7 mapping cases |
| Widget test paints from a synthetic session frame | `paints a synthetic session frame without errors`; `the selected chain is painted in lime` renders the overlay to an image and requires lime pixels |
| Empty/partial frames paint safely | `an empty landmark frame paints safely`, `a partial head-on frame paints safely` (the front fixture omits knees/ankles) |
| Landmark seam carries exactly the counter's frames | `the landmark seam exposes exactly the frames the counter consumes` — reference identity, empty before practice |
| View mode / side come from the counter | `the snapshot carries the counter view mode and counting side`, `a head-on session reports the front view mode and no counting side` |
| Overlay visible by default and hideable, choice persists | `the skeleton overlays the texture and the hide control toggles it` (toggle off/on, then a completed practice rep keeps the choice) |
| No skeleton when tracking is lost / paused / no texture | `a paused session draws no skeleton`; the fixture test asserts no overlay without a texture |
| Side-view counter suite unchanged | `git diff` touches no `rep_counter_test.dart`; the full suite passes |
| No new dependency | `pubspec.yaml`, `android/app/build.gradle` and `android/build.gradle` are unchanged in `git diff` |
| Privacy | no write/log/export path added; `dispose` clears the latest frame |

## 4. Performance

- Detector: unchanged, still throttled to one inference per 66 ms (~15 fps), so
  the overlay repaints at most at that rate.
- Host paint cost: `test/camera/overlay_paint_cost_test.dart`
  (`OVERLAY_BENCH=1`) paints 5000 frames: **15.4 µs/frame** on the first run
  and **21.0 µs/frame** on the recorded run (host JIT, 360x360 box) —
  `qa/competitive/f4/overlay_paint_cost_host.txt`. This is a host CPU bound,
  not a device frame-rate claim.
- No per-frame allocation storm: the four `Paint` objects are painter fields,
  lines are drawn with `drawLine` (no per-segment `Path`), and frames repaint
  through the notifier instead of rebuilding widgets.
- Device frame rate with the skeleton on/off: **BLOCKED** (no phone). If F3
  measures a cost, the throttle belongs in the overlay subscription
  (`PoseSkeletonOverlay`), never in the counter or the detector.

## 5. Commands and results

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found (`qa/competitive/f4/analyze.txt`) |
| `flutter test test/camera` | **109 passed, 2 skipped** (`qa/competitive/f4/test_camera.txt`) |
| `flutter test` | **579 passed, 2 skipped** (555 + 24 new; 1 new skip is the bench) |
| `$env:OVERLAY_BENCH='1'; flutter test test/camera/overlay_paint_cost_test.dart` | passed, 21.0 µs/frame printed |
| `flutter build apk --release -PallowDebugSignedRelease=true --dart-define=ARENA_FEATURE_SOLO_MODE=true --dart-define=ARENA_FEATURE_CAMERA_COUNTING=true` | built, 90,894,095 bytes, SHA-256 `D033A6BD134D6187F2805AD796F345C60B4DBC812F03554BBE51CF64AEE10AFF` |
| `adb devices -l` | emulator-5554, emulator-5556 only — no Redmi 10 |

Delivery: non-distributable, debug-signed test build
`TrainingArena-solo-camera-skeleton.apk` (copy of the built artifact) for the
owner's F3 session. No device install or copy was performed here.

## 6. What F3 must verify on the phone

1. Skeleton visible and correctly aligned in a **side-view** session and a
   **head-on** session; screenshots into `qa/competitive/f4/` (the preview and
   analysis use cases may crop differently; this is the unverified assumption).
2. The highlighted chain is the one being counted, and the dim/active contrast
   reads in grayscale.
3. Frame-rate impact with the skeleton on and off; throttle the painter only if
   it costs frames.
4. The hide control persists across practice → counting and a pause/resume.
5. Whether ML Kit's landmark noise makes the drawn joints jitter enough to
   warrant smoothing the overlay (the counter smooths its signal; the overlay
   currently draws raw points).

## 7. Scope, honesty and handoff

- No pose-detection dependency was added; no GitHub package was installed. The
  overlay has no detector and cannot disagree with the counter about landmarks:
  it draws the frame the counter consumed and the chain the counter selected.
- Counting behaviour, thresholds and view detection are untouched.
- Unrelated dirty files (`qa/integration/evidence/t10r2/*`) were preserved and
  are not part of this change.
- The physical-device acceptance items (alignment, screenshots, device frame
  rate) are **BLOCKED** on the phone; nothing device-specific is claimed.
