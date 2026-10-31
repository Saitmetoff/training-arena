# L06 prompt — native push, Google return and ranked scope

Paste this whole file into a new chat. It is self-contained.

## Role and rules

You are the sole coding executor for Training Arena in `D:/TrainingArena`.
Model: `opencode-go/deepseek-v4.1-flash`. One writer per tree: verify
`git status` first; **preserve any unrelated dirty/untracked files** (another
session may be mid-task) and never stage or revert work that is not yours. Do
not modify `D:/Kiro` or its shared toolchain. No product expansion, no
speculative framework, no generated fake evidence, no weakened release gates.
Trace every caller before changing a shared function. Reuse the existing
design, API and test tools. Commit only a scoped, secret-scanned change after
the relevant verification.

## Read first

A temp handoff may exist at
`C:\Users\ADMIN\AppData\Local\Temp\opencode\handoff.md`; read it if present,
otherwise reconstruct state from the docs below.

`docs/PROJECT_STATUS.md` (top sections), `docs/release/GO_NO_GO.md` (risk
register), `docs/release/CONFIGURATION.md` §1/§3/§6, `prompts/LAUNCH_CLOSEOUT_2026-09-20.md`
§L06, `qa/launch/L01.md`–`L05.md`, `qa/launch/l05/DEPLOYMENT_PACKET.md`,
`docs/notifications/ANDROID_PUSH_SETUP.md` (the binding bridge contract),
`docs/decisions/08-notifications-matchmaking-interface-decisions.md`,
`docs/API.md` §3/§5, `app/lib/notifications/` (all files),
`app/android/app/src/main/kotlin/app/trainingarena/mobile/MainActivity.kt`,
`app/android/app/build.gradle`, `app/android/app/proguard-rules.pro`.

Current state to verify, not assume: branch `codex/training-arena`, last L05
commit `1819ebf`; L04 physical camera/media evidence and L05 hosted connection
are **BLOCKED** on owner inputs; `ARENA_FEATURE_PUSH_NOTIFICATIONS=false` and
`ARENA_FEATURE_RANKED_MATCHMAKING=false` in the pilot scope.

## Scope (from the closeout pack, in order)

1. **Android FCM host.** Implement the missing native Android host for the
   exact channels and payloads in `app/lib/notifications/platform_push_transport.dart`
   and `docs/notifications/ANDROID_PUSH_SETUP.md` §2–§4: two notification
   channels, `FirebaseMessagingService` (`onNewToken` → tokens event channel,
   never logged; `onMessageReceived` → messages event channel + local
   notification whose `PendingIntent` reuses the `singleTop` `MainActivity`
   with the data map as extras), `permissionStatus`/`requestPermission` for
   API 33+ through the existing in-context flow, `deviceToken`, `initialTap`
   from launch extras, warm taps event channel, `dispose`. Do **not** build a
   second Dart notification service; the Dart layer, tap router and
   `device_register` path already exist. Keep
   `flutter_deeplinking_enabled=false` (task-05 contract). Tokens never go to
   logs, analytics or evidence.
   - Build hygiene: the repository must keep building and CI must stay green
     **without** the owner's Firebase config. Apply the Google Services
     plugin/`google-services.json`/service account only when the owner
     supplies them (smallest fail-closed mechanism, e.g. conditional plugin
     application); without config the bridge must degrade to "no push"
     exactly as the contract says, and the app must not crash or show a
     broken permission flow. Keep the existing R8 keeps working; re-run the
     API 36 and 16 KB emulator smokes after any dependency or shrinker change.
2. **Google OAuth return.** Wire the exact allowlisted redirect
   (`ARENA_AUTH_REDIRECT_URL`, suggested `trainingarena://challenge/auth`)
   using the **Play app-signing** identity (Android OAuth client SHA-1 +
   package `app.trainingarena.mobile`). Verify Google and email return to
   exactly the same pending challenge after process death, including
   username-required accounts. Hosted provider values and the Play
   app-signing certificate are owner inputs (L05 §0 / CONFIGURATION §3/§6).
   If they are absent, finish all local code/config work, add tests for the
   redirect/continuity logic that can run on the host, and report BLOCKED
   with the exact missing values — do not fake a hosted redirect.
3. **Ranked two-phone matrix.** With two physical devices and the pilot
   build: concurrent entry, blocked players, cancellation/back/background,
   the 15-second alternative, the 60-second stop, reconnect, tie/win/no-result
   and idempotent receipt/rating updates. Review obvious score-event
   replay/injection/rate abuse against existing protections; do not advertise
   cheating prevention beyond the evidence. If devices are not available,
   keep ranked inaccessible (`ARENA_FEATURE_RANKED_MATCHMAKING=false` and the
   existing L03 refusal path), document the narrower scope and mark the
   matrix BLOCKED. Do not use emulator fixtures as device evidence.

## Owner inputs required (ask only for what is missing)

Firebase Android app + `google-services.json` (gitignored) + FCM service
account JSON (server-side only); Google OAuth client id/secret and Play
app-signing SHA-1/SHA-256; a hosted project/auth/SMTP from L05; two physical
devices for ranked. Never commit credentials; never send a live notification
to a non-consenting user.

## Environment (reuse; do not modify D:/Kiro)

```powershell
$env:JAVA_HOME='D:\Kiro\.tooling\jdk17'
$env:PUB_CACHE='C:\Users\ADMIN\AppData\Local\Pub\Cache'
$env:GRADLE_USER_HOME='C:\Users\ADMIN\AppData\Local\GradleTA'
$flutter='D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat'
# from D:\TrainingArena\app
& $flutter analyze; & $flutter test
& $flutter build apk --release -PallowDebugSignedRelease=true   # smoke, non-distributable
# Deno edge tests (read-only toolchain)
& 'D:\Kiro\.tooling\deno\deno.exe' test tests
```

Gotchas: pass Gradle properties as `-Pname=value` (env vars do not reach
`flutter build`); keep `kotlin.incremental=false` +
`kotlin.compiler.execution.strategy=in-process`; keep the Room/ML Kit R8 keeps;
PowerShell 5.1 evidence files need `-Encoding utf8`; `flutter analyze` fails on
info-level findings.

## Verification and submission

- Run the full Flutter suite and analyzer, Deno arena/dispatcher tests, the
  release-equivalent APK build, `node tools/release/secret_scan.mjs` and
  `--artifacts`, and the API 36/16 KB emulator smokes after dependency
  changes. Record exact commands, exit codes and evidence paths under
  `qa/launch/l06/`; write the report to `qa/launch/L06.md`.
- Acceptance (report each PASS/FAIL/BLOCKED): native host implements every
  contract channel and degrades to no-push without config; permission
  ask-once/denied paths verified; foreground/background/terminated taps route
  to the exact request/match; duplicate/expired/blocked/cancelled payloads are
  harmless; token refresh/unregister and logout/account-switch verified; no
  token in logs; Google and email return to the same challenge after process
  death; ranked matrix with real two-phone evidence; no live send to
  non-consenting users; any deferred feature stays inaccessible and the
  narrower scope is documented.
- Submission must state repository, branch, starting/ending commit, model;
  what changed and the relevant diff; actual commands, exit status, evidence
  paths and skipped checks; per-criterion PASS/FAIL/BLOCKED; remaining
  dependencies and human decisions; measured active time and revised estimate.
- Stop after L06. Do not start L07+ work in this session.
