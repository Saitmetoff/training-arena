# C01 — solo max-reps mode: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Directive: owner ("commit changes and finish all the tasks in one shot"),
decisions in `docs/decisions/12-competitive-direction.md`.

## What landed

| Area | Files |
| --- | --- |
| Domain | `app/lib/solo/domain/solo_result.dart` (result + source + derived stats) |
| Store | `app/lib/solo/data/solo_result_store.dart` (port, in-memory, SharedPreferences, 100-entry cap, corrupt-entry skip) |
| Controller | `app/lib/solo/runtime/solo_controller.dart` (intro → countdown → practice → counting → result; manual path; save/restart; re-entrancy-safe round start) |
| UI | `app/lib/solo/ui/solo_page.dart` (entry, countdown, live preview + reps, manual stepper, result + stats) |
| Entry | `app/lib/battle/ui/battle_tab.dart` — flag-gated `Solo set` secondary action |
| Flag | `app/lib/config/arena_config.dart` (`ARENA_FEATURE_SOLO_MODE`), `tools/release/check_release_flags.mjs`, `.github/workflows/release-checks.yml` |
| Tests | `app/test/solo/` (fakes, store, controller, gate/flow widget tests) |

## Non-competitive guarantees

- No server call exists in the solo path; the store is device-local.
- No receipt, rating, leaderboard row or match row is created (there is no
  code path to any of them).
- Manual results are labelled `Self-reported`; camera results
  `Camera-counted`.
- The page states: "Solo sets are practice: no receipt, no rating, no
  leaderboard. Results stay on this device."

## Verification (commands and results)

| Command | Result |
| --- | --- |
| `flutter analyze` (from `app/`) | No issues found (exit 0) |
| `flutter test test/solo` | 15/15 passed |
| `flutter test` (full suite) | **507/507 passed** (492 before; +15) |
| `node tools/release/check_release_flags.mjs` | release flag check passed |
| `node --test tools/release/test/check_release_flags.test.mjs tools/release/test/check_android_bundle.test.mjs` | 13/13 passed |

Flutter 3.47.5 at `D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat`
(not on PATH). No physical device was attached; the camera path is exercised
with a scripted fake only, consistent with R1/R7 remaining open.

## Deliberately not done

- No exercise picker (push-ups only in v1).
- No backend sync of solo results (C02 owns server truth for streaks).
- No camera device validation; camera counting stays off in the release
  workflow.
- No badge/achievement work (C03).
