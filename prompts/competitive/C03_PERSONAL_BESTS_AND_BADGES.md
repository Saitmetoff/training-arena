# C03 — Personal bests, badges and the stats view

Status 2026-09-23: **implemented as derived badges over the local history.**
Bests/stats shipped with C01/C02; badges are pure functions of the stored
history (no stored awards, no server). Record: `qa/competitive/c03/REPORT.md`.

Depends on: C02 (server activity and streak exist). Estimate: 8–16 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `supabase-postgres-best-practices` — read-model queries and indexes.
- `tdd` — badge rules and idempotent awards are pure logic; test first.

## Goal

Turn the solo record into visible progress without inventing reward economics:
personal bests, a small deterministic badge set and one stats view. This is the
retention layer the leader has, minus the coins, battle pass and spin wheel
(analysis §7 reject list).

Scope:

1. **Bests.** Max set, lifetime reps, sessions, current and longest streak —
   read from the C02 data; no new write path, no separate counters that can
   drift.
2. **Badges.** A short, fixed list (suggest five to eight) with deterministic,
   testable unlock rules, each reachable from real solo activity. Award
   idempotently; no badge may imply a competitive claim or a health claim.
   Suggested shape: first set, first goal day, 7-day streak, 30-day streak,
   lifetime rep milestones. Real numbers only — the owner decides final
   thresholds in C00's record if they are contested.
3. **Stats view.** One screen reachable from the profile: bests, badge grid
   with locked/unlocked states, last 30 days. Reuse the existing design tokens
   (`design/arena/DESIGN_SYSTEM.md`); no new visual language.
4. **Decision.** Badges award server-side (survive reinstall) or locally?
   Default to server-side since C02 data is server truth; record the choice in
   the task's interface note.

## Owned paths

New badge/read-model SQL in the gateway's read actions plus new tests, a new
`app/lib/solo/ui/` screen, profile entry, `docs/API.md` read actions, tests,
`qa/competitive/c03/`.

## Must not

- Add coins, currency, purchasable items, loot, streaks-freezes, XP shops or
  any paid or random reward.
- Touch ranked, Elo or battle receipts.
- Award a badge for anything that did not happen; no placeholder/unlocked-by-
  default badges in the build.
- Introduce a new dependency or a localisation framework.

## Acceptance

- Every badge rule has a unit test proving lock and unlock at the boundary,
  and the award path is idempotent under duplicate evaluation.
- Reinstalling/clearing the client does not duplicate or lose badges
  (server-truth evidence line).
- The stats view renders locked/unlocked states from real data only; a fresh
  account shows zero progress (screenshot evidence under `qa/competitive/c03/`).
- `flutter analyze` clean; full suite passes; pgTAP and Deno suites pass.
- No forbidden claims in badge names or descriptions.

## Handoff

Standard handoff, listing each badge id, its rule and its evidence.
