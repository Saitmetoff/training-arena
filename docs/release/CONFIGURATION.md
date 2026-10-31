# Training Arena release configuration

Owner: task `11` (release pilot). Status: **owner inputs missing (R2, R3, R9)**
— refreshed after `qa/REPORT.md` (task `10`, conditional pass) and the L02
Android toolchain migration (2026-09-20, `qa/launch/L02.md`). This file
describes every release value, where it comes from and the exact owner action.
No credential in this document is real, and no secret is stored in the
repository. `tools/release/secret_scan.mjs` is clean on the repository and on
the built artifacts (R5 closed on 2026-09-18).

Related: `docs/release/RELEASE_CHECKLIST.md`, `docs/release/GO_NO_GO.md`,
`docs/API.md` §8, `docs/CONTRACT.md` §5, `docs/decisions/0001-...` (D1, D3),
`challenge-web/README.md`.

## 1. Client build values (public, safe to compile into the app)

Passed as `--dart-define`; read only through
`app/lib/config/arena_config.dart`. Never put a service-role key, dispatcher
secret or FCM service account here.

| Key | Release value | Owner | Notes |
| --- | --- | --- | --- |
| `ARENA_LINK_HOST` | owner's real HTTPS host (D1) | product owner | must equal the Gradle `arenaLinkHost` and `challenge-web/config.js` `linkHost`; `example.invalid` is a hard release failure |
| `ARENA_PUBLIC_URL` | `https://<ARENA_LINK_HOST>` | product owner | shared-content public site URL |
| `ARENA_PLAY_STORE_URL` | `https://play.google.com/store/apps/details?id=app.trainingarena.mobile` | fixed | install/update route and referrer carrier |
| `ARENA_SUPABASE_URL` | hosted project URL (D3) | product owner + backend owner | never the previous application's project |
| `ARENA_SUPABASE_ANON_KEY` | hosted project anon/publishable key | product owner + backend owner | public client key only |
| `ARENA_AUTH_REDIRECT_URL` | `trainingarena://challenge/auth` (suggested) | account owner | must exactly match a Supabase Auth **additional redirect URL** and the scheme/host declared in the manifest (`trainingarena` / `challenge`); sign-in otherwise fails closed |
| `ARENA_FEATURE_CAMERA_COUNTING` | `false` until camera device QA passes (`docs/camera/CAMERA_QA.md` §4.3) | device QA owner | enabling without the signed checklist is a stop condition |
| `ARENA_FEATURE_CHALLENGE_LINKS` | `true` for the pilot | link owner | gates the challenge entry route |
| `ARENA_FEATURE_RANKED_MATCHMAKING` | `false` until ranked is in scope; `true` only when camera counting is also on | matchmaking owner | **enforced in L03**: when false (or camera counting is false) `BattleController.startRankedSearch` refuses to queue and the Battle tab shows an honest unavailable banner instead of the ranked action. It is a ship-time scope control, not a remote kill switch — see `docs/decisions/07-matchmaking-incident-control-proposal.md` |
| `ARENA_FEATURE_RESULT_SHARING` | `true` for the pilot | sharing owner | enforced at the composition-root factory `app/lib/arena_app.dart:136`; when off, the task-05 plain-text share is preserved (no card/QR), so it is a scope control, not a kill switch |
| `ARENA_FEATURE_PUSH_NOTIFICATIONS` | **`false` for the pilot** | notifications owner / task `11` | L06 wired the native FCM host (`app/android/app/src/main/kotlin/app/trainingarena/mobile/push/`); it stays inert without the owner's `google-services.json` and no-push is the pilot scope. The transport degrades to no-push and the in-app inbox stays authoritative |
| `ARENA_FEATURE_PREVIEW_FIXTURES` | **always `false`** | release owner | labelled fixtures; they can never produce receipts and must not ship |
| `ARENA_FEATURE_SOLO_MODE` | **`true` for the beta** | product owner | owner-approved 2026-09-30 (`docs/decisions/12-competitive-direction.md`); release-hold checks require it. Signed-out local sets never create receipts, ratings or leaderboard entries; manual entry is self-reported and solo-only |
| `ARENA_FEATURE_CAMERA_TRACE` | **always `false`** | camera owner / task `F3` | debug-only landmark tracing for the C05 replay harness: keeps the last three minutes of landmark numbers in memory and writes a text file only when the owner taps Export. Numbers only, no image; the release-hold check fails if it is `true` or unpinned |

