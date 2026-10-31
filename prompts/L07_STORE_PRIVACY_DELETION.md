# L07 prompt — store, privacy and deletion surfaces

Paste this whole file into a new chat. It is self-contained.

## Role and rules

You are the sole coding executor for Training Arena in `D:/TrainingArena`.
Model: `opencode-go/deepseek-v4.1-flash`. One writer per tree: verify
`git status` first; **preserve any unrelated dirty/untracked files** (another
session may be mid-task) and never stage or revert work that is not yours. Do
not modify `D:/Kiro` or its shared toolchain. No product expansion, no
speculative framework, no generated fake evidence, no weakened release gates.
No fabricated legal statements, reviews or testimonials. Trace every caller
before changing a shared function. Reuse the existing design, API and test
tools. Commit only a scoped, secret-scanned change after the relevant
verification.

## Read first

A temp handoff may exist at
`C:\Users\ADMIN\AppData\Local\Temp\opencode\handoff.md`; read it if present,
otherwise reconstruct state from the docs below.

`docs/PROJECT_STATUS.md` (top sections), `docs/release/GO_NO_GO.md`,
`docs/release/CONFIGURATION.md`, `prompts/LAUNCH_CLOSEOUT_2026-09-20.md` §L07,
`qa/launch/L01.md`–`L05.md`, `qa/launch/l05/DEPLOYMENT_PACKET.md` §0,
`docs/release/PILOT_PLAN.md` §4 (support script) and §5 (distribution),
`docs/release/LAUNCH_PLAN_2026-09-20.md` §2 (Play policy facts),
`docs/API.md` §7, `docs/decisions/0001-...` (D5 avatar deferral),
`docs/decisions/06-account-profile-leaderboard-interface-note.md`,
`docs/media/PROVENANCE.md`, `app/lib/account/ui/settings_page.dart`,
`supabase/migrations/`, `supabase/functions/arena/lib/actions.ts`,
`qa/REPORT.md`.

Current state to verify, not assume: branch `codex/training-arena`, last L05
commit `1819ebf`; L04 (camera/media) and L05 (hosted domain/project/SMTP) are
**BLOCKED** on owner inputs; release verdict NO-GO (R9 signing is the only
artifact blocker).

## Scope (from the closeout pack, in order)

1. **Traceable data inventory.** Cover auth/email, usernames, avatars,
   match/rep events, telemetry and optional FCM tokens. Derive it from the
   actual migrations/tables/columns and Edge Function code — every row must
   cite the table/column or code path. State explicitly where camera frames
   and landmarks go (on-device only, never accepted by any endpoint) and do
   **not** infer "no data collected" from that. Record retention and deletion
   behavior, including records retained for the counterpart player (receipts,
   rating history, immutable rep events) and service backups. Mark every
   value that depends on an owner retention decision as pending rather than
   inventing a period.
2. **Public privacy/support pages and external deletion route.** Using actual
   owner legal/contact details (legal entity, contact email, support address,
   hosting target from L05), prepare the public privacy policy and support
   pages and a **functional external account-deletion request route** that
   meets the current Play policy (an in-app Settings paragraph alone is not
   enough). Reuse the existing `delete_account` backend and the in-app flow
   where appropriate; an externally initiated request must verify account
   ownership (for example the documented email-code flow, never a guessable
   token), preserve retry/error safety, and never put secret-bearing deletion
   tokens in logs or analytics. A securely handled manual request channel may
   be sufficient if it is documented and operations support it; do not invent
   instant deletion. Add clear in-app links to both pages.
3. **Play store packet.** Prepare listing copy (short/full description that
   matches the selected scope and the current artifact), real release
   screenshots captured from the actual build (no mockups or fabricated
   scores), current feature graphic and icon assets from `design/arena/`,
   target audience, content rating and ads declarations, and the Data Safety
   and Health apps declaration. Explain why "Activity and Fitness" applies;
   never claim medical approval, automatic form scoring, CV verification or
   accuracy that L04 has not signed. Audit reporting/blocking and the support
   process for usernames/avatars. Provide reviewer access that works despite
   email OTP and synchronized two-person battles — design it without
   weakening authentication (for example a documented reviewer account and a
   scripted, consenting two-account session), and never put credentials in the
   repository.
4. **Policy check.** Verify the current official Play requirements for
   account deletion, Data Safety, Health apps and content rating against the
   live policy pages before writing copy. Missing owner identity, retention
   decisions, support address or hosting remain explicitly pending.

## Owner inputs required (ask only for what is missing)

Legal entity name and address, privacy/support contact email, support address,
retention periods for matches/telemetry/backups, hosting destination for the
public pages (L05), Play Console access. If these are absent, complete the
factual local packet (inventory, drafts, code, tests, templates with clearly
marked placeholders) and report BLOCKED with the exact missing inputs — never
publish a fabricated policy or a fake contact.

## Environment (reuse; do not modify D:/Kiro)

```powershell
$env:JAVA_HOME='D:\Kiro\.tooling\jdk17'
$env:PUB_CACHE='C:\Users\ADMIN\AppData\Local\Pub\Cache'
$flutter='D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat'
# from D:\TrainingArena\app
& $flutter analyze; & $flutter test
# backend (local stack must be running; Docker)
supabase db reset; supabase test db --local
& 'D:\Kiro\.tooling\deno\deno.exe' test tests
```

Screenshot capture: rebuild the release-equivalent APK with the selected pilot
flags (camera counting **off** until L04 signs; ranked off), install it on an
emulator/device (the artifact is a non-distributable smoke build), and capture
the real UI with `adb exec-out screencap -p`; keep large captures in gitignored
paths (`qa/integration/screens/`) and record the build SHA-256 with each shot.
Never stage real user data.

## Verification and submission

- Run the analyzer, full Flutter suite, pgTAP and Deno suites relevant to any
  changed code, and `node tools/release/secret_scan.mjs` (+ `--artifacts`).
  Record commands, exit codes and evidence paths under `qa/launch/l07/`; write
  the report to `qa/launch/L07.md`.
- Acceptance (report each PASS/FAIL/BLOCKED): complete factual store packet;
  functional public endpoints after authorized hosting; copy matches the
  selected scope and the current artifact; data inventory traceable to
  schema/code; deletion behavior verified and retry-safe; no fake reviews,
  testimonials, scores or legal statements; no secret-bearing deletion token
  in logs or analytics; reviewer access works without weakening auth.
- Submission must state repository, branch, starting/ending commit, model;
  what changed and the relevant diff; actual commands, exit status, evidence
  paths and skipped checks; per-criterion PASS/FAIL/BLOCKED; remaining
  dependencies and human decisions; measured active time and revised estimate.
- Stop after L07. Do not start L08+ work in this session.
