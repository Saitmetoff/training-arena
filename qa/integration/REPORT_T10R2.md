# Task 10 round 2 — emulator QA re-run, two defect fixes

Date: 2026-09-24 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Branch: `codex/training-arena` · Start commit: `fd0326f` (F3) · Round 1:
`qa/REPORT.md` (2026-09-18) and `qa/integration/results.json`.

Owner request: finish the stalled round-2 integration pass and record it.
Round 2 re-ran the task-10 checks on the current tree (after the F1–F4 camera
work), captured the emulator walkthrough in
`qa/integration/evidence/t10r2/`, and fixed two defects it found. **No
production, accuracy or camera claim is made.**

## Verdict

| Area | Result |
| --- | --- |
| Emulator walkthrough: cold link → sign-in → request → accept → preparation → camera permission → ready gate | PASS — `evidence/t10r2/01…13` (captured 2026-09-24 12:22–12:32) |
| Defect D6 — prelive forfeit (server) | FIXED — migration + 4 pgTAP assertions; smoke 24/24 |
| Defect D7 — forfeit result copy (app) | FIXED — widget test; device re-capture **pending** |
| `flutter analyze` / full suite | PASS — clean, **593/593** + 2 skipped (592 before, +1 for D7) |
| pgTAP (`supabase test db`) | PASS — 4 files, **194 assertions** (190 before, +4 for D6) |
| HTTP e2e smoke with `ARENA_DISPATCHER_SECRET` | PASS — **24/24** |
| QA APK rebuilt with both fixes | PASS — `app-release.apk`, 91 729 591 bytes, SHA-256 `4BF32EA0…14C7F` |
| Fixed result screen re-captured on the emulator | **NOT RUN** — needs the sign-in redone after `db reset`; steps in §5 |
| Deno edge-function suites | NOT RUN — `deno` is not available in this shell; `supabase/functions/` is unchanged |
| R1 / R2 / R6 / R7 | **OPEN** — unchanged, see §5 |

## 1. Defects found and fixed

### D6 — an early-ready player was forfeited at live start (server)

Repro (emulator, 2026-09-24 12:32): both players confirmed ready; the match
turned live and closed **0.44 s later** as `opponent_absent`/`win` even though
both players had `ready = tracking = practice_complete = true`. Evidence:
`evidence/t10r2/defect_prelive_forfeit_match.txt` (match `6fa19e2b…`,
`starts_at` 07:32:25.563, `finished_at` 07:32:26.007).

Cause: readiness is the presence proof during preparation and countdown. A
player who readied more than ten seconds before the countdown ended (for
example while the other player finished the practice rep) was already "stale"
when `arena_match_tick` promoted the match to live, so the first live tick
forfeited them without the documented ten-second recovery window
(`docs/API.md` §5: "One player absent for more than 10 seconds forfeits").

Fix: `supabase/migrations/20260924090000_arena_live_start_presence.sql`
replaces `arena_match_tick`; at the countdown → live promotion both active
players' presence is lifted to the **live start time**
(`greatest(last_seen_at, starts_at)`), so the recovery window starts when live
starts. Mid-round and end-of-round absence rules are unchanged.

The first version of this fix stamped `clock_timestamp()` (the sweep clock).
Because the promotion is lazy — it happens on the first sweep after
`starts_at`, which can be many seconds later — that hid a **shared outage**
that began before live: the smoke's "both clients gone" check failed and the
match stayed `live`. It was replaced with the `greatest(last_seen_at,
starts_at)` lift above; both behaviours are now pinned by pgTAP (§3).

### D7 — a forfeit receipt read "beat me by 0" (app)

Repro (same session): the result screen for the D6 match showed
`@fixture_alice beat me by 0` with both scores 0 — a forfeit decides the match
without a scored round, so a margin of 0 is never true. Evidence:
`evidence/t10r2/14_result_opponent_absent_defect.png` / `.xml`.

