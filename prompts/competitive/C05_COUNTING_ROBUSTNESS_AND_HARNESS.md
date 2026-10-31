# C05 — Counting robustness and a replayable landmark harness

Status 2026-09-23: **implemented as harness + fixtures; thresholds unchanged.**
The counter already covered the targeted defect classes; the new text fixture
format lets L04 device traces be replayed permanently. Record:
`qa/competitive/c05/REPORT.md`, input list:
`qa/competitive/c05/DEVICE_INPUT_LIST.md`.

Depends on: nothing. Estimate: 12–24 h.
Does **not** replace the physical camera gate (R1/R7); it makes that gate
cheaper and the counting testable without a device.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `diagnosing-bugs` — for the shake/noise false-positive class of defect.
- `tdd` — every behaviour change lands with a fixture test first.

## Goal

The category's number-one review complaint is counting that is wrong in both
directions: real reps missed, camera movement counted (analysis §2). Training
Arena cannot tune this without a device today, which is exactly why the
protocol in `qa/camera/device_validation_checklist.md` is still unsigned. Build
the missing middle: a deterministic replay harness over landmark sequences so
the counting state machine can be regression-tested, then use it to improve
robustness honestly.

Scope:

1. **Harness.** A pure-Dart runner that feeds landmark-frame sequences through
   the existing counting state machine and asserts rep counts, partials and
   rejects. Fixtures are recorded sequences or clearly labelled synthetic
   sequences — never presented as physical-device evidence. Keep fixtures
   small and text-based under `app/test/camera/fixtures/`.
2. **Defect classes.** With the harness, cover: camera shake/handling with no
   body motion, half-depth reps, plank collapse, missing landmarks, frame
   dropouts, and both movements (push-up, squat). Each gets a failing case and
   a fix.
3. **Behaviour.** Implement shake/handling rejection and depth validation with
   honest partial-rep accounting, all behind tests. Any threshold you change
   is a **candidate** and must be listed with its old value, new value and the
   fixture that justifies it.
4. **Device-session input list.** Write the exact list of what the L04
   physical session must measure to confirm or reject each candidate
   threshold, so the human session has a concrete target instead of a
   pass/fail vibe.
5. **Honest claims.** If partials become user-visible, C04 owns the copy; here
   only make the data available.

## Owned paths

`app/lib/camera/` counting logic, `app/test/camera/` plus new fixtures,
`qa/camera/` input list note, `qa/competitive/c05/`.

## Must not

- Weaken a threshold to make a test pass, or change behaviour without a
  fixture that fails before and passes after.
- Touch the native bridge or permissions unless a reproduced defect requires
  it; if it does, write the interface note first.
- Claim accuracy, calibration success or device validation. Emulators and
  fixtures are not physical evidence.
- Change release flags or the media review gate.

## Acceptance

- The harness runs offline with `flutter test`; a documented command replays
  one fixture and prints the rep/partial/reject trace.
- Each defect class has a before/after test pair, and the full suite passes
  (459+ existing plus new).
- Every threshold change is listed with old value, new value and the fixture
  name; unchanged thresholds are listed as "unchanged, pending device data".
- The L04 input list is written and names each candidate with the measurement
  that would confirm or reject it.
- No user-facing copy changed in this task.

## Handoff

Standard handoff, including the threshold table and the fixture inventory.
