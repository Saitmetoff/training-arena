# Training Arena fix log

## Final verification result and stop decision

All WP rows are now terminal: WP0 DONE, WP1 BLOCKED, WP2 BLOCKED, WP3 DONE, WP4 DONE. One commit per WP exists on codex/training-arena, as shown by the logged git log. No further implementation work or reruns are performed after final verification.

- Final `flutter analyze` (pinned path) exit 0, no issues.
- Final `flutter test --reporter expanded` exit 1: 637 passed, two skipped, three retained WP1 failures. The logged final command includes the complete AFTER table, all seed counts and rejection/outcome histograms. No failing test was weakened/deleted.
- Final existing release hold check exit 0.
- Final `rtk proxy powershell -NoProfile -Command "supabase db reset --local"`: NOT RUN. The fresh Docker version probe confirms the Linux engine pipe is unavailable. The WP2 reset attempt failed before database execution. The unchanged failing command is not repeated.
- Final `rtk proxy powershell -NoProfile -Command "supabase test db --local"`: NOT RUN. No local PostgreSQL at the configured port; prior exact attempt/connection refusal is recorded in WP2. No hosted project is supplied or used.
- Final `rtk proxy deno test supabase/functions/arena/tests supabase/functions/arena-dispatcher/tests`: NOT RUN. Fresh Get-Command probe returned False; Deno is absent.
- Physical-device validation and audibility: NOT RUN. No real traces supplied. beta_device_results remains blocked, devices empty.

WP1's specific retained failures: missing selected-side ankle test expects 0 but readable far-side counting produces 1; shallow replay expects none but returns notDeepEnough; noise seed 4 has only 9 outcomes for 10 descents. WP2 additionally has protected test-1 SQL version fixtures and signature-only avatar fixtures incompatible with the required hardening. Those conflicts are source evidence, not claims of a native Deno/pgTAP run.

### Final BEFORE versus AFTER (SYNTHETIC, extracted from real logged outputs)

| SYNTHETIC scenario | BEFORE mean /10 | AFTER mean /10 |
| --- | --- | --- |
| push 3.0s | 10.0 | 10.0 |
| push 2.1s | 10.0 | 10.0 |
| push 1.6s | 8.4 | 10.0 |
| push 1.2s | 1.0 | 10.0 |
| push 1.0s | 1.0 | 10.0 |
| push 0.8s | 0.0 | 10.0 |
| push 0.6s diagnostic | 0.0 | 10.0 |
| push 150-95 | 0.0 | 9.6 |
| push 8fps | 0.4 | 10.0 |
| push 10fps | 0.6 | 10.0 |
| push 30fps | 10.0 | 10.0 |
| push noise .02 | 5.8 | 9.8 |
| push y*.75 | 1.0 | 10.0 |
| push bottom115 | 0.0 | 0.0 |
| push partial122 | 0.0 | 0.0 |
| squat 1.2s | 2.0 | 10.0 |
| squat 1.6s | 0.0 | 10.0 |
| squat 2.1s | 10.0 | 10.0 |
| squat 3.0s | 10.0 | 10.0 |

All values above are mean counted out of 10 across five seeds; they are not accuracy numbers or device measurements. Owner actions are in NEEDS_OWNER_ACTIONS.md. Follow-up: separately review existing unverified UGC model/quota/biomechanics claims outside this run's guardrail scope. Final audit documents are intentionally left in the working tree after the five WP commits so no extra implementation commit or verification rerun is created.

WP4 end verification: full analyze exit 0, full test 637 passed / two skipped / three retained WP1 failures. Requirement-by-requirement audit is in `docs/audit/COMPLETION_AUDIT.md`. WP2 protected SQL fixture versions are inspected in the exact logged source-inventory command; strict version acceptance must not be weakened to preserve unsupported fixture versions.

## WP4 outcome

Five targeted acceptance tests passed (logged exact command/output): every internal CounterRejection has a non-empty plain-language helper, every TrackingPauseReason has non-empty copy for both exercises, battle preparation and solo intro/practice show the exact placement text, and a counted SYNTHETIC practice rep sends one SystemSound click plus one lightImpact haptic. Shallow and duplicate frames do not add cue calls. No new package, applicationId change or release-default change. Physical sound/haptic audibility: NOT RUN; no physical session. Owner action if built-in feedback is insufficient: choose an audio package.

WP3 and WP4 scoped changes do not resolve WP1's retained failures. The required full checks below report those failures honestly. Owner steps for all explicitly excluded tasks are collected in `docs/audit/NEEDS_OWNER_ACTIONS.md`.

WP4 targeted attempt 1: new placement widget test incorrectly awaited the existing void `SoloController.startCamera`, producing the logged compile error. Attempt 2 calls the synchronous API, then advances its existing ManualBattleClock and pumps the async camera opening. The new feedback fixture now includes an actual duplicate timestamp; count/cue assertions are unchanged. No protected existing test was edited.

## WP3 scope interpretation and preservation

Hard gates section added to the owner's existing untracked UGC draft. The instruction to remove multiple-account quota multiplication is treated as the only permitted edit outside that new section: exactly five phrases changed, all other content preserved by the one-shot script. The owner's entire untracked draft is not staged; only our diff is committed as `docs/audit/WP3_UGC_GUARDRAILS.patch`. No platform quota, commercial terms, identity or contact value was invented. The pre-existing .gitignore owner hunk is preserved and only our personal-PDF rule is staged via a separate index patch.

The HTML privacy draft begins with an HTML comment containing the exact review notice, and its first visible main content shows the same notice; this keeps the HTML doctype intact. The Markdown inventory begins with the exact plain-text notice. No legal wording or [[OWNER: ...]] values changed. `git ls-files tmp/pdfs` returned no tracked paths, so no personal file was opened or described and no history-removal action is needed from that check.

Public output checks include every challenge-web file, fault-web/public, export output when present, Next static assets and public prerender payloads. The passing/failing fixtures passed; the real gate's exit 1 is the required refusal while 11 files contain owner placeholders. Owner must finish those values before publication. No website content or release flag defaults changed. CI's release-candidate job now invokes the new gate. Existing protected release-hold tests passed.

WP2 verification: `rtk proxy deno test supabase/functions/arena/tests supabase/functions/arena-dispatcher/tests` NOT RUN (Deno absent). `supabase db reset --local` and `supabase test db --local` were invoked but database operations/tests did NOT RUN because the local engine/port is unavailable. No retry of unchanged failing infrastructure commands within WP2. Flutter end analysis exit 0; full test retains the same three WP1 failures. The avatar source passed Node's syntax-only check; this does not establish Deno type checking or runtime behavior. Backup script created and verified `D:\TrainingArena-WP2.bundle`, containing committed history through WP1; owner should run it again after all WP commits to capture the final committed history.

## WP2 assumptions and limitations

Supabase skill documentation: queried official pgTAP/local test docs through Supabase MCP; read the changelog index and the linked Postgres 15.19/17.11 breaking-change notice. The new migration does not use affected ltree/btree_gist indexes or legacy ciphers. Documentation sources: https://supabase.com/docs/guides/local-development/testing/overview and https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes. Context7 supplied official Flutter built-in feedback API references earlier in this run.

New migration created by the installed CLI, never by editing an applied migration. New allow-list has RLS/no client grants; existing service-role RPC boundary retained with explicit revoked client execute grants. Per-player row locks serialize rep quotas; per-user profile locks serialize analytics quotas. AR017 maps to existing `rate_limited` in errors.ts. Header layouts checked against primary PNG/WebP specifications; no new dependency or full decoder added.

Compatibility blocker: the actual old wire version is `arena-counter/1.2.1`, which cannot satisfy the requested exact semantic-version regex. It is seeded in the inventory along with `1.3.0`, but raw legacy clients fail closed. No invented compatibility exception. Existing Deno avatar tests accept signature-only byte arrays (PNG 8 bytes, JPEG 6, WebP 12) whose dimensions cannot be parsed. Those protected tests are preserved; a complete Deno run is expected to expose this conflict and needs an owner decision. Deno tests: NOT RUN because deno is not installed. Hosted Supabase: NOT RUN, owner setup explicitly excluded. Local database execution is unavailable while Docker's Linux engine pipe is missing; commands are attempted and recorded below.

WP1 end checks: full test finished with 632 passed, two skipped and three failures (matrix silent descent plus the two protected assertions). Full analysis found five informational lints in new audit tests; required console printing is explicitly documented with a file-level avoid_print exception, and brace lints are repaired in the new replay tooling. No counter behavior or protected tests changed for these lint repairs.

## WP1 decision and bounded tuning

The preceding goal turn made progress: engine changes, BEFORE/AFTER measurements and five passing SYNTHETIC acceptance/HUD tests were written to authoritative files. The interrupted test handle was revalidated and completed with exit 0; it was not restarted.

WP1 BLOCKED. Two implementation edits touched the attempt state machine. A third rewrite would violate the explicit stop rule, so no further counter tuning is performed. Exact failures are retained below. Best hypotheses: an invalid/noisy frame suppresses one descent without producing an outcome (seed 4, amplitude .02); protected legacy tests intentionally expect primary-side failure and silent shallow rejection, contradicting the new full-chain selection and named shallow-outcome requirements. These tests remain unchanged.

| Attempt | tau / dwell / duration (ms) | Push bands | Squat bands | re-descent qualification | noise mean /10 | outcome evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 60 / 60 / 250 | 105/145 | 105/155 | peak fall 8° | 5.8 | false repeated lockout events |
| 2 | 60 / 60 / 250 | 105/145 | 105/155 | enter+20 then enter | 9.8 | seed 4 only 9 outcomes/10 descents |

Bounce 80 ms fixture remains unchanged and passed in both targeted runs; no dwell tuning was needed. Geometry/side/timeout/HUD checks passed in the exact logged command. Counter version changes from the actual old `arena-counter/1.2.1` to semantic `1.3.0`; WP2 must handle the old wire prefix explicitly because the requested strict semver regex excludes it. Real-device session: NOT RUN, no physical phone traces supplied. Device record remains blocked.

WP1 allowed existing fixture edit: `rep_counter_test.dart` too-fast fixture 300/200/300 ms → 120/0/120 (attempt 1, smoothing masked the bottom, last rejection none) → 0/160/0 plus 300 ms top hold (attempt 2). This is a genuinely short bottom-to-lockout rep; the original repTooFast and zero-count assertions stay unchanged. Bounce fixture untouched.

WP1 attempt 1 tuning: tau 60 ms, push bands 105/145, squat 105/155, duration 250 ms, dwell 60 ms. Noise .02 failed (mean 5.8); false re-descents also broke squat/reacquisition fixtures. Attempt 2 qualifies re-descent only after rising above enter+20 then returning below enter; resets smoothing on tracking loss. Dwell remains 60.

WP1 measurement correction: the first BEFORE portrait row used `likelihood` instead of the bridge's actual `l` key, so that row was invalid (all joints had confidence zero). Corrected the new fixture only and reran the unchanged counter. Use the corrected BEFORE section below. The measured tempo rows differ from the independent Python expectations; no tuning to those expected counts.

All synthetic results are labeled SYNTHETIC. Real-device results must not be inferred from these tests.

## Initial tree (before edits)

Command: `rtk git status --short`
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
 M .gitignore
 M docs/social/briefs/BRIEF-03-ai-dramatization.md
?? 1.txt
?? design/fault-website/
?? docs/FAULT_OPENCODE_WORKFLOW.md
?? docs/FAULT_WEBSITE_PLAN.md
?? docs/FAULT_WEBSITE_PROMPTS.md
?? docs/fault-website/
?? docs/research/FREE_UGC_VIDEO_CREATION_2026-10-03.md
?? docs/social/UGC_VIDEO_GENERATION_STRATEGY.md
?? docs/strategy/
?? fault-web/
?? prompts/fault-website/
?? supabase/migrations/20261004112705_fault_waitlist_stage3.sql
?? supabase/migrations/20261004161500_fault_waitlist_preview_isolation.sql
?? tmp/
?? tools/social/
```

Command: `rtk git log -5 --oneline`
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
28d64ab Finish solo-first beta flow, shared camera geometry and fresh rematches
54ba2a4 docs(research): add the rep-counter OSS/app landscape and adoption notes
c29483b feat(camera): add the squat heels-lifted coaching cue from the OSS reference
65af4c2 fix(camera): normalise ML Kit pixel landmarks in the bridge
db349ae feat(camera): use the front camera and mirror the preview
```

The initial .gitignore change and untracked owner files must be preserved. No remote, device, or hosted results are assumed.

WP0 notes: Flutter on PATH was NOT RUN (rtk could not resolve it). Both documented pinned-path discovery commands succeeded; the first runner printed a Windows encoding error after saving the successful command output, corrected by configuring UTF-8 stdout. Read all specified camera files, counter/fixture tests, synthetic generator and F3 RUNSHEET. Baseline analysis/test above also serve the required WP0 end checks (read-only WP).

## WP0 pinned Flutter discovery attempt 1

Command: `rtk proxy powershell -NoProfile -Command "& 'D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat' --version"`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings

┌─────────────────────────────────────────────────────────┐
│ A new version of Flutter is available!                  │
│                                                         │
│ To update to the latest version, run "flutter upgrade". │
└─────────────────────────────────────────────────────────┘
Flutter 3.47.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6a19cca564 (4 weeks ago) • 2026-09-17 14:13:22 -0400
Engine • hash ab598368592da0064197e2bc15c7f5b0a2c6bb1f (revision af7e796e16) (25 days ago) • 2026-09-16 18:35:09.000Z
Tools • Dart 3.13.4 • DevTools 2.60.0

```

## WP0 pinned Flutter discovery attempt 2

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat --version`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Waiting for another flutter command to release the startup lock...
Flutter 3.47.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6a19cca564 (4 weeks ago) • 2026-09-17 14:13:22 -0400
Engine • hash ab598368592da0064197e2bc15c7f5b0a2c6bb1f (revision af7e796e16) (25 days ago) • 2026-09-16 18:35:09.000Z
Tools • Dart 3.13.4 • DevTools 2.60.0

```

## WP0 baseline flutter analyze

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing app...                                                
No issues found! (ran in 20.9s)

```

