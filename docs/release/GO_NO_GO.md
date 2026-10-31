# Training Arena go / no-go recommendation

Owner decision required. Refreshed by task `11` on 2026-09-18 after task `10`
delivered `qa/REPORT.md` (tree at commit `bfaa6bd`, branch
`codex/training-arena`; task work is still uncommitted — see R8).

> **L01 reconciliation — 2026-09-20 (OpenCode).** The working tree was frozen
> into a scoped integration baseline commit; the exact hash, scope and fresh
> checks are in `qa/launch/L01.md`. **R8 is closed.** The verdict is still
> **NO-GO** for distribution: R1–R4, R6, R7, R9, R10, R13 and the owner
> decisions below remain open. **R11 is split in §4**: the ranked flag is
> unused (a confirmed gap for L03), while result sharing is already enforced by
> the composition-root factory in `app/lib/arena_app.dart:136` and every
> challenge-share entry path routes through the single `BattleController`
> sharer (entry-path audit in `qa/launch/L01.md`). The task-`11` sentences
> below are kept as the dated 2026-09-18 snapshot.

> **L02 reconciliation — 2026-09-20 (OpenCode).** The Android artifact now
> meets the current Play target requirement on a pinned, reproducible
> toolchain: Flutter 3.47.5 / Dart 3.13.4, Gradle 9.3.1, AGP 9.1.0, Kotlin
> 2.4.0, compileSdk/targetSdk **36**, minSdk 24, installed in an independent
> SDK outside `D:\Kiro` (`D:\toolchains`). A release AAB path exists locally
> and in CI, with manifest/native checks (`tools/release/check_android_bundle.mjs`):
> 18 native libraries for arm64-v8a/armeabi-v7a/x86_64, all 64-bit libs 16 KB
> ELF-aligned, `zipalign -P 16` clean, `extractNativeLibs=false`, and a
> Play-delivery estimate of **20 471 415 bytes (~19.5 MB)** for an arm64 API 36
> device (the old 307 MB debug APK is not a download size). The release build
> was smoke-tested on API 36 (edge-to-edge enforced, frame full-display,
> zero crashes) and on an API 35 **16 KB page-size** emulator (app launches and
> stays resumed). Two latent release-only defects were found and fixed: the
> R8 rules now keep Room's reflectively instantiated database constructors and
> ML Kit's reflectively instantiated component registrars (release builds
> previously crashed at startup). **R9 is still open — signing remains the only
> artifact blocker**: the AAB is unsigned and the APK is debug-signed, both
> non-distributable. Details and exact commands: `qa/launch/L02.md`.
> New follow-up **R14** (built-in Kotlin migration) is recorded in §4.

> **L03 reconciliation — 2026-09-20 (OpenCode).** Ranked scope is now real:
> `ARENA_FEATURE_RANKED_MATCHMAKING` is passed through the composition root
> into `BattleController`, which refuses every queue join when off, and the
> Battle tab replaces the ranked action with honest copy when ranked **or**
> camera counting is off (no questionnaire, no camera-counted claim). **R11a is
> closed.** Existing camera/preview/push/challenge gates were audited and the
> result-sharing fallback is preserved unchanged. Sessions and the PKCE
> verifier moved to **Android Keystore-backed storage**
> (`flutter_secure_storage`) with a one-time migration that removes the
> plaintext copy only after the secure write succeeds, fails closed on storage
> write failure and clears both copies on logout/deletion; cloud backup is off
> (`android:allowBackup="false"`). **R10 is closed on the code side**, pending
> one physical-device verification pass (L04). Build-time flags are explicitly
> **not** remote kill switches; no operational server switch exists today, so
> the smallest scoped backend control is proposed in
> `docs/decisions/07-matchmaking-incident-control-proposal.md` (**new R15**).
> Details and exact commands: `qa/launch/L03.md`.

