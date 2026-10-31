import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/linking/challenge_analytics.dart';

import '../linking/fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  testWidgets(
    'home exposes the confirmed account link without sending a request',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = BattleHarness();
      final api = FakeArenaChallengeApi();
      final linking = buildTestLinking(api: api);
      await pumpBattleApp(tester, harness: harness, linking: linking);
      await tester.tap(find.byKey(const ValueKey('battle-my-link')));
      await tester.pumpAndSettle();
      expect(find.text('My challenge link'), findsOneWidget);
      expect(find.text('https://example.invalid/c/$fakeToken'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
      expect(find.text('Share link'), findsOneWidget);
      expect(api.snapshotCalls, 1);
      expect(api.sendCalls, 0);
      expect(
        (linking.analytics as MemoryChallengeAnalyticsSink).eventNames,
        isEmpty,
      );
      harness.dispose();
      linking.dispose();
    },
  );
}
