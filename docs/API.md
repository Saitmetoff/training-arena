# Training Arena API

Status: reconciled by task `04` on 2026-09-18 against
`supabase/migrations/20260917143538_arena_initial.sql`,
`..._arena_rpc.sql` and `supabase/functions/arena`. The additive response
keys are recorded in `docs/decisions/03-arena-backend-interface-decisions.md`.

Local implementation; no hosted backend has been configured or deployed.

- `POST /functions/v1/arena` — authenticated `{action,params}` request,
  `{data:...}` or `{error:{code,message}}` reply. Every POST requires
  `Authorization: Bearer <Supabase user access token>`.
- `GET /functions/v1/arena?token=<challenge token>` — anonymous, read-only
  link resolution. It never creates a profile, request, queue seat or match.

All JSON uses `snake_case`. Actions, object keys and wire values are frozen;
additions require a `docs/decisions/` note.

## 1. Envelopes and HTTP status

```json
// success
{"data": {"profile": {...}}}

// business failure
{"error": {"code": "link_not_found", "message": "challenge link is not available"}}
```

| HTTP | Meaning |
| --- | --- |
| 200 | Success or a business `{error}` envelope (read `error.code`) |
| 401 | Missing/invalid bearer token, or the RPC rejected the session |
| 405 | Wrong method (`GET`/`POST`/`OPTIONS` only) |
| 500 | Unexpected server fault (`internal_error`); details stay in server logs |

The platform JWT check is disabled so the anonymous GET can resolve links.
Every POST verifies the token with Supabase Auth, takes `sub` and
`session_id` from the verified JWT, and the RPC re-checks that the session is
still active. No request body field is ever used as a user id.

## 2. Objects

- **Profile**: `{id,username,avatar_url,rating,ranked_wins,ranked_battles}`.
  Avatar nullable; username null until chosen. Auth email and notification
  tokens are never returned here.
- **Link**: `{token,code}` — token and code are the same random 12-character
  lowercase identifier (input is case-insensitive). The client builds its
  configured HTTPS `/c/<token>` URL. Rotation invalidates the previous token;
  a link stays valid until rotated, revoked or the account is deleted.
- **Request**: `{id,sender:Profile,recipient:Profile,status,created_at,expires_at,match_id}`.
  Status `pending|accepted|declined|cancelled|expired`; requests last 24 hours.
- **Match**: `{id,exercise,mode,status,players,starts_at,ends_at,server_now,receipt}`.
  `exercise` is `pushups|squats` and is selected by the server when the match
  is created. `mode` is `casual|ranked`. `status` is
  `preparing|countdown|live|finished|no_result`. `receipt` is null until the
  match closes.
- **Match player**: `{id,username,avatar_url,score,ready,last_seen,tracking,practice_complete,left}`.
  `tracking`, `practice_complete` and `left` are additive; the documented keys
  are unchanged.
- **Receipt**: `{id,match_id,exercise,mode,players,winner_id,outcome,finished_at,reason}`.
  Outcome `win|draw|no_result`. Players are immutable snapshots:
  `{id,username,avatar_url,score,rating_after,rating_change}`.
  `rating_after`/`rating_change` are null for casual and no-result matches.
- **Queue state**: `{match,queued,queued_since,expires_at}`. `queued` is
  additive; the seat lives 60 seconds.

Fake example (never a production id):

```json
{"id":"11111111-1111-4111-8111-111111111111","username":"arena_demo",
 "avatar_url":null,"rating":1016,"ranked_wins":1,"ranked_battles":1}
```

## 3. Actions

| Action | Parameters | Data |
| --- | --- | --- |
| `profile` | none | `{profile,link,active_match_id}` |
| `profile_update` | `username` | `{profile}` |
| `avatar_update` | `base64,mime_type` (JPEG/PNG/WebP, max 2 MiB) | `{profile}` |
| `avatar_remove` | none | `{profile}` |
| `resolve_link` | `token` | `{owner,available}` |
| `inbox` | none | `{requests,active_match_id,link}` |
| `request_send` | `token` | `{request}` |
| `request_rematch` | `match_id` (finished match the caller participated in) | `{request}` |
| `request_accept` | `request_id` | `{match}` |
| `request_respond` | `request_id,response` (`decline`/`cancel`) | `{request}` |
| `queue_join` | none | `{match,queued,queued_since,expires_at}` |
| `queue_poll` | none | `{match,queued,queued_since,expires_at}` |
| `queue_leave` | none | `{ok:true}` |
| `match_state` | `match_id` | `{match}` |
| `ready` | `match_id,tracking,practice_complete` | `{match}` |
| `heartbeat` | `match_id,tracking` | `{match}` |
| `rep` | `match_id,event_id,sequence,observed_at,counter_version` | `{match}` |
| `leave` | `match_id` | `{match}` |
| `leaderboard` | none | `{profiles}` (top 100 by rating, plus own row if outside) |
| `history` | none | `{receipts}` (newest 100, own matches only) |
| `profile_public` | `user_id` | `{profile}` |
| `link_rotate` | none | `{link}` |
| `report` | `target_user_id,match_id?,reason` (3–500 chars) | `{ok:true}` |
| `block` | `target_user_id` | `{ok:true}` |
| `unblock` | `target_user_id` | `{ok:true}` |
| `blocked` | none | `{profiles}` |
| `device_register` | `token,platform?` (`android`/`ios`) | `{ok:true}` |
| `delete_account` | none | `{ok:true}` |
| `analytics` | `event,properties` | `{ok:true}` |

