# F2 — head-on (front-view) counting: verification record

Date: 2026-09-24 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Start commit: `384452e` (F1 fix) · Branch: `main`.

Owner report: "The counting is not processing. It should not count sideways
only, it should count straight head on too."

## Verdict

| Area | Result |
| --- | --- |
| Geometric cause verified with fixtures | PASS (`qa/competitive/f2/fixture_before_fix.txt`, `fixture_measurements.txt`) |
| Front-view counting implemented + fixture-tested | PASS (85/85 camera tests, 555/555 full suite) |
| Side-view suite unchanged and green | PASS (`rep_counter_test.dart` has no diff) |
| Physical Redmi 10 session | **BLOCKED** — no phone attached |

Physical-device evidence is **not** claimed. `adb devices -l` lists only two
emulators (`emulator-5554`, `emulator-5556`); the owner's Redmi 10 was not
connected and USB debugging was off in the F1 session. The missing input is
the phone (or the owner running the delivered APK and returning the traces).

## 1. Root cause — verified, not assumed

All four suspected causes were reproduced on fixtures before any counter
change (`fixture_before_fix.txt` is the red run of the new replay tests
against the unchanged counter):

| Suspected cause | Verification |
| --- | --- |
| 2D elbow angle is degenerate head-on | On the clean head-on fixture the shoulder–elbow–wrist angle stays **135.6°…172.5°**; the side-view bottom band is ≤ 100°, so the rep never enters the bottom (`fixture_measurements.txt`). |
| Side-view span framing reports `tooFar` | The head-on fixture's nose→wrist bounds span is ≈ 0.30 at the top and collapses at the bottom, below `minimumBodySpan` 0.35 → framing cannot lock; the clean head-on fixture counted **0** on the unchanged counter (`fixture_before_fix.txt`). |
| `_validateBottom` shoulder–hip–ankle check is degenerate | A floor-level head-on view hides the legs behind the torso (the front fixture deliberately omits knees/ankles, as a real detector does), so the old check fails closed on `ankle == null`; even with legs detected the hip line is foreshortened. The red run shows the sag fixture rejected as `none` — the rep never reached the bottom at all. |
| Guidance copy describes side placement only | `camera_types.dart` push-up copy said "Lie sideways…" with no head-on option before the change. |

Fixture signal measurements (raw, before smoothing):

| Fixture | 2D elbow angle | Front signal (shoulder height / shoulder width) | Expected |
| --- | --- | --- | --- |
| `pushups_front_clean_rep.txt` | 135.6…172.5° | **0.420…1.117** | counts 1 |
| `pushups_front_half_depth.txt` | 153.3…172.4° | 0.717…1.129 | counts 0 |
| `pushups_front_shake_only.txt` | 159.3…171.7° | 0.975…1.126 | counts 0 |
| `pushups_front_sag.txt` | 136.2…170.9° | 0.435…1.123 | rejected `bodyNotStraight` |

## 2. What changed

### 2.1 View detection

- `CameraViewMode { side, front }` in `camera_types.dart`.
- `detectCameraViewMode` in `pose_math.dart`: shoulder width / projected
  shoulder-to-hip torso length, with the shoulder z-spread as a tiebreaker
  inside the hysteresis band. Returns `null` for an ambiguous or incomplete
  frame; the counter keeps its previous mode. Initial mode is `side`.
- Ratios: front ≥ 0.75, side ≤ 0.35 (the wide band stops a squat's shortening
  projected torso from flapping the mode mid-rep). The z term is ignored when
  the frame carries no depth at all, so the text fixtures (which drop `z`)
  decide on the ratio alone.
- The mode is observable in `RepCounterResult.viewMode` for tests and F4.

### 2.2 Front-view push-up counting

- **Signal chosen:** shoulder height above the hands, normalised by shoulder
  width. The 3D elbow angle was rejected because ML Kit `z` is documented
  experimental and the C05 fixture format carries no `z`, so it could not be
  regression-tested; the 2D elbow angle is measurably degenerate.
- Same state machine, hysteresis, dwell, debounce and confidence rules as the
  side view; only the enter/exit values differ (bottom = low signal).
- **Front framing:** head, both shoulders, both wrists and both hips visible;
  shoulder width 0.12…0.75 is the size proxy. A missing hand is
  `partialBody` and never locks framing; a shrunken body is still `tooFar`.
- **Front sag guard:** the projected shoulder-to-hip offset (in shoulder
  widths) must stay within 0.30 of the top reference captured once per framing
  episode; drift rejects with `bodyNotStraight`. The reference is captured on
  the first high-signal frame after the framing lock, not during the descent
  (recording every top-band frame silently captured the sag mid-descent and
  was caught by the sag fixture).

### 2.3 Squats — decided, not half-implemented

Squats stay **side-view only**. The knee bends towards the lens head-on: the
side-view 2D knee angle stays 159…169° across a hand-built front-view squat
while the hip drops 0.16 of the frame (test
`the side-view knee angle cannot separate a front-view squat`). Implementing a
front knee signal would add a second unvalidated signal with no device
evidence. A head-on squat is refused with the new `TrackingPauseReason.
wrongView` and copy that asks the athlete to turn side-on.

### 2.4 Copy and versions

- Push-up instructions in `camera_types.dart` now describe both placements
  ("lie sideways (best for depth) or face the phone head-on").
