# 07 — Operational match-creation incident control (proposal)

Status: **proposal — not applied**. Owner decision required before launch.
Date: 2026-09-20 (L03, corrected after coordinator review). Related:
`docs/release/INCIDENT_RESPONSE.md`, `docs/release/GO_NO_GO.md` (R11a/R15),
`supabase/migrations/20260917143539_arena_rpc.sql`.

## Why

`ARENA_FEATURE_*` values are **build-time** dart-defines. Once an APK is
installed they cannot change, so they are ship-time scope controls, not
incident kill switches. L03 gated the client, but an incident on an installed
build needs a server-side refusal of **new match creation**.

## Selected launch shape (invite-first)

The pilot ships with ranked matchmaking **off**. Matches are created by:

- friend invitation: `arena_request_send` → `arena_request_respond` (accept)
  or `arena_request_accept` (link/token acceptance), which create the match;
- ranked queue: `arena_queue_join` / `arena_queue_poll`.

A ranked-only pause therefore does **not** protect the selected launch. The
control must refuse new matches on the invite paths too, while **active matches
continue to settle** (ready, rep, heartbeat, leave, tick, maintenance).

## Audit result: no operational control exists today

- The RPCs above create matches unconditionally for any authenticated,
  unblocked actor.
- `arena_maintenance()` only expires overdue requests/queue seats and ticks
  matches; it cannot refuse new entry.
- There is no flags table, global switch or operator RPC. Per-user controls
  (`arena_blocks`, reports, deletion) are not global.

## Smallest scoped enforcement (proposal)

One additive migration plus checks in the five match-creation functions. No
wire change and no client change: refusals reuse the existing `AR021 →
forbidden` business-error envelope (`supabase/functions/arena/lib/errors.ts`),
which every shipped client already renders as a plain message.

```sql
-- supabase/migrations/20260920120000_arena_match_creation_control.sql
create table if not exists public.arena_controls (
  id boolean primary key default true check (id),
  match_creation_enabled boolean not null default true,
  ranked_matchmaking_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.arena_controls (id) values (true)
on conflict (id) do nothing;

alter table public.arena_controls enable row level security;
revoke all on table public.arena_controls from anon, authenticated, public;
```

Fail-closed check, inserted after `arena_assert_actor` in
`arena_request_send`, `arena_request_accept`, `arena_request_respond` (accept
branch only), `arena_queue_join` and `arena_queue_poll`:

```sql
-- A missing control row must refuse new matches, never allow them:
-- `not (select ...)` is NULL when no row exists and would fall through.
if not coalesce(
     (select match_creation_enabled from public.arena_controls where id),
     false) then
  perform public.arena_fail('AR021', 'new matches are temporarily paused');
end if;

-- ranked only (queue functions): additionally require the ranked flag
if not coalesce(
     (select ranked_matchmaking_enabled from public.arena_controls where id),
     false) then
  perform public.arena_fail('AR021', 'ranked matchmaking is temporarily paused');
end if;
```

Operator procedure (service role / hosted SQL; document in
`INCIDENT_RESPONSE.md`):

```sql
update public.arena_controls
   set match_creation_enabled = false, updated_at = now();
update public.arena_queue set status = 'expired' where status = 'queued';
-- re-enable: set match_creation_enabled = true (and ranked flag if needed)
```

### Transaction boundary, in-flight behaviour and rollback

- Each check runs inside the same RPC transaction that would create the match,
  so a toggle committed before the statement begins is honored. Under READ
  COMMITTED an already-running statement that passed the check can still
  create one match; the exposure is bounded by that single RPC statement.
- Disabling does **not** touch existing matches: `arena_match_ready`,
  `arena_match_rep`, `arena_match_heartbeat`, `arena_match_leave`,
  `arena_match_tick` and `arena_maintenance` are unchanged, so active matches
  settle or expire normally. The operator snippet expires queued seats so
  nobody waits in a paused queue.
- Rollback: restore the five function bodies from
  `20260917143539_arena_rpc.sql` and `drop table public.arena_controls`.
  Additive table, no data migration, no contract change.

## Proposed tests (pgTAP, `supabase/tests/arena_ops_test.sql`)

1. After reset the singleton row exists and both flags are `true`.
2. Deleting the row (within a test transaction) makes `arena_queue_join` and
   `arena_request_send` raise `AR021` — **missing row fails closed**.
3. With `match_creation_enabled=false`: `arena_request_send`,
   `arena_request_accept`, `arena_request_respond` (accept) and
   `arena_queue_join`/`arena_queue_poll` raise `AR021`; declining/cancelling a
   request still succeeds.
4. With `ranked_matchmaking_enabled=false` but creation enabled: only the queue
   functions raise `AR021`.
5. An existing live match still accepts `arena_match_rep` /
   `arena_match_heartbeat` / `arena_match_ready` while paused, and
   `arena_maintenance()` still ticks it.
6. `anon`/`authenticated` cannot select or update `arena_controls`
   (`has_table_privilege`).

## Alternatives (this is one scoped option, not the only one)

- Play staged-rollout halt (stops delivery, not running installs).
- An Edge-Function-level maintenance flag / `ARENA_ALLOWED_ORIGINS`-style
  server env switch (no database migration, coarser, needs a function deploy).
- Per-feature client flags for future builds (cannot affect installed builds).
The database control above is the smallest option that refuses new matches for
**already-installed** clients while preserving active-match settlement.

## Decision needed

Apply before the pilot (recommended: it is the only proposed control that stops
an invite-first incident in installed builds), or accept the alternative and
record it. No hosted change was made by L03.

## Explicit non-claims

- Changing a dart-define does not disable installed builds.
- This proposal was not applied, deployed or tested against a hosted project.
