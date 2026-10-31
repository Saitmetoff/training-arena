# 05 — challenge link and install recovery interface decisions

Date: 2026-09-18
Task: `05_CHALLENGE_LINK_AND_INSTALL`
Status: accepted; implemented by task `05`. Recorded because the task resolves
open decision D2, adds one additive config key and fixes client-visible names
that later tasks consume.

## Context

Task `05` owns `challenge-web/`, `app/lib/linking/` and the Android link
manifest/config. `docs/API.md` fixes the wire protocol (token shape,
`resolve_link`, request/match lifecycle) and task `04` owns the server
implementation. This note only records client-side names and platform
configuration that other tasks must agree on; it does not change
`docs/API.md` object shapes or the `/c/<token>` path.

## D1 — HTTPS link host

- Still `example.invalid` everywhere: Dart (`ARENA_LINK_HOST`), the Android
  manifest placeholder (`arenaLinkHost`) and `challenge-web/config.js`.
- The manifest carries a real `android:autoVerify="true"` App Links filter, but
  `example.invalid` can never host `assetlinks.json`, so verification is
  explicitly documented as pending. The build must not claim otherwise.
- Supplying the real domain means updating the Dart flag, the Gradle property
  and the web config; no code change is required.

## D2 — custom URL scheme (resolved)

- Scheme: `trainingarena`.
- Challenge form: `trainingarena://challenge/<token>`.
- The scheme is a local fallback for shortcuts/QR/install round trips only;
  shared messages always use `https://<host>/c/<token>`.
- The scheme is declared in the manifest with `host="challenge"` and never
  reuses a legacy identifier.

## Additive config key

| Key | Default | Meaning | Owner |
| --- | --- | --- | --- |
| `ARENA_PLAY_STORE_URL` | `https://play.google.com/store/apps/details?id=app.trainingarena.mobile` | supported Play install/update route shown by the web landing page and the in-app install-recovery page | `05` |

`ArenaConfig.playStoreUrl` and `ArenaConfig.installReferrerUrl(token)` (adds
`referrer=challenge%3D<token>`) are additive; no existing key is renamed.

## Android link configuration

- The App Links filter uses the Gradle manifest placeholder
  `${arenaLinkHost}`, resolved from the Gradle property `arenaLinkHost`
  (default `example.invalid`). `ARENA_LINK_HOST` (Dart) and `arenaLinkHost`
  (Gradle) must be set together for a real domain.
- `flutter_deeplinking_enabled=false` is declared on `MainActivity` because
  `app_links` receives the intent itself; the Flutter default deep-link
  router would otherwise fail to resolve a route.
- `app_links` is pinned to `6.1.3`: 6.4.x references
  `flutter.compileSdkVersion` inside its own Gradle script, which the pinned
  Flutter 3.24.5 Gradle plugin does not provide.
- `assetlinks.json` must be served at
  `https://<host>/.well-known/assetlinks.json` with relation
  `delegate_permission/common.handle_all_urls`, package
  `app.trainingarena.mobile` and the release SHA-256 fingerprint. The template
  and instructions live in `challenge-web/`.

## Install recovery

- The web landing page's Play button carries
  `referrer=challenge%3D<token>`; the app reads it through the Play Install
  Referrer library and treats `challenge=<token>`/`token=<token>` as a pending
  challenge exactly once. The consumed marker is persisted so a later launch
  does not reopen an already handled referrer.
- Install Referrer data is best effort; if it is missing, the user reopens the
  link (App Links) or types the readable code under Join with code.

## Client state mapping (no `docs/API.md` shape change)

`resolve_link` keeps `{owner, available}`. Richer states come from the
documented error envelope `{error:{code,message}}` and are mapped client-side:

| State | Signal |
| --- | --- |
| `available` | `available=true` |
| `revoked` / `unavailable` | `available=false`, `link_revoked`/`link_unavailable`/`owner_deleted`/`not_found` |
| `busyPlayer` | `player_busy` on resolve or send |
| `blocked` | `blocked` / `blocked_peer` |
| `expired` | `request_expired` or a stored request past `expires_at` |
| `completed` | `challenge_completed` / `match_completed` |
| `owner_offline` | `challenger_offline`; the landing offers **Send live challenge** and never promises replay |

Unknown codes fall back to the generic unavailable state with the server
message; the client never invents an outcome and never creates a local match.

## Analytics event names

Recorded through the documented `analytics` action (best effort):

| Event | Properties | Notes |
| --- | --- | --- |
| `challenge_link_opened` | `source` (`https`, `scheme`, `install_referrer`), `installed` | fired by the app only |
| `challenge_sign_in_completed` | `method` (`google`, `email`), `pending_challenge` | after a real sign-in delegate returns |
| `challenge_request_sent` | `source` (`link`, `reopen`) | only after the API confirms the request |
| `challenge_request_accepted` | `source` (`poll`, `return`) | when an accepted request surfaces as a match |
| `challenge_share_sheet_opened` | `source` (`battle`, `result`, `landing`) | not a referral |
| `challenge_install_cta_tapped` | `surface` (`web`, `app`) | no token leaves the device |

Opening a platform share sheet is never counted as a referral and no recipient
profile is created until a recipient sends a request.

## Persistence rule

Pending challenge context (token, resolved challenger, request id, expiry,
optional match id) is persisted across auth redirect, process restart and
install recovery. It is cleared only on explicit accept-into-match, explicit
decline/cancel, or an unrecoverable expiry; closing the landing keeps it.
