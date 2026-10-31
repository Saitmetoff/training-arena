# Interface note 08 — request notifications and honest ranked search

Date: 2026-09-18
Author: task `08` (request notifications and honest low-population
matchmaking)
Status: implemented; `flutter analyze` clean on the owned paths, focused
Flutter and Deno tests passing

This note records the additive changes task `08` had to make to paths owned
by other tasks, as required by `docs/CONTRACT.md` section 8. It also fixes
the queue behaviour that task `07` deliberately left to this task.

## What this task delivered

Owned paths only (`app/lib/notifications/`, `app/test/notifications/`,
`app/test/matchmaking/`, dispatcher FCM module and tests, this note):

- `notifications/notification_models.dart` — wire payload parsing
  (`challenge_request`, `request_accepted`, `request_declined`,
  `match_ready`, `match_finished`), permission status and dedupe keys.
  Parsing never throws and unknown input fails closed.
- `notifications/push_transport.dart` — platform port plus the inert
  `UnavailablePushTransport`.
- `notifications/platform_push_transport.dart` — production method/event
  channel adapter (`app.trainingarena.mobile/push`); every platform failure
  degrades to no-push.
- `notifications/notification_api.dart` — `device_register` and `analytics`
  over the documented arena envelope. Tokens are sent only here and never
  logged.
- `notifications/notification_permission_store.dart` — the ask-once flag.
- `notifications/notification_request_source.dart` — authoritative inbox /
  `match_state` lookup used by the tap router.
- `notifications/notification_service.dart` — permission, token
  registration, foreground/tap/token streams, duplicate suppression and the
  exact-target routing contract.
- `notifications/notification_runtime.dart`,
  `notifications/ui/notification_gate.dart` — composition root and the
  focused gate (pending request, match ready, explanatory closed/failed
  screens, permission rationale).
- `notifications/matchmaking_analytics.dart` — best-effort `analytics` sink
  for the queue events.
- `supabase/functions/arena-dispatcher/lib/fcm.ts` + tests — FCM HTTP v1
  send path with RS256 service-account auth, channel/data shaping, invalid
  token detection and unregistered-token cleanup. No live send was run.
- `docs/notifications/ANDROID_PUSH_SETUP.md` — Android channel, API 33
  permission, native bridge contract, worker secrets and task `11`
  checklist.

## Additive shared changes applied by this task

1. `app/lib/config/arena_config.dart` — new key
   `ARENA_FEATURE_PUSH_NOTIFICATIONS` (default `false`). Push is only wired
   when the build also has Supabase credentials. Recorded in
   `docs/CONTRACT.md` §5.
2. `app/lib/battle/ports/battle_analytics.dart` — new port
   `BattleAnalyticsSink` plus `NoopBattleAnalyticsSink` and the stable event
   names. Analytics failures can never block a battle.
3. `app/lib/battle/state/battle_models.dart` — `BattleQueueState.queued`
   (wire key already documented as additive in `docs/API.md`), with
   `seatActive` meaning "server still holds this seat".
4. `app/lib/battle/state/battle_events.dart` + `battle_state_machine.dart` —
   new events `QueueSeatClosed`, `QueueContactLost`, `QueueContactRestored`
   and the additive snapshot field `BattleSnapshot.queueOffline`. No
   existing event, phase or wire value was renamed or removed.
5. `app/lib/battle/runtime/battle_controller.dart` —
   - polls `queue_poll` every 2 seconds while a seat is open (task `07` left
     the call to this task) and enters preparation only from the
     server-issued `match_id`;
   - refuses a second seat: a guard while `queue_join` is in flight and a
     guard while a match is active;
   - releases the seat idempotently on Back, app pause, manual stop and
     friend-challenge switch; failed leaves never surface because the seat
     expires server-side;
   - keeps the 60-second window monotonic so a stale server clock cannot
     extend the search;
   - observes app lifecycle (`WidgetsBindingObserver`) and tracks the five
     matchmaking analytics events;
   - exposes `attachRequestActivityListener` so `ArenaApp` can offer the
     notification prompt after a send or a link-accept send.
