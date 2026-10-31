# Android push and notification worker setup (task 08)

Task `08` ships the client notification plumbing, the tap router and the
server worker send path. **No live FCM send was performed in this task**: the
worker was exercised only with injected fakes. This file is the deployment
checklist for task `11`, which owns the live Firebase project.

Nothing in this document is a credential. `google-services.json`,
`google-services.json`-derived Dart options and the FCM service account JSON
are never committed; `app/.gitignore` already excludes them.

## 1. Delivery model

```text
request/match RPC ──insert──> arena_notification_outbox
                                      │ lease (60 s) / confirm (retry 60 s)
                                      v
                     POST /functions/v1/arena-dispatcher
                     Authorization: Bearer <ARENA_DISPATCHER_SECRET>
                                      │ FCM HTTP v1, per device token
                                      v
                                 Android device
                                      │ tap → data payload
                                      v
                     NotificationService → exact request/match or
                     explanatory screen; `inbox` remains authoritative
```

The in-app request inbox is the source of truth at every step. Permission
denial, a missing token, an expired token or a failed send never hides or
changes a request.

## 2. Android notification channels (native host)

The FCM payload names the channel in `android.notification.channel_id`
(`supabase/functions/arena-dispatcher/lib/fcm.ts`):

| Channel id | Name | Importance | Used for |
| --- | --- | --- | --- |
| `arena_requests` | Challenge requests | `IMPORTANCE_HIGH` | `challenge_request`, `request_declined`, unknown kinds |
| `arena_matches` | Battle updates | `IMPORTANCE_HIGH` | `request_accepted`, `match_ready`, `match_finished` |

The native host creates both channels before the first notification
(`NotificationManager.createNotificationChannel`, API 26+) with a short
description. `AndroidManifest.xml` already declares
`com.google.firebase.messaging.default_notification_channel_id =
"arena_requests"`, so a payload that omits the channel still lands on the
requests channel.

## 3. API 33 runtime permission

`AndroidManifest.xml` already declares
`android.permission.POST_NOTIFICATIONS`. On Android 13+ the app must ask at
runtime:

- The prompt is offered once, in context, when the user first **sends or
  receives a challenge request** (`NotificationService.noteRequestActivity`).
- The in-app rationale is `showNotificationPermissionRationale`; the OS
  dialog is requested only after the user taps **Allow**.
- Denial (in-app "Not now" or OS denial) leaves the request fully usable:
  the inbox keeps rendering it and no state is changed.
- When the OS has already denied permanently, the app does not nag; the
  Profile/notifications surface may deep-link to the app notification
  settings page. `PushPermissionStatus` is `denied` in that case.

## 4. Native bridge contract (Dart ↔ Android host)

`app/lib/notifications/platform_push_transport.dart` speaks the following
channels. The native host is implemented in
`app/android/app/src/main/kotlin/app/trainingarena/mobile/push/` (L06); the
Dart layer, tap router and `device_register` path are unchanged. Without the
owner's `google-services.json` the bridge degrades to "no push" exactly as
described below and never breaks the app.

```text
MethodChannel  app.trainingarena.mobile/push
  permissionStatus() -> "granted" | "denied" | "notDetermined"
  requestPermission() -> "granted" | "denied" | "notDetermined"
  deviceToken() -> String | null       // FCM registration token
  initialTap() -> Map | null           // cold-start tap payload
  dispose() -> null

EventChannel   app.trainingarena.mobile/push/messages  // foreground data
EventChannel   app.trainingarena.mobile/push/taps      // warm taps
EventChannel   app.trainingarena.mobile/push/tokens    // token rotation
```

Data payload keys (all strings, produced by the worker):

| kind | keys |
| --- | --- |
| `challenge_request` | `kind`, `request_id`, `sender_id`, `sender_username` |
| `request_accepted` | `kind`, `request_id`, `match_id` |
| `request_declined` | `kind`, `request_id`, `status` |
| `match_ready` | `kind`, `match_id` |
| `match_finished` | `kind`, `match_id`, `receipt_id` |

Native host requirements:

1. `FirebaseMessagingService.onNewToken` forwards the token to the
   `tokens` event channel and never logs it.
2. `onMessageReceived` forwards the data map to `messages` and builds a
   local notification with the channel from `channel_id` (default
   `arena_requests`). The notification `PendingIntent` must reuse the
   launcher `MainActivity` (already `singleTop`) with the data map as
   intent extras, so warm and cold taps both reach the `taps`/`initialTap`
   methods.
