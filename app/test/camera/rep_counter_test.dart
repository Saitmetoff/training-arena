import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera_types.dart';
import 'package:training_arena/camera/counter/exercise_profile.dart';
import 'package:training_arena/camera/counter/rep_counter.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/pose/pose_math.dart';
import 'package:training_arena/camera/pose/pose_types.dart';
import 'package:training_arena/domain/arena_types.dart';

RepCounter counterFor(ArenaExercise exercise) =>
    RepCounter(ExerciseCounterProfile.forExercise(exercise));

List<RepCounterResult> feedAll(RepCounter counter, Iterable<PoseFrame> frames) {
  final results = <RepCounterResult>[];
  for (final frame in frames) {
    results.add(counter.addFrame(frame));
  }
  return results;
}

PoseFrame patchLikelihood(PoseFrame frame, PoseLandmarkType type, double likelihood) {
  final points = <PoseLandmarkType, PosePoint>{};
  for (final landmark in PoseLandmarkType.values) {
    final point = frame.point(landmark);
    if (point == null) {
      continue;
    }
    points[landmark] = landmark == type
        ? PosePoint(x: point.x, y: point.y, z: point.z, likelihood: likelihood)
        : point;
  }
  return PoseFrame.of(
    timestampMicros: frame.timestampMicros,
    points: points,
    luminance: frame.luminance,
  );
}

PoseFrame scaleAboutCenter(PoseFrame frame, double scale) {
  final points = <PoseLandmarkType, PosePoint>{};
  for (final landmark in PoseLandmarkType.values) {
    final point = frame.point(landmark);
    if (point == null) {
      continue;
    }
    points[landmark] = PosePoint(
      x: 0.5 + (point.x - 0.5) * scale,
      y: 0.5 + (point.y - 0.5) * scale,
      z: point.z * scale,
      likelihood: point.likelihood,
    );
  }
  return PoseFrame.of(
    timestampMicros: frame.timestampMicros,
    points: points,
    luminance: frame.luminance,
  );
}

PoseFrame liftHeels(PoseFrame frame) {
  final points = <PoseLandmarkType, PosePoint>{};
  for (final landmark in PoseLandmarkType.values) {
    final point = frame.point(landmark);
    if (point == null) {
      continue;
    }
    final isHeel =
        landmark == PoseLandmarkType.leftHeel ||
        landmark == PoseLandmarkType.rightHeel;
    points[landmark] = isHeel
        ? PosePoint(x: point.x, y: point.y - 0.06, z: point.z, likelihood: point.likelihood)
        : point;
  }
  return PoseFrame.of(
    timestampMicros: frame.timestampMicros,
    points: points,
    luminance: frame.luminance,
  );
}

PoseFrame hideHeels(PoseFrame frame) => patchLikelihood(
      patchLikelihood(frame, PoseLandmarkType.leftHeel, 0.3),
      PoseLandmarkType.rightHeel,
      0.3,
    );

/// True when the squat knee angle is inside the bottom band, so fixture
/// patches can target the descent/bottom frames only.
bool nearSquatBottom(PoseFrame frame) {
  final hip = frame.point(PoseLandmarkType.leftHip);
  final knee = frame.point(PoseLandmarkType.leftKnee);
  final ankle = frame.point(PoseLandmarkType.leftAnkle);
  if (hip == null || knee == null || ankle == null) {
    return false;
  }
  return angleDegrees(hip, knee, ankle) <= 110;
}