6. `app/lib/battle/data/http_battle_backend.dart` — parses the additive
   `queued` key (absent means unknown, never "closed").
7. `app/lib/battle/runtime/battle_runtime.dart` — optional
   `matchmakingAnalytics` port; production builds default to the arena
   `analytics` client when credentials exist.
8. `app/lib/battle/ui/battle_tab.dart` — `Find an opponent` now says
   "Ranked · camera-counted"; the search card shows a Reconnecting state
   instead of implying an opponent is online; `PopScope` cancels the seat
   before allowing Back to leave the app.
9. `app/lib/arena_app.dart` — builds/injects the notification runtime,
   listens for the first request activity (incoming request, in-app send and
   link-accept send), shows the permission rationale in context, refreshes
   the inbox on foreground messages and renders `NotificationGate` for a tap.
10. `app/android/app/src/main/AndroidManifest.xml` — adds
    `POST_NOTIFICATIONS` and the default FCM channel metadata. No Firebase
    credential or Gradle dependency was added.
11. `app/.gitignore` — ignores `google-services.json`,
    `GoogleService-Info.plist`, `firebase_options.dart` and service-account
    JSON files.
12. `supabase/functions/arena-dispatcher/index.ts` — uses the new FCM sender,
    deletes device rows FCM reports as unregistered and never logs tokens.
    The no-service-account behaviour (maintenance only) is unchanged.
13. `app/test/support/battle_fakes.dart` + `battle_harness.dart` — the fake
    queue keeps a stable `queued_since` and the harness accepts an analytics
    sink. Task `07`'s fixture test expectation changed from `danger` to
    `warning` because the active-match guard now refuses a second seat before
    the fixture backend answers; the intended check (no ranked seat ever
    exists) is unchanged.

## Frozen contracts that did not change

- No rating rule, Elo value, exercise, match status/phase or wire value was
  touched. Countdown/live/result still come only from the server.
- No bot, no async score challenge, no manual score entry.
- Backend authorization is untouched: `device_register` and `analytics` are
  still called through the authenticated Edge Function, and no request body
  field is used as a user id.
- The `arena` and `arena-dispatcher` secrets stay server-side; nothing in
  the repository contains a Firebase credential.

## Analytics events (best effort, never blocking)

| Event | When | Properties |
| --- | --- | --- |
| `matchmaking_search_started` | queue seat created | `mode: ranked` |
| `matchmaking_match_found` | server issued a match | `mode: ranked` |
| `matchmaking_search_cancelled` | manual stop, app pause, friend switch or server-closed seat | `reason: manual \| app_paused \| friend_challenge \| seat_closed` |
| `matchmaking_search_timed_out` | 60-second window elapsed with no match | `elapsed_seconds: 60` |
| `matchmaking_friend_alternative` | 15-second alternative offered or chosen | `action: offered \| switched` |

Opening a share sheet is **not** tracked as a referral; the friend-challenge
event only records that the alternative exists or was chosen.

## Evidence

From `app/` (Flutter 3.24.5 / Dart 3.5.4):

- `dart analyze lib/notifications lib/battle lib/arena_app.dart lib/config
  test/notifications test/matchmaking test/support` — `No issues found!`
- `flutter test test/notifications test/matchmaking` — 44 tests passed.
- `flutter test test/notifications test/matchmaking test/battle
  test/linking test/camera test/arena_shell_smoke_test.dart` — 234 tests
  passed together (the earlier sporadic loader errors were the host system
  drive being full, not the code; stale Flutter temp directories were
  cleared before the final run).

From `supabase/functions/arena-dispatcher/` (Deno 2.9.6):

- `deno test tests` — 10 FCM tests passed.
- `deno check index.ts` — clean.

## Unresolved risks / open items

1. The native Android FCM host and `google-services.json` are task `11`
   work; this task delivers the Dart bridge, manifest permissions and the
   documented contract. No live push was sent or received.
2. `docs/API.md` records that live device/Play/FCM integration and load
   testing are required before release.
3. Task `06`'s account suite currently has unrelated in-progress compile
   errors in the shared checkout; they are not touched by this task and the
   focused suites above do not depend on them.
