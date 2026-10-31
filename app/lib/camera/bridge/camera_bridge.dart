/// Flutter/native bridge for on-device pose tracking.
///
/// Channel contract (owned by task `03`, frozen here):
///
/// | Channel | Type | Direction | Purpose |
/// | --- | --- | --- | --- |
/// | `trainingarena/device` | `MethodChannel` | Dart → native | permission, camera lifecycle, torch, runtime info |
/// | `trainingarena/pose` | `EventChannel` | native → Dart | landmarks or tracking-loss signals |
/// | `trainingarena/cues` | `EventChannel` | native → Dart | native framing/lighting cues |
///
/// The bridge carries numbers only: landmarks, luminance, timestamps and
/// codes. Images, thumbnails and encoded frames are never part of the
/// protocol in either direction. The event types below deliberately have no
/// field that could carry a frame.
library;

import '../../domain/arena_types.dart';
import '../camera_types.dart';
import '../pose/pose_types.dart';

/// Platform channel names.
abstract final class CameraChannels {
  static const String device = 'trainingarena/device';
  static const String pose = 'trainingarena/pose';
  static const String cues = 'trainingarena/cues';
}

/// Bridge failure carrying the native error code.
class CameraBridgeException implements Exception {
  const CameraBridgeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CameraBridgeException($code): $message';
}

/// Typed event received on `trainingarena/pose`.
sealed class PoseBridgeEvent {
  const PoseBridgeEvent(this.timestampMicros);

  final int timestampMicros;
}

/// A full landmark frame. Kept in memory only.
class PoseFrameEvent extends PoseBridgeEvent {
  PoseFrameEvent({required this.frame}) : super(frame.timestampMicros);

  final PoseFrame frame;
}

class PosePreviewEvent extends PoseBridgeEvent {
  const PosePreviewEvent({required this.geometry, required int timestampMicros})
      : super(timestampMicros);

  final CameraPreviewGeometry geometry;
}

/// Native tracking signal without landmarks (loss, reacquisition, pause).
class PoseTrackingEvent extends PoseBridgeEvent {
  const PoseTrackingEvent({
    required this.state,
    required this.reason,
    required this.luminance,
    required int timestampMicros,
  }) : super(timestampMicros);

  final CameraTrackingState state;
  final TrackingPauseReason reason;
  final double luminance;
}

/// Fatal or recoverable detector/camera error from native.
class PoseErrorEvent extends PoseBridgeEvent {
  const PoseErrorEvent({
    required this.code,
    required this.message,
    required int timestampMicros,
  }) : super(timestampMicros);

  final String code;
  final String message;
}

/// User-facing native cue such as low light or camera readiness.
class CameraCueEvent {
  const CameraCueEvent({
    required this.code,
    required this.timestampMicros,
    this.message,
  });

  final String code;
  final String? message;
  final int timestampMicros;
}

/// Host-testable seam between the camera session and the Android bridge.
abstract class CameraBridge {
  Stream<PoseBridgeEvent> get poseEvents;

  Stream<CameraCueEvent> get cueEvents;

  Future<CameraPermissionStatus> checkPermission();

  Future<CameraPermissionStatus> requestPermission();

  Future<bool> openAppSettings();

  Future<bool> hasCamera();

  /// Starts the local preview pipeline and returns the Flutter texture id.
  Future<int> startPreview(ArenaExercise exercise);

  Future<void> setTorch(bool enabled);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<CameraRuntimeInfo> runtimeInfo();

  /// Releases the camera, the detector and the preview texture. Idempotent.
  Future<void> dispose();
}

