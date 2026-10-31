/// Text trace format shared by the debug tracer and the test replay harness.
///
/// Format v1, one frame per line (identical to
/// `app/test/camera/fixture_replay.dart`, which parses it):
///
/// ```text
/// <timestampMicros>,<luminance>|<index>,<x>,<y>,<likelihood>|...
/// ```
///
/// * `index` is `PoseLandmarkType.index`; omit a landmark to simulate a
///   missing joint.
/// * an empty frame (no person) is `<timestampMicros>,<luminance>|`.
/// * `#` starts a comment line.
///
/// Numbers only: no frame, image, device identifier or account value can be
/// represented here.
library;

import '../../domain/arena_types.dart';
import '../pose/pose_types.dart';

/// First header line of every file, kept byte-identical to the committed
/// fixtures so regeneration does not churn.
const String poseTraceFormatHeader = '# Training Arena pose fixture v1';

/// Column header comment written by the serializer.
const String poseTraceColumnHeader =
    '# timestampMicros,luminance|index,x,y,likelihood|...';

/// Serializes frames to format v1 (header plus one line per frame).
String serializePoseFrames(Iterable<PoseFrame> frames) {
  final buffer = StringBuffer()
    ..writeln(poseTraceFormatHeader)
    ..writeln(poseTraceColumnHeader);
  _writeFrameLines(buffer, frames);
  return buffer.toString();
}

/// Serializes a recorded device trace: the same format plus comment lines
/// naming the exercise and, when known, the in-app rep count at export time.
/// Both are comments, so the replay parser ignores them.
String serializePoseTrace(
  Iterable<PoseFrame> frames, {
  required ArenaExercise exercise,
  int? inAppReps,
}) {
  final buffer = StringBuffer()
    ..writeln(poseTraceFormatHeader)
    ..writeln(poseTraceColumnHeader)
    ..writeln('# exercise: ${exercise.wire}');
  if (inAppReps != null) {
    buffer.writeln('# in_app_reps: $inAppReps');
  }
  _writeFrameLines(buffer, frames);
  return buffer.toString();
}

void _writeFrameLines(StringBuffer buffer, Iterable<PoseFrame> frames) {
  for (final frame in frames) {
    buffer.write(
      '${frame.timestampMicros},${frame.luminance.toStringAsFixed(4)}'
      '${frame.aspectRatio == 1 ? "" : ",${frame.aspectRatio}"}|',
    );
    final entries = <String>[];
    for (final type in PoseLandmarkType.values) {
      final point = frame.point(type);
      if (point == null) {
        continue;
      }
      entries.add(
        '${type.index},${point.x.toStringAsFixed(6)},'
        '${point.y.toStringAsFixed(6)},${point.likelihood.toStringAsFixed(4)}',
        // Depth preserves view selection on recorded device replays.
      );
      if (point.z != 0) entries[entries.length - 1] += ',${point.z}';
    }
    buffer.writeln(entries.join('|'));
  }
}
