# 0001 — open baseline interface decisions

Date: 2026-09-17
Task: `00_RECONCILE_AND_BOOTSTRAP`
Status: open; the baseline keeps compiling with the safe defaults below.

The task-00 baseline deliberately did not invent values that belong to the
owner or to a later task. Until a decision lands, the values below stay as
they are:

## D1 — real HTTPS challenge domain (blocks task `05`)

- Current value: `ARENA_LINK_HOST=example.invalid`,
  `ARENA_PUBLIC_URL=https://example.invalid`.
- Needed: the production HTTPS host that serves `/c/<token>` and its
  `assetlinks.json`. Task `05` adds the Android App Link filter once the host
  exists; until then no link-specific manifest entry is present.
- Owner: product owner.

## D2 — custom URL scheme name (task `05`)

- Current state: no custom scheme is declared anywhere. QR codes and local
  shortcuts should use the HTTPS link plus the Android install-recovery flow.
- Needed: if task `05` wants a custom scheme (for example for the Play install
  referrer round trip), record the exact scheme string here before adding the
  intent filter. It must not reuse the legacy application's scheme.

## D3 — Supabase project and public client keys (task `04`)

- Current value: `ARENA_SUPABASE_URL` and `ARENA_SUPABASE_ANON_KEY` are empty.
- Needed: a new project (never the previous application's project), Google
  provider, confirmed email-code sign-in, Auth redirect allowlist, public
  anon key. Server-only secrets stay out of the app repository.
- Owner: product owner + task `04`.

## D4 — brand mark and launcher icon (task `01`)

- Current state: the Android launcher icon and splash mark are inherited
  shell assets on the arena charcoal background.
- Needed: task `01` delivers the arena mark; the platform task replaces the
  `mipmap-*` files. No Dart code depends on the current artwork.

## D5 — avatar upload deferral (tasks `04`, `06`)

- Contract: avatar upload is optional and may be deferred without blocking
  sign-in, challenge acceptance or battles. `ArenaProfile.avatarUrl` is
  nullable everywhere.
- Needed: nothing to decide now; recorded so no task makes avatars a gate.

## Fixed by `docs/API.md`, not open

- Challenge link path: `https://<host>/c/<token>`, 12-character
  case-insensitive token/code.
- Match lifecycle wire values, rep-event idempotency, heartbeat/forfeit
  rules, ranked-only Elo (`1000`, `K=32`), no bots and no server-side camera
  upload.