void main() {
  group('push-up counter', () {
    test('counts a complete rep after stable full-body framing', () {
      final source = SyntheticPoseSource.pushups(seed: 11);
      source.holdTop(800);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
      expect(counter.framingLocked, isTrue);
      final counting = results.firstWhere((result) => result.repCounted);
      expect(counting.rejection, CounterRejection.none);
      expect(counting.repConfidence, greaterThanOrEqualTo(0.6));
    });

    test('counts a rep once with strong landmark noise', () {
      final source = SyntheticPoseSource.pushups(seed: 5, noiseAmplitude: 0.012);
      source.holdTop(800);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
    });

    test('ignores a partial rep that never reaches the bottom band', () {
      final source = SyntheticPoseSource.pushups(seed: 3);
      source.holdTop(800);
      source.partialRep(minimum: 122);
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(
        results.where((result) => result.outcome).map((result) => result.rejection),
        [CounterRejection.notDeepEnough],
      );
    });

    test('ignores top-of-movement jitter and threshold rumours', () {
      final source = SyntheticPoseSource.pushups(seed: 4);
      source.holdTop(800);
      source.jitterTop(1600, suspicionEvery: 5);
      final counter = counterFor(ArenaExercise.pushUps);

      feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(counter.framingLocked, isTrue);
    });

    test('rejects a bottom bounce shorter than the dwell guard', () {
      // High frame rate so the anti-jitter smoothing itself does not mask the
      // dwell: the athlete dips into the band and springs straight back out.
      final source = SyntheticPoseSource.pushups(seed: 6, intervalMicros: 16000);
      source.holdTop(640);
      source.segment(source.bottomAngle, to: source.bottomAngle, durationMs: 80);
      source.segment(source.bottomAngle, to: source.topAngle, durationMs: 160);
      source.holdTop(400);
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(results.last.rejection, CounterRejection.dwellTooShort);
      expect(
        results.where((result) => result.outcome).map((result) => result.rejection),
        [CounterRejection.dwellTooShort],
      );
    });

    test('rejects a rep completed too fast', () {
      final source = SyntheticPoseSource.pushups(seed: 6);
      source.holdTop(800);
      source.rep(descendMs: 0, bottomHoldMs: 160, ascendMs: 0);
      source.holdTop(300);
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(results.last.rejection, CounterRejection.repTooFast);
    });

    test('rejects a rep with a sagging body line', () {
      final source = SyntheticPoseSource.pushups(seed: 6);
      source.holdTop(800);
      source.rep(hipDrop: 0.06);
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(results.last.rejection, CounterRejection.bodyNotStraight);
      expect(
        results.where((result) => result.outcome).map((result) => result.rejection),
        [CounterRejection.bodyNotStraight],
      );
    });

    test('missing ankles on both signal chains gate counting', () {
      final source = SyntheticPoseSource.pushups(seed: 9);
      source.holdTop(800);
      source.rep();
      // One hidden ankle leaves a complete far-side chain. Hide both to
      // exercise missing-signal rejection rather than forbid that fallback.
      final hidden = source.frames
          .map((frame) => patchLikelihood(
                patchLikelihood(frame, PoseLandmarkType.leftAnkle, 0.2),
                PoseLandmarkType.rightAnkle,
                0.2,
              ))
          .toList();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, hidden);

      expect(counter.countedReps, 0);
      expect(
        results.any((result) => result.pauseReason == TrackingPauseReason.partialBody),
        isTrue,
      );
    });

    test('a complete far-side chain counts when the near ankle is missing', () {
      final source = SyntheticPoseSource.pushups(seed: 9);
      source.holdTop(800);
      source.rep();
      final hidden = source.frames
          .map((frame) => patchLikelihood(frame, PoseLandmarkType.leftAnkle, 0.2))
          .toList();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, hidden);
      final accepted = results.where((result) => result.repCounted).toList();

      expect(counter.countedReps, 1);
      expect(accepted, hasLength(1));
      expect(accepted.single.side, PoseSide.right);
      expect(accepted.single.outcome, isTrue);
      expect(accepted.single.rejection, CounterRejection.none);
    });

    test('reports too-far framing and refuses to count a shrunken body', () {
      final source = SyntheticPoseSource.pushups(seed: 9);
      source.holdTop(800);
      source.rep();
      final shrunken = source.frames.map((frame) => scaleAboutCenter(frame, 0.4)).toList();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, shrunken);

      expect(counter.countedReps, 0);
      expect(
        results.any((result) => result.pauseReason == TrackingPauseReason.tooFar),
        isTrue,
      );
    });

    test('pauses on low landmark confidence and refuses to count', () {
      final source = SyntheticPoseSource.pushups(seed: 2, likelihood: 0.58);
      source.holdTop(900);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(
        results.any(
          (result) =>
              result.pauseReason == TrackingPauseReason.lowConfidence ||
              result.pauseReason == TrackingPauseReason.partialBody,
        ),
        isTrue,
      );
    });

    test('tracking loss resets the in-progress rep and surfaces the reason', () {
      final source = SyntheticPoseSource.pushups(seed: 8);
      source.holdTop(800);
      source.segment(source.topAngle, to: source.bottomAngle, durationMs: 700);
      source.trackingLoss(600);
      source.holdTop(700);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
      expect(
        results.any((result) => result.pauseReason == TrackingPauseReason.noPerson),
        isTrue,
      );
    });

    test('low light is reported as the pause reason', () {
      final source = SyntheticPoseSource.pushups(seed: 8);
      source.holdTop(800);
      source.trackingLoss(700, dark: true);
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(
        results.any((result) => result.pauseReason == TrackingPauseReason.lowLight),
        isTrue,
      );
      expect(counter.countedReps, 0);
    });

    test('a detector stall resets the rep and requires reframing', () {
      final source = SyntheticPoseSource.pushups(seed: 8);
      source.holdTop(800);
      source.segment(source.topAngle, to: source.bottomAngle, durationMs: 700);
      source.silence(1200);
      source.holdTop(700);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
      expect(
        results.any((result) => result.pauseReason == TrackingPauseReason.detectorStalled),
        isTrue,
      );
    });

    test('an interrupted rep is not completed across the gap', () {
      final source = SyntheticPoseSource.pushups(seed: 8);
      source.holdTop(800);
      source.segment(source.topAngle, to: 90, durationMs: 700);
      source.trackingLoss(600);
      source.segment(90, to: source.topAngle, durationMs: 900);
      source.holdTop(500);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
    });

    test('duplicate timestamps never count twice', () {
      final source = SyntheticPoseSource.pushups(seed: 11);
      source.holdTop(800);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      feedAll(counter, source.frames);
      final duplicate = counter.addFrame(source.frames.last);

      expect(duplicate.duplicateFrame, isTrue);
      expect(counter.countedReps, 1);
    });

    test('two consecutive full reps count exactly two', () {
      final source = SyntheticPoseSource.pushups(seed: 13);
      source.holdTop(800);
      source.rep();
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);

      feedAll(counter, source.frames);

      expect(counter.countedReps, 2);
    });
  });

  group('squat counter', () {
    test('counts a complete squat rep after stable framing', () {
      final source = SyntheticPoseSource.squats(seed: 21);
      source.holdTop(800);
      source.rep(descendMs: 1000, bottomHoldMs: 400, ascendMs: 1000);
      final counter = counterFor(ArenaExercise.squats);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
      expect(results.last.rejection, CounterRejection.none);
    });

    test('ignores a shallow squat', () {
      final source = SyntheticPoseSource.squats(seed: 22);
      source.holdTop(800);
      source.rep(bottomAngleOverride: 115, descendMs: 700, bottomHoldMs: 200, ascendMs: 700);
      final counter = counterFor(ArenaExercise.squats);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(
        results.where((result) => result.outcome).map((result) => result.rejection),
        [CounterRejection.notDeepEnough],
      );
    });

    test('rejects a folded-over torso at the bottom', () {
      final source = SyntheticPoseSource.squats(seed: 24);
      source.holdTop(800);
      source.rep(
        descendMs: 900,
        bottomHoldMs: 500,
        ascendMs: 900,
        torsoLean: 70,
      );
      final counter = counterFor(ArenaExercise.squats);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 0);
      expect(results.last.rejection, CounterRejection.torsoCollapsed);
      expect(
        results.where((result) => result.outcome).map((result) => result.rejection),
        [CounterRejection.torsoCollapsed],
      );
    });

    test('tracking loss mid-squat discards the in-progress rep', () {
      final source = SyntheticPoseSource.squats(seed: 25);
      source.holdTop(800);
      source.segment(source.topAngle, to: source.bottomAngle, durationMs: 900);
      source.trackingLoss(600);
      source.holdTop(800);
      source.rep(descendMs: 900, bottomHoldMs: 400, ascendMs: 900);
      final counter = counterFor(ArenaExercise.squats);

      feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
    });

    test('a heel lift at the bottom cues coaching and still counts', () {
      final source = SyntheticPoseSource.squats(seed: 26);
      final frames = [...source.holdTop(800)];
      for (final frame
          in source.rep(descendMs: 1000, bottomHoldMs: 400, ascendMs: 1000)) {
        frames.add(nearSquatBottom(frame) ? liftHeels(frame) : frame);
      }
      final counter = counterFor(ArenaExercise.squats);

      final results = feedAll(counter, frames);

      expect(counter.countedReps, 1);
      expect(
        results.any(
          (result) => result.pauseReason == TrackingPauseReason.heelsLifted,
        ),
        isTrue,
      );
    });

    test('flat heels never produce the heel cue', () {
      final source = SyntheticPoseSource.squats(seed: 23);
      source.holdTop(800);
      source.rep(descendMs: 1000, bottomHoldMs: 400, ascendMs: 1000);
      final counter = counterFor(ArenaExercise.squats);

      final results = feedAll(counter, source.frames);

      expect(counter.countedReps, 1);
      expect(
        results.every(
          (result) => result.pauseReason != TrackingPauseReason.heelsLifted,
        ),
        isTrue,
      );
    });

    test('untracked feet disable the heel cue instead of pausing', () {
      final source = SyntheticPoseSource.squats(seed: 26);
      final frames = source.holdTop(800).map(hideHeels).toList();
      for (final frame
          in source.rep(descendMs: 1000, bottomHoldMs: 400, ascendMs: 1000)) {
        frames.add(hideHeels(frame));
      }
      final counter = counterFor(ArenaExercise.squats);

      final results = feedAll(counter, frames);

      expect(counter.countedReps, 1);
      expect(
        results.every(
          (result) => result.pauseReason != TrackingPauseReason.heelsLifted,
        ),
        isTrue,
      );
    });
  });
}
