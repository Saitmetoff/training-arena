# Interface note 03 — camera rep counting and device bridge

Date: 2026-09-18
Author: task `03` (on-device pose tracking and rep counting)
Status: delivered; no charted contract symbol renamed or removed.
Owned paths: `app/lib/camera/`, the camera bridge files under
`app/android/app/src/main/kotlin/app/trainingarena/mobile/camera/`,
`app/test/camera/`, `docs/camera/`, `qa/camera/`, plus the camera permission
lines in `app/android/app/src/main/AndroidManifest.xml` and the camera
dependencies in `app/android/app/build.gradle` (both granted to task `03` by
`docs/CONTRACT.md` §7).

## Why this note exists

`docs/CONTRACT.md` §7 assigns task `03` the camera layer and allows camera
permission additions to the base manifest. The task prompt asks for a
documented Flutter/native bridge with preferred channel names
`trainingarena/device`, `trainingarena/pose`, `trainingarena/cues`, and for any
uncertain accuracy claim to be listed in `docs/media/FORM_REVIEW.md` or a
camera QA note. `docs/media/FORM_REVIEW.md` is owned by task `02`, so the
accuracy caveats live in `docs/camera/CAMERA_QA.md` and are linked here. No
other task's file was edited except the two camera-owned platform files above.

## What this task delivered

- `app/lib/camera/` — camera session, bridge abstraction, platform and fixture
  bridges, pose math, push-up/squat state machines, synthetic fixtures and a
  preview widget.
- `app/android/app/src/main/kotlin/app/trainingarena/mobile/camera/` —
  `ArenaCameraPlugin` (channels, permission, lifecycle), `ArenaCameraController`
  (CameraX pipeline, texture preview, rotation, release) and `PoseAnalyzer`
  (ML Kit Pose Detection, on-device only).
- `app/android/app/src/main/AndroidManifest.xml` — `CAMERA` permission plus
  optional camera features. No other manifest line changed.
- `app/android/app/build.gradle` — pinned `androidx.camera:camera-core`,
  `camera-camera2`, `camera-lifecycle` `1.4.1` and
  `com.google.mlkit:pose-detection:18.0.0-beta5`.
- `app/test/camera/` — 49 tests (state machine, session, bridge protocol).
- `docs/camera/CAMERA_ARCHITECTURE.md`, `docs/camera/CAMERA_QA.md`,
  `qa/camera/` — protocol, thresholds, limitations and evidence.

## Interfaces other tasks can rely on

1. **Dart-facing `CameraSession`** (`app/lib/camera/camera_session.dart`,
   exported by `app/lib/camera/camera.dart`):
   `exercise`, `permission`, `phase`, `tracking`, `pauseReason`, `instruction`,
   `practiceComplete`, `reps`, `isCompetitive`, `demoLabel`,
   `previewTextureId`, `failure`, `snapshot`, `snapshots`, `repEvents`,
   `requestPermission`, `openAppSettings`, `startPractice`, `beginRound`,
   `endRound`, `resetPractice`, `pause`, `resume`, `setTorch`, `runtimeInfo`,
   `dispose`. Factories: `CameraSession.platform(...)` and
   `CameraSession.debugFixture(...)`.
2. **Permission states**: `unknown`, `granted`, `denied`,
   `permanentlyDenied` (`CameraPermissionStatus`). Permanent denial is derived
   from the persisted "already requested" flag plus
   `shouldShowRequestPermissionRationale`; Settings return is handled through
   `openAppSettings()` and the app-lifecycle observer.
3. **Rep events**: `RepEvent` with `eventId`, `sequence`, `observedAt`,
   `monotonicMicros`, `counterVersion`, `confidence`, `exercise`, `practice`,
   `competitive`. `toArenaRepPayload()` returns exactly
   `event_id`, `sequence`, `observed_at`, `counter_version` for the
   `docs/API.md` `rep` action; the battle feature adds `match_id` and owns the
   request. Events never contain an image, a thumbnail, a buffer or landmarks.
   Practice events have `practice: true, competitive: false`; fixture events
   always have `competitive: false`.
4. **Bridge channels** (fixed by this task; exact payloads in
   `docs/camera/CAMERA_ARCHITECTURE.md`):
   `trainingarena/device` (MethodChannel), `trainingarena/pose` (EventChannel),
   `trainingarena/cues` (EventChannel).
5. **Feature flag**: `ARENA_FEATURE_CAMERA_COUNTING` (default `false`) remains
   the task `07` gate. The camera layer exposes no manual increment and no
   fallback counter: when the flag is off, the battle feature must not mount
   `CameraSession`.

## Counting summary (details in `CAMERA_ARCHITECTURE.md`)

- Full-body framing must be visible and stable for 500 ms before counting.
- Push-up: elbow ≤ 100° enters the bottom band, ≥ 150° completes; 120 ms raw
  band dwell, 700 ms minimum rep, 350 ms debounce, 0.60 tracking confidence,
  and a shoulder-hip-ankle line guard (≥ 150°).
- Squat: knee ≤ 100° enters, ≥ 160° completes; 150 ms dwell, 900 ms minimum
  rep, 400 ms debounce, and a torso-fold guard (≤ 60° lean).
- Tracking loss, low confidence, detector stalls and duplicate/out-of-order
  frames reset the in-progress rep and pause local counting; the shared battle
  clock is never touched by this layer.
- Counter version: `arena-counter/1.0.0`.

## Cross-task requests

- **Task `07` (battle runtime UI)**: consume `CameraSession` (the adapter
  `app/lib/battle/data/camera_session_bridge.dart` already targets this
  interface). Keep non-competitive fixture sessions visibly labeled and never
  submit their events; gate mounting on `ARENA_FEATURE_CAMERA_COUNTING`.
- **Task `10` (device QA)**: run `docs/camera/CAMERA_QA.md` §4 on physical
  devices and attach the signed checklist before any camera-counted release.
- **Baseline owner (task `00`)**: nothing required. The camera permission is
  the only manifest addition and the pubspec `flutter:` section is untouched.

## Open items

1. Physical-device validation has not run (no device attached in this
   environment); see the release-blocking threshold in
   `docs/camera/CAMERA_QA.md` §4–§5.
2. ML Kit `pose-detection` is still beta; its Tensor/Pixel 6 crash reports are
   recorded in `docs/camera/CAMERA_QA.md` §3. The base (fast) model is used.
3. Thresholds are derived from the task `02` demonstration poses and synthetic
   fixtures, not from a human form study. They are explicitly listed as
   unvalidated claims in `docs/camera/CAMERA_QA.md` §2.

## Addendum 2026-09-22 — paused-state hardening (no symbol changes)

A review of the task `07` consumer (`CameraSessionBattleCamera`) found that
background/resume and Settings-return races can ask the session to act while
its phase is `paused`:

- `endRound()` now also ends a round from `paused` when the round was live
  before the pause. The shared battle clock keeps running, so the round can
  expire while counting is paused; the camera stays released and the session
  does not wait for a resume.
- `beginRound()`, `startPractice()` and `resetPractice()` now rebind the
  camera when the session was paused, instead of switching phase against a
  released camera and silently counting nothing.

This is additive behaviour: no symbol was renamed or removed, and the
documented `CameraSession` surface is unchanged. Five tests were added
(`app/test/camera/camera_session_test.dart`; the camera suite is now 54
tests). Host evidence was regenerated at the L02 toolchain
(Flutter 3.47.5 / Dart 3.13.4, targetSdk 36); physical validation remains the
gate for `ARENA_FEATURE_CAMERA_COUNTING=true`.
