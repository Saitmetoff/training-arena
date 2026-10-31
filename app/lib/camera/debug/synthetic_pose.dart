/// Deterministic synthetic landmarks for the debug fixture path and host
/// tests.
///
/// This is **not a detector** and makes no accuracy claim: it is a scripted
/// geometry generator used to exercise the rep state machine and to show a
/// visibly non-competitive demo. Every frame it emits is flagged by
/// `FixtureCameraBridge` as non-competitive and no detector is involved.
library;

import 'dart:math' as math;

import '../pose/pose_types.dart';

/// Tiny deterministic LCG so the same seed always produces the same noise.
class SyntheticNoise {
  SyntheticNoise(this.seed) : _state = seed & 0x7fffffff;

  final int seed;
  int _state;

  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }

  /// Value in [-amplitude, amplitude].
  double jitter(double amplitude) => (next() * 2 - 1) * amplitude;
}

/// Which exercise a synthetic landmark set represents.
enum SyntheticExercise { pushUps, squats }

/// Builds one synthetic landmark frame for the requested joint angle.
abstract final class SyntheticPose {
  /// Push-up side view: the primary angle is the elbow between shoulder and
  /// wrist. [hipDrop] moves the hip off the shoulder-ankle line to simulate
  /// sag/pike for negative tests.
  static PoseFrame pushupFrame({
    required int timestampMicros,
    required double elbowAngle,
    SyntheticNoise? noise,
    double hipDrop = 0,
    double likelihood = 0.92,
    double luminance = 0.55,
    double noiseAmplitude = 0.004,
  }) {
    const wristX = 0.50;
    const wristY = 0.86;
    const upperArm = 0.13;
    const forearm = 0.13;
    const shoulderInset = 0.03;

    final d = math.sqrt(
      upperArm * upperArm +
          forearm * forearm -
          2 * upperArm * forearm * math.cos(elbowAngle * math.pi / 180),
    );
    const sx = wristX - shoulderInset;
    final sy = wristY - math.sqrt(math.max(d * d - shoulderInset * shoulderInset, 1e-9));
    final shoulder = _Joint(sx, sy);
    const wrist = _Joint(wristX, wristY);

    final half = d / 2;
    final height = math.sqrt(math.max(upperArm * upperArm - half * half, 0));
    final ux = (wrist.x - shoulder.x) / d;
    final uy = (wrist.y - shoulder.y) / d;
    final elbow = _Joint(
      shoulder.x + ux * half - uy * height,
      shoulder.y + uy * half + ux * height,
    );

    const dirX = -0.995;
    const dirY = -0.10;
    final dirLength = math.sqrt(dirX * dirX + dirY * dirY);
    final nx = dirX / dirLength;
    final ny = dirY / dirLength;

    final hip = _Joint(shoulder.x + nx * 0.17, shoulder.y + ny * 0.17 + hipDrop);
    final knee = _Joint(shoulder.x + nx * 0.27, shoulder.y + ny * 0.27);
    final ankle = _Joint(shoulder.x + nx * 0.36, shoulder.y + ny * 0.36);
    final heel = _Joint(ankle.x + 0.035, ankle.y - 0.035);
    final foot = _Joint(ankle.x - 0.045, ankle.y + 0.005);
    final nose = _Joint(shoulder.x + 0.06, shoulder.y - 0.035);

    return _frame(
      timestampMicros: timestampMicros,
      luminance: luminance,
      noise: noise,
      likelihood: likelihood,
      noiseAmplitude: noiseAmplitude,
      leftPoints: {
        PoseLandmarkType.nose: nose,
        PoseLandmarkType.leftShoulder: shoulder,
        PoseLandmarkType.leftElbow: elbow,
        PoseLandmarkType.leftWrist: wrist,
        PoseLandmarkType.leftHip: hip,
        PoseLandmarkType.leftKnee: knee,
        PoseLandmarkType.leftAnkle: ankle,
        PoseLandmarkType.leftHeel: heel,
        PoseLandmarkType.leftFootIndex: foot,
      },
      rightPoints: {
        PoseLandmarkType.rightShoulder: shoulder,
        PoseLandmarkType.rightElbow: elbow,
        PoseLandmarkType.rightWrist: wrist,
        PoseLandmarkType.rightHip: hip,
        PoseLandmarkType.rightKnee: knee,
        PoseLandmarkType.rightAnkle: ankle,
        PoseLandmarkType.rightHeel: heel,
        PoseLandmarkType.rightFootIndex: foot,
      },
    );
  }

