/// Head-on (front-view) counting: geometric cause, view detection, framing,
/// signal and the squat decision.
///
/// The side-view suite in `rep_counter_test.dart` stays untouched; this file
/// is the front-view regression home on top of the committed fixtures.
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/pose/pose_math.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fixture_replay.dart';

RepCounter counterFor(ArenaExercise exercise) =>
    RepCounter(ExerciseCounterProfile.forExercise(exercise));

/// A frame carrying only the landmarks view detection reads.
PoseFrame viewFrame({
  required int timestampMicros,
  required double shoulderWidth,
  required double torsoLength,
  double zSpread = 0,
  double likelihood = 0.9,
}) {
  const shoulderY = 0.4;
  final points = <PoseLandmarkType, PosePoint>{
    PoseLandmarkType.leftShoulder: PosePoint(
      x: 0.5 - shoulderWidth / 2,
      y: shoulderY,
      z: zSpread / 2,
      likelihood: likelihood,
    ),
    PoseLandmarkType.rightShoulder: PosePoint(
      x: 0.5 + shoulderWidth / 2,
      y: shoulderY,
      z: -zSpread / 2,
      likelihood: likelihood,
    ),
    PoseLandmarkType.leftHip: PosePoint(
      x: 0.5,
      y: shoulderY + torsoLength,
      likelihood: likelihood,
    ),
    PoseLandmarkType.rightHip: PosePoint(
      x: 0.5,
      y: shoulderY + torsoLength,
      likelihood: likelihood,
    ),
  };
  return PoseFrame.of(timestampMicros: timestampMicros, points: points);
}

PoseFrame _withLikelihood(
  PoseFrame frame,
  PoseLandmarkType type,
  double likelihood,
) {
  final points = <PoseLandmarkType, PosePoint>{};
  for (final landmark in PoseLandmarkType.values) {
    final point = frame.point(landmark);
    if (point == null) {
      continue;
    }
    points[landmark] = landmark == type
        ? PosePoint(
            x: point.x,
            y: point.y,
            z: point.z,
            likelihood: likelihood,
          )
        : point;
  }
  return PoseFrame.of(
    timestampMicros: frame.timestampMicros,
    points: points,
    luminance: frame.luminance,
  );
}

