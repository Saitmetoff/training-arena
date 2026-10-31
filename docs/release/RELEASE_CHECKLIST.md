# Training Arena release checklist

Owner: task `11` (release pilot). Verdict and gates:
`docs/release/GO_NO_GO.md`. Configuration and owner actions:
`docs/release/CONFIGURATION.md`. Risk IDs R1–R8 are task `10`'s
(`qa/REPORT.md` §6); R9+ are task `11` release gates. Task record:
`qa/launch/l11/L11.md`.

**Beta checkpoint — 2026-09-30:** solo/links/sharing on; ranked/push/fixtures/
trace off; camera gated by reviewed two-phone evidence matching app sources.
Version **1.0.1+2**. Fresh local evidence: 626 Flutter passed, 2 skipped,
analyzer clean; Deno 59, pgTAP 212, HTTP smoke 31, Node release/web 37 passed;
repository secret scan exit 0. See `qa/beta/checkpoint-results.json` and the
current `PILOT_PLAN.md`. Hosted services, domain, signing, physical camera and
media review remain open. Build identity is generated from the committed
checkpoint; historical hashes below are not this candidate.

**Historical snapshot (2026-09-22)**: branch `codex/training-arena`, HEAD `1561673` (L08 docs) with
the L08 product freeze at `1de6127`, plus the uncommitted review-fix Batch A/B
patch set on top (`docs/release/REVIEW_2026-09-21.md`; Batch C open — see
§8.12). **No distribution candidate has been built from this tree**; the L02/L07/L08
artifact hashes are historical and must not be handed to testers (R8/R9).

**Fresh verification — 2026-09-22** (this tree, exact commands in
`qa/launch/l11/release_checks_2026-09-22.txt`): `flutter analyze` clean,
**492/492 Flutter tests**, repository and artifact secret scans clean,
`check_release_flags` and its 12 Node regressions pass, challenge-web 21/21,
prototype 10/10 check groups, App Link release gate fails without a host and
on `example.invalid` and passes on a real-format host, the Gradle release build
aborts on the placeholder, the bundle manifest/16 KB check passes, and source
plus debug-APK identity pass. Deno edge tests were last run on the L08 freeze
(48+10) and are not re-run here because no backend file changed and Deno is not
installed in this session.

Legend: ✅ verified · ⚠ verified with an open caveat · ⛔ blocked / not
configured. A ⛔ blocks distribution to invited testers until the owner
decision is recorded.

## 1. Release identity and disclosures

| # | Check | Method | Result | Evidence / owner |
| --- | --- | --- | --- | --- |
| 1.1 | Application label **Training Arena** | manifest, Dart title, APK badging | ✅ | `AndroidManifest.xml`, `arena_app.dart`, APK badging |
| 1.2 | Application ID `app.trainingarena.mobile` (applicationId, namespace, Kotlin package) | source + APK badging | ✅ | `build.gradle`, APK badging |
| 1.3 | `minSdk 24`, compiled/targeted SDK 36 | source + badging | ✅ | `build.gradle`; APK badging (`sdkVersion:'24'`, `targetSdkVersion:'36'`) — L02 migration |
| 1.4 | Version `1.0.1+2`, bumped per candidate | `pubspec.yaml` + identity tool | ✅ | bump `version:` for every pilot build; identity tool enforces `<name>+<code>` |
| 1.5 | Artifact identity + SHA-256 recorded | `check_artifact_identity.mjs --apk` | ✅ tooling | 2026-09-22 debug APK (QA only, debuggable): `6EA276E0…46C2366`, 222 290 406 bytes, `1.0.0+1`, minSdk 24, targetSdk 36, label "Training Arena". Release-equivalent smoke APK (non-debuggable, debug-signed, **not distributable**): `B4813C0B…75EFED`, 90 402 075 bytes. L02/L08 hashes are historical (superseded by the review-fix source changes) |
| 1.6 | Camera optional (installs on camera-less devices) | manifest + badging | ✅ | three `uses-feature ... required="false"` |
| 1.7 | Privacy text present in-app and on the landing page | source review | ✅ | Settings → Privacy (`settings_page.dart`), challenge entry (`challenge_entry_view.dart`), landing (`challenge-web/app.js`): frames stay on device; only rep counts reach the score |
| 1.8 | Camera disclosure | manifest comments + privacy copy | ✅ | `CAMERA` permission, on-device ML Kit, no storage/network permission for frames |
| 1.9 | Notification disclosure | manifest + setup doc | ✅ | `POST_NOTIFICATIONS` declared; in-context prompt only; denial leaves inbox authoritative |
| 1.10 | No legacy FitBattle identifiers | source scan | ✅ | `docs/PROJECT_STATUS.md` §8 |