  /// Push-up front (head-on) view: the athlete faces the lens and the body
  /// extends away, so the torso and legs are foreshortened and the knees and
  /// ankles are omitted (a floor-level head-on view usually cannot see them
  /// behind the torso). The elbow bends towards the lens, so the 2D elbow angle
  /// stays high while the shoulder height above the hands drops: that vertical
  /// displacement, normalised by shoulder width, is the front-view signal.
  ///
  /// [sag] pushes the hips down in the image to simulate a sagging body for
  /// negative tests; a straight body keeps a constant shoulder-to-hip offset.
  static PoseFrame pushupFrontFrame({
    required int timestampMicros,
    required double elbowAngle,
    SyntheticNoise? noise,
    double sag = 0,
    double likelihood = 0.92,
    double luminance = 0.55,
    double noiseAmplitude = 0.004,
  }) {
    const wristLeftX = 0.40;
    const wristRightX = 0.60;
    const wristY = 0.86;
    const shoulderLeftX = 0.38;
    const shoulderRightX = 0.62;
    const upperArm = 0.13;
    const forearm = 0.13;
    const elbowFlare = 0.015;

    final chord = math.sqrt(
      upperArm * upperArm +
          forearm * forearm -
          2 * upperArm * forearm * math.cos(elbowAngle * math.pi / 180),
    );
    // A straight arm points almost straight down towards the hand; a bent arm
    // points down and away from the lens, so less of its length survives the
    // 2D projection.
    final verticalFraction =
        (0.55 + (elbowAngle - 88) * 0.40 / 72).clamp(0.0, 1.0);
    final shoulderY = wristY - chord * verticalFraction;
    final hip = _Joint(0.5, shoulderY + 0.12 + sag);
    final nose = _Joint(0.5, shoulderY - 0.06);

    final leftShoulder = _Joint(shoulderLeftX, shoulderY);
    final rightShoulder = _Joint(shoulderRightX, shoulderY);
    const leftWrist = _Joint(wristLeftX, wristY);
    const rightWrist = _Joint(wristRightX, wristY);
    final leftElbow = _Joint(
      (leftShoulder.x + leftWrist.x) / 2 - elbowFlare,
      (leftShoulder.y + leftWrist.y) / 2,
    );
    final rightElbow = _Joint(
      (rightShoulder.x + rightWrist.x) / 2 + elbowFlare,
      (rightShoulder.y + rightWrist.y) / 2,
    );

    return _frame(
      timestampMicros: timestampMicros,
      luminance: luminance,
      noise: noise,
      likelihood: likelihood,
      noiseAmplitude: noiseAmplitude,
      leftPoints: {
        PoseLandmarkType.nose: nose,
        PoseLandmarkType.leftShoulder: leftShoulder,
        PoseLandmarkType.leftElbow: leftElbow,
        PoseLandmarkType.leftWrist: leftWrist,
        PoseLandmarkType.leftHip: hip,
      },
      rightPoints: {
        PoseLandmarkType.rightShoulder: rightShoulder,
        PoseLandmarkType.rightElbow: rightElbow,
        PoseLandmarkType.rightWrist: rightWrist,
        PoseLandmarkType.rightHip: hip,
      },
    );
  }

