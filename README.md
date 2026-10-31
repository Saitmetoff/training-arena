# Training Arena

> Invite-first push-up and squat battle app — Flutter client, Supabase backend, static challenge pages, and a dependency-free clickable design prototype.

**Live design prototype:** https://saitmetoff.github.io/training-arena/

The prototype is simulated data only. It has no backend, camera, accounts, or share sheet.

## Status

This repository is a source snapshot imported from the owner's working tree at commit `3ccc260` (23 October 2026), the latest clean launch-readiness branch. It is a development project, not a published release.

- No hosted backend, domain, signing key, or Play Store release is configured.
- The prototype exists for design review; every score, account, and match in it is simulated.
- The Flutter app and `fault-web` need owner-supplied Supabase/Resend credentials and are not deployed here.
- `docs/PROJECT_STATUS.md` and `docs/release/GO_NO_GO.md` record the actual verification state and open blockers.

## What is here

| Path | Contents |
|---|---|
| `app/` | Flutter Android client: camera rep counting, battles, results and sharing |
| `backend/` | Backend notes and interface material |
| `supabase/` | Postgres migrations, RLS/RPC, Edge Functions and pgTAP tests |
| `challenge-web/` | Static challenge landing and public policy pages |
| `fault-web/` | Next.js Fault marketing/waitlist development app |
| `prototype/` | Dependency-free clickable design prototype (published to GitHub Pages) |
| `design/` | Design system, tokens, screen map and component inventory |
| `docs/` | Contracts, API, release configuration and project status |
| `qa/` | Test reports, release evidence and known gaps |
| `prompts/`, `tools/` | Internal workflow documents and release tooling |

## Run the prototype

Open `prototype/index.html` directly in a browser, or serve the repository root:

```sh
npx --yes serve .
# open http://localhost:3000/prototype/
```

Start at `#/c/9f2k4p7q` to review the friend-link path. See `prototype/README.md` for preview fixtures and checks.

## Build the app

```sh
cd app
flutter pub get
flutter test
```

The app needs a Java/Android SDK and owner-supplied Supabase configuration for live features. See `docs/release/CONFIGURATION.md` and `supabase/README.md`.

## Security

Only `.env.example` files are tracked. No service-role key, signing key, Firebase service account or provider secret is included. If you believe a secret was published, contact the owner privately instead of opening a public issue.

## License

No license is declared in this snapshot. All rights are reserved by the owner; ask before reusing or redistributing the code.

## Provenance

Imported from the owner's private working tree at commit `3ccc260cafde8dec023ae34a6680e35c961b1daa` on branch `codex/launch-readiness-20261021`. Git history before the import is not included.
