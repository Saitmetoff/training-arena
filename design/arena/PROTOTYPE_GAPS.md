# Prototype gaps — what intentionally waits for other tasks

Version 1.0.0 · 2026-09-17 · owned by task `01`

The prototype never fakes a backend, camera, install or share result. Every gap
below is visible in the UI as a label, a placeholder or an explicitly simulated
control. Removing the label requires the exit criteria, not a UI tweak.

| # | Gap | Prototype stand-in | Owner | Exit criteria |
| --- | --- | --- | --- | --- |
| 1 | Real authentication (Google / email, redirect, session) | `Continue with Google/email` opens a dialog that says sign-in is simulated and continues as a signed-in viewer | task `05` (redirect/context), task `04` (sessions) | A cold link on a signed-out device completes sign-in and lands on the same challenge without retyping anything |
| 2 | Arena backend (RPCs, requests, match state, receipts) | `js/fixtures.js` data; every screen labelled `Design preview`, panels say `Simulated` | task `04` | `POST /functions/v1/arena` responses replace fixture reads; UI renders only confirmed receipts |
| 3 | Server match clock and five-second countdown | Countdown and 60-second round run locally with a `Simulated` note | task `04` (clock), task `07` (rendering) | Countdown starts from server `starts_at`; both devices agree on the remaining time |
| 4 | Rep counting from the camera | Preparation practice button flips a state; live scores interpolate fixture keyframes | task `03` | On-device pose tracking produces sequenced rep events; no manual entry exists anywhere |
| 5 | 3D athlete demonstration media | `3D demonstration placeholder` frame labelled with task `02` | task `02` | Reviewed push-up and squat animations shipped with poster fallbacks and provenance |
| 6 | Private camera preview and framing guidance | `Camera placeholder` frame with corner brackets and a body outline | task `03` | Live preview with on-device framing feedback; frames never recorded or uploaded |
| 7 | Heartbeat/forfeit and no-result reconciliation | Banners count down; the outcome requires a click on `Simulated: confirm forfeit` | task `04`, task `07` | Server confirms forfeits/no-results; conservative reconciliation on outage |
| 8 | Ranked matchmaking queue | `battle-searching` / `battle-search-timeout` fixtures with a simulated progress bar | task `08` | Real 60 s queue seat with cancel-on-switch; no bots, no "online now" claims |
| 9 | Fastest-friend request notifications | Inbox cards only; notification switch is inert | task `08` | Outbox worker plus platform permission; inbox remains authoritative |
| 10 | Durable links, App Links and install recovery | Landing variants and `Reopen this link after installing` copy; the short code is `9F2K4P` | task `05` | Verified intent filter on the real domain, Play Install Referrer fallback, pending context survives restart |
| 11 | Real public domain and share URLs | `https://example.invalid/c/9f2k4p7q` shown, labelled as a preview host | task `05` (owner supplies domain) | `ARENA_LINK_HOST` points at the real host; links resolve read-only without mutation |
| 12 | System share sheet and QR renderer | `Share challenge` opens a dialog that explains no sheet opens and records nothing; QR block labelled placeholder | task `09` | Real 1080×1920 and 1080×1350 exports, QR encoding the same URL, share-sheet adapter |
| 13 | Result sharing analytics and referral semantics | Copy states that a share-sheet opening is not a referral | task `09` (events), task `05` (link analytics) | Analytics record link opened / request sent / accepted; share-sheet openings are never referrals |
| 14 | Leaderboard and history data | `leaderboard` fixture rows labelled simulated | task `06` | Top-100 plus own position from the leaderboard RPC, with empty and error states |
| 15 | Account management (username claim, avatar, delete, report) | Dialogs explain the action is simulated | task `06`, report API task `04` | Real profile updates, uniqueness checks, deletion, block/report |
| 16 | Haptics, audio cues and native lifecycle | None; motion only | task `07` | Native cues for countdown, last 10 s and result; lifecycle keeps the match id across process death |
| 17 | Device QA evidence | `prototype/screenshots/` state matrix | task `10` | The same matrix captured against the production build on real devices |
| 18 | Baseline contract docs | `docs/CONTRACT.md` and `docs/PROJECT_STATUS.md` were not present when this task ran; assumptions recorded in `docs/decisions/01-design-prototype-interface-note.md` | task `00` | Baseline docs describe tasks `01`–`11` interfaces, including this design system |

## Rules for closing a gap

1. The production implementation replaces the fixture source; it does not add a
   second provider next to it.
2. The label (`Placeholder`, `Simulated`, `Preview`) is removed only together
   with the fake behaviour, never before.
3. New states must appear in `prototype/js/fixtures.js` and
   `design/arena/SCREEN_MAP.md` so task `10` can capture them.
4. If a gap closes with a new token, update `tokens.json` first and rerun
   `node prototype/scripts/check.mjs`.
