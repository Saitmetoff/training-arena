/// Text fixture format and replay runner for the rep counter.
///
/// Format v1, one frame per line:
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
/// Committed fixtures live in `test/camera/fixtures/`. They are generated
/// from `SyntheticPoseSource` (`generate_pose_fixtures_test.dart`) and can be
/// replaced by traces recorded during the L04 device session — the parser
/// does not care where the numbers came from, and no frame carries an image.
library;

import 'dart:io';

import 'package:training_arena/camera/counter/rep_counter.dart';
import 'package:training_arena/camera/camera_types.dart';
import 'package:training_arena/camera/pose/pose_types.dart';
import 'package:training_arena/camera/trace/pose_trace_format.dart';

class PoseFixture {
  const PoseFixture({required this.name, required this.frames});

  final String name;
  final List<PoseFrame> frames;
}

/// Parses one fixture. Throws [FormatException] on a malformed line.
PoseFixture parsePoseFixture(String source, {required String name}) {
  final frames = <PoseFrame>[];
  for (final rawLine in source.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final separator = line.indexOf('|');
    if (separator < 0) {
      throw FormatException('missing "|" in "$line"');
    }
    final header = line.substring(0, separator).split(',');
    if (header.length != 2 && header.length != 3) {
      throw FormatException('bad frame header in "$line"');
    }
    final timestamp = int.parse(header[0]);
    final luminance = double.parse(header[1]);
    final aspect = header.length == 3 ? double.parse(header[2]) : 1.0;
    if (!luminance.isFinite || !aspect.isFinite || aspect <= 0) {
      throw const FormatException('non-finite luminance or invalid aspect');
    }
    final body = line.substring(separator + 1);
    if (body.isEmpty) {
      frames.add(
        PoseFrame.empty(timestampMicros: timestamp, luminance: luminance, aspectRatio: aspect),
      );
      continue;
    }
    final points = <PoseLandmarkType, PosePoint>{};
    for (final entry in body.split('|')) {
      if (entry.isEmpty) {
        continue;
      }
      final parts = entry.split(',');
      if (parts.length != 4 && parts.length != 5) {
        throw FormatException('bad landmark "$entry"');
      }
      final type = PoseLandmarkType.tryFromIndex(int.parse(parts[0]));
      if (type == null) {
        // Forward compatible with a newer landmark set.
        continue;
      }
      points[type] = PosePoint(
        x: double.parse(parts[1]),
        y: double.parse(parts[2]),
        z: parts.length == 5 ? double.parse(parts[4]) : 0,
        likelihood: double.parse(parts[3]),
      );
    }
    frames.add(
      PoseFrame.of(
        timestampMicros: timestamp,
        points: points,
        luminance: luminance,
        aspectRatio: aspect,
      ),
    );
  }
  return PoseFixture(name: name, frames: frames);
}

/// Serializes frames back to format v1; the inverse of [parsePoseFixture].
///
/// Delegates to the production serializer (`pose_trace_format.dart`) so the
/// committed fixtures and the device-trace recorder can never drift apart.
String serializePoseFixture(List<PoseFrame> frames) =>
    serializePoseFrames(frames);

/// Loads a committed fixture by file name.
PoseFixture loadPoseFixture(String fileName) => parsePoseFixture(
  File('test/camera/fixtures/$fileName').readAsStringSync(),
  name: fileName,
);

/// Replays a cropped camera view while retaining the exercise signal chain.
/// The fixture text round-trip keeps this variant on the C05 trace path.
List<PoseFrame> partialBodyFrames(
  List<PoseFrame> source, {
  bool missingWrists = false,
  bool lowConfidenceElbows = false,
}) {
  final cropped = source.map((frame) {
    final points = <PoseLandmarkType, PosePoint>{};
    for (final type in PoseLandmarkType.values) {
      final point = frame.point(type);
      if (point == null ||
          missingWrists &&
              (type == PoseLandmarkType.leftWrist ||
                  type == PoseLandmarkType.rightWrist)) {
        continue;
      }
      final outside =
          type == PoseLandmarkType.nose ||
          type == PoseLandmarkType.leftFootIndex ||
          type == PoseLandmarkType.rightFootIndex;
      points[type] = PosePoint(
        x: type == PoseLandmarkType.nose
            ? -0.5
            : type == PoseLandmarkType.leftFootIndex ||
                  type == PoseLandmarkType.rightFootIndex
            ? 1.5
            : point.x,
        y: point.y,
        likelihood: outside
            ? 0.1
            : lowConfidenceElbows &&
                  (type == PoseLandmarkType.leftElbow ||
                      type == PoseLandmarkType.rightElbow)
            ? 0.2
            : point.likelihood,
      );
    }
    return PoseFrame.of(timestampMicros: frame.timestampMicros, points: points);
  }).toList();
  return parsePoseFixture(
    serializePoseFixture(cropped),
    name: 'partial-body',
  ).frames;
}

/// What a replayed fixture produced.
class ReplaySummary {
  const ReplaySummary({
    required this.countedReps,
    required this.repEvents,
    required this.rejections,
    required this.lostTracking,
    required this.finalTracking,
    required this.framingEverLocked,
  });

  final int countedReps;
  final int repEvents;
  final List<CounterRejection> rejections;
  final bool lostTracking;
  final CameraTrackingState finalTracking;

  /// True when the counter ever reported a locked framing gate.
  final bool framingEverLocked;

  CounterRejection get lastRejection =>
      rejections.isEmpty ? CounterRejection.none : rejections.last;
}

/// Feeds every frame through [counter] and summarizes the run.
ReplaySummary replay(RepCounter counter, List<PoseFrame> frames) {
  var repEvents = 0;
  var lostTracking = false;
  var framingEverLocked = false;
  final rejections = <CounterRejection>[];
  var finalTracking = CameraTrackingState.framing;
  for (final frame in frames) {
    final result = counter.addFrame(frame);
    framingEverLocked = framingEverLocked || result.framingLocked;
    if (result.repCounted) {
      repEvents += 1;
      rejections.add(result.rejection);
    } else if (result.rejection != CounterRejection.none &&
        result.phase == CounterPhase.up &&
        !result.duplicateFrame) {
      // Record the most recent refusal so a fixture can assert why.
      if (rejections.isEmpty ||
          rejections.last != result.rejection ||
          result.countedReps != counter.countedReps) {
        rejections.add(result.rejection);
      }
    }
    if (result.tracking == CameraTrackingState.searching) {
      lostTracking = true;
    }
    finalTracking = result.tracking;
  }
  return ReplaySummary(
    countedReps: counter.countedReps,
    repEvents: repEvents,
    rejections: rejections,
    lostTracking: lostTracking,
    finalTracking: finalTracking,
    framingEverLocked: framingEverLocked,
  );
}