## WP0 baseline flutter test

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/account/account_api_test.dart
00:00 +0: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport fetchProfile posts the action envelope with bearer and anon key
00:00 +1: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport unconfigured builds never touch the network
00:00 +2: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a missing token fails closed as unauthenticated
00:00 +3: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport transport failures surface as retryable network errors
00:00 +4: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a TLS handshake failure is an offline retry, not a raw IO error
00:00 +5: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport 401 answers are unauthenticated; 500 answers are retryable
00:00 +6: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport business errors use the server code and actionable copy
00:00 +7: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +8: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +9: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +10: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +11: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +12: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +13: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +14: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing a win without a winner id is dropped
00:00 +15: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +16: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block publicProfile never surfaces extra private fields
00:00 +17: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a rejected session fails closed to signed out with plain copy
00:00 +18: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block report sends target, optional match and the reason
00:00 +19: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +20: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +21: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle accessToken returns the stored token when refresh is offline
00:00 +22: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block deleteAccount posts the documented action
00:00 +23: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block deleteAccount posts the documented action
00:00 +24: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in Google sign-in loads the profile and refreshes the viewer
00:00 +25: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in a first sign-in without a username stays in the username step
00:00 +26: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in email-code sign-in asks for the code and never keeps the address
00:00 +27: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in cancellation surfaces the plain provider message
00:00 +28: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim normalizes before sending and updates the viewer
00:00 +29: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim an unchanged name is a no-op without a round trip
00:00 +30: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim a server race reports an actionable duplicate message
00:00 +31: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim invalid local input never reaches the backend
00:00 +32: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim claiming before sign-in fails closed
00:00 +33: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar accepts a valid image and sends sniffed base64
00:00 +34: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects camera frames before any upload
00:00 +35: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +36: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +37: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +38: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +39: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +40: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +41: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +42: D:/TrainingArena/app/test/account/account_durable_session_test.dart: deleteAccount does not claim durable removal when storage fails
00:00 +43: D:/TrainingArena/app/test/account/account_durable_session_test.dart: a failed server deletion keeps the valid session
00:00 +44: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a refresh that finishes after sign-out cannot resurrect the session
00:00 +45: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out drops the session immediately, before the gateway answers
00:00 +46: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +47: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +48: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +49: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +50: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername isSame compares normalized names without case
00:00 +51: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a newer identity does not join the prior account pending refresh
00:00 +52: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername valid names pass at both length bounds
00:00 +53: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +54: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +55: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalized input is what the backend receives
00:00 +56: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +57: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +58: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +59: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +60: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits camera-like raw bytes are never a supported image
00:00 +61: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +62: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +63: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +64: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +65: D:/TrainingArena/app/test/account/account_models_test.dart: AccountException classifies unauthenticated and retryable failures
00:00 +66: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering PKCE ordering holds for a delayed write, clear and newer write
00:00 +67: D:/TrainingArena/app/test/account/account_models_test.dart: AccountException toString never carries a message, token or email
00:00 +68: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +69: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +70: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +71: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a superseded sign-in cannot persist over the newer account
00:00 +72: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +73: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a pending refresh cannot overwrite a newer sign-in in storage
00:00 +74: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed logout cannot erase a verifier saved after it
00:00 +75: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: Google sign-in returns to the same challenge and claims a username
00:00 +76: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: email-code sign-in keeps the same token through both prompts
00:00 +77: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: a duplicate username re-prompts without losing the challenge
00:00 +78: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: restart restores the waiting challenge with the same token
00:00 +79: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController loads exactly the confirmed rows
00:00 +80: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an empty ladder is an honest empty state, not an error
00:00 +81: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController the viewer row outside the top page is surfaced as-is
00:00 +82: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an offline refresh keeps the last confirmed page
00:00 +83: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController a server error is not retryable and keeps the confirmed page
00:00 +84: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an unconfigured build reports the flag without inventing rows
00:00 +85: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController reset drops every row and goes back to initial
00:00 +86: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController loads confirmed receipts unchanged
00:00 +87: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an empty history is an honest empty state
00:00 +88: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an offline refresh keeps the last confirmed receipts
00:00 +89: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController reset drops every receipt on sign-out
00:01 +90: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a Google redirect after process death returns to the same challenge
00:01 +91: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: an email-code sign-in after process death keeps the same challenge
00:01 +92: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a redirect that does not match the allowlist is ignored
00:01 +93: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +94: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +95: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +96: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +97: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +98: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +99: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +100: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +101: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +102: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +103: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +104: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +105: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +106: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +107: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +108: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +109: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +110: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +111: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +112: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +113: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +114: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +115: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +116: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +117: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +118: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +119: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +120: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +121: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +122: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +123: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +124: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +125: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +126: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +127: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +128: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +129: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +130: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +131: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +132: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +133: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +134: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +135: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +136: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +137: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +138: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +139: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +140: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +141: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +142: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +143: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +144: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +145: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +146: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +147: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +148: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +149: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +150: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +151: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +152: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +153: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +154: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +155: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +156: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +157: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +158: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +159: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +160: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +161: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +162: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +163: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +164: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +165: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +166: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +167: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +168: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +169: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +170: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +171: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +172: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +173: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +174: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +175: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +176: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +177: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +178: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +179: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +180: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +181: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +182: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +183: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +184: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +185: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +186: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +187: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +188: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +189: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +190: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +191: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +192: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +193: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +194: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +195: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +196: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +197: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +198: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +199: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +200: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +201: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +202: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +203: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +204: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +205: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +206: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +207: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +208: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +209: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +210: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +211: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +212: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +213: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +214: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +215: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +216: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +217: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +218: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +219: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +220: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +221: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +222: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +223: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +224: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +225: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +226: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +227: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +228: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +229: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +230: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +231: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +232: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +233: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +234: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +235: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +236: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +237: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +238: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +239: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +240: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +241: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +242: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +243: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +244: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +245: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +246: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +247: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +248: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +249: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +250: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +251: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +252: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +253: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +254: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +255: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +256: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +257: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +258: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +259: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +260: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +261: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +262: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +263: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +264: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +265: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +266: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +267: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +268: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +269: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +270: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +271: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +272: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +273: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +274: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +275: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +276: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +277: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +278: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +279: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +280: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +281: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +282: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +283: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +284: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +285: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +286: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +287: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +288: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +289: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +290: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +291: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +292: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +293: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +294: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +295: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +296: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +297: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +298: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +299: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +300: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +301: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +302: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +303: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +304: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +305: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +306: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +307: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +308: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +309: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +310: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +311: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +312: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +313: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +314: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +315: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +316: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +317: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +318: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:07 +319: D:/TrainingArena/app/test/camera/camera_preview_test.dart: the front-camera preview and the skeleton are mirrored together
00:07 +320: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +321: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +322: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +323: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +324: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +325: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +326: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +327: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +328: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +329: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +330: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +331: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +332: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +333: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +334: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +335: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +336: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +337: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:08 +337: D:/TrainingArena/app/test/camera/generate_pose_fixtures_test.dart: regenerates the committed pose fixtures
  Skip: set FIXTURE_GEN=1 to regenerate
00:08 +337 ~1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:08 +338 ~1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +338 ~1: D:/TrainingArena/app/test/camera/overlay_paint_cost_test.dart: overlay paint cost, host only
  Skip: set OVERLAY_BENCH=1 to measure
00:08 +338 ~2: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +339 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +340 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +341 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +342 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +343 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +344 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +345 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +346 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +347 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +348 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +349 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +350 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +351 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +352 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +353 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +354 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +355 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +356 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +357 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +358 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +359 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +360 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +361 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +362 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +363 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +364 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +365 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:08 +366 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:08 +367 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:08 +368 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:08 +369 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +370 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +371 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +372 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +373 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +374 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +375 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +376 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +377 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +378 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +379 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +380 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +381 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +382 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +383 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +384 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +385 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +386 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +387 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +388 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +389 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +390 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +391 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +392 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +393 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +394 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +395 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +396 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +397 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +398 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +399 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +400 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +401 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +402 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +403 ~2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the selected chain is painted in lime
00:09 +404 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +405 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +406 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +407 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +408 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +409 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +410 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +411 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +412 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +413 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +414 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +415 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +416 ~2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +417 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +418 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +419 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +420 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +421 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +422 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +423 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +424 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +425 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +426 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +427 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +428 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +429 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +430 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +431 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +432 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +433 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +434 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +435 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +436 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +437 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +438 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +439 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +440 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +441 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +442 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +443 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +444 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +445 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +446 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +447 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +448 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +449 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +450 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +451 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +452 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +453 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +454 ~2: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +455 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +456 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +457 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +458 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +459 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +460 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +461 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +462 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +463 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +464 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +465 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +466 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +467 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +468 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +469 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +470 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +471 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +472 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +473 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +474 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +475 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +476 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +477 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:11 +478 ~2: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:11 +479 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +480 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +481 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +482 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +483 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +484 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +485 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +486 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:11 +487 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +488 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +489 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +490 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +491 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +492 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +493 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +494 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +495 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +496 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +497 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +498 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +499 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +500 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +501 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +502 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +503 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +504 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +505 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +506 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +507 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +508 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +509 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +510 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +511 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +512 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +513 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +514 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +515 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +516 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +517 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +518 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +519 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +520 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +521 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +522 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +523 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +524 ~2: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +525 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:12 +526 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +527 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +528 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +529 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +530 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +531 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +532 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +533 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +534 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +535 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +536 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +537 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +538 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +539 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +540 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +541 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +542 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +543 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +544 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +545 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +546 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +547 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +548 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +549 ~2: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +550 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +551 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +552 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +553 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +554 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +555 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +556 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +557 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +558 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +559 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +560 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +561 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +562 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +563 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +564 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +565 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +566 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +567 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +568 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +569 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +570 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +571 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +572 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:13 +573 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +574 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +575 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +576 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +577 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +578 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +579 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +580 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +581 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +582 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +583 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +584 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +585 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +586 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +587 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:13 +588 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +589 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +590 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +591 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +592 ~2: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +593 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +594 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +595 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +596 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +597 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +598 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +599 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +600 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +601 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +602 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +603 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +604 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +605 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +606 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +607 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +608 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +609 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:14 +610 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +611 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +612 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +613 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +614 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +615 ~2: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +616 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:15 +617 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:15 +618 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:15 +619 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:15 +620 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:15 +621 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:15 +622 ~2: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:15 +623 ~2: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:15 +624 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry opens the solo page when the flag is on
00:15 +625 ~2: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: manual entry reaches a labelled result and saves
00:16 +626 ~2: All tests passed!

```

## WP1 SYNTHETIC BEFORE unchanged counter matrix

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter/counter_stress_matrix_test.dart --dart-define=STRESS_BASELINE=true --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart
00:00 +0: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC BEFORE | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {}
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.6s | 8.4 | [7, 7, 9, 9, 10] | {dwellTooShort: 2}
push 1.2s | 1.0 | [1, 1, 1, 1, 1] | {}
push 1.0s | 1.0 | [1, 1, 1, 1, 1] | {}
push 0.8s | 0.0 | [0, 0, 0, 0, 0] | {}
push 0.6s diagnostic | 0.0 | [0, 0, 0, 0, 0] | {}
push 150-95 | 0.0 | [0, 0, 0, 0, 0] | {}
push 8fps | 0.4 | [0, 1, 0, 1, 0] | {}
push 10fps | 0.6 | [1, 0, 1, 1, 0] | {}
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {}
push noise .02 | 5.8 | [6, 6, 5, 5, 7] | {dwellTooShort: 6, repTooFast: 2}
push y*.75 | 0.0 | [0, 0, 0, 0, 0] | {}
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {}
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {}
squat 1.2s | 2.0 | [1, 4, 2, 2, 1] | {dwellTooShort: 1}
squat 1.6s | 0.0 | [0, 0, 0, 0, 0] | {repTooFast: 50}
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {}
00:00 +1: All tests passed!

```

## WP1 SYNTHETIC BEFORE corrected bridge fixture unchanged counter

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter/counter_stress_matrix_test.dart --dart-define=STRESS_BASELINE=true --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart
00:00 +0: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC BEFORE | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {}
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.6s | 8.4 | [7, 7, 9, 9, 10] | {dwellTooShort: 2}
push 1.2s | 1.0 | [1, 1, 1, 1, 1] | {}
push 1.0s | 1.0 | [1, 1, 1, 1, 1] | {}
push 0.8s | 0.0 | [0, 0, 0, 0, 0] | {}
push 0.6s diagnostic | 0.0 | [0, 0, 0, 0, 0] | {}
push 150-95 | 0.0 | [0, 0, 0, 0, 0] | {}
push 8fps | 0.4 | [0, 1, 0, 1, 0] | {}
push 10fps | 0.6 | [1, 0, 1, 1, 0] | {}
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {}
push noise .02 | 5.8 | [6, 6, 5, 5, 7] | {dwellTooShort: 6, repTooFast: 2}
push y*.75 | 1.0 | [1, 1, 1, 1, 1] | {}
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {}
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {}
squat 1.2s | 2.0 | [1, 4, 2, 2, 1] | {dwellTooShort: 1}
squat 1.6s | 0.0 | [0, 0, 0, 0, 0] | {repTooFast: 50}
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {}
00:00 +1: All tests passed!

```

## WP1 attempt 1 SYNTHETIC AFTER and counter regressions

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter/counter_stress_matrix_test.dart test/camera/rep_counter_test.dart test/camera/fixture_replay_test.dart test/camera/front_view_test.dart --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart
00:00 +0: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +2: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +5: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +5 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +5 -1: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter rejects a rep completed too fast [E]
  Expected: CounterRejection:<CounterRejection.repTooFast>
    Actual: CounterRejection:<CounterRejection.none>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 172:7             main.<fn>.<fn>
  
00:00 +6 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +6 -2: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +6 -2: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 198:7             main.<fn>.<fn>
  
00:00 +7 -2: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +8 -2: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +8 -3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +8 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter tracking loss resets the in-progress rep and surfaces the reason [E]
  Expected: <1>
    Actual: <0>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 251:7             main.<fn>.<fn>
  
00:00 +9 -3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +10 -3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +11 -3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +11 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +11 -4: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a detector stall resets the rep and requires reframing [E]
  Expected: <1>
    Actual: <0>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 284:7             main.<fn>.<fn>
  
00:00 +12 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +13 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +14 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +15 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +16 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +17 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +18 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +19 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +20 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +21 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +22 -4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {lockoutMissed: 2}
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {}
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {}
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {}
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2}
push 8fps | 9.6 | [10, 9, 10, 10, 9] | {lockoutMissed: 2}
00:00 +22 -5: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
push 10fps | 9.8 | [10, 9, 10, 10, 10] | {lockoutMissed: 1, dwellTooShort: 1}
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {}
00:00 +22 -5: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: squat counts with head and feet out of frame [E]
  Expected: <1>
    Actual: <0>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 103:5          main.<fn>
  
00:00 +22 -5: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
push noise .02 | 5.8 | [8, 7, 2, 7, 5] | {lockoutMissed: 39, notDeepEnough: 1, dwellTooShort: 1}
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {}
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {}
00:00 +23 -5: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {}
squat 1.2s | 9.6 | [10, 9, 10, 9, 10] | {lockoutMissed: 2}
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {lockoutMissed: 6}
squat 2.1s | 9.8 | [10, 9, 10, 10, 10] | {lockoutMissed: 26, dwellTooShort: 1}
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {lockoutMissed: 44}
00:00 +23 -6: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: front push-up counts with head out of frame
00:00 +23 -6: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: [
              'push noise .02 seed 1 counted 8',
              'push noise .02 seed 2 counted 7',
              'push noise .02 seed 3 counted 2',
              'push noise .02 seed 4 counted 7',
              'push noise .02 seed 5 counted 5'
            ]
  push noise .02 seed 1 counted 8
  push noise .02 seed 2 counted 7
  push noise .02 seed 3 counted 2
  push noise .02 seed 4 counted 7
  push noise .02 seed 5 counted 5
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 86:5  main.<fn>
  
00:00 +24 -6: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
00:00 +24 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:00 +24 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_plank_collapse.txt stays rejected with head and feet out of frame
00:00 +25 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: bottom bounce stays rejected with head and feet out of frame
00:00 +26 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +27 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +28 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +29 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +30 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +31 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:00 +32 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:00 +33 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:00 +34 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a dropout fixture loses tracking and counts nothing
00:00 +35 -7: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection a profile-width body reads as a side view
00:00 +36 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean squat fixture counts exactly one rep
00:00 +37 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean squat fixture counts exactly one rep
00:00 +38 -7: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean squat fixture counts exactly one rep
00:00 +38 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the ratio boundaries leave a hysteresis band
00:00 +38 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean squat fixture counts exactly one rep [E]
  Expected: <1>
    Actual: <0>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 209:5          main.<fn>
  
00:00 +39 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean head-on push-up fixture counts exactly one rep
00:00 +40 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean head-on push-up fixture counts exactly one rep
00:00 +41 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection inside the band a large shoulder z-spread supports side
00:00 +42 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on half-depth fixture counts nothing
00:00 +43 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on half-depth fixture counts nothing
00:00 +44 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on shake-only fixture counts nothing
00:00 +45 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the counter keeps the previous mode on an ambiguous frame
00:00 +46 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the counter keeps the previous mode on an ambiguous frame
00:00 +47 -8: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on fixture with a hidden hand never locks framing
00:00 +48 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting counts a head-on rep once with strong landmark noise
00:00 +49 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting two consecutive head-on reps count exactly two
00:00 +50 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting head-on top-of-movement jitter counts nothing
00:00 +51 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view framing a shrunken head-on body reports tooFar and never counts
00:00 +52 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view framing a head-on body with a hidden hand never locks framing
00:00 +53 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: squats stay side-view only a front-view squat is refused with wrongView, never counted
00:00 +54 -8: D:/TrainingArena/app/test/camera/front_view_test.dart: squats stay side-view only the side-view knee angle cannot separate a front-view squat
00:00 +55 -8: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean squat fixture counts exactly one rep
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: squat counts with head and feet out of frame
  ... and 4 more

```

## WP1 attempt 2 SYNTHETIC matrix and counter regressions

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter/counter_stress_matrix_test.dart test/camera/rep_counter_test.dart test/camera/fixture_replay_test.dart test/camera/front_view_test.dart --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart
00:00 +0: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +2: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +4: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +5: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +6: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +7: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +7 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +7 -1: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 199:7             main.<fn>.<fn>
  
00:00 +8 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +9 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +10 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +11 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +12 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +13 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +14 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +15 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +16 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +17 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +18 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
00:00 +19 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {}
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {}
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {}
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {}
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {}
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2}
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {}
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {}
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {}
00:00 +20 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {}
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {}
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50}
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50}
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {}
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {}
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {}
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {}
00:00 +21 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean push-up fixture counts exactly one rep
00:00 +22 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean push-up fixture counts exactly one rep
00:00 +23 -1: D:/TrainingArena/app/test/camera/rep_counter_test.dart: squat counter a heel lift at the bottom cues coaching and still counts
00:00 +24 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: side push-up counts with head and feet out of frame and cues move back
00:00 +25 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: side push-up counts with head and feet out of frame and cues move back
00:00 +26 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: side push-up counts with head and feet out of frame and cues move back
00:00 +27 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: squat counts with head and feet out of frame
00:00 +28 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: front push-up counts with head out of frame
00:00 +29 -1: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
00:00 +29 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:00 +29 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_plank_collapse.txt stays rejected with head and feet out of frame
00:00 +30 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: bottom bounce stays rejected with head and feet out of frame
00:00 +31 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +32 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +33 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +34 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +35 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:00 +36 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a half-depth fixture counts nothing
00:00 +37 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:00 +38 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:00 +39 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:00 +40 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean squat fixture counts exactly one rep
00:00 +41 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection a profile-width body reads as a side view
00:00 +42 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean head-on push-up fixture counts exactly one rep
00:00 +43 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a clean head-on push-up fixture counts exactly one rep
00:00 +44 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection a standing front view reads as front
00:00 +45 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on half-depth fixture counts nothing
00:00 +46 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the ratio boundaries leave a hysteresis band
00:00 +47 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection inside the band a small shoulder z-spread supports front
00:00 +48 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on shake-only fixture counts nothing
00:00 +49 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection inside the band a large shoulder z-spread supports side
00:00 +50 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on sag fixture refuses the rep as not straight
00:00 +51 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: a head-on sag fixture refuses the rep as not straight
00:00 +52 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the counter keeps the previous mode on an ambiguous frame
00:00 +53 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the counter keeps the previous mode on an ambiguous frame
00:00 +54 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting counts a head-on rep once with strong landmark noise
00:00 +55 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting two consecutive head-on reps count exactly two
00:00 +56 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting head-on top-of-movement jitter counts nothing
00:00 +57 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view framing a shrunken head-on body reports tooFar and never counts
00:00 +58 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view framing a head-on body with a hidden hand never locks framing
00:00 +59 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: squats stay side-view only a front-view squat is refused with wrongView, never counted
00:00 +60 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: squats stay side-view only the side-view knee angle cannot separate a front-view squat
00:00 +61 -2: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting

