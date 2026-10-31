# F1 — camera preview does not reopen after the first use

Status 2026-09-23: **fixed.** Native plugin kept a disposed controller and
skipped the bind; reproduce/fix/evidence in `qa/competitive/f1/REPORT.md`.
The failing-before/passing-after proof is the on-device integration test
`app/integration_test/camera_reopen_test.dart`. Physical confirmation on the
Redmi 10 is pending the owner installing the delivered APK.

Owner report: "when I use the camera for the first time it actually opens
camera but in the next times just nothing appears."

Depends on: nothing. Sequential before F2/F3. Estimate: 4–10 h.

Include the common preamble from `prompts/competitive/README.md` and read
`prompts/camera-fixes/README.md` first.

## Skills to load

- `diagnosing-bugs` — this is a hard lifecycle bug; follow its reproduce →
  instrument → isolate → fix loop.

## Reproduce first (required)

On the owner's Redmi 10 (or any physical Android phone):

1. Open Battle → Solo set → Count with camera. Preview appears (reported).
2. End the set or tap Done/Discard, then start the camera path again.
3. Observe: no preview on the second and later starts.

Also reproduce the same sequence through the battle flow if reachable (the
bug may be shared-layer or solo-specific — that distinction decides the fix
location). Capture `adb logcat` for the whole sequence, filtered to the app
and the camera bridge, and keep the log in `qa/competitive/f1/`.

## Investigate (do not guess)

Trace the full lifecycle: `SoloController._openCamera` →
`CameraSession.platform` → `PlatformCameraBridge` → the native Kotlin camera
plugin → `CameraSessionController.dispose` → `_disposeSession`. Candidate
causes to check and rule in/out with evidence:

- the native camera is released asynchronously and the second `startPreview`
  runs before the release completes (CameraX "in use" / error cue);
- the preview texture id is stale or `null` on the second session, and the UI
  has no failure branch for that (the owner saw "nothing", not an error);
- a singleton/static in the native plugin or bridge survives `dispose()`;
- `CameraSessionController.dispose()` closes streams while native callbacks
  still reference them, so the second session never receives frames;
- the solo controller's second `startPractice()` returns `false` and the
  user-facing message is not shown on that path (check the intro banner).

## Fix

Fix at the layer where the lifecycle is actually broken (native plugin or
shared bridge/session), not in the solo UI. Requirements:

- No sleeps or retry loops as the fix; use the release completion the camera
  stack provides.
- Make the failure visible: if the camera cannot start, the UI must say so
  (reuse the existing solo intro message path).
- Prove re-entry: start → stop → start → stop → start, preview visible on
  every cycle, verified on the physical device.

## Owned paths

`app/lib/camera/` (session, bridge, types), the native Kotlin camera plugin
under `app/android/app/src/main/kotlin/`, `app/test/camera/`,
`qa/competitive/f1/`. Do not change counting thresholds or the solo feature
scope in this task.

## Must not

- Change the rep counter or exercise profiles (that is F2).
- Claim device verification from an emulator; the emulator may not reproduce
  this at all — say so if it does not.
- Weaken the camera release path for the battle flow.

## Acceptance

- Logcat excerpt showing the failure before and the clean re-entry after.
- The exact start/stop/start sequence passes **on the physical Redmi 10**,
  with screen recording or screenshots per cycle in `qa/competitive/f1/`.
- A host test at the shared boundary covering the session re-create path
  (dispose → new session → start) that fails before the fix.
- `flutter analyze` clean, full suite passes.
- If the phone or USB debugging is unavailable, stop at the reproduced local
  analysis and report BLOCKED with the exact missing input.

## Handoff

Standard handoff, including the root cause in one sentence and what a later
regression would have to do to reintroduce it.
