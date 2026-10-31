# Training Arena screen map

Version 1.0.0 · 2026-09-17 · owned by task `01`

Route, state and ownership map for the clickable prototype. Every route below
exists in `prototype/js/app.js` (`ROUTES`) and is reachable from the prototype
shell; every state is a deterministic fixture in `prototype/js/fixtures.js`.
Production owners are the task numbers from `prompts/README.md`.

## Routes

<!-- routes:start -->
#/battle
#/inbox
#/c/:token
#/c/:token/signin
#/c/:token/install
#/prepare/:matchId
#/match/:matchId/ready
#/match/:matchId/countdown
#/match/:matchId/live
#/match/:matchId/result
#/share/:source
#/profile
#/leaderboard
#/settings
<!-- routes:end -->

| Route | Screen | Purpose | Back / close path | Production owner |
| --- | --- | --- | --- | --- |
| `#/battle` | Battle home | Incoming request, then Challenge a friend, Find an opponent, Join with code | root tab (bottom nav / rail) | task `07` |
| `#/inbox` | Requests | Request inbox with pending, offline, expired, busy, empty, loading and error states | Back to Battle | task `07`, data task `04` |
| `#/c/:token` | Challenge landing | Challenger, exercise explanation, privacy note, one accept action; unavailable-link state | Close to Battle | task `05` |
| `#/c/:token/signin` | Challenge + sign-in | Same challenge context, signed-out variant; returns to the challenge after sign-in | Back to challenge / close to Battle | task `05` |
| `#/c/:token/install` | Challenge + install | Not-installed variant with Play route, reopen instruction and short code | Back to challenge / close to Battle | task `05` |
| `#/prepare/:matchId` | Preparation | Revealed exercise, 3D demonstration placeholder, private camera preview, framing, one unscored practice rep, ready gate | Leave (confirm) to Battle | task `07`, media `02`, camera `03` |
| `#/match/:matchId/ready` | Ready check | Both players' ready state and the unattended-start rule | Cancel (confirm) to Battle | task `07` |
| `#/match/:matchId/countdown` | Countdown | 5-second server-started countdown, no controls except leave | Leave (confirm) to Battle | task `07` |
| `#/match/:matchId/live` | Live round | Timer, two score panels, connection/tracking banner, outage and forfeit handling | Leave (confirm) to Battle/result | task `07`, camera `03`, backend `04` |
| `#/match/:matchId/result` | Result | Confirmed receipt, perspective headline, share challenge | Back to Battle | task `09`, receipt task `04` |
| `#/share/:source` | Share challenge | Preview the exact story/feed card, simulated share sheet, copy link | Back to result (when sharing a result) or Battle | task `09` |
| `#/profile` | Profile | Small account card, challenge link, settings entry | root tab | task `06` |
| `#/leaderboard` | Leaderboard | Deliberately small ranked list with own position | root tab | task `06` |
| `#/settings` | Settings | Username, notifications, privacy statement, delete account | Back to Profile | task `06`, notifications `08` |

Concrete click-through examples (fixture included so reviewers can share URLs):

- Battle with a request: `#/battle?fixture=battle-incoming`
- Friend link, signed in: `#/c/9f2k4p7q?fixture=landing-default`
- Friend link, signed out: `#/c/9f2k4p7q/signin?fixture=landing-signed-out`
- Friend link, not installed: `#/c/9f2k4p7q/install?fixture=landing-not-installed`
- Preparation: `#/prepare/prep-9f2?fixture=prep-revealed`
- Live: `#/match/m1/live?fixture=live-normal`
- Result: `#/match/m1/result?fixture=result-win`
- Share: `#/share/result?fixture=share-result`
- Share after a loss (the card and back link follow the source result): `#/share/result?fixture=share-result&from=result-loss`

### The two-minute friend-link path

`#/c/9f2k4p7q` → **Accept challenge** → `#/prepare/prep-9f2` → **Take 1 practice
rep** → **I'm ready** → `#/match/m1/ready` (opponent confirms, simulated) →
countdown → `#/match/m1/live` (12 s preview round) → `#/match/m1/result` →
**Share challenge** → `#/share/result` → **Start a new challenge** → `#/battle`.

No friend search, no contact import and no code typing are required anywhere on
that path.

## States

The fixture switch (`Preview states` in the header bar, or `?fixture=<id>`) is
the only state control. Switching a state rewrites the address bar so reviewers
and task `10` can share exact views.

