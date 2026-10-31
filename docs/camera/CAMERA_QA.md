# Camera QA, accuracy claims and release gate

Owner: task `03` (camera rep counting) · Consumer: tasks `10` (device QA) and
`11` (release pilot)

This note lists every camera/counter claim that is **not** yet proven, the
known detector limitations, and the physical-device validation that blocks a
camera-counted release. It is the camera-layer counterpart to
`docs/media/FORM_REVIEW.md` (owned by task `02`).

## 1. What is verified today

Evidence below was regenerated on 2026-09-22 at the L02 toolchain (Flutter
3.47.5 / Dart 3.13.4, compileSdk/targetSdk 36) on base commit `1561673` plus
the camera paused-state hardening.

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| Analyzer clean | `flutter analyze lib/camera test/camera` | no issues | `qa/camera/evidence/flutter_analyze_camera.txt` |
| Counter/session/bridge tests | `flutter test test/camera` | 54/54 passed | `qa/camera/evidence/flutter_test_camera.txt` |
| Skeleton overlay mapping and painter | `flutter test test/camera/pose_skeleton_overlay_test.dart` | mapping (identity/cover/contain/mirror/rotation), chains and painted-pixel checks pass | `qa/competitive/f4/` |
| Overlay paint cost (host only) | `$env:OVERLAY_BENCH='1'; flutter test test/camera/overlay_paint_cost_test.dart` | ~15–21 µs/frame on the host JIT (not a device number) | `qa/competitive/f4/overlay_paint_cost_host.txt` |
| Android build | `flutter build apk --debug` | APK built (222 290 969 bytes) | `qa/camera/evidence/apk_build.txt` |
| Platform identifiers and permission | `aapt dump badging` | `app.trainingarena.mobile`, minSdk 24, targetSdk 36, `CAMERA` present, camera features optional | `qa/camera/evidence/apk_manifest_evidence.txt` |
| Model is bundled, not downloaded | APK inspection | `assets/mlkit_pose/pose_landmark_detector_lite_f16_inf.tflite` + tracking graphs inside the APK | same file |

Those checks prove compilation, protocol handling, state-machine behaviour on
synthetic landmarks and that inference is on-device. They do **not** prove
accuracy on real bodies, real lighting or real phones.

## 2. Uncertain accuracy claims (must stay unclaimed until validated)

Each item below is an assumption in the shipped code that physical validation
must confirm or reject. Until then, product copy, store text, marketing and QA
reports must not state them as facts.

1. **Angle thresholds transfer from rendered poses to ML Kit output.** The
   100°/150° (push-up) and 100°/160° (squat) bands are derived from the task
   `02` mannequin key poses; ML Kit joint centres on real bodies are noisier and
   systematically different. Status: unvalidated.
2. **The 2D form guards are enough.** "Body line ≥ 150° at the hip" and "torso
   lean ≤ 60°" are side-view heuristics; they cannot see knee valgus, elbow
   flare, scapular movement, heel rise, camera perspective or a pike filmed at
   an angle. Status: unvalidated; not a form score.
3. **Placement support.** Push-ups are counted from a side-on floor view and,
   since F2, from a head-on (front) view using a shoulder-height signal;
   squats stay side-view only and the counter asks the athlete to turn. The
   view detection and the front-view thresholds are supported by synthetic
   fixtures only; no device trace has validated them. Status: unvalidated on
   device; F3 owns the measured thresholds.
4. **The 0.60 confidence gate maps to trustworthy joints.** ML Kit's
   `inFrameLikelihood` is a probability that the landmark is inside the frame,
   not a calibrated joint-accuracy score. Status: unvalidated.
5. **The 500 ms framing lock and 300 ms loss grace feel right.** They are
   product choices, not measured. Status: unvalidated.
6. **Smoothing vs. bounce rejection.** The raw-band dwell rejects single-frame
   bottom bounces; whether a real touch-and-go rep at competition speed still
   counts in every rep cadence is untested. Status: unvalidated.
7. **Low light is detected by mean luminance < 0.18.** This is a heuristic on
   the Y plane, not an illuminance measurement; it may fire late or not at all.
   Status: unvalidated; copy says "too dark to track you", which is observable
   and therefore safe even if the threshold moves.