```

## WP1 SYNTHETIC geometry side timeout and HUD tests

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter/counter_acceptance_test.dart test/camera/diagnostics_hud_test.dart --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter/counter_acceptance_test.dart
00:00 +0: D:/TrainingArena/app/test/camera/counter/counter_acceptance_test.dart: SYNTHETIC bridge: 160-degree elbow in 480x640 pixels
00:00 +1: D:/TrainingArena/app/test/camera/counter/counter_acceptance_test.dart: SYNTHETIC full-chain side selection picks readable far side for two reps
00:00 +2: D:/TrainingArena/app/test/camera/counter/counter_acceptance_test.dart: SYNTHETIC incomplete lockout emits one rejection after 5s
00:00 +3: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:01 +4: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag true
00:01 +5: All tests passed!

```

## WP1 SYNTHETIC trace tooling and complete outcome matrix

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/trace_replay_test.dart test/camera/counter/counter_stress_matrix_test.dart --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/trace_replay_test.dart
00:00 +0: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
SYNTHETIC {counted_reps: 2, rejection_histogram: {}, cycles: [{timestamp_us: 2673000, outcome: counted, min_smoothed: 86.8131127524183, max_smoothed: 147.1670276677228}, {timestamp_us: 4653000, outcome: counted, min_smoothed: 86.01027679921629, max_smoothed: 146.87394404043283}], side_switches: 0, pause_reasons_by_frame: {}}
00:00 +1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +2: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
00:00 +3: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2} | outcomes [10, 10, 10, 10, 10]
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {} | outcomes [10, 10, 10, 9, 10]
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
00:00 +3 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: ['push noise .02 seed 4 has 9 outcomes for 10 descents']
  push noise .02 seed 4 has 9 outcomes for 10 descents
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 93:5  main.<fn>
  
00:00 +3 -1: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds

```

## WP1 release hold verification

Command: `rtk proxy node tools/release/check_release_flags.mjs`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
release flag check passed

```

## WP1 dev flag script print-only verification

Command: `rtk proxy powershell -NoProfile -File tools/run-dev.ps1 -PrintOnly`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ARENA_FEATURE_CAMERA_COUNTING=true
ARENA_FEATURE_CAMERA_TRACE=true
ARENA_FEATURE_CHALLENGE_LINKS=true
ARENA_FEATURE_PREVIEW_FIXTURES=true
ARENA_FEATURE_PUSH_NOTIFICATIONS=true
ARENA_FEATURE_RANKED_MATCHMAKING=true
ARENA_FEATURE_RESULT_SHARING=true
ARENA_FEATURE_SOLO_MODE=true

```

## WP1 replay empty trace expected exit nonzero

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/trace_replay_test.dart --dart-define=POSE_TRACE_PATH=D:\TrainingArena\qa\camera\replay_checks\empty.txt --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/trace_replay_test.dart
00:00 +0: owner trace replay (source provenance must be recorded separately)
00:00 +0 -1: owner trace replay (source provenance must be recorded separately) [E]
  FormatException: trace is empty
  test\camera\trace_replay_test.dart 13:23  replayTrace
  test\camera\trace_replay_test.dart 72:13  main.<fn>
  
00:00 +0 -1: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/trace_replay_test.dart: owner trace replay (source provenance must be recorded separately)

```

## WP1 replay invalid trace expected exit nonzero

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/trace_replay_test.dart --dart-define=POSE_TRACE_PATH=D:\TrainingArena\qa\camera\replay_checks\invalid.txt --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/trace_replay_test.dart
00:00 +0: owner trace replay (source provenance must be recorded separately)
00:00 +0 -1: owner trace replay (source provenance must be recorded separately) [E]
  FormatException: missing "|" in "this is an invalid trace"
  test\camera\fixture_replay.dart 44:7      parsePoseFixture
  test\camera\trace_replay_test.dart 12:18  replayTrace
  test\camera\trace_replay_test.dart 72:13  main.<fn>
  
00:00 +0 -1: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/trace_replay_test.dart: owner trace replay (source provenance must be recorded separately)

```

## WP1 end flutter analyze

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing app...                                                

   info - Don't invoke 'print' in production code. Try using a logging framework - test\camera\counter\counter_stress_matrix_test.dart:49:5 - avoid_print
   info - Don't invoke 'print' in production code. Try using a logging framework - test\camera\counter\counter_stress_matrix_test.dart:91:7 - avoid_print
   info - Statements in an if should be enclosed in a block. Try wrapping the statement in a block - test\camera\trace_replay_test.dart:58:24 - curly_braces_in_flow_control_structures
   info - Don't invoke 'print' in production code. Try using a logging framework - test\camera\trace_replay_test.dart:72:7 - avoid_print
   info - Don't invoke 'print' in production code. Try using a logging framework - test\camera\trace_replay_test.dart:81:5 - avoid_print

5 issues found. (ran in 10.0s)

```

## WP1 end flutter test

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/account/account_api_test.dart
00:00 +0: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport fetchProfile posts the action envelope with bearer and anon key
00:00 +1: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport unconfigured builds never touch the network
00:00 +2: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a missing token fails closed as unauthenticated
00:00 +3: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport transport failures surface as retryable network errors
00:00 +4: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a TLS handshake failure is an offline retry, not a raw IO error
00:00 +5: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport 401 answers are unauthenticated; 500 answers are retryable
00:00 +6: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport business errors use the server code and actionable copy
00:00 +7: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport server messages mentioning tokens are replaced
00:00 +8: D:/TrainingArena/app/test/account/account_api_test.dart: profile mutations profile_update normalizes nothing and sends the given name
00:00 +9: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +10: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +11: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +12: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +13: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing a win without a winner id is dropped
00:00 +14: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a restored session loads the authoritative profile
00:00 +15: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block publicProfile never surfaces extra private fields
00:00 +16: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +17: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block report sends target, optional match and the reason
00:00 +18: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a rejected session fails closed to signed out with plain copy
00:00 +19: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +20: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +21: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block deleteAccount posts the documented action
00:00 +22: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle accessToken returns the stored token when refresh is offline
00:00 +23: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a refused refresh ends the session and drops the token
00:00 +24: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in Google sign-in loads the profile and refreshes the viewer
00:00 +25: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in a first sign-in without a username stays in the username step
00:00 +26: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in email-code sign-in asks for the code and never keeps the address
00:00 +27: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in cancellation surfaces the plain provider message
00:00 +28: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim normalizes before sending and updates the viewer
00:00 +29: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim an unchanged name is a no-op without a round trip
00:00 +30: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim a server race reports an actionable duplicate message
00:00 +31: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim invalid local input never reaches the backend
00:00 +32: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim claiming before sign-in fails closed
00:00 +33: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar accepts a valid image and sends sniffed base64
00:00 +34: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects camera frames before any upload
00:00 +35: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects oversized images before any upload
00:00 +36: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar a rejected image keeps the profile and reports the reason
00:00 +37: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar remove is available with and without an avatar
00:00 +38: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion sign-out clears local state even when the server call fails
00:00 +39: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion deleteAccount clears local state and reports the result
00:00 +40: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion a failed deletion keeps the session for a retry
00:00 +41: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +42: D:/TrainingArena/app/test/account/account_durable_session_test.dart: deleteAccount does not claim durable removal when storage fails
00:00 +43: D:/TrainingArena/app/test/account/account_durable_session_test.dart: a failed server deletion keeps the valid session
00:00 +44: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a refresh that finishes after sign-out cannot resurrect the session
00:00 +45: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +46: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +47: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +48: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +49: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +50: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +51: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +52: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername empty, short, long, bad characters and reserved names fail
00:00 +53: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a newer identity does not join the prior account pending refresh
00:00 +54: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a newer identity does not join the prior account pending refresh
00:00 +55: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaEmail normalizes and validates the address shape
00:00 +56: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +57: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits sniffs JPEG, PNG and WebP signatures
00:00 +58: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +59: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +60: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +61: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +62: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +63: D:/TrainingArena/app/test/account/account_models_test.dart: AccountException classifies unauthenticated and retryable failures
00:00 +64: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed migration cannot survive a later clear and newer write
00:00 +65: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed migration cannot survive a later clear and newer write
00:00 +66: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +67: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +68: D:/TrainingArena/app/test/account/account_models_test.dart: leaderboard and public player view objects public player falls back to a safe display name
00:00 +69: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering PKCE ordering holds for a delayed write, clear and newer write
00:00 +70: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +71: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a superseded sign-in cannot persist over the newer account
00:00 +72: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +73: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a pending refresh cannot overwrite a newer sign-in in storage
00:00 +74: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed logout cannot erase a verifier saved after it
00:01 +75: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: Google sign-in returns to the same challenge and claims a username
00:01 +76: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: email-code sign-in keeps the same token through both prompts
00:01 +77: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: a duplicate username re-prompts without losing the challenge
00:01 +78: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: restart restores the waiting challenge with the same token
00:01 +79: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController loads exactly the confirmed rows
00:01 +80: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an empty ladder is an honest empty state, not an error
00:01 +81: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController the viewer row outside the top page is surfaced as-is
00:01 +82: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an offline refresh keeps the last confirmed page
00:01 +83: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController a server error is not retryable and keeps the confirmed page
00:01 +84: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an unconfigured build reports the flag without inventing rows
00:01 +85: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController reset drops every row and goes back to initial
00:01 +86: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController loads confirmed receipts unchanged
00:01 +87: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an empty history is an honest empty state
00:01 +88: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an offline refresh keeps the last confirmed receipts
00:01 +89: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController reset drops every receipt on sign-out
00:01 +90: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a Google redirect after process death returns to the same challenge
00:01 +91: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: an email-code sign-in after process death keeps the same challenge
00:01 +92: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a redirect that does not match the allowlist is ignored
00:02 +93: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +94: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +95: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +96: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +97: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +98: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +99: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +100: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +101: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +102: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +103: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +104: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +105: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +106: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +107: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +108: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +109: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +110: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab reflows at 200% text size without overflow
00:02 +111: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab reflows at 200% text size without overflow
00:03 +112: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab reflows at 200% text size without overflow
00:03 +113: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab reflows at 200% text size without overflow
00:03 +114: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +115: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +116: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +117: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +118: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +119: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +120: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +121: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +122: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +123: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +124: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +125: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +126: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +127: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +128: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +129: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +130: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +131: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +132: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +133: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +134: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +135: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +136: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +137: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +138: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +139: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +140: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +141: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +142: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +143: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +144: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +145: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:04 +146: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: public player card shows safe public identity, rating context and actions
00:04 +147: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links shows an honest notice when the pages are not published
00:04 +148: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: public player card report validates the reason before sending
00:04 +149: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:05 +150: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:05 +151: D:/TrainingArena/app/test/battle/battle_athlete_demo_review_test.dart: unreviewed assets render the placeholder
00:05 +152: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: public player card block confirms and can be undone from the card
00:05 +153: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: tapping a destination switches the visible page
00:05 +154: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: tapping a destination switches the visible page
00:05 +155: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: tapping a destination switches the visible page
00:05 +156: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:05 +157: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:05 +158: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:05 +159: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:05 +160: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:05 +161: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:06 +162: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a forfeit receipt never claims a zero-margin score
00:07 +163: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +164: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +165: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +166: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +167: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +168: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +169: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +170: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +171: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +172: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +173: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +174: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +175: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +176: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +177: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +178: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +179: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +180: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +181: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +182: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +183: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +184: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +185: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +186: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +187: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +188: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:07 +189: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +190: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +191: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +192: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +193: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +194: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +195: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +196: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +197: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +198: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +199: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +200: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +201: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +202: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +203: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +204: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +205: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +206: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +207: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +208: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +209: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +210: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +211: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +212: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +213: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +214: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +215: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +216: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +217: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +218: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:07 +219: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:08 +220: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:08 +221: D:/TrainingArena/app/test/battle/battle_contract_test.dart: draws stay ties
00:08 +222: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:08 +223: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:08 +224: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:08 +225: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:08 +226: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:08 +227: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:09 +228: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:09 +229: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:09 +230: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:09 +231: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +232: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +233: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +234: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +235: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +236: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +237: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +238: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +239: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +240: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +241: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +242: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:09 +243: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:10 +244: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:10 +245: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:10 +246: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:10 +247: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:10 +248: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +249: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +250: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +251: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +252: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +253: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +254: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +255: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +256: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +257: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +258: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +259: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +260: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +261: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:11 +262: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:11 +263: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +264: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +265: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +266: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +267: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +268: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +269: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +270: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +271: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +272: D:/TrainingArena/app/test/camera/camera_preview_test.dart: preview shows the demo label and never a fake texture
00:11 +273: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +274: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +275: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +276: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +277: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +278: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +279: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +280: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +281: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +282: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:11 +283: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +284: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +285: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +286: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +287: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +288: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +289: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +290: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +291: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +292: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +293: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +294: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +295: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +296: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +297: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +298: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +299: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:12 +300: D:/TrainingArena/app/test/camera/camera_preview_test.dart: the debug trace bar records, exports and deletes a trace
00:12 +301: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:12 +302: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:12 +303: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:12 +304: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:13 +304: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2} | outcomes [10, 10, 10, 10, 10]
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {} | outcomes [10, 10, 10, 9, 10]
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
00:13 +304 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:13 +304 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: ['push noise .02 seed 4 has 9 outcomes for 10 descents']
  push noise .02 seed 4 has 9 outcomes for 10 descents
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 93:5  main.<fn>
  
00:13 +305 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:13 +306 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:13 +307 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +308 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +309 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +310 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +311 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +312 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +313 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +314 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +314 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +314 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:13 +315 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +316 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:13 +317 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +318 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +319 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +320 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +321 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +322 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +323 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +324 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +325 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:14 +326 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:14 +327 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:14 +328 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:14 +329 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:14 +330 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:14 +331 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:14 +332 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag true
00:14 +333 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states blocked inbox shows a non-retryable explanation
00:14 +334 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:14 +335 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the side-view elbow angle never enters the bottom band head-on
00:14 +336 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: geometric cause the head-on signal separates the top from the bottom
00:14 +337 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection a profile-width body reads as a side view
00:14 +338 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection a wide, foreshortened body reads as a front view
00:14 +339 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection a standing front view reads as front
00:14 +340 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the ratio boundaries leave a hysteresis band
00:14 +341 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection inside the band a small shoulder z-spread supports front
00:14 +342 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection inside the band a large shoulder z-spread supports side
00:14 +343 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection missing or low-confidence geometry is unknown
00:14 +344 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: camera view detection the counter keeps the previous mode on an ambiguous frame
00:14 +345 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting counts a head-on rep once with strong landmark noise
00:14 +346 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting two consecutive head-on reps count exactly two
00:14 +347 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view counting head-on top-of-movement jitter counts nothing
00:14 +348 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view framing a shrunken head-on body reports tooFar and never counts
00:14 +349 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: front-view framing a head-on body with a hidden hand never locks framing
00:14 +350 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: squats stay side-view only a front-view squat is refused with wrongView, never counted
00:14 +351 -2: D:/TrainingArena/app/test/camera/front_view_test.dart: squats stay side-view only the side-view knee angle cannot separate a front-view squat
00:14 +352 -2: D:/TrainingArena/app/test/camera/generate_pose_fixtures_test.dart: regenerates the committed pose fixtures
  Skip: set FIXTURE_GEN=1 to regenerate
00:15 +352 ~1 -2: D:/TrainingArena/app/test/camera/overlay_paint_cost_test.dart: overlay paint cost, host only
  Skip: set OVERLAY_BENCH=1 to measure
00:15 +352 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint native crop mapping and mirror override fixture geometry
00:15 +353 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint identity: a box the size of the frame maps 1:1
00:15 +354 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint cover crops the overflowing axis and keeps the centre
00:15 +355 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint contain letterboxes and shrinks the frame
00:15 +356 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint mirror flips x in display space
00:15 +357 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint rotation is clockwise quarter turns
00:15 +358 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint rotation swaps the displayed frame size
00:15 +359 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint mirror applies after rotation
00:15 +360 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: skeleton chains the standard skeleton connects both sides and the nose
00:15 +361 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: skeleton chains side-view push-ups highlight the selected arm chain and elbow
00:15 +362 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: skeleton chains side-view squats highlight the selected leg chain and knee
00:15 +363 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: skeleton chains side view before a side is selected highlights nothing
00:15 +364 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: skeleton chains front view highlights the shoulder line, hand line and torso
00:15 +365 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: skeleton chains front-view squats are refused by the counter, so nothing highlights
00:15 +366 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +367 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +368 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +369 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +370 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +371 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +372 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +373 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +374 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +375 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +376 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:15 +377 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:16 +378 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay an empty landmark frame paints safely
00:16 +379 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay a partial head-on frame paints safely
00:16 +380 ~2 -2: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter counts a complete rep after stable full-body framing
00:16 +381 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay active false and visible false draw nothing
00:16 +382 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay active false and visible false draw nothing
00:16 +383 ~2 -2: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter ignores a partial rep that never reaches the bottom band
00:16 +384 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay a later frame repaints the canvas
00:16 +385 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay a later frame repaints the canvas
00:16 +386 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay a later frame repaints the canvas
00:16 +387 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay a later frame repaints the canvas
00:16 +388 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay a later frame repaints the canvas
00:16 +389 ~2 -2: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting
00:16 +389 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the selected chain is painted in lime
00:16 +389 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 199:7             main.<fn>.<fn>
  