PoseFrame _scaleAboutCenter(PoseFrame frame, double scale) {
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

/// Hand-built standing front-view squat frame: wide shoulders, full torso,
/// and a knee that only moves in depth. [hipY] is the squat depth.
PoseFrame frontSquatFrame({
  required int timestampMicros,
  double hipY = 0.48,
}) {
  const shoulderY = 0.20;
  const kneeY = 0.72;
  const ankleY = 0.88;
  const kneeX = 0.52;
  return PoseFrame.of(
    timestampMicros: timestampMicros,
    points: <PoseLandmarkType, PosePoint>{
      PoseLandmarkType.nose:
          const PosePoint(x: 0.5, y: 0.14, likelihood: 0.9),
      PoseLandmarkType.leftShoulder:
          const PosePoint(x: 0.38, y: shoulderY, likelihood: 0.9),
      PoseLandmarkType.rightShoulder:
          const PosePoint(x: 0.62, y: shoulderY, likelihood: 0.9),
      PoseLandmarkType.leftElbow:
          const PosePoint(x: 0.36, y: 0.30, likelihood: 0.9),
      PoseLandmarkType.rightElbow:
          const PosePoint(x: 0.64, y: 0.30, likelihood: 0.9),
      PoseLandmarkType.leftWrist:
          const PosePoint(x: 0.34, y: 0.42, likelihood: 0.9),
      PoseLandmarkType.rightWrist:
          const PosePoint(x: 0.66, y: 0.42, likelihood: 0.9),
      PoseLandmarkType.leftHip:
          PosePoint(x: 0.5, y: hipY, likelihood: 0.9),
      PoseLandmarkType.rightHip:
          PosePoint(x: 0.5, y: hipY, likelihood: 0.9),
      PoseLandmarkType.leftKnee:
          const PosePoint(x: kneeX, y: kneeY, likelihood: 0.9),
      PoseLandmarkType.rightKnee:
          const PosePoint(x: 1 - kneeX, y: kneeY, likelihood: 0.9),
      PoseLandmarkType.leftAnkle:
          const PosePoint(x: 0.5, y: ankleY, likelihood: 0.9),
      PoseLandmarkType.rightAnkle:
          const PosePoint(x: 0.5, y: ankleY, likelihood: 0.9),
    },
  );
}

void main() {
  group('geometric cause', () {
    test('the side-view elbow angle never enters the bottom band head-on', () {
      final fixture = loadPoseFixture('pushups_front_clean_rep.txt');
      var minimum = 180.0;
      for (final frame in fixture.frames) {
        final shoulder = frame.point(PoseLandmarkType.leftShoulder);
        final elbow = frame.point(PoseLandmarkType.leftElbow);
        final wrist = frame.point(PoseLandmarkType.leftWrist);
        if (shoulder == null || elbow == null || wrist == null) {
          continue;
        }
        minimum = math.min(minimum, angleDegrees(shoulder, elbow, wrist));
      }
      expect(
        minimum,
        greaterThan(100),
        reason: 'the side-view bottom band (<= 100 deg) is never reached '
            'when the elbow bends towards the lens',
      );
    });

    test('the head-on signal separates the top from the bottom', () {
      final fixture = loadPoseFixture('pushups_front_clean_rep.txt');
      final counter = counterFor(ArenaExercise.pushUps);
      var top = 0.0;
      var bottom = double.infinity;
      for (final frame in fixture.frames) {
        final result = counter.addFrame(frame);
        final signal = result.signal;
        if (signal == null) {
          continue;
        }
        top = math.max(top, signal);
        bottom = math.min(bottom, signal);
      }
      expect(bottom, lessThan(0.60));
      expect(top, greaterThan(0.90));
      expect(top, greaterThan(bottom * 2));
    });
  });

  group('camera view detection', () {
    test('a profile-width body reads as a side view', () {
      expect(
        detectCameraViewMode(
          viewFrame(
            timestampMicros: 0,
            shoulderWidth: 0.05,
            torsoLength: 0.30,
          ),
        ),
        CameraViewMode.side,
      );
    });

    test('a wide, foreshortened body reads as a front view', () {
      expect(
        detectCameraViewMode(
          viewFrame(
            timestampMicros: 0,
            shoulderWidth: 0.24,
            torsoLength: 0.12,
          ),
        ),
        CameraViewMode.front,
      );
    });

    test('a standing front view reads as front', () {
      expect(
        detectCameraViewMode(
          viewFrame(
            timestampMicros: 0,
            shoulderWidth: 0.24,
            torsoLength: 0.30,
          ),
        ),
        CameraViewMode.front,
      );
    });

    test('the ratio boundaries leave a hysteresis band', () {
      expect(
        detectCameraViewMode(
          viewFrame(timestampMicros: 0, shoulderWidth: 0.76, torsoLength: 1),
        ),
        CameraViewMode.front,
      );
      expect(
        detectCameraViewMode(
          viewFrame(timestampMicros: 0, shoulderWidth: 0.74, torsoLength: 1),
        ),
        isNull,
      );
      expect(
        detectCameraViewMode(
          viewFrame(timestampMicros: 0, shoulderWidth: 0.36, torsoLength: 1),
        ),
        isNull,
      );
      expect(
        detectCameraViewMode(
          viewFrame(timestampMicros: 0, shoulderWidth: 0.34, torsoLength: 1),
        ),
        CameraViewMode.side,
      );
    });

    test('inside the band a small shoulder z-spread supports front', () {
      expect(
        detectCameraViewMode(
          viewFrame(
            timestampMicros: 0,
            shoulderWidth: 0.60,
            torsoLength: 1,
            zSpread: 0.02,
          ),
        ),
        CameraViewMode.front,
      );
    });

    test('inside the band a large shoulder z-spread supports side', () {
      expect(
        detectCameraViewMode(
          viewFrame(
            timestampMicros: 0,
            shoulderWidth: 0.60,
            torsoLength: 1,
            zSpread: 0.20,
          ),
        ),
        CameraViewMode.side,
      );
    });

    test('missing or low-confidence geometry is unknown', () {
      expect(detectCameraViewMode(SyntheticPose.noPerson(0)), isNull);
      expect(
        detectCameraViewMode(
          viewFrame(
            timestampMicros: 0,
            shoulderWidth: 0.6,
            torsoLength: 1,
            likelihood: 0.4,
          ),
        ),
        isNull,
      );
    });

    test('the counter keeps the previous mode on an ambiguous frame', () {
      final front = SyntheticPoseSource.pushupsFront(seed: 41);
      front.holdTop(800);
      final frontCounter = counterFor(ArenaExercise.pushUps);
      for (final frame in front.frames) {
        frontCounter.addFrame(frame);
      }
      final afterFront = frontCounter.addFrame(
        viewFrame(
          timestampMicros: front.frames.last.timestampMicros + 33000,
          shoulderWidth: 0.60,
          torsoLength: 1,
        ),
      );
      expect(afterFront.viewMode, CameraViewMode.front);

      final side = SyntheticPoseSource.pushups(seed: 42);
      side.holdTop(800);
      final sideCounter = counterFor(ArenaExercise.pushUps);
      for (final frame in side.frames) {
        sideCounter.addFrame(frame);
      }
      final afterSide = sideCounter.addFrame(
        viewFrame(
          timestampMicros: side.frames.last.timestampMicros + 33000,
          shoulderWidth: 0.60,
          torsoLength: 1,
        ),
      );
      expect(afterSide.viewMode, CameraViewMode.side);
    });
  });

  group('front-view counting', () {
    test('counts a head-on rep once with strong landmark noise', () {
      final source = SyntheticPoseSource.pushupsFront(
        seed: 45,
        noiseAmplitude: 0.012,
      );
      source.holdTop(800);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);
      for (final frame in source.frames) {
        counter.addFrame(frame);
      }
      expect(counter.countedReps, 1);
    });

    test('two consecutive head-on reps count exactly two', () {
      final source = SyntheticPoseSource.pushupsFront(seed: 46);
      source.holdTop(800);
      source.rep();
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);
      for (final frame in source.frames) {
        counter.addFrame(frame);
      }
      expect(counter.countedReps, 2);
    });

    test('head-on top-of-movement jitter counts nothing', () {
      final source = SyntheticPoseSource.pushupsFront(seed: 47);
      source.holdTop(800);
      source.jitterTop(1600, suspicionEvery: 5);
      final counter = counterFor(ArenaExercise.pushUps);
      for (final frame in source.frames) {
        counter.addFrame(frame);
      }
      expect(counter.countedReps, 0);
      expect(counter.framingLocked, isTrue);
    });
  });

  group('front-view framing', () {
    test('a shrunken head-on body reports tooFar and never counts', () {
      final source = SyntheticPoseSource.pushupsFront(seed: 43);
      source.holdTop(800);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);
      var tooFarSeen = false;
      for (final frame in source.frames) {
        final result = counter.addFrame(_scaleAboutCenter(frame, 0.35));
        tooFarSeen =
            tooFarSeen || result.pauseReason == TrackingPauseReason.tooFar;
      }
      expect(counter.countedReps, 0);
      expect(tooFarSeen, isTrue);
    });

    test('a head-on body with a hidden hand never locks framing', () {
      final source = SyntheticPoseSource.pushupsFront(seed: 44);
      source.holdTop(800);
      source.rep();
      final counter = counterFor(ArenaExercise.pushUps);
      var everLocked = false;
      var partialBodySeen = false;
      for (final frame in source.frames) {
        final result =
            counter.addFrame(_withLikelihood(frame, PoseLandmarkType.rightWrist, 0.2));
        everLocked = everLocked || result.framingLocked;
        partialBodySeen = partialBodySeen ||
            result.pauseReason == TrackingPauseReason.partialBody;
      }
      expect(counter.countedReps, 0);
      expect(everLocked, isFalse);
      expect(partialBodySeen, isTrue);
    });
  });

  group('squats stay side-view only', () {
    test('a front-view squat is refused with wrongView, never counted', () {
      final counter = counterFor(ArenaExercise.squats);
      var wrongViewSeen = false;
      var timestamp = 0;
      for (var i = 0; i < 20; i++) {
        timestamp += 33000;
        final result = counter.addFrame(frontSquatFrame(timestampMicros: timestamp));
        wrongViewSeen = wrongViewSeen ||
            result.pauseReason == TrackingPauseReason.wrongView;
      }
      expect(counter.countedReps, 0);
      expect(wrongViewSeen, isTrue);
    });

    test('the side-view knee angle cannot separate a front-view squat', () {
      final top = frontSquatFrame(timestampMicros: 0, hipY: 0.48);
      final bottom = frontSquatFrame(timestampMicros: 33000, hipY: 0.64);
      double kneeAngle(PoseFrame frame) => angleDegrees(
            frame.point(PoseLandmarkType.leftHip)!,
            frame.point(PoseLandmarkType.leftKnee)!,
            frame.point(PoseLandmarkType.leftAnkle)!,
          );
      final hipDrop = (top.point(PoseLandmarkType.leftHip)!.y -
              bottom.point(PoseLandmarkType.leftHip)!.y)
          .abs();
      expect(hipDrop, greaterThan(0.1));
      expect(kneeAngle(top), greaterThan(160));
      expect(kneeAngle(bottom), greaterThan(150));
      expect(
        kneeAngle(top) - kneeAngle(bottom),
        lessThan(20),
        reason: 'the 2D knee angle barely moves when the knee bends in depth',
      );
    });
  });
}