Android host property (must move with `ARENA_LINK_HOST`):

```powershell
# Flutter forwards Gradle properties only via --android-project-arg / -P.
# ORG_GRADLE_PROJECT_* environment variables are not reliably visible to the
# Gradle invocation started by `flutter build` (verified 2026-09-20, L02).
flutter build appbundle --release -ParenaLinkHost="<real-host>" `
  --dart-define=ARENA_LINK_HOST="<real-host>" ...
```

## 2. Platform identity (frozen by `docs/CONTRACT.md` §4)

| Item | Value | Evidence |
| --- | --- | --- |
| Application ID / namespace / Kotlin package | `app.trainingarena.mobile` | `app/android/app/build.gradle`, `.../MainActivity.kt` |
| Application label | `Training Arena` | `AndroidManifest.xml`, `qa/camera/evidence/apk_manifest_evidence.txt` |
| `minSdk` / `targetSdk` | `24` / `36` (pinned; Play target requirement since 2026-08-31) | `app/android/app/build.gradle`, `check_artifact_identity.mjs` |
| Version | `app/pubspec.yaml` `1.0.1+2` | bump `version:` for every pilot build |
| Custom scheme | `trainingarena://challenge/**` | `AndroidManifest.xml` (local fallback only; shared messages use HTTPS) |
| App Links | `https://${arenaLinkHost}/c/`, `autoVerify=true` | `AndroidManifest.xml`; cannot verify on `example.invalid` |
| Privacy disclosure | Settings → Privacy: camera frames stay on-device; only rep counts reach the score; public profile is username/rating/optional avatar | `app/lib/account/ui/settings_page.dart` |
| Camera/notification disclosure | `CAMERA` + `POST_NOTIFICATIONS` declared; camera features optional; prompt only in context; denial keeps the inbox path | `AndroidManifest.xml`, `docs/notifications/ANDROID_PUSH_SETUP.md` |

### Android toolchain pins (L02, 2026-09-20)

Pinned so a release candidate is reproducible and Play-compatible. Enforced by
`tools/release/check_artifact_identity.mjs` (source checks) and
`tools/release/check_android_bundle.mjs` (artifact checks); updated together or
not at all.

| Component | Pin | Why |
| --- | --- | --- |
| Flutter / Dart | 3.47.5 / 3.13.4 (stable) | first supported line with targetSdk 36 + 16 KB page-size support; current stable patch at the freeze date |
| Gradle | 9.3.1 (`gradle-wrapper.properties`) | AGP 9.1 minimum; Flutter 3.47.5 template default |
| Android Gradle Plugin | 9.1.0 (`settings.gradle`) | Flutter 3.47.5 template default; required for API 36 |
| Kotlin Gradle Plugin | 2.4.0 (`settings.gradle`) | Flutter 3.47.5 template default |
| compileSdk / targetSdk | 36 / 36 (`app/build.gradle`, explicit) | Play new-submission target API requirement from 2026-08-31 |
| minSdk | 24 (explicit) | declared older-device support (32-bit armv7 + 64-bit) |
| Java / jvmTarget | 17 / 17 | Flutter 3.47.5 template default; AGP 9 requirement |
| NDK | not installed / no native sources | the app ships only Flutter/prebuilt AAR binaries; 16 KB is proven on the artifacts, not by an NDK number |
| bundletool | 1.18.2 (SHA-256 pinned in `tools/release/check_android_bundle.mjs`) | AAB manifest, native and delivery-size inspection |
| Local SDK roots (this machine) | `D:\toolchains\flutter-3.47.5\flutter`, `D:\toolchains\android-sdk` | independent of `D:\Kiro`; `app/android/local.properties` is gitignored |
| Android platform / build-tools | `platforms;android-36`, `build-tools;36.0.0` | API 36 manifest + `zipalign -P 16` |
| Google Services plugin | `com.google.gms.google-services` 4.5.0 (`settings.gradle`, applied conditionally) | L06; applied only when `app/android/app/google-services.json` exists |
| Firebase Messaging | `com.google.firebase:firebase-messaging:25.1.3` (`app/build.gradle`) | L06 native FCM host; no FlutterFire plugin and no BOM |

