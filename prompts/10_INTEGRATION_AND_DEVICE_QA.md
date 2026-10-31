# Task 10 — close the invitation-to-battle integration and device QA gate

You are the integration and quality owner for Training Arena. Work only in `D:\TrainingArena`; inspect all task handoff notes before changing code. Prefer fixes in the owning feature; do not silently rewrite contracts or revive FitBattle files. Never touch `D:\Kiro`.

## Primary acceptance test

A person who has never used Training Arena follows a friend’s link and completes that specific battle without searching for the friend, navigating tabs or re-entering an invitation code on the normal path.

## Test matrix

Exercise both cold and warm links and record evidence for:

- installed/signed-in, installed/signed-out and not-installed recipient;
- auth return, process restart and Play Install Referrer recovery;
- multiple recipients, revoked link, username change, expired request, completed link, blocked user and busy player;
- challenger offline, notification allowed/denied, duplicate notification tap;
- camera permission allowed/denied/permanently denied, no camera, bad framing, tracking loss, practice reset and lifecycle pause/resume;
- both-ready gate, countdown, 60-second round, single-player 10-second recovery, shared service failure and tie;
- empty matchmaking at 15/60 seconds, retry and switch-to-friend cancellation;
- confirmed ranked/casual receipts, history/leaderboard/profile updates and result sharing to destination apps;
- 1080×1920 and 1080×1350 card safe area, URL/QR correctness, copy-link behavior and no raw video export.

## Evidence and checks

- Run analyzer/unit/widget/integration tests and Android API 24+ device tests. Include at least one physical camera device for rep counting; emulator fixtures are supplementary.
- Capture screenshots or recordings for each state, plus logs with tokens/emails redacted. Use OCR/accessibility inspection for critical labels and timer/score readability.
- Verify RLS and adversarial API cases against a local/staging project with fake accounts. Verify retries, idempotency and no double rating.
- Measure `link opened → sign-in completed → request sent → accepted → both ready → battle completed`, first-battle completion time, matchmaking wait and rematch rate. Record share-sheet opening separately from confirmed referral activity.
- Produce `qa/REPORT.md`, machine-readable scenario results and a named list of blockers. Do not mark a simulated fixture as device accuracy or production readiness.

Acceptance requires every failed case to be visible with reproduction steps and owner. Fix all release-blocking failures or hand them to task `11` with explicit risk and an owner decision; never hide a failure by weakening the test.

