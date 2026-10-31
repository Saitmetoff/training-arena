import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  for (final enabled in [false, true]) {
    testWidgets('SYNTHETIC diagnostics constructor flag $enabled', (tester) async {
      final session = CameraSession.debugFixture(exercise:ArenaExercise.pushUps, autoPlay:false);
      addTearDown(session.dispose);
      await tester.pumpWidget(MaterialApp(home:CameraPreview(session:session,
        showDiagnostics:enabled)));
      expect(find.byKey(const ValueKey('camera-diagnostics')),
        enabled ? findsOneWidget : findsNothing);
    });
  }
}