Compatibility flags kept from the Flutter 3.47.5 template
(`app/android/gradle.properties`): `android.newDsl=false`,
`android.builtInKotlin=false`, plus `kotlin.incremental=false` and
`kotlin.compiler.execution.strategy=in-process` (Kotlin 2.4.0 on Windows fails
to close incremental caches; re-test before removing). Follow-up R14 tracks the
built-in Kotlin migration.

## 3. Release signing (owner action — not configured in this workspace)

The release build **fails closed**: `app/android/app/build.gradle` aborts any
`*Release` task unless `app/android/key.properties` exists or the operator
passes one of two explicit non-distributable opt-ins:

- `-PallowDebugSignedRelease=true` — debug-signed release-equivalent APK for
  device smoke checks (never distributable);
- `-PallowUnsignedRelease=true` — unsigned AAB for bundle/native inspection
  (Play cannot accept it until the upload key signs it).

**Three different certificates — do not conflate them:**

| Certificate | What it signs | Where it appears | Used by |
| --- | --- | --- | --- |
| **Upload key** (owner release keystore) | the artifact uploaded to Play (the `.aab`) and any side-loaded release APK | `apksigner verify --print-certs` (APK) / `keytool -printcert -jarfile` (AAB) on the local artifact | CI `ARENA_RELEASE_CERT_SHA256` pins `check_artifact_identity.mjs --expect-signer-sha256` (APK) and `check_android_bundle.mjs --expect-uploader-sha256` (AAB) |
| **Play app-signing key** | the APK Play actually installs (Google re-signs uploads) | Play Console → App integrity (SHA-256 **and** SHA-1) | `assetlinks.json` fingerprint and Android OAuth client; CI `ARENA_PLAY_APP_SIGNING_CERT_SHA256` for `check_app_links.mjs --fingerprint` |
| **Local debug key** | `flutter build apk --debug` and the L02 smoke APK | `%USERPROFILE%\.android\debug.keystore` | never in `assetlinks.json`, never handed to testers |

Current L02 state: a release-equivalent APK (debug-signed smoke, SHA-256
`95522a3fd1b7dd3a6b934b8878fe7361c2db2f75a71a4d527dbd0c2fad45d821`,
90 198 461 bytes) and an unsigned AAB (84.7 MB) exist for compatibility
inspection; **both are non-distributable** and signing is the only artifact
blocker (R9). The old 307 MB debug APK is not a download size — the Play
delivery estimate for an arm64 API 36 device is ~19.5 MB
(`qa/launch/L02.md`).

Owner actions:

1. Create a release keystore once, outside the repository:

   ```powershell
   keytool -genkeypair -v -keystore D:\secrets\training-arena-release.jks `
     -alias training-arena-release -keyalg RSA -keysize 4096 -validity 10000
   ```

2. Create `app/android/key.properties` (gitignored) with:

   ```properties
   storeFile=D:\\secrets\\training-arena-release.jks
   storePassword=<from owner vault>
   keyAlias=training-arena-release
   keyPassword=<from owner vault>
   ```

3. Back up the keystore and passwords in the owner vault. Losing them makes
   every installed pilot build unupgradable without an app ID reset (with Play
   App Signing, the app-signing key is Google-held; losing the upload key can
   be recovered through Play support, losing the app-signing key cannot).
4. Put the same values in the CI secret store for the `release-candidate` job:
   `ANDROID_KEYSTORE_BASE64` (base64 of the `.jks`), `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
5. Record the certificate fingerprints:

   ```powershell
   keytool -list -v -keystore D:\secrets\training-arena-release.jks -alias training-arena-release |
     Select-String "SHA256:|SHA1:"
   ```

   - Set CI secret `ARENA_RELEASE_CERT_SHA256` to the **upload-key** SHA-256
     (both the AAB and the release APK are signed with it).
   - With Play App Signing, set CI secret
     `ARENA_PLAY_APP_SIGNING_CERT_SHA256` to the **Play app-signing**
     certificate SHA-256 from Play Console → App integrity. Use it for
     `assetlinks.json` and App Links verification; the upload-key fingerprint
     does not match the installed app.

