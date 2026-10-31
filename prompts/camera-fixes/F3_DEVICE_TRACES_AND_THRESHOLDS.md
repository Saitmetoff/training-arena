# F3 — real-device traces and honest thresholds

Depends on: F1, F2 and F4 (the overlay shows what the counter sees, which
makes the device session and its traces easier to trust). Estimate: 8–16 h
plus real device time.

Include the common preamble from `prompts/competitive/README.md` and read
`prompts/camera-fixes/README.md` first.

## Goal

Turn the owner's phone sessions into permanent evidence: instrument landmark
tracing, run the L04 scenarios on the Redmi 10, replay the traces through the
C05 harness, and update the threshold table with measured values instead of
guesses.

## Required work

1. **Trace dump (debug-only).** Add `ARENA_FEATURE_CAMERA_TRACE` (default
   false) that, when enabled, writes the last N seconds of landmark frames in
   the exact text format of `app/test/camera/fixture_replay.dart` to
   app-private storage, with a visible in-app label while it is on and a way
   to export/delete the file. Numbers only — no frame, image, thumbnail or
   device identifier. Register the flag in `ArenaConfig`, `docs/CONTRACT.md`,
   `docs/release/CONFIGURATION.md`, and hold it `false` in the release
   workflow via `tools/release/check_release_flags.mjs` (plus its test). The
   trace file must never be included in a release artifact.
2. **Run the scenarios** from `qa/competitive/c05/DEVICE_INPUT_LIST.md` on the
   Redmi 10 with the F1/F2 build: 20 clean side reps, 20 clean head-on reps,
   5 shallow reps, a shake sequence, one occlusion mid-rep, one sagging rep,
   and a framing walk-in — both exercises where F2 supports them.
3. **Replay every trace** through `app/test/camera/fixture_replay.dart`,
   commit the traces under `app/test/camera/fixtures/` with a name that says
   which device session they came from, and add the replay tests. The in-app
   count and the replayed count must agree for each session; a mismatch is a
   bug that must be fixed or reported, never averaged away.
4. **Update the threshold table** in `qa/competitive/c05/DEVICE_INPUT_LIST.md`
   with the measured values. Any threshold change lists old → new, the trace
   that justifies it, and the scenarios that stay green.
5. **Update `qa/camera/device_validation_checklist.md`** honestly: mark the
   rows actually executed, with the build hash and trace names, and leave the
   rest open. Do not sign for a human reviewer.
6. **Report** per scenario: counted, rejected, rejection reason, and what
   remains unvalidated. No accuracy percentage, no "works everywhere".

## Owned paths

`app/lib/camera/` (trace instrumentation only), `app/lib/config/`,
`app/test/camera/`, `qa/camera/`, `qa/competitive/f3/`,
`qa/competitive/c05/DEVICE_INPUT_LIST.md`, `docs/`, the release-flag check and
its test.

## Must not

- Change counting behaviour in this task; that was F2. Here only measurements
  and the evidence-backed threshold updates.
- Commit a trace containing a device identifier, account id or any personal
  value; the format carries numbers and timestamps only.
- Ship the trace flag enabled in any release workflow (the hold check must
  fail if it is).
- Claim the R1 gate is closed: the checklist is partially executed and needs
  the owner's human review pass.

## Acceptance

- Traces and replay tests committed; `flutter test` passes with them.
- In-app vs replay counts agree per session (or the mismatch is fixed and
  documented).
- Threshold table updated with measured values and named traces; unchanged
  values say "measured, unchanged".
- `check_release_flags.mjs` and its test hold the new trace flag false; the
  full release-tool regression passes.
- `docs/PROJECT_STATUS.md` gets a dated section with the per-scenario results
  and the exact remaining R1 work.

## Handoff

Standard handoff: trace inventory, per-scenario results, threshold deltas,
and the remaining unvalidated scenarios with the reason.
