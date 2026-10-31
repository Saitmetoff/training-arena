# C05 — device-session input list for the counting thresholds

Date: 2026-09-23 · Feeds `qa/launch/l04/DEVICE_VALIDATION_PACKET.md`.

The replay harness (`app/test/camera/fixture_replay.dart`) proved the current
thresholds on synthetic fixtures. **No threshold was changed** — every value
below is unchanged and waits for physical measurements. A candidate change is
only justified by a recorded trace, not by an opinion.

**F3 status — 2026-09-24: still unmeasured.** The trace recorder is now in
place (`app/lib/camera/trace/`, `ARENA_FEATURE_CAMERA_TRACE`, run sheet
`qa/competitive/f3/RUNSHEET.md`), but no physical device was attached to the
F3 run (`adb devices -l` listed emulators only). Every value below therefore
keeps its candidate status; nothing here is "measured" yet. On the first
device session, unchanged values are labelled **measured, unchanged** and any
change is listed with old → new, the trace name and the scenarios that stay
green.

## Current thresholds (`app/lib/camera/counter/exercise_profile.dart`)

| Threshold | Push-ups | Squats | Candidate | What the device session must measure |
| --- | --- | --- | --- | --- |
| `enterBottomAngle` | 100° | 100° | unchanged | The deepest reliable elbow/knee angle per device; if real bottoms cluster above 100°, the entry is too strict (false negatives) |
| `exitBottomAngle` | 150° | 160° | unchanged | The top-of-rep angle; if lockout reads below the exit, reps never complete |
| `minimumBottomDwellMs` | 120 | 150 | unchanged | Frame-level dwell at the bottom; verify jitter cannot fake a dwell |
| `minimumRepDurationMs` | 700 | 900 | unchanged | Time per rep for fast but honest reps; if fast reps are rejected, lower with evidence |
| `minimumRepGapMs` | 350 | 400 | unchanged | Consecutive rep spacing; verify a bounce cannot count twice |
| `trackingConfidence` | 0.60 | 0.60 | unchanged | Mean landmark likelihood in a real room; if honest frames fall below, the counter under-counts |
| `framingConfidence` | 0.55 | 0.55 | unchanged | Likelihood while framing; must not lock on a partial body |
| `framingStableMs` | 500 | 500 | unchanged | Time from camera start to first count; user-perceived startup |
| `trackingLossGraceMs` | 300 | 300 | unchanged | Duration of real occlusions that should reset the rep |
| `maxFrameGapMs` | 600 | 600 | unchanged | Detector stalls on low-end devices; a stall must reset, not count |
| `minimumBodySpan` | 0.35 | 0.35 | unchanged | Distance at which the body becomes too small; low-end device framing |
| `maximumBodySpan` | 0.98 | 0.98 | unchanged | "Too close" detection |

## What the L04 session should capture (and how it feeds this harness)

1. **Record landmark traces, not video.** The session already uses
   `.invalid` test accounts and no frames leave the device; the bridge emits
   numbers only. Dump the pose event stream for each scenario to the text
   fixture format in `app/test/camera/fixture_replay.dart` (header comment
   documents it) and replay it with
   `flutter test test/camera/fixture_replay_test.dart`-style cases.
2. **Scenarios that matter for these thresholds** (each on low-end, mid and
   flagship devices, both exercises):
   - 20 clean reps at the tester's natural pace;
   - 5 deliberately shallow reps (half depth);
   - 5 fast reps;
   - 10 seconds of camera handling with the body still (shake);
   - one occlusion mid-rep (hand or leg leaving frame);
   - one sagging-body rep;
   - one framing walk-in and walk-out.
3. **Report per scenario**: counted reps, rejections, and the angle trace at
   the bottom. That is exactly what `ReplaySummary` already records.
4. **Pass thresholds stay unchanged** (`qa/camera/device_validation_checklist.md`)
   until the traces justify a candidate; if they do, the change is listed
   here with the fixture name and before/after values.

## What this task deliberately did not do

- No threshold change, no camera code change, no accuracy claim.
- No physical device was attached; synthetic fixtures are labelled as such
  and are not device evidence.
