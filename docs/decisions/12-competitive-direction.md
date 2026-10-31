# 12 — Competitive direction: owner directive and defaults

Date: 2026-09-23 · Owner directive: "commit changes and finish all the tasks
in one shot" while the Play closed-test roster is recruited. This record
captures the direction decisions the competitive pack (`prompts/competitive/`)
requires before its tasks can run. Each decision states the option applied,
the evidence, and what would reopen it.

Status: **applied by owner directive; each decision stays reversible until the
store listing locks or a release candidate is signed.**

## D-A — Solo scope: reopen `CONTRACT.md` §1

**Applied:** a solo max-reps mode is in scope. It is local-only and
non-competitive: it never creates a receipt, rating, leaderboard entry or
server match. Manual (self-reported) entry is allowed **for solo only**; the
competitive path keeps the existing ban on manual scoring.

Evidence: every live competitor is solo-playable; the pilot build ships with
camera counting off (R1), so without solo and manual entry a new user has
nothing to do at all (`docs/research/COMPETITIVE_ANALYSIS.md` CA-G2, CA-G6).
Reopens if: the owner rejects solo at review, or manual entry shows up in any
ranked/battle path (a defect, not a policy question).

## D-B — Name and brand

**Applied:** keep "Training Arena" for now. No rename work is performed. The
name collision risk ("Arena" appears in at least five apps in this niche,
analysis CA-G8) is recorded and must be decided before the store listing copy
locks.

Reopens: before `PLAY_STORE_PACKET.md` listing copy is finalized or any store
submission.

## D-C — First pilot camera scope

Beta update, 2026-09-30: the owner approved the solo-first beta plan.
The signed candidate now pins `ARENA_FEATURE_SOLO_MODE=true`; visitors may
start a local, self-reported solo set without signing in. Incoming challenges
and active matches retain priority. Camera counting still requires the signed
two-phone checklist. Ranked, push, preview fixtures and camera trace stay off.
This supersedes the release workflow's former solo-off hold.

**Applied:** camera counting stays off for the pilot (R1 checklist unsigned).
Solo ships with manual entry as the working path; the camera path is
implemented behind the existing `ARENA_FEATURE_CAMERA_COUNTING` flag and is
exercised by tests only.

Evidence: `GO_NO_GO.md` R1/R7, L04 packet not executed. Reopens: when the
device checklist is signed; solo camera counting then needs its own device
evidence before it is claimed.

## D-D — Monetization

**Applied:** the app stays free through validation. No billing code is added.
Intent recorded for later: annual-first plan with a trial, switched on only
after retention evidence (`COMPETITIVE_ANALYSIS.md` §5). Any future mobile
subscription must use Google Play Billing, never Stripe.

Reopens: owner decision after the closed test reports retention data.

## Beta interface additions — 2026-09-30

The approved beta plan adds authenticated `request_rematch {match_id}` →
`{request}`. Participation in a finished match is required; existing pending
requests in either direction are reused. The existing blocks, busy-player,
expiry and acceptance rules apply. Acceptance creates a fresh casual match;
scores, readiness and the old receipt are never reused. The camera bridge adds
numeric preview transformation metadata only. Seven-day solo history and
personal bests reuse local storage and compare the same exercise and source.
No additional remote solo analytics or dependencies are introduced.

## D-E — Screen-time currency mechanic

**Applied:** rejected for now (out of scope, no code). It is a breakout
mechanic in the niche but conflicts with the current product contract and
privacy story.

Reopens: owner request only.

## Consequences for the pack

- `C01` implements solo with both camera and manual paths; manual is allowed
  by this record.
- `C02`/`C03` build on solo results; they must not touch rating, receipts or
  the leaderboard.
- `C07` (clip export) inherits the privacy constraint from the analysis:
  camera frames must not leave the device without an explicit, inventoried
  user-initiated export.
- Nothing in this record authorizes a Play action, deployment or purchase.
