# Training Arena design system

Version 1.0.0 · 2026-09-17 · owned by task `01` (`design/arena/`, `prototype/`)

This is the visual contract for the invite-first push-up and squat battle app.
It replaces the earlier loose visual direction. Production code (tasks `05`–`09`)
must consume these tokens and component rules instead of inventing a second
palette or a second navigation model.

Single source of truth: **`design/arena/tokens.json`**
Human mirror: `prototype/styles/tokens.css`
Enforcement: `node prototype/scripts/check.mjs`

> Change order: `tokens.json` → this document → `prototype/styles/tokens.css` → prototype screens → run the check script.

---

## 1. Principles

1. **The challenge is the first action.** On Battle, the largest element is
   *Challenge a friend* (lime). Ranked matchmaking is second. Code entry is a
   small fallback. Nothing competes with the primary action.
2. **Two identities, two colours, never more.** Lime `#D6FF3F` is always the
   signed-in player and the primary action. Violet `#BEA1FF` is always the other
   person. No third accent, no success-green identity, no gradient.
3. **Bold blocks over decoration.** Large type, flat surfaces, hairline borders,
   generous spacing. No gradients, glows, drop shadows, or texture.
4. **Numbers are the drama.** Reps, timer and rating use the heaviest Inter
   weights with tabular figures. Everything else stays quiet.
5. **Honest states.** The UI never implies a result, a referral, a replay or a
   camera reading that does not exist. Simulated data is labelled as such.

## 2. Colour tokens

| Token | Hex | Role | Stable meaning |
| --- | --- | --- | --- |
| `canvas` | `#17191A` | app background, media viewport | never used for text |
| `surface` | `#242729` | bars, nav, dialogs, sheets | chrome and grouped content |
| `raised` | `#303537` | cards, list rows, inputs | interactive content blocks |
| `line` | `#3B4245` | decorative 1px dividers | non-text, no contrast claim |
| `lineStrong` | `#6F787A` | control and input boundaries | must stay ≥ 3:1 |
| `player` | `#D6FF3F` | you, primary actions, own score, live | reserved for the signed-in player |
| `playerInk` | `#17191A` | text/icons on lime | primary button label |
| `playerWash` | `#2A2F1B` | own panel background | never used for opponents |
| `opponent` | `#BEA1FF` | the other person, their score | reserved for the opponent |
| `opponentInk` | `#17191A` | text/icons on violet | opponent identity chip |
| `opponentWash` | `#2B2637` | opponent panel background | never used for the player |
| `text` | `#F6F7F2` | primary copy | |
| `textSecondary` | `#B6BDB9` | body and helper copy | |
| `textQuiet` | `#9BA59E` | meta copy, timestamps | never critical information |
| `positive` | `#7AE5A0` | connected, confirmed, ready | status only, never identity |
| `warning` | `#FFD66E` | reconnecting, waiting, caution | status only |
| `danger` | `#FF807C` | tracked-out, outage, destructive | status and destructive actions |
| `focus` | `#F6F7F2` | focus ring | 3px, 2px offset |
| `overlay` | `rgba(23,25,26,0.78)` | modal and sheet scrim | |

Rules:

- Colour is never the only signal. Every score panel also carries a name and a
  role label (`you · player`, `opponent`), every status chip carries text.
- Lime and violet may not be used for warnings, errors, notification counts or
  decorative shapes.
- Do not add colours for charts, promoted content or ranking medals. The
  leaderboard ranks are plain numbers.

## 3. Typography

Family: **Inter** (bundled at `app/assets/fonts/`, weights 400–900). Fallback
stack: system UI sans-serif. No display or serif faces.

| Token | px / rem | Weight | Line height | Tracking | Usage |
| --- | --- | --- | --- | --- | --- |
| `display` | 72 / 4.5rem | 900 | 0.9 | −0.03em | live timer digits, final score digits |
| `score` | 52 / 3.25rem | 900 | 0.95 | −0.02em | live score panels, countdown digits |
| `h1` | 34 / 2.125rem | 800 | 1.1 | −0.02em | screen title, result headline |
| `h2` | 24 / 1.5rem | 800 | 1.2 | −0.01em | card title, hero button title |
| `h3` | 18 / 1.125rem | 700 | 1.3 | 0 | component title, username |
| `body` | 16 / 1rem | 500 | 1.5 | 0 | body copy |
| `small` | 14 / 0.875rem | 500–700 | 1.45 | 0 | helper copy, chips, meta |
| `micro` | 12 / 0.75rem | 700 | 1.3 | 0.08em | uppercase kickers and nav labels only |

