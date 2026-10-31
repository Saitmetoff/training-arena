/// Local daily-goal and streak maths for solo sets.
///
/// Days are the device's local calendar days: a result is stored in UTC and
/// converted with `toLocal()`, so a set at 23:30 counts for that local day.
/// All arithmetic builds local midnights through the [DateTime] constructor
/// so DST transitions cannot shift a day by an hour.
library;

import 'solo_result.dart';

/// Daily rep goal for the solo habit loop (push-ups). Fixed for v1; the
/// owner can make it configurable later without changing this model.
const int soloDailyGoalReps = 20;

/// One local calendar day of solo activity.
class SoloDayProgress {
  const SoloDayProgress({
    required this.day,
    required this.reps,
    required this.sets,
  });

  /// Local midnight of the day.
  final DateTime day;
  final int reps;
  final int sets;
}

/// Derived goal/streak view over stored solo results.
class SoloStreak {
  const SoloStreak({
    required this.todayReps,
    required this.todaySets,
    required this.current,
    required this.longest,
    required this.goalReps,
  });

  static const SoloStreak empty = SoloStreak(
    todayReps: 0,
    todaySets: 0,
    current: 0,
    longest: 0,
    goalReps: soloDailyGoalReps,
  );

  final int todayReps;
  final int todaySets;

  /// Consecutive goal-met days ending today or yesterday. A day that has not
  /// met the goal yet does not break a streak that is alive through
  /// yesterday.
  final int current;
  final int longest;
  final int goalReps;

  bool get goalMetToday => todayReps >= goalReps;

  int get remainingToday =>
      todayReps >= goalReps ? 0 : goalReps - todayReps;

  factory SoloStreak.from(
    List<SoloSetResult> results,
    DateTime now, {
    int goalReps = soloDailyGoalReps,
  }) {
    final repsByDay = <DateTime, int>{};
    final setsByDay = <DateTime, int>{};
    for (final result in results) {
      final local = result.completedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      repsByDay[day] = (repsByDay[day] ?? 0) + result.reps;
      setsByDay[day] = (setsByDay[day] ?? 0) + 1;
    }

    final today = DateTime(now.year, now.month, now.day);
    final todayReps = repsByDay[today] ?? 0;

    final metDays = repsByDay.entries
        .where((entry) => entry.value >= goalReps)
        .map((entry) => entry.key)
        .toList()
      ..sort();

    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final day in metDays) {
      run = (previous != null && _isNextDay(previous, day)) ? run + 1 : 1;
      if (run > longest) {
        longest = run;
      }
      previous = day;
    }

    var current = 0;
    var cursor = today;
    if (todayReps < goalReps) {
      cursor = _previousDay(today);
    }
    while ((repsByDay[cursor] ?? 0) >= goalReps) {
      current += 1;
      cursor = _previousDay(cursor);
    }

    return SoloStreak(
      todayReps: todayReps,
      todaySets: setsByDay[today] ?? 0,
      current: current,
      longest: longest,
      goalReps: goalReps,
    );
  }
}

DateTime _previousDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// True when [b] is the local calendar day after [a]; DST-safe because both
/// sides are local midnights built through the constructor.
bool _isNextDay(DateTime a, DateTime b) {
  final next = DateTime(a.year, a.month, a.day + 1);
  return next.year == b.year && next.month == b.month && next.day == b.day;
}
