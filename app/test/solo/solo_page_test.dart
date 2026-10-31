import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/solo/data/solo_result_store.dart';
import 'package:training_arena/solo/domain/solo_result.dart';
import 'package:training_arena/solo/runtime/solo_controller.dart';
import 'package:training_arena/solo/ui/solo_page.dart';

import '../support/battle_fakes.dart';

void main() {
  testWidgets('failed persistence never shows Saved and keeps the count', (
    tester,
  ) async {
    final controller = SoloController(store: UnwritableSoloStore());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: SoloPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    controller.startManualEntry();
    controller.setManualReps(12);
    controller.submitManual();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('solo-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('solo-saved')), findsNothing);
    expect(find.byKey(const ValueKey('solo-save-error')), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.byKey(const ValueKey('solo-save')), findsOneWidget);
  });
  testWidgets(
    'recent history labels its source and personal best uses the same source',
    (tester) async {
      final clock = ManualBattleClock();
      SoloSetResult set(
        int reps,
        int days,
        SoloCountSource source, [
        ArenaExercise exercise = ArenaExercise.pushUps,
      ]) =>
          SoloSetResult(
            exercise: exercise,
            reps: reps,
            durationSeconds: 30,
            completedAt: clock.now().subtract(Duration(days: days)),
            source: source,
          );
      final controller = SoloController(
        clock: clock,
        store: InMemorySoloResultStore([
          set(9, 0, SoloCountSource.manual),
          set(80, 1, SoloCountSource.camera),
          set(99, 2, SoloCountSource.manual, ArenaExercise.squats),
          set(10, 6, SoloCountSource.manual),
          set(200, 7, SoloCountSource.camera),
        ]),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: SoloPage(controller: controller)),
      );
      await tester.pumpAndSettle();
      final history = find.byKey(const ValueKey('solo-history'));
      await tester.scrollUntilVisible(history, 200);
      expect(find.text('9 reps · Self-reported'), findsOneWidget);
      expect(find.text('80 reps · Camera-counted'), findsOneWidget);
      expect(find.text('200 reps · Camera-counted'), findsNothing);
      controller.startManualEntry();
      controller.setManualReps(11);
      controller.submitManual();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('solo-personal-best')),
        -200,
      );
      expect(
        find.text('New personal best · Self-reported push-ups'),
        findsOneWidget,
      );
      expect(find.text('Previous best: 10 reps'), findsOneWidget);
      expect(find.byKey(const ValueKey('solo-save')), findsOneWidget);
    },
  );
}

class UnwritableSoloStore extends InMemorySoloResultStore {
  @override
  Future<void> write(List<SoloSetResult> results) async =>
      throw StateError('Storage unavailable');
}
