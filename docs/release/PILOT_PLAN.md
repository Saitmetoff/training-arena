# Training Arena solo and friend beta

## Launch review update — 21 October 2026

Current findings, checks and blockers: [launch review](../audit/LAUNCH_REVIEW_2026-10-21.md).
This dated update supersedes the acquisition instructions in section 6 below.
Those instructions predate the owner's continuous-source video requirement.

The recommended first delivery is the existing **free, Android, signed-out,
self-reported solo beta**. Friend battles are a later gate while camera and
hosted round validation remain unresolved. This is a recommendation for review,
not permission to distribute, enable billing or waive failing checks. Do not
make 30,000 waitlist members, a new website, push, ranked play or subscriptions
prerequisites for learning from a small usable beta. The current signed workflow
still prepares links and requires hosted configuration; it is not yet an
independent offline-only release pipeline.

Development commands (from the repository root):

```powershell
# Working local solo path; no account, backend credentials or fixtures required.
rtk proxy powershell -NoProfile -File tools/run-dev.ps1 -Device <device-id>
# Real ports, not fixture opponents. Supply URL and public key via environment.
# ARENA_SUPABASE_URL, ARENA_SUPABASE_ANON_KEY
# Google OAuth also needs ARENA_AUTH_REDIRECT_URL; email OTP does not.
rtk proxy powershell -NoProfile -File tools/run-dev.ps1 -Mode Backend -Device <device-id>
# Physical diagnostic session only; not release validation by itself.
rtk proxy powershell -NoProfile -File tools/run-dev.ps1 -EnableCameraCounting -EnableCameraTrace -Device <device-id>
# Explicit design review fixtures, never evidence of a real battle.
rtk proxy powershell -NoProfile -File tools/run-dev.ps1 -Mode Fixtures -Device <device-id>
```

The source-video brief is **one continuous natural 60-second actor-only take**,
which the owner edits into an approximately 20-second ad. The actor is an adult
white blond man doing confident push-ups, then looking upward toward the future
app/opponent insert and reacting with surprise at losing. The owner adds the
app footage and meme “I got this” sound during editing. Raw source contains no
app, phone, interface, captions, voiceover, music, dialogue or endcard. A model
must demonstrate duration, motion fidelity, repeatability, rights and an
approved budget before a generation workflow is chosen. An eight-second clip
or stitched short clips do not meet this requirement. The owner cannot record
or publish themselves: use a consenting third-party performer or appropriately
licensed footage. No paid generation or guaranteed virality is assumed.

An actor's reaction insert can illustrate a future battle concept with honest
development disclosure; it cannot demonstrate a currently available camera
battle or verified counting accuracy. First-user measurement should follow the
actual solo path and the existing confirmed waitlist funnel.

Updated 2026-09-30 from the owner-approved beta plan. Entry gates remain open:
two physical phones, hosted Supabase/auth, real public domain/legal page values
and release signing. The local checks do not close those gates.

## 1. Release promise and scope

> Practice on your own. Challenge a friend to a 60-second battle.

Ordinary launches put **Start solo set** before friend challenges. Incoming
challenges and active matches retain priority. Signed-out solo needs no account;
self-reported entry stays labelled and never reaches a competitive score.
Seven-day history and personal bests are local; compare the same exercise and
counting source. The first beta is free, Android first and English.

Pins: solo, links and sharing **on**; ranked, push, preview fixtures and trace
export **off**. Camera remains off until reviewed two-phone evidence matches
the candidate app sources. A camera-off beta supports solo practice with
self-reported entry, but cannot complete camera-counted friend battles.
Bosses, clans, currencies, extra exercises and subscriptions are out of scope.

## 2. Entry gates

| Gate | Completion evidence | Current state |
| --- | --- | --- |
| First session | signed-out solo above notices; reliable save/restart; failed save never says Saved | automated checks pass; phone walkthrough pending |
| Camera | Redmi 10 + second phone, every scenario below, reviewed counts and resolved discrepancies | blocked; `qa/camera/beta_device_results.json` |
| Hosted battle | two real accounts sign in, invite, accept, prepare, ready and receive identical confirmed results | unconfigured; local HTTP smoke only |
| Public pages | real challenge/privacy/support/deletion domain and verified App Links | domain and legal/contact inputs missing |
| Signing | committed checkpoint; signed APK/AAB; version, flags, commit and hashes recorded | release keystore/CI secrets missing |
| Existing release gates | media review, tests/analyzer, backend/web checks, identity, bundle, flags and secrets | see `RELEASE_CHECKLIST.md` and `GO_NO_GO.md` |

