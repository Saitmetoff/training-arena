# C09 — Owner input wizards (signing, hosting, Play closed test)

Status 2026-09-23: **implemented.** `tools/wizards/` holds W1/W2/W3 plus the
index; all parse and dry-run clean (exit 0, no network, no writes). Record:
`qa/competitive/c09/REPORT.md`.

Depends on: nothing; scripts only. Estimate: 4–8 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `wizard` — the whole task is generating owner-driven interactive wizards.
  The skill's template is bash; this machine is Windows PowerShell 5.1, so
  deliver `.ps1` scripts (translate, do not ship bash that cannot run here).

## Goal

Six of the launch blockers are owner-only actions with no code substitute
(`docs/release/GO_NO_GO.md` §6, analysis §7 P0). Turn each into a re-runnable,
safe-by-default wizard that checks prerequisites, prompts for values, runs the
exact commands, verifies the outcome and prints what evidence to record. The
scripts must never echo, log or commit a secret.

Generate three scripts plus an index:

| Script | Covers | Source of truth |
| --- | --- | --- |
| `tools/wizards/W1-signing.ps1` | R9: keystore creation outside the repo, `android/key.properties` (gitignored), CI secrets, release-candidate workflow, fail-closed verification | `docs/release/CONFIGURATION.md` §3, `.github/workflows/release-checks.yml` |
| `tools/wizards/W2-hosting.ps1` | R2/R3/R16: domain + DNS check, Supabase project link, `challenge-web/config.js` values, SMTP, deploy, App Links fingerprints, `check.mjs --release`, `check_app_links.mjs --release` | `qa/launch/l05/DEPLOYMENT_PACKET.md` §0–§3 |
| `tools/wizards/W3-play-closed-test.ps1` | L10: account/package verification, closed-test track, 16–24 recruited / ≥12 continuous roster tracking, Data Safety answers, AAB upload, Play app-signing SHA-256 verification | `qa/launch/l10/PLAY_TEST_AND_LAUNCH_PACKET.md` |

Requirements for every script:

- `-DryRun` prints every action without executing it; default is dry-run.
- Prerequisite checks first (tool present, file present, value present) with
  an exact message naming what is missing.
- Secrets are read with `Read-Host -AsSecureString` or from the proper secret
  store, never written to disk inside the repo, never printed.
- Distinguish the three certificate roles correctly: upload key, Play
  app-signing certificate, local debug — the App Links and OAuth steps need
  the Play app-signing identity, not the upload key.
- Idempotent: re-running does not duplicate keystores, secrets, projects or
  listings; it reports what already exists.
- Ends with an evidence checklist the owner pastes into the task record.
- No network action without an explicit interactive confirmation.

Also write `tools/wizards/README.md`: what each wizard does, what the owner
must have ready before running, and where the resulting evidence goes.

## Owned paths

`tools/wizards/` (new). Nothing else. Do not edit the release packets, CI,
app or backend.

## Must not

- Commit, print or copy any secret, token, keystore or service JWT.
- Perform any external action during generation; the scripts are for the owner
  to run interactively.
- Invent a domain, project, account or Play track.
- Weaken any existing check to make a wizard "succeed".

## Acceptance

- All three scripts exist, syntax-check clean in PowerShell 5.1 (show the
  command and result), and run to completion in `-DryRun` without touching
  the network or writing files outside a stated temp path.
- A secret-scan pass over the new directory is clean.
- `tools/wizards/README.md` states prerequisites and evidence destinations.
- The handoff lists, per wizard, the exact owner inputs it needs — mapping
  back to R9, R2/R3/R16 and L10.

## Handoff

Standard handoff, including the per-wizard prerequisite list and the exact
dry-run output.
