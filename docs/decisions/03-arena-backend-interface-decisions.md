# Interface note 03 — arena backend and security boundary

Date: 2026-09-18
Author: task `04` (authoritative Arena backend and security boundary)
Status: accepted; additive changes are already reflected in `docs/API.md`

This note records the decisions task `04` had to make while turning the
partial `docs/API.md` contract into a migration, RPCs and an Edge Function.
It exists because `docs/CONTRACT.md` section 8 requires a `docs/decisions/`
note before changing a contract symbol, and because the baseline already
contains object shapes that did not cover every behaviour the product rules
require.

## Decisions that do not change any existing key

1. **Namespace.** Every table is `public.arena_*`, every enum is
   `public.arena_*`. No FitBattle table, function, enum, bucket, secret or
   Edge Function is referenced or recreated. The project has its own
   `supabase/config.toml` (`project_id = "TrainingArena"`).
2. **Profiles are created server-side.** A trigger on `auth.users` inserts an
   `arena_profiles` row on sign-up (username null, rating 1000). Clients never
   insert profiles directly; RLS and revoked grants deny all direct writes.
3. **Exercise is server-selected.** `docs/CONTRACT.md` and task `07` say a
   match reveals one server-selected exercise (push-ups or squats) before
   camera setup, and `docs/API.md` has no exercise parameter on
   `request_send` or `queue_join`. The backend therefore chooses the exercise
   with `random()` when it creates the match. Personal challenges are always
   `casual`; only queue matches are `ranked`.
4. **HTTP status.** `POST` replies use the documented envelope. HTTP status is
   `200` for every business error envelope (the client reads `error.code`),
   `401` for a missing or invalid bearer token, `405` for a wrong method and
   `500` for an unexpected server fault. This keeps one response shape for all
   `{action,params}` traffic.
5. **Session check.** The Edge Function validates the bearer token with
   Supabase Auth and passes `sub` and `session_id` to the RPC. Each RPC checks
   `auth.sessions` for that session id so a revoked/expired session cannot act
   (`docs/API.md` deployment section already promises this).
6. **Link resolution.** `GET /functions/v1/arena?token=...` is anonymous and
   read-only. An unknown or revoked token resolves to
   `{data:{owner:null,available:false}}`; it never discloses whether a token
   ever existed. `request_send` with such a token fails `link_not_found`.
   `resolve_link` (POST) keeps the same shape for authenticated clients.
7. **Receipts.** `arena_receipts.match_id` is unique and receipt/rating rows
   are immutable by trigger. One RPC transaction closes the match, writes the
   receipt, updates both ratings for ranked results and records
   `arena_rating_history` at most once per player per match.
8. **Avatars.** Public profile content. Uploads go to the public
   `arena-avatars` Storage bucket under `avatars/<user_id>/...`; only the
   service role can write, anyone can read the public URL. Camera frames are
   never accepted by any endpoint.
9. **Account deletion.** `delete_account` revokes links, cancels queue seats,
   closes/cancels involving requests, closes active matches conservatively as
   `no_result` (`reason='account_deleted'`) and marks the profile deleted. The
   Edge Function then removes stored avatars and deletes the auth user with
   the service role. It is retry-safe.

## Additive response keys (no existing key renamed or removed)

- `queue_join`, `queue_poll`: `{match, queued, queued_since, expires_at}`.
  `queued` distinguishes "searching" from "seat expired/cancelled" without
  changing `match`, `queued_since` or `expires_at`.
- `match.players[]`: adds `tracking`, `practice_complete`, `left`. The
  documented `id`, `username`, `avatar_url`, `score`, `ready`, `last_seen`
  keys are unchanged.
- `ready`, `heartbeat`, `rep`, `leave`: on a closed match these actions return
  the current `{match}` instead of raising, so client retries are idempotent.
  A new rep event that is not a duplicate of a stored `event_id` still fails
  `match_not_live` once the round is closed.
- `rep`: duplicate `event_id` returns the current `{match}` exactly once
  counted; it never increments the score twice.
- `leaderboard.profiles[]`: adds `rank`.
- `inbox.requests[]`: adds `created_at` (needed for "received 2 minutes ago"
  UI) to the documented `Request`; the array is the actor's pending
  incoming/outgoing requests plus requests resolved in the last 7 days,
  newest first, capped at 50.
- `delete_account` returns `{ok, avatar_paths}` internally to the Edge
  Function; the client envelope stays `{data:{ok:true}}`.
- `report.reason`: 3-500 characters. `analytics.event`: `^[a-z][a-z0-9_]{1,48}$`
  and `properties` must be a JSON object under 8 KiB.

## Deliberate non-goals

- No bots, no async score challenges, no manual score entry, no chat, no
  followers, no pull-ups/training plans/currency.
- No camera data, image bytes other than the deliberate avatar upload, or
  observed timestamp is ever trusted as the round clock.
- No deployment, no production keys, no FitBattle credentials; the local
  stack, seed users and fixtures are explicitly fake (`.invalid` addresses).
