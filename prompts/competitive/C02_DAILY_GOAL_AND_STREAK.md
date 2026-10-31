# C02 — Daily goal and streak with server truth

Status 2026-09-23: **implemented device-local, not server-backed.** Decision
12 makes solo local-only and no hosted stack exists (R2/R3/R16), so the
server path was deferred with the upgrade path recorded in
`qa/competitive/c02/REPORT.md`. The rest of this prompt is the original spec.

Depends on: C01 (a solo result exists to record). Estimate: 12–24 h.
This is the riskiest task in the pack: timezone, midnight and DST boundaries
are where streak features silently break.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `supabase` — migration, RPC, Edge Function and RLS conventions.
- `supabase-postgres-best-practices` — schema, indexes, query shape, RLS.
- `tdd` — the streak calendar tests come first.

## Goal

Give the solo result a reason to come back tomorrow: a daily goal and a streak
that is computed from real activity and cannot be inflated by reopening the app
or replaying a request.

Scope:

1. **Backend.** New additive migration under `supabase/migrations/` (do not
   edit existing migrations or RPCs). Record solo activity per user per local
   day, and expose goal, current streak, longest streak and today's progress
   through the existing `{action, params}` gateway in
   `supabase/functions/arena/` — reuse the established service-role boundary
   and deny-all RLS model; no client grants.
2. **Day rule, written down.** Pick and document one rule for "a day" (e.g.
   IANA timezone supplied and stored at submission, falling back to UTC), and
   implement it identically in SQL and Dart. State the rule in `docs/API.md`.
3. **Idempotency.** Re-submitting the same session (retry, offline queue)
   must not double-count. Reuse the existing idempotency pattern from the
   battle receipts.
4. **Client.** Goal progress and streak on the Battle tab's solo entry and on
   the profile; optimistic local display with server reconciliation; offline
   sessions queue and reconcile later.
5. **Flag.** `ARENA_FEATURE_SOLO_PROGRESS` in `app/lib/config/arena_config.dart`,
   added to `tools/release/check_release_flags.mjs` and documented; off by
   default until the owner sets the release value.

## Owned paths

`supabase/migrations/`, `supabase/functions/arena/`, pgTAP suites under
`supabase/tests/`, `docs/API.md`, `app/lib/solo/`, `app/lib/config/`,
`app/lib/account/ui/profile_tab.dart` (display only), new tests,
`tools/release/check_release_flags.mjs` flag list, `qa/competitive/c02/`.

## Must not

- Touch ranked, Elo, battle receipts, matchmaking or result sharing.
- Change camera code or counting.
- Award anything for opening the app: a day counts only from a recorded solo
  set that meets the goal; state the goal source (constant or owner setting)
  explicitly and keep it in one place.
- Send push notifications (R4 is off) or add a scheduler.
- Add a dependency.

## Acceptance

- `supabase db reset` applies cleanly; pgTAP passes (184 existing plus the new
  assertions); Deno arena/dispatcher tests pass (48 + 10 plus new).
- Pure-Dart and SQL tests agree on the same fixture calendar: same-day second
  session, consecutive days, one missed day resets current but not longest,
  local-midnight boundary, a DST spring-forward and fall-back day, and a UTC
  day that differs from the local day.
- Duplicate submission of the same session leaves counts unchanged (test).
- `flutter analyze` clean; full suite passes; flag off hides the surface with
  a tested refusal path.
- No solo activity changes rating, receipts or leaderboard (test or a
  server-query evidence line).

## Handoff

Standard handoff, including the day rule, the flag's release value and the
exact idempotency key used.