- `wrongView` copy: "this exercise is counted from the side. Turn so the
  phone sees your side."
- `arenaCounterVersion` 1.0.0 → **1.1.0** (counting change).

### 2.5 Fixtures and tests

- `SyntheticPose.pushupFrontFrame` + `SyntheticPoseSource.pushupsFront` and a
  `frontSag` sweep parameter.
- Five committed fixtures generated through the existing `FIXTURE_GEN=1`
  path: `pushups_front_clean_rep.txt`, `pushups_front_half_depth.txt`,
  `pushups_front_shake_only.txt`, `pushups_front_sag.txt`,
  `pushups_front_partial_body.txt`.
- `fixture_replay_test.dart` gained five replay cases; `front_view_test.dart`
  added 17 cases (geometric cause, detection boundaries, hysteresis,
  z tiebreak, framing, noise, squat decision).

## 3. Evidence per scenario

| Scenario | Before (unchanged counter) | After |
| --- | --- | --- |
| Clean head-on rep | **0 counted** (red test) | **1 counted** |
| Head-on half-depth | 0 | 0 — signal floors at 0.717, never ≤ 0.60 |
| Head-on shake only | 0 | 0 — signal floors at 0.975 |
| Head-on sag | 0 counted, rejection `none` (never reached the bottom) | 0 counted, rejection **`bodyNotStraight`** |
| Head-on hidden hand | never locked | never locked, front `partialBody` |
| Head-on shrunken body | `tooFar` (side span) | `tooFar` (shoulder width < 0.12) |
| Front-view squat | silently never counts | `wrongView`, copy asks to turn |
| Side-view push-up/squat suite | green | green, file unchanged |
| Full suite | 533 passed +1 skipped | **555 passed +1 skipped** |

Analyzer: `flutter analyze` → **No issues found**.

## 4. Candidate thresholds (F3 owns the measured values)

| Threshold | Candidate | Fixture that supports it | F3 must measure |
| --- | --- | --- | --- |
| Front enter-bottom signal | ≤ 0.60 | clean bottom 0.420 vs half-depth floor 0.717 | real top/bottom ratios per rep, across camera distances |
| Front exit-bottom signal | ≥ 0.90 | clean top 1.117 | full-extension ratio on device |
| Shoulder span min/max | 0.12 / 0.75 | clean width ≈ 0.23; shrink test | real framing walk-in/out |
| Sag tolerance | 0.30 shoulder widths | sag drift ≈ 0.45 vs clean ≈ 0.02 | real sag/pike traces |
| View ratio front/side | 0.75 / 0.35 | synthetic side ≈ 0.09, front ≈ 1.9 | oblique placements on device |
| Z-spread front/side | 0.06 / 0.12 | hand-built frames only | whether ML Kit z is stable enough to keep |

No physical threshold claim is made. Every front-view value is a synthetic
candidate until F3 replays real traces.

## 5. Commands and results

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test test/camera` (baseline, before change) | 63 passed, 1 skipped |
| `FIXTURE_GEN=1 flutter test test/camera/generate_pose_fixtures_test.dart` | 1 passed; 5 fixtures written |
| `flutter test test/camera/fixture_replay_test.dart` (red) | 3 failures → `fixture_before_fix.txt` |
| `flutter test test/camera/fixture_replay_test.dart` (after) | passed |
| `flutter test test/camera` (after) | **85 passed, 1 skipped** |
| `flutter test` (after) | **555 passed, 1 skipped** |
| `adb devices -l` | emulator-5554, emulator-5556 only — no Redmi 10 |

## 6. Scope, honesty and handoff

- **Delivery:** non-distributable, debug-signed test build
  `TrainingArena-solo-camera-frontview.apk` (90,877,423 bytes, SHA-256
  `71EA009E…5C05B7`) at `app/build/app/outputs/flutter-apk/`. The owner must
  install it on the Redmi 10 and record the front-view session traces for F3;
  no phone was attached here, so nothing was copied to a device.
- Evidence is **fixture-based only**; no device trace, no accuracy claim, no
  "works on all phones".
- One existing copy assertion in `camera_session_test.dart` changed
  (`'head, hands and feet'` → `'head and both hands'`) because the task
  requires truthful head-on guidance. No counting assertion changed;
  `rep_counter_test.dart` is untouched.
- Unrelated dirty files (`qa/integration/evidence/t10r2/*`) were preserved.
- `qa/camera/device_validation_checklist.md` is F3's file; its placement step
  still needs the side/head-on wording when F3 runs.
- `RepCounterResult` now carries `viewMode` and `signal`, which F4 can use for
  the skeleton overlay without a new data path.

### What F3 must still measure

1. Front signal top/bottom ratios on the Redmi 10 (clean set, shallow set,
   shake) and the resulting enter/exit values.
2. Sag/pike traces against the 0.30 shoulder-width drift tolerance.
3. Framing: shoulder-width min/max on a real walk-in/walk-out, and whether
   both hips are reliably detected head-on.
4. View detection across oblique placements, and whether ML Kit `z` is stable
   enough to keep as a tiebreaker.
5. Squat placement guidance on device (`wrongView` timing).
6. The physical acceptance items from the F2 prompt: a clean head-on set
   counts believably, a shallow head-on rep does not count, and the preview
   shows no false `tooFar`.

