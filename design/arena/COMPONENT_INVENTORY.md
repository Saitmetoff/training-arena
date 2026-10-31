# Training Arena component inventory

Version 1.0.0 · 2026-09-17 · owned by task `01`

Implementation-ready rules for every recurring surface. Tokens come from
`design/arena/tokens.json`; prototype markup lives in `prototype/js/app.js` and
`prototype/styles/app.css`. Production implementations (tasks `05`–`09`) should
reuse these rules and map them to Flutter widgets/themes.

Conventions in this document:

- **Tokens** list CSS custom properties; Flutter should consume the same names.
- **Prototype** lists the class names used by the clickable prototype.
- **States** are exhaustive; a production component that cannot render one is
  incomplete.
- Every interactive element has a ≥48×48px target and a visible focus ring.

---

## Buttons

Four kinds plus two composite actions. Exactly one primary action per screen
region.

| Kind | Look | Tokens | Prototype |
| --- | --- | --- | --- |
| Primary | Lime block, ink label, 800 weight | `player`, `playerInk`, `r-md`, 48px + 24px padding | `.btn.btn--primary` |
| Secondary | Raised fill, 1px control border, soft-white label | `raised`, `lineStrong`, `text` | `.btn.btn--secondary` |
| Quiet | Underlined text button, no fill (small fallbacks only) | `textSecondary` → `text` on hover | `.btn.btn--quiet` |
| Danger | Transparent fill, danger border/text | `danger`, `lineStrong`-weight border | `.btn.btn--danger` |
| Hero primary | 104px lime block: title `h2`, helper `small`, ink arrow badge | `player`, `playerInk` | `.action-hero` |
| Secondary action | 76px raised block: opponent-tinted mark, title, helper | `raised`, `opponent/wash` | `.action-secondary` |

Sizes: default 48px min height; `--lg` 72px (single decisive action such as
`I'm ready`, `Accept challenge`, `Share challenge`); block variant fills the
column width. Labels never wrap to more than two lines and never truncate with
an ellipsis.

States: default, hover (slight tint shift, no colour change), focus-visible
(3px `focus` ring, 2px offset), pressed (1px translate), disabled
(`opacity: .45`, `cursor: not-allowed`), busy (label unchanged; a separate
status line explains progress — never a spinner inside a primary button without
text).

Accessibility: real `<button>`/`<a>` elements, `aria-disabled` when a button
must stay focusable to explain why it is blocked (prototype `I'm ready` before
the practice rep), accessible names in sentence case, destructive actions always
confirm through a dialog first.

## Player identity

Anatomy: avatar → `@username` → role label, in a horizontal row. The avatar is
a photo circle or a two-letter monogram tile with a 2px ring.

| Variant | Ring / wash | Role label | Prototype |
| --- | --- | --- | --- |
| Player (you) | `player` ring, `playerWash` fill, `player` text | `you · player` in `player` | `.identity.identity--player` |
| Opponent | `opponent` ring, `opponentWash` fill, `opponent` text | `opponent` in `opponent` | `.identity.identity--opponent` |
| Large | 72px avatar, `h2` username | used on landing, preparation, ready | `.identity--lg` |

Sizes: 48px avatar in rows and score panels, 72px in hero contexts. Usernames
are `h3` (18px) minimum; never truncated below 12 characters without wrapping.

Accessibility: the avatar is decorative (`aria-hidden`) because the adjacent
username is text. Role labels are words, not colours: a colour-blind user must
still know who is who. Where a panel's ownership matters (score panels) the
group is labelled `Your score` / `Opponent score`.

## Score blocks

Used on live and result screens. Anatomy: identity row → value → unit → state
line. Two side-by-side panels and never a table.

| Element | Tokens |
| --- | --- |
| Panel | `playerWash`/`opponentWash` fill, 1px border at 45% of the identity colour, `r-lg`, 16px padding |
| Value | `score` (52px/900) or `display` (72px/900) for the final result, tabular numerals |
| Unit | `small`, `textQuiet` |
| State | `small`, `textSecondary`; becomes the reconnect/outage sentence |

States: `tracking: stable`, `counting paused` (your panel), `reconnecting…`,
`connection lost`, `last confirmed by server`, `forfeited` (result only).
Never show a score without a state line while the round is live.

Accessibility: value carries a full label (`Your score: 26 reps`,
`@zuhra's score: 23 reps`). `role="group"` per panel. Score changes are not
announced on every rep; milestone announcements come from the shared timer
region instead.

## Timer

Anatomy: digits → progress bar → exercise/duration label.

- Digits: `display` size, 900 weight, tabular, centred. Turn `danger` only in
  the last 10 seconds; the digits never animate.
- Bar: 12px, `r-pill`, `surface` track with `line` border, `player` fill that
  shrinks in real time. `role="progressbar"` with `aria-valuenow`.
- Label: `small`, `textSecondary`, e.g. `Push-ups · 60 seconds`.
- Countdown variant: digits count 5 → 1 with a polite live announcement of each
  second; no bar.

Accessibility: `role="timer"` with an updated `aria-label`; milestones at 10 s
and 3 s are announced through one polite region. Under
`prefers-reduced-motion` the fill jumps in steps rather than animating.

## Request card