00:16 +390 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the selected chain is painted in lime
00:16 +391 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the selected chain is painted in lime
00:16 +392 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter tracking loss resets the in-progress rep and surfaces the reason
00:16 +393 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +394 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +395 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +396 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +397 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +398 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +399 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +400 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:16 +401 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: squat counter rejects a folded-over torso at the bottom
00:16 +402 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: squat counter tracking loss mid-squat discards the in-progress rep
00:16 +403 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: squat counter a heel lift at the bottom cues coaching and still counts
00:16 +404 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: squat counter flat heels never produce the heel cue
00:16 +405 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: squat counter untracked feet disable the heel cue instead of pausing
00:16 +406 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
SYNTHETIC {counted_reps: 2, rejection_histogram: {}, cycles: [{timestamp_us: 2673000, outcome: counted, min_smoothed: 86.8131127524183, max_smoothed: 147.1670276677228}, {timestamp_us: 4653000, outcome: counted, min_smoothed: 86.01027679921629, max_smoothed: 146.87394404043283}], side_switches: 0, pause_reasons_by_frame: {}}
00:16 +407 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC empty and invalid traces fail
00:16 +408 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC trace preserves portrait aspect and depth
00:16 +409 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:16 +410 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares verified App Links for the configurable host
00:16 +411 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares verified App Links for the configurable host
00:16 +412 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares the trainingarena fallback and app_links routing
00:16 +413 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: gradle keeps the placeholder host and Play referrer dependency
00:16 +414 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: install referrer bridge uses the stable channel contract
00:16 +415 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: assetlinks template documents relation, package and fingerprint
00:16 +416 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: Android backup is off so credentials cannot leave the device
00:17 +417 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +418 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +419 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +420 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +421 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +422 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +423 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +424 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +425 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +426 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +427 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +428 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +429 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +430 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +431 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +432 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +433 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +434 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +435 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +436 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +437 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +438 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +439 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +440 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +441 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +442 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +443 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +444 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:17 +445 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +446 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +447 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +448 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +449 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +450 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +451 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:18 +452 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +453 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +454 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +455 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +456 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +457 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +458 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +459 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +460 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:18 +461 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:19 +462 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:19 +463 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:19 +464 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:19 +465 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:19 +466 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:19 +467 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:19 +468 ~2 -3: D:/TrainingArena/app/test/matchmaking/ranked_search_test.dart: truthful ranked search window empty queue times out at 60 seconds with no fake opponent
00:19 +469 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +470 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +471 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +472 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +473 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +474 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +475 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +476 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +477 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:19 +478 ~2 -3: D:/TrainingArena/app/test/matchmaking/ranked_search_test.dart: server-issued match handoff a real queue match enters preparation with mode and match id
00:19 +479 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: revoked link shows the honest unavailable state
00:19 +480 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: revoked link shows the honest unavailable state
00:19 +481 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: revoked link shows the honest unavailable state
00:19 +482 ~2 -3: D:/TrainingArena/app/test/notifications/android_push_host_config_test.dart: bridge implements every Dart channel and method of the contract
00:19 +483 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:19 +484 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:19 +485 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:19 +486 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:19 +487 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:19 +488 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: disabled links offer Play, reopen instruction and short code
00:19 +489 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: accepted match offers the preparation handoff
00:19 +490 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +491 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +492 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +493 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +494 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +495 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +496 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +497 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +498 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +499 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +500 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +501 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +502 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +503 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +504 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +505 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +506 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +507 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +508 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +509 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +510 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +511 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +512 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +513 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +514 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +515 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +516 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +517 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +518 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +519 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +520 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:20 +521 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: an unavailable request renders the explanation and back
00:20 +522 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: the permission rationale reports allow and not-now
00:21 +523 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: the permission rationale reports allow and not-now
00:21 +524 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: the permission rationale reports allow and not-now
00:21 +525 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +526 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +527 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +528 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +529 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +530 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +531 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +532 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +533 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:21 +534 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +535 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +536 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +537 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +538 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +539 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +540 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +541 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +542 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +543 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +544 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +545 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +546 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +547 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +548 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +549 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +550 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +551 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +552 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +553 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +554 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +555 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +556 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +557 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +558 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +559 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +560 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +561 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:21 +562 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +563 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +564 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +565 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +566 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +567 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +568 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:22 +569 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +570 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +571 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +572 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +573 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +574 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +575 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +576 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +577 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +578 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +579 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +580 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +581 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +582 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +583 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +584 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +585 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +586 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:22 +587 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +588 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +589 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +590 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +591 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +592 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +593 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +594 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +595 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +596 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +597 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +598 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:23 +599 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:23 +600 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:23 +601 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +602 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +603 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +604 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +605 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +606 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +607 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +608 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +609 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +610 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +611 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +612 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +613 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +614 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +615 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +616 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +617 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +618 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:24 +619 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:24 +620 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:24 +621 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:24 +622 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:24 +623 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:24 +624 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:24 +625 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:25 +626 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: missing avatars render as monograms in the preview
00:25 +627 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:25 +628 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:25 +629 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: a share-sheet failure keeps the preview card visible
00:25 +630 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry opens the solo page when the flag is on
00:25 +631 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: manual entry reaches a labelled result and saves
00:25 +632 ~2 -3: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting

```

## WP1 targeted lint repair for explicitly required console output

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze test/camera/counter/counter_stress_matrix_test.dart test/camera/trace_replay_test.dart`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing 2 items...                                            

   info - Statements in an if should be enclosed in a block. Try wrapping the statement in a block - test\camera\trace_replay_test.dart:62:24 - curly_braces_in_flow_control_structures

1 issue found. (ran in 3.6s)

```

## WP1 targeted lint attempt 2 replay brace repair

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze test/camera/counter/counter_stress_matrix_test.dart test/camera/trace_replay_test.dart`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing 2 items...                                            
No issues found! (ran in 1.9s)

```

## WP2 create new migration via installed CLI

Command: `rtk proxy powershell -NoProfile -Command "supabase migration new arena_goal_hardening"`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
{"path":"D:\\TrainingArena\\supabase\\migrations\\20261012144405_arena_goal_hardening.sql","message":"Migration created"}
A new version of Supabase CLI is available: v2.120.0 (currently installed v2.116.0)
We recommend updating regularly for new features and bug fixes: https://supabase.com/docs/guides/cli/getting-started#updating-the-supabase-cli

```

## WP2 local database availability and remote inventory

Command: `rtk proxy powershell -NoProfile -Command "docker ps --format '{{.Names}}'; git remote -v; Get-Command deno -ErrorAction SilentlyContinue"`
Working directory: `D:\TrainingArena`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine; check if the path is correct and if the daemon is running: open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.

```

## WP2 supabase test db local attempt

Command: `rtk proxy powershell -NoProfile -Command "supabase test db --local"`
Working directory: `D:\TrainingArena`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Connecting to local database...
{"_tag":"Error","error":{"code":"LegacyDbConnectError","message":"failed to connect to postgres: failed to connect to `host=127.0.0.1 user=postgres database=postgres`: dial error (connect ECONNREFUSED 127.0.0.1:54522)","suggestion":"Make sure Docker is running, then run: supabase start"}}

```

## WP2 supabase db reset local attempt

Command: `rtk proxy powershell -NoProfile -Command "supabase db reset --local"`
Working directory: `D:\TrainingArena`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
{"_tag":"Error","error":{"code":"LegacyLocalDbRunningError","message":"failed to inspect service: failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine; check if the path is correct and if the daemon is running: open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified."}}

```

## WP2 git bundle script outside-repo verification

Command: `rtk proxy powershell -NoProfile -File tools/backup-git.ps1 -OutputPath D:\TrainingArena-WP2.bundle`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
D:/TrainingArena-WP2.bundle is okay
The bundle contains these 7 refs:
157ed57478383ae41562f802256710333031812d refs/codex/turn-diffs/captures/1791815888829/6fc0ebf1-044c-47c6-9f56-7724af822535/base
157ed57478383ae41562f802256710333031812d refs/codex/turn-diffs/checkpoints/9c554ac27e169365b9eb370c53cca0a6/8b6fd7eabbcc0707c4aa79dbf1c5ff10/1791807372265/5f6e1fa1-7ca0-4b64-8145-002e617f7d44
1202113abe6297cf75884b57981e1f4a801270c7 refs/codex/turn-diffs/checkpoints/d55748e46d1790bd822c3cfb9c4c367c/60a62b679e44d36152ba22d6c5977df2/1791625980010/abf398af-3f40-48d8-b99e-54ded5bb0a89
5700dbc3cdb7f79ba9d5e98f79d66d1e58370a79 refs/heads/codex/training-arena
02c2f2b3d5bda12442370581a2af1a10781df797 refs/heads/master
02c2f2b3d5bda12442370581a2af1a10781df797 refs/tags/split/source-2026-09-17
5700dbc3cdb7f79ba9d5e98f79d66d1e58370a79 HEAD
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
Committed Git history saved: D:\TrainingArena-WP2.bundle
Uncommitted and untracked files are not in this bundle.

```

## WP2 end flutter analyze

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Waiting for another flutter command to release the startup lock...
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing app...                                                
No issues found! (ran in 5.4s)

```

## WP2 end flutter test

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/account/account_api_test.dart
00:00 +0: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport fetchProfile posts the action envelope with bearer and anon key
00:00 +1: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport unconfigured builds never touch the network
00:00 +2: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a missing token fails closed as unauthenticated
00:00 +3: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport transport failures surface as retryable network errors
00:00 +4: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a TLS handshake failure is an offline retry, not a raw IO error
00:00 +5: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport 401 answers are unauthenticated; 500 answers are retryable
00:00 +6: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport business errors use the server code and actionable copy
00:00 +7: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport server messages mentioning tokens are replaced
00:00 +8: D:/TrainingArena/app/test/account/account_api_test.dart: profile mutations profile_update normalizes nothing and sends the given name
00:00 +9: D:/TrainingArena/app/test/account/account_api_test.dart: profile mutations avatar_update sends base64 and mime_type from the picker
00:00 +10: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing leaderboard keeps only rows with an id and a positive rank
00:00 +11: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +12: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +13: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +14: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +15: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +16: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +17: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a restored session loads the authoritative profile
00:00 +18: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block deleteAccount posts the documented action
00:00 +19: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +20: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a rejected session fails closed to signed out with plain copy
00:00 +21: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +22: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle accessToken returns the stored token when refresh is offline
00:00 +23: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a refused refresh ends the session and drops the token
00:00 +24: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in Google sign-in loads the profile and refreshes the viewer
00:00 +25: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in a first sign-in without a username stays in the username step
00:00 +26: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in email-code sign-in asks for the code and never keeps the address
00:00 +27: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in cancellation surfaces the plain provider message
00:00 +28: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim normalizes before sending and updates the viewer
00:00 +29: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim an unchanged name is a no-op without a round trip
00:00 +30: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim a server race reports an actionable duplicate message
00:00 +31: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim invalid local input never reaches the backend
00:00 +32: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim claiming before sign-in fails closed
00:00 +33: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar accepts a valid image and sends sniffed base64
00:00 +34: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects camera frames before any upload
00:00 +35: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects oversized images before any upload
00:00 +36: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar a rejected image keeps the profile and reports the reason
00:00 +37: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar remove is available with and without an avatar
00:00 +38: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion sign-out clears local state even when the server call fails
00:00 +39: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion deleteAccount clears local state and reports the result
00:00 +40: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion a failed deletion keeps the session for a retry
00:00 +41: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +42: D:/TrainingArena/app/test/account/account_durable_session_test.dart: deleteAccount does not claim durable removal when storage fails
00:00 +43: D:/TrainingArena/app/test/account/account_durable_session_test.dart: a failed server deletion keeps the valid session
00:00 +44: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a refresh that finishes after sign-out cannot resurrect the session
00:00 +45: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out drops the session immediately, before the gateway answers
00:00 +46: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out without an in-memory session clears pending durable auth
00:00 +47: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a restore that finishes after sign-out cannot sign the user back in
00:00 +48: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +49: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a newer identity does not join the prior account pending refresh
00:00 +50: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +51: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +52: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +53: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +54: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername isSame compares normalized names without case
00:00 +55: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +56: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +57: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername empty, short, long, bad characters and reserved names fail
00:00 +58: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed migration cannot survive a later clear and newer write
00:00 +59: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed migration cannot survive a later clear and newer write
00:00 +60: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaEmail normalizes and validates the address shape
00:00 +61: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +62: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +63: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits camera-like raw bytes are never a supported image
00:00 +64: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering PKCE ordering holds for a delayed write, clear and newer write
00:00 +65: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +66: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +67: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +68: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +69: D:/TrainingArena/app/test/account/account_models_test.dart: leaderboard and public player view objects leaderboard rows know the viewer and compare by value
00:00 +70: D:/TrainingArena/app/test/account/account_models_test.dart: leaderboard and public player view objects public player falls back to a safe display name
00:00 +71: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a superseded sign-in cannot persist over the newer account
00:00 +72: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +73: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a pending refresh cannot overwrite a newer sign-in in storage
00:00 +74: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed logout cannot erase a verifier saved after it
00:00 +75: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: Google sign-in returns to the same challenge and claims a username
00:00 +76: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: email-code sign-in keeps the same token through both prompts
00:00 +77: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: a duplicate username re-prompts without losing the challenge
00:00 +78: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: restart restores the waiting challenge with the same token
00:00 +79: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController loads exactly the confirmed rows
00:00 +80: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an empty ladder is an honest empty state, not an error
00:00 +81: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController the viewer row outside the top page is surfaced as-is
00:00 +82: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an offline refresh keeps the last confirmed page
00:00 +83: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController a server error is not retryable and keeps the confirmed page
00:01 +84: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an unconfigured build reports the flag without inventing rows
00:01 +85: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController reset drops every row and goes back to initial
00:01 +86: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController loads confirmed receipts unchanged
00:01 +87: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an empty history is an honest empty state
00:01 +88: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an offline refresh keeps the last confirmed receipts
00:01 +89: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController reset drops every receipt on sign-out
00:01 +90: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a Google redirect after process death returns to the same challenge
00:01 +91: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: an email-code sign-in after process death keeps the same challenge
00:01 +92: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a redirect that does not match the allowlist is ignored
00:01 +93: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +94: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +95: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +96: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +97: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +98: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +99: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +100: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +101: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +102: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +103: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +104: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +105: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +106: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +107: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +108: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +109: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +110: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +111: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +112: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +113: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +114: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +115: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +116: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +117: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +118: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +119: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +120: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +121: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +122: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +123: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +124: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +125: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +126: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +127: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +128: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +129: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +130: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +131: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +132: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +133: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +134: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +135: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +136: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +137: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +138: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +139: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +140: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +141: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +142: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +143: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +144: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +145: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +146: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +147: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +148: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +149: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +150: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +151: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +152: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +153: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +154: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +155: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +156: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +157: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +158: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +159: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +160: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +161: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +162: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +163: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +164: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +165: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +166: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +167: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +168: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +169: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +170: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +171: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +172: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +173: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +174: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +175: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +176: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +177: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +178: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +179: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +180: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +181: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +182: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +183: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +184: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +185: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +186: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +187: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +188: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +189: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +190: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +191: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +192: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +193: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +194: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +195: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +196: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +197: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +198: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +199: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +200: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +201: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +202: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +203: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +204: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +205: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +206: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +207: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +208: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +209: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +210: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +211: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +212: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +213: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +214: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +215: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +216: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +217: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +218: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +219: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +220: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +221: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +222: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +223: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +224: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +225: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +226: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +227: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +228: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +229: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +230: D:/TrainingArena/app/test/battle/battle_contract_test.dart: duplicate polling updates are idempotent in the UI
00:05 +231: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +232: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +233: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +234: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +235: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +236: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +237: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +238: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +239: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +240: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +241: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +242: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +243: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +244: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +245: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +246: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +247: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +248: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +249: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +250: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +251: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +252: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +253: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +254: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +255: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +256: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +257: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +258: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +259: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +260: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +261: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +262: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +263: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +264: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +265: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +266: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +267: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +268: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +269: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +270: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +271: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +272: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +273: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +274: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +275: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +276: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +277: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +278: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +279: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +280: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +281: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +282: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +283: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +284: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +285: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +286: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +287: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +288: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +289: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +290: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +291: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +292: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +293: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +294: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +295: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +296: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +297: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +298: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +299: D:/TrainingArena/app/test/camera/camera_preview_test.dart: the front-camera preview and the skeleton are mirrored together
00:07 +300: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +301: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:08 +302: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +302: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2} | outcomes [10, 10, 10, 10, 10]
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {} | outcomes [10, 10, 10, 9, 10]
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
00:08 +302 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +302 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: ['push noise .02 seed 4 has 9 outcomes for 10 descents']
  push noise .02 seed 4 has 9 outcomes for 10 descents
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 95:5  main.<fn>
  
00:08 +303 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +304 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +305 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +306 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +307 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +308 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +308 -2: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +308 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:08 +309 -2: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +310 -2: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +311 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +312 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +313 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +314 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +315 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +316 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +317 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +318 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +319 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +320 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +321 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +322 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +323 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +324 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +325 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +326 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +327 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +328 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +329 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +330 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +331 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +332 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +333 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +334 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +335 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +336 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +337 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +338 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +339 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +340 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +341 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +342 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +343 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +344 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +344 -2: D:/TrainingArena/app/test/camera/generate_pose_fixtures_test.dart: regenerates the committed pose fixtures
  Skip: set FIXTURE_GEN=1 to regenerate
00:08 +344 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:09 +344 ~1 -2: D:/TrainingArena/app/test/camera/overlay_paint_cost_test.dart: overlay paint cost, host only
  Skip: set OVERLAY_BENCH=1 to measure
00:09 +344 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:09 +345 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +346 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +347 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint identity: a box the size of the frame maps 1:1
00:09 +348 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint cover crops the overflowing axis and keeps the centre
00:09 +349 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +350 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +351 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +352 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +353 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +354 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +355 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +356 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +357 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +358 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +359 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +360 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +361 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +362 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +363 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +364 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +365 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +366 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +367 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +368 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +369 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +370 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +371 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +372 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +373 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +374 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +375 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +376 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +377 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +378 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +379 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +379 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +379 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 199:7             main.<fn>.<fn>
  
00:09 +380 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +381 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +382 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +383 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +384 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +385 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +386 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +387 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +388 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +389 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:09 +390 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:09 +391 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:09 +392 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:09 +393 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:09 +394 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:09 +395 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay an empty landmark frame paints safely
00:09 +396 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay an empty landmark frame paints safely
00:09 +397 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
00:10 +398 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
SYNTHETIC {counted_reps: 2, rejection_histogram: {}, cycles: [{timestamp_us: 2673000, outcome: counted, min_smoothed: 86.8131127524183, max_smoothed: 147.1670276677228}, {timestamp_us: 4653000, outcome: counted, min_smoothed: 86.01027679921629, max_smoothed: 146.87394404043283}], side_switches: 0, pause_reasons_by_frame: {}}
00:10 +399 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states loading skeleton shows until the inbox answers
00:10 +400 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states loading skeleton shows until the inbox answers
00:10 +401 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states loading skeleton shows until the inbox answers
00:10 +402 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay active false and visible false draw nothing
00:10 +403 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:10 +404 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:10 +405 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +406 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +407 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states blocked inbox shows a non-retryable explanation
00:10 +408 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states blocked inbox shows a non-retryable explanation
00:10 +409 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +410 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +411 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares verified App Links for the configurable host
00:10 +412 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares the trainingarena fallback and app_links routing
00:10 +413 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: gradle keeps the placeholder host and Play referrer dependency
00:10 +414 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: install referrer bridge uses the stable channel contract
00:10 +415 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: assetlinks template documents relation, package and fingerprint
00:10 +416 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: Android backup is off so credentials cannot leave the device
00:10 +417 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +418 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +419 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +420 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +421 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +422 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:10 +423 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +424 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +425 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +426 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +427 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +428 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +429 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +430 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +431 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +432 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +433 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +434 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +435 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +436 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +437 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +438 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +439 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +440 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +441 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +442 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +443 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +444 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +445 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +446 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +447 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +448 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +449 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +450 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +451 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +452 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +453 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +454 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +455 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +456 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:11 +457 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +458 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +459 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +460 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +461 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +462 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +463 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +464 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +465 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +466 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +467 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +468 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +469 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +470 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +471 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +472 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +473 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +474 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +475 ~2 -3: D:/TrainingArena/app/test/matchmaking/ranked_search_test.dart: truthful ranked search window starting a search during an active match is refused
00:12 +476 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +477 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +478 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +479 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +480 ~2 -3: D:/TrainingArena/app/test/notifications/android_push_host_config_test.dart: bridge implements every Dart channel and method of the contract
00:12 +481 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +482 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +483 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +484 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +485 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +486 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: revoked link shows the honest unavailable state
00:12 +487 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:12 +488 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: disabled links offer Play, reopen instruction and short code
00:12 +489 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +490 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +491 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +492 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +493 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +494 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +495 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +496 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +497 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +498 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +499 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +500 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +501 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +502 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +503 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +504 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +505 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +506 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +507 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +508 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +509 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +510 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +511 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +512 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +513 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +514 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +515 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +516 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +517 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +518 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +519 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +520 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +521 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +522 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +523 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +524 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +525 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +526 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +527 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +528 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +529 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +530 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +531 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +532 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +533 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +534 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +535 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +536 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +537 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +538 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +539 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +540 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +541 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +542 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +543 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +544 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +545 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +546 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +547 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +548 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +549 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +550 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +551 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +552 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +553 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +554 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +555 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +556 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +557 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +558 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +559 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +560 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +561 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +562 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +563 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +564 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +565 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +566 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +567 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +568 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +569 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +570 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +571 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +572 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +573 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +574 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +575 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +576 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +577 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +578 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +579 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +580 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +581 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +582 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +583 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +584 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +585 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +586 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +587 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +588 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +589 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +590 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +591 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +592 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +593 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +594 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +595 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +596 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +597 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +598 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +599 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +600 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +601 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +602 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +603 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +604 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +605 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +606 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +607 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +608 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +609 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +610 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +611 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +612 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +613 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +614 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +615 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +616 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +617 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +618 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +619 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +620 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +621 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +622 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +623 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +624 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +625 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +626 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: failed persistence never shows Saved and keeps the count
00:16 +627 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: failed persistence never shows Saved and keeps the count
00:16 +628 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry is hidden when the flag is off
00:16 +629 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:16 +630 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry opens the solo page when the flag is on
00:16 +631 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: manual entry reaches a labelled result and saves
00:17 +632 ~2 -3: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting

```