> **L04 reconciliation — 2026-09-20 (OpenCode).** The physical-device and media
> validation packets are prepared (`qa/launch/l04/DEVICE_VALIDATION_PACKET.md`,
> `qa/launch/l04/MEDIA_REVIEW_PACKET.md`) but **not executed**: no physical
> device is attached (`adb devices -l` empty), and no tester, observer or
> qualified form reviewer is recruited. **R1/R7 and R13 stay open** and the
> camera checklist stays unsigned; the media release gate still fails by design
> (25 unreviewed assets). A release-path defect was fixed: the preparation
> demonstration now refuses to render media whose manifest `review_status` is
> not `approved` and shows the documented placeholder instead (3 regression
> tests; 435/435 Flutter tests, analyzer clean). No camera code or threshold
> changed — no physical defect was reproduced. A camera-enabled,
> release-equivalent validation APK was built and checked (SHA-256
> `53d6bafb…c8951`; identity and artifact secret scan clean; debug-signed,
> non-distributable). The L03 physical Keystore check remains pending in the
> same sessions. Full record: `qa/launch/l04/L04.md`.

> **L05 reconciliation — 2026-09-20 (OpenCode).** The hosted deployment
> runbook is complete (`qa/launch/l05/DEPLOYMENT_PACKET.md`) and the deploy
> path is locally verified: fresh `db reset` + pgTAP 184/184, arena/dispatcher
> Deno 48+10, challenge-web checks, App Links release gate (placeholder fails,
> real host passes) and an extended e2e smoke **24/24** covering the dispatcher
> worker boundary and the shared-outage `no_result` path. **No hosted step
> ran**: D1 (domain), D3 (project), hosting, SMTP and secret custody are still
> missing, so **R2/R3 stay open** and no hosted/auth/link evidence exists yet.
> A second writer session modified app files in the same tree during L05; that
> work is preserved uncommitted and is not part of the L05 commit. Full record:
> `qa/launch/l05/L05.md`.

> **L06 reconciliation — 2026-09-21 (OpenCode).** The missing native Android
> FCM host is implemented (`PushBridge` + `ArenaMessagingService`) for the
> exact task-08 channels and payloads, with the Google Services plugin and
> `firebase-messaging:25.1.3` pinned and the plugin applied **only** when the
> owner's `google-services.json` exists. Without it the bridge degrades to
> no-push: `permissionStatus = notDetermined`, no token, empty streams, no
> notification channels; the release-equivalent APK/AAB, the API 36 and 16 KB
> emulator smokes, the secret scans and the bundle check all pass (459 Flutter
> tests, Deno 48+10). Google/email redirect continuity through the real PKCE
> gateway after process death is host-tested, including a username-required
> account. **Live push and the Google return remain BLOCKED** on owner inputs
> (Firebase app + JSON, hosted project + Google client id/secret + Play
> app-signing SHA-1), and the **ranked two-phone matrix is BLOCKED** — no
> physical device is attached, so ranked stays
> `ARENA_FEATURE_RANKED_MATCHMAKING=false` with the L03 refusal path. **R3/R4
> and R6 stay open**; R9 remains the only artifact blocker. Full record:
> `qa/launch/L06.md`.

> **L07 reconciliation — 2026-09-21 (OpenCode).** The public privacy, support
> and external deletion surfaces exist: `challenge-web/privacy.html`,
> `support.html` and `delete-account.html` fill owner values from
> `config.js`, show a draft banner while any value is missing, and
> `check.mjs --release` refuses to pass until the owner inputs and endpoints
> are real. The external deletion route verifies account ownership with the
> documented email one-time code (`create_user:false`) and reuses the
> existing `delete_account` backend; it is proven end to end against the
> local stack with the shipped client (`qa/launch/l07/deletion_route_e2e.txt`)
> and never logs or persists a token. Settings now links the privacy policy,
> support and the web deletion resource and fails closed on the placeholder
> host. The traceable inventory (`docs/privacy/DATA_INVENTORY.md`), the store
> packet with the live policy check, Data Safety/Health declarations,
> reviewer-access plan and generated store graphics
> (`docs/release/PLAY_STORE_PACKET.md`) are complete, and six real 1080×1920
> screenshots were captured from the release-equivalent smoke APK. **New
> R16** (below): the pages are not hosted and the owner identity, contacts
> and retention periods are missing, so no public endpoint exists and no
> Play declaration can be submitted; the camera-off artifact also cannot
> finish a counted round, so only the closed-test listing variant is valid
> today. Full record: `qa/launch/L07.md`.

