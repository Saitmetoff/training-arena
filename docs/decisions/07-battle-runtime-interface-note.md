# Interface note 07 — battle runtime and state-driven UI

Date: 2026-09-18
Author: task `07` (battle runtime and state-driven UI)
Status: implemented; `flutter analyze` clean and all 186 app tests pass

## Why this note exists

`docs/CONTRACT.md` section 8 requires shared changes to be recorded before
they land, and `prompts/README.md` requires every task to report files
changed, tests run and unresolved risks. This note records the battle state
contract, the additive changes this task had to make to shared paths, and the
exact seams the camera (`03`), backend (`04`), linking (`05`), account (`06`),
matchmaking (`08`) and sharing (`09`) tasks plug into.

Task `07` consumed the landed interfaces instead of duplicating them:
`app/lib/camera/` (`CameraSession`, `CameraPreview`, `RepEvent`),
`app/lib/linking/` (`ChallengeEntryController`, `ChallengeShareService`,
`ArenaLinking`, `ArenaChallengeApi`), `docs/API.md` (task `04` decisions
included) and `design/arena/` (task `01` tokens, component rules, screen map).
`D:\Kiro` was not read or modified.

## What this task delivered

Owned paths only (`app/lib/battle/`, battle tests, this note):

- `battle/state/` — explicit state model: `BattlePhase`, `BattleConnection`,
  `PracticeState`, `BattleCameraStatus`, `BattleLoadStatus`,
  `BattleQueuePhase`, `BattleMatchOrigin`, `BattleExitReason`,
  `BattleNoticeKind`; `BattleSnapshot`; sealed `BattleEvent`s; the pure
  `BattleStateMachine`.
- `battle/ports/` — `BattleBackend`, `BattleCamera`, `BattleClock`,
  `BattleFeedback`, `BattleSessionStore`, `BattleChallengeSharer`,
  `BattleChallengeEntryDelegate`.
- `battle/data/` — production adapters: `HttpBattleBackend` (arena Edge
  Function envelope), `CameraSessionBattleCamera` (task `03` sessions and
  `CameraPreview`), `ChallengeShareServiceSharer` and `ChallengeEntryDelegate`
  (task `05`).
- `battle/runtime/` — `BattleController` (inbox polling, 1 Hz heartbeats,
  server-clock offset, queue windows, 10-second recovery window, rep queue
  with stable event ids) and `BattleRuntime` + `BattleRuntimeScope`.
- `battle/fixtures/` — deterministic preview fixtures, labelled and blocked
  from receipts.
- `battle/ui/` — Battle tab, request inbox, phase-driven flow page,
  preparation (athlete media fallback chain, framing, one unscored practice
  rep), ready gate, server countdown, live round, reconnect banners, result,
  no-result, leave/decline/join-code dialogs.
- `test/battle/` — state-machine, controller, contract and widget tests, plus
  `test/support/battle_fakes.dart` and `test/support/battle_widget_harness.dart`.

## State contract (frozen; adapters must not change it)

Runtime states: link/request/inbox (`home`, `inbox`, `resolving`),
`preparing`, `ready`, `countdown`, `live`, `reconnecting`, `result`,
`noResult`, `exiting`, `exited`.

Rules encoded in `BattleStateMachine` and enforced by tests:

1. A request/link accept creates a match in `preparing`; countdown and live
   play are only entered from server match status. Both ready checks are
   required.
2. `BattlePhase.result` is reached only from a server `ResultReceipt`.
   A `finished` match without a receipt stays unresolved.
3. Camera tracking loss pauses only that player's counting
   (`BattleConnection.selfTrackingLost`); the shared clock keeps running.
4. Two consecutive lost server contacts open the outage window at the first
   lost contact; after ten seconds `reconnectExpired` is set and the server
   still owns the outcome. Both-side failure becomes `no_result` with no
   rating change; ties stay ties.
5. Stale or duplicate match snapshots (older `server_now` or a status
   regression at the same clock) never regress state; duplicate rep event ids
   are re-sent unchanged and never double-count.
6. No UI path writes a competitive score. Practice reps are unscored and
   non-competitive camera events are ignored with honest copy.

## Additive shared changes applied by this task

1. `app/lib/theme/arena_tokens.dart` — added the task-01 tokens that were
   missing from the Dart mirror: `line`, `lineStrong`, `playerInk`,
   `playerWash`, `opponentInk`, `opponentWash`, `focus`, `overlay`. Values
   mirror `design/arena/tokens.json` exactly; no contract colour was renamed
   or re-valued, and no second palette was introduced.
