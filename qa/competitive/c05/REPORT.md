# C05 — counting robustness and replay harness: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

## Finding first

`app/lib/camera/counter/rep_counter.dart` already implements the protections
this task targeted: framing stability, hysteresis band, bottom dwell, minimum
rep duration, debounce, straight-body validation, low-confidence rejection,
tracking-loss reset, stall reset and duplicate-frame rejection — each with an
existing code-driven test in `app/test/camera/rep_counter_test.dart`. No
counting behaviour was changed.

## What was added

| Area | File |
| --- | --- |
| Fixture format + parser + serializer + replay runner | `app/test/camera/fixture_replay.dart` |
| Committed fixtures (6) | `app/test/camera/fixtures/*.txt` (generated from `SyntheticPoseSource`) |
| Regeneration path | `app/test/camera/generate_pose_fixtures_test.dart` (`FIXTURE_GEN=1`) |
| Replay tests | `app/test/camera/fixture_replay_test.dart` (round-trip, malformed input, clean push-up, shake, half depth, plank collapse, dropout, clean squat) |
| Device input list | `qa/competitive/c05/DEVICE_INPUT_LIST.md` |

The format carries numbers only — no frame, thumbnail or image field — so a
recorded device trace can be committed and replayed without touching the
privacy rules.

## Why this matters for R1

The L04 physical session can now dump its landmark traces into the same text
format and replay them here forever. That turns a one-off human session into a
permanent regression set, and it is the missing middle between "host tests
with synthetic poses" and "no device evidence at all".

## Verification (2026-09-23)

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test test/camera` | passed (existing + 8 new replay tests) |
| `flutter test` (full) | 532/532 passed (524 before; +8) |

Thresholds: **all unchanged**; every candidate waits on recorded device traces
(`DEVICE_INPUT_LIST.md`). No accuracy claim is made.