Do not commit the keystore, `key.properties` or the passwords. The scanners and
`.gitignore` block them, but the owner remains responsible.

## 4. App Links and challenge-web deployment

1. Deploy `challenge-web/` on `https://<ARENA_LINK_HOST>` with `/c/*`
   rewriting to `index.html` and `config.js` set to the real host, API base,
   public URL, public anon key and the owner legal/contact/retention values
   (L07). The folder also serves the privacy policy (`/privacy.html`),
   support (`/support.html`) and the external deletion resource
   (`/delete-account.html`) linked from the app's Settings. Run
   `node challenge-web/scripts/check.mjs --release` before publishing; it
   fails while any owner value or endpoint is still a placeholder
   (`docs/release/PLAY_STORE_PACKET.md` §10).
2. Create `https://<ARENA_LINK_HOST>/.well-known/assetlinks.json` from
   `challenge-web/.well-known/assetlinks.json.template`:
   `package_name = app.trainingarena.mobile`, relation
   `delegate_permission/common.handle_all_urls`, `sha256_cert_fingerprints` =
   the **Play app-signing certificate** SHA-256 (Play Console → App integrity)
   for Play-distributed builds. Include the upload-key SHA-256 as a second
   fingerprint only if side-loaded upload-key builds must also verify links.
   Serve as `application/json` over HTTPS without redirects.
3. Verify locally before distribution:

   ```powershell
   node tools/release/check_app_links.mjs --release --host <real-host> `
     --fingerprint <play-app-signing-sha256> --fetch-assetlinks
   adb shell pm verify-app-links --reverify app.trainingarena.mobile
   adb shell pm get-app-links app.trainingarena.mobile
   ```

   The app must show `verified` for `https://<real-host>`.
4. `example.invalid` never deploys. The release gate fails on it
   (`tools/release/check_app_links.mjs --release`) **and** `app/android/app/build.gradle`
   aborts any distributable release build that still uses the placeholder
   (verified 2026-09-22; the `allowDebugSignedRelease`/`allowUnsignedRelease`
   opt-ins are the only bypass and produce non-distributable artifacts).

## 5. Play Install Referrer contract

- Landing Play URL:
  `https://play.google.com/store/apps/details?id=app.trainingarena.mobile&referrer=challenge%3D<token>`
  (`ArenaConfig.installReferrerUrl`).
- The app reads the raw referrer once through `InstallReferrerBridge` and
  accepts `challenge=<token>`, `token=<token>`, an encoded `/c/<token>` URL or
  `trainingarena://challenge/<token>`.
- Best effort only: when Play/Referrer is unavailable, the link recovery path
  is reopening the HTTPS link (App Links) or `Join with code` in the Battle
  tab. No challenge is lost, but install recovery cannot be guaranteed
  (documented in `docs/decisions/05-...`).

## 6. Supabase project (D3 — owner action)

1. Create a new hosted project. Never reuse the previous application's
   project, keys or tables.
2. Apply `supabase/migrations/` and keep `seed.sql` local-only (fake fixtures;
   never load into the hosted project).
3. Auth settings (hosted dashboard):
   - Site URL: `https://<ARENA_LINK_HOST>`.
   - Additional redirect URLs: `trainingarena://challenge/auth` (exact match
     with `ARENA_AUTH_REDIRECT_URL`; include the exact path used).
   - Email provider: email OTP enabled, `otp_length = 6`, codes expire per
     policy (`otp_expiry`), production SMTP configured (sender + templates).
   - Google provider: enable, set client ID/secret from the owner's Google
     Cloud OAuth client; restrict the OAuth consent screen to the pilot. The
     Android OAuth client is bound to package `app.trainingarena.mobile` and a
     signing certificate SHA-1: register the **Play app-signing certificate**
     SHA-1 (Play Console → App integrity) for Play-distributed builds; add the
     upload-key or debug SHA-1 only while side-loading local builds.
   - Disable anonymous sign-ins (`enable_anonymous_sign_ins = false`).
