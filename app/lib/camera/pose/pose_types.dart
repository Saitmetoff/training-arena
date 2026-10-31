/// On-device pose landmark model shared by the native bridge, the rep
/// counter and the camera tests.
///
/// The landmark index order matches the ML Kit Pose Detection API
/// (`com.google.mlkit:pose-detection:18.0.0-beta5`, 33 landmarks). Coordinates
/// are normalised to the upright analysis frame: `x` grows to the right,
/// `y` grows downward, `z` has its origin near the subject's hips. The native
/// bridge converts ML Kit's image-pixel positions into this space; a
/// `PoseFrame` is an in-memory value only: it is never written to disk and
/// never leaves the device.
library;

/// The 33 ML Kit pose landmarks in SDK order. The enum's built-in `index`
/// matches the ML Kit landmark type integer, so it is the bridge wire value.
enum PoseLandmarkType {
  nose,
  leftEyeInner,
  leftEye,
  leftEyeOuter,
  rightEyeInner,
  rightEye,
  rightEyeOuter,
  leftEar,
  rightEar,
  mouthLeft,
  mouthRight,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftPinky,
  rightPinky,
  leftIndex,
  rightIndex,
  leftThumb,
  rightThumb,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex;

  /// Total number of ML Kit landmarks.
  static const int count = 33;

  /// Returns the landmark for an index or `null` when out of range.
  static PoseLandmarkType? tryFromIndex(Object? value) {
    if (value is! int || value < 0 || value >= count) {
      return null;
    }
    return values[value];
  }
}

/// Which body side a joint angle was measured on.
enum PoseSide {
  left,
  right;

  PoseLandmarkType shoulder() =>
      this == PoseSide.left ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder;

  PoseLandmarkType elbow() =>
      this == PoseSide.left ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow;

  PoseLandmarkType wrist() =>
      this == PoseSide.left ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist;

  PoseLandmarkType hip() =>
      this == PoseSide.left ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip;

  PoseLandmarkType knee() =>
      this == PoseSide.left ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee;

  PoseLandmarkType ankle() =>
      this == PoseSide.left ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle;

  PoseLandmarkType heel() =>
      this == PoseSide.left ? PoseLandmarkType.leftHeel : PoseLandmarkType.rightHeel;

  PoseLandmarkType footIndex() =>
      this == PoseSide.left ? PoseLandmarkType.leftFootIndex : PoseLandmarkType.rightFootIndex;
}

/// One landmark sample. [likelihood] is ML Kit's in-frame likelihood, not a
/// calibrated probability.
class PosePoint {
  const PosePoint({
    required this.x,
    required this.y,
    this.z = 0,
    required this.likelihood,
  });

  final double x;
  final double y;
  final double z;
  final double likelihood;
}

/// Axis-aligned bounds of a set of landmarks in normalised frame space.
class PoseBounds {
  const PoseBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;

  double get height => bottom - top;

  double get centerX => (left + right) / 2;

  double get centerY => (top + bottom) / 2;

  /// Largest span, used as a cheap body-size estimate.
  double get span => width > height ? width : height;
}

/// One analysis-frame worth of landmarks. Frames are processed in memory and
/// dropped immediately; nothing here is persisted or uploaded.
class PoseFrame {
  PoseFrame({
    required this.timestampMicros,
    required List<PosePoint?> landmarks,
    this.luminance = 1,
    this.aspectRatio = 1,
  })  : assert(landmarks.length == PoseLandmarkType.count),
        landmarks = List<PosePoint?>.unmodifiable(landmarks);

  /// Convenience builder for fixtures and synthetic frames.
  PoseFrame.of({
    required this.timestampMicros,
    required Map<PoseLandmarkType, PosePoint> points,
    this.luminance = 1,
    this.aspectRatio = 1,
  }) : landmarks = List<PosePoint?>.unmodifiable(
          List<PosePoint?>.generate(
            PoseLandmarkType.count,
            (index) => points[PoseLandmarkType.values[index]],
            growable: false,
          ),
        );

  /// Empty frame: the detector saw nothing. Used for tracking-loss tests and
  /// for the native `lost` signal.
  PoseFrame.empty({required this.timestampMicros, this.luminance = 1, this.aspectRatio = 1})
      : landmarks = List<PosePoint?>.unmodifiable(
          List<PosePoint?>.filled(PoseLandmarkType.count, null),
        );

  /// Local monotonic timestamp in microseconds (`elapsedRealtimeNanos / 1000`
  /// on Android). Never derived from the wall clock.
  final int timestampMicros;

  /// Upright analysis width / height. Bounds stay normalized per axis.
  final double aspectRatio;

  /// Landmark slot per [PoseLandmarkType.index]; `null` when not returned.
  final List<PosePoint?> landmarks;

  /// Mean normalised Y-plane luminance (0..1) of the analysed frame. Used for
  /// the low-light cue, never persisted.
  final double luminance;

  bool get hasPose => landmarks.any((point) => point != null);

  PosePoint? point(PoseLandmarkType type) => landmarks[type.index];

  bool has(PoseLandmarkType type) => point(type) != null;

  /// Mean in-frame likelihood across [types]; missing landmarks count as 0.
  double confidenceOf(Iterable<PoseLandmarkType> types) {
    var sum = 0.0;
    var count = 0;
    for (final type in types) {
      sum += point(type)?.likelihood ?? 0;
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  /// True when every landmark in [types] is present with a likelihood of at
  /// least [minLikelihood].
  bool allVisible(Iterable<PoseLandmarkType> types, {double minLikelihood = 0.5}) {
    for (final type in types) {
      final point = this.point(type);
      if (point == null || point.likelihood < minLikelihood) {
        return false;
      }
    }
    return true;
  }

  /// Bounds over the given landmarks; missing landmarks are skipped. Returns
  /// `null` when none are present.
  PoseBounds? boundsOf(Iterable<PoseLandmarkType> types) {
    double? left;
    double? top;
    double? right;
    double? bottom;
    for (final type in types) {
      final point = this.point(type);
      if (point == null) {
        continue;
      }
      left = left == null || point.x < left ? point.x : left;
      right = right == null || point.x > right ? point.x : right;
      top = top == null || point.y < top ? point.y : top;
      bottom = bottom == null || point.y > bottom ? point.y : bottom;
    }
    if (left == null || top == null || right == null || bottom == null) {
      return null;
    }
    return PoseBounds(left: left, top: top, right: right, bottom: bottom);
  }
}
