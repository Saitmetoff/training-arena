# Task 10 — invitation-to-battle integration and device QA report

Date: 2026-09-18
Author: task `10` (integration and device QA owner)
Status: **conditional pass** — the primary recipient path and the full casual
battle completed on an emulator against the real local backend, five
integration defects were found and fixed with regression tests, and eight
items remain blocked or unverified with named owners. **No production or
camera-accuracy claim is made.**

> **L01 reconciliation — 2026-09-20 (OpenCode).** This report remains the dated
> 2026-09-18 historical snapshot (its 416/48/184/16 counts are **not** re-used
> as fresh evidence). L01 re-ran the checks on 2026-09-20 and recorded fresh
> results in `qa/launch/L01.md`: `flutter analyze` clean, 416/416 Flutter tests,
> 48 arena + 10 dispatcher Deno tests, 6 challenge-web and 48 prototype smoke
> checks, debug APK identity/secret scan; pgTAP 184/184 and the 16/16 HTTP e2e
> smoke passed in a same-day verification pass against the same freeze commit.
> §5.1's compile break stays closed
> (analyzer is clean). **R8 is closed** by the L01 baseline commit. **R11 is
> split**: ranked flag unused (confirmed gap); result sharing is enforced at
> `app/lib/arena_app.dart:136` and its entry paths were audited in L01.

Machine-readable companion: `qa/integration/results.json` (schema
`app.trainingarena.qa/scenario-results@1`).

## 1. Scope and environment

| Item | Value |
| --- | --- |
| Repository | `D:\TrainingArena` (shared checkout, branch `codex/training-arena`) |
| `D:\Kiro` | not modified intentionally; see the incident note in §9 |
| App | Flutter 3.24.5 / Dart 3.5.4, debug APK, flags camera/links/ranked/share all on |
| Device | Android emulator `ArenaQA`, API 34, google_apis x86_64, 2.5 GB RAM, swiftshader, WHPX |
| Physical device | **none attached** — camera accuracy cannot be claimed |
| Backend | Supabase CLI 2.116.0 local stack `TrainingArena`, Docker 29.4.2, fake `@arena.invalid` accounts |
| Link host | `example.invalid` (D1 still open) |

All evidence is under `qa/integration/evidence/` (logs, a11y dumps, DB dumps)
and `qa/integration/screens/` (PNG captures). Helper tools are in
`qa/integration/tools/`. Tokens, bearer values and email addresses are not
reproduced in this report; local fixture emails are shown only as
`qa.recipient1@[…].invalid`. The captures contain only local fake fixture
identities and the tester's own local-link token. `qa/integration/.gitignore`
keeps the AVD image, scratch space and the raw captures out of git to avoid
repository bloat; they remain on disk for review and task `11` can promote a
selected subset.

## 2. Primary acceptance test

> A person who has never used Training Arena follows a friend's link and
> completes that specific battle without searching for the friend, navigating
> tabs or re-entering an invitation code on the normal path.

**Result: pass on the recipient path (emulator + local backend).**

Observed sequence, all without opening another tab or typing the code:

1. Cold link `trainingarena://challenge/fixturealice` resolved read-only to
   the exact challenger (`screens/02_small.png`).
2. Signed-out recipient chose email, received a one-time code through the
   local mail catcher, entered it, and returned to the **same** challenge
   (`screens/03_small.png`, `screens/05_small.png`, `screens/06_small.png`).
3. First sign-in claimed a unique username inside the challenge flow.
4. Request sent to `@fixture_alice` (`screens/08_small.png`).
5. Challenger accepted; the app moved to preparation with the server-selected
   exercise (`screens/10_small.png`, `screens/11_small.png`).
6. The app's ready gate correctly blocked on the required unscored practice rep
   (`screens/13_small.png`); the emulated camera cannot see a human body, so
   the ready step for both players was driven through the documented API.
7. Countdown and the full 60-second round ran; both players stayed present to
   the end; a **draw** receipt rendered with the correct viewer identity
   (`screens/22_small.png`).
8. History, leaderboard and profile reflected the confirmed result
   (`screens/28_small.png`, `screens/30_small.png`, `screens/19_small.png`).

Caveat: steps 6–7 used API calls for `ready` because no physical body exists
in the emulated camera. The app's own blocked-ready behaviour is correct and
was captured, but the human camera path remains blocked by **R1**.

## 3. Test matrix results

Status legend: `pass` (executed, evidence), `host` (host tests only),
`blocked` (cannot execute in this environment), `not run`.