Unknown parameters are rejected with `invalid_request`. Profile/inbox/queue/
match polling is authoritative. Use ~1 s match heartbeats while foregrounded,
3–5 s inbox polling, and stop on exit.

`request_rematch` is authenticated and accepts only a UUID `match_id`. The
server verifies participation in a finished match, then applies the existing
request rules for deleted accounts, blocks, busy players and expiry. Pending
requests in either direction are recovered under a pair lock, so repeated or
simultaneous rematch taps do not create another request. Acceptance creates a
fresh casual match with zero scores and both players unready; practice and
readiness must be completed again. The original receipt and scores are
immutable. This additive interface is approved in decision 12 (2026-09-30)
and pinned by the rematch pgTAP, HTTP smoke and client regressions.

The client shows pending/accepted/preparing/ready only from server responses.
An opened share sheet or landing link cannot establish that an opponent viewed
an invitation. A receipt confirms the recorded outcome, not physical form.

### Examples (fake ids)

```json
// POST profile
{"action":"profile","params":{}}
// -> {"data":{"profile":{"id":"11111111-1111-4111-8111-111111111111",
//     "username":"arena_demo","avatar_url":null,"rating":1000,
//     "ranked_wins":0,"ranked_battles":0},
//     "link":{"token":"arena0demo12","code":"arena0demo12"},
//     "active_match_id":null}}

// POST request_send
{"action":"request_send","params":{"token":"arena0demo12"}}
// -> {"data":{"request":{"id":"44444444-4444-4444-8444-444444444444",
//     "sender":{...},"recipient":{...},"status":"pending",
//     "created_at":"2026-09-18T12:00:00+00:00",
//     "expires_at":"2026-09-19T12:00:00+00:00","match_id":null}}}

// POST rep (only while the match is live)
{"action":"rep","params":{"match_id":"33333333-3333-4333-8333-333333333333",
  "event_id":"55555555-5555-4555-8555-555555555555","sequence":7,
  "observed_at":"2026-09-18T12:00:42.123Z","counter_version":"1.0.0"}}
```

## 4. State machines

Challenge link (durable):

```text
active --rotate--> old token revoked, new active token
active --revoke/account deleted--> inactive (GET reports available:false)
inactive --request_send--> error link_not_found (read-only failure)
```

Challenge request (24 h):

```text
pending --accept--> accepted (match created, casual)
pending --recipient decline--> declined
pending --sender cancel--> cancelled
pending --expires_at passed--> expired (applied by inbox/maintenance)
```

Match:

```text
request accepted / queue paired
        |
        v
   preparing (10 min deadline) --both ready & tracking--> countdown (5 s)
        |                                                     |
        | prep timeout / leave / account deleted               | server clock
        v                                                     v
     no_result <--- both absent >10 s (service_outage) --- live (60 s)
        ^                                                     |
        |                         one absent >10 s or leave    | round ends
        +----------------------------------------------- finished (win)
                                                              |
                                                       score compare
                                                       win / draw
```

Ranked Elo: start 1000, K=32, draws included. Only a completed ranked result
(win/draw/forfeit) changes rating; casual matches and `no_result` never do.
The close transaction writes the receipt, both rating rows
(`arena_rating_history`, unique per match and player) and both profiles at
most once.

## 5. Match rules enforced by the server

- Server time drives the 5-second countdown and 60-second round
  (`starts_at`, `ends_at`, `server_now`). Client `observed_at` is checked
  against that window and is never the round clock.
- Rep events require `event_id` (idempotent), a strictly increasing
  `sequence`, `observed_at` and `counter_version`. A retried `event_id`
  returns the match without double-counting; a new event that is not
  increasing fails `rep_rejected`.
- Events are accepted only while `live`, only with fresh tracking (heartbeat
  within ~5 s), and are rate limited (~150 ms minimum spacing, hard cap 240
  per round).
- Tracking loss clears readiness during countdown (back to `preparing`) and
  pauses only that player's counting during live play. It does not forfeit
  by itself.
- One player absent for more than 10 seconds forfeits (opponent wins, reason
  `opponent_absent`). Both absent yields `no_result`
  (`service_outage`) and no rating change. The same conservative
  reconciliation applies after a backend outage.
- Abandoned preparation expires after 10 minutes (`prep_timeout`,
  `no_result`). Leaving during preparation is also `no_result`; leaving during
  countdown/live forfeits to the opponent.
- Only push-ups (`pushups`) and squats (`squats`) exist; the server selects
  the exercise. No bots, async score challenges, manual score entry, chat or
  followers.

## 6. Error catalogue

`message` is human-readable; branch on `code`.