> **L08 reconciliation — 2026-09-21 (OpenCode).** The outstanding third-writer
> patch set was frozen in commit `1de6127` and the full acceptance was re-run
> on it: analyzer clean, **459/459 Flutter tests**, the real-Keystore
> integration test **2/2** on the API 36 emulator, pgTAP **184/184**, Deno
> **48+10**, HTTP e2e **24/24**, challenge-web **16/16** (the `--release` gate
> still fails by design on the pending owner values), prototype **48/48**,
> repository and artifact secret scans clean, fail-closed signing guard
> verified. The release-equivalent APK (91 417 891 B, SHA-256
> `E3574480…074CC9`, debug-signed, non-distributable — byte-identical to the
> L07 smoke APK) and the unsigned AAB (89 902 797 B,
> `9E77C0D4…C470A`) were built from the freeze; the bundle check passes
> (targetSdk 36, 16 KB alignment, 18 native libs, 20 723 380 B arm64 delivery)
> and emulator smokes pass on API 36 and on the 16 KB API 35 runtime. **The
> battle-capable pilot gate is BLOCKED**: physical matrix/physical camera and
> media review (R1/R7/R13), signing (R9) and the real hosted config/public
> pages (R2/R3/R16) are still missing. Artifact stages stop at
> *built + locally verified*; nothing was signed with an upload key, uploaded,
> submitted, approved or published. Stage table, timings, per-scenario
> coverage and the exact owner actions: `qa/launch/L08.md`.

> **L10 reconciliation — 2026-09-21 (OpenCode).** The closed-test and Play
> launch packet is prepared (`qa/launch/l10/PLAY_TEST_AND_LAUNCH_PACKET.md`)
> and the candidate is verified unchanged since the L08 freeze
> (`git diff 1de6127..HEAD` over the product paths is empty; fresh source
> identity and secret scans exit 0). **No stage moved:** no signed AAB exists
> (R9), so no track received an upload; nothing was submitted, approved or
> published; no roster was recruited and 0 days of the 14-day closed-test
> eligibility have elapsed. The packet keeps internal and closed testing
> distinct (internal never satisfies the production-access rule), defines the
> qualifying opt-in clock, and lists the exact missing authorizations
> (signing custody, Console execution, hosted config/public pages, camera/media
> decision, roster, countries and publishing approval). Planning windows still
> start at the first completed owner input; Google review durations remain
> un-promised. Full record: `qa/launch/L10.md`.

> **Task 11 final reconciliation — 2026-09-22 (OpenCode).** The release
> checklist, configuration, pilot plan, rollback and incident notes were
> re-verified against the current tree. Fresh results (exact transcript:
> `qa/launch/l11/release_checks_2026-09-22.txt`): `flutter analyze` clean,
> **492/492 Flutter tests**, repository and artifact secret scans clean,
> `check_release_flags.mjs` plus 12/12 release-tool regressions, challenge-web
> 21/21, prototype 10/10, App Link release gate fails without a host and on
> `example.invalid` and passes on a real-format host, source and debug-APK
> identity pass (`6EA276E0…46C2366`, 222 290 406 B, `1.0.0+1`, minSdk 24,
> targetSdk 36, label "Training Arena", debuggable/QA-only). The review-fix
> Batch A/B patch set (auth durability/lifecycle, public-deletion safety,
> ranked release hold, bundletool integrity) is in the working tree but
> **uncommitted**; Batch C (native push capability/account ownership) is open
> (**new R17**). **The verdict is unchanged: NO-GO** for handing a signed
> artifact to invited testers — signing, the real domain/project and the
> public pages do not exist, camera accuracy and the media gate are unvalidated,
> and the current tree has no committed distribution candidate. The debug APK
> above is QA evidence only and must not be distributed. Task `11` did not
> publish, deploy, send notifications or rotate credentials. Full record:
> `qa/launch/l11/L11.md`.

Risk IDs R1–R8 come from `qa/REPORT.md` §6 (task `10`); R9+ are release gates
added by task `11`. Before any distribution, re-run the release checks on the
frozen, committed commit:

```powershell
node tools/release/secret_scan.mjs --artifacts
node tools/release/check_app_links.mjs --release --host <host> `
  --fingerprint <sha256> --fetch-assetlinks
node tools/release/check_artifact_identity.mjs --release --apk <apk> `
  --expect-signer-sha256 <sha256>
```

## Recommendation: **NO-GO** for handing a signed artifact to invited testers

