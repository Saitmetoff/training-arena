/// Small, dependency-free geometry helpers used by the rep counter.
///
/// Everything here works on normalised pose landmarks (y grows downward), so
/// angles are unsigned 0..180 degree values and comparisons are done in
/// degrees. The functions are pure and synchronous so the state machine can be
/// tested on the host with synthetic fixtures.
library;

import 'dart:math' as math;

import '../camera_types.dart';
import '../counter/exercise_profile.dart';
import 'pose_types.dart';

/// Angle at [vertex] between the vectors to [first] and [second], in degrees.
///
/// Returns 0 when any vector has zero length.
double angleDegrees(PosePoint first, PosePoint vertex, PosePoint second, {double aspectRatio = 1}) {
  final ax = (first.x - vertex.x) * aspectRatio;
  final ay = first.y - vertex.y;
  final bx = (second.x - vertex.x) * aspectRatio;
  final by = second.y - vertex.y;
  final lengthA = math.sqrt(ax * ax + ay * ay);
  final lengthB = math.sqrt(bx * bx + by * by);
  if (lengthA == 0 || lengthB == 0) {
    return 0;
  }
  final cosine = ((ax * bx + ay * by) / (lengthA * lengthB)).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

/// Signed tilt of the [top] -> [bottom] segment away from vertical, in
/// degrees. Positive values lean towards +x (screen right / body forward in a
/// side view). Used for torso-lean guards, not for counting.
double leanDegrees(PosePoint top, PosePoint bottom, {double aspectRatio = 1}) {
  final dx = (bottom.x - top.x) * aspectRatio;
  final dy = bottom.y - top.y;
  if (dx == 0 && dy == 0) {
    return 0;
  }
  return math.atan2(dx, dy.abs()) * 180 / math.pi;
}

/// Inclination of the heel -> foot-index segment against the horizontal, in
/// unsigned degrees folded to 0..90 so either camera facing measures the same
/// foot (the single-facing `atan2` form would wrap near 180). A flat foot
/// measures near 0; a heel rising off the floor grows the value. Used for the
/// squat heels-lifted cue against a standing baseline, never for counting.
double heelToToeAngleDegrees(PosePoint heel, PosePoint toe, {double aspectRatio = 1}) {
  return math.atan2((heel.y - toe.y).abs(), (heel.x - toe.x).abs() * aspectRatio) *
      180 /
      math.pi;
}

/// Exponential moving average with [alpha] in (0, 1]. A `null` previous value
/// returns the sample unchanged.
double smoothValue(double? previous, double sample, double alpha) {
  if (previous == null) {
    return sample;
  }
  return previous + alpha * (sample - previous);
}

/// Distance between two landmarks in the 2D image plane. Depth (`z`) is
/// deliberately excluded: it is experimental and has no fixed origin.
double pointDistance(PosePoint a, PosePoint b, {double aspectRatio = 1}) {
  final dx = (a.x - b.x) * aspectRatio;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

/// Shoulder width over projected torso length: small in a profile view, large
/// when the athlete faces the lens. The wide gap is the hysteresis band: a
/// squatting athlete's projected torso shortens at the bottom, so the ratio
/// must not be allowed to flap the mode mid-rep. Candidate thresholds for F3.

/// Shoulder z-spread bounds supporting `front` / `side` when the ratio is
/// ambiguous. Candidates for F3.

/// Classifies the camera placement from shoulder and hip geometry.
///
/// The shoulder width divided by the projected shoulder-to-hip torso length
/// separates the two views; a small shoulder z-spread supports `front`, a
/// large one supports `side`. Depth is experimental, so the z term is ignored
/// when the frame carries no z at all (both shoulders exactly 0), and it only
/// breaks ties inside the ratio band. Returns `null` for an ambiguous or
/// incomplete frame: callers keep their previous mode and never invent one.
CameraViewMode? detectCameraViewMode(
  PoseFrame frame, {
  double minLikelihood = 0.55,
  double frontRatio = frontViewShoulderRatio,
  double sideRatio = sideViewShoulderRatio,
  double frontZSpread = frontViewShoulderZSpread,
  double sideZSpread = sideViewShoulderZSpread,
}) {
  final leftShoulder = frame.point(PoseLandmarkType.leftShoulder);
  final rightShoulder = frame.point(PoseLandmarkType.rightShoulder);
  final leftHip = frame.point(PoseLandmarkType.leftHip);
  final rightHip = frame.point(PoseLandmarkType.rightHip);
  if (leftShoulder == null ||
      rightShoulder == null ||
      leftHip == null ||
      rightHip == null) {
    return null;
  }
  if (leftShoulder.likelihood < minLikelihood ||
      rightShoulder.likelihood < minLikelihood ||
      leftHip.likelihood < minLikelihood ||
      rightHip.likelihood < minLikelihood) {
    return null;
  }
  final shoulderWidth = pointDistance(leftShoulder, rightShoulder, aspectRatio: frame.aspectRatio);
  final torsoDx = ((leftShoulder.x + rightShoulder.x) / 2 -
      (leftHip.x + rightHip.x) / 2) * frame.aspectRatio;
  final torsoDy = (leftShoulder.y + rightShoulder.y) / 2 -
      (leftHip.y + rightHip.y) / 2;
  final torsoLength = math.sqrt(torsoDx * torsoDx + torsoDy * torsoDy);
  if (shoulderWidth <= 0 || torsoLength <= 1e-6) {
    return null;
  }
  final ratio = shoulderWidth / torsoLength;
  final hasDepth = leftShoulder.z != 0 || rightShoulder.z != 0;
  final zSpread =
      hasDepth ? (leftShoulder.z - rightShoulder.z).abs() : null;
  final frontish = ratio >= frontRatio ||
      (zSpread != null && zSpread <= frontZSpread && ratio >= sideRatio);
  final sideish = ratio <= sideRatio ||
      (zSpread != null && zSpread >= sideZSpread && ratio <= frontRatio);
  if (frontish == sideish) {
    return null;
  }
  return frontish ? CameraViewMode.front : CameraViewMode.side;
}

/// Mean of [values]; returns 0 for an empty input.
double meanOf(Iterable<double> values) {
  var sum = 0.0;
  var count = 0;
  for (final value in values) {
    sum += value;
    count++;
  }
  return count == 0 ? 0 : sum / count;
}