## WP2 TS syntax only; Deno runtime NOT RUN

Command: `rtk proxy node --check supabase/functions/arena/lib/avatar.ts`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings

```

## WP3 tracked personal document path check only

Command: `rtk git ls-files tmp/pdfs`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings

```

## WP3 exact marketing guardrails edit and owner-draft preservation

Command: `rtk proxy python tools/audit_wp3_guardrails.py`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Original owner draft SHA256: 6b300bb8b241a3241c51a5d3268a864fb8b1fba7325f508c9943479ae9c77304
Added Hard gates and removed only the five quota-multiplication phrases.
All other original draft content preserved. Own diff saved as WP3_UGC_GUARDRAILS.patch.

```

## WP3 public-output passing and failing fixtures and unchanged release holds

Command: `rtk proxy node --test tools/release/test/check_public_output.test.mjs tools/release/test/check_release_flags.test.mjs`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
TAP version 13
# Subtest: passing public-output fixture scans every nested file
ok 1 - passing public-output fixture scans every nested file
  ---
  duration_ms: 8.1253
  type: 'test'
  ...
# Subtest: failing fixture rejects both markers in arbitrary nested/binary output
ok 2 - failing fixture rejects both markers in arbitrary nested/binary output
  ---
  duration_ms: 3.8514
  type: 'test'
  ...
# Subtest: required missing output fails closed
ok 3 - required missing output fails closed
  ---
  duration_ms: 0.3436
  type: 'test'
  ...
# Subtest: the shipped release workflow keeps every documented hold
ok 4 - the shipped release workflow keeps every documented hold
  ---
  duration_ms: 3.1734
  type: 'test'
  ...
# Subtest: a ranked=true define is rejected
ok 5 - a ranked=true define is rejected
  ---
  duration_ms: 0.2934
  type: 'test'
  ...
# Subtest: a missing ranked=false pin is rejected
ok 6 - a missing ranked=false pin is rejected
  ---
  duration_ms: 0.1274
  type: 'test'
  ...
# Subtest: push or preview enabled is rejected
ok 7 - push or preview enabled is rejected
  ---
  duration_ms: 0.1902
  type: 'test'
  ...
# Subtest: the explicit camera choice is required
ok 8 - the explicit camera choice is required
  ---
  duration_ms: 0.2428
  type: 'test'
  ...
# Subtest: beta requires solo mode enabled and rejects a disabled or missing pin
ok 9 - beta requires solo mode enabled and rejects a disabled or missing pin
  ---
  duration_ms: 0.2421
  type: 'test'
  ...
# Subtest: the debug camera trace enabled or unpinned is rejected
ok 10 - the debug camera trace enabled or unpinned is rejected
  ---
  duration_ms: 0.2247
  type: 'test'
  ...
1..10
# tests 10
# suites 0
# pass 10
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 99.9282

```

## WP3 actual public-output gate expected refusal while owner placeholders remain

Command: `rtk proxy node tools/release/check_public_output.mjs`
Working directory: `D:\TrainingArena`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
challenge-web\README.md: owner placeholder or example.invalid remains
challenge-web\app.js: owner placeholder or example.invalid remains
challenge-web\config.js: owner placeholder or example.invalid remains
challenge-web\delete-account.html: owner placeholder or example.invalid remains
challenge-web\privacy.html: owner placeholder or example.invalid remains
challenge-web\support.html: owner placeholder or example.invalid remains
fault-web\public\legacy\app.js: owner placeholder or example.invalid remains
fault-web\public\legacy\config.js: owner placeholder or example.invalid remains
fault-web\public\legacy\delete-account.html: owner placeholder or example.invalid remains
fault-web\public\legacy\privacy.html: owner placeholder or example.invalid remains
fault-web\public\legacy\support.html: owner placeholder or example.invalid remains
public output check failed: 11 file(s)

```

## WP3 personal PDF ignore verification without opening files

Command: `rtk git check-ignore tmp/pdfs/probe.pdf`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
tmp/pdfs/probe.pdf

```

## WP3 public legal draft regression checks

Command: `rtk proxy node --test challenge-web/test/public_pages.test.mjs`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
TAP version 13
# Subtest: rejects a malformed email without any network call
ok 1 - rejects a malformed email without any network call
  ---
  duration_ms: 1.0817
  type: 'test'
  ...
# Subtest: is not configured without an apiBase and anon key
ok 2 - is not configured without an apiBase and anon key
  ---
  duration_ms: 0.2637
  type: 'test'
  ...
# Subtest: requests the code with create_user:false and the project anon key
ok 3 - requests the code with create_user:false and the project anon key
  ---
  duration_ms: 0.8507
  type: 'test'
  ...
# Subtest: maps a rate limit to a retryable error
ok 4 - maps a rate limit to a retryable error
  ---
  duration_ms: 0.2563
  type: 'test'
  ...
# Subtest: verifies the code and deletes with the verified session bearer
ok 5 - verifies the code and deletes with the verified session bearer
  ---
  duration_ms: 0.4643
  type: 'test'
  ...
# Subtest: an expired code is reported and no session is kept
ok 6 - an expired code is reported and no session is kept
  ---
  duration_ms: 0.1999
  type: 'test'
  ...
# Subtest: a network failure keeps the verified session so the retry is safe
ok 7 - a network failure keeps the verified session so the retry is safe
  ---
  duration_ms: 0.3379
  type: 'test'
  ...
# Subtest: a dead session after deletion is not presented as a retryable failure
ok 8 - a dead session after deletion is not presented as a retryable failure
  ---
  duration_ms: 0.2389
  type: 'test'
  ...
# Subtest: a late verification for A cannot authenticate or delete for B
ok 9 - a late verification for A cannot authenticate or delete for B
  ---
  duration_ms: 0.5237
  type: 'test'
  ...
# Subtest: an out-of-order code request cannot overwrite a newer one
ok 10 - an out-of-order code request cannot overwrite a newer one
  ---
  duration_ms: 0.4132
  type: 'test'
  ...
# Subtest: a late delete completion after restart is ignored
ok 11 - a late delete completion after restart is ignored
  ---
  duration_ms: 1.0071
  type: 'test'
  ...
# Subtest: an HTTP 200 business error is not a confirmed deletion
ok 12 - an HTTP 200 business error is not a confirmed deletion
  ---
  duration_ms: 0.2878
  type: 'test'
  ...
# Subtest: a malformed success payload is rejected and keeps retry state
ok 13 - a malformed success payload is rejected and keeps retry state
  ---
  duration_ms: 0.1436
  type: 'test'
  ...
# Subtest: the shipped deletion script never logs and never persists
ok 14 - the shipped deletion script never logs and never persists
  ---
  duration_ms: 0.4604
  type: 'test'
  ...
# Subtest: every owner field used by a page exists in config.js
ok 15 - every owner field used by a page exists in config.js
  ---
  duration_ms: 0.8764
  type: 'test'
  ...
1..15
# tests 15
# suites 0
# pass 15
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 100.7798

```

## WP3 end flutter analyze

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing app...                                                
No issues found! (ran in 2.5s)

```

## WP3 end flutter test

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Waiting for another flutter command to release the startup lock...
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/account/account_api_test.dart
00:00 +0: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport fetchProfile posts the action envelope with bearer and anon key
00:00 +1: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport unconfigured builds never touch the network
00:00 +2: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a missing token fails closed as unauthenticated
00:00 +3: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport transport failures surface as retryable network errors
00:00 +4: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a TLS handshake failure is an offline retry, not a raw IO error
00:00 +5: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport 401 answers are unauthenticated; 500 answers are retryable
00:00 +6: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport business errors use the server code and actionable copy
00:00 +7: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +8: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +9: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +10: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +11: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +12: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +13: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +14: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +15: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +16: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block publicProfile never surfaces extra private fields
00:00 +17: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a rejected session fails closed to signed out with plain copy
00:00 +18: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block report sends target, optional match and the reason
00:00 +19: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +20: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +21: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +22: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a refused refresh ends the session and drops the token
00:00 +23: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block deleteAccount posts the documented action
00:00 +24: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in Google sign-in loads the profile and refreshes the viewer
00:00 +25: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in a first sign-in without a username stays in the username step
00:00 +26: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in email-code sign-in asks for the code and never keeps the address
00:00 +27: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in cancellation surfaces the plain provider message
00:00 +28: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim normalizes before sending and updates the viewer
00:00 +29: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim an unchanged name is a no-op without a round trip
00:00 +30: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim a server race reports an actionable duplicate message
00:00 +31: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim invalid local input never reaches the backend
00:00 +32: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim claiming before sign-in fails closed
00:00 +33: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar accepts a valid image and sends sniffed base64
00:00 +34: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects camera frames before any upload
00:00 +35: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects oversized images before any upload
00:00 +36: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar a rejected image keeps the profile and reports the reason
00:00 +37: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar remove is available with and without an avatar
00:00 +38: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +39: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +40: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +41: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +42: D:/TrainingArena/app/test/account/account_durable_session_test.dart: deleteAccount does not claim durable removal when storage fails
00:00 +43: D:/TrainingArena/app/test/account/account_durable_session_test.dart: a failed server deletion keeps the valid session
00:00 +44: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a refresh that finishes after sign-out cannot resurrect the session
00:00 +45: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out drops the session immediately, before the gateway answers
00:00 +46: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out without an in-memory session clears pending durable auth
00:00 +47: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a restore that finishes after sign-out cannot sign the user back in
00:00 +48: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +49: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a newer identity does not join the prior account pending refresh
00:00 +50: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +51: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +52: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +53: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +54: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +55: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +56: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +57: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername isSame compares normalized names without case
00:00 +58: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering PKCE ordering holds for a delayed write, clear and newer write
00:00 +59: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername valid names pass at both length bounds
00:00 +60: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +61: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +62: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +63: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +64: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +65: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +66: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +67: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a superseded sign-in cannot persist over the newer account
00:00 +68: D:/TrainingArena/app/test/account/account_models_test.dart: AccountException classifies unauthenticated and retryable failures
00:00 +69: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +70: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +71: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +72: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +73: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a pending refresh cannot overwrite a newer sign-in in storage
00:00 +74: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed logout cannot erase a verifier saved after it
00:00 +75: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: Google sign-in returns to the same challenge and claims a username
00:00 +76: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: email-code sign-in keeps the same token through both prompts
00:00 +77: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: a duplicate username re-prompts without losing the challenge
00:00 +78: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: restart restores the waiting challenge with the same token
00:00 +79: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController loads exactly the confirmed rows
00:00 +80: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an empty ladder is an honest empty state, not an error
00:00 +81: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController the viewer row outside the top page is surfaced as-is
00:00 +82: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an offline refresh keeps the last confirmed page
00:00 +83: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController a server error is not retryable and keeps the confirmed page
00:00 +84: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an unconfigured build reports the flag without inventing rows
00:00 +85: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController reset drops every row and goes back to initial
00:00 +86: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController loads confirmed receipts unchanged
00:00 +87: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an empty history is an honest empty state
00:01 +88: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an offline refresh keeps the last confirmed receipts
00:01 +89: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController reset drops every receipt on sign-out
00:01 +90: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a Google redirect after process death returns to the same challenge
00:01 +91: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: an email-code sign-in after process death keeps the same challenge
00:01 +92: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a redirect that does not match the allowlist is ignored
00:01 +93: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +94: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +95: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +96: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +97: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +98: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +99: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +100: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +101: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +102: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +103: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +104: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +105: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +106: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +107: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +108: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +109: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +110: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +111: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +112: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +113: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +114: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +115: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +116: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +117: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +118: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +119: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +120: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +121: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +122: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +123: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +124: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +125: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +126: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +127: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +128: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +129: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +130: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +131: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +132: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +133: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +134: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +135: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +136: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +137: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +138: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +139: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +140: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +141: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +142: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +143: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +144: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +145: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +146: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +147: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +148: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +149: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +150: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +151: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +152: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +153: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +154: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +155: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +156: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +157: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +158: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +159: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +160: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +161: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +162: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +163: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +164: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +165: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +166: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +167: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +168: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +169: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +170: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +171: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +172: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +173: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +174: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +175: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +176: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +177: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +178: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +179: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +180: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +181: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +182: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +183: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +184: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +185: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +186: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +187: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +188: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +189: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +190: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +191: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +192: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +193: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +194: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +195: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +196: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +197: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +198: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +199: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +200: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +201: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +202: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +203: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +204: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +205: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +206: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +207: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +208: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +209: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +210: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +211: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +212: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +213: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +214: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +215: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +216: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +217: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +218: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +219: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +220: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +221: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +222: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +223: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +224: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +225: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +226: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +227: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +228: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +229: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +230: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +231: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +232: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +233: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +234: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +235: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +236: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +237: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +238: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +239: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +240: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +241: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +242: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +243: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +244: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +245: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +246: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +247: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +248: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +249: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +250: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +251: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +252: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +253: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +254: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +255: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +256: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +257: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +258: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +259: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +260: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +261: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +262: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +263: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +264: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +265: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +266: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +267: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +268: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +269: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +270: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +271: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +272: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +273: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +274: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +275: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +276: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +277: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +278: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +279: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +280: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +281: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +282: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +283: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +284: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +285: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +286: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +287: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +288: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +289: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +290: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +291: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +292: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +293: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +294: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +295: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +296: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +297: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +298: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +299: D:/TrainingArena/app/test/camera/camera_preview_test.dart: the front-camera preview and the skeleton are mirrored together
00:07 +300: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +301: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:08 +302: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +302: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2} | outcomes [10, 10, 10, 10, 10]
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {} | outcomes [10, 10, 10, 9, 10]
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
00:08 +302 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +302 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: ['push noise .02 seed 4 has 9 outcomes for 10 descents']
  push noise .02 seed 4 has 9 outcomes for 10 descents
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 95:5  main.<fn>
  