4. Edge Function secrets (`supabase secrets set`, server-side only):
   `ARENA_ALLOWED_ORIGINS` (the real landing origin(s), never `*` for release),
   `ARENA_PUBLIC_URL`, `ARENA_DISPATCHER_SECRET` (long random bearer),
   `FCM_SERVICE_ACCOUNT_JSON` (only when push delivery is enabled with owner
   authorization; not used by the no-push pilot).
   Platform-provided `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
   `SUPABASE_SERVICE_ROLE_KEY` stay in the hosted function settings.
   `SUPABASE_SERVICE_ROLE_KEY` must never appear in the app, the web page, the
   repository or CI logs.
5. Deploy `arena` (platform JWT verification disabled solely for the anonymous
   read-only GET; every POST verifies the token and session) and
   `arena-dispatcher` (its own bearer secret; with no FCM secret it runs
   maintenance only and `delivery: "not_configured"`).
6. Migration `20260930160034_arena_maintenance_schedule.sql` schedules
   `arena_maintenance()` directly in Postgres once per minute with `pg_cron`.
   This expires requests/queue seats and ticks matches without an HTTP bearer
   or push delivery. Applying migrations installs this maintenance schedule;
   verify the active `arena-maintenance` job after hosted deployment. Never
   load the local seed into the hosted project. Configure a push dispatcher
   worker and `FCM_SERVICE_ACCOUNT_JSON` only when push is approved. Task `08`
   implements the FCM HTTP v1 send path
   (`supabase/functions/arena-dispatcher/lib/fcm.ts`) and L06 implements the
   native Android host; the **pilot still ships no push**: the app is built
   with `ARENA_FEATURE_PUSH_NOTIFICATIONS=false`, the host stays inert without
   `google-services.json` (no channels, no token, `permissionStatus =
   notDetermined`), no notification is sent and the in-app inbox stays
   authoritative. Enabling delivery needs the Firebase Android app + JSON and
   the service-account secret, plus a physical-device verification pass.

RLS/service-role boundary (verified in `supabase/migrations/` and documented
in `docs/API.md` §7): RLS enabled on every `arena_*` table with no policies;
`anon`/`authenticated` have all table, sequence and function grants revoked;
clients reach data only through the Edge Function's service-role RPC client.
Camera frames are never accepted by any endpoint.

## 7. Secret handling

- Repository scan (default, git-visible files):

  ```powershell
  node tools/release/secret_scan.mjs
  node tools/release/secret_scan.mjs --artifacts   # scans built APK/AAB entries
  node tools/release/secret_scan.mjs --all --json  # also gitignored local files
  ```

  Status 2026-09-22: repository scan clean, artifact scan clean on the current
  debug APK; `--all` additionally flags only the gitignored local
  `supabase/.env.local` and `supabase/.temp/.../docker.env` service JWT (R12).
  The `private-key-block` rule matches complete PEM blocks
  (header, base64 body, footer), so synthetic template headers in tests are
  not false positives while real key material still fails the gate (R5
  closed); credential-bearing URLs and signed Supabase storage URLs are
  flagged too.

- The release environment/CI secret store is the only source for signing
  material, SMTP/OAuth secrets, the dispatcher secret and the FCM service
  account. `supabase/.env.local` and `supabase/.temp/**` are local-only and
  gitignored; `supabase/.temp/.../docker.env` contains a local-only service
  JWT and must never be committed or copied to a hosted environment.
- Logs, analytics and share exports must never contain tokens, emails, camera
  frames or raw landmarks. The gateway never logs tokens/emails; analytics
  events carry only the documented low-risk properties; the camera layer
  processes frames in memory. Re-verify these with the checklist items in
  `docs/release/RELEASE_CHECKLIST.md` §7.

### Session storage and device backup (L03)

- Auth sessions and the one in-flight PKCE verifier are stored in
  **Android Keystore-backed storage** via `flutter_secure_storage`
  (`SecureAuthSessionStore` in `app/lib/account/auth/auth_store.dart`; Android
  default AES-GCM with RSA-OAEP Keystore wrapping, API 23+). No token is
  written to a plaintext preferences file for new sessions.
- **Migration**: an existing `arena.auth.session.v1` / `arena.auth.pkce.v1`
  SharedPreferences value is read once, written to the secure store, and the
  plaintext copy is removed **only after** the secure write succeeds. If the
  secure write fails, the legacy value is kept so the user stays signed in and
  the migration is retried; a failed migration never drops the session.
- **Failure behavior**: a secure write failure fails sign-in closed with a
  plain `storage` message (never a silent plaintext fallback); a secure read
  failure degrades to signed-out; a delete failure is reported while the
  legacy copy is still removed. Logout and account deletion clear the secure
  and legacy copies; a failed account deletion keeps the valid session so the
  retry works.
- **Backup**: `android:allowBackup="false"` for the app. Keystore data is not
  restorable elsewhere and the remaining preferences are device-local, so no
  credential is eligible for cloud backup or device transfer.
- Verified by `app/test/account/secure_auth_store_test.dart` (round trip,
  migration, write/delete failure, clear) and the manifest assertion in
  `app/test/linking/android_link_config_test.dart`. Device-level verification
  of the Keystore path belongs to the L04 physical-device pass.

## 8. Exact owner actions to produce the first release candidate

1. Decide D1 (real HTTPS domain) and D3 (Supabase project) in
   `docs/decisions/0001-...` and `docs/decisions/03-...`.
2. Freeze and commit the release-candidate tree (R8); re-run all
   `tools/release/*` checks on that commit.
3. Create and vault the release keystore (§3) and upload the CI secrets.
4. Deploy the landing page, `assetlinks.json` and the Supabase project (§4-6).
5. Close the pilot entry gates from `PILOT_PLAN.md` §2: camera device
   validation (R1) or an explicitly scoped non-camera pilot, Google/redirect
   QA (R3) or email-OTP-only scope, and `qa/media` human review (R13);
   `qa/REPORT.md` (task `10`) is already delivered as a conditional pass.
6. Run the manual `release-candidate` workflow (or a local signed
   `flutter build appbundle --release` + `flutter build apk --release` with the
   dart-defines and `-ParenaLinkHost=...` above), verify with
   `tools/release/check_android_bundle.mjs` (AAB manifest, 16 KB native,
   delivery sizes, upload-key pin) and `check_artifact_identity.mjs`, then
   record the SHA-256/version of both artifacts.
7. Accept or reject `docs/release/GO_NO_GO.md`; publishing/deployment remains a
   separate owner-approved action.

### Beta checkpoint gates (2026-09-30)

The candidate pins solo/links/sharing on and ranked/push/fixtures/trace off.
Enabling camera also runs `tools/release/check_camera_evidence.mjs`: the
reviewed `qa/camera/beta_device_results.json` must cover two distinct physical
phones, every required scenario and resolved count discrepancies. The app
sources must match the tested commit. The gate checks record completeness;
it cannot establish physical accuracy. The current record is blocked.

CI writes `release-candidate.txt` alongside APK/AAB with commit, version,
scope flags and SHA-256 hashes. Local debug or unsigned artifacts remain
non-distributable. Hosted credentials, real domain/legal page values and
release signing are still missing; a local smoke pass does not close them.

## 9. Review-fix state (2026-09-22)

The launch review (`docs/release/REVIEW_2026-09-21.md`) dispatched three fix
batches. Their state on this tree:

- **Batch A (auth durability/lifecycle)** and **Batch B (public-deletion
  safety, ranked release hold, bundletool integrity)** are implemented in the
  working tree and verified: analyzer clean, 492/492 Flutter tests, 12/12
  release-tool regressions, 21/21 challenge-web tests, fresh identity and
  secret scans (`qa/launch/l11/release_checks_2026-09-22.txt`). They are
  **uncommitted** (R8 partially reopened); commit before building a candidate.
- **Batch C (native push capability/account ownership)** is **not
  implemented** — R17 in `GO_NO_GO.md` §4. It does not affect the no-push
  pilot (there is no `google-services.json` and the release workflow pins
  `ARENA_FEATURE_PUSH_NOTIFICATIONS=false`), but push must not be enabled
  before it closes.

The release workflow now enforces the holds mechanically:
`tools/release/check_release_flags.mjs` fails if ranked/push/preview are
re-enabled or the explicit camera choice is removed; `tools/release/bundletool.mjs`
verifies the pinned bundletool digest **before** any Java process runs.
