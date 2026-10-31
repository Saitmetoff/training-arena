import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/solo/domain/solo_badges.dart';
import 'package:training_arena/solo/domain/solo_result.dart';
import 'package:training_arena/solo/domain/solo_streak.dart';

SoloSetResult result(DateTime local, int reps) => SoloSetResult(
      exercise: ArenaExercise.pushUps,
      reps: reps,
      durationSeconds: 30,
      completedAt: local.toUtc(),
      source: SoloCountSource.camera,
    );

List<SoloBadge> badgesFor(List<SoloSetResult> results, DateTime now) =>
    soloBadges(
      stats: SoloStats.from(results),
      streak: SoloStreak.from(results, now),
    );

SoloBadge badge(List<SoloBadge> badges, String id) =>
    badges.firstWhere((entry) => entry.id == id);

void main() {
  final now = DateTime(2026, 9, 23, 21);

  test('nothing is unlocked on an empty history', () {
    final badges = badgesFor(const <SoloSetResult>[], now);
    expect(badges.length, 6);
    expect(unlockedBadgeCount(badges), 0);
  });

  test('the first set unlocks at exactly one session', () {
    final none = badgesFor(const <SoloSetResult>[], now);
    expect(badge(none, 'first-set').unlocked, isFalse);
    final one = badgesFor(<SoloSetResult>[result(DateTime(2026, 9, 23, 8), 5)], now);
    expect(badge(one, 'first-set').unlocked, isTrue);
    // Five reps do not reach the goal, so no goal-day badge yet.
    expect(badge(one, 'goal-day').unlocked, isFalse);
  });

  test('goal-day unlocks on the first goal-met day', () {
    final badges = badgesFor(
      <SoloSetResult>[result(DateTime(2026, 9, 23, 8), soloDailyGoalReps)],
      now,
    );
    expect(badge(badges, 'goal-day').unlocked, isTrue);
    expect(badge(badges, 'week-streak').unlocked, isFalse);
  });

  test('the seven-day badge unlocks at exactly seven consecutive days', () {
    List<SoloSetResult> days(int count) => List<SoloSetResult>.generate(
          count,
          (index) => result(
            DateTime(2026, 9, 17 + index, 8),
            soloDailyGoalReps,
          ),
        );
    expect(badge(badgesFor(days(6), now), 'week-streak').unlocked, isFalse);
    expect(badge(badgesFor(days(7), now), 'week-streak').unlocked, isTrue);
    expect(badge(badgesFor(days(7), now), 'month-streak').unlocked, isFalse);
  });

  test('rep milestones unlock at the boundary', () {
    final ninetyNine =
        badgesFor(<SoloSetResult>[result(DateTime(2026, 9, 23, 8), 99)], now);
    expect(badge(ninetyNine, 'hundred-reps').unlocked, isFalse);
    final hundred =
        badgesFor(<SoloSetResult>[result(DateTime(2026, 9, 23, 8), 100)], now);
    expect(badge(hundred, 'hundred-reps').unlocked, isTrue);
    expect(badge(hundred, 'thousand-reps').unlocked, isFalse);
    final thousand =
        badgesFor(<SoloSetResult>[result(DateTime(2026, 9, 23, 8), 1000)], now);
    expect(badge(thousand, 'thousand-reps').unlocked, isTrue);
  });

  test('evaluation is idempotent: same history, same badges', () {
    final results = <SoloSetResult>[result(DateTime(2026, 9, 23, 8), 20)];
    final first = badgesFor(results, now);
    final second = badgesFor(results, now);
    expect(unlockedBadgeCount(first), unlockedBadgeCount(second));
    for (var index = 0; index < first.length; index += 1) {
      expect(first[index].id, second[index].id);
      expect(first[index].unlocked, second[index].unlocked);
    }
  });
}
