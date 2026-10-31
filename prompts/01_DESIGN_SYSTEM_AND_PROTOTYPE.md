# Task 01 — finish the visual system and clickable invitation prototype

You are the product designer/front-end prototype engineer for Training Arena. Work only in `D:\TrainingArena`, after reading `docs/CONTRACT.md` and `docs/PROJECT_STATUS.md`. Do not edit the production Flutter feature paths owned by other tasks. Do not touch `D:\Kiro`.

## Goal

Replace the sloppy legacy visual direction with a precise, energetic fitness-game system that makes the challenge the obvious first action. Produce both a documented design system and a clickable prototype that another engineer can implement without guessing.

## Visual contract

Use charcoal `#17191A` as the canvas, graphite `#242729` as primary surface, raised `#303537` for cards, lime `#D6FF3F` for the signed-in player and primary actions, violet `#BEA1FF` for the opponent, and soft-white `#F6F7F2` for text. Keep lime and violet semantically stable; do not introduce a competing accent palette. Use Inter or the project’s bundled equivalent with a strong numeric style for reps, timer and scores. Prefer bold blocks, generous safe spacing, high contrast and restrained decoration over gradients, tiny labels or dense dashboards.

## Prototype scope

Build a responsive, keyboard-accessible prototype in `prototype/` (or the existing prototype location after inspection) with simulated data clearly marked as design preview. It must be clickable through:

1. Battle home with an incoming request at the top, **Challenge a friend** as the dominant action, **Find an opponent** second, and **Join with code** as a small fallback.
2. Challenge landing page showing the challenger photo/username, exercise explanation, privacy note and one primary action.
3. Signed-out and not-installed landing variants that keep the same challenge context through sign-in/install.
4. Request inbox, offline challenger, expired request and busy-player states.
5. Preparation with one random exercise revealed, 3D demonstration placeholder, private camera preview, framing guidance and one unscored practice rep.
6. Ready/countdown/live/result screens with two score panels, the player in lime, opponent in violet and clear connection/tracking states.
7. Result screen with factual win/loss/draw copy and a prominent **Share challenge** action.
8. Profile, leaderboard and settings kept deliberately small.

Every prototype link must have a visible destination and a back/close path. Do not make the prototype imply that a share-sheet opening is a referral, that a result link replays an old match, or that an unattended battle can start.

## Required deliverables

- `design/arena/DESIGN_SYSTEM.md`: tokens, typography scale, spacing, component rules, accessibility contrast, motion and copy voice.
- `design/arena/SCREEN_MAP.md`: routes, states, ownership and empty/error/loading variants.
- `design/arena/COMPONENT_INVENTORY.md`: buttons, player identity, score blocks, timer, request card, camera status, result card and bottom navigation.
- `prototype/`: working prototype with README and a small deterministic fixture switch for the required states.
- `design/arena/PROTOTYPE_GAPS.md`: any behavior that intentionally waits for backend/camera work.

## Acceptance checks

- A reviewer can complete the friend-link path from landing page to result and back to a new challenge in under two minutes without searching for a friend or typing a code.
- Primary action hierarchy and player/opponent color semantics match the contract at desktop and narrow mobile widths.
- Text remains readable at 200% scale, focus order is usable by keyboard, and all critical states have accessible labels.
- Prototype does not hide missing backend/camera work behind fake success; simulated values are labeled.
- No FitBattle or Blue Steel terminology remains in the new design artifacts.

At handoff, list exact prototype routes and screenshots or a short recording path so task `10` can use the same state matrix.