  /// Squat side view: the primary angle is the knee between hip and ankle.
  /// The hip travels down and back while the knee tracks forward over the
  /// foot, as in an actual squat. [torsoLean] overrides the derived forward
  /// lean for collapse tests; `null` derives the lean from the knee angle.
  static PoseFrame squatFrame({
    required int timestampMicros,
    required double kneeAngle,
    SyntheticNoise? noise,
    double? torsoLean,
    double likelihood = 0.92,
    double luminance = 0.55,
    double noiseAmplitude = 0.004,
  }) {
    const ankleX = 0.50;
    const ankleY = 0.88;
    const shinLength = 0.18;
    const thighLength = 0.22;
    const torsoLength = 0.30;

    const ankle = _Joint(ankleX, ankleY);
    final angleRad = kneeAngle * math.pi / 180;
    final hipDistance = math.sqrt(
      shinLength * shinLength +
          thighLength * thighLength -
          2 * shinLength * thighLength * math.cos(angleRad),
    );
    final hipBeta = (8 + (175 - kneeAngle) * 22 / 95).clamp(0, 60) * math.pi / 180;
    final hip = _Joint(
      ankleX - math.sin(hipBeta) * hipDistance,
      ankleY - math.cos(hipBeta) * hipDistance,
    );
    final ux = (hip.x - ankleX) / hipDistance;
    final uy = (hip.y - ankleY) / hipDistance;
    final along = (shinLength * shinLength - thighLength * thighLength +
            hipDistance * hipDistance) /
        (2 * hipDistance);
    final offset = math.sqrt(math.max(shinLength * shinLength - along * along, 0));
    final knee = _Joint(
      ankleX + ux * along - uy * offset,
      ankleY + uy * along + ux * offset,
    );
    final leanDegrees = torsoLean ?? (175 - kneeAngle) * 30 / 95;
    final lean = leanDegrees * math.pi / 180;
    final shoulder = _Joint(
      hip.x + math.sin(lean) * torsoLength,
      hip.y - math.cos(lean) * torsoLength,
    );
    final elbow = _Joint(shoulder.x + 0.09, shoulder.y + 0.02);
    final wrist = _Joint(shoulder.x + 0.17, shoulder.y + 0.05);
    final nose = _Joint(shoulder.x + 0.05, shoulder.y - 0.035);
    final heel = _Joint(ankle.x - 0.04, ankle.y + 0.01);
    final foot = _Joint(ankle.x + 0.06, ankle.y + 0.005);

    return _frame(
      timestampMicros: timestampMicros,
      luminance: luminance,
      noise: noise,
      likelihood: likelihood,
      noiseAmplitude: noiseAmplitude,
      leftPoints: {
        PoseLandmarkType.nose: nose,
        PoseLandmarkType.leftShoulder: shoulder,
        PoseLandmarkType.leftElbow: elbow,
        PoseLandmarkType.leftWrist: wrist,
        PoseLandmarkType.leftHip: hip,
        PoseLandmarkType.leftKnee: knee,
        PoseLandmarkType.leftAnkle: ankle,
        PoseLandmarkType.leftHeel: heel,
        PoseLandmarkType.leftFootIndex: foot,
      },
      rightPoints: {
        PoseLandmarkType.rightShoulder: shoulder,
        PoseLandmarkType.rightElbow: elbow,
        PoseLandmarkType.rightWrist: wrist,
        PoseLandmarkType.rightHip: hip,
        PoseLandmarkType.rightKnee: knee,
        PoseLandmarkType.rightAnkle: ankle,
        PoseLandmarkType.rightHeel: heel,
        PoseLandmarkType.rightFootIndex: foot,
      },
    );
  }

  /// Empty frame with normal light: the person is missing.
  static PoseFrame noPerson(int timestampMicros) =>
      PoseFrame.empty(timestampMicros: timestampMicros, luminance: 0.55);

  /// Empty frame with very low luminance: the low-light cue.
  static PoseFrame lowLight(int timestampMicros) =>
      PoseFrame.empty(timestampMicros: timestampMicros, luminance: 0.05);

  static PoseFrame _frame({
    required int timestampMicros,
    required double luminance,
    required SyntheticNoise? noise,
    required double likelihood,
    required double noiseAmplitude,
    required Map<PoseLandmarkType, _Joint> leftPoints,
    required Map<PoseLandmarkType, _Joint> rightPoints,
  }) {
    final points = <PoseLandmarkType, PosePoint>{};
    void add(Map<PoseLandmarkType, _Joint> source, double dx, double dy, double scale) {
      source.forEach((type, joint) {
        points[type] = PosePoint(
          x: joint.x + dx + (noise?.jitter(noiseAmplitude) ?? 0),
          y: joint.y + dy + (noise?.jitter(noiseAmplitude) ?? 0),
          z: noise?.jitter(noiseAmplitude * 2) ?? 0,
          likelihood:
              (likelihood * scale + (noise?.jitter(0.02) ?? 0)).clamp(0.0, 1.0),
        );
      });
    }

    add(leftPoints, 0.008, 0.003, 1.0);
    add(rightPoints, -0.008, -0.003, 0.95);
    return PoseFrame.of(
      timestampMicros: timestampMicros,
      points: points,
      luminance: luminance,
    );
  }
}

