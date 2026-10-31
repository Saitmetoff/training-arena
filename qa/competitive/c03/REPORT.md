# C03 — personal bests, badges and stats: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

## What landed

| Area | File |
| --- | --- |
| Badge model | `app/lib/solo/domain/solo_badges.dart` — six deterministic badges, derived from stats + streak, plus `unlockedBadgeCount` |
| UI | `solo_page.dart` — `solo-badges` grid on the intro and on the saved-result screen; locked badges are labelled "locked", not colour-only |
| Tests | `app/test/solo/solo_badges_test.dart` — boundaries and idempotency |

Personal bests and the stats view already exist from C01/C02 (`solo-stats`
card: best set / last set / sessions; `solo-streak` card: today, streak,
longest). This task adds the badge layer and keeps bests as derived values —
no separate counters that could drift.

## Badge rules

| Id | Rule |
| --- | --- |
| `first-set` | at least one stored set |
| `goal-day` | longest streak ≥ 1 (a day reached the goal) |
| `week-streak` | longest streak ≥ 7 |
| `month-streak` | longest streak ≥ 30 |
| `hundred-reps` | lifetime reps ≥ 100 |
| `thousand-reps` | lifetime reps ≥ 1,000 |

Badges are pure functions of the local history: evaluating them twice cannot
duplicate anything, and they need no server award or migration. Clearing app
data clears them with the history, which is consistent with the local-only
scope of decision 12.

## Deliberately not done

- No coins, currency, purchases, loot, streak freezes or XP shop.
- No badge that implies a competitive or health claim.
- No server persistence (same scope decision as C02).

## Verification (2026-09-23)

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test test/solo` | 30/30 passed |
| `flutter test` (full) | **522/522 passed** (516 before; +6) |
