# Interface note 06 — sign-in continuity, minimal profile and leaderboard

Date: 2026-09-18
Author: task `06` (account, profile, leaderboard)
Status: implemented; re-verified 2026-09-22 on the current tree: `flutter
analyze` clean for the account paths (and the whole app) and **154/154 account
tests pass** (`flutter test test/account`; full app suite 492/492). The
redirect/continuity paths now also have host tests from L06. Physical-device
items are listed under open items.

## Why this note exists

`docs/CONTRACT.md` section 8 requires shared changes to be recorded before
they land, and the task prompt asks for the auth redirect configuration the
release task must supply plus the interface notes the battle UI needs. This
note records the additive config key, the account seams other tasks consume,
one accessibility fix in a shared battle widget and the tests that prove the
acceptance checks.

`D:\Kiro` was not read or modified.

## What this task delivered

Owned paths: `app/lib/account/`, `app/test/account/` and this note.

- `account/auth/` — small `ArenaAuthGateway` interface (`restoreSession`,
  `signInWithGoogle`, `requestEmailCode`, `verifyEmailCode`, `refreshSession`,
  `signOut`), `MemoryAuthSessionStore`/`SharedPreferencesAuthSessionStore`
  (session + one in-flight PKCE verifier only) and the production
  `SupabaseAuthGateway` (GoTrue `/otp`, `/verify`, `/authorize` with PKCE
  `S256`, `token?grant_type=pkce`, `refresh_token`, `/logout`).
- `account/models/` — username/email/avatar rules mirrored from the backend,
  `AccountException` with actionable, address-free copy and the leaderboard /
  public-player view objects.
- `account/data/account_api.dart` — typed `AccountApi` over the documented
  `{action,params}` envelope for `profile`, `profile_update`, `avatar_update`,
  `avatar_remove`, `leaderboard`, `history`, `profile_public`, `report`,
  `block`, `unblock`, `blocked`, `delete_account`. Malformed rows are dropped;
  server messages containing an address or token are replaced by generic copy.
- `account/runtime/` — `AccountController` (session lifecycle, username claim,
  avatar updates, token provider), `LeaderboardController`,
  `BattleHistoryController` and `AccountRuntime`/`AccountRuntimeScope`.
- `account/challenge/` — `AccountChallengeAuthDelegate` over the task-05
  `ChallengeAuthDelegate` boundary; every prompt is a sign-in step and the
  pending token is never touched.
- `account/avatar/` — document-picker-only avatar picker (never the camera).
- `account/ui/` — Leaderboard tab, Profile tab, Edit profile, Battle history,
  Settings, public player card with Report/Block and the sign-in sheets.
- `test/account/` — fakes plus eight suites covering the acceptance checks
  below.

## Additive config key (owner: release task `11`)

| Key | Default | Meaning |
| --- | --- | --- |
| `ARENA_AUTH_REDIRECT_URL` | empty | Exact OAuth redirect registered with the auth provider and reached by the app (`ArenaConfig.authRedirectUrl`). Empty fails Google sign-in closed with plain copy. |

No existing key was renamed or repurposed.

## Auth redirect configuration expected from the release task

`SupabaseAuthGateway` matches the redirect on **scheme + host + path only**
(query and fragment are read for `code`/`error` and otherwise ignored):

1. Set `ARENA_AUTH_REDIRECT_URL` to the exact allowlisted URL. The release
   decision is **`trainingarena://challenge/auth`** (custom scheme, no App
   Links verification; `docs/release/CONFIGURATION.md` §6 and
   `docs/release/RELEASE_CHECKLIST.md` 4.1). An HTTPS form
   (`https://<real-link-host>/auth`) remains possible but needs verified App
   Links.
2. Add the same URL to the Supabase Auth **redirect allowlist**, enable the
   Google provider and upload the Google client credentials to Supabase.
   Google's own authorized redirect URI points at the Supabase callback
   (`https://<project>.supabase.co/auth/v1/callback`), not at the app.
3. Enable confirmed email-code sign-in and the SMTP template (the gateway posts
   `/auth/v1/otp` with `create_user: true`).
4. No new Android intent filter is required for the chosen value. The gateway
   matches scheme + host + path, and the existing task-05
   `trainingarena`/`challenge` filter already receives
   `trainingarena://challenge/auth` (its `host` match ignores the path); the
   earlier `trainingarena://auth` example would have needed a second filter.
   The HTTPS form needs either the same host with a new path prefix or a second
   filter. `flutter_deeplinking_enabled=false` and `app_links` delivery already
   work for the challenge filters and apply unchanged.
5. Keep the release signing fingerprint in `assetlinks.json` only if the HTTPS
   redirect form is chosen; the custom scheme needs no asset links.
6. End-to-end QA must cover: cold-start redirect resume (app killed during the
   browser round trip), warm resume, cancel, expired code and offline retry.
   The stored PKCE verifier (`arena.auth.pkce.v1`) is what makes cold resume
   work, and it is cleared on cancel, expiry and sign-out. L06 host tests cover
   the cold/warm resume through the real PKCE gateway; the hosted redirect
   round trip itself is still owner-gated (R3).

