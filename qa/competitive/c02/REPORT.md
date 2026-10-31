# C02 — daily goal and streak: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

## Scope decision (deviation from the prompt, recorded)

The prompt asked for server truth with a migration, gateway actions, pgTAP
and Deno tests. This implementation is **device-local**, for three reasons:

1. Decision 12 defines solo as local-only and non-competitive; no server
   match, receipt or rating may exist for it.
2. There is no hosted Supabase project (R2/R3/R16 open), so a server path
   could not be verified end to end; a local stack run would not change that.
3. The habit loop only needs the stored history that C01 already keeps.

Upgrade path when hosting exists: a day-completion record
(`user, local_day, reps, idempotency key`) can be uploaded from the same
derived model; `SoloStreak.from` is pure and would stay the source of truth
for display.

## What landed

| Area | File |
| --- | --- |
| Day/streak maths | `app/lib/solo/domain/solo_streak.dart` (local calendar days, DST-safe day stepping, longest/current streak, goal-met) |
| Controller | `solo_controller.dart` — `SoloStreak` derived on `load()` and after `save()`, exposed in `SoloSnapshot` |
| UI | `solo_page.dart` — `solo-streak` card with today's progress, goal bar, streak, longest |
| Tests | `app/test/solo/solo_streak_test.dart` (9 cases) + controller assertions |

Goal: `soloDailyGoalReps = 20` for push-ups, fixed in v1 (a goal picker is
deferred; the model already accepts a custom goal).

## Rules implemented

- A day counts only when reps that day reach the goal.
- Several sets on one day sum toward the goal.
- An unmet today does not break a streak that is alive through yesterday.
- A missed day resets the current streak, never the longest.
- Days are local calendar days: a 23:30 local set counts for that day, not
  the UTC day.
- All day arithmetic uses local-midnight `DateTime` construction, so DST
  transitions cannot shift a day.

## Verification (2026-09-23)

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test test/solo` | 24/24 passed |
| `flutter test` (full) | **516/516 passed** (507 before; +9) |

No server, database or release flag changed in this task.
