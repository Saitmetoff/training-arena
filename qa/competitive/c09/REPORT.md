# C09 — owner input wizards: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

## What landed

| File | Covers | Source |
| --- | --- | --- |
| `tools/wizards/W1-signing.ps1` | R9 keystore, `key.properties`, CI secrets, fingerprints | `docs/release/CONFIGURATION.md` §3 |
| `tools/wizards/W2-hosting.ps1` | R2/R3/R16 domain, `config.js`, `assetlinks.json`, Supabase link/migrate/secrets/deploy | §4–§6, L05 packet |
| `tools/wizards/W3-play-closed-test.ps1` | L10 Console, closed track, roster, upload, fresh-install verification, forms | L10 packet |
| `tools/wizards/README.md` | prerequisites, safety rules, usage, evidence destinations | — |

## Safety properties (verified)

- **Dry-run by default.** All three were run with `powershell -NoProfile -File`
  and completed with exit 0, printing only the plan: no prompts, no network,
  no file writes.
- **No secret exposure.** W1 reads passwords with
  `Read-Host -AsSecureString`, passes them to `keytool` via `-storepass:env`,
  and verifies `git check-ignore` on `app/android/key.properties` before
  leaving it on disk. W2 generates the dispatcher secret locally and prints
  only its length.
- **Idempotent.** An existing keystore is never overwritten; the wizards
  report what already exists.
- **Certificate roles kept separate.** W1 records the upload-key fingerprint;
  W2 requires the **Play app-signing** SHA-256 for `assetlinks.json`; W3
  checks that Console's app-signing fingerprint matches the hosted file.
- **No external action.** W3 uploads nothing and submits nothing; each
  Console step is gated on an explicit owner confirmation.

## Verification (2026-09-23)

| Command | Result |
| --- | --- |
| `[Parser]::ParseFile` on all three scripts | syntax OK |
| `powershell -NoProfile -File tools/wizards/W1-signing.ps1` | dry run, exit 0 |
| `... W2-hosting.ps1` | dry run, exit 0 |
| `... W3-play-closed-test.ps1` | dry run, exit 0 |

One defect found and fixed during verification: W1's keytool fallback called
`Join-Path` with an unset `JAVA_HOME` and crashed; it now guards the variable
and resolves the known JDK 17 path.

## Prerequisites the owner must supply

W1: JDK 17 (`keytool`), optional `gh` for CI secrets. W2: Supabase CLI, the
domain, the Play app-signing SHA-256, the project ref, the owner legal/contact
values. W3: a signed AAB (W1 first), a roster ledger outside the repository.