## Interface notes for the battle UI (task `07`)

1. **Viewer identity** — `AccountRuntime.viewer` is a
   `ValueNotifier<ArenaProfile?>`; `ArenaApp` forwards it through
   `BattleRuntime.setViewer`. Lime is the signed-in player; the battle runtime
   already renders the opponent violet. `AccountController.profile` updates are
   authoritative after `refreshProfile()`; never derive rating changes locally.
2. **Session** — `AccountRuntime.accessToken()` returns the bearer token or
   `null` when signed out/expired. `BattleRuntime.fromConfig` already receives
   it as the token provider; a `null` token means "show the sign-in entry
   point", not "retry with a fake token". Sign-in itself is owned by task `06`
   surfaces (`profile_tab.dart`, `sign_in_flow.dart`) and the challenge
   delegate; battle must not build a second auth flow.
3. **First sign-in** — `AccountController.usernameRequired` is `true` until the
   backend has a unique username. Battle and queue actions should stay blocked
   with plain copy (`Choose a username before battling.`); the server still
   answers `username_required`, and 401 answers end the local session with
   `Your sign-in expired. Sign in again to continue.`
4. **Confirmed results only** — `BattleHistoryController` renders exactly the
   `history` receipts. Rating context (`rating_after`, `rating_change`) is shown
   only when `mode == ranked`; casual and `no_result` receipts have null rating
   fields and must never show a delta. After a finished ranked match, call
   `AccountController.refreshProfile()` to refresh the ladder rating rather than
   applying an optimistic change.
5. **Failure copy** — branch on `AccountException.code`
   (`unauthenticated`/`unauthorized`, `expired`, `network`, `username_taken`,
   `username_invalid`, `username_required`, `blocked`, `avatar_invalid`,
   `avatar_too_large`, ...) and use `isRetryable` for retry affordances. The
   message is already plain, actionable and free of addresses/tokens.
6. **Moderation** — `blocked` is enforced server-side for future requests and
   ranked queue pairing; the client only needs to surface the blocked state and
   offer unblock through the task-06 Settings page.

## Shared change recorded (task `07` path)

`app/lib/battle/ui/battle_widgets.dart` — `BattleChip` now wraps its label in a
`Flexible` child. Without it, chips overflowed by 128–240 px at 200% text size
on the Profile tab, which fails the design-system reflow requirement. No token,
variant or wire value changed; battle widget tests pass unchanged.

## Acceptance checks and evidence

From `app/` (Flutter 3.47.5 / Dart 3.13.4), run with `flutter test test/account`
(154 tests; `flutter analyze` clean; the full app suite is 492/492). The
2026-09-18 run redirected temp to the build directory because the machine's
system drive was nearly full; the 2026-09-22 re-run did the same:

| Check | Where |
| --- | --- |
| Challenge sign-in returns to the same token (Google, email code, duplicate username, restart) | `test/account/challenge_continuity_test.dart` |
| Normalized, race-safe usernames with actionable client errors | `test/account/account_models_test.dart`, `account_controller_test.dart`, `account_api_test.dart` |
| Profile shows only the specified fields and reflows at 200% text | `test/account/profile_surfaces_test.dart` |
| Public profile/report/block have tests and expose no email, camera or token data | `test/account/profile_surfaces_test.dart`, `account_api_test.dart` |
| Leaderboard/rating/history come from confirmed receipts, never optimistic guesses | `test/account/leaderboard_history_controller_test.dart`, `profile_surfaces_test.dart` |
| Username changes update future displays but receipts keep the confirmed snapshot | `test/account/profile_surfaces_test.dart` |
| Cancellation, expiry, offline retry and sign-out copy | `test/account/account_controller_test.dart`, `supabase_auth_gateway_test.dart`, `account_api_test.dart` (socket and TLS failures both map to the retryable `network` copy) |

Also fixed while testing: `AccountController.deleteAccount` no longer clears
the local session when the server deletion fails; a retry keeps the signed-in
state.

## Open items

1. No physical-device pass was run by task `06` itself. L02/L03/L06 have since
   run emulator smokes (including the real Keystore store) and the account
   suites are part of the L08 459-test freeze; a physical device is still
   required for the OAuth return, the avatar document-picker round trip and the
   Keystore migration (L04/task `10`).
2. Real Supabase project values (D3) and the hosted auth redirect are still
   open; `AccountRuntime.fromConfig` falls back to `UnavailableArenaAuthGateway`
   and `UnavailableAvatarPicker`, so the shell stays usable and honest. The
   release redirect value is decided (`trainingarena://challenge/auth`); the
   hosted allowlist entry is not.
3. Task `09` (sharing) and task `08` (notifications) had unrelated compile
   errors in their own paths while this note was written; those paths now
   compile and the full suite passes, and the account suites never imported
   them.
4. Avatar upload was exercised through the picker boundary and image rules;
   the Android `AccountAvatarPlugin` document-picker round trip still needs
   device QA (task `10`).