Fix: `app/lib/battle/ui/battle_flow_page.dart` (`_ResultBody`) recognises
`opponent_absent`, `abandoned_preparing` and `service_outage` reasons and uses
forfeit copy ("@x didn't finish — win confirmed" / "I didn't finish — @x
wins") instead of a score margin. Regression:
`app/test/battle/battle_contract_test.dart` "a forfeit receipt never claims a
zero-margin score".

## 2. Round-2 emulator evidence (captured before the fixes)

| File | Step |
| --- | --- |
| `01_cold_link_signed_out.png/.xml` | cold challenge link, signed out |
| `02_cold_link_resolved.png/.xml` | link resolves to the exact challenger |
| `03_email_form.xml`, `04_code_entry.xml`, `05_after_verify.xml`, `05b_username.xml`, `06_after_username.xml`, `06_challenge_after_signin.png` | email-code sign-in returns to the same challenge |
| `07_request_sent.xml`, `api_inbox_before_accept.txt`, `api_accept.txt` | request sent; accepted through the API fixture |
| `10_preparing.xml/.png`, `10b_camera_permission.xml`, `11_preparing.xml`, `12_prep_screen.xml`, `12b_prep_scrolled.xml`, `12_preparation_camera.png` | preparation screen and camera permission |
| `13_ready_gate.xml`, `13_ready_blocked.png/.xml` | the app refuses ready until the practice rep (honest gate) |
| `api_ready_alice.txt`, `api_ready_recipient.txt`, `alice_heartbeat.log` | both-ready countdown driven by the API fixture |
| `14_result_opponent_absent_defect.png/.xml` | the D7 defect screen |
| `defect_prelive_forfeit_match.txt` | the D6 database state |

The walkthrough steps 01–13 were re-verified in this round; the **fixed**
result screen was not re-captured on the emulator (see §5).

## 3. Verification commands and results

| Command | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | No issues found | this report |
| `flutter test` | **593 passed, 2 skipped** | this report |
| `supabase db reset` | migration applied cleanly from scratch | `evidence/t10r2/supabase_db_reset.txt` |
| `supabase test db` | **194/194** (4 files) | `evidence/t10r2/supabase_pgtap.txt` |
| `ARENA_API=http://127.0.0.1:54521 ARENA_DISPATCHER_SECRET=… node backend/e2e/arena_smoke.mjs` | **24/24** — before the D6 lift it failed 2 checks (`arena_smoke_e2e_before_fix.txt`) | `evidence/t10r2/arena_smoke_e2e.txt` |
| `qa/integration/evidence/t10r2/build_qa_apk.cmd` | built 91 729 591 B, SHA-256 `4BF32EA0…14C7F` | `evidence/t10r2/apk_build_qa_release.txt` |
| `adb devices -l` | emulators only; no physical device | — |

The 4 new pgTAP assertions: early readiness never forfeits at live start; no
forfeit receipt is written at live start; absence during live still forfeits;
and a shared outage across the live start still closes as
`no_result`/`service_outage`.

## 4. Environment notes

- `supabase db reset` is a smoke prerequisite (the smoke assumes the seed).
  It wiped the QA account created during the 12:22–12:32 walkthrough, so the
  emulator app's stored session is now invalid — this is why the fixed result
  screen must be re-captured after a fresh sign-in.
- `supabase functions serve` must run with `--env-file supabase/.env.local`
  for the dispatcher checks; without it the smoke reports
  `dispatcher_not_configured` and the outage checks cannot pass.
- The running edge runtime answered the dispatcher boundary in this round;
  the failing `before_fix` smoke was caused by the serve instance that
  predated the env file plus the D6 stamping bug.

## 5. Remaining work and blockers

1. **D7 device re-verification** (this round): re-install the rebuilt QA APK,
   sign in again (the local DB was reset), run the D6 scenario
   (both ready → viewer absent > 10 s → dispatcher sweep) and capture the
   result screen; expected copy is the forfeit headline, never "beat me by 0".
2. **R1 — physical-device camera accuracy**: unchanged; F3's traced session on
   the Redmi 10 (`qa/competitive/f3/RUNSHEET.md`) is the input.
3. **R2 — real HTTPS link domain**; **R6 — ranked pairing on two live
   clients**; **R7 — device matrix beyond one API 34 emulator**: unchanged.
4. **Deno suites** were not re-run here (not installed in this shell); the
   edge functions are unchanged in this round, so round 1's results stand.

No simulated fixture is presented as device accuracy or production readiness.
