import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/counter/exercise_profile.dart';
import 'package:training_arena/camera/counter/rep_counter.dart';
import 'package:training_arena/camera/camera_types.dart';
import 'package:training_arena/camera/pose/pose_types.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fixture_replay.dart';

void main() {
  List<PoseFrame> partialFrames(
    String fileName, {
    PoseLandmarkType? missing,
    bool lowConfidence = false,
    List<PoseFrame>? sourceFrames,
  }) {
    return partialBodyFrames(
      sourceFrames ?? loadPoseFixture(fileName).frames,
      missingWrists: missing == PoseLandmarkType.leftWrist,
      lowConfidenceElbows: lowConfidence,
    );
  }

  ReplaySummary run(String fileName, ArenaExercise exercise) {
    final fixture = loadPoseFixture(fileName);
    expect(fixture.frames, isNotEmpty, reason: '$fileName has no frames');
    return replay(
      RepCounter(ExerciseCounterProfile.forExercise(exercise)),
      fixture.frames,
    );
  }

  test('the committed fixtures round-trip through the text format', () {
    final fixture = loadPoseFixture('pushups_clean_rep.txt');
    final reparsed = parsePoseFixture(
      serializePoseFixture(fixture.frames),
      name: 'round-trip',
    );
    expect(reparsed.frames.length, fixture.frames.length);
    final first = fixture.frames.first;
    final again = reparsed.frames.first;
    final landmark = PoseLandmarkType.values.firstWhere(
      (type) => first.point(type) != null,
    );
    expect(again.timestampMicros, first.timestampMicros);
    expect(again.luminance, closeTo(first.luminance, 1e-3));
    expect(
      again.point(landmark)?.likelihood,
      closeTo(first.point(landmark)!.likelihood, 1e-3),
    );
  });

  test('a malformed fixture line is rejected', () {
    expect(
      () => parsePoseFixture('12345,0.5|oops', name: 'bad'),
      throwsFormatException,
    );
    expect(() => parsePoseFixture('12345', name: 'bad'), throwsFormatException);
  });

  test('a clean push-up fixture counts exactly one rep', () {
    final summary = run('pushups_clean_rep.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 1);
    expect(summary.repEvents, 1);
  });

  test(
    'side push-up counts with head and feet out of frame and cues move back',
    () {
      final counter = RepCounter(
        ExerciseCounterProfile.forExercise(ArenaExercise.pushUps),
      );
      final frames = partialFrames('pushups_clean_rep.txt');
      final results = frames.map(counter.addFrame).toList();
      expect(results.where((result) => result.repCounted).length, 1);
      expect(
        results.any(
          (result) =>
              result.framingLocked &&
              result.tracking == CameraTrackingState.tracking &&
              result.pauseReason == TrackingPauseReason.tooClose,
        ),
        isTrue,
      );
      expect(
        trackingInstruction(
          exercise: ArenaExercise.pushUps,
          tracking: CameraTrackingState.tracking,
          reason: TrackingPauseReason.tooClose,
          practiceComplete: false,
        ),
        contains('Move the phone back'),
      );
    },
  );

  test('squat counts with head and feet out of frame', () {
    final summary = replay(
      RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.squats)),
      partialFrames('squats_clean_rep.txt'),
    );
    expect(summary.countedReps, 1);
  });

  test('front push-up counts with head out of frame', () {
    final summary = replay(
      RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps)),
      partialFrames('pushups_front_clean_rep.txt'),
    );
    expect(summary.countedReps, 1);
  });

  for (final (file, rejection) in [
    // Shallow attempts stay uncounted and now explain the failed depth guard.
    ('pushups_half_depth.txt', CounterRejection.notDeepEnough),
    ('pushups_plank_collapse.txt', CounterRejection.bodyNotStraight),
  ]) {
    test('$file stays rejected with head and feet out of frame', () {
      final counter = RepCounter(
        ExerciseCounterProfile.forExercise(ArenaExercise.pushUps),
      );
      final results = partialFrames(file).map(counter.addFrame).toList();
      final outcomes = results.where((result) => result.outcome).toList();

      expect(counter.countedReps, 0);
      expect(results.last.rejection, rejection);
      expect(outcomes, hasLength(1));
      expect(outcomes.single.repCounted, isFalse);
      expect(outcomes.single.rejection, rejection);
    });
  }

  test('bottom bounce stays rejected with head and feet out of frame', () {
    final source = SyntheticPoseSource.pushups(seed: 6, intervalMicros: 16000);
    source.holdTop(640);
    source.segment(source.bottomAngle, to: source.bottomAngle, durationMs: 80);
    source.segment(source.bottomAngle, to: source.topAngle, durationMs: 160);
    source.holdTop(400);
    final summary = replay(
      RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps)),
      partialFrames('bounce', sourceFrames: source.frames),
    );
    expect(summary.countedReps, 0);
    expect(summary.lastRejection, CounterRejection.dwellTooShort);
  });

  test('low-confidence signal chain stays rejected with head and feet out', () {
    final summary = replay(
      RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps)),
      partialFrames('pushups_clean_rep.txt', lowConfidence: true),
    );
    expect(summary.countedReps, 0);
    expect(summary.framingEverLocked, isFalse);
  });

  test('off-frame head does not make a tiny signal count', () {
    final small = loadPoseFixture('pushups_clean_rep.txt').frames.map((frame) {
      final points = <PoseLandmarkType, PosePoint>{};
      for (final type in PoseLandmarkType.values) {
        final point = frame.point(type);
        if (point != null) {
          points[type] = PosePoint(
            x: 0.5 + (point.x - 0.5) * 0.4,
            y: 0.5 + (point.y - 0.5) * 0.4,
            likelihood: point.likelihood,
          );
        }
      }
      return PoseFrame.of(timestampMicros: frame.timestampMicros, points: points);
    }).toList();
    final counter = RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps));
    final results = partialBodyFrames(small).map(counter.addFrame).toList();
    expect(counter.countedReps, 0);
    expect(results.any((result) => result.pauseReason == TrackingPauseReason.tooFar), isTrue);
  });

  test('missing selected signal joint still cannot count', () {
    final summary = replay(
      RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps)),
      partialFrames(
        'pushups_clean_rep.txt',
        missing: PoseLandmarkType.leftWrist,
      ),
    );
    expect(summary.countedReps, 0);
  });

  test('a shake-only fixture counts nothing', () {
    final summary = run('pushups_shake_only.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.repEvents, 0);
  });

  test('a half-depth fixture counts nothing', () {
    final summary = run('pushups_half_depth.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.repEvents, 0);
  });

  test('a plank-collapse fixture refuses the rep as not straight', () {
    final summary = run('pushups_plank_collapse.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.lastRejection, CounterRejection.bodyNotStraight);
  });

  test('a dropout fixture loses tracking and counts nothing', () {
    final summary = run('pushups_dropout.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.lostTracking, isTrue);
  });

  test('a clean squat fixture counts exactly one rep', () {
    final summary = run('squats_clean_rep.txt', ArenaExercise.squats);
    expect(summary.countedReps, 1);
    expect(summary.repEvents, 1);
  });

  test('a clean head-on push-up fixture counts exactly one rep', () {
    final summary = run('pushups_front_clean_rep.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 1);
    expect(summary.repEvents, 1);
  });

  test('a head-on half-depth fixture counts nothing', () {
    final summary = run('pushups_front_half_depth.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.repEvents, 0);
  });

  test('a head-on shake-only fixture counts nothing', () {
    final summary = run('pushups_front_shake_only.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.repEvents, 0);
  });

  test('a head-on sag fixture refuses the rep as not straight', () {
    final summary = run('pushups_front_sag.txt', ArenaExercise.pushUps);
    expect(summary.countedReps, 0);
    expect(summary.lastRejection, CounterRejection.bodyNotStraight);
  });

  test('a head-on fixture with a hidden hand never locks framing', () {
    final summary = run(
      'pushups_front_partial_body.txt',
      ArenaExercise.pushUps,
    );
    expect(summary.countedReps, 0);
    expect(summary.repEvents, 0);
    expect(summary.framingEverLocked, isFalse);
  });
}