00:08 +303 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +304 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +305 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +306 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +307 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +308 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +309 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +309 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +309 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:08 +310 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +311 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +312 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +313 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +314 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +315 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +316 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +317 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +318 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +319 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +320 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +321 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +322 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +323 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +324 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +325 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +326 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +327 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +328 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +329 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +330 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +331 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +332 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +333 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +334 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +335 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +336 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +337 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +338 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +339 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +340 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +341 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +342 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:09 +343 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:09 +344 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:09 +344 -2: D:/TrainingArena/app/test/camera/generate_pose_fixtures_test.dart: regenerates the committed pose fixtures
  Skip: set FIXTURE_GEN=1 to regenerate
00:09 +344 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:09 +344 ~1 -2: D:/TrainingArena/app/test/camera/overlay_paint_cost_test.dart: overlay paint cost, host only
  Skip: set OVERLAY_BENCH=1 to measure
00:09 +344 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:09 +345 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +346 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +347 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +348 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +349 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +350 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +351 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +352 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:09 +353 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: poseOverlayPoint mirror applies after rotation
00:09 +354 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +355 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +356 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +357 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +358 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +359 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +360 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +361 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +362 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +363 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +364 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +365 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +366 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +367 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +368 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +369 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +370 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +371 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:10 +372 ~2 -2: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay paints a synthetic session frame without errors
00:10 +373 ~2 -2: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter counts a complete rep after stable full-body framing
00:10 +374 ~2 -2: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter counts a complete rep after stable full-body framing
00:10 +375 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +376 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +377 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +378 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +379 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +380 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +381 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +382 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +382 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +382 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 199:7             main.<fn>.<fn>
  
00:10 +383 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +384 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +385 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +386 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +386 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
SYNTHETIC {counted_reps: 2, rejection_histogram: {}, cycles: [{timestamp_us: 2673000, outcome: counted, min_smoothed: 86.8131127524183, max_smoothed: 147.1670276677228}, {timestamp_us: 4653000, outcome: counted, min_smoothed: 86.01027679921629, max_smoothed: 146.87394404043283}], side_switches: 0, pause_reasons_by_frame: {}}
00:10 +387 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +388 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +389 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +390 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +391 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +392 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +393 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +394 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +395 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +396 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +397 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +398 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +399 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility reduced motion removes the phase transition animation
00:10 +400 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +401 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +402 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +403 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +404 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +405 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states loading skeleton shows until the inbox answers
00:10 +406 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: request inbox states expired, busy and cancelled requests render honest cards
00:10 +407 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +408 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +409 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +410 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +411 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +412 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +413 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +414 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +415 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:10 +416 ~2 -3: D:/TrainingArena/app/test/battle/battle_widget_test.dart: preview fixtures fixture mode is labelled on the Battle tab
00:11 +417 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +418 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +419 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +420 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +421 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +422 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +423 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +424 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +425 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +426 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +427 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +428 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +429 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +430 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +431 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +432 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +433 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +434 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +435 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +436 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +437 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +438 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +439 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +440 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +441 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +442 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +443 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +444 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +445 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +446 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +447 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +448 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +449 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +450 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +451 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +452 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +453 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +454 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +455 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +456 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +457 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +458 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +459 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +460 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +461 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +462 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +463 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +464 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +465 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +466 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +467 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +468 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +469 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +470 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +471 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +472 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +473 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +474 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +475 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +476 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +477 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +478 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +479 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +480 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +481 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +482 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +483 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +484 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +485 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +486 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +487 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +488 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +489 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +490 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +491 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +492 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +493 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +494 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +495 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +496 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +497 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +498 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +499 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +500 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +501 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +502 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +503 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +504 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +505 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +506 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +507 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +508 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +509 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +510 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +511 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +512 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +513 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +514 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +515 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +516 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +517 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +518 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +519 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +520 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +521 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +522 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +523 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +524 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +525 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +526 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +527 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +528 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +529 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +530 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +531 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +532 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +533 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +534 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +535 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +536 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +537 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +538 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +539 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +540 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +541 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +542 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +543 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +544 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +545 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +546 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +547 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +548 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +549 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +550 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +551 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +552 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +553 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +554 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +555 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +556 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +557 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +558 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +559 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +560 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +561 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +562 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +563 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +564 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +565 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +566 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +567 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +568 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +569 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +570 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +571 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:15 +572 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:15 +573 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:15 +574 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:15 +575 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:15 +576 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:15 +577 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +578 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +579 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +580 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +581 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +582 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +583 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +584 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +585 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +586 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +587 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +588 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +589 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +590 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +591 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +592 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +593 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +594 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +595 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +596 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +597 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +598 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +599 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +600 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +601 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +602 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +603 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +604 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +605 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +606 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +607 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +608 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +609 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +610 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +611 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +612 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +613 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +614 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +615 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +616 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +617 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +618 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +619 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +620 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +621 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +622 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +623 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +624 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +625 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +626 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:17 +627 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:17 +628 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:17 +629 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:17 +630 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry opens the solo page when the flag is on
00:17 +631 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: manual entry reaches a labelled result and saves
00:17 +632 ~2 -3: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting

```

## WP4 SYNTHETIC enum copy placement widgets and counted feedback acceptance

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter_copy_test.dart test/camera/phone_placement_widget_test.dart test/camera/counted_rep_feedback_test.dart --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter_copy_test.dart
test/camera/phone_placement_widget_test.dart:34:22: Error: This expression has type 'void' and can't be used.
    await controller.startCamera();
                     ^
00:00 +0 -1: loading D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart [E]
  Failed to load "D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart":
  Compilation failed for testPath=D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: test/camera/phone_placement_widget_test.dart:34:22: Error: This expression has type 'void' and can't be used.
      await controller.startCamera();
                       ^
  .
00:00 +0 -2: loading D:/TrainingArena/app/test/camera/counter_copy_test.dart [E]
  Error: The Dart compiler exited unexpectedly.
  package:flutter_tools/src/base/common.dart 34:3  throwToolExit
  package:flutter_tools/src/compile.dart 1024:11   DefaultResidentCompiler._compile.<fn>
  dart:async/zone_root.dart 48:47                  _rootRunUnary
  dart:async/zone.dart 816:35                      _CustomZone.runUnary
  dart:async/future_impl.dart 948:45               Future._propagateToListeners.handleValueCallback
  dart:async/future_impl.dart 977:13               Future._propagateToListeners
  dart:async/future_impl.dart 862:9                Future._propagateToListeners
  dart:async/future_impl.dart 720:5                Future._completeWithValue
  dart:async/future_impl.dart 804:7                Future._asyncCompleteWithValue.<fn>
  dart:async/zone_root.dart 35:13                  _rootRun
  dart:async/zone.dart 810:35                      _CustomZone.run
  dart:async/zone.dart 702:7                       _CustomZone.runGuarded
  dart:async/zone.dart 743:23                      _CustomZone.bindCallbackGuarded.<fn>
  dart:async/schedule_microtask.dart 40:35         _microtaskLoop
  dart:async/schedule_microtask.dart 49:5          _startMicrotaskLoop
  dart:isolate-patch/isolate_patch.dart 127:13     _runPendingImmediateCallback
  dart:isolate-patch/isolate_patch.dart 193:5      _RawReceivePort._handleMessage
  
00:00 +0 -2: D:/TrainingArena/app/test/camera/counter_copy_test.dart: every CounterRejection has nonempty plain-language copy
00:00 +1 -2: D:/TrainingArena/app/test/camera/counter_copy_test.dart: every TrackingPauseReason has nonempty copy for both exercises
00:01 +2 -2: D:/TrainingArena/app/test/camera/counted_rep_feedback_test.dart: SYNTHETIC accepted practice rep cues once; duplicate and shallow frames do not cue
00:01 +3 -2: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter_copy_test.dart: loading D:/TrainingArena/app/test/camera/counter_copy_test.dart
  D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: loading D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart

```

## WP4 targeted attempt 2 SYNTHETIC copy placement and feedback

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/counter_copy_test.dart test/camera/phone_placement_widget_test.dart test/camera/counted_rep_feedback_test.dart --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/camera/counter_copy_test.dart
00:00 +0: D:/TrainingArena/app/test/camera/counter_copy_test.dart: every CounterRejection has nonempty plain-language copy
00:00 +1: D:/TrainingArena/app/test/camera/counter_copy_test.dart: every TrackingPauseReason has nonempty copy for both exercises
00:00 +2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:00 +3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:01 +4: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:01 +5: All tests passed!

```

## WP4 end flutter analyze

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing app...                                                
No issues found! (ran in 3.6s)

```

## WP4 end flutter test

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Waiting for another flutter command to release the startup lock...
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/account/account_api_test.dart
00:00 +0: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport fetchProfile posts the action envelope with bearer and anon key
00:00 +1: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport unconfigured builds never touch the network
00:00 +2: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a missing token fails closed as unauthenticated
00:00 +3: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport transport failures surface as retryable network errors
00:00 +4: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a TLS handshake failure is an offline retry, not a raw IO error
00:00 +5: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport 401 answers are unauthenticated; 500 answers are retryable
00:00 +6: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport business errors use the server code and actionable copy
00:00 +7: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +8: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +9: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +10: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +11: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +12: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +13: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +14: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +15: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +16: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a rejected session fails closed to signed out with plain copy
00:00 +17: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block publicProfile never surfaces extra private fields
00:00 +18: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +19: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +20: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +21: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block block, unblock and blocked use the documented actions
00:00 +22: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a refused refresh ends the session and drops the token
00:00 +23: D:/TrainingArena/app/test/account/account_api_test.dart: public profile, report and block deleteAccount posts the documented action
00:00 +24: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in Google sign-in loads the profile and refreshes the viewer
00:00 +25: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in a first sign-in without a username stays in the username step
00:00 +26: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in email-code sign-in asks for the code and never keeps the address
00:00 +27: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in cancellation surfaces the plain provider message
00:00 +28: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim normalizes before sending and updates the viewer
00:00 +29: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim an unchanged name is a no-op without a round trip
00:00 +30: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim a server race reports an actionable duplicate message
00:00 +31: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim invalid local input never reaches the backend
00:00 +32: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim claiming before sign-in fails closed
00:00 +33: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar accepts a valid image and sends sniffed base64
00:00 +34: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects camera frames before any upload
00:00 +35: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects oversized images before any upload
00:00 +36: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar a rejected image keeps the profile and reports the reason
00:00 +37: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar remove is available with and without an avatar
00:00 +38: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion sign-out clears local state even when the server call fails
00:00 +39: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion deleteAccount clears local state and reports the result
00:00 +40: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion a failed deletion keeps the session for a retry
00:00 +41: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +42: D:/TrainingArena/app/test/account/account_durable_session_test.dart: deleteAccount does not claim durable removal when storage fails
00:00 +43: D:/TrainingArena/app/test/account/account_durable_session_test.dart: a failed server deletion keeps the valid session
00:00 +44: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a refresh that finishes after sign-out cannot resurrect the session
00:00 +45: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +46: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +47: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +48: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +49: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +50: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +51: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed older sign-in cannot overwrite a newer account
00:00 +52: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername empty, short, long, bad characters and reserved names fail
00:00 +53: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a newer identity does not join the prior account pending refresh
00:00 +54: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalized input is what the backend receives
00:00 +55: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +56: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +57: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits sniffs JPEG, PNG and WebP signatures
00:00 +58: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +59: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits camera-like raw bytes are never a supported image
00:00 +60: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +61: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +62: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +63: D:/TrainingArena/app/test/account/account_models_test.dart: AccountException classifies unauthenticated and retryable failures
00:00 +64: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed migration cannot survive a later clear and newer write
00:00 +65: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +66: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refused delete during clear still lets the newer write win
00:00 +67: D:/TrainingArena/app/test/account/account_models_test.dart: leaderboard and public player view objects leaderboard rows know the viewer and compare by value
00:00 +68: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering PKCE ordering holds for a delayed write, clear and newer write
00:00 +69: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering PKCE ordering holds for a delayed write, clear and newer write
00:00 +70: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +71: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a superseded sign-in cannot persist over the newer account
00:00 +72: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +73: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a pending refresh cannot overwrite a newer sign-in in storage
00:00 +74: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed logout cannot erase a verifier saved after it
00:00 +75: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: Google sign-in returns to the same challenge and claims a username
00:00 +76: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: email-code sign-in keeps the same token through both prompts
00:00 +77: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: a duplicate username re-prompts without losing the challenge
00:00 +78: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: restart restores the waiting challenge with the same token
00:01 +79: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController loads exactly the confirmed rows
00:01 +80: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an empty ladder is an honest empty state, not an error
00:01 +81: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController the viewer row outside the top page is surfaced as-is
00:01 +82: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an offline refresh keeps the last confirmed page
00:01 +83: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController a server error is not retryable and keeps the confirmed page
00:01 +84: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an unconfigured build reports the flag without inventing rows
00:01 +85: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController reset drops every row and goes back to initial
00:01 +86: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController loads confirmed receipts unchanged
00:01 +87: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an empty history is an honest empty state
00:01 +88: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an offline refresh keeps the last confirmed receipts
00:01 +89: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController reset drops every receipt on sign-out
00:01 +90: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a Google redirect after process death returns to the same challenge
00:01 +91: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: an email-code sign-in after process death keeps the same challenge
00:01 +92: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a redirect that does not match the allowlist is ignored
00:01 +93: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +94: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +95: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +96: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +97: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +98: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +99: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +100: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +101: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +102: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +103: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +104: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +105: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +106: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +107: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +108: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +109: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +110: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +111: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +112: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:02 +113: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +114: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +115: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +116: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +117: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +118: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +119: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +120: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +121: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +122: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +123: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +124: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +125: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +126: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +127: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +128: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +129: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +130: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +131: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +132: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +133: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +134: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +135: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +136: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +137: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +138: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +139: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +140: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +141: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +142: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +143: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +144: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +145: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +146: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +147: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +148: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:03 +149: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +150: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +151: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +152: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +153: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +154: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +155: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +156: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +157: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +158: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +159: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +160: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +161: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +162: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +163: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +164: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +165: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +166: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +167: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +168: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +169: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +170: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +171: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +172: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +173: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +174: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +175: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +176: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +177: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +178: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +179: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +180: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +181: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +182: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +183: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +184: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +185: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +186: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +187: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +188: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +189: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +190: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +191: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +192: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +193: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +194: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +195: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +196: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +197: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +198: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +199: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +200: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +201: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +202: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +203: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +204: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +205: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +206: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +207: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +208: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +209: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +210: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +211: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +212: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +213: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +214: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +215: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +216: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +217: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +218: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:05 +219: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +220: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +221: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +222: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +223: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +224: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +225: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +226: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +227: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +228: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +229: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +230: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +231: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +232: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +233: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +234: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +235: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +236: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +237: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +238: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +239: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +240: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +241: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +242: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +243: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +244: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +245: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +246: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +247: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +248: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +249: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +250: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +251: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +252: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +253: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +254: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +255: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +256: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +257: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +258: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +259: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +260: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +261: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +262: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +263: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +264: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +265: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +266: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +267: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +268: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +269: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +270: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +271: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +272: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +273: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +274: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +275: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +276: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +277: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +278: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +279: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:07 +280: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +281: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +282: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +283: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +284: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +285: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +286: D:/TrainingArena/app/test/camera/counted_rep_feedback_test.dart: SYNTHETIC accepted practice rep cues once; duplicate and shallow frames do not cue
00:07 +287: D:/TrainingArena/app/test/camera/camera_session_test.dart: lifecycle background pauses and foreground resumes the camera
00:07 +288: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a paused session draws no skeleton
00:07 +289: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a paused session draws no skeleton
00:07 +290: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a paused session draws no skeleton
00:07 +291: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +292: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +293: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +294: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +295: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +296: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +297: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +298: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +299: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +300: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +301: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +302: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +303: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +304: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +305: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +305: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2} | outcomes [10, 10, 10, 10, 10]
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {} | outcomes [10, 10, 10, 9, 10]
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
00:08 +305 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:08 +305 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: ['push noise .02 seed 4 has 9 outcomes for 10 descents']
  push noise .02 seed 4 has 9 outcomes for 10 descents
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 95:5  main.<fn>
  
