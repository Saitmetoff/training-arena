# Owner input wizards (C09)

Three PowerShell wizards for the launch steps only the owner can perform.
Every one is **dry-run by default**: it prints the plan, touches no network
and writes nothing. Add `-Execute` to act.

| Wizard | Covers | Source of truth |
| --- | --- | --- |
| `W1-signing.ps1` | R9: keystore, `key.properties`, CI signing secrets, fingerprints | `docs/release/CONFIGURATION.md` §3 |
| `W2-hosting.ps1` | R2/R3/R16: domain, `config.js`, `assetlinks.json`, Supabase link/migrate/secrets/deploy | `CONFIGURATION.md` §4–§6, `qa/launch/l05/DEPLOYMENT_PACKET.md` |
| `W3-play-closed-test.ps1` | L10: Console, closed track, roster, upload, fresh-install verification, forms | `qa/launch/l10/PLAY_TEST_AND_LAUNCH_PACKET.md` |

## Before running

- JDK 17 with `keytool` (PATH, `JAVA_HOME`, or `D:\Kiro\.tooling\jdk17`).
- `gh` authenticated for W1's CI secrets (optional; the wizard prints manual
  names when it is missing).
- Supabase CLI for W2.
- A signed AAB for W3 (W1 must have run first).

## Safety rules

- Passwords are read with `Read-Host -AsSecureString`, passed to `keytool`
  through an environment variable, never printed and never written into the
  repository. `key.properties` is verified with `git check-ignore` before the
  wizard continues.
- W2 generates the dispatcher secret locally, sets it in Supabase and prints
  only its length; copy it to the owner vault.
- W3 uploads nothing and submits nothing; it gates each Console step on an
  explicit owner confirmation.
- Re-running W1 is safe: an existing keystore is never overwritten.

## Usage

```powershell
# see the plan
powershell -NoProfile -File tools/wizards/W1-signing.ps1

# act
powershell -NoProfile -File tools/wizards/W1-signing.ps1 -Execute

powershell -NoProfile -File tools/wizards/W2-hosting.ps1 -Execute `
  -Domain arena.example.com -PlaySigningSha256 AA:BB:... -SupabaseProjectRef abcdefgh

powershell -NoProfile -File tools/wizards/W3-play-closed-test.ps1 -Execute `
  -AabPath app\build\app\outputs\bundle\release\app-release.aab
```

## Evidence destinations

W1 → owner vault + the release task record. W2 → public URLs and the Data
Safety answers in `docs/release/PLAY_STORE_PACKET.md`. W3 → the roster ledger
and feedback ledger (owner-held, outside the repository) plus the Play packet.

Nothing in these wizards authorizes a Play action, deployment or purchase; the
GO/NO-GO decision in `docs/release/GO_NO_GO.md` still applies.
