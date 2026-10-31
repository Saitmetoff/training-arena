# F1 — camera preview does not reopen after the first use: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Owner report reproduced on the emulator (`emulated` back camera).

## Root cause

`ArenaCameraPlugin` (native Android) disposed the camera controller on
`disposeSession` but **kept the reference**. `ArenaCameraController.dispose()`
is permanent (`disposed = true`, texture released, executor shut down), and
the next `startPreview` reused that dead instance:

- `start()` created a **new** surface texture and returned its id to Dart, so
  the Flutter side rendered a `Texture` widget that never received a frame;
- `bindAll()` early-returned on `disposed`, so the camera never bound and the
  analyzer never ran;
- no error and no cue was emitted — exactly the owner's "nothing appears",
  with no landmarks and therefore no counting.

The Dart side was correct: every session creates its own
`PlatformCameraBridge` and calls `disposeSession` once.

## Fix (native, shared by solo and battle flows)

- `ArenaCameraPlugin.kt`: `disposeSession` now disposes **and drops** the
  reference; a new `ensureController()` is used by both the activity-attach
  path and `startPreview`, so any start path builds a fresh controller.
- `ArenaCameraController.kt`: `start()` now fails loudly
  (`check(!disposed)`) instead of returning a texture id that would stay
  black forever — a future regression surfaces as an error, not a silent
  preview.

## Evidence

Regression test: `app/integration_test/camera_reopen_test.dart` — drives the
real `PlatformCameraBridge` through **three** start/dispose cycles; each cycle
must produce a `cameraReady` cue **and** at least one pose/tracking event. A
texture id alone is explicitly not success.

| Run | Result | Log |
| --- | --- | --- |
| Before the fix | **FAIL** at the second start: `second start: no cameraReady cue — the camera never bound (cues: [])` | `qa/competitive/f1/integration_before_fix.txt` |
| After the fix | **PASS**: 3/3 cycles ready with events | `qa/competitive/f1/integration_after_fix.txt` |

Host contract lock: `app/test/camera/camera_session_test.dart` — a recreated
session starts a fresh preview and disposes its own bridge (the native
regression itself is on-device only; this test protects the Dart side).

## Verification

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` (full) | **533/533 passed** (532 before, +1 contract test) |
| `flutter test integration_test/camera_reopen_test.dart -d emulator-5554` | 1/1 passed (three cycles) |

## Scope and honesty notes

- Evidence is **emulator** (emulated back camera), not the Redmi. The bug is a
  lifecycle defect independent of camera hardware, and the test fails before
  the fix and passes after on the same emulator. Physical confirmation is the
  owner installing the fixed APK.
- Fixed build for the phone: `TrainingArena-solo-camera-fixed.apk`
  (90,861,039 bytes, SHA-256 `16dc9463…b88e2b728`, debug-signed,
  non-distributable), copied to the phone's `Download/`.
- The same fix covers the battle-flow camera restart, which shares the plugin.
- Re-running the integration test resets the camera permission (the test
  installer replaces the package): grant it right before or during the run, or
  the test fails fast with the exact `pm grant` command.

## Acceptance status

| Criterion | Status |
| --- | --- |
| Logcat/instrumented repro before and clean re-entry after | PASS (integration test + logs in `qa/competitive/f1/`) |
| Start/stop/start sequence on the physical Redmi 10 | **PENDING OWNER** — fixed APK delivered |
| Host test at the shared boundary | PASS (contract lock; native regression covered on-device) |
| Analyzer + full suite | PASS |