The core loop is demonstrably working (task `10` primary recipient path passed
on an emulator against the real local backend), but the release cannot be
distributed today: signing does not exist, the real domain/project are not
chosen, camera accuracy is unvalidated and the pilot entry gates are not met.
Waiving any gate below is an explicit owner decision that must be recorded in
this file (name, date, scope, expiry).

## 1. What task `10` delivered (`qa/REPORT.md`)

- **Conditional pass** for invitation-to-battle integration on an Android
  emulator + local Supabase stack: recipient cold link → sign-in → request →
  accept → both-ready gate → 60 s round → receipt → history/leaderboard.
- Five integration defects found and fixed with regression tests:
  account compile break, durable link claim, battle viewer identity, ranked
  search clock and the local email OTP template.
- Automated baseline: `flutter analyze` clean, **416/416 Flutter tests**,
  48/48 Deno tests, 184/184 pgTAP assertions, 16/16 e2e smoke checks.
- Receipts, RLS/adversarial/idempotency, permission-denial, no-result,
  matchmaking-timeout and sharing rows executed; ranked device pairing, FCM
  delivery, Play referrer and physical camera accuracy are **not** executed.
- No production readiness, camera-accuracy or ranked-live claim is made.
- Incident disclosed: one accidental detached command briefly served
  `D:\Kiro` functions (killed immediately; see `qa/REPORT.md` §9). Task `11`
  did not modify `D:\Kiro`. (Historical note: at that time the Flutter SDK for
  this checkout lived under `D:\Kiro`; since L02 the pinned toolchain is
  `D:\toolchains\flutter-3.47.5`, and the 2026-09-22 pass used it, with the
  JDK 17 under `D:\Kiro\.tooling` only read.)

## 2. Why no-go

1. **Release signing is not configured (R9).** No `key.properties`, no
   keystore, no CI secrets. No signed QA artifact exists and none was
   invented. `app/android/app/build.gradle` fails closed for `*Release`
   tasks; the only artifacts built here are the debuggable QA APK and the
   debug-signed release-equivalent smoke APK, both non-distributable (§3.1).
   Exact owner action: `docs/release/CONFIGURATION.md` §3.
2. **R2 — real HTTPS domain (D1) missing.** The manifest, Gradle, Dart and
   `challenge-web` defaults are still `example.invalid`; App Links cannot
   verify. `check_app_links.mjs --release` intentionally fails without a real
   host and on the placeholder, and since 2026-09-22 the Gradle release build
   itself aborts on the placeholder (re-verified; §3.1).
3. **R1 — physical camera accuracy unvalidated.** The release must ship with
   `ARENA_FEATURE_CAMERA_COUNTING=false`; because there is no manual score
   path, competitive camera-counted battles cannot run in the pilot until
   `qa/camera/device_validation_checklist.md` is complete and signed.
4. **R3 — Google provider/redirect unexecuted.** No Google OAuth client and
   no hosted `ARENA_AUTH_REDIRECT_URL` allowlist; the Google sign-in return
   path has never run. Email OTP works locally only.
5. **R4 — FCM and Play Install Referrer unavailable locally.** Notification
   and not-installed/install-recovery matrix rows are blocked. The pilot must
   be **no-push** (`ARENA_FEATURE_PUSH_NOTIFICATIONS=false`); the in-app
   inbox is authoritative (verified in code and by task `10` test rows).
6. **R6/R7 — ranked device pairing and device matrix unexecuted.** Ranked
   receipts/ratings rest on host tests only; the only device exercised is one
   API 34 emulator (API 24–26, low-end and Tensor checkpoints untested).
7. **R13 — media release gate fails by design.**
   `qa/media/validation_report_release.json` still reports
   `release_eligible: false` (25 unreviewed assets). Human review is
   outstanding.
8. **R8 — the shared checkout is uncommitted.** **Closed 2026-09-20 by L01**
   (baseline commit, `qa/launch/L01.md`) but **partially reopened 2026-09-22**:
   the review-fix Batch A/B patch set is uncommitted on top of `1561673`. No
   pilot artifact has been built from a committed review-fix tree yet; see the
   final reconciliation above and §3.1.

