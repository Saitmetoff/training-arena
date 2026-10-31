# F3 — real-device traces and honest thresholds: verification record

Date: 2026-09-24 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Start commit: `017f084` (F4) · Branch: `codex/training-arena`.

Owner direction: run the device session on the Redmi 10 after the work is
finished if a phone is available.

## Verdict

| Area | Result |
| --- | --- |
| `ARENA_FEATURE_CAMERA_TRACE` (default false) registered in `ArenaConfig` | PASS |
| Trace dump in the exact C05 text format, numbers only, in memory until export | PASS — 11 unit tests |
| Visible in-app label, export (share sheet) and delete control | PASS — widget test |
| Release hold: check + test + workflow pin `false` | PASS — 7/7 release-tool tests |
| Trace file never in a release artifact | PASS by construction — written at runtime to app-private storage, never bundled; flag pinned false |
| Device scenarios (20 clean side/head-on, shallow, shake, occlusion, sag, walk-in) | **BLOCKED — no phone attached** |
| Traces committed + replay tests, in-app vs replay agreement | **BLOCKED** — depends on the session |
| Threshold table updated with measured values | **BLOCKED** — nothing measured; table unchanged |
| Checklist rows executed | **BLOCKED** — no row executed, nothing signed |
| R1 gate | **OPEN** — needs the owner's session and human review |

## 1. What changed

### 1.1 Trace recorder (`app/lib/camera/trace/`)

- `pose_trace_format.dart` owns the C05 text format. The test serializer
  (`app/test/camera/fixture_replay.dart`) now delegates to it, so committed
  fixtures and device traces cannot drift apart.
- `pose_trace_recorder.dart` keeps the last three minutes of frames in an
  in-memory ring (`add` drops anything older than the window), serializes them
  on demand, writes `trace-<exercise>-<yyyyMMdd-HHmmss>.txt` into an
  app-private `camera-traces/` directory (`save`), lists them
  (`storedFiles`) and deletes them (`deleteStored`). The header carries
  `# exercise:` and `# in_app_reps:` comments; no device identifier, account
  value or image is representable.
- `ARENA_FEATURE_CAMERA_TRACE` (default `false`) in `ArenaConfig` arms the
  recorder on the camera card. Only the user's Export tap writes a file.

### 1.2 Camera-card controls (`camera_preview.dart`)

When the flag is on, a `TRACE ON · <frames>` label appears with an export
button (writes the file, opens the share sheet) and a delete button (removes
exported files and clears the window). Without the flag nothing is created,
subscribed or shown. The share call is fire-and-forget: a missing share target
cannot lose the file or block the card.

### 1.3 Dependency

`path_provider` was promoted from a transitive to a direct dependency
(`^2.1.5`) to locate the app-private documents directory. It is already in
`pubspec.lock` and its Android plugin is already registered in
`GeneratedPluginRegistrant.java` (pulled in by `share_plus`), so no new package
enters the APK. One-line justification: the trace file must live in the app's
private documents directory and there is no Flutter API for that path without
this plugin.

### 1.4 Release hold

`tools/release/check_release_flags.mjs` now fails when
`ARENA_FEATURE_CAMERA_TRACE` is `true` or unpinned, and
`.github/workflows/release-checks.yml` pins it `false` in the manual
release-candidate build. Regression: `check_release_flags.test.mjs`
(7/7 pass). The trace file itself is written at runtime under the app's private
documents directory and is never part of a build artifact.

## 2. Trace inventory

**Empty.** No physical device was attached during this run; `adb devices -l`
listed `emulator-5554` and `emulator-5556` only. The emulators cannot produce
real pose traces (no person in the virtual camera scene).

Deliverables for the owner's session, both with
`ARENA_FEATURE_CAMERA_TRACE=true`, `ARENA_FEATURE_CAMERA_COUNTING=true` and
`ARENA_FEATURE_SOLO_MODE=true`:

| Build | Purpose | Size | SHA-256 |
| --- | --- | --- | --- |
| `TrainingArena-f3-trace-debug.apk` | debuggable: install and pull traces with `adb run-as` | 222 378 595 B | `A7F690AC2C61C685FB45253F727448E99EE58499A030F3BBC73FB68C358869A6` |
| `TrainingArena-f3-trace.apk` | debug-signed release build; traces leave via the share sheet | 91 140 003 B | `8031DB1E0106A7D2C94F9B99F97CCC36EE6F399523EC02CA800A2213CC97B58A` |

Steps and the scenario table are in `qa/competitive/f3/RUNSHEET.md`.

## 3. Per-scenario results

No scenario was executed on a phone, so no count, rejection or rejection
reason is reported. Reporting invented numbers is exactly what this task
forbids.

| # | Scenario | Counted | Rejected | Remaining to validate |
| --- | --- | --- | --- | --- |
| 1 | 20 clean side push-ups | not run | not run | `enterBottomAngle`, `exitBottomAngle`, dwell, duration, gap |
| 2 | 20 clean head-on push-ups | not run | not run | front signal bands, shoulder span, sag tolerance |
| 3 | 5 shallow reps | not run | not run | that half-depth never counts on a real body |
| 4 | shake, body still | not run | not run | debounce/dwell against real jitter |
| 5 | occlusion mid-rep | not run | not run | `trackingLossGraceMs` against a real occlusion |
| 6 | one sagging rep | not run | not run | `frontMaximumTorsoDrift`, hip-line guard |
| 7 | walk-in / walk-out | not run | not run | framing ranges and lock timing |
| 8–11 | squats set and head-on refusal | not run | not run | `minimumBodySpan`, lean guard, `wrongView` timing |

## 4. Threshold deltas

**None.** No trace was recorded, so no value is justified to change and no
value is claimed as measured. `qa/competitive/c05/DEVICE_INPUT_LIST.md` now
states this explicitly; every threshold keeps its candidate status.

## 5. Commands and results

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | **592 passed, 2 skipped** (579 before; +13: 11 recorder/format, 2 camera-card) |
| `flutter test test/camera` | passed with the new trace tests |
| `node tools/release/check_release_flags.mjs` | exit 0 |
| `node --test tools/release/test/check_release_flags.test.mjs` | 7/7 pass |
| `flutter build apk --release -PallowDebugSignedRelease=true --dart-define=ARENA_FEATURE_SOLO_MODE=true --dart-define=ARENA_FEATURE_CAMERA_COUNTING=true --dart-define=ARENA_FEATURE_CAMERA_TRACE=true` | built (see §2 for size/hash) |
| `adb devices -l` | emulators only — no Redmi 10 |

## 6. Remaining R1 work (exact)

1. Owner installs `TrainingArena-f3-trace.apk` on the Redmi 10 and runs the
   scenarios in `qa/competitive/f3/RUNSHEET.md` (one export per scenario).
2. Executor commits the traces under
   `app/test/camera/fixtures/redmi10_*.txt`, adds one replay test per trace,
   and checks the replayed count against the trace's `# in_app_reps:` value.
   A mismatch is a bug to fix or report, never an average.
3. Only then: threshold updates with old → new, the trace that justifies each,
   and the scenarios that stay green (`qa/competitive/c05/DEVICE_INPUT_LIST.md`).
4. Human rounds (5×20 per exercise, human observer) and the failure-path rows
   in `qa/camera/device_validation_checklist.md`, signed by the device-QA and
   release-pilot roles — the executor cannot sign those.
5. Device frame-rate impact with the F4 skeleton on and off (CAMERA_QA §4.2
   and the F4 handoff).
