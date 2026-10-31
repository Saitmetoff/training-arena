import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/runtime/battle_runtime.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/arena_linking.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_persistence.dart';
import 'package:training_arena/linking/challenge_share.dart';

import '../linking/fakes.dart';
import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';
import '../support/battle_widget_harness.dart';

void main() {
  testWidgets('a finished match without a receipt never renders a result',
      (tester) async {
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
    harness.setLiveMatch(viewerScore: 20, opponentScore: 18);
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The clock ended server-side, but there is no receipt yet.
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      viewerReady: true,
      opponentReady: true,
      viewerScore: 20,
      opponentScore: 18,
      serverNow: harness.clock.now(),
    );
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(harness.controller.snapshot.receipt, isNull);
    expect(find.byKey(const ValueKey('battle-result-headline')), findsNothing);
    expect(find.byKey(const ValueKey('battle-live-timer')), findsOneWidget);

    // Only the server receipt opens the result screen.
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      viewerReady: true,
      opponentReady: true,
      viewerScore: 26,
      opponentScore: 23,
      receipt: testReceipt(),
      serverNow: harness.clock.now(),
    );
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('battle-result-headline')), findsOneWidget);
    expect(find.text('I beat @zuhra by 3'), findsOneWidget);
    harness.dispose();
  });

  testWidgets('a forfeit receipt never claims a zero-margin score',
      (tester) async {
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
    harness.setLiveMatch(viewerScore: 0, opponentScore: 0);
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The server forfeits the absent opponent without a scored round.
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      viewerReady: true,
      opponentReady: true,
      viewerScore: 0,
      opponentScore: 0,
      receipt: testReceipt(
        outcome: ArenaMatchOutcome.win,
        winnerId: 'opponent-1',
        viewerScore: 0,
        opponentScore: 0,
        reason: 'opponent_absent',
      ),
      reason: 'opponent_absent',
      serverNow: harness.clock.now(),
    );
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.text('I didn\'t finish — @zuhra wins'),
      findsOneWidget,
    );
    expect(find.text('@zuhra beat me by 0'), findsNothing);
    harness.dispose();
  });

  testWidgets('duplicate polling updates are idempotent in the UI',
      (tester) async {
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

    final live = testMatch(
      status: ArenaMatchStatus.live,
      viewerReady: true,
      opponentReady: true,
      viewerScore: 7,
      opponentScore: 5,
      startsAt: harness.clock.now().subtract(const Duration(seconds: 3)),
      endsAt: harness.clock.now().add(const Duration(seconds: 57)),
      serverNow: harness.clock.now(),
    );
    harness.backend.matchData = live;
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    harness.clock.advance(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battle-score-you')), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-score-opp')), findsOneWidget);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Your score: 7 reps'), findsOneWidget);
    handle.dispose();
    harness.dispose();
  });

  test('a new user returning from challenge sign-in resumes the challenge',
      () async {
    final harness = BattleHarness(viewerProfile: null);
    harness.backend.matchData = testMatch();
    await harness.controller.beginChallenge(
      const ChallengeContext(token: '9f2k4p7q', sender: testOpponent),
    );
    await pumpEventQueue();

    expect(harness.controller.snapshot.match, isNull);
    expect(harness.controller.snapshot.challengeAwaitingSignIn, isTrue);

    harness.viewer.value = testViewer;
    await pumpEventQueue();
    expect(harness.controller.snapshot.phase, BattlePhase.preparing);
    expect(harness.controller.snapshot.match?.id, 'match-1');
    expect(harness.controller.snapshot.pendingChallenge, isNull);
    harness.dispose();
  });

  testWidgets('a link landing hands the confirmed match to the battle flow',
      (tester) async {
    final api = FakeArenaChallengeApi();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final analytics = MemoryChallengeAnalyticsSink();
    final config = testConfig();
    final entryController = ChallengeEntryController(
      config: config,
      api: api,
      persistence: MemoryChallengePersistence(),
      deepLinks: deepLinks,
      installReferrer: FakeInstallReferrerSource(),
      auth: FakeChallengeAuthDelegate(),
      analytics: analytics,
      matchPollInterval: Duration.zero,
    );
    final linking = ArenaLinking(
      config: config,
      controller: entryController,
      shareService: ChallengeShareService(
        api: api,
        config: config,
        launcher: FakeShareSheetLauncher(),
        analytics: analytics,
      ),
      installLauncher: FakeChallengeInstallLauncher(),
      analytics: analytics,
      auth: FakeChallengeAuthDelegate(),
    );
    final harness = BattleHarness();
    harness.backend.matchData = testMatch(id: fakeMatchId);

    await pumpBattleApp(tester, harness: harness, linking: linking);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('challenge-landing-review')),
      findsOneWidget,
    );

    await entryController.acceptChallenge();
    api.activeMatchId = fakeMatchId;
    await entryController.checkForAcceptedMatch();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('challenge-match-ready-view')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('challenge-open-battle-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battle-flow')), findsOneWidget);
    expect(find.text('Preparation'), findsOneWidget);
    expect(
      harness.controller.snapshot.origin,
      BattleMatchOrigin.challengeLink,
    );
    harness.dispose();
  });

  testWidgets('draws stay ties', (tester) async {
    final drawHarness = BattleHarness();
    await drawHarness.store.writeActiveMatchId('match-1');
    drawHarness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      receipt: testReceipt(
        outcome: ArenaMatchOutcome.draw,
        winnerId: null,
        viewerScore: 24,
        opponentScore: 24,
      ),
    );
    await pumpBattleApp(tester, harness: drawHarness);
    expect(find.text('Draw — 24 each'), findsOneWidget);
    drawHarness.dispose();
  });

  testWidgets('losses are viewer-relative', (tester) async {
    final lossHarness = BattleHarness();
    await lossHarness.store.writeActiveMatchId('match-1');
    lossHarness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      receipt: testReceipt(
        outcome: ArenaMatchOutcome.win,
        winnerId: testOpponent.id,
        viewerScore: 19,
        opponentScore: 24,
      ),
    );
    await pumpBattleApp(tester, harness: lossHarness);
    expect(find.text('@zuhra beat me by 5'), findsOneWidget);
    lossHarness.dispose();
  });

  testWidgets('a no-result receipt changes no rating', (tester) async {
    final harness = BattleHarness();
    await harness.store.writeActiveMatchId('match-1');
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.noResult,
      reason: 'The battle service stopped responding before a confirmed '
          'score.',
    );
    await pumpBattleApp(tester, harness: harness);
    expect(find.text('No result'), findsOneWidget);
    expect(find.text('No rating change'), findsOneWidget);
    expect(
      find.textContaining('stopped responding'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('battle-result-headline')), findsNothing);
    harness.dispose();
  });

  testWidgets('ranked receipts show the confirmed rating change',
      (tester) async {
    final harness = BattleHarness();
    await harness.store.writeActiveMatchId('match-1');
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      receipt: testReceipt(
        mode: ArenaMatchMode.ranked,
        outcome: ArenaMatchOutcome.win,
        winnerId: testViewer.id,
        viewerScore: 31,
        opponentScore: 28,
        ratingAfter: 1058,
        ratingChange: 16,
      ),
    );
    await pumpBattleApp(tester, harness: harness);
    expect(find.text('Ranked · 1042 → 1058'), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-result-share')), findsOneWidget);
    harness.dispose();
  });

  testWidgets('an unknown viewer never reads a receipt as a personal loss',
      (tester) async {
    final harness = BattleHarness(viewerProfile: null);
    await harness.store.writeActiveMatchId('match-1');
    harness.backend.matchData = testMatch(
      status: ArenaMatchStatus.finished,
      receipt: testReceipt(
        outcome: ArenaMatchOutcome.win,
        winnerId: testOpponent.id,
        viewerScore: 12,
        opponentScore: 20,
      ),
    );
    await pumpBattleApp(tester, harness: harness);
    expect(find.textContaining('beat me'), findsNothing);
    expect(find.text('@zuhra won'), findsOneWidget);
    harness.dispose();
  });

  test('fromConfig shares one viewer notifier with the controller', () {
    final runtime = BattleRuntime.fromConfig(testConfig());
    expect(runtime.controller.snapshot.viewer, isNull);
    runtime.setViewer(testViewer);
    expect(runtime.controller.snapshot.viewer?.id, testViewer.id);
    runtime.dispose();
  });
}