8. **Occlusion cheating is fully addressed.** A rep split by tracking loss is
   discarded, but a person who keeps all landmarks visible while using a
   partial range of motion in a way the 2D guards cannot see may still be
   counted. Status: unvalidated; the server remains authoritative and can
   reject events but cannot see the video.
9. **Performance on low-end hardware.** The base model targets ~30 fps on
   Pixel 3-class hardware; the layer analyses at ~15 fps. Thermals, dropped
   frames and battery impact on slow devices are unmeasured. Status:
   unvalidated.
10. **The debug fixture represents nothing.** Synthetic landmarks are a
    deterministic test script. They must never be presented as detector
    accuracy evidence; `CameraSession.debugFixture` is labeled
    `DEMO FIXTURE — NOT COUNTED` and events are non-competitive.
11. **The skeleton overlay is aligned with the body on device.** The overlay
    maps normalised analysis-frame landmarks onto the preview texture assuming
    the preview buffer and the analysis frame share a field of view and crop
    (cover fit, identity rotation, mirrored front camera). Host tests prove the mapping
    function and the painting; no device session has yet confirmed that the
    drawn joints sit on the athlete. Status: unvalidated; the F4 device check
    is part of the F3 session.

## 3. Known detector and platform limitations

- **SDK version**: `com.google.mlkit:pose-detection:18.0.0-beta5` (base model).
  The API is beta and may change; upgrades require re-validation and a counter
  version bump if thresholds move.
  <https://developers.google.com/ml-kit/vision/pose-detection/android>
- **One person only.** ML Kit detects the most prominent person; two people in
  frame (for example a spotter) can steal the landmarks.
- **Z is experimental.** Depth (`z`) is returned but less accurate than x/y and
  has no fixed origin; the counter deliberately uses 2D angles only.
- **Missing landmarks.** When a person is partially outside the frame ML Kit
  assigns off-frame coordinates with low likelihood; the framing gate rejects
  those frames rather than guessing.
- **Input resolution.** Google recommends at least ~480×360 for streaming; the
  analyzer uses 640×480. Smaller/larger devices may behave differently.
- **Pixel 6 / Tensor crash reports.** Multiple reports describe a native JNI
  crash with `pose-detection`/`pose-detection-accurate` `18.0.0-beta5` on
  Pixel 6/6 Pro and some other Tensor/legacy devices at process start:
  <https://github.com/googlesamples/mlkit/issues/982> and
  <https://github.com/googlesamples/mlkit/issues/1039>. The base SDK is used
  here (fewer reports than the accurate SDK) and the detector is created
  lazily, but this is a release-blocking risk until the pilot matrix confirms
  no crash on the target hardware.
- **CameraX `1.4.1` requires `compileSdk` ≥ 34** (the L02 baseline builds with
  36) and runs on minSdk 24. The 16 KB page-size effort relies on the beta5
  native libraries; if the pilot targets 16 KB devices, confirm the packaged
  `.so` alignment during release checks.
- **No camera / camera unavailable.** The app installs on camera-less devices
  and shows actionable copy; it cannot count there.

## 4. Physical-device validation protocol

Nothing below has been executed in this environment (no device attached). It is
the gate for enabling `ARENA_FEATURE_CAMERA_COUNTING=true` in a pilot.

### 4.1 Device matrix (minimum)

| Slot | Requirement | Purpose |
| --- | --- | --- |
| Low-end | Physical device, API 24–26 | minSdk behaviour, detector performance |
| Mid | Physical device, API 30–32 | mainstream path |
| Flagship | Physical device, API 33+ | latest behaviour |
| Tensor checkpoint | Pixel 6/6 Pro class if the pilot targets it | known beta5 crash reports |
| Optional | Front-camera-only or camera-less device | error copy and installability |

### 4.2 Procedure (per device, per exercise)

1. Build and install from the release-candidate commit; record the commit hash
   and `runtimeInfo()` output (detector SDK/model, CameraX, API level, device).
