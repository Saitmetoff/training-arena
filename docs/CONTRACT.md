# Training Arena product and interface contract

Status: baseline, established by task `00` on 2026-09-17 (branch `codex/training-arena`).
This file is the shared contract for tasks `01`-`11`. Every change here is a
product decision and must be recorded in `docs/decisions/`. Dart, Android,
Supabase and web code must agree with this file; `docs/API.md` remains the
authoritative protocol contract owned by task `04`.

## 1. Product

- App name: **Training Arena**.
- Scope: camera-counted push-up and squat battles, plus device-local solo
  practice (decision 12, owner-approved solo-first beta on 2026-09-30).
- Out of scope, permanently: pull-ups, training plans, chat, followers,
  currency, async score challenges and bots.
- Invite-first loop: receive a challenge → accept → both ready → 60-second
  battle → confirmed result → share a new challenge.
- Sign-in is required for battles; solo works signed out. New users choose a unique username; avatar upload is
  optional and can be deferred. A pending friend challenge resumes straight
  into that challenge, never through generic onboarding.
- Camera frames stay on device. Competitive reps come only from the camera
  counter; manual entry is confined to solo and labelled self-reported.
  Solo never creates a server receipt, rating or leaderboard entry.
- Ranked matchmaking changes Elo (start `1000`, `K=32`) only after a
  server-confirmed ranked result. Personal challenges and friend rematches
  are casual and never change rating.

Server-owned match rules (details in `docs/API.md`): five-second countdown,
60-second round, idempotent sequenced rep events, ~1s heartbeats while live,
`no_result` when both sides lose heartbeats, one authoritative receipt per
match. A backend outage is reconciled conservatively before a winner exists.

## 2. Navigation

Bottom navigation, in this exact order and default:

| Index | Tab | Default |
| --- | --- | --- |
| 0 | Leaderboard |  |
| 1 | **Battle** | selected on launch |
| 2 | Profile |  |

The shell lives in `app/lib/shell/arena_shell.dart`. Task `06` replaces the
Leaderboard/Profile bodies and task `07` replaces the Battle body; the order,
the default index and the `ArenaTab` names are frozen.

## 3. Visual identity

All Dart colors come from the single token file
`app/lib/theme/arena_tokens.dart` (`ArenaColors`). The native Android splash
mirrors only `charcoal` in
`app/android/app/src/main/res/values/colors.xml`.

| Token | Hex | Use |
| --- | --- | --- |
| `charcoal` | `#17191A` | app background |
| `graphite` | `#242729` | cards, navigation surface |
| `raised` | `#303537` | sheets, chips, raised surfaces |
| `lime` | `#D6FF3F` | current player, primary action |
| `violet` | `#BEA1FF` | opponent |
| `softWhite` | `#F6F7F2` | primary text |
| `secondary` | `#B6BDB9` | secondary text |
| `quiet` | `#9BA59E` | quiet/disabled text |
| `positive` | `#7AE5A0` | ready/win states |
| `warning` | `#FFD66E` | warnings |
| `danger` | `#FF807C` | errors, destructive actions |

Task `01` owns the full visual system and may add tokens; it may not rename or
revalue the contract colors. No other Dart file may define raw color literals
for these roles.

## 4. Platform identifiers

| Item | Value | Owner |
| --- | --- | --- |
| Android application ID | `app.trainingarena.mobile` | task `00` (release task may not change without a decision note) |
| Android namespace / Kotlin package | `app.trainingarena.mobile` | task `00` |
| Application label | `Training Arena` | task `00` |
| `minSdk` | 24 | task `00` |
| `compileSdk` / `targetSdk` | Flutter toolchain defaults (34 at baseline) | task `00`/`11` |
| Base permission | `android.permission.INTERNET` only | task `00` |

Camera permissions belong to task `03`, notification permissions and link
intent filters to tasks `08`/`05`. The runtime must not contain legacy
package names, labels, comments or deep-link hosts. Challenge links use the
config contract below; the HTTPS host stays `example.invalid` until the owner
supplies the real domain.

## 5. Configuration contract

`app/lib/config/arena_config.dart` (`ArenaConfig`) is the only config reader.
Values arrive as `--dart-define`; defaults are safe placeholders. Keys are
additive: tasks add keys, they never rename or repurpose existing ones.

| Key | Default | Meaning | Owner |
| --- | --- | --- | --- |
| `ARENA_PUBLIC_URL` | `https://example.invalid` | public site URL for shared content | `05`, `09` |
| `ARENA_LINK_HOST` | `example.invalid` | host serving `/c/<token>` challenge links | `05` (real domain missing, see status) |
| `ARENA_PLAY_STORE_URL` | `https://play.google.com/store/apps/details?id=app.trainingarena.mobile` | supported Play install/update route | `05` |
| `ARENA_SUPABASE_URL` | empty | Supabase project URL | `04` |
| `ARENA_SUPABASE_ANON_KEY` | empty | Supabase anon (public) key only | `04` |
| `ARENA_FEATURE_CAMERA_COUNTING` | `false` | camera counter enabled | `03` |
| `ARENA_FEATURE_CHALLENGE_LINKS` | `false` | challenge links enabled | `05` |
| `ARENA_FEATURE_RANKED_MATCHMAKING` | `false` | ranked queue enabled | `08` |
| `ARENA_FEATURE_PUSH_NOTIFICATIONS` | `false` | request push permission, token registration and tap routing enabled | `08` |
| `ARENA_FEATURE_RESULT_SHARING` | `false` | share cards enabled | `09` |
| `ARENA_FEATURE_SOLO_MODE` | `false` | local, non-competitive solo max-reps set enabled (decision 12) | `C01` |
| `ARENA_FEATURE_CAMERA_TRACE` | `false` | debug-only landmark trace export for the replay harness; never enabled in a release build | `F3` |

