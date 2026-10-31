/// Local, non-competitive solo set models.
///
/// A solo set never creates a receipt, rating, leaderboard entry or server
/// match; it is stored on this device only. Values are additive; changing a
/// wire value needs a `docs/decisions/` note.
library;

import '../../domain/arena_types.dart';

/// How a solo rep count was produced.
enum SoloCountSource {
  camera('camera', 'Camera-counted'),
  manual('manual', 'Self-reported');

  const SoloCountSource(this.wire, this.label);

  final String wire;
  final String label;

  static SoloCountSource? tryFromWire(Object? value) {
    for (final source in SoloCountSource.values) {
      if (source.wire == value) {
        return source;
      }
    }
    return null;
  }
}

/// One finished solo set.
class SoloSetResult {
  const SoloSetResult({
    required this.exercise,
    required this.reps,
    required this.durationSeconds,
    required this.completedAt,
    required this.source,
  });

  final ArenaExercise exercise;
  final int reps;
  final int durationSeconds;
  final DateTime completedAt;
  final SoloCountSource source;

  /// True for self-reported sets; the UI must label them.
  bool get selfReported => source == SoloCountSource.manual;

  Map<String, Object?> toJson() => <String, Object?>{
        'exercise': exercise.wire,
        'reps': reps,
        'duration_seconds': durationSeconds,
        'completed_at': completedAt.toUtc().toIso8601String(),
        'source': source.wire,
      };

  /// Returns `null` for anything malformed so one bad entry cannot lose the
  /// whole history.
  static SoloSetResult? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final exercise = ArenaExercise.tryFromWire(raw['exercise']);
    final source = SoloCountSource.tryFromWire(raw['source']);
    final reps = raw['reps'];
    final duration = raw['duration_seconds'];
    final completedAt = raw['completed_at'];
    if (exercise == null ||
        source == null ||
        reps is! int ||
        reps < 0 ||
        duration is! int ||
        duration < 0 ||
        completedAt is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(completedAt);
    if (parsed == null) {
      return null;
    }
    return SoloSetResult(
      exercise: exercise,
      reps: reps,
      durationSeconds: duration,
      completedAt: parsed.toUtc(),
      source: source,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SoloSetResult &&
      other.exercise == exercise &&
      other.reps == reps &&
      other.durationSeconds == durationSeconds &&
      other.completedAt == completedAt &&
      other.source == source;

  @override
  int get hashCode =>
      Object.hash(exercise, reps, durationSeconds, completedAt, source);

  @override
  String toString() =>
      'SoloSetResult(${exercise.wire}, reps=$reps, ${source.wire})';
}

/// Derived summary of stored solo results; never stored itself.
class SoloStats {
  const SoloStats({
    required this.sessions,
    required this.totalReps,
    required this.bestSetReps,
    this.last,
  });

  static const SoloStats empty =
      SoloStats(sessions: 0, totalReps: 0, bestSetReps: 0);

  factory SoloStats.from(List<SoloSetResult> results) {
    var total = 0;
    var best = 0;
    for (final result in results) {
      total += result.reps;
      if (result.reps > best) {
        best = result.reps;
      }
    }
    return SoloStats(
      sessions: results.length,
      totalReps: total,
      bestSetReps: best,
      last: results.isEmpty ? null : results.first,
    );
  }

  final int sessions;
  final int totalReps;
  final int bestSetReps;
  final SoloSetResult? last;
}

/// Best set in the retained history, compared only within the same signal.
int soloPersonalBest(
  List<SoloSetResult> results, {
  required ArenaExercise exercise,
  required SoloCountSource source,
}) {
  var best = 0;
  for (final result in results) {
    if (result.exercise == exercise &&
        result.source == source &&
        result.reps > best) {
      best = result.reps;
    }
  }
  return best;
}

/// Seven local calendar days, including today; future dates are excluded.
List<SoloSetResult> recentSoloResults(
  List<SoloSetResult> results,
  DateTime now,
) {
  final local = now.toLocal();
  final first = DateTime(local.year, local.month, local.day - 6);
  final end = DateTime(local.year, local.month, local.day + 1);
  final recent = results.where((result) {
    final date = result.completedAt.toLocal();
    return !date.isBefore(first) && date.isBefore(end);
  }).toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return List<SoloSetResult>.unmodifiable(recent);
}