class _Joint {
  const _Joint(this.x, this.y);
  final double x;
  final double y;
}

/// Mutable frame source that timestamps frames monotonically and remembers
/// everything it emitted, so tests can assert on the complete sequence.
class SyntheticPoseSource {
  SyntheticPoseSource({
    required this.exercise,
    this.intervalMicros = 33000,
    this.seed = 1,
    this.likelihood = 0.92,
    this.luminance = 0.55,
    this.noiseAmplitude = 0.004,
    this.frontView = false,
  }) : _noise = SyntheticNoise(seed);

  factory SyntheticPoseSource.pushups({
    int intervalMicros = 33000,
    int seed = 1,
    double likelihood = 0.92,
    double noiseAmplitude = 0.004,
  }) =>
      SyntheticPoseSource(
        exercise: SyntheticExercise.pushUps,
        intervalMicros: intervalMicros,
        seed: seed,
        likelihood: likelihood,
        noiseAmplitude: noiseAmplitude,
      );

  factory SyntheticPoseSource.squats({
    int intervalMicros = 33000,
    int seed = 1,
    double likelihood = 0.92,
    double noiseAmplitude = 0.004,
  }) =>
      SyntheticPoseSource(
        exercise: SyntheticExercise.squats,
        intervalMicros: intervalMicros,
        seed: seed,
        likelihood: likelihood,
        noiseAmplitude: noiseAmplitude,
      );

  /// Push-ups filmed head-on ([SyntheticPose.pushupFrontFrame]).
  factory SyntheticPoseSource.pushupsFront({
    int intervalMicros = 33000,
    int seed = 1,
    double likelihood = 0.92,
    double noiseAmplitude = 0.004,
  }) =>
      SyntheticPoseSource(
        exercise: SyntheticExercise.pushUps,
        intervalMicros: intervalMicros,
        seed: seed,
        likelihood: likelihood,
        noiseAmplitude: noiseAmplitude,
        frontView: true,
      );

  final SyntheticExercise exercise;
  final int intervalMicros;
  final int seed;
  final double likelihood;
  final double luminance;
  final double noiseAmplitude;

  /// True for the head-on push-up generator.
  final bool frontView;

  final SyntheticNoise _noise;
  final List<PoseFrame> frames = [];
  int _timestamp = 0;

  double get topAngle => exercise == SyntheticExercise.pushUps ? 160 : 175;

  double get bottomAngle => exercise == SyntheticExercise.pushUps ? 88 : 80;

  /// Valid top-of-movement frames. Used as the framing lead-in.
  List<PoseFrame> holdTop(int durationMs) =>
      _segment(topAngle, topAngle, durationMs);

  /// A complete rep from the top, down and back up.
  List<PoseFrame> rep({
    int descendMs = 800,
    int bottomHoldMs = 300,
    int ascendMs = 800,
    double? bottomAngleOverride,
    double hipDrop = 0,
    double? torsoLean,
    double frontSag = 0,
  }) {
    final resolvedBottom = bottomAngleOverride ?? bottomAngle;
    return [
      ..._segment(topAngle, resolvedBottom, descendMs,
          hipDrop: hipDrop, torsoLean: torsoLean, frontSag: frontSag),
      ..._segment(resolvedBottom, resolvedBottom, bottomHoldMs,
          hipDrop: hipDrop, torsoLean: torsoLean, frontSag: frontSag),
      ..._segment(resolvedBottom, topAngle, ascendMs,
          hipDrop: hipDrop, torsoLean: torsoLean, frontSag: frontSag),
    ];
  }

  /// A rep that never reaches the bottom band.
  List<PoseFrame> partialRep({double minimum = 118, int durationMs = 700}) => [
        ..._segment(topAngle, minimum, durationMs ~/ 2),
        ..._segment(minimum, topAngle, durationMs ~/ 2),
      ];