**Fixed in this pass (was R5).** `tools/release/secret_scan.mjs` no longer
flags synthetic PEM-shaped test fixtures: the `private-key-block` rule now
requires a complete PEM block (header, base64 body, matching footer), which
still catches real key material but not a bare template header; the
`fcm_test.ts` synthetic value is explicitly `test`-prefixed. Repository and
artifact scans are clean (see §3).

## 3. Verified ready now (task `11` checks)

### 3.0 Historical table, 2026-09-18

| Area | Result | Evidence |
| --- | --- | --- |
| Label / app ID | `Training Arena` / `app.trainingarena.mobile` on source and the built debug APK | `check_artifact_identity.mjs --apk` |
| minSdk/targetSdk | 24 / 34 | APK badging + `build.gradle` |
| Version | `1.0.0+1`, identity tool enforces the shape | `pubspec.yaml` |
| Camera/notification disclosure | `CAMERA` + `POST_NOTIFICATIONS` permissions; camera features `required="false"`; privacy copy in Settings | manifest badging, `settings_page.dart` |
| Custom scheme | `trainingarena://challenge` present in manifest and APK | `aapt dump xmltree` |
| App Link release guard | `--release` fails without host and on `example.invalid`; passes on a real-format host | `check_app_links.mjs` |
| Secret scan | repository clean; artifact scan clean; only gitignored local `supabase/.temp` service JWT on `--all` | `secret_scan.mjs` |
| FCM/dispatcher boundary | dispatcher needs its own bearer secret; service account server-only; client transport degrades to "no push" | `arena-dispatcher/index.ts`, `fcm.ts`, `platform_push_transport.dart` |
| RLS/service-role | RLS on every `arena_*` table, no client grants | `supabase/migrations/20260917143538_arena_initial.sql` |
| CI | analyzer, tests, secret scan, App Link manifest and artifact identity on push/PR; gated manual signed release job | `.github/workflows/release-checks.yml` |
| No committed credentials | no keystore, `key.properties`, `google-services.json` or `firebase_options.dart` | scanner + filesystem check |
| Debug artifact | `163dfb340be8ff2c8d0035563791bc7f661d2a982b02b6e236e02b7dc1369958`, 307 759 487 bytes, debuggable (not distributable) | `check_artifact_identity.mjs --apk` |

### 3.1 Fresh verification, 2026-09-22 (current tree)

| Check | Result | Evidence |
| --- | --- | --- |
| Analyzer | clean | `flutter analyze` (Flutter 3.47.5) |
| Flutter suite | **492/492 passed** | `flutter test` |
| Release-tool regressions | 12/12 passed (`check_release_flags`, `check_android_bundle`) | `node --test tools/release/test/…` |
| Challenge-web | check passed; 21/21 tests; `--release` fails by design on missing owner values | `node challenge-web/scripts/check.mjs [--release]`, `node --test …` |
| Prototype | 10/10 check groups | `node prototype/scripts/check.mjs` |
| Repository secret scan | clean | `secret_scan.mjs` |
| Artifact secret scan | clean (debug APK; historical AAB/APK) | `secret_scan.mjs --artifacts` |
| Ignored-file audit | only gitignored `supabase/.env.local` + local `docker.env` service JWT | `secret_scan.mjs --all --json` |
| App Link release gate | fails without host and on `example.invalid`; passes on a real-format host; `assetlinks.json` still owner-supplied | `check_app_links.mjs --release` |
| Gradle placeholder-host guard | a distributable release build aborts on `example.invalid` (`BUILD FAILED`, exit 1); the two non-distributable opt-ins still build | `flutter build apk --release` (2026-09-22) |
| Release-hold gate | ranked/push/preview pinned off; explicit camera choice preserved | `check_release_flags.mjs` |
| Source identity | passed (label, package, minSdk 24, targetSdk 36, version, signing guard) | `check_artifact_identity.mjs` |
| Debug APK identity | `6EA276E0…46C2366`, 222 290 406 B, `app.trainingarena.mobile 1.0.0+1`, minSdk 24, targetSdk 36, label "Training Arena", debuggable — **QA only** | `check_artifact_identity.mjs --apk` |
| Release-equivalent APK (smoke) | `B4813C0B…75EFED`, 90 402 075 B, non-debuggable, debug-signed — **not distributable**; supersedes the L08 hash for this tree | `check_artifact_identity.mjs --release --apk` |
| Backend | not re-run (no backend change since the L08 freeze); L08 evidence 184/184 pgTAP, 48+10 Deno, 24/24 e2e | `qa/launch/L08.md` |

