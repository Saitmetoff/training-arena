import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/solo/data/solo_result_store.dart';
import 'package:training_arena/solo/runtime/solo_controller.dart';
import 'package:training_arena/solo/ui/solo_page.dart';
import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  testWidgets('SYNTHETIC preparation/practice screen gives exact placement guidance', (tester) async {
    final harness = BattleHarness();
    addTearDown(harness.dispose);
    await pumpBattleApp(tester,harness:harness);
    harness.backend.inboxData = BattleInbox(requests:[testRequest()]);
    harness.backend.matchData = testMatch();
    await harness.controller.loadHome();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
    await tester.pumpAndSettle();
    expect(find.text(cameraPhonePlacementGuidance),findsOneWidget);
    expect(find.byKey(const ValueKey('battle-practice-card')),findsOneWidget);
  });
  testWidgets('SYNTHETIC solo intro and camera practice give exact placement guidance', (tester) async {
    final clock = ManualBattleClock();
    final controller = SoloController(store:InMemorySoloResultStore(),clock:clock,
      cameraEnabled:true,cameraFactory:(exercise)=>CameraSession.debugFixture(exercise:exercise,autoPlay:false));
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(home:SoloPage(controller:controller)));
    await tester.pumpAndSettle();
    expect(find.textContaining(cameraPhonePlacementGuidance),findsOneWidget);
    controller.startCamera();
    clock.advance(const Duration(seconds:3));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('solo-practice-placement')),findsOneWidget);
    expect(find.text(cameraPhonePlacementGuidance),findsOneWidget);
  });
}