00:08 +306 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +307 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +308 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +309 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +310 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +311 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +312 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +313 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +313 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +313 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:08 +314 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +315 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +316 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +317 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +318 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +319 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +320 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +321 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +322 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +323 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +324 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +325 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +326 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +327 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +328 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +329 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during a live round explains the forfeit honestly
00:08 +330 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +331 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +332 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +333 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +334 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +335 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +336 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +337 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +338 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +339 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +340 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +341 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +342 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +343 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +344 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +345 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +346 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +347 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:08 +347 -2: D:/TrainingArena/app/test/camera/generate_pose_fixtures_test.dart: regenerates the committed pose fixtures
  Skip: set FIXTURE_GEN=1 to regenerate
00:08 +347 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:08 +348 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:08 +349 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +349 ~1 -2: D:/TrainingArena/app/test/camera/overlay_paint_cost_test.dart: overlay paint cost, host only
  Skip: set OVERLAY_BENCH=1 to measure
00:09 +349 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +350 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +351 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +352 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +353 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +354 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +355 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +356 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +357 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +358 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +359 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +360 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +361 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +362 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +363 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +364 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +365 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +366 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +367 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +368 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +369 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +370 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +371 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +372 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +373 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +374 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +375 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +376 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +377 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +378 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +379 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +380 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +381 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +382 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +383 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +384 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +385 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +386 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +387 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +387 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +387 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 199:7             main.<fn>.<fn>
  
00:10 +388 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +389 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +390 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +391 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +392 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +393 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +394 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +395 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +396 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +397 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +398 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +399 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +400 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +401 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +402 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +403 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +404 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +405 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +406 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
SYNTHETIC {counted_reps: 2, rejection_histogram: {}, cycles: [{timestamp_us: 2673000, outcome: counted, min_smoothed: 86.8131127524183, max_smoothed: 147.1670276677228}, {timestamp_us: 4653000, outcome: counted, min_smoothed: 86.01027679921629, max_smoothed: 146.87394404043283}], side_switches: 0, pause_reasons_by_frame: {}}
00:10 +407 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +408 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +409 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +410 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +411 ~2 -3: D:/TrainingArena/app/test/copy/forbidden_claims_test.dart: no forbidden claim appears in a lib/ string literal
00:10 +412 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +413 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +414 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +415 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +416 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares verified App Links for the configurable host
00:10 +417 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares the trainingarena fallback and app_links routing
00:10 +418 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: gradle keeps the placeholder host and Play referrer dependency
00:10 +419 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: install referrer bridge uses the stable channel contract
00:10 +420 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: assetlinks template documents relation, package and fingerprint
00:10 +421 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: Android backup is off so credentials cannot leave the device
00:10 +422 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +423 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +424 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +425 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +426 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +427 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +428 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +429 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +430 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +431 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +432 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +433 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +434 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +435 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +436 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +437 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +438 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +439 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +440 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +441 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +442 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +443 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +444 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +445 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +446 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +447 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +448 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +449 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +450 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +451 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +452 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +453 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +454 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +455 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +456 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +457 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +458 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +459 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +460 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +461 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +462 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +463 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +464 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +465 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +466 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +467 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +468 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +469 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +470 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +471 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +472 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +473 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +474 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +475 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +476 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +477 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +478 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +479 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +480 ~2 -3: D:/TrainingArena/app/test/matchmaking/ranked_search_test.dart: server-issued match handoff a real queue match enters preparation with mode and match id
00:12 +481 ~2 -3: D:/TrainingArena/app/test/notifications/android_push_host_config_test.dart: bridge implements every Dart channel and method of the contract
00:12 +482 ~2 -3: D:/TrainingArena/app/test/notifications/android_push_host_config_test.dart: bridge implements every Dart channel and method of the contract
00:12 +483 ~2 -3: D:/TrainingArena/app/test/notifications/android_push_host_config_test.dart: bridge implements every Dart channel and method of the contract
00:12 +484 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +485 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +486 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +487 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +488 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +489 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +490 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +491 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: revoked link shows the honest unavailable state
00:12 +492 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +493 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +494 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +495 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +496 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +497 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +498 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +499 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +500 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +501 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +502 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +503 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +504 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +505 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +506 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +507 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +508 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +509 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +510 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +511 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +512 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +513 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +514 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +515 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +516 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +517 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +518 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +519 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +520 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +521 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +522 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +523 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +524 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +525 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +526 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +527 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +528 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +529 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +530 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +531 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +532 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +533 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +534 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +535 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +536 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +537 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +538 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +539 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +540 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +541 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +542 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +543 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +544 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +545 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +546 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +547 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +548 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +549 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +550 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +551 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +552 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +553 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +554 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +555 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +556 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +557 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +558 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +559 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +560 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +561 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +562 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +563 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +564 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +565 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +566 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +567 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +568 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +569 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +570 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +571 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +572 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +573 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +574 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +575 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +576 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +577 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +578 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +579 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +580 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +581 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +582 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +583 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +584 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +585 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +586 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +587 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +588 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +589 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +590 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +591 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +592 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +593 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +594 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +595 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +596 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +597 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +598 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +599 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +600 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +601 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +602 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +603 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +604 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +605 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +606 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +607 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +608 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +609 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +610 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +611 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +612 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +613 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +614 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +615 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +616 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +617 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +618 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +619 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +620 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +621 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +622 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +623 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +624 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +625 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +626 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +627 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +628 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +629 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +630 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +631 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +632 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: a share-sheet failure keeps the preview card visible
00:16 +633 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:16 +634 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:16 +635 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry opens the solo page when the flag is on
00:16 +636 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: manual entry reaches a labelled result and saves
00:17 +637 ~2 -3: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting

```

## Pre-final source inventory for protected server fixture version conflict

Command: `rtk rg -n fixture/|counter/|test-counter|counter_version supabase/tests`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
supabase/tests\arena_goal_hardening_test.sql:17:select ok((select relrowsecurity from pg_class where oid='public.arena_counter_versions'::regclass),
supabase/tests\arena_goal_hardening_test.sql:19:select ok(not has_table_privilege('anon','public.arena_counter_versions','SELECT'),
supabase/tests\arena_goal_hardening_test.sql:21:select ok(not has_table_privilege('authenticated','public.arena_counter_versions','INSERT'),
supabase/tests\arena_goal_hardening_test.sql:23:select ok(exists(select 1 from public.arena_counter_versions where version='arena-counter/1.2.1'),
supabase/tests\arena_goal_hardening_test.sql:25:select ok(exists(select 1 from public.arena_counter_versions where version='1.3.0'),
supabase/tests\arena_goal_hardening_test.sql:40:insert into public.arena_match_events(match_id,user_id,event_id,sequence,observed_at,received_at,counter_version)
supabase/tests\arena_goal_hardening_test.sql:43:insert into public.arena_match_events(match_id,user_id,event_id,sequence,observed_at,received_at,counter_version)
supabase/tests\arena_goal_hardening_test.sql:48:  'AR001','counter_version must be an allowed semantic version','malformed version fails');
supabase/tests\arena_goal_hardening_test.sql:50:  'AR001','counter_version must be an allowed semantic version','unknown semantic version fails');
supabase/tests\arena_goal_hardening_test.sql:51:select throws_ok($$select public.arena_match_rep(actor,actor,match_id,gen_random_uuid(),10,now(),'arena-counter/1.2.1') from goal_fixture$$,
supabase/tests\arena_goal_hardening_test.sql:52:  'AR001','counter_version must be an allowed semantic version','legacy prefix fails strict semantic-version gate');
supabase/tests\arena_schema_test.sql:324:insert into public.arena_match_events (match_id, user_id, event_id, sequence, observed_at, counter_version)

```

## Pre-final exact legacy SQL rep fixture arguments

Command: `rtk rg -n -A 10 arena_match_rep supabase/tests/arena_flow_test.sql`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
371:  public.arena_match_rep(
372-    'b0000000-0000-4000-8000-000000000002',
373-    'b0000000-0000-4000-8000-000000000002',
374-    (select match_id from flow),
375-    'e0000000-0000-4000-8000-000000000001',
376-    1,
377-    now(),
378-    'test-1'
379-  )->'match'->'players'->0->>'score',
380-  '1',
381-  'a valid live rep is counted'
--
384:  public.arena_match_rep(
385-    'b0000000-0000-4000-8000-000000000002',
386-    'b0000000-0000-4000-8000-000000000002',
387-    (select match_id from flow),
388-    'e0000000-0000-4000-8000-000000000001',
389-    1,
390-    now(),
391-    'test-1'
392-  )->'match'->'players'->0->>'score',
393-  '1',
394-  'a retried event_id does not double-count'
--
405:    $$ select public.arena_match_rep(
406-         'b0000000-0000-4000-8000-000000000002',
407-         'b0000000-0000-4000-8000-000000000002',
408-         %L, 'e0000000-0000-4000-8000-000000000002', 1, now(), 'test-1'
409-       ) $$,
410-    (select match_id from flow)
411-  ),
412-  'AR015',
413-  null,
414-  'a stale sequence is rejected'
415-);
--
418:    $$ select public.arena_match_rep(
419-         'b0000000-0000-4000-8000-000000000002',
420-         'b0000000-0000-4000-8000-000000000002',
421-         %L, 'e0000000-0000-4000-8000-000000000003', 2, now() + interval '1 hour', 'test-1'
422-       ) $$,
423-    (select match_id from flow)
424-  ),
425-  'AR015',
426-  null,
427-  'a rep observed far outside the round window is rejected'
428-);
--
434:    $$ select public.arena_match_rep(
435-         'b0000000-0000-4000-8000-000000000002',
436-         'b0000000-0000-4000-8000-000000000002',
437-         %L, 'e0000000-0000-4000-8000-000000000004', 2, now(), 'test-1'
438-       ) $$,
439-    (select match_id from flow)
440-  ),
441-  'AR016',
442-  null,
443-  'stale tracking rejects new reps'
444-);
--
451:  public.arena_match_rep(
452-    'b0000000-0000-4000-8000-000000000002',
453-    'b0000000-0000-4000-8000-000000000002',
454-    (select match_id from flow),
455-    'e0000000-0000-4000-8000-000000000005',
456-    2,
457-    now(),
458-    'test-1'
459-  )->'match'->'players'->0->>'score',
460-  '2',
461-  'a fresh event with an increasing sequence is counted'
--
465:    $$ select public.arena_match_rep(
466-         'b0000000-0000-4000-8000-000000000002',
467-         'b0000000-0000-4000-8000-000000000002',
468-         %L, 'e0000000-0000-4000-8000-000000000006', 3, now(), 'test-1'
469-       ) $$,
470-    (select match_id from flow)
471-  ),
472-  'AR017',
473-  null,
474-  'rep flooding is rate limited'
475-);
--
525:    $$ select public.arena_match_rep(
526-         'b0000000-0000-4000-8000-000000000002',
527-         'b0000000-0000-4000-8000-000000000002',
528-         %L, 'e0000000-0000-4000-8000-000000000007', 3, now(), 'test-1'
529-       ) $$,
530-    (select match_id from flow)
531-  ),
532-  'AR014',
533-  null,
534-  'new reps after the final whistle are rejected'
535-);
--
537:  public.arena_match_rep(
538-    'b0000000-0000-4000-8000-000000000002',
539-    'b0000000-0000-4000-8000-000000000002',
540-    (select match_id from flow),
541-    'e0000000-0000-4000-8000-000000000005',
542-    3,
543-    now(),
544-    'test-1'
545-  )->'match'->>'status',
546-  'finished',
547-  'a retried accepted event on a closed match is still idempotent'

```

## Pre-final current branch and one commit per WP

Command: `rtk git log -5 --oneline`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ec270d5 feat(camera): WP4 placement guidance and counted rep feedback
5c77700 fix(release): WP3 public output and marketing guardrails
3d18b88 fix(server): WP2 rate limits counter allow-list and avatar headers
5700dbc fix(camera): WP1 candidate counter and reproducible trace diagnostics
74d28fd docs(audit): record pinned baseline for WP0

```

## FINAL VERIFICATION existing release hold check once

Command: `rtk proxy node tools/release/check_release_flags.mjs`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
release flag check passed

```

## FINAL VERIFICATION database runtime availability

Command: `rtk proxy docker version`
Working directory: `D:\TrainingArena`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Client:
 Version:           29.4.2
 API version:       1.54
 Go version:        go1.26.2
 Git commit:        055a478
 Built:             Fri May  1 01:27:10 2026
 OS/Arch:           windows/amd64
 Context:           desktop-linux
failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine; check if the path is correct and if the daemon is running: open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.

```

## FINAL VERIFICATION Deno runtime availability

Command: `rtk proxy powershell -NoProfile -Command "[bool](Get-Command deno -ErrorAction SilentlyContinue)"`
Working directory: `D:\TrainingArena`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
False

```

## FINAL VERIFICATION flutter analyze once

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze`
Working directory: `D:\TrainingArena\app`
Exit code: 0
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing app...                                                
No issues found! (ran in 2.5s)