## 4. Risk register (every item has an owner and a release decision)

| # | Risk | Owner | Release decision required |
| --- | --- | --- | --- |
| R1 | Physical camera accuracy unvalidated | device QA owner / task `11` | keep camera counting **off** or complete and sign `qa/camera/device_validation_checklist.md` |
| R2 | D1 real HTTPS domain missing; App Links unverified | product owner | supply domain, `assetlinks.json` and the **Play app-signing** certificate SHA-256 (upload-key SHA-256 is not the installed-app identity); then verify on device |
| R3 | Google provider and auth redirect allowlist unset | account owner / product owner | configure OAuth client + `ARENA_AUTH_REDIRECT_URL` and run redirect QA, or scope pilot to email OTP only; the Android OAuth client must use the package name plus the **Play app-signing** certificate SHA-1 for Play-distributed builds (`docs/release/CONFIGURATION.md` §3/§6). **L06:** redirect/continuity logic is implemented and host-tested (`app/test/account/oauth_return_continuity_test.dart`); the hosted redirect itself is still unexecuted |
| R4 | FCM delivery and Play install recovery unexecuted | notifications owner / task `11` | accept a no-push pilot with inbox authority; live FCM needs owner authorization and Firebase setup. **L06:** the native host exists and the fail-closed no-push path is verified on both emulators; permission ask-once/denied, live taps and token rotation still need `google-services.json` + a physical device |
| R5 | Secret scan false positives on synthetic fixtures | task `11` | **closed** — scanner now detects complete PEM blocks only; scans clean |
| R6 | Ranked device pairing unexecuted | task `11` pilot | run a two-device coordinated ranked match before any ranked claim. **L06:** still BLOCKED (no physical device attached); ranked stays off and the narrower scope is documented in `qa/launch/L06.md` |
| R7 | Device matrix is emulator-only | device QA owner | L02 added API 36 and API 35 (16 KB page-size) emulator runs; run the API 24+/low-end/Tensor **physical** matrix before camera enablement |
| R8 | Shared checkout uncommitted | release owner | **closed 2026-09-20 by L01**, but **partially reopened 2026-09-22**: the review-fix Batch A/B patch set is uncommitted on top of `1561673` (`git status`). Commit it, then build the candidate from that commit; the L08 artifact hashes are historical (`docs/release/REVIEW_2026-09-21.md`) |
| R9 | Release signing/keystore/CI secrets missing | release owner | create and vault the keystore, set CI secrets (or explicitly stay unsigned/internal and non-distributable) |
| R10 | Auth tokens live in app-private SharedPreferences | account owner | **closed on the code side 2026-09-20 by L03** — sessions/PKCE now use Android Keystore-backed storage with safe migration, fail-closed writes, logout/delete clearing and backup disabled (`qa/launch/L03.md`); one physical-device Keystore verification remains in L04 |
| R11a | `ARENA_FEATURE_RANKED_MATCHMAKING` was read into `ArenaConfig` but had **no runtime consumer** | battle owner / L03 | **closed 2026-09-20 by L03** — the flag reaches `BattleController`, `startRankedSearch` refuses to queue when off, and the Battle tab shows honest unavailable copy when ranked or camera counting is off (`qa/launch/L03.md`) |
| R11b | `ARENA_FEATURE_RESULT_SHARING` **is** enforced at the composition-root factory `app/lib/arena_app.dart:136`; when off, `BattleRuntime` falls back to task-05 plain text share | battle owner / L03 | preserve the existing guard; no claim that sharing is ungated. Re-audit only if new entry paths bypass the single `BattleController` sharer (`qa/launch/L01.md`) |
| R12 | Local `supabase/.temp` service-role JWT on disk (gitignored) | backend owner | never commit/copy to hosted; rotate or delete if the machine is shared |
| R13 | Media `release_eligible: false` (25 assets unreviewed) | media owner | complete human review or exclude the unreviewed media from the release build |
| R14 | Flutter 3.47 warns that the app and some plugins apply the Kotlin Gradle Plugin; a future Flutter will fail to build them (built-in Kotlin migration). `android.newDsl=false` / `android.builtInKotlin=false` are the current compatibility flags | Android owner / L03 | migrate to built-in Kotlin when `shared_preferences_android` (and the pinned Flutter template flags) support it; keep the R8 keeps in `app/android/app/proguard-rules.pro` and re-run the API 36/16 KB smokes |
| R15 | No operational server-side control to refuse new ranked matches during an incident; compile-time flags cannot stop installed builds | backend owner / release owner | decide whether to apply the additive `arena_controls` migration proposed in `docs/decisions/07-matchmaking-incident-control-proposal.md` before the pilot, or accept its absence explicitly |
| R16 | Public privacy/support/deletion pages are written and locally verified but **not hosted** (no D1/hosting target), and the owner identity, contact emails and retention periods are missing; without them no public URL can be entered in Play Console and no Data deletion/Data safety answer can be submitted | product owner / release owner | supply the L07 §9 inputs and the L05 hosting target, fill `challenge-web/config.js`, run `node challenge-web/scripts/check.mjs --release`, deploy and verify the three URLs, then complete the Console forms (`docs/release/PLAY_STORE_PACKET.md` §10) |
| R17 | **Review Batch C open**: native delivery ignores `ARENA_FEATURE_PUSH_NOTIFICATIONS=false` (SDK background payloads can display from a retained Firebase config), `PushBridge.requestPermission` lacks the availability guard, and token registration is deduplicated by token alone with no account unregister/rebind | notifications owner / release owner | keep push disabled in the pilot and close Batch C (`prompts/REVIEW_FIXES_C_2026-09-21.md`) before any push enablement; a retained-config push-enabled→disabled upgrade must not deliver |

