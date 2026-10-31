// SYNTHETIC state-machine regression; this does not validate device accuracy.
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  test('a view change rejects an active attempt without counting it', () {
    final source = SyntheticPoseSource.pushups();
    source.holdTop(800);
    source.segment(160, to: 88, durationMs: 800);
    final counter = RepCounter(
      ExerciseCounterProfile.forExercise(ArenaExercise.pushUps),
    );
    for (final frame in source.frames) {
      counter.addFrame(frame);
    }
    final result = counter.addFrame(
      SyntheticPose.pushupFrontFrame(
        timestampMicros: source.frames.last.timestampMicros + 66667,
        elbowAngle: 88,
      ),
    );

    expect(result.outcome, isTrue);
    expect(result.rejection, CounterRejection.lowConfidence);
    expect(result.repCounted, isFalse);
    expect(counter.countedReps, 0);
  });

  test('noisy continuous push-ups report every completed attempt', () {
    final source = SyntheticPoseSource(
      exercise: SyntheticExercise.pushUps,
      intervalMicros: (1000000 / 15).round(),
      seed: 4,
      noiseAmplitude: .02,
    );
    source.segment(160, to: 160, durationMs: 800);
    for (var cycle = 0; cycle < 10; cycle++) {
      source.segment(160, to: 88, durationMs: 800);
      source.segment(88, to: 160, durationMs: 800);
    }
    source.segment(160, to: 160, durationMs: 800);
    final counter = RepCounter(
      ExerciseCounterProfile.forExercise(ArenaExercise.pushUps),
    );
    final outcomes = source.frames
        .map(counter.addFrame)
        .where((result) => result.outcome)
        .toList();
    expect(outcomes, hasLength(10));
    expect(counter.countedReps, 9);
    expect(
      outcomes.where((result) => !result.repCounted).single.rejection,
      CounterRejection.lowConfidence,
    );
  });
}
