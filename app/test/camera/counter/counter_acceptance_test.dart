// SYNTHETIC geometry and outcome checks, not physical-device evidence.
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/pose/pose_math.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  test('SYNTHETIC bridge: 160-degree elbow in 480x640 pixels', () {
    final event = parsePoseBridgeEvent({
      'type': 'pose', 'timestamp_us': 1, 'frame_width': 480, 'frame_height': 640,
      'landmarks': [
        {'t': 11, 'x': 240 + 100 * math.cos(160 * math.pi / 180),
         'y': 320 + 100 * math.sin(160 * math.pi / 180), 'l': .9},
        {'t': 13, 'x': 240, 'y': 320, 'l': .9},
        {'t': 15, 'x': 340, 'y': 320, 'l': .9},
      ],
    }) as PoseFrameEvent;
    final f = event.frame;
    expect(angleDegrees(f.point(PoseLandmarkType.leftShoulder)!,
      f.point(PoseLandmarkType.leftElbow)!, f.point(PoseLandmarkType.leftWrist)!,
      aspectRatio: f.aspectRatio), closeTo(160, 1));
  });

  test('SYNTHETIC full-chain side selection picks readable far side for two reps', () {
    final s = SyntheticPoseSource.pushups();
    s.holdTop(800); s.rep(); s.rep();
    final c = RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps));
    for (final f in s.frames) {
      final points = <PoseLandmarkType, PosePoint>{};
      for (final type in PoseLandmarkType.values) {
        final p = f.point(type);
        if (p == null) continue;
        final left = [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow,
          PoseLandmarkType.leftWrist, PoseLandmarkType.leftHip, PoseLandmarkType.leftAnkle].contains(type);
        final hidden = type == PoseLandmarkType.leftHip || type == PoseLandmarkType.leftAnkle;
        points[type] = PosePoint(x:p.x, y:p.y, z:p.z,
          likelihood: hidden ? .4 : left ? .9 : .8);
      }
      final r = c.addFrame(PoseFrame.of(timestampMicros:f.timestampMicros, points:points));
      if (r.signal != null) expect(r.side, PoseSide.right);
    }
    expect(c.countedReps, 2);
  });

  test('SYNTHETIC incomplete lockout emits one rejection after 5s', () {
    final s = SyntheticPoseSource.pushups();
    s.holdTop(800);
    s.segment(160, to:88, durationMs:800);
    s.segment(88, to:88, durationMs:5200);
    final c = RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps));
    final outcomes = s.frames.map(c.addFrame).where((r) => r.outcome).toList();
    expect(outcomes.length, 1);
    expect(outcomes.single.rejection, CounterRejection.lockoutMissed);
    expect(c.countedReps, 0);
  });
}