```

## FINAL VERIFICATION flutter test once including SYNTHETIC AFTER matrix

Command: `rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --reporter expanded`
Working directory: `D:\TrainingArena\app`
Exit code: 1
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Waiting for another flutter command to release the startup lock...
Resolving dependencies...
Downloading packages...
  app_links 7.2.1 (7.2.2 available)
  app_links_linux 1.0.3 (1.0.4 available)
  app_links_web 1.0.4 (1.0.5 available)
  async 2.11.0 (2.13.1 available)
  boolean_selector 2.1.1 (2.1.2 available)
  cross_file 0.3.5+5 (0.4.0 available)
  flutter_lints 4.0.0 (6.0.0 available)
  http_parser 4.0.2 (4.1.2 available)
  lints 4.0.0 (6.1.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  path_provider 2.1.5 (2.1.6 available)
  path_provider_android 2.2.15 (2.3.1 available)
  path_provider_foundation 2.4.1 (2.6.0 available)
  path_provider_linux 2.2.1 (2.2.2 available)
  path_provider_platform_interface 2.1.2 (2.1.3 available)
  platform 3.1.6 (3.2.0 available)
  qr 3.0.2 (4.0.0 available)
  share_plus 13.3.0 (13.3.1 available)
  shared_preferences 2.5.3 (2.5.6 available)
  shared_preferences_android 2.4.7 (2.4.28 available)
  shared_preferences_foundation 2.5.4 (2.5.7 available)
  shared_preferences_platform_interface 2.4.1 (2.4.2 available)
  source_span 1.10.0 (1.10.2 available)
  string_scanner 1.2.0 (1.4.1 available)
  term_glyph 1.2.1 (1.2.2 available)
  test_api 0.7.12 (0.7.15 available)
  url_launcher 6.3.1 (6.3.3 available)
  url_launcher_android 6.3.14 (6.3.33 available)
  url_launcher_ios 6.3.3 (6.4.2 available)
  url_launcher_macos 3.2.2 (3.2.6 available)
  vm_service 14.2.5 (15.3.0 available)
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading D:/TrainingArena/app/test/account/account_api_test.dart
00:00 +0: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport fetchProfile posts the action envelope with bearer and anon key
00:00 +1: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport unconfigured builds never touch the network
00:00 +2: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a missing token fails closed as unauthenticated
00:00 +3: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport transport failures surface as retryable network errors
00:00 +4: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport a TLS handshake failure is an offline retry, not a raw IO error
00:00 +5: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport 401 answers are unauthenticated; 500 answers are retryable
00:00 +6: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport business errors use the server code and actionable copy
00:00 +7: D:/TrainingArena/app/test/account/account_api_test.dart: envelope and transport server messages mentioning tokens are replaced
00:00 +8: D:/TrainingArena/app/test/account/account_api_test.dart: profile mutations profile_update normalizes nothing and sends the given name
00:00 +9: D:/TrainingArena/app/test/account/account_api_test.dart: profile mutations avatar_update sends base64 and mime_type from the picker
00:00 +10: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing leaderboard keeps only rows with an id and a positive rank
00:00 +11: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing history parses a ranked receipt and drops malformed rows
00:00 +12: D:/TrainingArena/app/test/account/account_api_test.dart: leaderboard and history parsing a win without a winner id is dropped
00:00 +13: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +14: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +15: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +16: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +17: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle no stored session lands signed out with no profile
00:00 +18: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a restored session loads the authoritative profile
00:00 +19: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a profile that cannot load keeps the session and stays retryable
00:00 +20: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a rejected session fails closed to signed out with plain copy
00:00 +21: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle expired local sessions refresh through the gateway
00:00 +22: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle accessToken returns the stored token when refresh is offline
00:00 +23: D:/TrainingArena/app/test/account/account_controller_test.dart: session lifecycle a refused refresh ends the session and drops the token
00:00 +24: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in Google sign-in loads the profile and refreshes the viewer
00:00 +25: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in a first sign-in without a username stays in the username step
00:00 +26: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in email-code sign-in asks for the code and never keeps the address
00:00 +27: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-in cancellation surfaces the plain provider message
00:00 +28: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim normalizes before sending and updates the viewer
00:00 +29: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim an unchanged name is a no-op without a round trip
00:00 +30: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim a server race reports an actionable duplicate message
00:00 +31: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim invalid local input never reaches the backend
00:00 +32: D:/TrainingArena/app/test/account/account_controller_test.dart: username claim claiming before sign-in fails closed
00:00 +33: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar accepts a valid image and sends sniffed base64
00:00 +34: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects camera frames before any upload
00:00 +35: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar rejects oversized images before any upload
00:00 +36: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar a rejected image keeps the profile and reports the reason
00:00 +37: D:/TrainingArena/app/test/account/account_controller_test.dart: avatar remove is available with and without an avatar
00:00 +38: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion sign-out clears local state even when the server call fails
00:00 +39: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion deleteAccount clears local state and reports the result
00:00 +40: D:/TrainingArena/app/test/account/account_controller_test.dart: sign-out and deletion a failed deletion keeps the session for a retry
00:00 +41: D:/TrainingArena/app/test/account/account_durable_session_test.dart: signOut reports a durable failure when the secure copy cannot be erased
00:00 +42: D:/TrainingArena/app/test/account/account_durable_session_test.dart: deleteAccount does not claim durable removal when storage fails
00:00 +43: D:/TrainingArena/app/test/account/account_durable_session_test.dart: a failed server deletion keeps the valid session
00:00 +44: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a refresh that finishes after sign-out cannot resurrect the session
00:00 +45: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out drops the session immediately, before the gateway answers
00:00 +46: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation sign-out without an in-memory session clears pending durable auth
00:00 +47: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a restore that finishes after sign-out cannot sign the user back in
00:00 +48: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +49: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +50: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalize trims only surrounding whitespace
00:00 +51: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: controller identity invalidation a delayed expired-response logout cannot clear a newer sign-in
00:00 +52: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername isSame compares normalized names without case
00:00 +53: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a deletion that finishes after a newer sign-in cannot clear it
00:00 +54: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername valid names pass at both length bounds
00:00 +55: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +56: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: deletion and profile ordering a stale profile mutation cannot overwrite a newer account
00:00 +57: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaUsername normalized input is what the backend receives
00:00 +58: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +59: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +60: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed write cannot outlive a later clear or a newer write
00:00 +61: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits camera-like raw bytes are never a supported image
00:00 +62: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed migration cannot survive a later clear and newer write
00:00 +63: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +64: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +65: D:/TrainingArena/app/test/account/account_models_test.dart: ArenaAvatarLimits validation messages are actionable and catch every rejection
00:00 +66: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +67: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +68: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +69: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +70: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a refresh that finishes after logout cannot rewrite the cleared session
00:00 +71: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a superseded sign-in cannot persist over the newer account
00:00 +72: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a stale restore cannot clear the verifier of a newer sign-in
00:00 +73: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a pending refresh cannot overwrite a newer sign-in in storage
00:00 +74: D:/TrainingArena/app/test/account/account_lifecycle_ordering_test.dart: durable store ordering a delayed logout cannot erase a verifier saved after it
00:00 +75: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: Google sign-in returns to the same challenge and claims a username
00:00 +76: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: email-code sign-in keeps the same token through both prompts
00:00 +77: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: a duplicate username re-prompts without losing the challenge
00:00 +78: D:/TrainingArena/app/test/account/challenge_continuity_test.dart: restart restores the waiting challenge with the same token
00:00 +79: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController loads exactly the confirmed rows
00:00 +80: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an empty ladder is an honest empty state, not an error
00:00 +81: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController the viewer row outside the top page is surfaced as-is
00:01 +82: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an offline refresh keeps the last confirmed page
00:01 +83: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController a server error is not retryable and keeps the confirmed page
00:01 +84: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController an unconfigured build reports the flag without inventing rows
00:01 +85: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: LeaderboardController reset drops every row and goes back to initial
00:01 +86: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController loads confirmed receipts unchanged
00:01 +87: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an empty history is an honest empty state
00:01 +88: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController an offline refresh keeps the last confirmed receipts
00:01 +89: D:/TrainingArena/app/test/account/leaderboard_history_controller_test.dart: BattleHistoryController reset drops every receipt on sign-out
00:01 +90: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a Google redirect after process death returns to the same challenge
00:01 +91: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: an email-code sign-in after process death keeps the same challenge
00:01 +92: D:/TrainingArena/app/test/account/oauth_return_continuity_test.dart: a redirect that does not match the allowlist is ignored
00:01 +93: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +94: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +95: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +96: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +97: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +98: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +99: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +100: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +101: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +102: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +103: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +104: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +105: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +106: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +107: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +108: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +109: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +110: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +111: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +112: D:/TrainingArena/app/test/account/profile_surfaces_test.dart: ProfileTab shows exactly the contract fields and actions
00:01 +113: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:01 +114: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:01 +115: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:01 +116: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:01 +117: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:01 +118: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +119: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +120: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +121: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +122: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +123: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +124: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +125: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +126: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +127: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +128: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +129: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +130: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +131: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +132: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +133: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +134: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +135: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +136: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +137: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +138: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +139: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +140: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +141: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +142: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +143: D:/TrainingArena/app/test/account/settings_public_pages_test.dart: SettingsPage public links opens the privacy, support and deletion pages
00:02 +144: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +145: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +146: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +147: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +148: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +149: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +150: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +151: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +152: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +153: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +154: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +155: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +156: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +157: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +158: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +159: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +160: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +161: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +162: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +163: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +164: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +165: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +166: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +167: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +168: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +169: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +170: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +171: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:02 +172: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +173: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +174: D:/TrainingArena/app/test/arena_shell_smoke_test.dart: shell shows Leaderboard/Battle/Profile and opens on Battle
00:03 +175: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +176: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +177: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +178: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +179: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +180: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +181: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +182: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +183: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +184: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +185: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +186: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +187: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +188: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +189: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +190: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +191: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +192: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +193: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +194: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +195: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +196: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +197: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +198: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +199: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +200: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +201: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +202: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +203: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +204: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +205: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +206: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +207: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:03 +208: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +209: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +210: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +211: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +212: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +213: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +214: D:/TrainingArena/app/test/battle/battle_contract_test.dart: a finished match without a receipt never renders a result
00:04 +215: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +216: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +217: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +218: D:/TrainingArena/app/test/battle/battle_ranked_gate_widget_test.dart: ranked disabled replaces the action with honest copy
00:04 +219: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +220: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +221: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +222: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +223: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +224: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +225: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +226: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +227: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +228: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +229: D:/TrainingArena/app/test/battle/battle_widget_test.dart: Battle home hierarchy incoming request, hero, ranked and code render in order
00:05 +230: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +231: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +232: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +233: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +234: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +235: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +236: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +237: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +238: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +239: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +240: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +241: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +242: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +243: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +244: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +245: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +246: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +247: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +248: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +249: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:05 +250: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +251: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +252: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +253: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +254: D:/TrainingArena/app/test/battle/my_challenge_link_test.dart: home exposes the confirmed account link without sending a request
00:06 +255: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +256: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +257: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +258: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +259: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +260: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +261: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +262: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +263: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +264: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +265: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +266: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +267: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +268: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +269: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +270: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +271: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +272: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +273: D:/TrainingArena/app/test/battle/rematch_widget_test.dart: rematch waits for a fresh accepted match
00:06 +274: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +275: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +276: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +277: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +278: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +279: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +280: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +281: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +282: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +283: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:06 +284: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +285: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +286: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +287: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +288: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +289: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +290: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +291: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +292: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +293: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +294: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +295: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow practice rep gates ready; both-ready gates the countdown
00:07 +296: D:/TrainingArena/app/test/camera/camera_preview_test.dart: the debug trace bar records, exports and deletes a trace
00:07 +297: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +298: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +299: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +300: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +301: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +302: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow live round shows server scores and the tracking banner
00:07 +303: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:07 +304: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:07 +305: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:07 +305: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
SYNTHETIC AFTER | mean/10 | seeds | rejection histogram
push 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 1.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.8s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 0.6s diagnostic | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 150-95 | 9.6 | [10, 9, 9, 10, 10] | {lockoutMissed: 2} | outcomes [10, 10, 10, 10, 10]
push 8fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 10fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push 30fps | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push noise .02 | 9.8 | [10, 10, 10, 9, 10] | {} | outcomes [10, 10, 10, 9, 10]
push y*.75 | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
push bottom115 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
push partial122 | 0.0 | [0, 0, 0, 0, 0] | {notDeepEnough: 50} | outcomes [10, 10, 10, 10, 10]
squat 1.2s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 1.6s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 2.1s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
squat 3.0s | 10.0 | [10, 10, 10, 10, 10] | {} | outcomes [10, 10, 10, 10, 10]
00:07 +305 -1: D:/TrainingArena/app/test/camera/camera_preview_test.dart: a judged rep that fails the check shows a transient cue card
00:07 +305 -1: D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds [E]
  Expected: empty
    Actual: ['push noise .02 seed 4 has 9 outcomes for 10 descents']
  push noise .02 seed 4 has 9 outcomes for 10 descents
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\camera\counter\counter_stress_matrix_test.dart 95:5  main.<fn>
  
00:08 +306 -1: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow back during preparation confirms before leaving
00:08 +307 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +308 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +309 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +310 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +311 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +312 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +313 -1: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +313 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +313 -2: D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame [E]
  Expected: CounterRejection:<CounterRejection.none>
    Actual: CounterRejection:<CounterRejection.notDeepEnough>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\fixture_replay_test.dart 124:7          main.<fn>
  
00:08 +314 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +315 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +316 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +317 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +318 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +319 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +320 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +321 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +322 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +323 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +324 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +325 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +326 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +327 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +328 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +329 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +330 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +331 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +332 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +333 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +334 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +335 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +336 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +337 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +338 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +339 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +340 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +341 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +342 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +343 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +344 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +345 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +346 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +346 -2: D:/TrainingArena/app/test/camera/generate_pose_fixtures_test.dart: regenerates the committed pose fixtures
  Skip: set FIXTURE_GEN=1 to regenerate
00:08 +346 ~1 -2: D:/TrainingArena/app/test/camera/diagnostics_hud_test.dart: SYNTHETIC diagnostics constructor flag false
00:08 +347 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:08 +348 ~1 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:08 +348 ~1 -2: D:/TrainingArena/app/test/camera/overlay_paint_cost_test.dart: overlay paint cost, host only
  Skip: set OVERLAY_BENCH=1 to measure
00:08 +348 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: match flow declining a request confirms and creates nothing
00:08 +349 ~2 -2: D:/TrainingArena/app/test/battle/battle_widget_test.dart: accessibility score panels carry full semantic labels
00:09 +350 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +351 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +352 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +353 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +354 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +355 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +356 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +357 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +358 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +359 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +360 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +361 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +362 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +363 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +364 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +365 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +366 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +367 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +368 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +369 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +370 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +371 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +372 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +373 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +374 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +375 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +376 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +377 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +378 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +379 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +380 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +381 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +382 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +383 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +384 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +385 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +386 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +387 ~2 -2: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +387 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +387 ~2 -3: D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting [E]
  Expected: <0>
    Actual: <1>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\camera\rep_counter_test.dart 199:7             main.<fn>.<fn>
  
00:09 +388 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +389 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +390 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +391 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +392 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +393 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +394 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +395 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:09 +396 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +397 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +398 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +399 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +400 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +401 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +402 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +403 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC preparation/practice screen gives exact placement guidance
00:10 +404 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
00:10 +405 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
00:10 +406 ~2 -3: D:/TrainingArena/app/test/camera/trace_replay_test.dart: SYNTHETIC replay prints counts, cycle extrema, side switches and pauses
SYNTHETIC {counted_reps: 2, rejection_histogram: {}, cycles: [{timestamp_us: 2673000, outcome: counted, min_smoothed: 86.8131127524183, max_smoothed: 147.1670276677228}, {timestamp_us: 4653000, outcome: counted, min_smoothed: 86.01027679921629, max_smoothed: 146.87394404043283}], side_switches: 0, pause_reasons_by_frame: {}}
00:10 +407 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +408 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +409 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +410 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +411 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +412 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +413 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +414 ~2 -3: D:/TrainingArena/app/test/camera/phone_placement_widget_test.dart: SYNTHETIC solo intro and camera practice give exact placement guidance
00:10 +415 ~2 -3: D:/TrainingArena/app/test/camera/pose_skeleton_overlay_test.dart: PoseSkeletonOverlay the counting chain flashes warning while a rep is rejected
00:10 +416 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares verified App Links for the configurable host
00:10 +417 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: manifest declares the trainingarena fallback and app_links routing
00:10 +418 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: gradle keeps the placeholder host and Play referrer dependency
00:10 +419 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: install referrer bridge uses the stable channel contract
00:10 +420 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: assetlinks template documents relation, package and fingerprint
00:10 +421 ~2 -3: D:/TrainingArena/app/test/linking/android_link_config_test.dart: Android backup is off so credentials cannot leave the device
00:10 +422 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +423 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +424 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +425 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +426 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +427 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +428 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +429 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +430 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +431 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +432 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +433 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +434 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +435 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +436 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +437 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +438 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +439 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +440 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +441 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +442 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +443 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +444 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +445 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +446 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +447 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +448 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +449 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +450 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +451 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +452 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +453 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +454 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +455 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +456 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +457 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +458 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +459 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +460 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:11 +461 ~2 -3: D:/TrainingArena/app/test/linking/arena_app_link_test.dart: ArenaApp opens a cold challenge link before the shell
00:12 +462 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +463 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +464 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +465 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +466 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +467 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +468 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +469 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +470 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +471 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +472 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +473 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +474 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +475 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +476 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +477 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +478 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: cold link lands on the challenger without visiting a tab
00:12 +479 ~2 -3: D:/TrainingArena/app/test/matchmaking/ranked_search_test.dart: truthful ranked search window starting a search during an active match is refused
00:12 +480 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +481 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +482 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +483 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +484 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +485 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +486 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +487 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +488 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: signed-out link returns to the same challenge after sign-in
00:12 +489 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: closing the challenge returns to the shell
00:12 +490 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: warm link interrupts the shell with the same landing
00:12 +491 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: revoked link shows the honest unavailable state
00:12 +492 ~2 -3: D:/TrainingArena/app/test/linking/challenge_entry_widget_test.dart: offline challenger offers a live request with no replay promise
00:12 +493 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +494 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +495 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +496 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +497 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +498 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:12 +499 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +500 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +501 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +502 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +503 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +504 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +505 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +506 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +507 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +508 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +509 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +510 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +511 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +512 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +513 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +514 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +515 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +516 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +517 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +518 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +519 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +520 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +521 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +522 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +523 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +524 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +525 ~2 -3: D:/TrainingArena/app/test/notifications/notification_gate_test.dart: a pending request renders with accept and decline actions
00:13 +526 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +527 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +528 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +529 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +530 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +531 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +532 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +533 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +534 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +535 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +536 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +537 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:13 +538 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +539 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +540 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +541 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +542 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +543 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +544 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +545 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +546 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +547 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +548 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +549 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_card_view_test.dart: Stories card renders every mandatory element
00:14 +550 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +551 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +552 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +553 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +554 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +555 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +556 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +557 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +558 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +559 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +560 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +561 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +562 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +563 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +564 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +565 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +566 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +567 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +568 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +569 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +570 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +571 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +572 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +573 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +574 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +575 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +576 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +577 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +578 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +579 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +580 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +581 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +582 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: stories export is exactly 1080x1920
00:14 +583 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +584 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +585 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +586 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +587 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +588 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +589 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +590 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +591 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +592 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +593 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +594 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +595 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +596 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +597 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +598 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +599 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:14 +600 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +601 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +602 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +603 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_preview_test.dart: preview renders the exact card and all three actions
00:15 +604 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +605 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +606 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +607 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +608 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +609 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +610 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +611 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:15 +612 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +613 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +614 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +615 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +616 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +617 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +618 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +619 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +620 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +621 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +622 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +623 ~2 -3: D:/TrainingArena/app/test/sharing/result_share_export_test.dart: every fixture exports at both exact sizes
00:16 +624 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +625 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +626 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +627 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +628 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +629 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +630 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +631 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +632 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: signed-out visitors can start solo before home notices
00:16 +633 ~2 -3: D:/TrainingArena/app/test/solo/solo_page_test.dart: recent history labels its source and personal best uses the same source
00:16 +634 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry is hidden when the flag is off
00:16 +635 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: the solo entry opens the solo page when the flag is on
00:16 +636 ~2 -3: D:/TrainingArena/app/test/solo/solo_gate_widget_test.dart: manual entry reaches a labelled result and saves
00:17 +637 ~2 -3: Some tests failed.

Failing tests:
  D:/TrainingArena/app/test/camera/counter/counter_stress_matrix_test.dart: SYNTHETIC stress matrix: ten continuous cycles across five seeds
  D:/TrainingArena/app/test/camera/fixture_replay_test.dart: pushups_half_depth.txt stays rejected with head and feet out of frame
  D:/TrainingArena/app/test/camera/rep_counter_test.dart: push-up counter a missing selected-side ankle gates counting

```