## 2. Signing and keystore separation

| # | Check | Result | Evidence / owner |
| --- | --- | --- | --- |
| 2.1 | Release signing fails closed without a keystore | ✅ guard | `build.gradle` aborts `*Release` unless `android/key.properties` exists or `-PallowDebugSignedRelease=true` is explicit |
| 2.2 | Keystore and passwords outside the repository | ⛔ R9 | no `key.properties`/`.jks` present; exact owner action in `CONFIGURATION.md` §3 |
| 2.3 | CI uses its own secret store, never committed files | ✅ workflow | `.github/workflows/release-checks.yml` materializes the keystore from secrets in a protected environment |
| 2.4 | Signed QA artifact produced | ⛔ R9 | signing not configured; no credential invented. **Owner must create/vault the keystore first**; the pre-existing debug APK is not distributable |
| 2.5 | Release APK not debuggable, signer pinned | ✅ tooling | `check_artifact_identity.mjs --release --expect-signer-sha256`; `apksigner` in CI (local JDK not on PATH) |
| 2.6 | Debug signing never reaches testers | ✅ guard | release task with debug signing requires the explicit `-PallowDebugSignedRelease=true` smoke opt-in |

## 3. Challenge links and install recovery

| # | Check | Result | Evidence / owner |
| --- | --- | --- | --- |
| 3.1 | Custom scheme `trainingarena://challenge/**` declared | ✅ | manifest + APK `xmltree`; decisions `05` (D2 resolved) |
| 3.2 | HTTPS App Links filter `/c/`, `autoVerify=true` | ✅ present | manifest via `${arenaLinkHost}` |
| 3.3 | Real domain configured and verified | ⛔ R2 | still `example.invalid`; App Links cannot verify |
| 3.4 | `example.invalid` blocks release | ✅ verified | `check_app_links.mjs --release` fails with no host **and** on `example.invalid`, passes on a real-format host; **and** the Gradle release build now aborts on the placeholder before signing (`build.gradle` guard, verified 2026-09-22: `BUILD FAILED`, exit 1). Only the explicit non-distributable `allowDebugSignedRelease`/`allowUnsignedRelease` opt-ins bypass it |
| 3.5 | `assetlinks.json` template pinned to the package | ✅ | `challenge-web/.well-known/assetlinks.json.template`; release fingerprint owner-supplied |
| 3.6 | Play Install Referrer recovery | ⚠ R4 | `InstallReferrerBridge.kt`, `install_referrer.dart`; best effort, never exercised (needs Play test track) |
| 3.7 | Link states (revoked, expired, completed, blocked, busy, offline) | ✅ | task `10` matrix + `docs/decisions/05-...`; host and emulator rows pass |
| 3.8 | Landing page read-only and secret-free | ✅ | `node challenge-web/scripts/check.mjs`; text-only share URLs |
| 3.9 | Auth return preserves the pending challenge | ✅ | task `10` rows: cold/warm link, sign-in return, process restart |

## 4. Auth configuration

