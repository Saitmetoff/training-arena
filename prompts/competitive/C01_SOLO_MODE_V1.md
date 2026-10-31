# C01 — Solo mode v1: max-reps session

Depends on: C00 (D-A and the manual-entry answer). Estimate: 8–16 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `tdd` first — write the session/state-machine tests before the UI.
- `implement` — keep the change inside the recorded spec.

## Goal

Give a new user a complete first value moment with no second person and no
ranked queue: start a solo max-reps set, count it (camera when available,
manual only if C00 allows it), show the result, and keep the personal result
locally. This is the activation path the analysis says does not exist today
(CA-G2), and it doubles as the honest demo format while the camera gate (R1)
is unresolved.

Scope:

1. A solo session domain model and state machine, pure Dart, no platform
   calls; injectable clock and runtime, matching the existing battle
   controller patterns (`app/lib/battle/battle_controller.dart`).
2. A minimal UI entry on the Battle tab: "Solo set" → countdown → live count →
   result → "again". Reuse the existing camera preview and rep badge; do not
   fork the camera pipeline.
3. Local persistence of the personal result (best set, last set, total
   sessions) using the existing local storage approach. No server, no
   leaderboard, no rating change, no receipt.
4. A feature flag in `app/lib/config/arena_config.dart` following the existing
   `ARENA_FEATURE_*` pattern, and the matching entry in
   `tools/release/check_release_flags.mjs` and its docs.

## Owned paths

`app/lib/solo/` (new), minimal additions to `app/lib/domain/`,
`app/lib/config/arena_config.dart`, `app/lib/battle/ui/battle_tab.dart` entry
only, `app/test/solo/` (new), `tools/release/check_release_flags.mjs` flag
list, `docs/` note for the interface. Reuse, do not modify, camera files
except where a new read-only hook is genuinely needed — if so, write an
interface note first.

## Must not

- Touch ranked, matchmaking, receipts, Elo, battle history or result sharing.
- Change any camera threshold or counting behaviour (that is C05).
- Add a dependency without a one-line justification and an owner-visible note.
- Imply competitive validity: a solo set never creates a receipt, rating or
  leaderboard entry, and the UI must say so.
- Claim accuracy percentages in any copy.

## Acceptance

- `flutter analyze` clean; the full existing suite still passes (459+ at the
  last freeze) plus the new solo tests.
- The solo flow completes end to end on an emulator with camera counting off
  (manual path per C00) and with it on (counted path), evidence recorded under
  `qa/competitive/c01/`.
- A solo set leaves no server state: query the local stack and show that no
  match/receipt/rating row was created.
- Flag off = no solo entry visible, with a test proving the refusal path.
- No forbidden claims in user-facing strings (see preamble truth rules).

## Handoff

Standard handoff, including the flag name and its release value.