| State id | Route | What it demonstrates |
| --- | --- | --- |
| `battle-incoming` | Battle | Request is the first content block; Accept is primary |
| `battle-clear` | Battle | No request; the challenge hero is the only dominant action |
| `battle-searching` | Battle | Ranked search with progress and 60 s limit; friend challenge stays available |
| `battle-search-timeout` | Battle | Explicit stop state with Retry and Challenge a friend |
| `inbox-pending` | Inbox | Accept / decline a live request |
| `inbox-offline` | Inbox | Challenger offline: live challenge only, no async replay |
| `inbox-expired` | Inbox | Expired after 24 h, no match created |
| `inbox-busy` | Inbox | Player in another battle; request can be sent, accept unlocks later |
| `inbox-empty` | Inbox | Empty inbox with one next action |
| `inbox-loading` | Inbox | Loading skeleton rows |
| `inbox-error` | Inbox | Backend failure with a retry (simulated) |
| `landing-default` | `#/c/:token` | Installed + signed in landing |
| `landing-signed-out` | `#/c/:token/signin` | Sign-in first, challenge preserved |
| `landing-not-installed` | `#/c/:token/install` | Install first, reopen link, short code |
| `landing-unavailable` | `#/c/:token` | Revoked / deleted link; no replay promise |
| `prep-revealed`, `prep-squats` | Prepare | Single revealed exercise (random per match) |
| `ready-waiting`, `ready-both` | Ready | Ready gate, no unattended start |
| `countdown` | Countdown | 5 → 1 server countdown |
| `live-normal` | Live | Stable tracking, both scores updating |
| `live-tracking-lost` | Live | Your counting pauses, clock continues |
| `live-opponent-reconnecting` | Live | Opponent recovery window |
| `live-opponent-offline` | Live | Ten-second forfeit window, server-confirmed outcome only |
| `live-outage` | Live | Shared service failure, no-result path, no rating change |
| `result-win`, `result-loss`, `result-draw` | Result | Perspective-aware factual receipts |
| `result-no-result` | Result | No winner, no rating change, reason shown |
| `result-ranked-win` | Result | Ranked receipt with rating before → after |
| `share-new` | Share | New invite card (unknown recipient, no referral) |
| `share-result` | Share | Result-based challenge card, story/feed previews; the card and its back link follow the source result (`from=result-loss` shows the loss). A no-result source card states there is no confirmed result and claims no win, loss or draw |
| `profile`, `leaderboard`, `settings` | separate routes | Deliberately small account surfaces |

### Empty, loading and error coverage

| Screen | Empty | Loading | Error |
| --- | --- | --- | --- |
| Battle | `battle-clear` | tab data loads with the profile; no fake request card is shown | failing profile/inbox leaves Battle usable; errors surface in Inbox |
| Inbox | `inbox-empty` | `inbox-loading` skeleton rows | `inbox-error` with retry, no cached request is silently dropped |
| Challenge landing | n/a (a link always has context) | app resolution is a short silent load | `landing-unavailable` for revoked/expired/deleted |
| Preparation | n/a | media placeholder until task `02` ships | camera placeholder + framing note when task `03` is unavailable |
| Live | n/a | `Reconnecting…` score state | `live-outage`, `live-opponent-offline` banners |
| Result | n/a | receipt poll shows the last confirmed state | `result-no-result` is the honest error outcome |
| Leaderboard | copy in `PROTOTYPE_GAPS.md` (task `06` owns empty state) | skeleton list is a task `06` deliverable | task `06` retry pattern |
| Profile / Settings | username fallback before claim (task `06`) | short silent load | task `06` |

### Runtime state model

```
link/request ──accept──▶ prepare ──practice rep──▶ ready ──both ready──▶ countdown
                                      │                                   │
                                      └── leave (expires 10 min)          ▼
                                                                        live
                                        tracking loss ⇄ reconnect ────────┤
                                        heartbeat lost (10 s) ──▶ forfeit ┤
                                        shared outage ──▶ no result ──────┤
                                                                          ▼
                                                                       result
                                                                          │
                                                            share challenge (new invite)
```

Rules encoded in the prototype and required of the production UI (task `07`):

- An accepted request creates a match immediately, but **countdown and live play
  never start unattended**; both ready checks are required.
- Tracking loss pauses only the affected player's counting; the shared clock
  keeps running.
- A single-player connection loss gets ten seconds to recover; both lost
  heartbeats yield `no_result` with no rating change.
- The UI renders only server-confirmed receipts. Local state never declares a
  winner.

## Ownership

| Path / surface | Owner | Notes |
| --- | --- | --- |
| `design/arena/`, `prototype/` | task `01` | this map, tokens, prototype, checks |
| `app/assets/media/`, `docs/media/` | task `02` | 3D athlete and demonstration media |
| `app/lib/camera/`, Android camera bridge | task `03` | pose tracking, rep state machine |
| `supabase/`, `backend/`, `docs/API.md` | task `04` | RPCs, receipts, match authority |
| `challenge-web/`, `app/lib/linking/`, link manifest | task `05` | landing page, App Links, install referrer |
| account / profile / leaderboard features | task `06` | sign-in continuity, rating, history |
| battle Flutter features, navigation, UI tests | task `07` | implements these screens |
| notifications, matchmaking integration | task `08` | request notifications, ranked queue |
| sharing feature, card renderer, QR | task `09` | story/feed exports |
| `qa/`, integration tests, device evidence | task `10` | uses the screenshot matrix below |
| Flutter shell, `docs/CONTRACT.md`, `docs/PROJECT_STATUS.md` | task `00` | baseline; currently missing (see `docs/decisions/`) |

Shared changes (for example a new token or route) belong in an interface note
under `docs/decisions/` and are applied by the owner of the path.

