import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/solo/data/solo_result_store.dart';
import 'package:training_arena/solo/domain/solo_result.dart';
import 'package:training_arena/solo/runtime/solo_controller.dart';

import '../support/battle_fakes.dart';
import 'solo_fakes.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'squat diagnostics require debug and tracing; release stays push-ups',
    () {
      expect(
        diagnosticSoloExercise(debug: true, trace: true, requested: 'squats'),
        ArenaExercise.squats,
      );
      expect(
        diagnosticSoloExercise(debug: false, trace: true, requested: 'squats'),
        ArenaExercise.pushUps,
      );
      expect(
        diagnosticSoloExercise(debug: true, trace: false, requested: 'squats'),
        ArenaExercise.pushUps,
      );
    },
  );
  late InMemorySoloResultStore store;
  late ManualBattleClock clock;

  setUp(() {
    store = InMemorySoloResultStore();
    clock = ManualBattleClock();
  });

  SoloController build({bool cameraEnabled = false, FakeSoloCamera? camera}) =>
      SoloController(
        store: store,
        clock: clock,
        cameraEnabled: cameraEnabled,
        cameraFactory: camera == null ? null : (_) => camera,
      );

  test('manual entry saves a self-reported set and updates stats', () async {
    final controller = build();
    addTearDown(controller.dispose);
    await controller.load();

    controller.startManualEntry();
    expect(controller.snapshot.phase, SoloPhase.manualEntry);

    controller.adjustManualReps(25);
    expect(controller.snapshot.reps, 25);

    controller.submitManual();
    final result = controller.snapshot.result;
    expect(result, isNotNull);
    expect(result!.reps, 25);
    expect(result.source, SoloCountSource.manual);
    expect(result.selfReported, isTrue);
    expect(controller.snapshot.saved, isFalse);

    await controller.save();
    expect(controller.snapshot.saved, isTrue);
    expect(controller.snapshot.stats.sessions, 1);
    expect(controller.snapshot.stats.bestSetReps, 25);
    expect(controller.snapshot.streak.todayReps, 25);
    expect(controller.snapshot.streak.current, 1);
    expect((await store.read()).single.reps, 25);

    // Saving twice must not duplicate the entry.
    await controller.save();
    expect((await store.read()).length, 1);
  });

  test('failed save keeps the result unsaved and can be retried', () async {
    final failingStore = FailingSoloStore();
    final controller = SoloController(store: failingStore, clock: clock);
    addTearDown(controller.dispose);
    await controller.load();
    controller.startManualEntry();
    controller.setManualReps(12);
    controller.submitManual();
    await controller.save();
    expect(controller.snapshot.saved, isFalse);
    expect(controller.snapshot.result?.reps, 12);
    expect(controller.snapshot.message, contains('Could not save'));
    expect(controller.snapshot.stats.sessions, 0);
    failingStore.fail = false;
    await controller.save();
    expect(controller.snapshot.saved, isTrue);
    expect(controller.snapshot.message, isNull);
    expect((await failingStore.read()).length, 1);
  });

  test('manual entry refuses a zero count', () {
    final controller = build();
    addTearDown(controller.dispose);
    controller.startManualEntry();
    controller.submitManual();
    expect(controller.snapshot.phase, SoloPhase.manualEntry);
    expect(controller.snapshot.result, isNull);
  });

  test(
    'finishing during a history read preserves prior best and saved sets',
    () async {
      final readGate = Completer<void>();
      final old = SoloSetResult(
        exercise: ArenaExercise.pushUps,
        reps: 30,
        durationSeconds: 0,
        completedAt: clock.now(),
        source: SoloCountSource.manual,
      );
      final delayed = DelayedSoloStore(readGate, [old]);
      final controller = SoloController(store: delayed, clock: clock);
      addTearDown(controller.dispose);
      final loading = controller.load();
      controller.startManualEntry();
      controller.setManualReps(12);
      controller.submitManual();
      expect(controller.snapshot.previousBestReps, isNull);
      readGate.complete();
      await loading;
      expect(controller.snapshot.previousBestReps, 30);
      await Future.wait([controller.save(), controller.save()]);
      expect((await delayed.read()).map((r) => r.reps), [12, 30]);
    },
  );

  test('camera flow runs countdown, practice and round', () async {
    final camera = FakeSoloCamera();
    final controller = build(cameraEnabled: true, camera: camera);
    addTearDown(controller.dispose);

    controller.startCamera();
    expect(controller.snapshot.phase, SoloPhase.countdown);
    expect(controller.snapshot.countdown, 3);

    clock.advance(const Duration(seconds: 3));
    await flush();
    await flush();
    expect(camera.calls, contains('requestPermission'));
    expect(camera.calls, contains('startPractice'));
    expect(controller.snapshot.phase, SoloPhase.practice);

    camera.completePractice();
    await flush();
    await flush();
    expect(camera.calls, contains('beginRound'));
    expect(controller.snapshot.phase, SoloPhase.counting);

    camera.countedReps = 14;
    camera.emit();
    clock.advance(const Duration(seconds: 45));
    await controller.endSet();

    final result = controller.snapshot.result;
    expect(result, isNotNull);
    expect(result!.reps, 14);
    expect(result.durationSeconds, 45);
    expect(result.source, SoloCountSource.camera);
    expect(result.selfReported, isFalse);
    expect(camera.calls, contains('endRound'));
  });

  test(
    'denied camera permission returns to intro with manual guidance',
    () async {
      final camera = FakeSoloCamera()..permissionGranted = false;
      final controller = build(cameraEnabled: true, camera: camera);
      addTearDown(controller.dispose);

      controller.startCamera();
      clock.advance(const Duration(seconds: 3));
      await flush();
      await flush();

      expect(controller.snapshot.phase, SoloPhase.intro);
      expect(controller.snapshot.message, contains('manually'));
      expect(camera.disposeCount, 1);
    },
  );

  test('camera start is refused when the build has no camera', () {
    final controller = build();
    addTearDown(controller.dispose);
    controller.startCamera();
    expect(controller.snapshot.phase, SoloPhase.intro);
    expect(controller.snapshot.countdown, 0);
  });

  test('restart returns to the intro and clears the pending result', () async {
    final controller = build();
    addTearDown(controller.dispose);
    controller.startManualEntry();
    controller.setManualReps(9);
    controller.submitManual();
    expect(controller.snapshot.phase, SoloPhase.result);

    await controller.restart();
    expect(controller.snapshot.phase, SoloPhase.intro);
    expect(controller.snapshot.result, isNull);
    expect(controller.snapshot.reps, 0);
  });

  test('load exposes stored history to the stats', () async {
    await store.write(<SoloSetResult>[
      SoloSetResult(
        exercise: ArenaExercise.pushUps,
        reps: 40,
        durationSeconds: 60,
        completedAt: DateTime.utc(2026, 9, 22),
        source: SoloCountSource.camera,
      ),
    ]);
    final controller = build();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.snapshot.stats.sessions, 1);
    expect(controller.snapshot.stats.bestSetReps, 40);
    expect(controller.snapshot.stats.last?.reps, 40);
  });
}

class DelayedSoloStore extends InMemorySoloResultStore {
  DelayedSoloStore(this.gate, super.initialResults);
  final Completer<void> gate;
  @override
  Future<List<SoloSetResult>> read() async {
    await gate.future;
    return super.read();
  }
}

class FailingSoloStore extends InMemorySoloResultStore {
  bool fail = true;

  @override
  Future<void> write(List<SoloSetResult> results) async {
    if (fail) throw StateError('storage unavailable');
    await super.write(results);
  }
}
