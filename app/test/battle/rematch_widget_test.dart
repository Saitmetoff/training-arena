import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/domain/arena_types.dart';

import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  testWidgets('rematch waits for a fresh accepted match', (tester) async {
    tester.view.physicalSize = const Size(420, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = BattleHarness();
    await pumpBattleApp(tester, harness: harness);
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      receipt: testReceipt(),
    );
    await harness.controller.attachMatch('match-1');
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('battle-result-rematch')));
    await tester.pumpAndSettle();
    expect(
      harness.backend.callLog.where((c) => c == 'rematch:match-1'),
      hasLength(1),
    );
    expect(find.text('Request pending'), findsOneWidget);
    expect(find.textContaining('Waiting for @zuhra'), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-accept-request')), findsNothing);
    expect(harness.controller.snapshot.match, isNull);
    expect(harness.controller.snapshot.receipt, isNull);

    harness.backend.matchData = testMatch(id: 'match-fresh');
    harness.backend.inboxData = const BattleInbox(activeMatchId: 'match-fresh');
    await harness.controller.refreshInbox();
    await tester.pumpAndSettle();
    expect(harness.controller.snapshot.phase, BattlePhase.preparing);
    expect(harness.controller.snapshot.match?.id, 'match-fresh');
    expect(harness.controller.snapshot.readySubmitted, isFalse);
    expect(harness.backend.readyCalls, isEmpty);
    harness.dispose();
  });
}
