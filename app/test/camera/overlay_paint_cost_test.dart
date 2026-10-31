/// Measures the overlay paint cost on the host.
///
/// Device frame-rate impact is measured on the physical phone (F3 owns that
/// session); this bench only bounds the CPU cost of `PoseSkeletonPainter.paint`
/// so a regression is visible without a device. It is a host number, not a
/// device claim. Skipped unless `OVERLAY_BENCH=1`:
///
/// ```powershell
/// $env:OVERLAY_BENCH='1'; flutter test test/camera/overlay_paint_cost_test.dart
/// ```
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  final enabled = Platform.environment['OVERLAY_BENCH'] == '1';

  test('overlay paint cost, host only', () {
    final frames = <PoseFrame>[
      ...SyntheticPoseSource.pushups(seed: 7).holdTop(800),
      ...SyntheticPoseSource.pushupsFront(seed: 8).holdTop(800),
    ];
    final notifier = ValueNotifier<PoseFrame?>(frames.first);
    final painter = PoseSkeletonPainter(
      frame: notifier,
      exercise: ArenaExercise.pushUps,
      side: PoseSide.left,
    );
    const size = Size(360, 360);
    for (var i = 0; i < 100; i++) {
      _paintOnce(painter, size);
    }

    const iterations = 5000;
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      notifier.value = frames[i % frames.length];
      _paintOnce(painter, size);
    }
    stopwatch.stop();

    final perFrameMicros = stopwatch.elapsedMicroseconds / iterations;
    // ignore: avoid_print
    print(
      'overlay paint: ${perFrameMicros.toStringAsFixed(1)} us/frame over '
      '$iterations frames (host JIT, 360x360 box)',
    );
    expect(perFrameMicros, lessThan(1000));
  }, skip: enabled ? null : 'set OVERLAY_BENCH=1 to measure');
}

void _paintOnce(PoseSkeletonPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  recorder.endRecording().dispose();
}