## 5. Owner decision required for any deployment

One explicit decision record containing:

1. Whether this no-go is accepted as written or which gates are waived (with
   scope and expiry).
2. D1 and D3 values (domain, hosted project, anon key, auth redirect,
   providers).
3. Signing custody (keystore owner, vault, CI secret names) and the frozen
   commit for the pilot build.
4. Pilot scope: distribution method (direct signed APK vs Play internal
   testing), roster/windows and whether camera counting is enabled. Direct
   APK cannot exercise Play Install Referrer; Play internal testing requires
   an owner-approved Play action that task `11` does not perform.
5. Confirmation that **no** Play publication, backend deployment, real
   notification or credential rotation happens without a separate explicit
   approval.
6. Whether R17 (review Batch C) is accepted as a pre-push gate or closed
   before any push enablement; and confirmation that the pilot stays no-push.

## 6. Conditions to flip to GO (in order)

1. Freeze + commit the tree including the review-fix Batch A/B patch set (R8),
   re-run all `tools/release/*` checks on that commit.
2. Resolve R1 (signed camera checklist) **or** explicitly scope a non-camera,
   no-push pilot and accept that competitive rounds cannot complete.
3. Configure D1 (R2) and verify `pm get-app-links` → `verified` on a device;
   configure D3 + auth providers/redirect (R3) and run the Google return QA.
4. Complete media review (R13).
5. Create the keystore + CI secrets (R9), build the signed release candidate
   (AAB + release-equivalent APK) **from the committed review-fix tree**, pin
   the AAB/APK upload-key signer
   (`check_artifact_identity.mjs --release --expect-signer-sha256`,
   `check_android_bundle.mjs --expect-uploader-sha256`), run the App Links
   gate with the **Play app-signing** SHA-256, scan the artifacts; record
   version/SHA-256.
6. Owner accepts `PILOT_PLAN.md` §2 entry gates, §5 distribution method, §7
   stop conditions and the support/recovery script.
7. Owner appointments for the pilot roles in `INCIDENT_RESPONSE.md` §3.
8. Accept R17 (Batch C) as a pre-push gate or close it before push is enabled
   in any later pilot; the pilot itself stays no-push.

## 7. Boundaries honored by task `11`

No Play publication, no backend deployment, no real notification, no
credential rotation, no keystore creation and no secret committed. Task `11`
used the Flutter 3.47.5 toolchain at `D:\toolchains` (L02) and Java 17 from
`D:\Kiro\.tooling\jdk17` **read-only**; no file under `D:\Kiro` was modified.
The only artifacts built in this pass are the debuggable QA APK and the
debug-signed release-equivalent smoke APK (§3.1); neither is a distribution
artifact.