## Handoff for task `10` — screenshot and state matrix

`node prototype/scripts/capture.mjs` regenerates these exact files into
`prototype/screenshots/`. Mobile captures are 390×844 CSS px, narrow-mobile
captures (`44`–`46`) are 320×720, desktop captures are 1200×900; `50`–`52` are
mobile with the root font size doubled (200% text). `smoke.mjs` also asserts
that Battle, Live and Share cause no horizontal overflow at 320px and at 200%
text on a 320px screen.

| # | File | Route + fixture |
| --- | --- | --- |
| 01 | `01-battle-home-incoming.png` | `#/battle?fixture=battle-incoming` |
| 02 | `02-battle-home-clear.png` | `#/battle?fixture=battle-clear` |
| 03 | `03-battle-ranked-search.png` | `#/battle?fixture=battle-searching&fast=0` |
| 04 | `04-battle-search-timeout.png` | `#/battle?fixture=battle-search-timeout` |
| 05 | `05-inbox-pending.png` | `#/inbox?fixture=inbox-pending` |
| 06 | `06-inbox-offline.png` | `#/inbox?fixture=inbox-offline` |
| 07 | `07-inbox-expired.png` | `#/inbox?fixture=inbox-expired` |
| 08 | `08-inbox-busy.png` | `#/inbox?fixture=inbox-busy` |
| 09 | `09-inbox-loading.png` | `#/inbox?fixture=inbox-loading` |
| 10 | `10-inbox-error.png` | `#/inbox?fixture=inbox-error` |
| 11 | `11-landing-signed-in.png` | `#/c/9f2k4p7q?fixture=landing-default` |
| 12 | `12-landing-signed-out.png` | `#/c/9f2k4p7q/signin?fixture=landing-signed-out` |
| 13 | `13-landing-not-installed.png` | `#/c/9f2k4p7q/install?fixture=landing-not-installed` |
| 14 | `14-landing-unavailable.png` | `#/c/9f2k4p7q?fixture=landing-unavailable` |
| 15 | `15-prepare-pushups.png` | `#/prepare/prep-9f2?fixture=prep-revealed` |
| 16 | `16-prepare-squats.png` | `#/prepare/prep-9f2?fixture=prep-squats` |
| 17 | `17-ready-waiting.png` | `#/match/m1/ready?fixture=ready-waiting` |
| 18 | `18-countdown.png` | `#/match/m1/countdown?fixture=countdown&fast=0` |
| 19 | `19-live-normal.png` | `#/match/m1/live?fixture=live-normal` |
| 20 | `20-live-tracking-lost.png` | `#/match/m1/live?fixture=live-tracking-lost` |
| 21 | `21-live-opponent-reconnecting.png` | `#/match/m1/live?fixture=live-opponent-reconnecting` |
| 22 | `22-live-opponent-offline.png` | `#/match/m1/live?fixture=live-opponent-offline` |
| 23 | `23-live-outage.png` | `#/match/m1/live?fixture=live-outage` |
| 24 | `24-result-win.png` | `#/match/m1/result?fixture=result-win` |
| 25 | `25-result-loss.png` | `#/match/m1/result?fixture=result-loss` |
| 26 | `26-result-draw.png` | `#/match/m1/result?fixture=result-draw` |
| 27 | `27-result-no-result.png` | `#/match/m1/result?fixture=result-no-result` |
| 28 | `28-result-ranked-win.png` | `#/match/m1/result?fixture=result-ranked-win` |
| 29 | `29-share-new.png` | `#/share/new?fixture=share-new` |
| 30 | `30-share-after-result.png` | `#/share/result?fixture=share-result` |
| 31 | `31-profile.png` | `#/profile?fixture=profile` |
| 32 | `32-leaderboard.png` | `#/leaderboard?fixture=leaderboard` |
| 33 | `33-settings.png` | `#/settings?fixture=settings` |
| 34 | `34-preview-panel.png` | Battle + open fixture panel |
| 35 | `35-share-sheet-dialog.png` | Share + simulated share-sheet dialog |
| 36 | `36-join-code-dialog.png` | Battle + Join with code dialog |
| 37 | `37-share-after-loss.png` | `#/share/result?fixture=share-result&from=result-loss` |
| 40 | `40-desktop-battle-home.png` | desktop Battle |
| 41 | `41-desktop-live.png` | desktop Live |
| 42 | `42-desktop-landing.png` | desktop Challenge landing |
| 43 | `43-desktop-result.png` | desktop Result |
| 44 | `44-narrow-battle-home.png` | Battle at 320px |
| 45 | `45-narrow-live.png` | Live at 320px |
| 46 | `46-narrow-result.png` | Result at 320px |
| 50–52 | `50-text-200-battle.png`, `51-text-200-live.png`, `52-text-200-share.png` | 200% text reflow checks |

A screen recording is not required: the route + fixture matrix above is the
same state list task `10` should drive against the production build.
`node prototype/scripts/smoke.mjs` already drives the complete two-minute path
in a real browser and fails on a broken route, an unclosable dialog or a page
exception, so task `10` can start from a known-good path.
