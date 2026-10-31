# Interface note 01 — design system and prototype

Date: 2026-09-17
Author: task `01` (design system and clickable invitation prototype)
Status: informational note because the baseline docs were not present

## Why this note exists

`prompts/01_DESIGN_SYSTEM_AND_PROTOTYPE.md` requires reading
`docs/CONTRACT.md` and `docs/PROJECT_STATUS.md` before working. Neither file
exists in this checkout. Task `00` is recorded as **Partial** in
`prompts/README.md`, and `docs/` only contains `API.md`.

`prompts/README.md` says an early chat must inspect the repository and write an
interface note instead of inventing a competing contract. This is that note.
The product contract used here is the non-negotiable list in
`prompts/00_RECONCILE_AND_BOOTSTRAP.md` (app name, scope, bottom navigation,
colour palette, invite-first loop, sign-in requirement, on-device camera, ranked
rating rules) plus `docs/API.md` for data shapes. Nothing in the contract was
guessed beyond those two sources.

## Repository facts observed

- `D:\TrainingArena` is a git repository on branch `codex/training-arena`.
- The working tree contains many staged deletions from the pre-split app
  (`app/` Flutter feature sources, `qa_shots/`, old scripts, old migrations) and
  untracked baseline folders (`app/`, `docs/`, `prompts/`, `supabase/`).
- `app/` contains only `android/`, `assets/fonts/` (Inter 400–900),
  `analysis_options.yaml` and empty `lib/`/`test/` folders. There is no
  `pubspec.yaml` yet; task `00` has not completed the Flutter shell.
- `supabase/migrations/20260917143538_arena_initial.sql` is empty;
  `docs/API.md` is the only written interface contract.
- `D:\Kiro` was not read, opened or modified by this task.

## What this task delivered

- `design/arena/tokens.json` — canonical tokens and required contrast pairs.
- `design/arena/DESIGN_SYSTEM.md` — visual contract, typography, spacing,
  motion, accessibility, copy voice.
- `design/arena/SCREEN_MAP.md` — routes, states, ownership, empty/loading/error
  variants, task `10` screenshot matrix.
- `design/arena/COMPONENT_INVENTORY.md` — component rules for production ports.
- `design/arena/PROTOTYPE_GAPS.md` — deliberately simulated behaviour.
- `prototype/` — dependency-free clickable prototype, fixture switch, check and
  capture scripts, 43 screenshots.

Owned paths: `design/arena/`, `prototype/` only. No production Flutter path,
`docs/API.md`, `supabase/`, or Android manifest was modified.

## Interfaces other tasks can rely on

- Colour/layout/type tokens and their measured WCAG ratios (section 2 of
  `DESIGN_SYSTEM.md`). `line` is decorative only; control boundaries use
  `lineStrong` (`#6F787A`) so they clear 3:1.
- Bottom navigation order Leaderboard · Battle · Profile with Battle default;
  lime = signed-in player/primary action; violet = opponent (screen map and
  component inventory).
- Route names and the state machine in `SCREEN_MAP.md`, including the rule that
  an accepted request never starts a battle unattended.
- Fixture ids for every acceptance state, usable by task `10` as the QA matrix.

## Response to decision D4 (brand mark)

`design/arena/arena-mark.svg`, `arena-mark-mono.svg` and `arena-mark-1024.png`
deliver the provisional arena mark requested from task `01`: charcoal `#17191A`
"A" glyph on a lime `#D6FF3F` rounded tile, transparent 1024px export included.
The prototype rail uses the same glyph. Final art review and launcher/splash
replacement stay open with the platform owner; the mark will not change the
token set.

## Requests to the baseline owner (task `00`)

1. Create `docs/CONTRACT.md` and `docs/PROJECT_STATUS.md` and record the
   contents of this note plus the token set as the authoritative interfaces.
2. Record that `app/` currently has no `pubspec.yaml`; tasks `02`–`09` cannot
   compile until the shell exists.
3. Record the open product values this task could not resolve: the real
   `ARENA_LINK_HOST` domain, the final challenge URL path (`/c/<token>` is
   assumed from `docs/API.md`), and whether the production top bar shows the
   app name on Battle (the prototype keeps the title only, to avoid duplicating
   the desktop rail).
4. When the baseline exists, re-run `node prototype/scripts/check.mjs` from the
   repository root; it fails on drift between `design/arena/tokens.json` and
   `prototype/styles/tokens.css` and on any legacy product terminology.
