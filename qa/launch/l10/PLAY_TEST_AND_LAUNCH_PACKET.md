# L10 Play closed-test and launch packet

Prepared: 2026-09-21 · Branch: `codex/training-arena` · L10 (OpenCode,
`opencode-go/deepseek-v4.1-flash`) for the owner and coordinator.

Status: **NOTHING WAS UPLOADED, SUBMITTED, APPROVED OR PUBLISHED.** This
packet is the owner-executable runbook for the closed test and the production
launch, prepared against the L08 freeze. Every external stage is blocked on
owner inputs and Console access; the exact missing authorizations are §7.

Current release facts (L08, unchanged by L09/L10 — verified in §0):

| Item | Value |
| --- | --- |
| Freeze | `1de6127` (product tree unchanged since) |
| Unsigned AAB | 89 902 797 B, SHA-256 `9E77C0D4A3F2A723A429289E3AFAE9B8AF36EBDE0F700BD91920F5E0D8AC470A` — **cannot be uploaded** |
| Release-equivalent APK | 91 417 891 B, SHA-256 `E35744806C88DE3160D5A0BB03807D6A9E55748A68255B79B87019447D074CC9`, **debug-signed, non-distributable** |
| Scope if gates close | camera **off**, ranked **off**, push **off**, challenge links on, sharing on, fixtures off |
| Verdict | `docs/release/GO_NO_GO.md` + `qa/launch/L08.md`: **NO-GO**; L10 owns the upload stage |

## 0. Local verification performed by L10

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| No product change since the freeze | `git diff --stat 1de6127..HEAD -- app supabase tools .github challenge-web prototype design docs/privacy` | empty | L08 evidence stands for the current tree |
| Source identity | `node tools/release/check_artifact_identity.mjs` | exit 0 | `qa/launch/l10/identity_source.txt` |
| Repo secret scan | `node tools/release/secret_scan.mjs` | exit 0 | `qa/launch/l10/secret_scan_repo.txt` |

No build, no upload and no Console action was performed. A signed AAB does not
exist (R9), so no track can receive this candidate yet.

## 1. Account, identity and Console prerequisites (owner-executed)

Nothing below can be verified by this executor (no Console access, no browser
tool). Record each result in `qa/launch/l10/console_state.txt` (create at
execution time; no credentials in it).

| # | Check | Where | Evidence to record |
| --- | --- | --- | --- |
| 1.1 | Account **type** (personal vs organization) and identity-verification state | Play Console → account settings | type, verification state, date |
| 1.2 | Package-name registration `app.trainingarena.mobile` | Play Console → app creation | registered date; the 2026-09-20 guidance named **30 September 2026** for package registration — treat as urgent (`LAUNCH_PLAN_2026-09-20.md`) |
| 1.3 | Developer identity / contact details complete | Console settings | yes/no |
| 1.4 | Target-audience, content-rating, ads, Health declarations *not yet submitted* (they come with listing, `PLAY_STORE_PACKET.md` §10) | Console → App content | state per form |

