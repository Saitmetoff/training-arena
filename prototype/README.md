# Training Arena prototype

A clickable, keyboard-accessible design prototype for the invite-first push-up
and squat battle app. It is **design preview only**: no network requests, no
camera, no accounts, no share sheet. Every value is simulated from
`js/fixtures.js` and every limitation is labelled in the UI (see
`design/arena/PROTOTYPE_GAPS.md`).

- Visual contract: `design/arena/DESIGN_SYSTEM.md`
- Routes and states: `design/arena/SCREEN_MAP.md`
- Components: `design/arena/COMPONENT_INVENTORY.md`
- Tokens (source of truth): `design/arena/tokens.json`

## Run it

Open `prototype/index.html` in a Chromium browser (double-click works), or serve
the repository root with any static server, for example:

```
npx --yes serve .        # then open /prototype/
```

No build step and no dependencies. Inter loads from `../app/assets/fonts/`;
if the prototype folder is copied elsewhere the system sans-serif fallback is
used and nothing else changes.

## Review the friend-link path in two minutes

1. Start at `#/c/9f2k4p7q` — the challenge landing page.
2. **Accept challenge** → Preparation.
3. **Take 1 practice rep** → **I'm ready**.
4. The opponent confirms (simulated, a couple of seconds) → countdown → live.
5. The 60-second round is compressed to 12 seconds by default → result.
6. **Share challenge** → **Start a new challenge** → Battle home.

No friend search, no contact import and no code typing anywhere.

## Preview states (fixture switch)

Use **Preview states** in the header bar, or add `?fixture=<id>` to the hash:

- `#/battle?fixture=battle-incoming`, `battle-clear`, `battle-searching`, `battle-search-timeout`
- `#/inbox?fixture=inbox-pending`, `inbox-offline`, `inbox-expired`, `inbox-busy`, `inbox-empty`, `inbox-loading`, `inbox-error`
- `#/c/9f2k4p7q?fixture=landing-default` (signed in), `landing-unavailable`
- `#/c/9f2k4p7q/signin?fixture=landing-signed-out`
- `#/c/9f2k4p7q/install?fixture=landing-not-installed`
- `#/prepare/prep-9f2?fixture=prep-revealed` or `prep-squats`
- `#/match/m1/ready?fixture=ready-waiting` or `ready-both`
- `#/match/m1/countdown?fixture=countdown`
- `#/match/m1/live?fixture=live-normal`, `live-tracking-lost`, `live-opponent-reconnecting`, `live-opponent-offline`, `live-outage`
- `#/match/m1/result?fixture=result-win`, `result-loss`, `result-draw`, `result-no-result`, `result-ranked-win`
- `#/share/new?fixture=share-new`, `#/share/result?fixture=share-result`
  (add `&from=result-loss` to preview the card and back link after a loss)
- `#/profile?fixture=profile`, `#/leaderboard?fixture=leaderboard`, `#/settings?fixture=settings`

Extra preview switches:

- `fast=0` — run the full 60-second round instead of the 12-second preview round
  (used for live captures). The compressed timing is preview-only.
- `zoom=200` — double the root font size to check 200% text reflow.

Switching a state rewrites the address bar, so any view can be shared with a
reviewer or task `10`.

## Keyboard and accessibility

- `Tab` follows visual order; a **Skip to main content** link is first.
- Every route change moves focus to the screen heading.
- Dialogs and the preview panel trap focus, close on `Escape` and return focus
  to the trigger.
- `I'm ready` before the practice rep uses `aria-disabled` and stays focusable
  so keyboard users hear why it is blocked.
- Scores, the timer and status banners carry text labels; colour is never the
  only signal.

## Checks and screenshots

```
node prototype/scripts/check.mjs      # contrast, token parity, route/fixture/naming checks
node prototype/scripts/smoke.mjs      # drives the two-minute path in a real browser (55 checks)
node prototype/scripts/capture.mjs    # regenerate prototype/screenshots/ (47 files)
node prototype/scripts/capture.mjs --only=result
```

The browser scripts need Node 21+ (built-in `WebSocket`) and a local Chromium
browser; set `ARENA_BROWSER=<path to exe>` when it is not in a default location.

`check.mjs` fails if any documented contrast pair drops below its WCAG minimum,
if `styles/tokens.css` drifts from `tokens.json`, if a colour literal appears
outside the token set, if a route or required fixture is missing, or if legacy
product terminology returns.

`smoke.mjs` fails if the friend-link path breaks, if a dialog cannot be closed
with `Escape`, if the skip link is not the first tab stop, if a result-based
share card or its back link loses the source result, if any screen overflows
horizontally at 320px or at 200% text, or if the page logs an uncaught
exception.

## File layout

```
prototype/
  index.html                 shell: preview strip, nav rail, bottom nav, skip link
  styles/tokens.css          mirror of design/arena/tokens.json
  styles/app.css             component styles, responsive layout, motion
  js/fixtures.js             deterministic states (profiles, link, timelines, fixtures)
  js/app.js                  hash router, screens, actions, dialogs, live simulation
  scripts/check.mjs          design-system guardrails
  scripts/cdp.mjs            dependency-free DevTools-protocol client
  scripts/smoke.mjs          clickable-path smoke test
  scripts/capture.mjs        screenshot matrix (no dependencies)
  screenshots/               captured state matrix for task 10
README.md                    this file
```

## What is simulated (short list)

Sign-in, install, backend data, request delivery, camera counting, the opponent,
the round clock, the share sheet and the QR. All of it is labelled where a
reviewer sees it. Do not treat any score or receipt here as evidence.

## Changing the prototype

1. Update `design/arena/tokens.json` first, then the docs, then
   `styles/tokens.css`.
2. Add new states to `js/fixtures.js` and to `design/arena/SCREEN_MAP.md`.
3. Run `node prototype/scripts/check.mjs` and refresh the screenshots.
