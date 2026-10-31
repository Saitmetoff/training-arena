# Camera fix pack — owner device findings, 2026-09-23

Source: the owner's first physical-device session (Redmi 10, MIUI) on the
`TrainingArena-solo-camera.apk` build. Verbatim report:

> "The counting is not processing. It should not be that hard. It should not
> count sideways only, it should count straight head on too. Not only that, I
> found a bug, when I use the camera for the first time it actually opens
> camera but in the next times just nothing appears."

Three separable problems plus one visual feature, four prompts, **strictly
sequential** (all of them touch the same camera paths — one writer per tree):

| Prompt | Problem / feature | Depends on |
| --- | --- | --- |
| `F1_CAMERA_REOPEN_BUG.md` | second and later camera starts show no preview | none |
| `F2_FRONT_VIEW_COUNTING.md` | counting only works from a side view; head-on never counts | F1 |
| `F4_SKELETON_OVERLAY.md` | visible skeleton over the preview, both view modes | F2 |
| `F3_DEVICE_TRACES_AND_THRESHOLDS.md` | prove it on the real phone and tune with evidence | F1, F2, F4 |

F4 comes before F3 on purpose: seeing exactly what the counter sees makes the
F3 device session faster and its traces easier to trust. F4 adds no detector —
the landmarks already exist in memory; only the drawing is new.

Paste the **common preamble** from `prompts/competitive/README.md` with every
prompt below. Keep ponytail mode on. One chat per prompt, in order.

## Known-good context for the executor

- Flutter: `D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat`;
  JDK 17: `D:\Kiro\.tooling\jdk17` (set `JAVA_HOME`; never modify `D:\Kiro`).
- Build a testable APK (non-distributable, debug-signed, installable):
  ```powershell
  $env:JAVA_HOME='D:\Kiro\.tooling\jdk17'
  & 'D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat' build apk --release `
    -PallowDebugSignedRelease=true `
    --dart-define=ARENA_FEATURE_SOLO_MODE=true `
    --dart-define=ARENA_FEATURE_CAMERA_COUNTING=true
  ```
  Output: `app\build\app\outputs\flutter-apk\app-release.apk`.
- The owner's phone is a **Redmi 10**; adb is at
  `D:\toolchains\android-sdk\platform-tools\adb.exe`. USB debugging was **off**
  at the time of the report; the APK was side-loaded by copying it to
  `Download/`. If `adb devices -l` does not list the phone, ask the owner to
  enable Developer options → USB debugging (and MIUI's "Install via USB"),
  then use `adb install -r <apk>` and `adb logcat` for evidence.
- Existing relevant surfaces: `app/lib/camera/` (session, counter, profile,
  bridge, `debug/synthetic_pose.dart`), `app/lib/solo/runtime/solo_controller.dart`
  (`_openCamera`, `_disposeSession`), `app/test/camera/` (counter tests, C05
  fixture replay), `qa/camera/device_validation_checklist.md`,
  `docs/camera/CAMERA_ARCHITECTURE.md`, `docs/camera/CAMERA_QA.md`.

## Rules for all three prompts

- Root cause first: reproduce, capture evidence, then fix where every caller
  routes through. No symptom patches in the solo feature.
- No `Future.delayed`/sleeps as fixes, no threshold weakening to make a test
  pass, no invented device evidence. If a physical step cannot run, say
  BLOCKED and name the missing input.
- Landmark numbers only in any trace: no frame, image or thumbnail may be
  written, logged or exported (privacy inventory, Play Data Safety).
- Every behaviour change lands with a test that fails before and passes
  after; the C05 fixture replay is the regression home for counting changes.
- Update `docs/PROJECT_STATUS.md` with a dated section and record the exact
  device evidence per task.
