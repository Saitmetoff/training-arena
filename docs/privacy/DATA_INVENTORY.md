UNREVIEWED AI-GENERATED DRAFT - needs review by a qualified lawyer before publication

# Training Arena data inventory, retention and deletion

Prepared: 2026-09-20 · Branch: `codex/training-arena` · Starting commit: `1819ebf`
Status: **factual local packet complete; owner retention and identity decisions pending.**

Every row below cites the migration, table/column, RPC, Edge Function or app
code path it comes from. This document does not state a retention period that
the owner has not decided; those rows are marked **PENDING (owner)**. It does
not claim "no data is collected" because camera frames and pose landmarks are
processed on-device — exercise results, account data and product analytics are
collected and stored server-side and are described here.

Re-derive it from this tree with:

```powershell
# schema: tables, columns, constraints, RLS, immutability triggers
supabase/migrations/20260917143538_arena_initial.sql
# every RPC: what is written, read, returned and deleted
supabase/migrations/20260917143539_arena_rpc.sql
# HTTP surface, action registry, storage handling, account deletion
supabase/functions/arena/lib/app.ts
supabase/functions/arena/lib/actions.ts
supabase/functions/arena/lib/avatar.ts
# client-side collection (what the app sends and what it keeps on device)
app/lib/linking/challenge_analytics.dart
app/lib/battle/ports/battle_analytics.dart
app/lib/account/runtime/account_controller.dart
app/lib/camera/camera.dart
app/lib/camera/pose/pose_types.dart
```

## 1. Where data lives

| Store | Content | Citation |
| --- | --- | --- |
| Supabase Auth (`auth.users`, `auth.sessions`, `auth.identities`) | email address, provider identity, sessions, OTP attempts | Supabase platform tables; the app sends `POST /auth/v1/otp` and `/auth/v1/verify` (`app/lib/account/auth/supabase_auth_gateway.dart`) |
| `public.arena_*` tables | profile, links, requests, matches, rep events, queue, receipts, rating history, blocks, reports, devices, outbox, analytics | `supabase/migrations/20260917143538_arena_initial.sql` |
| Storage bucket `arena-avatars` (public) | optional avatar images under `avatars/<user_id>/...` | initial migration §"Avatar storage"; `supabase/functions/arena/lib/actions.ts` |
| Supabase service backups | full database backups on the hosting plan | platform behavior; retention **PENDING (owner)** (Supabase plan) |
| Edge Function logs | request/error logs; the served-function scan found no token, email or bearer value | `qa/launch/l05/serve_log_scan.txt`; `supabase/functions/arena/lib/app.ts` (`console.error` for failures only) |

RLS is enabled on every `arena_*` table with **no policies**, and `anon` /
`authenticated` hold no table, sequence or function grants; clients reach data
only through the `arena` Edge Function with the service role
(`20260917143538_arena_initial.sql` §RLS, `docs/API.md` §7).

## 2. Data categories

### 2.1 Account and auth

| Data | Where | Why | Retention | Deletion behavior |
| --- | --- | --- | --- | --- |
| Email address | `auth.users.email` (Supabase Auth) | sign-in with email one-time code; account identity | while the account exists; auth-provider policy for OTP records | `arena_delete_account` + `deps.auth.deleteUser` remove the auth user (`actions.ts` `deleteAccount`) |
| Session tokens, refresh token, one in-flight PKCE verifier | device only: Android Keystore-backed store (`arena.auth.session.v2`, `arena.auth.pkce.v2`), legacy v1 values migrated and removed | keep the user signed in across restarts | while signed in | cleared on logout, expiry and successful account deletion (`app/lib/account/auth/auth_store.dart`, `account_controller.dart`) |
| Google identity (provider id/token) | Supabase Auth | optional Google sign-in | while the account exists | removed with the auth user; Google sign-in is out of pilot scope until R3 closes |
| Username, username_normalized | `arena_profiles.username`, generated `username_normalized` | unique public handle, leaderboard identity | while the account exists | profile row is deleted by the `on delete cascade` from `auth.users`; receipts keep the frozen snapshot |
| Rating, ranked_wins, ranked_battles | `arena_profiles` | leaderboard and Elo | while the account exists | removed with the profile row |
| deleted_at marker | `arena_profiles.deleted_at` | transient marker used by the deletion RPC before the auth user is removed | removed with the profile row (auth deletion cascades) | n/a |
| Avatar image + `avatar_url`, `avatar_path` | public bucket `arena-avatars`, `arena_profiles` columns | optional public profile content (D5: optional and deferrable) | while the account exists | Edge Function removes the stored object(s), then deletes the auth user (`actions.ts` `deleteAccount`, `removeQuietly`). If storage removal fails it is logged without any token and the deletion still proceeds; the orphan object would need manual cleanup. |

