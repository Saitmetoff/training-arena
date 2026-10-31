// SYNTHETIC only. This is state-machine coverage, never device evidence.
// Console output is an explicit audit acceptance requirement.
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

const baseline = bool.fromEnvironment('STRESS_BASELINE');

class Cell {
  const Cell(this.name, this.ms, {this.fps = 15, this.top = 160,
    this.bottom = 88, this.noise = .004, this.aspect = false,
    this.squat = false, this.accept = true});
  final String name;
  final int ms, fps;
  final double top, bottom, noise;
  final bool aspect, squat, accept;
}

const cells = [
  Cell('push 3.0s', 3000), Cell('push 2.1s', 2100),
  Cell('push 1.6s', 1600), Cell('push 1.2s', 1200),
  Cell('push 1.0s', 1000), Cell('push 0.8s', 800),
  Cell('push 0.6s diagnostic', 600, accept: false),
  Cell('push 150-95', 1600, top: 150, bottom: 95),
  Cell('push 8fps', 1600, fps: 8), Cell('push 10fps', 1600, fps: 10),
  Cell('push 30fps', 1600, fps: 30),
  Cell('push noise .02', 1600, noise: .02),
  Cell('push y*.75', 1600, aspect: true),
  Cell('push bottom115', 1600, bottom: 115, accept: false),
  Cell('push partial122', 1600, bottom: 122, accept: false),
  Cell('squat 1.2s', 1200, top: 175, bottom: 80, squat: true),
  Cell('squat 1.6s', 1600, top: 175, bottom: 80, squat: true),
  Cell('squat 2.1s', 2100, top: 175, bottom: 80, squat: true),
  Cell('squat 3.0s', 3000, top: 175, bottom: 80, squat: true),
];

PoseFrame portrait(PoseFrame frame) => (parsePoseBridgeEvent({
  'type': 'pose', 'timestamp_us': frame.timestampMicros,
  'luminance': frame.luminance, 'frame_width': 480, 'frame_height': 640,
  'landmarks': [for (final type in PoseLandmarkType.values)
    if (frame.point(type) case final point?)
      {'t': type.index, 'x': point.x * 480, 'y': point.y * 480,
       'z': point.z * 480, 'l': point.likelihood}],
}) as PoseFrameEvent).frame;

void main() {
  test('SYNTHETIC stress matrix: ten continuous cycles across five seeds', () {
    final failures = <String>[];
    print('SYNTHETIC ${baseline ? "BEFORE" : "AFTER"} | mean/10 | seeds | rejection histogram');
    for (final cell in cells) {
      final counts = <int>[];
      final outcomesPerSeed = <int>[];
      final histogram = <String, int>{};
      for (var seed = 1; seed <= 5; seed++) {
        final source = SyntheticPoseSource(
          exercise: cell.squat ? SyntheticExercise.squats : SyntheticExercise.pushUps,
          intervalMicros: (1000000 / cell.fps).round(), seed: seed,
          noiseAmplitude: cell.noise,
        );
        source.segment(cell.top, to: cell.top, durationMs: 800);
        for (var i = 0; i < 10; i++) {
          source.segment(cell.top, to: cell.bottom, durationMs: cell.ms ~/ 2);
          source.segment(cell.bottom, to: cell.top, durationMs: cell.ms ~/ 2);
        }
        source.segment(cell.top, to: cell.top, durationMs: 800);
        final counter = RepCounter(ExerciseCounterProfile.forExercise(
          cell.squat ? ArenaExercise.squats : ArenaExercise.pushUps));
        var previous = CounterPhase.awaitingFraming;
        var outcomes = 0;
        for (final f in source.frames) {
          final result = counter.addFrame(cell.aspect ? portrait(f) : f);
          if (!baseline && result.outcome) outcomes++;
          if ((baseline ? previous == CounterPhase.bottom && result.phase == CounterPhase.up : result.outcome) &&
              !result.repCounted && result.rejection != CounterRejection.none) {
            histogram.update(result.rejection.name, (n) => n + 1, ifAbsent: () => 1);
          }
          previous = result.phase;
        }
        counts.add(counter.countedReps);
        outcomesPerSeed.add(outcomes);
        if (!baseline && outcomes != 10) {
          failures.add('${cell.name} seed $seed has $outcomes outcomes for 10 descents');
        }
        if (!baseline && cell.accept && counter.countedReps < 9) {
          failures.add('${cell.name} seed $seed counted ${counter.countedReps}');
        }
        if (!baseline && (cell.bottom == 115 || cell.bottom == 122) && counter.countedReps != 0) {
          failures.add('${cell.name} seed $seed counted a shallow rep');
        }
      }
      print('${cell.name} | ${counts.reduce((a,b) => a+b)/5} | $counts | $histogram | outcomes $outcomesPerSeed');
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