Distribution follows these gates. Prefer a Play test track once Console allows
it. A signed direct APK can support an identified private pilot, but cannot
validate Play Install Referrer. Debug-signed and unsigned artifacts never go
to testers. For qualifying new personal Play accounts, document approval does
not replace the closed-test requirement: at least 12 testers opted in
continuously for 14 days before applying for production access.
[Google's testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)

## 3. Recruit and support

- Recruit **20 adult Android testers in 10 pairs** while preparing the build.
  The blank, pseudonymous roster is `qa/beta/tester-roster.csv`; keep contact
  details outside the repository. Recruitment has not been performed.
- Plan **two 30-minute casual battle windows each week**. Confirm times with
  pairs in their timezone before announcing them. Ranked stays off; friends
  use direct challenges and the authoritative in-app inbox.
- Use one support organizer and one backend owner per window. Pin the actual
  build version/hash, scope, installation method and recovery steps.
- Stop distribution on reproducible false counts, crashes, lost invitations,
  inconsistent receipts or exposed private data. Investigate each discrepancy;
  do not hide failures in an average or tune thresholds without device traces.

## 4. Validation on both phones

Record device/model/Android, tested commit, APK hash and human vs app counts.
Use `qa/camera/device_validation_checklist.md` and the development trace
runsheet. Images remain on device; only voluntarily exported numeric traces
may be replayed in C05. Release trace export stays off.

1. Preview/analysis crop, rotation, mirroring and skeleton alignment.
2. Side/front push-ups and side squats; partial framing with the signal chain
   visible; too-close guidance while readable practice completes.
3. Low light, low-confidence chain, missing signal joint, half depth, bounce,
   sag/collapse, tracking loss and recovery. Preserve counting protections.
4. Permission denial, Settings return, background/resume, offline solo,
   save/restart and a failed save retaining its result and retry action.
5. Cold invitation, installation recovery, sign-in return, code fallback,
   expired invitation, duplicate actions, early readiness and connection loss.
6. Confirm identical results on both phones. Rematch creates a new pending
   request, then a fresh casual match: both accept/prepare/ready again; no old
   score or receipt is reused. Check blocks and busy opponents.

Waiting copy must describe server-confirmed pending, accepted, preparing or
ready states. Never infer that someone viewed an invitation. Account links can
be copied/shared through **My challenge link / code** for recovery.

## 5. Build and release checks

Use the manual `release-candidate` workflow from the committed checkpoint.
It materialises signing from the CI secret store, pins the approved flags,
checks two-phone evidence before enabling camera, verifies public App Links
and artifact identity, and writes `release-candidate.txt` with hashes. Public
build values and exact signing/hosting actions are in `CONFIGURATION.md`.
The workflow produces artifacts; it does not publish to Play.

Run full Flutter tests/analyzer; Deno arena/dispatcher tests; local pgTAP and
HTTP smoke; challenge-web/release regressions; flags, source/App Link identity,
APK/AAB bundle/16 KB checks and repository/artifact secret scans. Record exact
counts and exit codes in the checkpoint evidence. Old L04/L08/F3 hashes are
historical and cannot identify this build.

## 6. Acquisition while review proceeds

The visual production and measurement board is `qa/beta/launch-board.html`.
Prepare **three original edits weekly**, adapted for TikTok, Reels and Shorts:
**lost by one rep**, **first counted set**, **challenge your training partner**.
Generate adult actors exercising and reacting in separate short shots; edit
real app captures into them and label the result **Dramatization**. Do not
invent an accuracy demonstration, customer testimonial or product feature.

Before access exists, invite people to join the Android test with a friend.
After the gated build is available, show solo and the actual invitation path.
Paid advertising stays **zero** for the initial cohort. Scripts are prepared;
no messages, paid generations or social posts have been sent.

## 7. Measurements and exit

| Measure | Source and denominator |
| --- | --- |
| First solo completion | tester-reported completed / attempted first solo sessions; signed-out sessions stay local |
| Practice abandonment | tester reports, started practice attempts with explicit completion/abandonment outcome |
| First confirmed battle | server receipt; separate full `round_complete` from forfeits and no-results |
| Another battle within seven days | server full rounds; include only players whose first round has a complete seven-day observation window |
| Invitation conversion | request acceptance and accepted-request-to-full-round from server; full shared-link funnel needs tester reports and cannot be inferred from share-sheet opens |
| Support complaints | issue log with attempts, build and disposition; avoid counting unreported sessions as complaint-free |

`qa/beta/server-metrics.sql` provides read-only aggregates, with no account or
token output. Run it against the hosted pilot only; local fixtures are not
customer analytics. `qa/beta/observations.csv` starts blank. Do not invent
growth targets from test totals. A receipt is recorded server outcome, not
independent physical exercise verification.

Initial exit evidence: each recruited pair can start solo, recover an invite
and complete a casual battle; at least 20 full confirmed casual rounds across
at least six pairs; no unresolved reproducible discrepancy or stop condition
in the last 48 hours. These are pilot acceptance goals, not observed results.
Choose the next feature from observed friction, then release fixes in small
batches before wider acquisition.
