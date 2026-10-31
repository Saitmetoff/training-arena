# Owner acceptance release — updated 23 October 2026

Current execution plan and evidence checkpoint. This supersedes the earlier
solo-only recommendation for the first owner acceptance build. Baseline:
`e00169c`, branch `codex/launch-readiness-20261021`; preservation commit
`348c690` remains intact. The saved checkout `D:\TrainingArena` is read-only.

## Locked scope and rules

- First acceptance: camera-counted solo and real friend battles, email-code
  **and** Google sign-in, invitation/code/inbox, practice/readiness, completed
  rounds, matching results/history, recovery and fresh rematches.
- Two physical Android phones will be supplied for guided validation. Emulator
  automation is functional evidence only; physical accuracy remains pending
  until observer counts and actual device sessions exist.
- All testers update to the new build. Keep strict numeric counter versions;
  unsupported legacy clients get an actionable update-required result. No
  backwards-compatibility migration merely to support the old wire value.
- Reuse/resume existing `fit_ap`; preserve Arena/Fault and unrelated data.
  No destructive hosted reset, applied-migration rewrite or new paid resource.
- Zero new spending. Transactional test/auth messages only; no outreach,
  customer campaign, live billing, public posting or app-store publication.
- Private owner diagnostics are unmistakably non-production. Keep production
  camera evidence, release flags, signing and public-copy holds intact.
- Fix usability defects that obstruct these journeys now. Optional design,
  animation, events and product expansion wait for owner acceptance.

## Execution order and acceptance

| Priority | Work | Acceptance evidence |
| --- | --- | --- |
| P0 foundation | Pin Flutter 3.47.5/JDK 17/one Android SDK, inspect local engine, resume selected backend and inventory schema/functions/migrations | Exact tool/runtime output; backup/recovery preparation before forward-only hosted changes; no copied admin secrets in app |
| P0 counter contracts | Stable visible exercise signal chain; crop non-signal head/feet permitted; missing signal pauses; shallow/bounce/sag/collapse rejected with explicit outcomes | Focused genuine regressions; no loosened depth/safety thresholds, no hidden failing case; contract differences logged |
| P0 backend contracts | Complete valid positive avatar fixtures; malformed/truncated/dimension/MIME/size negatives; supported current SQL test version; legacy update recovery | Native Edge tests and real PostgreSQL schema/authz/flow/rate/idempotency/maintenance/rematch checks; existing data preserved |
| P0 auth | Route exact OAuth callback away from challenge parsing; real shared-link broadcast regression; configure both hosted auth methods | Warm/cold/recreated return, original invitation retained, cancel/deny/transient retry; actual Google browser return and actual OTP delivery distinguished from mocks |
| P0 diagnostics | Numeric trace owned by session/match, surviving reconnect/result; export after round; correct runbook and deterministic squat path | Phase/lifecycle regression and resulting completed trace; no mid-round share requirement, frame recording or automatic upload |
| P1 core end-to-end | Install/profile/auth; solo save/restart; permissions/settings/reopen; two-account request/accept/ready/round/results; reconnect/termination/rematch | Emulator/manual walkthrough with actual backend plus guided physical checklist; honest failures and no fabricated success |
| P1 final checkpoint | One full relevant suite/analyzer and artifact validation after targeted work | Counts/exit codes/source commit; repeat only after new changes or newly identified risks; stop and reconsider after three failed fixes per unresolved check |
| P1 delivery | Fresh owner diagnostic APK, configuration/signer/hash/source record and install instructions | Accessible supported file/USB route; inspect installed signature/version/data before replacement; never silently uninstall owner data |

Counter semantics changes require an appropriate new version and registration;
diagnostic-only changes do not silently relabel behavior. Physical acceptance:
zero false positives; at least 90% of 20-rep rounds within ±2; aggregate error
at most 5%; understandable tracking pauses; lifecycle recovery; no crash/frame
leak. Record actual device/model/Android/build/hash/observer results. These are
acceptance requirements, not achieved results.