2. Place the phone: floor-level side view for push-ups (best for depth) or
   head-on for push-ups with the head and both hands in frame; waist/chest
   height side-on for squats (squats are not counted head-on). The build uses
   the **front camera**, so prop the phone with its screen toward you instead
   of lying it lens-up on the floor. Follow the on-screen instruction.
3. Three testers of different builds run **5 rounds of 20 controlled reps**
   each while a human observer counts independently.
4. With the skeleton overlay visible, confirm in a side-view session and a
   head-on session that the drawn joints track the athlete and the highlighted
   chain is the one being counted; hide it with the camera-card control and
   confirm the choice holds for the session. Capture a screenshot of each
   placement into `qa/competitive/f4/`.
5. Reproduce the C05 scenario list (`qa/competitive/c05/DEVICE_INPUT_LIST.md`)
   in a build with `ARENA_FEATURE_CAMERA_TRACE=true` (never a release build):
   after each scenario tap Export on the camera card and keep the trace file
   (it carries the exercise and the in-app count), then replay every trace
   through `app/test/camera/fixture_replay.dart`. A replay count that disagrees
   with the in-app count is a bug, never an average.
6. Repeat one round at deliberately fast touch-and-go pace, one round with a
   3-second bottom pause, and one round where the tester steps out of frame for
   ~2 seconds mid-round.
7. Exercise the failure paths:
   - first-run permission allow, deny, deny-again then Settings return;
   - background the app mid-round (home, then lock screen) and return;
   - rotate the device; open another camera app to force `camera_busy`;
   - dim the room until the low-light copy appears, then restore light;
   - cover the lens (no-person copy) and cover one limb (partial-body copy).
8. Confirm the camera is released after leaving the camera screen: no camera
   indicator, no `CameraX` errors in logcat, no ANR.
9. Inspect app data (`adb shell run-as app.trainingarena.mobile ls -R`) and
   confirm there is no image, landmark or video file beyond Flutter's own
   cache and the exported trace files; capture logcat for a full round and
   confirm no frame bytes.

### 4.3 Blocking threshold

The release is **blocked** (ship without camera counting, keep the flag `false`
and the labeled demo) unless all of the following hold:

1. **No false positives**: zero counted reps without a human-observed complete
   down/up across all validation rounds. A single confirmed false rep blocks.
2. **Count agreement**: for at least 90 % of 20-rep rounds the device count is
   within ±2 reps of the human count, and the aggregate absolute error across
   all rounds is ≤ 5 %. Higher disagreement blocks.
3. **Pause transparency**: in 100 % of induced tracking-loss, low-light,
   camera-busy and no-person cases the app shows a reason plus a reframe action
   and does not keep counting.
4. **Lifecycle safety**: 100 % of background/lock/rotate/Settings-return cases
   either resume counting correctly or show a reframing instruction; no crash,
   ANR or stuck black preview.
5. **Privacy**: no frame, thumbnail or landmark artifact is found on disk or in
   network traffic during any round.
6. **Hardware risk**: no crash on the Tensor checkpoint device. If the beta5
   native crash reproduces, pin a different validated ML Kit version or drop
   the affected devices from the pilot before enabling counting.

### 4.4 Evidence to attach

Record device, Android version, build hash, tester, datetime, device count vs
human count, failure-path result and logcat excerpt per scenario in
`qa/camera/device_validation_checklist.md`. Task `10` owns the signed report;
task `11` fails the release gate while the checklist is incomplete.

## 5. Explicit non-oracles

- The task `02` 3D animation and posters are **instructional visual aids and a
  test fixture geometry source**. They are not a detector oracle and cannot
  prove rep accuracy.
- The synthetic fixture in `app/lib/camera/debug/synthetic_pose.dart` proves
  state-machine logic only.
- Host unit tests prove software behaviour under scripted inputs; they are not
  evidence of camera performance.

## 6. Reproduce the current evidence

```powershell
cd D:\TrainingArena\app
flutter analyze lib/camera test/camera
flutter test test/camera
flutter build apk --debug
```

Expected: analyzer clean, 54 tests passed, APK built with the ML Kit pose model
bundled in `assets/mlkit_pose/`.
