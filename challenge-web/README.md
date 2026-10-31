# Challenge landing and public pages

Static, read-only landing page for `https://<ARENA_LINK_HOST>/c/<token>` plus
the public policy, support and account-deletion pages. Owned by task `05`
(landing) and `L07` (public pages). It is plain HTML/CSS/JS with no build step
and no dependencies.

## What it does

- Reads the token from the path (`/c/<token>`, with `?token=`/`?code=` as a
  fallback) using `link.js`, the same shape the app parses.
- Optionally resolves the challenger through the anonymous, read-only
  `GET /functions/v1/arena?token=<token>` and shows the available, offline,
  revoked, expired, completed, busy, blocked and unavailable states.
- Offers the custom-scheme open (`trainingarena://challenge/<token>`) and the
  Play install route with `referrer=challenge%3D<token>`.
- Always shows **Reopen this link after installing** and the readable short
  code.

## Public pages (L07)

| Page | Purpose | Notes |
| --- | --- | --- |
| `privacy.html` | privacy policy (Play Console policy URL) | every owner value is a `data-arena-field` placeholder filled from `config.js` |
| `support.html` | support and moderation contact | states that support never asks for a password or a sign-in code |
| `delete-account.html` | external deletion resource (Play Console Data deletion URL) | verifies ownership with the email one-time code and calls the same `delete_account` action the app uses |

`pages.js` fills the owner fields from `config.js` and shows a draft banner
while any value is still missing. `delete_account.js` keeps the verified
session in memory only: no cookie, no storage, no analytics and no logging, so
no token or code can reach a log. `create_user:false` means the page can never
create an account, and no guessable token is accepted anywhere.

Deployment: serve this folder with `/c/*` rewritten to `index.html` (the pages
are plain files, no rewrite needed). Fill `config.js` with the real host,
`apiBase`, the public anon key, the owner legal/contact details and the
retention periods, then run the release gate:

```sh
node scripts/check.mjs --release
```

It fails while any owner value or endpoint is still a placeholder, so an
unfinished policy cannot be published by accident. The in-app Settings screen
links `https://<ARENA_PUBLIC_URL>/privacy.html`, `/support.html` and
`/delete-account.html`.

## Read-only guarantee

Opening this page never mutates anything:

- the only network call is `GET /functions/v1/arena?token=...`;
- there is no sign-in, request send, seat reservation or match creation;
- there are no cookies, no local storage and no analytics POST;
- the social preview is passive and generic (no challenger identity, no token).

`node scripts/check.mjs` enforces these constraints plus the absence of
secrets in the client files.

## Runtime configuration

Edit `config.js` (or replace it during deployment):

| Field | Meaning |
| --- | --- |
| `apiBase` | Supabase project URL for the read-only resolve; empty disables the network call |
| `linkHost` | Host serving `/c/<token>`; stays `example.invalid` until the owner supplies the domain |
| `playStoreUrl` | Supported Play install route |
| `publicUrl` | Public site URL used by the back link |

Never put a service-role key, dispatcher secret or FCM service account here.
The resolve endpoint is anonymous; no key is required.

## Hosting

- Serve this folder as static files.
- Rewrite `/c/*` to `index.html` (for example with a static host rewrite rule,
  a CDN edge rule or a tiny worker). Without the rewrite the path 404s.
- Keep `linkHost` and the app's `ARENA_LINK_HOST` plus the Gradle
  `arenaLinkHost` property in sync.

## Android App Links and assetlinks.json

The app declares `autoVerify="true"` for
`https://${arenaLinkHost}/c/`. Verification requires the real release
fingerprint:

1. Copy `.well-known/assetlinks.json.template` to
   `<site-root>/.well-known/assetlinks.json`.
2. Replace `REPLACE_WITH_RELEASE_CERT_SHA256_FINGERPRINT` with the release
   signing certificate SHA-256 (for example
   `keytool -list -v -keystore <release-keystore>`).
3. Keep `package_name` as `app.trainingarena.mobile` (application ID is
   frozen by `docs/CONTRACT.md`).
4. Serve it over HTTPS at
   `https://<ARENA_LINK_HOST>/.well-known/assetlinks.json`, content type
   `application/json`, without redirects.

The relation is a single entry:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "app.trainingarena.mobile",
      "sha256_cert_fingerprints": ["<release SHA-256>"]
    }
  }
]
```

`example.invalid` cannot host this file, so verification cannot succeed until
the owner supplies the real domain. The manifest filter is present so the
build is ready; do not claim verified App Links on the placeholder host.

## Install referrer format

The Play button URL is:

```
https://play.google.com/store/apps/details?id=app.trainingarena.mobile&referrer=challenge%3D<token>
```

The app reads the raw referrer once (`InstallReferrerBridge` on Android) and
`challengeTokenFromReferrer` accepts `challenge=<token>`, `token=<token>`, an
encoded `/c/<token>` URL or `trainingarena://challenge/<token>`.

## Checks

```sh
node scripts/check.mjs
node scripts/check.mjs --release        # owner values required; fails while pending
node --test test/link.test.mjs test/public_pages.test.mjs
```
