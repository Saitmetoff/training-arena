# Interface note 10 — native Android push host (fail-closed Firebase wiring)

Date: 2026-09-21
Author: L06 (native push, Google return, ranked scope)
Status: implemented; `flutter analyze` clean, 459 app tests pass, Deno arena 48
+ dispatcher 10 pass, release-equivalent APK/AAB build and the API 36 / 16 KB
emulator smokes pass. Live delivery and the Google return are **BLOCKED** on
owner Firebase/OAuth inputs (see `qa/launch/L06.md`).

`docs/CONTRACT.md` section 8 requires shared changes to be recorded. This note
records the additive Android host that implements the bridge contract in
`docs/notifications/ANDROID_PUSH_SETUP.md` §4 and the smallest fail-closed
mechanism that keeps the repository buildable without the owner's Firebase
project. No existing Dart notification code, channel name, payload key or tap
route changed; the Dart layer, tap router and `device_register` path are
untouched.

## What L06 delivered (owned paths)

- `app/android/app/src/main/kotlin/app/trainingarena/mobile/push/PushBridge.kt`
  — `FlutterPlugin` + `ActivityAware` host for the exact MethodChannel
  (`app.trainingarena.mobile/push`) and the three EventChannels
  (`.../messages`, `.../taps`, `.../tokens`); creates the
  `arena_requests`/`arena_matches` channels (API 26+, `IMPORTANCE_HIGH`);
  implements `permissionStatus`, `requestPermission` (API 33+ runtime dialog
  through `ActivityPluginBinding`), `deviceToken`, `initialTap` (launch
  extras) and `dispose`. Tokens never enter a log, analytics property or
  evidence file; the Kotlin sources contain no logging calls at all.
- `.../push/ArenaMessagingService.kt` — `FirebaseMessagingService`:
  `onNewToken` forwards to the `tokens` stream; `onMessageReceived` forwards
  the data map to `messages` and posts a local notification on the channel
  named by `android.notification.channel_id` (default `arena_requests`) whose
  `PendingIntent` reuses the `singleTop` `MainActivity` with the data map as
  extras. Duplicate deliveries replace the same notification id.
- `app/android/app/src/main/res/drawable/ic_arena_notification.xml` — the
  monochrome small icon referenced by
  `com.google.firebase.messaging.default_notification_icon`.
- `MainActivity.kt` — registers the bridge; `AndroidManifest.xml` declares the
  service (`exported="false"`, `com.google.firebase.MESSAGING_EVENT`), the
  default icon and keeps `flutter_deeplinking_enabled=false`.
- `app/android/settings.gradle` + `app/android/app/build.gradle` — pins the
  Google Services plugin `4.5.0` and `firebase-messaging:25.1.3`, and applies
  the plugin only when `app/android/app/google-services.json` exists.
- `app/test/notifications/android_push_host_config_test.dart` — host-runnable
  static contract checks (channels, methods, manifest, conditional plugin,
  channel ids cross-checked against the dispatcher `fcm.ts`).
- `app/test/account/oauth_return_continuity_test.dart` — the real
  `SupabaseAuthGateway` PKCE resume after process death returning to the same
  pending challenge for Google and email, including a username-required
  account, plus redirect-allowlist rejection.

## Fail-closed rule (binding)

1. Without `google-services.json` the Google Services plugin is not applied,
   no `google_app_id` resource exists, the Firebase default app does not
   initialize, and the bridge reports `permissionStatus = notDetermined`,
   `deviceToken = null`, empty streams and no notification channels. The app
   starts cleanly and never shows a permission prompt for a capability that
   cannot deliver; the in-app inbox stays authoritative.
2. No Dart-side permission rationale or `device_register` call is changed:
   with `ARENA_FEATURE_PUSH_NOTIFICATIONS=false` (pilot) the runtime still
   uses `UnavailablePushTransport` and the bridge is never consulted.
3. The service account JSON stays server-side; the client never holds a
   Firebase credential and no live notification was sent in L06.

## Frozen contracts that did not change

- Channel ids, data payload keys, permission status wire values, tap routing
  and dedupe keys are exactly the task-08 contract.
- `docs/API.md` actions (`device_register`, `analytics`) and the arena RPC
  authorization are untouched; no request body field is used as a user id.
- `flutter_deeplinking_enabled` stays `false`; notification taps are not
  routed through Flutter named-route deep links.
- No rating rule, match phase, receipt or wire value was touched.

## Open items

1. Live FCM delivery, permission ask-once/denied paths and tap routing need
   the owner's Firebase Android app + `google-services.json` and a physical
   device; recorded BLOCKED in `qa/launch/L06.md`.
2. Google return needs the hosted Supabase project, the Google provider
   client id/secret and the Play app-signing SHA-1 (Android OAuth client).
3. Ranked two-phone matrix needs two physical devices; ranked stays
   `ARENA_FEATURE_RANKED_MATCHMAKING=false` with the L03 refusal path.