Numeric style:

- All digits use `font-variant-numeric: tabular-nums lining-nums` so scores do
  not jitter while counting.
- Scores are displayed at `score` or larger, always with the unit `reps` in
  `small` next to them, and an accessible label that includes the number
  (`Your score: 26 reps`).
- The timer never animates its digits; the bar communicates motion.
- No text smaller than 12px. No condensed or thin weights. No italics.

## 4. Spacing, layout and shape

- Spacing scale (px): `4, 8, 12, 16, 24, 32, 48, 64` (`--s-1`…`--s-8`).
  Cards use 24px padding, screen gutters use `clamp(16px, 5vw, 24px)`.
- Radius: `10px` small, `14px` controls, `20px` cards, `999px` pills.
  Nothing is fully square; nothing is a bubble except avatars and pills.
- Layout: one column, max 560px, centered below 900px. At 900px and above the
  bottom navigation becomes a 248px left rail and content widens to 1040px with
  two-column grids where a screen has a natural pairing (request + actions,
  scores + scores, demo + camera).
- Minimum touch target: 48×48px, including icon buttons and nav items.
- Safe spacing: no text closer than 16px to a screen edge or card edge; scores
  and timer keep ≥24px of clear space.
- Elevation is expressed only by surface steps (`canvas` → `surface` → `raised`)
  plus a 1px border. No shadows.

## 5. Components

Full anatomy, states and accessibility notes live in
`design/arena/COMPONENT_INVENTORY.md`. Component rules in one line each:

- **Primary button**: lime block, `playerInk` label, 48px min height, 800 weight.
  One per screen region. Never outline a primary action.
- **Secondary button**: `raised` fill, `lineStrong` border, soft-white label.
- **Quiet action** (`Join with code`): underlined text button, 48px target.
- **Destructive action**: transparent fill, `danger` border and text, always
  paired with a confirmation dialog.
- **Action hero** (`Challenge a friend`): 104px lime block with title + helper
  and an ink arrow badge; the only element allowed to be that large.
- **Player identity**: avatar (photo or two-letter monogram) + `@username` +
  role label; lime ring/panel for you, violet ring/panel for the opponent.
- **Score panel**: identity + big number + `reps` + state line; `playerWash` for
  you, `opponentWash` for the opponent.
- **Timer**: `display` digits + 12px progress bar + exercise label. Digits turn
  `danger` in the last 10 seconds; no other colour change during a round.
- **Request card**: status chip + expiry/received meta + identity + one fact per
  line + actions. Accept is primary; decline is secondary.
- **Camera status**: chip + one sentence + optional action. `positive` for
  stable, `warning` for reconnecting, `danger` for lost/outage. Never a fake
  progress bar.
- **Result card**: perspective headline + two score panels + exercise/duration +
  mode chip + one share action. Factual, no confetti and no "you win!" banner.
- **Bottom navigation**: Leaderboard · Battle · Profile, Battle centred and the
  default. Current item is lime with `aria-current="page"`; labels are always
  visible (no icon-only navigation).

## 6. Motion

| Token | Value | Use |
| --- | --- | --- |
| `fast` | 120ms | button press, hovers |
| `base` | 180ms | switches, chips, state changes |
| `slow` | 260ms | screen entry |
| easing | `cubic-bezier(0.2, 0, 0, 1)` | all transitions |

Rules:

- Motion explains state: countdown digits, timer bar, score increments,
  reconnecting pulses. Nothing bounces, floats or parallaxes.
- No animation exceeds 300ms except the timer bar, which tracks real time.
- `prefers-reduced-motion: reduce` removes entrance transforms and pulses; state
  changes stay instant and legible.
- Never animate numbers themselves; animate the bar or the panel border.

## 7. Accessibility

Measured WCAG 2.1 contrast (verified by `prototype/scripts/check.mjs`):

| Foreground | Background | Ratio | Required | Use |
| --- | --- | --- | --- | --- |
| `text` | `canvas` | 16.39:1 | 4.5 | body copy |
| `text` | `raised` | 11.54:1 | 4.5 | body copy on cards |
| `textSecondary` | `raised` | 6.49:1 | 4.5 | helper copy on cards |
| `textQuiet` | `raised` | 4.89:1 | 4.5 | meta copy on cards |
| `player` | `canvas` | 15.32:1 | 4.5 | player identity, links |
| `playerInk` | `player` | 15.32:1 | 4.5 | primary button label |
| `opponent` | `canvas` | 8.17:1 | 4.5 | opponent identity |
| `opponent` on `opponentWash` | wash | 6.78:1 | 4.5 | opponent panel |
| `positive` | `canvas` | 11.38:1 | 4.5 | connected state |
| `warning` | `canvas` | 12.68:1 | 4.5 | reconnecting state |
| `danger` | `canvas` | 7.25:1 | 4.5 | tracking loss, outage |
| `lineStrong` | `surface` | 3.32:1 | 3.0 | input boundaries |