/// Parses one `trainingarena/pose` payload. Unknown or malformed payloads
/// return `null` so a newer native side can add event types safely.
PoseBridgeEvent? parsePoseBridgeEvent(Object? raw) {
  if (raw is! Map<Object?, Object?>) {
    return null;
  }
  final type = raw['type'];
  final timestamp = _intOf(raw['timestamp_us']) ?? 0;
  switch (type) {
    case 'preview':
      final width = _doubleOf(raw['width']);
      final height = _doubleOf(raw['height']);
      final crop = _numbers(raw['crop'], 4);
      final matrix = _numbers(raw['analysis_to_preview'], 6);
      final turns = raw['texture_quarter_turns'];
      final mirrored = raw['mirrored'];
      if (width == null ||
          height == null ||
          width <= 0 ||
          height <= 0 ||
          crop == null ||
          matrix == null ||
          turns is! int ||
          turns < 0 ||
          turns > 3 ||
          mirrored is! bool ||
          crop[0] < 0 ||
          crop[1] < 0 ||
          crop[2] > width ||
          crop[3] > height ||
          crop[2] <= crop[0] ||
          crop[3] <= crop[1]) {
        return null;
      }
      if ((matrix[0] * matrix[4] - matrix[1] * matrix[3]).abs() < 1e-9) {
        return null;
      }
      return PosePreviewEvent(
        timestampMicros: timestamp,
        geometry: CameraPreviewGeometry(
          width: width,
          height: height,
          crop: crop,
          analysisToPreview: matrix,
          textureQuarterTurns: turns,
          mirrored: mirrored,
        ),
      );
    case 'pose':
      final landmarks = raw['landmarks'];
      if (landmarks is! List) {
        return null;
      }
      final frameWidth = _doubleOf(raw['frame_width']);
      final frameHeight = _doubleOf(raw['frame_height']);
      if (frameWidth == null ||
          frameHeight == null ||
          frameWidth <= 0 ||
          frameHeight <= 0) {
        // ML Kit positions are image pixels in the upright analysis frame;
        // without that frame's size they cannot be normalised, so the event is
        // dropped instead of feeding pixel values to the counter.
        return null;
      }
      return PoseFrameEvent(
        frame: _parseFrame(
          landmarks,
          timestamp,
          _doubleOf(raw['luminance']) ?? 1,
          frameWidth: frameWidth,
          frameHeight: frameHeight,
        ),
      );
    case 'tracking':
      return PoseTrackingEvent(
        state: CameraTrackingState.fromWire(raw['state']),
        reason: TrackingPauseReason.fromWire(raw['reason']),
        luminance: _doubleOf(raw['luminance']) ?? 1,
        timestampMicros: timestamp,
      );
    case 'error':
      final code = raw['code'];
      if (code is! String || code.isEmpty) {
        return null;
      }
      final message = raw['message'];
      return PoseErrorEvent(
        code: code,
        message: message is String ? message : code,
        timestampMicros: timestamp,
      );
    default:
      return null;
  }
}

/// Parses one `trainingarena/cues` payload.
CameraCueEvent? parseCameraCueEvent(Object? raw) {
  if (raw is! Map<Object?, Object?>) {
    return null;
  }
  final code = raw['code'];
  if (code is! String || code.isEmpty) {
    return null;
  }
  final message = raw['message'];
  return CameraCueEvent(
    code: code,
    message: message is String ? message : null,
    timestampMicros: _intOf(raw['timestamp_us']) ?? 0,
  );
}

/// Parses one landmark list into a [PoseFrame], normalising the detector's
/// image-pixel positions against the upright analysis frame the landmarks were
/// measured in (`x` by [frameWidth], `y` by [frameHeight]; `z` shares the
/// x/y unit, so it scales by [frameWidth]).
PoseFrame _parseFrame(
  List<Object?> rawLandmarks,
  int timestampMicros,
  double luminance, {
  required double frameWidth,
  required double frameHeight,
}) {
  final points = <PoseLandmarkType, PosePoint>{};
  for (final raw in rawLandmarks) {
    if (raw is! Map<Object?, Object?>) {
      continue;
    }
    final type = PoseLandmarkType.tryFromIndex(_intOf(raw['t']));
    final x = _doubleOf(raw['x']);
    final y = _doubleOf(raw['y']);
    if (type == null || x == null || y == null) {
      continue;
    }
    points[type] = PosePoint(
      x: x / frameWidth,
      y: y / frameHeight,
      z: (_doubleOf(raw['z']) ?? 0) / frameWidth,
      likelihood: (_doubleOf(raw['l']) ?? 0).clamp(0.0, 1.0),
    );
  }
  return PoseFrame.of(
    timestampMicros: timestampMicros,
    points: points,
    luminance: luminance,
    aspectRatio: frameWidth / frameHeight,
  );
}

int? _intOf(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

double? _doubleOf(Object? value) {
  if (value is num && value.isFinite) {
    return value.toDouble();
  }
  return null;
}

List<double>? _numbers(Object? raw, int length) {
  if (raw is! List || raw.length != length) return null;
  final values = raw.map(_doubleOf).toList();
  if (values.any((value) => value == null)) return null;
  return List<double>.unmodifiable(values.cast<double>());
}
