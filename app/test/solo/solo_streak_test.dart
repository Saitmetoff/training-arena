import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/solo/domain/solo_result.dart';
import 'package:training_arena/solo/domain/solo_streak.dart';

/// Builds a result at a local wall-clock time; the store keeps UTC.
SoloSetResult at(
  DateTime local,
  int reps, {
  SoloCountSource source = SoloCountSource.camera,
}) =>
    SoloSetResult(
      exercise: ArenaExercise.pushUps,
      reps: reps,
      durationSeconds: 30,
      completedAt: local.toUtc(),
      source: source,
    );

void main() {
  test('no history means no streak and the goal is unmet', () {
    final streak = SoloStreak.from(const <SoloSetResult>[], DateTime(2026, 9, 23, 9));
    expect(streak.todayReps, 0);
    expect(streak.current, 0);
    expect(streak.longest, 0);
    expect(streak.goalMetToday, isFalse);
    expect(streak.remainingToday, soloDailyGoalReps);
  });

  test('one goal-met day starts a one-day streak', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[at(DateTime(2026, 9, 23, 8), 25)],
      DateTime(2026, 9, 23, 20),
    );
    expect(streak.goalMetToday, isTrue);
    expect(streak.current, 1);
    expect(streak.longest, 1);
    expect(streak.remainingToday, 0);
  });

  test('multiple sets on one day sum toward the goal', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[
        at(DateTime(2026, 9, 23, 8), 8),
        at(DateTime(2026, 9, 23, 12), 7),
        at(DateTime(2026, 9, 23, 18), 6),
      ],
      DateTime(2026, 9, 23, 19),
    );
    expect(streak.todayReps, 21);
    expect(streak.todaySets, 3);
    expect(streak.goalMetToday, isTrue);
    expect(streak.current, 1);
  });

  test('an unmet today keeps a streak that is alive through yesterday', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[
        at(DateTime(2026, 9, 22, 9), 20),
        at(DateTime(2026, 9, 23, 9), 5),
      ],
      DateTime(2026, 9, 23, 21),
    );
    expect(streak.goalMetToday, isFalse);
    expect(streak.current, 1);
    expect(streak.remainingToday, 15);
  });

  test('a missed day breaks the current streak but not the longest', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[
        at(DateTime(2026, 9, 18, 9), 20),
        at(DateTime(2026, 9, 19, 9), 20),
        at(DateTime(2026, 9, 20, 9), 20),
        at(DateTime(2026, 9, 23, 9), 20),
      ],
      DateTime(2026, 9, 23, 21),
    );
    expect(streak.current, 1);
    expect(streak.longest, 3);
  });

  test('consecutive days across a month boundary count', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[
        at(DateTime(2026, 9, 30, 9), 20),
        at(DateTime(2026, 10, 1, 9), 20),
        at(DateTime(2026, 10, 2, 9), 20),
      ],
      DateTime(2026, 10, 2, 21),
    );
    expect(streak.current, 3);
    expect(streak.longest, 3);
  });

  test('a late local set counts for that local day, not the UTC day', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[at(DateTime(2026, 9, 23, 23, 30), 20)],
      DateTime(2026, 9, 23, 23, 59),
    );
    expect(streak.todayReps, 20);
    expect(streak.current, 1);
  });

  test('a result before the goal is reached does not count as a day', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[
        at(DateTime(2026, 9, 21, 9), 19),
        at(DateTime(2026, 9, 22, 9), 20),
        at(DateTime(2026, 9, 23, 9), 20),
      ],
      DateTime(2026, 9, 23, 21),
    );
    expect(streak.current, 2);
    expect(streak.longest, 2);
  });

  test('a custom goal is honoured', () {
    final streak = SoloStreak.from(
      <SoloSetResult>[at(DateTime(2026, 9, 23, 9), 10)],
      DateTime(2026, 9, 23, 21),
      goalReps: 10,
    );
    expect(streak.goalMetToday, isTrue);
    expect(streak.current, 1);
  });
}
