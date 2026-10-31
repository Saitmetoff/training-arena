# F2 — head-on (front-view) counting

Status 2026-09-24: **host-complete; physical session BLOCKED.** View detection,
the front-view push-up signal, front framing and sag guard, the side-only squat
decision and the guidance copy are implemented and fixture-tested; the side
suite is unchanged. Evidence and candidate thresholds are in
`qa/competitive/f2/REPORT.md`. No phone was attached (`adb devices -l` lists
emulators only), so the Redmi 10 acceptance rows are pending the owner.

Owner report: "The counting is not processing. It should not count sideways
only, it should count straight head on too."

Depends on: F1 (the camera must reopen before any of this is testable).
Estimate: 16–32 h.

Include the common preamble from `prompts/competitive/README.md` and read
`prompts/camera-fixes/README.md` first.

## Skills to load

- `diagnosing-bugs` — verify the geometric cause before changing the counter.
- `tdd` — every signal and profile change lands with a failing fixture first.

## Why it fails (verify, do not assume)

The counter is built for a side view:

- `RepCounter._updateAngle` uses the 2D elbow angle
  (shoulder–elbow–wrist). Facing the camera, the elbow bends towards the lens,
  so that 2D angle barely changes; the rep never enters the bottom band.
- Framing requires a body span of `0.35…0.98` of the frame
  (`ExerciseCounterProfile.minimumBodySpan`), measured across the required
  landmarks. A head-on athlete is foreshortened, so framing reports
  `tooFar`/`partialBody`.
- `_validateBottom` checks shoulder–hip–ankle ≥ 150°, which is degenerate
  head-on.
- The user-facing camera guidance only describes a side placement.

Confirm each on a physical device (logcat + the failing pause reasons), then
fix the geometry, not the thresholds.

## Required work

1. **View detection.** Add a `CameraViewMode { side, front }` (name it in the
   camera types), detected from landmark geometry — for example normalised
   shoulder width against torso length, plus the shoulder z-spread. Must be
   deterministic, hysteretic (no mode flapping mid-set) and unit-tested at the
   boundary. Unknown/ambiguous frames must keep the previous mode, never
   invent one.
2. **Front-view counting signal (push-ups).** Investigate candidates on
   fixtures — shoulder–wrist vertical displacement, shoulder height relative
   to the wrist, or a 3D elbow angle using the landmark z — pick the one the
   fixtures support, and keep its thresholds as **candidates** for F3.
3. **Front-view bottom validation.** The side-view straight-body check cannot
   apply; define a front-view equivalent (for example torso length relative to
   the top position) and reject sag with a named rejection reason.
4. **Front-view framing.** Framing must accept a foreshortened body: define
   front-view span/visibility rules (shoulders, head, both wrists in frame)
   instead of the side-view nose→ankle span. No false `tooFar`, no unlocked
   framing for a partial body.
5. **Squats.** Decide with evidence: either the same front-view treatment for
   the knee signal, or keep squats side-view-only and say so in the guidance.
   Do not half-implement it silently.
6. **Guidance copy.** Update the camera instructions in `camera_types.dart`
   and the setup documentation so both placements are described truthfully
   (side view stays best for depth; front view is supported for push-ups).
7. **Fixtures.** Extend `app/lib/camera/debug/synthetic_pose.dart` with a
   front-view generator (`SyntheticPose.pushupFrontFrame` or equivalent),
   regenerate the committed fixtures with the existing `FIXTURE_GEN=1` path,
   and add replay cases: a clean front rep counts 1, a front half-depth rep
   counts 0, a front shake sequence counts 0.

## Owned paths

`app/lib/camera/` (counter, profile, types, synthetic pose),
`app/test/camera/`, `docs/camera/`, `qa/competitive/f2/`.

## Must not

- Loosen the side-view thresholds to make front-view work — the existing
  side-view tests must stay unchanged and green.
- Claim accuracy or "works on all phones"; device evidence is per-device.
- Change the solo feature, ranked flags or release holds.
- Add a dependency for geometry; this is arithmetic on landmarks already in
  memory.
- Write, log or export a frame or image anywhere (landmarks only).

## Acceptance

- Logcat/fixture evidence for the geometric cause before the change.
- Side-view suite unchanged; new front-view fixtures fail before and pass
  after; full suite and analyzer clean.
- On the physical Redmi 10: a clean head-on push-up set counts reps
  believably, a deliberately shallow head-on rep does not count, and the
  preview shows no false `tooFar`. Record the session traces for F3.
- Guidance copy updated and truthful about both placements.
- Threshold changes are listed as candidates with their fixture; no physical
  threshold claim is made until F3 replays real traces.

## Handoff

Standard handoff: the chosen front-view signal, the detection rule, the
candidate thresholds, the evidence per scenario, and what F3 must still
measure.