## Owner validation and delivery contract

The diagnostic runtime uses `tools/run-dev.ps1 -Mode Backend
-EnableCameraCounting -EnableCameraTrace -Device <serial>` with the public
backend URL/key and exact auth redirect. Fixtures, ranked and push remain off.
Two current builds/accounts exercise both authentication methods, then real
requests, readiness, full rounds, matching receipts, recovery and rematches.

Before installing: identify phone model/Android, installed package version and
signer, and any local history that must be retained. A debug certificate cannot
silently replace an incompatible signed install. A local PC file path is not
automatically a phone-accessible download link; prepare and verify the selected
transfer route. Historical September/October APK names are not current builds.

After owner device evidence passes, the same verified source may become a
signed candidate with traces/fixtures off and identity/native 16 KB/size/secrets/
App Links checks. Public Play approval/testing and factual public policies are
separate gates. Do not call diagnostic availability a public release.

## Live evidence

The interrupted 22 October changes were inspected and resumed on 23 October.
The counter contract correction is committed as `637b602`: a still-visible far
signal chain is valid; the missing-chain negative removes both ankles. Shallow,
bounce, sag and collapse outcomes remain explicit. No counter thresholds,
geometry or version changed (`1.3.0`). Complete valid PNG/JPEG/WebP fixtures
replace incomplete headers; security/dimension/size negatives remain intact.

Final local checkpoint: **Flutter 661 passed, 2 optional skips, 0 failures;
analyzer clean; native Deno 75 passed; both Edge entrypoints typecheck; Node
release/web/launcher 49 passed; secret scan and diff whitespace checks passed.**
An exploratory global link fallback caused 26 sharing-contract failures and was
reverted; the canonical HTTPS referral/card contract is preserved. The final
suite above passed after that correction. There are no retained counter-test
conflicts in this checkpoint.

Camera diagnostics now belong to the session. Completed traces survive result
and reconnect, and replay consumes the real round boundary and pause/resume
markers. A real adapter/controller phase matrix passes practice, ready,
countdown and live background/resume, resumed scored reps and a fresh rematch.
Finished-preview teardown waits before new practice and cannot change a
completed result on failure. These are synthetic lifecycle tests, not physical
accuracy evidence.

`fit_ap` is ACTIVE_HEALTHY. Before changes, its existing public rows/function
definitions/triggers/columns/grants, Fault table metadata and row counts were
captured under ignored `artifacts/hosted-backup/`. This is an affected-schema
snapshot, not a full point-in-time backup. Existing `public.profiles` (3 rows)
and `xp_events` were compared equal afterward; Fault subscriber/outbox counts
were unchanged. No reset, deletion, old migration edit or paid resource occurred.

Hosted forward-only history now includes:

| Hosted version/name | Source |
| --- | --- |
| 20261023045536 / arena_owner_acceptance_foundation | Exact six Arena schema/RPC/presence/rematch/hardening/version-handshake SQL files, source hashes recorded in the hosted migration comments |
| 20261023045600 / arena_owner_acceptance_maintenance | Existing minute maintenance migration |
| 20261023045745 / arena_function_search_path | New additive pinning of four Arena helper search paths |

The existing two hosted Fault history entries were preserved. Their timestamps
and the bundled Arena versions differ from local filenames: **do not blindly
run `db push` or rewrite applied history**. Inspect/reconcile this recorded
mapping before any future CLI deployment. Roll forward on defects; disable the
new Arena function/maintenance job as containment if necessary. Do not drop
shared schemas, clear user data or reset the project as rollback.

