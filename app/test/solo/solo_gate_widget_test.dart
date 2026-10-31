import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../linking/fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('signed-out visitors can start solo before home notices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = BattleHarness(viewerProfile: null);
    addTearDown(harness.dispose);
    await pumpBattleApp(
      tester,
      harness: harness,
      config: testConfig(soloModeEnabled: true),
    );

    final solo = find.byKey(const ValueKey('battle-solo-set'));
    final friend = find.byKey(const ValueKey('battle-challenge-friend'));
    expect(tester.getTopLeft(solo).dy, lessThan(tester.getTopLeft(friend).dy));
    await tester.tap(solo);
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('solo-start-manual'));
    expect(tester.getBottomRight(start).dy, lessThan(500));
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('solo-manual-field')), findsOneWidget);
  });

  testWidgets('the solo entry is hidden when the flag is off', (tester) async {
    final harness = BattleHarness();
    addTearDown(harness.dispose);

    await pumpBattleApp(
      tester,
      harness: harness,
      config: testConfig(soloModeEnabled: false),
    );

    expect(find.byKey(const ValueKey('battle-solo-set')), findsNothing);
  });

  testWidgets('the solo entry opens the solo page when the flag is on',
      (tester) async {
    final harness = BattleHarness();
    addTearDown(harness.dispose);

    await pumpBattleApp(
      tester,
      harness: harness,
      config: testConfig(soloModeEnabled: true),
    );

    final entry = find.byKey(const ValueKey('battle-solo-set'));
    expect(entry, findsOneWidget);

    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('solo-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('solo-start-manual')), findsOneWidget);
    // Camera counting is off in this config, so the honest banner replaces
    // the camera action.
    expect(find.byKey(const ValueKey('solo-start-camera')), findsNothing);
    expect(find.byKey(const ValueKey('solo-camera-off')), findsOneWidget);
  });

  testWidgets('manual entry reaches a labelled result and saves', (tester) async {
    final harness = BattleHarness();
    addTearDown(harness.dispose);

    await pumpBattleApp(
      tester,
      harness: harness,
      config: testConfig(soloModeEnabled: true),
    );

    final entry = find.byKey(const ValueKey('battle-solo-set'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('solo-start-manual')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('solo-plus-10')));
    await tester.tap(find.byKey(const ValueKey('solo-plus-10')));
    await tester.tap(find.byKey(const ValueKey('solo-plus-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('solo-save-manual')));
    await tester.pumpAndSettle();

    expect(find.text('21'), findsOneWidget);
    expect(find.text('reps · Self-reported'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('solo-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('solo-saved')), findsOneWidget);

    // The result page is taller than the viewport; the actions live below the
    // badge grid, so scroll them into the built range before asserting.
    final again = find.byKey(const ValueKey('solo-again'));
    await tester.scrollUntilVisible(
      again,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(again, findsOneWidget);
  });
}
