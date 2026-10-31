# Training Arena backend (task 04)

This tree is the authoritative Arena backend. It is a separate Supabase
project (`supabase/config.toml` → `project_id = "TrainingArena"`) and shares
no credentials, tables, functions or buckets with FitBattle.

| Path | Contents |
| --- | --- |
| `migrations/20260917143538_arena_initial.sql` | `arena_*` enums, 14 tables, constraints, indexes, triggers, RLS, grants, avatar bucket |
| `migrations/20260917143539_arena_rpc.sql` | helper functions and every action RPC, outbox lease/confirm, maintenance sweep |
| `functions/arena/` | `POST`/`GET` Edge Function (auth, validation, envelopes, avatar storage, account deletion) |
| `functions/arena-dispatcher/` | server-only outbox worker with its own bearer secret and a no-op provider seam |
| `tests/` | pgTAP suites for schema/RLS, lifecycle/state transitions and adversarial authorization |
| `seed.sql` | local-only fake fixtures (`fixture_*`, `@arena.invalid`); never for a hosted project |

`docs/API.md` is the client-facing contract; `docs/decisions/03` records the
intentional additive changes.

## Local workflow

```sh
# from the repository root
supabase start                 # local stack (Docker)
supabase db reset              # migrations + seed fixtures
supabase test db --local       # pgTAP suites (184 assertions)
supabase functions serve --no-verify-jwt --env-file supabase/.env.local
node backend/e2e/arena_smoke.mjs
```

`supabase functions serve` serves `arena` and `arena-dispatcher` together.
With `ARENA_DISPATCHER_SECRET` set in `supabase/.env.local` (gitignored,
local-only), the e2e smoke also checks the dispatcher worker boundary
(missing/wrong/valid bearer) and that a match with both clients gone is closed
`no_result`/`service_outage` by the worker sweep; without the variable the
smoke stays the 16-check task-04 smoke. Hosted execution is the L05 deployment
packet: `qa/launch/l05/DEPLOYMENT_PACKET.md`.

Edge unit tests run on Deno and do not need Docker:

```sh
cd supabase/functions/arena
npx --yes deno@2 test tests
```

`supabase/.env.local` (gitignored) may set `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `ARENA_ALLOWED_ORIGINS`,
`ARENA_DISPATCHER_SECRET` and `FCM_SERVICE_ACCOUNT_JSON` for local function
serving. Production secrets live only in the hosted project's function
settings.

## Local fixtures are fake

`seed.sql` creates `fixture_alice`, `fixture_bob` and `fixture_carol` with
`@arena.invalid` emails, a documented fake password, fixed sessions and
deliberately guessable `fixture*` link tokens. They exist only so a developer
can explore the API locally. They cannot receive mail and must never be
loaded into a hosted project.

## Security model (short version)

- `anon`/`authenticated`: no table, sequence or function grants; RLS enabled
  with no policies, so even a future accidental grant fails closed.
- Every POST verifies the JWT in the Edge Function, then the RPC re-checks
  `auth.sessions`. Client-supplied user ids, ratings, outcomes and observed
  timestamps are never trusted.
- Receipts, rating history and rep events are immutable by trigger. One
  receipt per match, one rating row per player per match.
- Challenge links are durable; expired/revoked links only ever produce
  read-only failures.
- Avatars are public profile content in the `arena-avatars` bucket; camera
  data is never accepted.

## Rollback notes

Roll back only before the namespace carries real data, and in this order:

```sql
-- 1. drop the RPC migration objects
drop function public.arena_outbox_confirm(uuid, text, boolean, text, integer);
drop function public.arena_outbox_lease(text, integer, integer);
drop function public.arena_maintenance();
drop function public.arena_delete_account(uuid, uuid);
drop function public.arena_analytics(uuid, uuid, text, jsonb);
drop function public.arena_device_register(uuid, uuid, text, text);
drop function public.arena_blocked(uuid, uuid);
drop function public.arena_unblock(uuid, uuid, uuid);
drop function public.arena_block(uuid, uuid, uuid);
drop function public.arena_report(uuid, uuid, uuid, uuid, text);
drop function public.arena_public_profile(uuid, uuid, uuid);
drop function public.arena_history(uuid, uuid);
drop function public.arena_leaderboard(uuid, uuid);
drop function public.arena_match_leave(uuid, uuid, uuid);
drop function public.arena_match_rep(uuid, uuid, uuid, uuid, bigint, timestamptz, text);
drop function public.arena_match_heartbeat(uuid, uuid, uuid, boolean);
drop function public.arena_match_ready(uuid, uuid, uuid, boolean, boolean);
drop function public.arena_match_state(uuid, uuid, uuid);
drop function public.arena_queue_leave(uuid, uuid);
drop function public.arena_queue_poll(uuid, uuid);
drop function public.arena_queue_join(uuid, uuid);
drop function public.arena_request_respond(uuid, uuid, uuid, text);
drop function public.arena_request_accept(uuid, uuid, uuid);
drop function public.arena_request_send(uuid, uuid, text);
drop function public.arena_inbox(uuid, uuid);
drop function public.arena_resolve_link(text);
drop function public.arena_rotate_link(uuid, uuid);
drop function public.arena_clear_avatar(uuid, uuid);
drop function public.arena_set_avatar(uuid, uuid, text, text);
drop function public.arena_update_profile(uuid, uuid, text);
drop function public.arena_get_profile(uuid, uuid);
drop function public.arena_queue_try_match(uuid);
drop function public.arena_after_player_update(uuid);
drop function public.arena_match_tick(uuid);
drop function public.arena_close_match(uuid, text, public.arena_outcome, uuid);
drop function public.arena_expire_requests_for(uuid);
drop function public.arena_request_json(uuid);
drop function public.arena_match_view(uuid);
drop function public.arena_receipt_json(uuid);
drop function public.arena_notify(uuid, text, jsonb);
drop function public.arena_new_token();
drop function public.arena_are_blocked(uuid, uuid);
drop function public.arena_active_match_id(uuid);
drop function public.arena_link_json(uuid);
drop function public.arena_profile_json(uuid);
drop function public.arena_assert_actor(uuid, uuid);
drop function public.arena_fail(text, text);

-- 2. drop the schema migration objects (tables before types), then:
drop trigger arena_on_auth_user_created on auth.users;
drop function public.arena_handle_new_user();
delete from storage.buckets where id = 'arena-avatars';
```

`supabase db reset` is the supported way to rebuild the namespace from
scratch in development.

## Verification evidence (local, 2026-09-18)

- `supabase db reset` — migrations and seed apply cleanly.
- `supabase test db --local` — 4 pgTAP suites, 184 assertions, all passing
  (`arena_schema_test.sql`, `arena_flow_test.sql`, `arena_authz_test.sql`,
  `arena_ops_test.sql`).
- `npx --yes deno@2 test tests` — 48 Edge Function assertions passing
  (validators, avatar sniffing, auth/session checks, envelopes, storage
  cleanup, delete-account flow).
- No deployment was performed and no production credential was requested.