| # | Check | Result | Evidence / owner |
| --- | --- | --- | --- |
| 4.1 | Auth redirect allowlist matches the app | ⛔ R3 | `ARENA_AUTH_REDIRECT_URL` default empty → sign-in fails closed; suggested `trainingarena://challenge/auth`; owner config in `CONFIGURATION.md` §6 |
| 4.2 | Email OTP provider | ⚠ local pass / hosted ⛔ | `otp_length = 6`, template with `{{ .Token }}`; hosted SMTP unset (`supabase/config.toml`) |
| 4.3 | Google provider settings | ⛔ R3 | no Google section in `config.toml`; owner creates the OAuth client |
| 4.4 | Auth return to the pending challenge | ✅ code/tests | `AccountChallengeAuthDelegate`; task `10` emulator evidence |
| 4.5 | Tokens/emails never logged | ✅ code | gateway coded to keep tokens/emails out of logs/errors; no `print`/`debugPrint` in `app/lib` |
| 4.6 | Session stored in Keystore-backed secure storage | ✅ code / ⚠ device | **R10 closed on the code side by L03/L08**: sessions and the PKCE verifier use Android Keystore-backed storage with a verified-write migration, fail-closed writes and backup disabled (`app/lib/account/auth/auth_store.dart`; `docs/release/CONFIGURATION.md` §7). One physical-device Keystore pass remains in the L04 packet |

## 5. Backend separation and data boundaries

| # | Check | Result | Evidence / owner |
| --- | --- | --- | --- |
| 5.1 | Separate Supabase project, no shared credentials | ✅ local config | `supabase/config.toml` `project_id = "TrainingArena"` |
| 5.2 | RLS on every table, no policies; anon/authenticated grants revoked | ✅ | `supabase/migrations/20260917143538_...`; task `10` pgTAP/HTTP evidence |
| 5.3 | Service-role key server-only | ✅ code | `functions/arena/index.ts`, `arena-dispatcher/index.ts` read env at runtime only |
| 5.4 | FCM worker secret separation | ✅ | dispatcher requires its own `ARENA_DISPATCHER_SECRET` bearer; `FCM_SERVICE_ACCOUNT_JSON` server-only; no Firebase file in the app |
| 5.5 | Live FCM delivery | ⛔ R4 | worker `deliver()` path exists but no project/worker is configured; a no-push pilot must be explicitly accepted |
| 5.6 | Client push lane and denial path | ⚠ R4 | Dart layer + native host wired by L06 (`PushBridge`, `ArenaMessagingService`); inert without the owner's `google-services.json`; **no push in the pilot**, in-app inbox authoritative (poll every 4 s). Native disabled-build hardening is open (R17, §8.12) |
| 5.7 | Receipts/ratings immutable, idempotent matches | ✅ | migrations + `supabase/tests/`; task `10` 184/184 pgTAP + 16/16 e2e |
| 5.8 | Hosted backend deployed | ⛔ D3 | no project configured or deployed; deployment is owner-approved only |

## 6. Secret and leak scan

| # | Check | Command | Result |
| --- | --- | --- | --- |
| 6.1 | Repository scan (git-visible files) | `node tools/release/secret_scan.mjs` | ✅ clean on the 2026-09-22 tree (R5 scanner fix) |
| 6.2 | Build artifact scan | `node tools/release/secret_scan.mjs --artifacts` | ✅ clean on the 2026-09-22 debug and release-equivalent APKs (and the historical L02/L08 artifacts) |
| 6.3 | Ignored local files (audit) | `node tools/release/secret_scan.mjs --all --json` | ⚠ exit 1, only two gitignored local files: `supabase/.env.local` and `supabase/.temp/.../docker.env` (local service-role JWT, R12). Both are ignored by `supabase/.gitignore`; neither is committed |
| 6.4 | Debug Firebase files absent | scanner + filesystem | ✅ no `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` |
| 6.5 | No keystore/`.env`/service-account JSON committed | scanner rules | ✅ |
| 6.6 | Camera frames/landmarks out of logs, analytics, share exports | code review | ✅ no debug prints in `app/lib`; share exporter paints receipt surfaces only; camera frames stay in memory |
| 6.7 | Auth tokens out of analytics/share | code review | ✅ analytics carry event names + allow-listed low-risk properties; share message carries username + challenge URL only |

## 7. CI checks

`.github/workflows/release-checks.yml` (not executed in this workspace — the
jobs run on GitHub-hosted runners; local verification uses the pinned
`D:\toolchains` Flutter 3.47.5 toolchain from L02):