3. `flutter_deeplinking_enabled` stays `false` (task 05 contract); the
   notification tap must not be routed through Flutter's named-route
   deep-link handling.
4. The token is only ever passed to the Dart layer; the Dart layer sends it
   to the backend through `device_register` and never logs it or puts it in
   analytics properties.

Fail-closed rule (L06): the host is compiled into every build, but the
Google Services plugin (and therefore any Firebase credential) is applied
only when `app/android/app/google-services.json` exists. Without it
`FirebaseApp.getApps()` is empty and the bridge returns `notDetermined` /
`null` / empty streams and creates no notification channels, so a build
without the owner's Firebase project is still fully usable and never shows
a permission prompt that cannot deliver.

## 5. Firebase project checklist (task 11)

1. Create/attach the Firebase Android app for application ID
   `app.trainingarena.mobile`; place `google-services.json` at
   `app/android/app/google-services.json` (gitignored, CI secret).
2. The Google Services Gradle plugin (`com.google.gms.google-services`
   `4.5.0`) is declared in `app/android/settings.gradle` and applied by
   `app/android/app/build.gradle` only when the JSON above exists; the
   Firebase BOM is not used and `firebase-messaging` is pinned to `25.1.3`
   (see `docs/release/CONFIGURATION.md` §2).
3. The two channels are created by the native host
   (`PushBridge.ensureChannels`) before the first notification.
4. The native bridge is registered in `MainActivity`; `initialTap()` reads
   the launch intent extras and warm taps arrive through `onNewIntent`.
5. Request `POST_NOTIFICATIONS` only through the in-context flow; verify the
   denied path still shows incoming requests in Battle.
6. Do not commit any Firebase config; supply it per build machine.

## 6. Worker configuration and secrets

| Name | Where | Purpose |
| --- | --- | --- |
| `SUPABASE_URL` | function env (automatic) | project URL for the service client |
| `SUPABASE_SERVICE_ROLE_KEY` | function secret (automatic) | service-role RPC/table access; server-only |
| `ARENA_DISPATCHER_SECRET` | function secret | bearer secret for the dispatcher endpoint; never an app token |
| `FCM_SERVICE_ACCOUNT_JSON` | function secret | Firebase service account JSON used by `lib/fcm.ts`; enables delivery |
| `ARENA_ALLOWED_ORIGINS`, `ARENA_PUBLIC_URL` | function secrets | the `arena` function's CORS/public URL config (task 04) |

The dispatcher reads the service account with `JSON.parse`; a malformed value
fails closed with `dispatcher_not_configured` and never echoes the value.
Access tokens are minted from the service account with the
`https://www.googleapis.com/auth/firebase.messaging` scope and cached until
60 seconds before expiry.

Scheduling (task 11): invoke the worker at least once per minute, for
example Supabase Cron (`pg_cron` + `pg_net`) calling
`net.http_post('https://<project>.functions.supabase.co/arena-dispatcher',
headers => '{"Authorization":"Bearer <ARENA_DISPATCHER_SECRET>"}')` with the
secret provided through Vault rather than committed SQL, or an external
scheduler. Concurrent workers are safe: `arena_outbox_lease` uses
`FOR UPDATE SKIP LOCKED` and `arena_outbox_confirm` only accepts the current
lease owner. Retries stop after 5 attempts and the row becomes `failed`; the
inbox action is unaffected either way.

## 7. Verification checklist for task 11

- [ ] Permission allowed: request arrives, OS dialog shown in context, token
      registered once via `device_register`.
- [ ] Permission denied: no token registered, request visible and usable in
      Battle, prompt never repeats.
- [ ] Foreground message refreshes the inbox; background and cold-start taps
      open the exact pending request or match preparation.
- [ ] Duplicate delivery/tap of the same message id is harmless.
- [ ] Expired, cancelled, blocked and already-accepted taps show the
      explanatory screen.
- [ ] Invalid FCM tokens are deleted from `arena_devices`; logs never contain
      a token.
- [ ] Outbox drains with lease/retry; a killed worker does not strand rows.
- [ ] Load test before release (`docs/API.md` deployment section).

L06 status (2026-09-21): the host contract, the fail-closed degrade without
`google-services.json`, the release build and the API 36 / 16 KB emulator
smokes are verified locally. The live rows above remain **BLOCKED** until the
owner supplies the Firebase Android app + `google-services.json` and a
physical device; see `qa/launch/L06.md` for the exact missing inputs.
