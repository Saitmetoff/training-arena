# `backend/` — Arena server boundary

Task `04` owns this directory, but the implementation lives beside the
database it serves:

- database schema, RPCs, RLS and rollback notes: `supabase/migrations/`
- Edge Function and tests: `supabase/functions/arena/`, `supabase/functions/arena-dispatcher/`
- pgTAP suites: `supabase/tests/`
- local workflow and fixtures: `supabase/README.md`
- client protocol: `docs/API.md` (additive changes in `docs/decisions/03-...`)

No code belongs here that duplicates those modules. This file exists so the
ownership boundary from `docs/CONTRACT.md` §7 has a single entry point.

## Local end-to-end smoke

`e2e/arena_smoke.mjs` signs development JWTs for the local seed fixtures and
exercises the served Edge Function over HTTP (anonymous GET, JWT boundaries,
a request round trip, analytics validation). It is idempotent and local-only;
see the header for the three commands to run it.