| Code | Raised when | Typical fix |
| --- | --- | --- |
| `invalid_request` | malformed envelope/params, bad report reason, bad analytics | fix the client payload |
| `unauthorized` | missing/invalid token, revoked or expired session, deleted account | re-authenticate |
| `not_found` | unknown id, non-participant, hidden/blocked profile, own public profile | refresh state |
| `username_taken` | normalized username collision | pick another |
| `username_invalid` | shape/reserved-name rule | pick another |
| `link_not_found` | unknown/revoked/owner-deleted link, dead challenge | ask for a new link |
| `request_closed` | request is no longer pending | refresh inbox |
| `request_expired` | 24 h elapsed; expiry applied lazily on next inbox/maintenance | refresh inbox |
| `request_exists` | duplicate pending request to the same recipient | wait or cancel |
| `blocked` | either side blocked the other | unblock or stop |
| `busy` | own or peer active match, second queue seat | finish the current battle |
| `match_not_ready` | reserved for readiness conflicts | refresh match |
| `match_closed` | action on a closed match that is not retry-safe | refresh match |
| `match_not_live` | rep outside live play | wait for countdown/live |
| `rep_rejected` | stale/duplicate-with-new-id sequence or out-of-window event | do not retry |
| `tracking_stale` | rep without a fresh tracking heartbeat | resume tracking |
| `rate_limited` | reps too fast or above the round cap | do not retry |
| `avatar_invalid` | mime/signature mismatch, not base64, empty | re-encode JPEG/PNG/WebP |
| `avatar_too_large` | decoded avatar over 2 MiB | downscale |
| `username_required` | challenge/queue before choosing a username | choose a username |
| `forbidden` | reserved for future moderation rules | — |
| `invalid_action` | unknown action name | fix the client |
| `payload_too_large` | body/properties over the limit | shrink the payload |
| `conflict` | token/row race that could not be resolved | retry once |
| `internal_error` | unexpected fault, including immutable-row triggers | report with a request id |

An expired `request_accept`/`request_respond` returns `request_expired`
without persisting the `expired` status in the same transaction; `inbox` and
the maintenance worker apply it. Expired/revoked links only ever produce
read-only failures: the anonymous GET reports `{owner:null,available:false}`
and POST actions fail with `link_not_found`.

## 7. Security and data model

The tracking flag is client-reported and the server cannot verify that reps were really performed.

WP2 candidate limits: each player/round accepts at most 10 reps in a rolling 5-second server-receipt window, retaining the 150 ms gap and 240 round cap. Counter versions must be exact semantic versions in `arena_counter_versions`; the new client sends `1.3.0`. The actual legacy `arena-counter/1.2.1` is inventoried but fails the strict semantic-version gate. This compatibility conflict needs an owner rollout decision before deployment. Analytics accepts at most 120 events per user in a rolling hour; excess returns `rate_limited` (AR017). Avatar headers must yield positive dimensions no larger than 1024 by 1024, retaining the 2 MiB byte cap. These changes require local database and Deno verification before deployment.

- Only `public.arena_*` tables and types exist in this project; no FitBattle
  object, bucket, function or credential is reused.
- RLS is enabled on every arena table with **no policies**, and `anon`/
  `authenticated` have every table, sequence and function grant revoked.
  Clients reach data exclusively through the Edge Function with the service
  role; service-role access stays in server-only code.
- Immutable by trigger: receipts, rating history and rep events. Receipts are
  unique per match; rating history is unique per match and player.
- Constraints enforce unique normalized usernames, 24 h request expiry, no
  overlapping accepted battles (one active match per user), one active queue
  seat per user and one receipt per match.
- Public link resolution exposes only `{owner,available}` where owner is the
  public Profile. Avatars are deliberate public profile content stored in the
  public `arena-avatars` bucket under `avatars/<user_id>/...`; only the
  service role writes. Camera frames are never accepted by this API.
- `delete_account` revokes links, cancels queue seats, closes active matches
  as `no_result`, resolves pending requests, then the Edge Function deletes
  stored avatars and the auth user. It is retry-safe.

## 8. Deployment requirements

Configure a separate Supabase project, Google provider, confirmed email-code
sign-in and SMTP template, correct Auth redirect allowlist, public HTTPS
challenge domain, Android App Links certificate, Firebase FCM service account,
dispatcher secret and recurring worker. Do not reuse credentials from the
previous application. Set `ARENA_ALLOWED_ORIGINS`, `ARENA_PUBLIC_URL`, and
server-only secrets in functions. `arena` has platform JWT checks disabled
solely to allow anonymous GET; every POST validates with Auth and checks its
active session in the RPC. Only the service role can execute RPCs or access
tables. Public avatars are intentional profile content, not camera uploads.

Notification delivery is an outbox with lease/retry; the
`arena-dispatcher` worker endpoint uses its own bearer secret
(`ARENA_DISPATCHER_SECRET`), never an app token. Platform delivery is best
effort; inbox requests remain authoritative if permission or delivery fails.
Live device/Play/FCM integration and load testing are required before release;
local tests are not evidence of production readiness.
