# Physical-device validation checklist

Owner: task `10` (integration and device QA) · Gate: task `11` release pilot
Procedure and blocking threshold: `docs/camera/CAMERA_QA.md` §4.

Status: **prepared, not executed — camera-counted release is blocked until this
checklist is complete and signed.** Build identity pre-filled by L04
(2026-09-20); no device slot is assigned and no round has been run. The camera
layer must not be enabled with `ARENA_FEATURE_CAMERA_COUNTING=true` while any
row below is incomplete.

## Beta validation — pending (2026-09-30)

The new shared preview geometry needs fresh runs on **Redmi 10 and a second
physical Android phone**. No beta camera case has been executed or signed.
Use the new committed build identity, not the historical L04/F3 artifacts
below. Fill `qa/camera/beta_device_results.json` after review; CI refuses camera
enablement without both models and app sources matching that tested commit.

On each phone check preview/analysis crop alignment, rotation and mirroring;
side/front push-ups and side squats; head/feet outside the frame with the
signal chain visible; too-close guidance while readable practice completes;
low light, a missing signal joint, low-confidence signal chain, half depth,
bounce, sag/collapse and tracking loss/recovery. Also run permission denial,
background/resume, offline solo, save/restart and a failed save. Record human
and app counts per round, every false positive, and the investigation for
every discrepancy. An average does not close a reproducible failure. Export
only voluntarily shared numeric development traces, never camera images.
Counting thresholds and protections remain unchanged.

## Historical build under test (L04)

Prepared by L04 on 2026-09-20; the packet is
`qa/launch/l04/DEVICE_VALIDATION_PACKET.md` and the raw build record is
`qa/launch/l04/build_under_test.txt`.

| Field | Value |
| --- | --- |
| Commit hash | `9d94ee4` + L04 media-policy change (L04 commit) |
| Build date | 2026-09-20 |
| APK SHA-256 | `53d6bafb5e17a53bbd3af74e3d9d441d68d02b6d58616b9285a2a68032ec8951` (91 444 249 bytes, debug-signed smoke artifact, non-distributable) |
| `runtimeInfo()` output (detector SDK/model, CameraX, API, device) | compile-time pins: ML Kit `pose-detection:18.0.0-beta5` (base), CameraX 1.4.1, minSdk 24; per device record API level and model from `adb shell getprop ro.build.version.sdk` / `ro.product.model` (the app does not surface `runtimeInfo()` on device) |
| Feature flags in the build | camera counting **true**, ranked **false**, challenge links **true**, result sharing **true**, push **false**, preview fixtures **false** |

A new commit, dependency, threshold or counter change invalidates these rows
and the physical runs.

## F3 trace session — prepared, not executed (2026-09-24)

The F3 landmark-trace tooling is in place and the session instructions are
`qa/competitive/f3/RUNSHEET.md`. **No physical device was attached to the F3
environment** (`adb devices -l` listed emulators only), so **no row in this
checklist was executed and nothing is signed**. The prepared session builds
are the debuggable `TrainingArena-f3-trace-debug.apk` (222 378 595 bytes,
SHA-256 `A7F690AC…869A6`; `adb run-as` pull) and the debug-signed release
`TrainingArena-f3-trace.apk` (91 140 003 bytes, SHA-256 `8031DB1E…97B58A`),
the F1–F4 code with `ARENA_FEATURE_CAMERA_TRACE=true` for the trace pass; the
flag is pinned `false` in every release workflow and is not part of any
distributable artifact. The L04 build rows above remain as L04 recorded them;
the F3 session should record these builds instead when it runs.

## Device matrix

| # | Device | Android | Tester | Date |
| --- | --- | --- | --- | --- |
| 1 (low-end) | | | | |
| 2 (mid) | | | | |
| 3 (flagship) | | | | |
| 4 (Tensor checkpoint, if targeted) | | | | |

## Per device, per exercise

Record device count vs human count for five 20-rep rounds plus the fast, paused
and step-out rounds. Attach raw notes or screenshots.

### Push-ups

| Round | Human | Device | Within ±2? | False positives | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |
| Fast touch-and-go | | | | | |
| 3 s bottom pause | | | | | |
| Step out mid-round | | | | | |

### Squats

| Round | Human | Device | Within ±2? | False positives | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |
| Fast touch-and-go | | | | | |
| 3 s bottom pause | | | | | |
| Step out mid-round | | | | | |

## Failure paths (mark pass/fail and attach logcat)

| Scenario | Expected | Result |
| --- | --- | --- |
| First-run permission allow | practice starts, on-device copy shown | |
| Permission deny | actionable copy, camera stays off | |
| Deny again → permanent | Settings action shown | |
| Settings return with permission allowed | practice resumes automatically | |
| Background mid-round | camera released, round clock unaffected | |
| Lock screen mid-round | same as background | |
| Rotate during round | preview upright, counting continues | |
| Another camera app holds the camera | camera-busy copy, no crash | |
| Dark room | low-light copy, counting pauses | |
| Lens covered | no-person copy | |
| Non-signal head/foot outside frame, visible stable signal chain | practice/rep can complete; too-close copy is guidance | |
| Missing signal joint | partial-body copy, no rep | |
| Route exit | camera indicator off within 2 s, no leak | |
| App data inspection | no frames, thumbnails or landmark files | |
| Sustained use / heat (L04) | 6 consecutive live rounds: no crash, ANR or thermal shutdown; record battery temperature and thermal status before/after | |

## Verdict

| Criterion (from CAMERA_QA §4.3) | Pass? |
| --- | --- |
| Zero false-positive reps | |
| ≥ 90 % of rounds within ±2 reps and aggregate error ≤ 5 % | |
| 100 % transparent pause reasons | |
| 100 % lifecycle recovery, no crash/ANR | |
| No frame/landmark artifact on disk or network | |
| No crash on the Tensor checkpoint | |

Release decision (enabled / blocked) and rationale:

| Role | Name | Date | Signature |
| --- | --- | --- | --- |
| Device QA (task `10`) | | | |
| Release pilot (task `11`) | | | |