| Area | Case | Status | Verification | Evidence |
| --- | --- | --- | --- | --- |
| Recipient | installed, signed-in, cold link | pass | emulator | `screens/20_small.png` |
| Recipient | installed, signed-out, cold link | pass | emulator | `screens/02_small.png` |
| Recipient | warm link while shell runs | pass | emulator | `screens/09_small.png` |
| Recipient | not installed (Play install + referrer) | blocked | none | R4 |
| Recipient | auth return + process restart | pass | emulator | `screens/09_small.png`, `18`, `19` |
| Recipient | expired code retry keeps challenge | pass | emulator | `screens/05_small.png` |
| Recipient | multiple/revoked/username/expired/completed/blocked/busy | host | tests | `app/test/linking`, `app/test/account`, pgTAP |
| Notifications | allowed/denied/duplicate tap/offline | blocked | host | `app/test/notifications`; R4 |
| Camera | permission allowed + detector runs | pass | emulator | `screens/14_small.png` (not accuracy) |
| Camera | permission denied | pass | emulator | `screens/36_small.png`, `37` |
| Camera | permanently denied, no camera, tracking loss, reset, lifecycle | not run | host | `app/test/camera` |
| Camera | physical rep accuracy / false positives | blocked | none | `docs/camera/CAMERA_QA.md`; R1 |
| Battle | both-ready gate (no unattended start) | pass | emulator+api | `screens/13_small.png` |
| Battle | countdown + 60 s round + tie | pass | emulator+db | `screens/22_small.png`, DB evidence |
| Battle | abandoned preparing -> no_result | pass | emulator+db | DB evidence |
| Battle | 10 s recovery, shared outage | not run | host | `app/test/battle` |
| Matchmaking | empty at 15 s and 60 s | pass | emulator | `screens/38_small.png`, `33` |
| Matchmaking | switch to friend cancels | pass | emulator+db | DB evidence |
| Receipts | casual receipt, history, leaderboard, profile | pass | emulator+db | `screens/28`, `30`, `19` |
| Receipts | ranked receipt, no double rating | not run | pgTAP/host | `supabase/tests`; R6 |
| Sharing | preview, copy URL, system share, no raw video | pass | emulator+host | `screens/23`–`26`, `app/test/sharing` |
| Sharing | card safe areas 1080×1920 / 1080×1350 | pass | host | `app/test/sharing/result_share_export_test.dart` |
| Backend | RLS + adversarial + idempotency | pass | pgTAP+HTTP | `evidence/supabase_pgtap.txt`, `arena_smoke_e2e.txt` |

## 4. Automated suites (all run in this pass)

| Suite | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | No issues found | `evidence/flutter_analyze_final.txt` |
| `flutter test` | **416/416 passed** | `evidence/flutter_test_final.txt` |
| Deno edge tests | 48/48 passed | `evidence/deno_edge_tests.txt` |
| `supabase db reset` | migrations + seed applied | `evidence/supabase_db_reset.txt` |
| `supabase test db --local` | 184/184 assertions | `evidence/supabase_pgtap.txt` |
| `backend/e2e/arena_smoke.mjs` | 16/16 checks | `evidence/arena_smoke_e2e.txt` |
| `node --test challenge-web/test/link.test.mjs` | 6/6 passed | — |
| `node prototype/scripts/check.mjs` | 10 check groups passed | — |
| `tools/release/secret_scan.mjs` | **3 findings** | R5 |
| `tools/release/check_app_links.mjs --release` | **fails** (no host) | R2 |
| `tools/release/check_artifact_identity.mjs <apk>` | source identity passed | — |

## 5. Integration defects found and fixed

All five were release-blocking for the core loop and now have regression
coverage in the 416-test suite. Reproduction steps are kept here so a failure
is never hidden.

1. **Account feature did not compile** (owner task `06`, repaired here).
   `flutter analyze` reported 23 issues (nullable misuse, missing imports,
   undefined `AccountLoadingRows`/`ArenaProfile`). Repro: run analyze before
   2026-09-18 11:34. Fix: repair imports/nullable flows; analyzer clean.
2. **New accounts never received a durable link** (owner task `05`, repaired
   here). `profile` legitimately returns `link:null` for a new account; the
   client threw `malformed_response` and never read `active_match_id`, so an
   accepted challenge never surfaced. Repro: sign in, send a request, have the
   challenger accept — the waiting screen shows "Could not check for an
   accepted match" forever. Fix: call the documented `link_rotate` action on
   demand; tests in `app/test/linking/challenge_api_test.dart`.
3. **Battle viewer was never known in production** (owner task `07`, repaired
   here). `BattleRuntime.fromConfig` gave the controller a different
   `ValueNotifier` than `runtime.viewer`, so `setViewer` never reached the
   state machine; a receipt could render as a personal loss. Repro: cold
   start, finished receipt with the viewer winning → "@opponent beat me".
   Fix: share one notifier; unknown-viewer receipts render neutral, factual
   copy; tests in `app/test/battle/battle_contract_test.dart`.
4. **Ranked search clock stuck at 0 s** (owner task `08`, repaired here).
   Queue replies carry no `server_now`, so the client never anchored elapsed
   time; the 15-second friend alternative never fired. Repro: Battle → Find an
   opponent; the card stays "0 s / 60 s". Fix: anchor once on the local clock
   when the reply has no clock and reset per search; verified on device
   (`screens/38_small.png` = "16 s / 60 s").