2. `app/lib/config/arena_config.dart` — additive key
   `ARENA_FEATURE_PREVIEW_FIXTURES` (default `false`). It enables the
   labelled preview fixtures only. It must never be set in a release build;
   fixtures cannot produce ranked or casual receipts.
3. `app/pubspec.yaml` — added the six `assets/media/athlete/...` entries
   requested by task `02` (its interface note asked the baseline owner to
   apply them; task `07` needs them for the preparation demonstration).
4. `app/lib/arena_app.dart` — now builds (or accepts) an `ArenaLinking`
   bundle, starts challenge entry, renders `ChallengeEntryView` instead of
   the shell while a link is focused, and exposes the `linking` and
   `onMatchReady` parameters task `05` tests expect. On
   `ChallengeEntryMatchReady` the app attaches the match to the battle
   runtime (or calls an injected `onMatchReady`), so the link landing reaches
   preparation without a second link implementation.
5. `app/lib/battle/runtime/battle_runtime.dart` — `BattleRuntime.fromConfig`
   composes the production adapters and takes an optional
   `accessTokenProvider` (task `06`), `shareService` (task `09`/`05`) and
   `challengeEntry` (task `05`).

## How other tasks plug in

| Task | Seam | Provided adapter |
| --- | --- | --- |
| `03` camera | `BattleCamera` | `CameraSessionBattleCamera` (`battle/data/camera_session_bridge.dart`) consumes `CameraSession.platform`; `CameraPreview` is embedded in preparation and live. |
| `04` backend | `BattleBackend` | `HttpBattleBackend` (`battle/data/http_battle_backend.dart`) implements the `{action,params}` envelope and parses `docs/API.md` objects (including `tracking`, `practice_complete`, `queued_since`, `expires_at`). |
| `05` links | `BattleChallengeEntryDelegate`, `ChallengeEntryMatchReady` handoff | `ChallengeEntryDelegate` + `ArenaApp` wiring; `Join with code` resolves through `ChallengeEntryController.openCode`. |
| `06` account | `ValueListenable<ArenaProfile?>`, `BattleAccessTokenProvider` | `BattleRuntime.setViewer`; `ArenaApp` can pass a real token provider. Until then the HTTP backend fails closed as unauthenticated. |
| `08` matchmaking | queue UI + `queue_join/queue_poll/queue_leave` | The 15 s/60 s windows, cancel-on-switch and "nobody is promised online" copy are in `BattleController`/Battle tab; task `08` only replaces the backend behavior. |
| `09` sharing | `BattleChallengeSharer` | `ChallengeShareServiceSharer` over task `05`'s share service; result receipts are passed as facts, never replayed. |
| `10` QA | routes/states | The state list above maps to the task-01 screenshot matrix; `ARENA_FEATURE_PREVIEW_FIXTURES=true` renders every screen with invented, labelled data. |

## Preview fixtures

`BattleRuntime.preview()` / `ARENA_FEATURE_PREVIEW_FIXTURES=true` uses
`FixtureBattleBackend` and `FixtureBattleCamera`:

- every screen shows the persistent `Preview fixtures` banner;
- `queueJoin`, `ready` and `reportRep` fail with a labelled conflict, so a
  fixture session can never produce a ranked or casual receipt;
- only the practice rep and the labelled fixture data are simulated.

## Evidence

From `app/` (Flutter 3.24.5 / Dart 3.5.4):

- `flutter analyze` — `No issues found!`
- `flutter test` — 186 tests passed, including the task-03 camera and task-05
  linking suites; the battle suite is `test/battle/` (state machine,
  controller, contract, widget) with `test/support/` doubles.
- The suite covers every transition, back/leave behavior, request
  acceptance, the both-ready gate, tracking loss, the ten-second recovery
  window, shared outage, duplicate polling/rep idempotency, receipt-only
  results, the challenge sign-in return, the link-landing handoff, the
  fixture label/receipt block and the reduced-motion switch.

## Unresolved risks / open items

1. No debug APK build was run in this task (the machine's system drive had
   under 0.5 GB free); compilation is proven by `flutter analyze` and the
   test compiler only. Task `10` owns device builds.
2. Task `06` has not landed, so production defaults have no viewer or access
   token: the Battle tab renders the honest signed-out/unauthenticated
   states until the account task injects them. No fake sign-in was added.
3. The real Supabase project values (D3) and the real HTTPS link host (D1)
   are still open; the HTTP adapter and link wiring already read
   `ArenaConfig`, so no code change is needed when they land.
4. `SharedPreferencesBattleSessionStore` is wired for the active match id;
   restoring into a live round re-prepares the camera session on resume.
   Device-level process-death QA remains task `10` evidence.
