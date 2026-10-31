import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/ports/battle_analytics.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/domain/arena_types.dart';

import '../notifications/fakes.dart';
import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';

void main() {
  group('truthful ranked search window', () {
    test('empty queue times out at 60 seconds with no fake opponent', () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );
      expect(analytics.lastFor(MatchmakingAnalyticsEvent.searchStarted),
          isNotNull);

      // Mid-window checks: only the server can issue a match.
      harness.clock.advance(const Duration(seconds: 15));
      await pumpEventQueue();
      expect(harness.controller.snapshot.match, isNull);
      expect(harness.controller.snapshot.opponent, isNull);
      expect(harness.controller.snapshot.queueExtended, isTrue);

      harness.clock.advance(const Duration(seconds: 30));
      await pumpEventQueue();
      expect(harness.controller.snapshot.match, isNull);

      harness.clock.advance(const Duration(seconds: 15));
      await pumpEventQueue();

      final snapshot = harness.controller.snapshot;
      expect(snapshot.queuePhase, BattleQueuePhase.stopped);
      expect(snapshot.match, isNull);
      expect(snapshot.opponent, isNull);
      expect(snapshot.notice, contains('60 seconds'));
      expect(
        harness.backend.callLog.where((call) => call == 'queueLeave'),
        hasLength(1),
      );
      expect(analytics.countOf(MatchmakingAnalyticsEvent.searchTimedOut), 1);

      // Retry opens a fresh seat and never loops on its own.
      await harness.controller.startRankedSearch();
      await pumpEventQueue();
      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );
      harness.dispose();
    });

    test('15-second alternative is offered once and tracked once', () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.clock.advance(const Duration(seconds: 15));
      await pumpEventQueue();
      expect(harness.controller.snapshot.queueExtended, isTrue);
      expect(
        analytics
            .lastFor(MatchmakingAnalyticsEvent.friendAlternative)?['action'],
        'offered',
      );
      expect(
        analytics.countOf(MatchmakingAnalyticsEvent.friendAlternative),
        1,
      );

      harness.clock.advance(const Duration(seconds: 10));
      await pumpEventQueue();
      expect(
        analytics.countOf(MatchmakingAnalyticsEvent.friendAlternative),
        1,
      );
      harness.dispose();
    });

    test('switching to a friend challenge cancels the seat idempotently',
        () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();
      harness.clock.advance(const Duration(seconds: 16));
      await pumpEventQueue();

      await harness.controller.challengeFriend();
      await pumpEventQueue();
      await harness.controller.challengeFriend();
      await pumpEventQueue();

      expect(
        harness.backend.callLog.where((call) => call == 'queueLeave'),
        hasLength(1),
      );
      expect(harness.controller.snapshot.queuePhase, BattleQueuePhase.stopped);
      expect(
        analytics.lastFor(MatchmakingAnalyticsEvent.searchCancelled)?['reason'],
        'friend_challenge',
      );
      expect(
        analytics
            .lastFor(MatchmakingAnalyticsEvent.friendAlternative)?['action'],
        'switched',
      );
      final sharer = harness.sharer as RecordingChallengeSharer;
      expect(sharer.invites, hasLength(2));
      harness.dispose();
    });

    test('back (stop) is idempotent and repeated calls leave one seat',
        () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      await harness.controller.stopRankedSearch();
      await harness.controller.stopRankedSearch();
      await pumpEventQueue();

      expect(
        harness.backend.callLog.where((call) => call == 'queueLeave'),
        hasLength(1),
      );
      expect(harness.controller.snapshot.queuePhase, BattleQueuePhase.stopped);
      expect(
        analytics.lastFor(MatchmakingAnalyticsEvent.searchCancelled)?['reason'],
        'manual',
      );
      harness.dispose();
    });

    test('two rapid taps create only one queue seat', () async {
      final harness = BattleHarness();
      final first = harness.controller.startRankedSearch();
      final second = harness.controller.startRankedSearch();
      await Future.wait(<Future<void>>[first, second]);
      await pumpEventQueue();

      expect(
        harness.backend.callLog.where((call) => call == 'queueJoin'),
        hasLength(1),
      );
      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );
      harness.dispose();
    });

    test('pausing the app releases the seat and never rejoins', () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.controller.pause();
      await pumpEventQueue();
      harness.controller.pause();
      await pumpEventQueue();

      expect(harness.controller.snapshot.queuePhase, BattleQueuePhase.stopped);
      expect(
        harness.backend.callLog.where((call) => call == 'queueLeave'),
        hasLength(1),
      );
      expect(
        analytics.lastFor(MatchmakingAnalyticsEvent.searchCancelled)?['reason'],
        'app_paused',
      );

      await harness.controller.resume();
      await pumpEventQueue();
      expect(
        harness.backend.callLog.where((call) => call == 'queueJoin'),
        hasLength(1),
      );
      harness.dispose();
    });

    test('a network loss keeps the seat, shows reconnecting, then recovers',
        () async {
      final harness = BattleHarness();
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.backend.queueFailure =
          const BattleFailure(BattleFailureKind.offline, 'offline');
      harness.clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();
      expect(harness.controller.snapshot.queueOffline, isTrue);
      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );
      expect(harness.controller.snapshot.match, isNull);

      harness.backend.queueFailure = null;
      harness.clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();
      expect(harness.controller.snapshot.queueOffline, isFalse);
      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );
      harness.dispose();
    });

    test('a server-closed seat ends the search with honest copy', () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.backend.queuePollReply = BattleQueueState(
        joinedAt: harness.clock.now().subtract(const Duration(seconds: 5)),
        expiresAt: harness.clock.now().add(const Duration(seconds: 55)),
        serverNow: harness.clock.now(),
        queued: false,
      );
      harness.clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();

      final snapshot = harness.controller.snapshot;
      expect(snapshot.queuePhase, BattleQueuePhase.stopped);
      expect(snapshot.match, isNull);
      expect(snapshot.notice, contains('no longer active'));
      expect(
        analytics.lastFor(MatchmakingAnalyticsEvent.searchCancelled)?['reason'],
        'seat_closed',
      );
      harness.dispose();
    });

    test('starting a search during an active match is refused', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();

      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      expect(
        harness.backend.callLog.where((call) => call == 'queueJoin'),
        isEmpty,
      );
      expect(harness.controller.snapshot.notice, contains('Finish'));
      harness.dispose();
    });
  });

  group('server-issued match handoff', () {
    test('a real queue match enters preparation with mode and match id',
        () async {
      final analytics = RecordingBattleAnalyticsSink();
      final harness = BattleHarness(analytics: analytics);
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.backend.matchData =
          testMatch(id: 'ranked-7', mode: ArenaMatchMode.ranked);
      harness.backend.queuePollReply = BattleQueueState(
        matchId: 'ranked-7',
        joinedAt: harness.clock.now().subtract(const Duration(seconds: 4)),
        expiresAt: harness.clock.now().add(const Duration(seconds: 56)),
        serverNow: harness.clock.now(),
        queued: true,
      );
      harness.clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();

      final snapshot = harness.controller.snapshot;
      expect(snapshot.phase, BattlePhase.preparing);
      expect(snapshot.match?.id, 'ranked-7');
      expect(snapshot.match?.mode, ArenaMatchMode.ranked);
      expect(snapshot.origin, BattleMatchOrigin.rankedQueue);
      expect(snapshot.queuePhase, BattleQueuePhase.matched);
      expect(snapshot.practice, PracticeState.notStarted);
      expect(await harness.store.readActiveMatchId(), 'ranked-7');
      expect(harness.camera.callLog, contains('prepare:pushups'));
      expect(analytics.countOf(MatchmakingAnalyticsEvent.matchFound), 1);
      harness.dispose();
    });

    test('a blocked pairing never opens a match or an opponent', () async {
      final harness = BattleHarness();
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      // The server would never issue this pair; if it somehow did, the
      // authoritative match fetch fails closed and nothing is displayed.
      harness.backend.matchStateFailure = const BattleFailure(
        BattleFailureKind.blocked,
        'This player is blocked.',
      );
      harness.backend.matchStateFailures = 1;
      harness.backend.queuePollReply = BattleQueueState(
        matchId: 'blocked-1',
        joinedAt: harness.clock.now().subtract(const Duration(seconds: 2)),
        expiresAt: harness.clock.now().add(const Duration(seconds: 58)),
        serverNow: harness.clock.now(),
        queued: true,
      );
      harness.clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();

      expect(harness.controller.snapshot.match, isNull);
      expect(harness.controller.snapshot.opponent, isNull);
      expect(harness.controller.snapshot.phase, BattlePhase.home);
      expect(harness.controller.snapshot.notice, contains('blocked'));
      harness.dispose();
    });

    test('a queue match fetched after stopping is never applied', () async {
      final harness = BattleHarness();
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.backend.matchData =
          testMatch(id: 'ranked-9', mode: ArenaMatchMode.ranked);
      // Stop before the next poll; the seat is cancelled.
      await harness.controller.stopRankedSearch();
      harness.backend.queuePollReply = BattleQueueState(
        matchId: 'ranked-9',
        joinedAt: harness.clock.now().subtract(const Duration(seconds: 2)),
        expiresAt: harness.clock.now().add(const Duration(seconds: 58)),
        serverNow: harness.clock.now(),
        queued: true,
      );
      harness.clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();

      expect(harness.controller.snapshot.match, isNull);
      expect(harness.controller.snapshot.queuePhase, BattleQueuePhase.stopped);
      harness.dispose();
    });
  });
}