Requirements:

- **Focus**: 3px `focus` ring with 2px offset on every interactive element;
  never remove it. On lime surfaces switch the ring to `canvas`.
- **Keyboard**: full tab order follows visual order; dialogs and the preview
  panel trap focus and close on `Escape`; every route change moves focus to the
  screen `h1` (`tabindex="-1"`); a skip link precedes the shell.
- **Screen readers**: score panels use `role="group"` with a labelled value
  (`Your score: 26 reps`); the timer uses `role="timer"` and milestones
  (10 s, 3 s) are announced through one polite live region; status banners are
  text, not icons alone.
- **Text scale**: layout must reflow at 200% text size with no horizontal
  scrolling, no clipped labels and no overlapping text. The prototype ships a
  preview switch that doubles the root font size for this check.
- **Colour independence**: every colour-coded state also has a word.
- **Reduced motion** and **reduced transparency** are respected; the scrim is
  the only translucent surface.

## 8. Copy voice

Voice: direct, calm, factual, second person. Short sentences. Verbs first in
actions. No hype, no exclamation marks, no emoji, no "epic"/"insane"/"smash".

| Situation | Write | Avoid |
| --- | --- | --- |
| Primary action | `Challenge a friend` | `Invite & crush your friends!` |
| Waiting | `Waiting for @zuhra. Nothing starts until you both confirm ready.` | `Get hype, battle starting soon!` |
| Result | `I beat @zuhra by 3` / `@zuhra beat me by 5` / `Draw — 24 each` | `VICTORY!`, `You crushed it` |
| No result | `No result. The service was unreachable, so no rating changed.` | `Something went wrong 😅` |
| Sharing | `Sharing starts a new challenge. It never replays this match.` | `Rematch and beat this score!` |

Hard rules:

- Never imply that opening a share sheet is a referral, that a link stores or
  replays a match, that an old score can be beaten asynchronously, or that a
  battle can start without both players present.
- Never display a score, winner or rating that has not been confirmed by the
  server. Prototype fixtures are labelled `simulated`.
- Exercise names are `Push-ups` and `Squats`. No other exercise exists.
- Every pre-split legacy product name and package identifier is banned from
  design artifacts. `prototype/scripts/check.mjs` fails the build when one
  reappears.

## 9. Brand mark (provisional, assigned to task `01` by decision D4)

Files: `design/arena/arena-mark.svg` (charcoal "A" on lime tile),
`design/arena/arena-mark-mono.svg` (lime on charcoal) and
`design/arena/arena-mark-1024.png` (transparent 1024px export for launcher and
store work).

Rules: 16px radius on a 64px tile, 9px strokes with round joins, charcoal
`#17191A` on lime `#D6FF3F` only. The mark must stay legible at 16px and must
not gain gradients, shadows or a second colour. The prototype rail uses the
same glyph. Platform launcher/splash replacement belongs to the platform task;
final art review is still open, so the files are labelled provisional.

## 10. What this system forbids

- Gradients, glassmorphism, neon glows, drop shadows, background photos.
- More than two accent hues, or lime/violet used decoratively.
- Text below 12px, uppercase for anything but kickers/nav labels, letter-spaced
  body copy.
- Dashboards: more than four blocks on Battle before scrolling, more than one
  primary action per screen region.
- Fake progress: spinners that never resolve, counters that tick without a
  source, "live" players who are bots.

## 11. Files and checks

| File | Purpose |
| --- | --- |
| `design/arena/tokens.json` | canonical tokens + contrast requirements |
| `design/arena/DESIGN_SYSTEM.md` | this document |
| `design/arena/SCREEN_MAP.md` | routes, states, ownership, variants |
| `design/arena/COMPONENT_INVENTORY.md` | component anatomy and states |
| `design/arena/PROTOTYPE_GAPS.md` | behaviours waiting on other tasks |
| `prototype/` | clickable, keyboard-accessible state prototype |
| `prototype/scripts/check.mjs` | contrast, token parity, route/fixture, naming checks |
| `prototype/scripts/capture.mjs` | deterministic screenshot matrix for task `10` |
