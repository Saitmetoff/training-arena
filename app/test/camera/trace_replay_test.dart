// Replay owner-supplied numeric traces with Flutter's existing test runtime.
// Console diagnostics are the purpose of this replay command.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/trace/pose_trace_format.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fixture_replay.dart';

Map<String, Object?> replayTrace(String text, ArenaExercise exercise) {
  final frames = parsePoseFixture(text, name: 'trace').frames;
  if (frames.isEmpty) throw const FormatException('trace is empty');
  var previousTimestamp = -1;
  for (final f in frames) {
    if (f.timestampMicros <= previousTimestamp ||
        f.luminance < 0 ||
        f.luminance > 1) {
      throw const FormatException('invalid timestamp order or luminance');
    }
    previousTimestamp = f.timestampMicros;
    for (final p in f.landmarks.whereType<PosePoint>()) {
      if (![p.x, p.y, p.z, p.likelihood].every((v) => v.isFinite) ||
          p.likelihood < 0 ||
          p.likelihood > 1) {
        throw const FormatException('invalid landmark');
      }
    }
  }
  final profile = ExerciseCounterProfile.forExercise(exercise);
  final c = RepCounter(profile);
  final boundaryMatch = RegExp(
    r'^# round_start_after_us: (-?\d+)$',
    multiLine: true,
  ).firstMatch(text);
  final boundary = boundaryMatch == null ? null : int.parse(boundaryMatch[1]!);
  if (boundary != null &&
      boundary >= 0 &&
      frames.first.timestampMicros > boundary) {
    throw const FormatException(
      'round lead-in was truncated; replay agreement unavailable',
    );
  }
  final events = RegExp(
    r'^# counter_event: (-?\d+),(pause|resume)$',
    multiLine: true,
  ).allMatches(text).map((m) => (int.parse(m[1]!), m[2]!)).toList();
  var eventIndex = 0;
  var roundStarted = boundary == null;
  if (!roundStarted) c.setCountingEnabled(false);
  final histogram = <String, int>{};
  final pauseReasons = <String, int>{};
  final cycles = <Map<String, Object?>>[];
  var switches = 0;
  PoseSide? previousSide;
  double? minimum, maximum;
  for (final f in frames) {
    while (eventIndex < events.length &&
        events[eventIndex].$1 < f.timestampMicros) {
      if (events[eventIndex].$2 == 'pause') {
        c.pause();
      } else {
        c.resume();
      }
      eventIndex++;
    }
    if (!roundStarted && f.timestampMicros > boundary!) {
      c.reset(keepFraming: true);
      c.setCountingEnabled(true);
      roundStarted = true;
      minimum = null;
      maximum = null;
    }
    final r = c.addFrame(f);
    if (!roundStarted) continue;
    if (previousSide != null && r.side != null && previousSide != r.side) {
      switches++;
    }
    if (r.side != null) previousSide = r.side;
    if (r.pauseReason != TrackingPauseReason.none) {
      pauseReasons.update(r.pauseReason.name, (n) => n + 1, ifAbsent: () => 1);
    }
    final signal = r.signal;
    final near = r.viewMode == CameraViewMode.front
        ? profile.frontEnterBottomSignal + profile.frontNearBottomSignal
        : profile.enterBottomAngle + profile.nearBottomDegrees;
    if (signal != null && (minimum != null || signal <= near)) {
      minimum = math.min(minimum ?? signal, signal);
      maximum = math.max(maximum ?? signal, signal);
    }
    if (r.outcome) {
      final verdict = r.repCounted ? 'counted' : r.rejection.name;
      if (!r.repCounted) {
        histogram.update(verdict, (n) => n + 1, ifAbsent: () => 1);
      }
      cycles.add({
        'timestamp_us': f.timestampMicros,
        'outcome': verdict,
        'min_smoothed': minimum,
        'max_smoothed': maximum,
      });
      minimum = null;
      maximum = null;
    }
  }
  if (minimum != null) {
    cycles.add({
      'outcome': 'unfinished',
      'min_smoothed': minimum,
      'max_smoothed': maximum,
    });
  }
  return {
    'counted_reps': c.countedReps,
    'rejection_histogram': histogram,
    'cycles': cycles,
    'side_switches': switches,
    'pause_reasons_by_frame': pauseReasons,
  };
}

void main() {
  const path = String.fromEnvironment('POSE_TRACE_PATH');
  const exerciseName = String.fromEnvironment(
    'POSE_TRACE_EXERCISE',
    defaultValue: 'pushups',
  );
  if (path.isNotEmpty) {
    test(
      'owner trace replay (source provenance must be recorded separately)',
      () {
        if (exerciseName != 'pushups' && exerciseName != 'squats') {
          throw const FormatException('exercise must be pushups or squats');
        }
        print(
          replayTrace(
            File(path).readAsStringSync(),
            exerciseName == 'pushups'
                ? ArenaExercise.pushUps
                : ArenaExercise.squats,
          ),
        );
      },
    );
    return;
  }
  test(
    'SYNTHETIC replay prints counts, cycle extrema, side switches and pauses',
    () {
      final s = SyntheticPoseSource.pushups();
      s.holdTop(800);
      s.rep();
      s.rep();
      final result = replayTrace(
        serializePoseFixture(s.frames),
        ArenaExercise.pushUps,
      );
      print('SYNTHETIC $result');
      expect(result['counted_reps'], 2);
      expect(result['cycles'], hasLength(2));
      expect(
        result.keys,
        containsAll([
          'rejection_histogram',
          'side_switches',
          'pause_reasons_by_frame',
        ]),
      );
    },
  );
  test('SYNTHETIC empty and invalid traces fail', () {
    for (final text in [
      '',
      '# only a comment',
      'invalid',
      '1,NaN|',
      '1,.5|11,NaN,.5,.9',
      '2,.5|\n1,.5|',
    ]) {
      expect(
        () => replayTrace(text, ArenaExercise.pushUps),
        throwsFormatException,
      );
    }
  });
  test('SYNTHETIC trace preserves portrait aspect and depth', () {
    final f = SyntheticPose.pushupFrame(timestampMicros: 1, elbowAngle: 160);
    final portrait = PoseFrame(
      timestampMicros: 1,
      landmarks: f.landmarks,
      aspectRatio: .75,
    );
    final again = parsePoseFixture(
      serializePoseFrames([portrait]),
      name: 'portrait',
    ).frames.single;
    expect(again.aspectRatio, .75);
  });
}
