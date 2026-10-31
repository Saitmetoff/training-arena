import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/runtime/battle_runtime.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/battle/ui/battle_inbox_page.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/theme/arena_theme.dart';

import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  group('Battle home hierarchy', () {
    testWidgets('incoming request, hero, ranked and code render in order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);

      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      await harness.controller.loadHome();
      await tester.pumpAndSettle();

      final requestY = tester
          .getTopLeft(find.byKey(const ValueKey('battle-incoming-card')))
          .dy;
      final heroY = tester
          .getTopLeft(find.byKey(const ValueKey('battle-challenge-friend')))
          .dy;
      final rankedY = tester
          .getTopLeft(find.byKey(const ValueKey('battle-find-opponent')))
          .dy;
      final codeY =
          tester.getTopLeft(find.byKey(const ValueKey('battle-join-code'))).dy;

      expect(requestY, lessThan(heroY));
      expect(heroY, lessThan(rankedY));
      expect(rankedY, lessThan(codeY));
      harness.dispose();
    });

    testWidgets('empty inbox keeps the hero as the dominant action', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);

      expect(find.byKey(const ValueKey('battle-incoming-card')), findsNothing);
      expect(
        find.byKey(const ValueKey('battle-challenge-friend')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle-find-opponent')),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('offline and blocked inbox states are honest and retryable', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);

      harness.backend.inboxFailure = const BattleFailure(
        BattleFailureKind.offline,
        'The arena is unreachable.',
      );
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle-offline')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle-retry-load')), findsOneWidget);

      harness.backend.inboxFailure = const BattleFailure(
        BattleFailureKind.blocked,
        'This player cannot be challenged from your account.',
      );
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle-blocked')), findsOneWidget);
      harness.dispose();
    });

    testWidgets('signed-out state keeps the challenge context promise', (
      tester,
    ) async {
      final harness = BattleHarness(viewerProfile: null);
      await pumpBattleApp(tester, harness: harness);
      expect(find.byKey(const ValueKey('battle-signed-out')), findsOneWidget);
      expect(
        find.textContaining('you return to that exact challenge'),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('first launch keeps the challenge action above setup notices', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = BattleHarness(viewerProfile: null);
      harness.backend.inboxFailure = const BattleFailure(
        BattleFailureKind.unconfigured,
        'The arena service is not configured in this build.',
      );
      await pumpBattleApp(tester, harness: harness);
      await harness.controller.loadHome();
      await tester.pumpAndSettle();

      final hero = find.byKey(const ValueKey('battle-challenge-friend'));
      final service = find.byKey(const ValueKey('battle-unconfigured'));
      expect(find.byKey(const ValueKey('battle-signed-out')), findsNothing);
      expect(
        find.byKey(const ValueKey('battle-ranked-unavailable')),
        findsNothing,
      );
      expect(
        tester.getTopLeft(hero).dy,
        lessThan(tester.getTopLeft(service).dy),
      );
      expect(find.textContaining('service setup'), findsNothing);
      expect(tester.getBottomRight(hero).dy, lessThan(500));
      expect(find.byKey(const ValueKey('battle-retry-load')), findsNothing);
      expect(
        find.textContaining('Friend challenges and the inbox still work'),
        findsNothing,
      );
      harness.dispose();
    });
  });

  group('ranked search UI', () {
    testWidgets(
        'search never claims anyone is online and offers the friend '
        'alternative after 15 seconds', (tester) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);

      await tester.tap(find.byKey(const ValueKey('battle-find-opponent')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle-search-card')), findsOneWidget);
      expect(
        find.textContaining('Nobody is promised to be online'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle-search-challenge-friend')),
        findsOneWidget,
      );

      harness.clock.advance(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('switching cancels the queue seat'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('battle-stop-search')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-search-stopped')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('battle-retry-search')), findsOneWidget);
      harness.dispose();
    });
  });

  group('match flow', () {
    testWidgets('accepting a request opens preparation, never live play', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('battle-flow')), findsOneWidget);
      expect(find.text('Preparation'), findsOneWidget);
      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.byKey(const ValueKey('battle-live-timer')), findsNothing);
      expect(
        find.textContaining('There is no manual score entry'),
        findsWidgets,
      );
      harness.dispose();
    });

    testWidgets('practice rep gates ready; both-ready gates the countdown', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();

      // Ready before the practice rep is explained, not silently accepted.
      await tester.ensureVisible(
        find.byKey(const ValueKey('battle-ready-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-ready-button')));
      await tester.pumpAndSettle();
      expect(harness.backend.readyCalls, isEmpty);
      expect(
        find.textContaining('Take the practice rep first'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('battle-practice-rep')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-practice-rep')));
      await tester.pump();
      harness.camera.emitPracticeRep();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-practice-done')),
        findsOneWidget,
      );

      harness.backend.readyReply = testMatch(
        status: ArenaMatchStatus.preparing,
        viewerReady: true,
        opponentReady: false,
        serverNow: harness.clock.now(),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('battle-ready-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-ready-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-ready-waiting')),
        findsOneWidget,
      );
      expect(find.textContaining('Nothing starts unattended'), findsOneWidget);

      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.countdown,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().add(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 65)),
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-countdown-value')),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('live round shows server scores and the tracking banner', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();
      await harness.controller.takePracticeRep();
      harness.camera.emitPracticeRep();
      await tester.pumpAndSettle();
      harness.backend.readyReply = testMatch(
        status: ArenaMatchStatus.countdown,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().add(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 65)),
        serverNow: harness.clock.now(),
      );
      await harness.controller.submitReady();
      await tester.pumpAndSettle();

      harness.setLiveMatch(viewerScore: 12, opponentScore: 9);
      harness.clock.advance(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('battle-live-timer')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle-score-you')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle-score-opp')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle-live-status')), findsOneWidget);
      expect(
        find.textContaining('Tracking and connection stable'),
        findsOneWidget,
      );

      harness.camera.emitTracking(BattleCameraStatus.trackingLost);
      await tester.pumpAndSettle();
      expect(find.textContaining('your counting is paused'), findsOneWidget);
      harness.dispose();
    });

    testWidgets('back during preparation confirms before leaving', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('battle-leave')));
      await tester.pumpAndSettle();
      expect(find.text('Leave preparation?'), findsOneWidget);
      expect(
        find.textContaining('The match stays open for 10 minutes'),
        findsOneWidget,
      );

      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle-flow')), findsOneWidget);
      expect(harness.backend.callLog, isNot(contains('leave')));

      await tester.tap(find.byKey(const ValueKey('battle-leave')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-leave-confirm')));
      await tester.pumpAndSettle();
      expect(harness.backend.callLog, contains('leave'));
      expect(find.byKey(const ValueKey('battle-home')), findsOneWidget);
      harness.dispose();
    });

    testWidgets('back during a live round explains the forfeit honestly', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();
      await harness.controller.takePracticeRep();
      harness.camera.emitPracticeRep();
      await tester.pumpAndSettle();
      harness.backend.readyReply = testMatch(
        status: ArenaMatchStatus.countdown,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().add(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 65)),
        serverNow: harness.clock.now(),
      );
      await harness.controller.submitReady();
      await tester.pumpAndSettle();
      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('battle-leave')));
      await tester.pumpAndSettle();
      expect(find.text('Leave this battle?'), findsOneWidget);
      expect(find.textContaining('forfeits the match'), findsOneWidget);
      expect(
        find.textContaining('no result and no rating changes'),
        findsOneWidget,
      );
      harness.dispose();
    });

    testWidgets('declining a request confirms and creates nothing', (
      tester,
    ) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      await harness.controller.loadHome();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('battle-decline-request')));
      await tester.pumpAndSettle();
      expect(find.text('Decline this request?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('battle-decline-confirm')));
      await tester.pumpAndSettle();
      expect(harness.backend.callLog, contains('respond:decline'));
      expect(harness.controller.snapshot.match, isNull);
      harness.dispose();
    });
  });

  group('accessibility', () {
    testWidgets('score panels carry full semantic labels', (tester) async {
      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();
      await harness.controller.takePracticeRep();
      harness.camera.emitPracticeRep();
      await tester.pumpAndSettle();
      harness.backend.readyReply = testMatch(
        status: ArenaMatchStatus.countdown,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().add(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 65)),
        serverNow: harness.clock.now(),
      );
      await harness.controller.submitReady();
      await tester.pumpAndSettle();
      harness.setLiveMatch(viewerScore: 26, opponentScore: 23);
      harness.clock.advance(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel('Your score: 26 reps'), findsOneWidget);
      expect(find.bySemanticsLabel("@zuhra's score: 23 reps"), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Time remaining:')), findsOneWidget);
      handle.dispose();
      harness.dispose();
    });

    testWidgets('reduced motion removes the phase transition animation', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final harness = BattleHarness();
      await pumpBattleApp(tester, harness: harness);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-accept-request')));
      await tester.pumpAndSettle();

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(const ValueKey('battle-phase-switcher')),
      );
      expect(switcher.duration, Duration.zero);
      harness.dispose();
    });
  });

  group('request inbox states', () {
    Future<void> pumpInbox(WidgetTester tester, BattleHarness harness) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ArenaTheme.dark,
          home: BattleRuntimeScope(
            controller: harness.controller,
            child: const BattleInboxPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('loading skeleton shows until the inbox answers', (
      tester,
    ) async {
      final harness = BattleHarness();
      harness.backend.inboxGate = Completer<void>();
      unawaited(harness.controller.openInbox());
      await pumpInbox(tester, harness);
      expect(find.text('Loading requests…'), findsOneWidget);
      harness.backend.inboxGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Loading requests…'), findsNothing);
      harness.dispose();
    });

    testWidgets('expired, busy and cancelled requests render honest cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = BattleHarness();
      harness.backend.inboxData = BattleInbox(
        requests: [
          testRequest(id: 'r-expired', kind: BattleRequestKind.expired),
          testRequest(id: 'r-busy', kind: BattleRequestKind.busyPlayer),
          testRequest(id: 'r-cancelled', kind: BattleRequestKind.cancelled),
        ],
      );
      await pumpInbox(tester, harness);

      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('In a battle'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.textContaining('Requests expire 24 hours'), findsOneWidget);
      expect(find.textContaining('Wait until they finish'), findsOneWidget);
      harness.dispose();
    });

    testWidgets('blocked inbox shows a non-retryable explanation', (
      tester,
    ) async {
      final harness = BattleHarness();
      harness.backend.inboxFailure = const BattleFailure(
        BattleFailureKind.blocked,
        'This account cannot send or accept requests.',
      );
      await pumpInbox(tester, harness);
      expect(find.byKey(const ValueKey('inbox-blocked')), findsOneWidget);
      harness.dispose();
    });
  });

  group('preview fixtures', () {
    testWidgets('fixture mode is labelled on the Battle tab', (tester) async {
      final harness = BattleHarness(previewFixtures: true);
      await pumpBattleApp(tester, harness: harness);
      expect(
        find.byKey(const ValueKey('battle-preview-banner')),
        findsOneWidget,
      );
      expect(find.text('Preview fixtures'), findsOneWidget);
      harness.dispose();
    });
  });
}
