# Interface note 11 — public privacy, support and external deletion surfaces

Date: 2026-09-21
Task: `L07` (store, privacy and deletion surfaces)
Status: implemented and locally verified; hosted publication is blocked on the
owner inputs listed in `docs/release/PLAY_STORE_PACKET.md` §9.

## Why this note exists

`docs/CONTRACT.md` §8 asks shared changes to be recorded before they land. L07
adds the public pages that Google Play's User Data policy requires for an app
that creates accounts (an external deletion resource plus a privacy policy),
adds in-app links to them, and fixes the URL shapes other tasks must keep in
sync. No existing key, route or wire value was renamed.

## What landed

- `challenge-web/privacy.html`, `support.html`, `delete-account.html` — static
  pages served from the same host as the challenge landing. Owner-specific
  values are `data-arena-field` placeholders filled from `config.js`; while any
  value is missing the page shows a draft banner and the release gate fails.
- `challenge-web/pages.js`, `pages.css` — owner-field filler, draft guard and
  long-form styles.
- `challenge-web/delete_account.js` — the external deletion client. It verifies
  ownership with the documented email one-time-code flow
  (`POST /auth/v1/otp` with `create_user:false`, `POST /auth/v1/verify`) and
  then calls the existing `delete_account` action with the resulting session.
  The session lives in the closure only; there is no cookie, no storage, no
  analytics and no logging, so no token or code can reach a log.
- `challenge-web/config.js` — additive public fields: `supabaseAnonKey`
  (public client key), `legalEntity`, `legalAddress`, `privacyEmail`,
  `supportEmail`, `supportResponseTime`, `effectiveDate`, `childrenPolicy`,
  `emailProvider` and the four retention fields. All empty until the owner
  supplies them.
- `challenge-web/scripts/check.mjs` — page checks plus `--release`, which
  refuses to pass while any owner value or endpoint is still a placeholder and
  rejects a service-role JWT in `config.js` while allowing the public anon key.
- `app/lib/account/ui/public_pages.dart` — `PublicPages` + `PublicPageLauncher`
  over `url_launcher`; `ArenaConfigScope.maybeOf` was added for resolution.
- `app/lib/account/ui/settings_page.dart` — Settings → Privacy now links
  **Privacy policy** and **Support**, and the account section adds
  **Delete from the web instead** next to the in-app delete button. With the
  placeholder host (`example.invalid`) the buttons fail closed with honest
  copy instead of opening a dead address.
- `tools/store/build_store_assets.py` — deterministic generation of the Play
  icon (512×512 RGBA) and feature graphic (1024×500 RGB) from
  `design/arena/arena-mark-1024.png` and the bundled Inter fonts.
- `docs/privacy/DATA_INVENTORY.md` and `docs/release/PLAY_STORE_PACKET.md`.

## Fixed URL shapes (keep in sync)

| Path | Purpose | Consumed by |
| --- | --- | --- |
| `https://<ARENA_PUBLIC_URL>/privacy.html` | privacy policy (Play Console policy URL) | Settings link, store packet |
| `https://<ARENA_PUBLIC_URL>/support.html` | support and moderation contact | Settings link, store packet |
| `https://<ARENA_PUBLIC_URL>/delete-account.html` | external deletion resource (Play Console Data deletion URL) | Settings link, store packet |

`ARENA_PUBLIC_URL` is the existing release key; no new dart-define was added.
The pages ship in the same static folder as the landing and need no server
rewrite except the existing `/c/*` → `index.html`.

## Deletion contract

The external route reuses `arena_delete_account` and the Edge Function's
storage/auth deletion exactly as the in-app path does. It never creates an
account (`create_user:false`), never accepts a guessable token, keeps the
verified session for a safe retry, and reports an already-processed state
without claiming a second deletion. The behavior is proven end to end against
the local stack by `qa/launch/l07/tools/deletion_route_e2e.mjs`
(`qa/launch/l07/deletion_route_e2e.txt`).

## Verification

`flutter analyze` clean, **459/459 Flutter tests**, `challenge-web/scripts/check.mjs`
passes and `--release` fails only on the pending owner values, 16/16 web tests,
pgTAP **184/184** (after the documented `supabase db reset`), Deno arena **48**
+ dispatcher **10**, repository and artifact secret scans clean. Full record:
`qa/launch/L07.md`.