5. **Local email sign-in had no code** (owner task `04`, repaired here).
   Mailpit received a magic link with no numeric token because the local
   template was default. Repro: request a code against the local stack. Fix:
   additive `supabase/templates/magic_link.html` with `{{ .Token }}` and the
   `auth.email.template.magic_link` config entry.

## 6. Blockers (named, with owner and required decision)

| ID | Blocker | Impact | Owner | Required action |
| --- | --- | --- | --- | --- |
| R1 | Physical camera accuracy unvalidated | Blocks camera-counted release; no accuracy claim | task 11 / owner hardware | Execute `docs/camera/CAMERA_QA.md` §4 and sign the checklist |
| R2 | D1 real HTTPS domain missing | App Links unverified; release link check fails | product owner | Supply domain + `assetlinks.json` + fingerprint |
| R3 | Google credentials/redirect absent | Google auth-return path unexecuted | task 11 / owner | Configure provider + `ARENA_AUTH_REDIRECT_URL`, run redirect QA |
| R4 | FCM + Play referrer unavailable locally | Notification and not-installed recovery unexecuted | task 11 | Configure FCM, test-track install, rerun those matrix rows |
| R5 | Secret scan red on synthetic PEM fixtures | CI release gate fails; low exposure risk | task 11 scanner / task 08 fixture | Exclude test fixture paths or replace PEM-shaped data |
| R6 | Ranked device pairing unexecuted | Ranked receipt/rating path rests on tests only | task 11 pilot | Two-device coordinated ranked match and receipt capture |
| R7 | Device matrix is one API 34 emulator | API 24–26, low-end performance, Tensor crash risk unverified | task 11 | Run the physical matrix incl. Tensor checkpoint |
| R8 | Shared checkout uncommitted | Task work is uncommitted on the shared branch | task 11 / L01 | **closed 2026-09-20 by L01** — intended tree captured in the baseline commit (`qa/launch/L01.md`) |

Blocking thresholds from `docs/camera/CAMERA_QA.md` §4.3 remain unmet: the
release must ship with `ARENA_FEATURE_CAMERA_COUNTING=false` and the labelled
demo until R1 and R7 are closed.

## 7. Measured metrics

| Segment | Value | Source |
| --- | --- | --- |
| Tap "Accept challenge" → request row created | 350 ms | DB (`created_at` 16:59:29.577Z) |
| Request sent → accepted (automation-driven) | 19.73 s | DB |
| Both ready → countdown start | 4.93 s | DB `starts_at` 17:00:39.593Z |
| Countdown start → round end | 60.000 s | DB `ends_at` |
| Round end → receipt written | 203 ms | DB `finished_at` 17:01:39.796Z |
| First battle completion (request → receipt) | 130.2 s | DB |
| Matchmaking empty window / alternative | 60 s / 15 s | DB + `screens/38` |
| Rematch rate | 0 of 1 session (not meaningful) | session log |
| Share-sheet opening | confirmed, recorded separately | `screens/26` |
| Confirmed referrals from sharing | 0 | analytics contract; sheet ≠ referral |

The first-battle time above is dominated by deliberate automation gaps; the
per-segment values are the meaningful ones.

## 8. What this report does **not** prove

- No physical-device rep-counting accuracy, false-positive or tracking-loss
  performance claim. Emulator fixtures are supplementary only.
- No production readiness: D1, Google auth, FCM, signing and the real
  Supabase project are still owner decisions (task `11`).
- No claim that the ranked queue pairs live players; that is a pilot item.
- The prototype design checks and media validation reports are design
  evidence, not device accuracy evidence.

## 9. Incident disclosure — accidental command in `D:\Kiro`

While starting the local function server, one detached command inherited the
session default working directory `D:\Kiro` instead of `D:\TrainingArena` and
briefly served that checkout's functions (port 54821, functions `coach`,
`validate_purchase`). Detection was immediate; the process was killed
(`Stop-Process` on PID 6792) and the container it started was returned to its
prior stopped state (`docker stop supabase_edge_runtime_Kiro`). No source file
in `D:\Kiro` was intentionally opened or edited; the Supabase CLI may have
touched its own runtime state under `D:\Kiro\supabase\.temp`. All later
commands were re-run with an explicit working directory, and all TrainingArena
operations used `D:\TrainingArena` only.

## 10. Handoff to task `11`

1. Treat R1–R7 as release-gate items with the owners above; R5 is safe to fix
   immediately (scanner allowlist for test fixtures).
2. Do not enable camera counting or claim accuracy until the signed
   `qa/camera/device_validation_checklist.md` exists.
3. Reuse `qa/integration/tools/api_probe.mjs` and `alice_heartbeat.mjs` for the
   pilot's local verification; they only sign local development JWTs.
4. The 416-test suite and the five regression tests are the acceptance
   baseline for any further integration work.