### 2.2 Challenge links, requests and matches

| Data | Where | Why | Retention | Deletion behavior |
| --- | --- | --- | --- | --- |
| Challenge link token | `arena_links.token` (12 chars, not guessable) | durable personal challenge link | until rotated or the account is deleted | revoked on deletion (`arena_delete_account`) |
| Requests: sender, recipient, status, created/expires/responded, match id | `arena_requests` | invitation lifecycle | 24 h to answer; rows are kept afterwards | pending requests are cancelled/settled on deletion; historic rows remain until the counterpart is deleted (they reference both users and cascade on either side's auth deletion) |
| Match clock, mode, exercise, origin, status, closed_reason | `arena_matches` | authoritative match session | **PENDING (owner)** | retained; has no user foreign key, so it survives account deletion and keeps the counterpart's record intact |
| Per-player score, ready/practice/tracking flags, presence timestamps, username/avatar snapshot | `arena_match_players` | live match state; snapshot keeps a match readable after a profile change | **PENDING (owner)** | the deleted player's rows cascade from `auth.users`; the counterpart's rows and the match remain |
| Camera rep events: `event_id`, `sequence`, `observed_at`, `received_at`, `counter_version` | `arena_match_events` | idempotent, ordered, immutable count of accepted reps | **PENDING (owner)**; immutable by trigger `arena_match_events_immutable` | the deleted player's events cascade; the counterpart's events stay |
| Queue seat | `arena_queue` | ranked waiting seat, 60 s expiry | short-lived | cancelled on deletion; expired by the maintenance worker (`arena_maintenance`) |

`arena_match_events` never contains frames, landmarks or derived pose data —
only the counters listed above (`supabase/functions/arena/lib/actions.ts`
`rep` action; `app/lib/camera/camera.dart`).

### 2.3 Results, rating and moderation

| Data | Where | Why | Retention | Deletion behavior |
| --- | --- | --- | --- | --- |
| Receipt: exercise, mode, outcome, winner id, frozen `players` jsonb (id, username, avatar url, score, rating change), finished_at, reason | `arena_receipts` | immutable confirmed result; history and sharing | **PENDING (owner)**; immutable by trigger | retained for the counterpart when one account is deleted. The frozen snapshot can still contain the deleted player's username and avatar URL |
| Rating audit: rating_before/after/change | `arena_rating_history` | exactly-once Elo record | **PENDING (owner)**; immutable by trigger | `user_id` is `on delete set null`, so the row survives without the deleted user's id and the counterpart's audit is preserved |
| Blocks (blocker, blocked) | `arena_blocks` | mutual exclusion for requests and ranked pairing | while either account exists | cascades for both sides |
| Reports (reporter, target, match, reason) | `arena_reports` | manual moderation; never automated enforcement | **PENDING (owner)** | cascades with either account, which means reports about a deleted account are removed with it |

### 2.4 Optional push (pilot ships no push)

| Data | Where | Why | Retention | Deletion behavior |
| --- | --- | --- | --- | --- |
| FCM device token, platform, timestamps | `arena_devices` | native push routing; the client registers a token only when `ARENA_FEATURE_PUSH_NOTIFICATIONS=true` | superseded tokens are deleted so at most 10 newest are kept per user | all rows for the user are deleted by `arena_delete_account` |
| Notification outbox: user, kind, payload (ids and usernames only), attempts, lease, last_error | `arena_notification_outbox` | transactional outbox for best-effort delivery; inbox is authoritative | **PENDING (owner)** | cascades with the account |

### 2.5 Product analytics

| Data | Where | Why | Retention | Deletion behavior |
| --- | --- | --- | --- | --- |
| `arena_analytics_events`: user id, event name, capped jsonb properties (≤8 KB), timestamp | `arena_analytics_events` | product metrics (funnel, matchmaking health) | **PENDING (owner)** | `user_id` is `on delete set null`; the event rows remain without the user id. The RPC accepts no camera data and rejects unknown shapes |

Events currently sent by the client:
`challenge_link_opened`, `challenge_sign_in_completed`,
`challenge_request_sent`, `challenge_request_accepted`,
`challenge_share_sheet_opened`, `challenge_install_cta_tapped`
(`app/lib/linking/challenge_analytics.dart`) and
`matchmaking_search_started`, `matchmaking_match_found`,
`matchmaking_search_cancelled`, `matchmaking_search_timed_out`,
`matchmaking_friend_alternative` (`app/lib/battle/ports/battle_analytics.dart`).
Properties are limited to source labels, auth method name, mode, cancel reason,
elapsed seconds and the offered/switched action; they carry no email, token or
camera value. `arena` / `arena-dispatcher` logs and the share exports were
audited for tokens, emails and frames (`docs/release/CONFIGURATION.md` §7,
`qa/launch/l05/serve_log_scan.txt`).

## 3. Camera frames and pose landmarks: on-device only

- The Android layer captures with CameraX and analyses frames with the on-device
  ML Kit Pose Detection analyzer; only landmark numbers cross to Dart over the
  `trainingarena/pose` event channel (`app/lib/camera/bridge/camera_bridge.dart`,
  `app/android/.../camera/PoseAnalyzer.kt`, `ArenaCameraController.kt`).
- Frames are processed in memory and dropped; nothing is written to disk,
  encoded or uploaded (`app/lib/camera/camera.dart`,
  `app/lib/camera/pose/pose_types.dart`).
- **One debug-only exception, off in every release build.** When
  `ARENA_FEATURE_CAMERA_TRACE` is compiled in (`false` by default, pinned
  `false` by the release-hold check), the camera card can write the last three
  minutes of landmark **numbers** to an app-private text file under
  `<documents>/camera-traces/` when the owner taps Export, and shares that
  file only through the OS share sheet they opened. It contains timestamps,
  coordinates and likelihoods, plus an exercise name and the in-app rep count;
  no frame, image, device identifier or account value. The owner can delete
  every exported file from the same control (`app/lib/camera/trace/`,
  `app/lib/camera/camera_preview.dart`).
- The Edge Function has no endpoint that accepts an image, frame or landmark:
  `POST /functions/v1/arena` accepts only the documented actions
  (`supabase/functions/arena/lib/actions.ts`), the only image upload is the
  optional avatar (`avatar_update`), and `GET` resolves a link token only
  (`app.ts`).
- **This does not mean "no data is collected".** Rep counts, match results,
  account data and analytics described above are collected and stored.

One third-party SDK consideration: the bundled `com.google.mlkit:pose-detection`
SDK processes input data on-device and does not send input data or outputs to
Google, but per the ML Kit terms it contacts Google servers for model/hardware
configuration and sends operational metrics (device/app identification,
configuration, event types, error codes, performance metrics, per-installation
identifiers, IP addresses). The privacy policy discloses this, and the pilot
build ships with `ARENA_FEATURE_CAMERA_COUNTING=false`, so the camera flow is
not reachable in the pilot artifact even though the SDK is packaged
(terms: https://developers.google.com/ml-kit/terms, retrieved 2026-09-20).

## 4. On-device records

| Record | Key | Content | Cleared |
| --- | --- | --- | --- |
| Pending challenge | `arena.pending_challenge.v1` (SharedPreferences) | challenge token, source, sender snapshot | on completion, cancel, or sign-in restart of the flow (`app/lib/linking/challenge_persistence.dart`) |
| Install referrer handled flag | `arena.install_referrer.v1` | boolean, avoids a second recovery attempt | not sensitive; stays on the device |
| Session + PKCE verifier | `arena.auth.session.v2` / `arena.auth.pkce.v2` (Keystore-backed) | tokens | logout, expiry, account deletion |
| Exported landmark trace (debug only) | `<app documents>/camera-traces/trace-<exercise>-<timestamp>.txt` | the last three minutes of landmark numbers and the in-app rep count at export; written only when `ARENA_FEATURE_CAMERA_TRACE` is on and the owner taps Export | the Delete control on the camera card clears the directory; nothing is written without an export tap |

Android cloud backup and device-to-device transfer are disabled
(`android:allowBackup="false"` plus explicit backup/data-extraction rule files),
so none of this is eligible for cloud backup.

## 5. Retention summary and pending owner decisions

| Record | Default behavior in code | Owner decision |
| --- | --- | --- |
| Auth account | while the account exists | — |
| Profile, links, devices, pending requests | until deletion | — |
| Match rows, match_players, match_events, queue | retained indefinitely today (no sweep deletes them) | **PENDING** — period for match/rep history |
| Receipts, rating history | retained indefinitely, immutable | **PENDING** — period; must state the counterpart-retention reason |
| Moderation reports | retained until either account is deleted | **PENDING** — moderation/abuse retention |
| Analytics events | retained indefinitely today | **PENDING** — telemetry retention |
| Notification outbox | retained after delivery today | **PENDING** (only relevant if push is enabled) |
| Supabase service backups | managed by the hosting plan | **PENDING** — plan and backup window; deletion is not retroactive in existing backups |
| Edge Function logs | platform log retention | **PENDING** — hosted log retention |

`arena_maintenance` (`20260917143539_arena_rpc.sql`) expires requests and queue
seats and ticks active matches; it does **not** delete historic rows. No other
scheduled purge exists in this tree.

## 6. Deletion behavior (verified)

In-app path: Settings → **Delete account** → confirmation dialog →
`AccountController.deleteAccount()` → `POST {action: "delete_account"}`
(`app/lib/account/ui/settings_page.dart`, `actions.ts` `deleteAccount`).

Server behavior (`arena_delete_account` RPC, `actions.ts`, verified by
`supabase/functions/arena/tests/app_test.ts` "delete_account removes storage,
deletes the auth user and stays idempotent" and `supabase/tests`):
1. verifies the actor's session (`auth.sessions`), not just the token;
2. closes every active match as `no_result` / `account_deleted`;
3. revokes the challenge link, cancels the queue seat, settles pending requests;
4. deletes push device tokens;
5. marks `deleted_at` and returns the avatar path(s);
6. the Edge Function removes the stored avatar object(s) and deletes the auth
   user, which cascades the profile, links, requests, match-player rows, rep
   events, blocks and reports for that user;
7. the client clears the Keystore session on success; a failed deletion keeps
   the session so the retry works (`account_controller.dart`).

Retained for the counterpart after a deletion: match rows, the counterpart's
player rows and rep events, the immutable receipt (including the frozen
username/avatar snapshot of the deleted player), and the rating-history rows
with the deleted user's id set to null. Analytics events keep history without
the user id. This retention is the reason the privacy policy must not promise
"everything is erased"; the owner must supply the retention periods and the
lawful basis text before publication.

Retry safety: a second `delete_account` call before the auth user is removed
returns `{ok, already_deleted: true}` with the stored avatar paths; after the
auth user is removed the session is gone, so the operation reports a plain
expired/unauthorized state instead of a partial success.

External path: the public deletion-request page in `challenge-web/`
(`delete-account.html`, `delete_account.js`) verifies ownership with the same
email one-time-code flow (`POST /auth/v1/otp` with `create_user:false`, then
`POST /auth/v1/verify`) and calls the same `delete_account` action with the
resulting session. It keeps the session in memory only, has no cookies, no
local storage and no analytics, and never logs the code or token.

## 7. What this inventory does not claim

- No retention period is invented; every undecided value is **PENDING (owner)**.
- No legal basis, jurisdiction or regulatory statement is made here; the public
  policy must be completed with the owner's legal entity, address and contacts.
- Camera accuracy, health claims and medical claims are out of scope; the only
  camera claim is where frames are processed (on-device, never uploaded).
