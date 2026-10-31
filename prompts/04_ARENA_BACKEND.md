# Task 04 — build the authoritative Arena backend and security boundary

You own the new Training Arena backend. Work only in `D:\TrainingArena`; read the existing partial `docs/API.md` and migration before editing. Use a separate Supabase project/namespace from FitBattle. Do not reuse credentials, tables, Edge Functions or legacy scoring behavior. Do not deploy or ask for secrets in chat.

## Product rules

The backend models four separate concepts:

1. A durable **challenge link** identifies a sharer and remains valid until revoked or the account is deleted.
2. A **challenge request** records one recipient’s invitation, can be accepted/declined/cancelled/expired and lasts 24 hours.
3. A **match** is created after mutual acceptance and never starts until both players complete practice and confirm readiness.
4. An immutable **result receipt** is the sole evidence for history and sharing.

Only push-ups and squats are valid exercises. Ranked queue matches affect Elo (1,000 start, K=32); personal challenges and friend rematches are casual and never affect rating. No bots, async score challenges, manual competitive scoring, chat or followers.

## API contract

Implement or reconcile `POST /functions/v1/arena` with authenticated `{action,params}` and `{data:...}` / `{error:{code,message}}` envelopes. `GET /functions/v1/arena?token=...` is anonymous, read-only link resolution. At minimum support profile, profile update/avatar, link resolve/rotate, inbox, request send/accept/respond, queue join/poll/leave, match state/ready/heartbeat/rep/leave, leaderboard, history, public profile, report/block, device registration, delete account and analytics. Keep all identifiers and JSON keys stable with `docs/API.md`; document intentional changes before making them.

For rep events require `event_id`, strictly increasing sequence, observed timestamp and counter version. Use server time for the five-second countdown and 60-second round. Accept events only during live play and with fresh tracking; make retries idempotent. Tracking loss pauses only that player’s count. One player absent for over ten seconds forfeits; shared service failure yields `no_result` and no rating change. Preparation abandoned for ten minutes expires without rating.

## Data and security

- Use explicit `arena_*` tables or a separate project. Include profile/avatar, durable links, requests, matches, match players/events, immutable receipts, rating history, blocks/reports, notification outbox and analytics events.
- Enforce unique normalized usernames, request expiry, no overlapping accepted battles, one active queue seat per user and one receipt per match.
- RLS must deny direct client writes to scores, ratings, receipts and server timestamps. Public link resolution exposes only safe challenger identity and availability. Avatars are intentional public profile content; camera data is never stored.
- RPCs/transactions close a match, calculate result and rating once, snapshot names/avatars/rating in the receipt and remain safe under retries/concurrency.
- Validate authorization on every action, never trust client user IDs, observed timestamps, outcome or rating. Keep service-role access inside server-only code.

## Deliverables

- Migrations with constraints, indexes, RLS and rollback notes.
- `supabase/functions/arena` implementation plus focused tests for every state transition and adversarial authorization case.
- Reconciled `docs/API.md`, examples with fake IDs, error-code catalogue and state diagrams.
- Local seed/fixture data that cannot be mistaken for production users.

Acceptance means unauthorized users cannot read another player’s private history or mutate a result, duplicate reps/retries do not double-count, expired/revoked links are read-only failures, ties remain ties, and a completed ranked result updates both ratings exactly once. Deployment and production credentials remain a later release task.