**New personal accounts** created after 2023-11-13 generally need **12 testers
continuously opted into closed testing for 14 days** before production access;
**internal testing does not satisfy this**. [Google closed-test requirement](https://support.google.com/googleplay/android-developer/answer/14151465)
(checked 2026-09-20 in the launch plan). If the account is older/verified and
exempt, record the Console evidence instead of assuming either way.

## 2. Track decision

| Track | Purpose here | Satisfies production-access rule? |
| --- | --- | --- |
| **Internal testing** | First upload after signing: proves Play signing identity, App Links, Google redirect, Install Referrer on a fresh install with ≤ 100 testers, no review wait | **No** — explicitly excluded |
| **Closed testing** | The qualifying cohort: 12 continuously opted in for 14 days; the production-access clock starts at the 12th qualifying opt-in, not at account creation or first upload | **Yes**, if the cohort is maintained |
| **Open testing** | Not used for this pilot | No |
| **Production** | Only after production access is actually granted | — |

Sequence: R9 signing → upload to **internal** → verify install/referrer/links
(§4) → promote the same verified AAB to **closed** → run the 14 days with the
cohort → apply for production access → submission (L08's verified candidate
or its reviewed successor).

## 3. Roster and opt-in plan

- Target **16–24 recruited** to hold **≥ 12 continuously opted in** (dropout
  buffer), adults only, Android 7.0+ (minSdk 24) devices.
- Recruit per the launch plan's channels: friends, university fitness groups
  and small gym communities, with consent; coordinated play windows as in
  `PILOT_PLAN.md` §3. **Do not buy opt-ins.**
- The roster (emails/accounts) is **personal data**: keep it owner-held, never
  in this repository. The repo-side tracker uses tester codes only.
- Opt-in evidence (the clock): the date the 12th qualifying tester is opted in
  and the daily cohort state, recorded in the owner-held roster; a redacted
  copy can be referenced from `qa/launch/l10/` as `tester_cohort.md` with
  counts and dates only.

What the cohort can exercise with the camera-off scope: link install, sign-in
(email OTP), invitation/inbox, accept/decline/expiry, preparation screens,
profile/history/blocking, share text path. It **cannot complete a counted
battle** — a camera-off demo is not a completed battle release
(`qa/launch/L08.md` §3.1). If the owner wants the closed test to validate the
battle loop, the L04 camera/media gate and the L05 hosted stack must close
first; otherwise state the narrower test scope in the production-access
application and in the tester instructions.

## 4. Upload and fresh-install verification runbook (owner/browser + device)

Prerequisite: a **signed** AAB (`CONFIGURATION.md` §3; R9) and a real hosted
stack (`CONFIGURATION.md` §4–6; R2/R3/R16). Then:

1. Upload the signed AAB to **internal testing**; record version
   (`pubspec.yaml` `version:`), versionCode, track, AAB SHA-256, upload-key
   SHA-256 and the Play **app-signing** SHA-256 / SHA-1 from Console → App
   integrity (`qa/launch/l10/upload_record.txt`).
2. On a **fresh device/account**, install *through Play* (remove any sideload
   first), then verify:
   - the installed APK's signer equals the Play app-signing certificate
     (`apksigner verify --print-certs` on the installed split base APK —
     `adb shell pm path app.trainingarena.mobile`), never the upload key;
   - `adb shell pm get-app-links app.trainingarena.mobile` → `verified` for
     the real host; open a real challenge link cold and confirm it opens the
     app;
   - Google sign-in return (if R3 closed) and email OTP return land back on
     the **same pending challenge**, including after process death;
   - Play **Install Referrer**: tap the landing's Play button with
     `referrer=challenge=<token>`, complete install, first launch recovers the
     pending challenge. A sideload cannot prove this (`PILOT_PLAN.md` §4.1).
3. Record the Console-visible outcome verbatim (track, status, review state,
   opt-in count) plus install timestamps and any error text.
4. Then promote the same verified AAB to **closed testing** and start the
   cohort clock when the roster first holds 12 continuous opt-ins.

If any step fails, stop and fix via the process in §5; never edit the
verification record to look successful.

## 5. During the test

- **Stop conditions** are `PILOT_PLAN.md` §7 (counter accuracy — not
  applicable while camera is off; crash rate; auth/link recovery; server
  consistency; notification/data safety). Any stop condition pauses the test
  and pages the owner.
- **Fix path**: one OpenCode writer, reviewed patch, rerun the affected gates
  from `qa/launch/L08.md` §1, then a new signed version for the cohort.
  Prefer fixes that do not force every tester to update mid-window; keep the
  cohort opted in — removing testers restarts the qualifying clock.
- **Feedback/changes ledger** (owner-held; the redacted summary supports the
  production-access application). Columns:
  `id, date, tester_code, app_version, device, android, stage(link|auth|practice|battle|result|share|support), description, severity, reproducible, disposition(fixed_in|accepted|cannot_reproduce), gate_rerun, commit`.
- **Forms and reviewer access**: complete the Console forms listed in
  `PLAY_STORE_PACKET.md` §10 using its §3/§4/§5 answers; reviewer access per
  §8 (dedicated mailbox, two consenting accounts, no auth weakening). The
  still-missing owner values are `PLAY_STORE_PACKET.md` §9.

## 6. Production access and first public release

1. Apply for production access only when the 12/14 cohort requirement is
   actually met; attach the concise feedback/changes ledger. Review duration
   is not guaranteed (Google documents usually ≤ 7 days, sometimes longer).
2. Prepare, for the owner's go/no-go: target **countries** (one initial
   market per the launch plan), **version** (bumped candidate), **listing**
   (variant A — closed-test copy — is the only honest variant while camera
   counting is off; variant B requires L04 sign-off), store assets
   (`PLAY_STORE_PACKET.md` §7), and support contact.
3. First production release is offered to **all users in the selected
   countries**; do not assume percentage rollout or managed publishing is
   available for a first release — verify the actual release screen.
4. Publishing is a separate explicit owner authorization; this executor does
   not publish. If authorized later, record the submission, review outcome
   and actual public availability as separate dated events.

## 7. Exact missing authorization and inputs

1. **R9 signing custody** — keystore + vault + CI secrets, or an explicit
   decision to stay non-distributable (then there is no Play path).
2. **Play Console** — owner access/execution of §1 and §4 on the real account
   and track; no credentials in the repo or chat.
3. **D1/D3 hosted stack + L07 owner values + Google OAuth** — otherwise
   links, referrer and the required public privacy/deletion URLs do not work
   and the forms cannot be submitted (R2/R3/R16).
4. **L04 camera/media decision** — decides whether the closed test can include
   counted battles and which listing variant ships.
5. **Roster** — owner recruits 16–24 testers and approves the play windows.
6. **Countries/language and production-access application authorization** —
   owner decision before §6.
7. **Incident roles** (`INCIDENT_RESPONSE.md` §3) and the R15 incident-control
   decision before real users.

No new monitoring automation was created: use the L05 operations runbook and
the established stop conditions.