The `arena` Edge Function is ACTIVE version 2, deployment SHA256
`836f10690da51d6186b6f23803ae15676e0ae02a35dd90e7eec5af8637c2f2b3`.
Gateway JWT verification is off as designed for anonymous link GETs; every POST
verifies its bearer with Auth and SQL rechecks the active session. All 15 Arena
tables have RLS; clients cannot call the privileged version wrappers. Missing,
legacy and unsupported versions fail before readiness/countdown or restore/live
heartbeat. The app stops camera/timers/pending retry work and offers an update
path without inventing a receipt or no-result.

Docker Desktop crashed on its stale inference socket. No factory reset was
attempted. An isolated native PostgreSQL **18.3** cluster at loopback port 55432
ran **240 pgTAP assertions successfully**, using minimal Auth/Storage table seams
and official pgTAP 1.3.4 SQL. Native Windows lacks pg_cron, so scheduling was
verified separately on hosted PostgreSQL **17**: job active every minute and its
latest run succeeded. Hosted transaction checks exercised real signup triggers,
sessions, unsupported ready, supported two-player countdown, restore and
heartbeat; their synthetic fixtures were rolled back. Public HTTP checks:
unauthenticated profile POST -> 401; unknown link GET -> available=false.

The official product name is Fault. The owner selected Fault as the email display name with the temporary onboarding@resend.dev address; fault.fit DNS remains untouched. Both code templates have Fault subjects/body/footer. Email and Google providers and the exact approved callback are saved. The existing Google project consent name workflow is preserved. A fresh app-requested Fault email was delivered and its actual eight-digit code signed in and loaded the profile. The owner selected new; backend SQL and native Profile confirm @new. Final build2026102304 restored the named session after upgrade/new process. Google browser launch/cancel/retry passed, while consent/token exchange/warm-cold return still require owner interaction. Emulator DNS was repaired without wiping data. Detailed provider, delivery and app evidence is maintained in [OWNER_AUTH_SETUP_2026-10-23.md](OWNER_AUTH_SETUP_2026-10-23.md). No duplicate key/client or paid resource was created.

The API36 Android emulator accepted an in-place upgrade with the same debug
certificate. Cold launch, Battle/Solo navigation and deny-then-grant permission
were observed. A pre-existing System UI ANR was dismissed; this is not evidence
of an app ANR. The initial AVD had a missing expected camera and showed a
placeholder. Restarting with both virtual cameras restored the native camera
texture and its geometry, with the expected noPerson tracking state. The HUD
counts PoseFrame arrivals, so zero pose FPS with a test pattern is not evidence
of missing analyzer input. Preview and practice survived Home/foreground;
leaving to Battle and opening Solo camera again also restored the texture.
real-person landmarks/counting, completed camera sets, save/restart and real
friend rounds remain unverified. No physical-phone result is claimed.

The current Fault APK built cleanly from 7937c7f6476287bfaf628bac62d0c4323a37deb8, source_dirty=false, version 1.0.1-owner.20261023 / 2026102304, 201,348,471 bytes. APK SHA256: 857064ce902e13ac384bc0d7df753d43a8550898972fb2d9f9c7f3dd3dc39add. Signature/manifest/ABI/hash and repository/artifact secret scans passed. Same-certificate upgrades preserved the account, and the new process restored @new. The timing command timed out before the actual UI became usable; startup performance remains unproven. Two additional widget regressions cover the first-sign-in username submission context defect fixed in this build. See [OWNER_INSTALL_2026-10-23.md](OWNER_INSTALL_2026-10-23.md) for the source/hash/signer packet, actual evidence and physical acceptance checklist. Historical builds remain intact.

Private testing uses real in-app codes/inbox. Public HTTPS App Links/website
installation routes remain unverified; the placeholder domain is not a working
invite website. Physical counting, two-account friend end-to-end, real provider
return, release signing, public policies/Play and signed-candidate native 16 KB
checks remain pending. Diagnostic availability does not clear these gates.

Post-launch work is recorded separately in [POST_LAUNCH_PLAN.md](POST_LAUNCH_PLAN.md)
and is not implementation scope before functional acceptance.
