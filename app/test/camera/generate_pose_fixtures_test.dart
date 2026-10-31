/// Regenerates the committed pose fixtures from `SyntheticPoseSource`.
///
/// Skipped unless `FIXTURE_GEN=1`:
///
/// ```powershell
/// $env:FIXTURE_GEN='1'; flutter test test/camera/generate_pose_fixtures_test.dart
/// ```
///
/// Run it after changing the synthetic generator; `fixture_replay_test.dart`
/// replays the committed files, so the two must stay in step.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/pose/pose_types.dart';

import 'fixture_replay.dart';

void main() {
  final enabled = Platform.environment['FIXTURE_GEN'] == '1';

  test('regenerates the committed pose fixtures', () {
    final directory = Directory('test/camera/fixtures')
      ..createSync(recursive: true);
    void write(String name, List<PoseFrame> frames) {
      File('${directory.path}/$name')
          .writeAsStringSync(serializePoseFixture(frames));
    }

    final clean = SyntheticPoseSource.pushups();
    write('pushups_clean_rep.txt', <PoseFrame>[
      ...clean.holdTop(800),
      ...clean.rep(),
    ]);

    final shake = SyntheticPoseSource.pushups(seed: 7);
    write('pushups_shake_only.txt', <PoseFrame>[
      ...shake.holdTop(800),
      ...shake.jitterTop(3000),
    ]);

    final half = SyntheticPoseSource.pushups(seed: 2);
    write('pushups_half_depth.txt', <PoseFrame>[
      ...half.holdTop(800),
      ...half.partialRep(),
    ]);

    final collapse = SyntheticPoseSource.pushups(seed: 3);
    write('pushups_plank_collapse.txt', <PoseFrame>[
      ...collapse.holdTop(800),
      ...collapse.rep(hipDrop: 0.12),
    ]);

    final dropout = SyntheticPoseSource.pushups(seed: 4);
    write('pushups_dropout.txt', <PoseFrame>[
      ...dropout.holdTop(800),
      ...dropout.segment(160, to: 88, durationMs: 500),
      ...dropout.trackingLoss(500),
    ]);

    final squats = SyntheticPoseSource.squats(seed: 5);
    write('squats_clean_rep.txt', <PoseFrame>[
      ...squats.holdTop(800),
      ...squats.rep(),
    ]);

    final frontClean = SyntheticPoseSource.pushupsFront(seed: 31);
    write('pushups_front_clean_rep.txt', <PoseFrame>[
      ...frontClean.holdTop(800),
      ...frontClean.rep(),
    ]);

    final frontShake = SyntheticPoseSource.pushupsFront(seed: 32);
    write('pushups_front_shake_only.txt', <PoseFrame>[
      ...frontShake.holdTop(800),
      ...frontShake.jitterTop(3000),
    ]);

    final frontHalf = SyntheticPoseSource.pushupsFront(seed: 33);
    write('pushups_front_half_depth.txt', <PoseFrame>[
      ...frontHalf.holdTop(800),
      ...frontHalf.partialRep(minimum: 118),
    ]);

    final frontSag = SyntheticPoseSource.pushupsFront(seed: 34);
    write('pushups_front_sag.txt', <PoseFrame>[
      ...frontSag.holdTop(800),
      ...frontSag.rep(frontSag: 0.10),
    ]);

    final frontPartial = SyntheticPoseSource.pushupsFront(seed: 35);
    write(
      'pushups_front_partial_body.txt',
      <PoseFrame>[
        ...frontPartial.holdTop(800),
        ...frontPartial.rep(),
      ].map((frame) => _withLikelihood(
            frame,
            PoseLandmarkType.rightWrist,
            0.2,
          )).toList(),
    );
  }, skip: enabled ? null : 'set FIXTURE_GEN=1 to regenerate');
}

/// Copies [frame] with one landmark's likelihood forced low: an occluded hand.
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