Anatomy: status chip + time meta → identity → one factual sentence per line →
actions. Used on Battle (incoming) and Inbox (pending, offline, expired, busy).

| Variant | Chip | Primary action | Copy rule |
| --- | --- | --- | --- |
| Pending | `Pending` positive | `Accept challenge` | state the exercise, mode, duration, expiry |
| Incoming (Battle) | `Incoming request` opponent | `Accept challenge` | same as pending, larger identity |
| Offline challenger | `Challenger offline` warning | `Send live challenge` | say both must be available; no replay promise |
| Expired | `Expired` neutral | `Challenge @user again` quiet | say nothing was created |
| Busy player | `In a battle` warning | `Send request` | say accepting unlocks when they finish |
| Empty inbox | — | `Challenge a friend` primary | one sentence, one action |

Rules: Accept is always primary and lime; Decline is always secondary. The
expiry or received time is `meta` (quiet) and never the headline. A request card
never shows a score or an avatar-only action.

Accessibility: the section is labelled `Request from @username`; the two
actions are sibling buttons in source order Accept → Decline; status chips
include text so warning/neutral is not colour-only.

## Camera status

Anatomy: status chip → one-sentence explanation → optional single action.
Used before and during the round; it is the only place that reports tracking.

| State | Colour | Copy |
| --- | --- | --- |
| Ready/preview | neutral chip | `Camera placeholder` in the prototype; production shows live framing guidance |
| Stable | `positive` | `Tracking and connection stable` + what is being counted |
| Your tracking lost | `warning` | counting is paused, clock continues, offer re-scan |
| Opponent reconnecting | `warning` | recovery window and what happens on expiry |
| Opponent lost | `danger` | 10-second forfeit window, server confirms the outcome |
| Service outage | `danger` | no result, no rating change, retry or end |

Rules: never show a fake preview feed, fake skeleton overlay or a "detecting…"
state that cannot resolve. The demo placeholder and camera placeholder are
explicitly labelled as placeholders until tasks `02` and `03` land.

Accessibility: the banner is text with an icon that is `aria-hidden`; a state
change updates the same region rather than stacking new banners. Actions use
`alert`-free copy and stay reachable at 200% text size.

## Result card

Anatomy: perspective headline → two score panels → meta chips (exercise and
mode) → confirmation note → share action → receipt details (collapsible).

- Headline: `I beat @user by N` / `@user beat me by N` / `Draw — N each` /
  `No result`. Win headline uses `player`, loss uses `opponent`, draw and
  no-result use `text`.
- Meta: `exercise · 60 seconds` chip; `Casual · rating unchanged` or
  `Ranked · 1042 → 1058` chip.
- Confirmation: one sentence that the receipt is server-confirmed and
  immutable; no confetti, no "victory" banner, no sound cue.
- Share: single primary `Share challenge`; copy states that sharing creates a
  new challenge and never replays the match.
- Receipt details: collapsible `dl` with receipt id, exercise, mode, confirmed
  time and source.

Accessibility: the headline is the screen `h1`; score panels carry the same
labels as live; `details`/`summary` is keyboard operable; the report action is a
quiet destructive-styled button that opens a dialog.

## Bottom navigation

Anatomy: three items — `Leaderboard`, `Battle`, `Profile` — with `Battle`
centred and selected by default. Labels are always visible under the icons.

| Mode | Behaviour |
| --- | --- |
| Mobile (<900px) | Fixed bottom bar, 64px + safe area, 12px uppercase labels |
| Desktop (≥900px) | 248px left rail with the same three items, selected item gets `playerWash` |

Rules: never more than three items, never icon-only, never a floating action
button that competes with the challenge hero. The selected item uses lime text
plus `aria-current="page"`; unselected items are `textQuiet`. Hidden
non-current items are not used to fit more destinations.

Accessibility: two `<nav aria-label="Primary">` elements exist (rail and bottom
bar) but only the visible one is in the accessibility tree; each item's target
is ≥48px; the order is always Leaderboard → Battle → Profile.

## Supporting components

| Component | Prototype | Rules |
| --- | --- | --- |
| Status chip | `.chip`, `.chip--positive/warning/danger/player/opponent` | pill, 14px/700, dot + word; never the only signal |
| Banner | `.banner--positive/warning/danger` | icon + title + body + up to two actions; replaces, never stacks |
| Media frame (demo/camera) | `.media-frame`, `.camera-guides` | 3:4 or 4:3 viewport, explicit `Placeholder` tag, private-device footnote |
| Score/share card | `.share-card--story/feed` | 9:16 and 4:5 exports, safe area, sharer left lime, opponent right violet. A result-based card and its back path follow the source receipt: a loss shows the loss, and a no-result source renders a new-challenge card that claims no win, loss or draw |
| List row | `.list-row`, `.list-row--you` | rank, identity, rating; own row uses `playerWash` |
| Dialog | `.dialog__card` | `role="dialog"`, `aria-modal`, focus trap, Escape closes, destructive confirm |
| Preview panel | `.panel__card` | dev-only; fixture select + 200% text and round-speed switches |
| Skeleton | `.skeleton` | inbox loading only; static under reduced motion |
| Empty state | `.card--quiet` | one sentence + one action, never an illustration |