| Job | Steps | Blocks on |
| --- | --- | --- |
| `verify` | Flutter 3.47.5/JDK 17 → `pub get` → `flutter analyze` → `flutter test` → challenge-web check + tests → release-hold check (`check_release_flags.mjs`) + the bundletool/release-flag Node regressions → debug APK → release-equivalent APK + unsigned AAB → repo secret scan → App Link manifest check → source identity → artifact identity (debug + release-equivalent) → bundle manifest/16 KB/delivery check → artifact secret scan | any failure |
| `release-candidate` (manual, owner-approved, `needs: verify`) | requires release secrets; refuses `example.invalid`; materializes signing from CI; builds the signed AAB + APK with real dart-defines and `RANKED=false`/`PUSH=false`/`PREVIEW_FIXTURES=false`; runs `check_app_links.mjs --release --fetch-assetlinks`; pins the upload key on the AAB and APK; scans the artifacts; uploads both | missing secrets, placeholder host, unverifiable `assetlinks.json`, wrong signer, debuggable APK, any hold reversal |

## 8. Distribution gate

| # | Check | Result |
| --- | --- | --- |
| 8.1 | `qa/REPORT.md` (task `10`) present with scenario results | ✅ conditional pass; primary recipient path passed; blockers R1–R8 owned |
| 8.2 | Camera device validation complete and signed | ⛔ R1 (`qa/camera/device_validation_checklist.md` not started) |
| 8.3 | Media release gate passed (human review) | ⛔ R13 (`release_eligible: false`) |
| 8.4 | Result-sharing card/renderer landed (task `09`) | ✅ cards, QR, safe-area tests and spec in tree; task `10` sharing rows pass |
| 8.5 | In-app request path works without push | ✅ inbox polling every 4 s; `Challenge a friend` visible during ranked search; queue stops at 60 s |
| 8.6 | Support/recovery scripts ready | ✅ `PILOT_PLAN.md` §3–§4 |
| 8.7 | Stop conditions defined and owned | ✅ `PILOT_PLAN.md` §3, `CAMERA_QA.md` §4.3 |
| 8.8 | Rollback/incident notes ready | ✅ `ROLLBACK.md`, `INCIDENT_RESPONSE.md` |
| 8.9 | Signed release candidate built on a frozen commit | ⛔ R8 + R9 (exact owner action in `CONFIGURATION.md` §3/§8). The review-fix A/B patch set is uncommitted and changes Dart/Kotlin-free source, so **any distributable build must be rebuilt from a new commit**; the L02/L08 artifact hashes are historical |
| 8.10 | Owner accepts `GO_NO_GO.md`, pilot scope and distribution method | ⛔ owner decision (§5 of `GO_NO_GO.md`) |
| 8.11 | Review-fix Batch A/B landed and verified (auth durability/lifecycle, public-deletion safety, ranked hold, bundletool integrity) | ✅ in tree, 2026-09-22: analyzer clean, 492/492 Flutter tests, 12/12 release-tool regressions, 21/21 challenge-web tests, fresh identity + secret scans. Evidence: `qa/launch/l11/release_checks_2026-09-22.txt` |
| 8.12 | Review-fix Batch C (native push capability + account ownership; disabled-build delivery) | ⛔ **R17** — not implemented; owner/decision in `GO_NO_GO.md` §4. The no-push pilot is unaffected (no `google-services.json`), but push must not be enabled before this closes |

## 9. Owner decision summary

Required before any distribution to invited testers:

1. Freeze and commit the tree, including the review-fix Batch A/B patch set
   (R8), then rebuild — never distribute the L08 artifacts.
2. D1 real HTTPS challenge domain (R2) with `assetlinks.json` + release cert.
3. D3 hosted Supabase project, anon key, Google/email providers, redirect
   allowlist, SMTP (R3).
4. Release keystore + vault + CI secrets, or an explicit decision to remain
   unsigned/internal (R9).
5. Camera device validation verdict (R1) or an explicitly scoped non-camera
   pilot.
6. Media human review (R13).
7. Review closeout: accept Batch C (R17) as a pre-push gate or schedule it
   before push enablement.
8. Explicit accept/reject of `docs/release/GO_NO_GO.md` for the pilot.
