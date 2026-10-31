/// R11a UI regression: when ranked is disabled (or camera counting is off, so
/// a ranked round could never be counted) the Battle tab must not offer the
/// ranked action or claim camera-counted availability.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../linking/fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  testWidgets('ranked disabled replaces the action with honest copy',
      (tester) async {
    final harness = BattleHarness(rankedMatchmakingEnabled: false);
    await pumpBattleApp(
      tester,
      harness: harness,
      config: testConfig(
        cameraCountingEnabled: true,
        rankedMatchmakingEnabled: false,
      ),
    );

    expect(find.byKey(const ValueKey('battle-find-opponent')), findsNothing);
    expect(
      find.byKey(const ValueKey('battle-ranked-unavailable')),
      findsOneWidget,
    );
    expect(find.textContaining('does not include ranked'), findsOneWidget);
    harness.dispose();
  });

  testWidgets('camera counting off keeps the ranked claim honest',
      (tester) async {
    final harness = BattleHarness(rankedMatchmakingEnabled: true);
    await pumpBattleApp(
      tester,
      harness: harness,
      config: testConfig(
        cameraCountingEnabled: false,
        rankedMatchmakingEnabled: true,
      ),
    );

    expect(find.byKey(const ValueKey('battle-find-opponent')), findsNothing);
    expect(
      find.byKey(const ValueKey('battle-ranked-unavailable')),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not enable camera counting'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Live 60-second battles only'),
      findsNothing,
    );
    harness.dispose();
  });

  testWidgets('ranked and camera enabled keep the ranked action',
      (tester) async {
    final harness = BattleHarness(rankedMatchmakingEnabled: true);
    await pumpBattleApp(tester, harness: harness);

    expect(find.byKey(const ValueKey('battle-find-opponent')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('battle-ranked-unavailable')),
      findsNothing,
    );
    harness.dispose();
  });
}
