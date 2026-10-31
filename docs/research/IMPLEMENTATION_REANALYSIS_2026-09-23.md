# Implementation re-analysis vs the competitive pack — 2026-09-23

Read-only analysis. No source, config, test or release file was changed to
produce this. Sources: working tree at HEAD `1561673` plus the uncommitted
review-fix A/B set; `prompts/competitive/` (C00–C09); `docs/research/`
(analysis and owner notes). Method: file inspection, `git log -S` provenance
checks and a per-task sweep of `app/`, `supabase/`, `tools/`, `docs/decisions/`
and `qa/`.

## 1. Headline

**The belief that most of the competitive pack is already implemented is not
supported by the tree: 0 of 10 tasks have deliverables.** Two tasks (C04, C05)
partially overlap code that shipped in the L01 freeze, which is the likely
source of the impression. Eight tasks have no artifact at all.

Second finding: the pack and its source documents are **untracked**
(`prompts/competitive/`, `docs/research/`, `docs/social/`), so nothing in this
direction exists at HEAD.

## 2. Verdict per task

| Task | Verdict | Evidence |
| --- | --- | --- |
| C00 decisions ADR | **ABSENT** | `docs/decisions/` stops at `11-privacy-deletion-interface-note.md`; D-A…D-E exist only as unchecked boxes in `docs/research/NOTES.md:27-36` |
| C01 solo mode | **ABSENT** | No `app/lib/solo/`, no `app/test/solo/`; `arena_config.dart:58-68` has no `ARENA_FEATURE_SOLO*`; `check_release_flags.mjs` checks no solo flag |
| C02 daily goal + streak | **ABSENT** | Only the two original migrations exist; zero `streak|daily_goal` matches in `supabase/**`; no Dart goal/streak logic |
| C03 bests + badges + stats | **ABSENT** | No badge/best/stats code; `app/test/account/profile_surfaces_test.dart:142` still asserts the profile has no Badges surface; the only "badge" in `app/lib` is the camera rep badge (`camera_preview.dart:56,129`) |
| C04 trust surface | **PARTIAL, pre-existing** | Truthful copy already in the L01 freeze: `settings_page.dart:321-324`, `battle_flow_page.dart:363,797`, `battle_widgets.dart:288`. Missing: provenance audit, forbidden-claims copy test, `qa/competitive/c04` |
| C05 counting harness | **PARTIAL, pre-existing** | `app/test/camera/rep_counter_test.dart` already replays `SyntheticPoseSource` sequences (`app/lib/camera/debug/synthetic_pose.dart:322`). Missing: `app/test/camera/fixtures/`, a text-fixture replay runner, shake/handling rejection, depth/partial-rep accounting, the L04 device-input list |
| C06 listing + ASO | **ABSENT** | `docs/release/PLAY_STORE_PACKET.md` unchanged since L07 (`04124f3`); no keyword table, no forbidden-claims checklist |
| C07 share clip | **ABSENT** | No clip decision record, no `ARENA_FEATURE_SHARE_CLIP`; `app/lib/sharing/` is the pre-existing static card only |
| C08 web battle spike | **ABSENT** | No spike artifacts anywhere; only mentions are in the analysis and the prompt itself |
| C09 owner wizards | **ABSENT** | `tools/wizards/` does not exist |

`qa/competitive/` does not exist; no C task has a `PROJECT_STATUS.md` section
or a commit.

## 3. What "already implemented" actually is

- **C04 and C05 overlap existing behavior, not existing tasks.** The privacy
  and server-confirmed copy predates the pack (L01, `3efdc07`), and the camera
  tests use synthetic pose sequences inline. Neither task's acceptance is met:
  there is no audit, no copy guard, no fixture files, no replay command, no
  threshold table and no device-input list.
- **The L01–L11 work is release infrastructure, not these features.** It
  covers signing gates, hosting/deployment packets, store/privacy surfaces and
  the review fixes. It does not add solo play, streaks, badges, clips, spikes
  or wizards.
- A session that runs a C prompt and concludes "already implemented" from the
  C04/C05 overlap would be generalizing from two partial cases to the whole
  pack.

## 4. What the uncommitted tree actually contains

So this work is not mistaken for competitive-pack output:

- **Review-fix Batch A** — auth durability/lifecycle (`account/auth/*`,
  `account_controller.dart`, `account_api.dart`) and the paused-session camera
  fix (`camera/camera_session.dart:338-620`), with tests.
- **Review-fix Batch B** — deletion-page identity/HTTP-envelope guards,
  release workflow hold, `tools/release/bundletool.mjs`,
  `check_release_flags.mjs` and their tests, Gradle placeholder-host guard.
- **Batch C (native push hardening)** — not implemented; tracked as the new
  **R17**.
- **L11** — `qa/launch/l11/L11.md`: release packet re-verified (analyzer
  clean, 492/492 Flutter tests, 12/12 release-tool regressions, 21/21
  challenge-web, prototype groups, App Link fail-closed); distribution
  **NO-GO**; nothing uploaded or published. The A/B closeout summary is still
  owed (L11.md:51).
- **L09/L10 records** (`qa/launch/l09`, `l10`) and `docs/social/` are
  deliberately uncommitted.
- Current status line (`PROJECT_STATUS.md:3`, 2026-09-22): review-fix A/B in
  tree, Batch C open, **NO-GO**. Open blockers: R1, R2, R3, R4, R8, R9, R12,
  R13, R16, R17.

## 5. Stray artifacts and duplication found

- **`C00`–`C11` empty directories at the repo root** — created by executor
  sessions that used the task id as a working directory. All were empty; ten
  were removed during this pass, two (`C04`, `C10`) were held open by other
  running opencode processes at the time and need those sessions closed before
  removal. Nothing was relocated because nothing was in them.
- `qa/integration/evidence/t10r2/` duplicates evidence file names already
  present in `qa/integration/evidence/` (`apk_build_qa.txt`,
  `arena_smoke_e2e.txt`, `emulator_arenaqa*.log`); one location should be
  canonical.
- The review pass is described at three levels (`docs/release/REVIEW_2026-09-21.md`,
  five `prompts/REVIEW_FIXES_*.md`, `qa/launch/l11/L11.md`); the owed closeout
  summary would make a fourth. Consolidate rather than add.
- `docs/research/`, `docs/social/` and `prompts/competitive/` are untracked
  while the pack cites them as sources, so the pack is not reproducible from
  HEAD.

## 6. Corrected next actions

1. **Decide the pack's fate**: run it for real (start at C00) or archive it.
   If run, C04 and C05 need only their missing pieces, not a rewrite.
2. **Protect the untracked set** — commit or explicitly park `docs/research/`,
   `docs/social/`, `prompts/competitive/` and the L09–L11 records. Owner
   decision; nothing here was committed by this analysis.
3. **Close the two executor sessions** holding `C04`/`C10`; they produced no
   files, and their open handles block cleanup.
4. Keep the one-writer rule: none of C00–C09 should run while the A/B patch
   set is uncommitted (R8), or the two will interleave in the same tree.