  /// Arbitrary angle sweep, for interrupted-rep and validator fixtures.
  List<PoseFrame> segment(
    double from, {
    required double to,
    required int durationMs,
    double hipDrop = 0,
    double? torsoLean,
    double frontSag = 0,
  }) =>
      _segment(from, to, durationMs,
          hipDrop: hipDrop, torsoLean: torsoLean, frontSag: frontSag);

  /// Top-of-movement jitter with occasional threshold rumours.
  List<PoseFrame> jitterTop(int durationMs, {int suspicionEvery = 6}) {
    final frames = <PoseFrame>[];
    final count = (durationMs / (intervalMicros / 1000)).floor();
    for (var i = 0; i < count; i++) {
      final suspicion = i % suspicionEvery == 0 && i != 0;
      frames.add(_frameAt(suspicion ? 149 : topAngle + _noise.jitter(2)));
    }
    this.frames.addAll(frames);
    return frames;
  }

  /// Losing the subject for [durationMs]; optionally pitch dark.
  List<PoseFrame> trackingLoss(int durationMs, {bool dark = false}) {
    final frames = <PoseFrame>[];
    final count = math.max(1, (durationMs / (intervalMicros / 1000)).floor());
    for (var i = 0; i < count; i++) {
      _timestamp += intervalMicros;
      frames.add(
        dark
            ? SyntheticPose.lowLight(_timestamp)
            : SyntheticPose.noPerson(_timestamp),
      );
    }
    this.frames.addAll(frames);
    return frames;
  }

  /// Advances the clock without emitting frames: a detector stall.
  void silence(int durationMs) {
    _timestamp += durationMs * 1000;
  }

  PoseFrame _frameAt(double angle) {
    _timestamp += intervalMicros;
    switch (exercise) {
      case SyntheticExercise.pushUps:
        return frontView
            ? SyntheticPose.pushupFrontFrame(
                timestampMicros: _timestamp,
                elbowAngle: angle,
                noise: _noise,
                likelihood: likelihood,
                luminance: luminance,
                noiseAmplitude: noiseAmplitude,
              )
            : SyntheticPose.pushupFrame(
                timestampMicros: _timestamp,
                elbowAngle: angle,
                noise: _noise,
                likelihood: likelihood,
                luminance: luminance,
                noiseAmplitude: noiseAmplitude,
              );
      case SyntheticExercise.squats:
        return SyntheticPose.squatFrame(
          timestampMicros: _timestamp,
          kneeAngle: angle,
          noise: _noise,
          likelihood: likelihood,
          luminance: luminance,
          noiseAmplitude: noiseAmplitude,
        );
    }
  }

  List<PoseFrame> _segment(
    double from,
    double to,
    int durationMs, {
    double hipDrop = 0,
    double? torsoLean,
    double frontSag = 0,
  }) {
    if (durationMs <= 0) {
      return const [];
    }
    final frames = <PoseFrame>[];
    final steps = math.max(1, (durationMs / (intervalMicros / 1000)).ceil());
    for (var i = 1; i <= steps; i++) {
      final fraction = math.min(1.0, i * intervalMicros / (durationMs * 1000));
      final angle = from + (to - from) * fraction;
      _timestamp += intervalMicros;
      switch (exercise) {
        case SyntheticExercise.pushUps:
          frames.add(
            frontView
                ? SyntheticPose.pushupFrontFrame(
                    timestampMicros: _timestamp,
                    elbowAngle: angle,
                    noise: _noise,
                    sag: frontSag,
                    likelihood: likelihood,
                    luminance: luminance,
                    noiseAmplitude: noiseAmplitude,
                  )
                : SyntheticPose.pushupFrame(
                    timestampMicros: _timestamp,
                    elbowAngle: angle,
                    noise: _noise,
                    hipDrop: hipDrop,
                    likelihood: likelihood,
                    luminance: luminance,
                    noiseAmplitude: noiseAmplitude,
                  ),
          );
        case SyntheticExercise.squats:
          frames.add(
            SyntheticPose.squatFrame(
              timestampMicros: _timestamp,
              kneeAngle: angle,
              noise: _noise,
              torsoLean: torsoLean,
              likelihood: likelihood,
              luminance: luminance,
              noiseAmplitude: noiseAmplitude,
            ),
          );
      }
    }
    this.frames.addAll(frames);
    return frames;
  }
}