Rules: only public client values may be compiled into the app. Service-role
keys, dispatcher secrets and FCM service accounts live server-side and are
never committed. `ArenaConfig.challengeLink(token)` builds
`https://<linkHost>/c/<token>` as fixed by `docs/API.md`, and
`ArenaConfigScope.of(context)` exposes the values to widgets.

## 6. Domain interface layer

`app/lib/domain/arena_types.dart` is pure Dart (no Flutter, Supabase, camera
or platform imports). Tasks `03`, `04`, `06`-`09` consume these types; new
fields/types are additive and need a decision note.

Constants: `arenaStartingRating = 1000`, `arenaEloKFactor = 32`.

| Type | Fields | Wire values |
| --- | --- | --- |
| `ArenaExercise` (enum) | `wire`, `label` | `pushups`, `squats` |
| `ArenaMatchMode` (enum) | `wire`, `label` | `casual`, `ranked` |
| `ArenaMatchStatus` (enum) | `wire` | `preparing`, `countdown`, `live`, `finished`, `no_result` |
| `ArenaMatchOutcome` (enum) | `wire` | `win`, `draw`, `no_result` |
| `ArenaProfile` | `id`, `username?`, `avatarUrl?`, `rating` (default 1000), `rankedWins`, `rankedBattles`, `displayName` | — |
| `ChallengeContext` | `token` (required), `sender?`, `matchId?`, `receivedAt?`, `isResolved`, `copyWith` | token is the 12-char link/code identifier |
| `ArenaReceiptPlayer` | `profile`, `score`, `ratingAfter?`, `ratingChange?` | casual/no-result ratings are null |
| `ResultReceipt` | `id`, `matchId`, `exercise`, `mode`, `players`, `outcome`, `winnerId?`, `finishedAt?`, `reason?`, `outcomeFor(userId)` | immutable server-confirmed result |

`ArenaExercise.tryFromWire`, `ArenaMatchMode.tryFromWire`,
`ArenaMatchStatus.tryFromWire` and `ArenaMatchOutcome.tryFromWire` return
`null` for unknown input so API boundaries can fail closed.

## 7. Task interfaces

Each task owns its paths; it must not rewrite another task's paths, and shared
changes go through a `docs/decisions/` note applied by the owning task.

| Task | Owns | Baseline it consumes | Must not change |
| --- | --- | --- | --- |
| `01` design system | `design/arena/`, `prototype/` | token values and names, tab order | `ArenaColors` contract values, tab order |
| `02` 3D athlete media | `app/assets/media/`, `docs/media/`, `qa/media/` | shell compiles without media | pubspec `flutter:` section ownership of fonts, shell structure |
| `03` camera rep counting | `app/lib/camera/`, camera Android bridge, camera tests | `ArenaExercise`, config flag `ARENA_FEATURE_CAMERA_COUNTING` | no camera frames to network, no manual entry, base manifest beyond camera permission additions |
| `04` backend | `supabase/`, `backend/`, `docs/API.md` | config keys for project URL/anon key, domain wire values | object shapes in `docs/API.md` only with a decision note |
| `05` challenge links/install | `challenge-web/`, `app/lib/linking/`, Android link manifest/config | `ArenaConfig.challengeLink`, `ChallengeContext` | `/c/<token>` path, link host config key, application ID |
| `06` account/profile/leaderboard | account/profile/leaderboard Flutter features | `ArenaProfile`, `ArenaTab.leaderboard/profile` bodies | `ArenaProfile` field names, tab order/default |
| `07` battle runtime UI | battle Flutter features and UI tests | `ArenaMatchStatus`, `ArenaMatchMode`, `ResultReceipt`, Battle tab body | mode/status wire values, camera-only scoring |
| `08` notifications/matchmaking | notification service, matchmaking UI, worker docs | ranked flag, `ArenaMatchMode.ranked` | Elo rules (1000/K32 ranked-only), no bots |
| `09` result sharing | sharing Flutter feature, card renderer, share tests | `ResultReceipt`, `ArenaConfig.publicUrl`, share flag | receipt facts (no invented numbers), real challenge URLs |
| `10` integration/device QA | `qa/`, integration tests, QA reports | buildable shell, all above | not a production deploy |
| `11` release pilot | `docs/release/`, CI/release checks | platform identifiers, config keys | application ID, contract colors, scope |

## 8. Change control

1. Keep the shell compiling: every intermediate commit must pass
   `flutter analyze` and the focused test.
2. Additive-only interfaces; renaming or removing a contract symbol needs a
   `docs/decisions/` note accepted by the owner of that path.
3. Never commit secrets, keystores, service-role keys or Firebase files.
4. Never reintroduce the legacy application's identifiers, screens or
   dependencies.
