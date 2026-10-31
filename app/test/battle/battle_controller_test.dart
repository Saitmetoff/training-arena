import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/battle/fixtures/battle_fixtures.dart';
import 'package:training_arena/battle/ports/battle_feedback.dart';
import 'package:training_arena/battle/ports/battle_session_store.dart';
import 'package:training_arena/battle/runtime/battle_controller.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/domain/arena_types.dart';

import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';

void main() {
  group('unsupported build recovery', () {
    const failure = BattleFailure(
      BattleFailureKind.updateRequired,
      'Update required',
    );
    test(
      'readiness rejection stops camera and timers without inventing a result',
      () async {
        final h = BattleHarness();
        addTearDown(h.dispose);
        await h.loadWithRequest();
        h.backend.matchData = testMatch();
        await h.controller.attachMatch('match-1');
        await h.controller.takePracticeRep();
        h.camera.emitPracticeRep();
        await pumpEventQueue();
        h.backend.readyFailure = failure;
        await h.controller.submitReady();
        await pumpEventQueue();
        expect(h.controller.snapshot.phase, BattlePhase.updateRequired);
        expect(h.controller.snapshot.receipt, isNull);
        expect(h.controller.snapshot.noResultReason, isNull);
        expect(await h.store.readActiveMatchId(), isNull);
        expect(h.camera.callLog.last, 'stop');
        final calls = h.backend.callLog.length;
        h.clock.advance(const Duration(seconds: 20));
        await h.controller.retryTracking();
        await h.controller.retryConnection();
        await h.controller.restoreSession();
        await pumpEventQueue();
        expect(h.backend.callLog.length, calls);
        expect(h.controller.snapshot.phase, BattlePhase.updateRequired);
      },
    );
    test(
      'rep rejection discards pending retries and prevents live continuation',
      () async {
        final h = BattleHarness();
        addTearDown(h.dispose);
        await h.loadWithRequest();
        h.backend.matchData = testMatch();
        await h.controller.attachMatch('match-1');
        await h.completePracticeAndReady();
        h.setLiveMatch();
        h.clock.advance(const Duration(seconds: 6));
        await pumpEventQueue();
        h.backend.repFailure = failure;
        h.camera.emitCompetitiveRep();
        await pumpEventQueue();
        expect(h.controller.snapshot.phase, BattlePhase.updateRequired);
        expect(h.controller.snapshot.receipt, isNull);
        final reps = h.backend.repCalls.length;
        h.camera.emitCompetitiveRep(sequence: 2);
        h.clock.advance(const Duration(seconds: 20));
        await pumpEventQueue();
        expect(h.backend.repCalls.length, reps);
        expect(h.camera.callLog.last, 'stop');
      },
    );
    test('process restore validates before starting camera', () async {
      final h = BattleHarness();
      addTearDown(h.dispose);
      await h.store.writeActiveMatchId('match-1');
      h.backend.matchStateFailures = 1;
      h.backend.matchStateFailure = failure;
      await h.controller.restoreSession();
      await pumpEventQueue();
      expect(h.controller.snapshot.phase, BattlePhase.updateRequired);
      expect(
        h.camera.callLog.where(
          (c) => c.startsWith('prepare') || c == 'startMatch',
        ),
        isEmpty,
      );
      expect(await h.store.readActiveMatchId(), isNull);
    });
  });
  group('home and match creation', () {
    test(
      'rematch coalesces taps and preserves the receipt on failure',
      () async {
        final harness = BattleHarness();
        addTearDown(harness.dispose);
        await harness.loadWithRequest();
        harness.backend.matchData = testMatch(
          status: ArenaMatchStatus.finished,
          receipt: testReceipt(),
        );
        await harness.controller.attachMatch('match-1');
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();
        harness.backend.rematchGate = Completer<void>();
        harness.backend.rematchFailure = const BattleFailure(
          BattleFailureKind.blocked,
          'Challenge is unavailable.',
        );
        final first = harness.controller.requestRematch();
        await harness.controller.requestRematch();
        expect(
          harness.backend.callLog.where((c) => c == 'rematch:match-1'),
          hasLength(1),
        );
        expect(harness.controller.rematching, isTrue);
        harness.backend.rematchGate!.complete();
        await first;
        expect(harness.controller.snapshot.phase, BattlePhase.result);
        expect(harness.controller.snapshot.receipt?.id, 'receipt-1');
        expect(harness.controller.snapshot.notice, 'Challenge is unavailable.');
        expect(harness.controller.rematching, isFalse);
      },
    );
    test('inbox loads the incoming request', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      await pumpEventQueue();

      expect(harness.controller.snapshot.phase, BattlePhase.home);
      expect(harness.controller.snapshot.incomingRequest?.id, 'request-1');
      harness.dispose();
    });

    test(
      'unconfigured backend never schedules polling and stays honest',
      () async {
        final clock = ManualBattleClock();
        final controller = BattleController(
          backend: FakeBattleBackend(now: () => clock.now())
            ..configured = false,
          camera: FakeBattleCamera(),
          clock: clock,
          feedback: RecordingBattleFeedback(),
          sessionStore: InMemoryBattleSessionStore(),
          viewer: ValueNotifier<ArenaProfile?>(testViewer),
        );
        await controller.loadHome();
        await pumpEventQueue();
        expect(controller.snapshot.inboxStatus, BattleLoadStatus.unconfigured);
        expect(controller.snapshot.notice, isNull);
        controller.dispose();
      },
    );

    test(
      'accept request creates a match, persists the id and never starts',
      () async {
        final harness = BattleHarness();
        await harness.loadWithRequest();
        harness.backend.matchData = testMatch();
        await harness.controller.acceptRequest('request-1');
        await pumpEventQueue();

        final snapshot = harness.controller.snapshot;
        expect(snapshot.phase, BattlePhase.preparing);
        expect(snapshot.match?.id, 'match-1');
        expect(snapshot.origin, BattleMatchOrigin.request);
        expect(snapshot.practice, PracticeState.notStarted);
        expect(snapshot.readySubmitted, isFalse);
        expect(await harness.store.readActiveMatchId(), 'match-1');
        expect(harness.camera.callLog, contains('prepare:pushups'));
        harness.dispose();
      },
    );

    test('attachMatch enters a match the server already created', () async {
      final harness = BattleHarness();
      harness.backend.matchData = testMatch(id: 'linked-1');
      await harness.controller.attachMatch('linked-1');
      await pumpEventQueue();

      expect(harness.controller.snapshot.phase, BattlePhase.preparing);
      expect(
        harness.controller.snapshot.origin,
        BattleMatchOrigin.challengeLink,
      );
      harness.dispose();
    });
  });

  group('practice and ready gate', () {
    test('ready is submitted with tracking and practice facts only after the '
        'practice rep', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();

      // Ready before the practice rep is refused locally.
      await harness.controller.requestReady();
      await pumpEventQueue();
      expect(harness.backend.readyCalls, isEmpty);
      expect(harness.controller.snapshot.notice, contains('practice rep'));

      await harness.completePracticeAndReady();
      expect(harness.backend.readyCalls, hasLength(1));
      expect(harness.backend.readyCalls.single['tracking'], isTrue);
      expect(harness.backend.readyCalls.single['practiceComplete'], isTrue);
      harness.dispose();
    });

    test('both players ready is required before the countdown', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();
      await harness.controller.takePracticeRep();
      harness.camera.emitPracticeRep();
      await pumpEventQueue();

      harness.backend.readyReply = testMatch(
        status: ArenaMatchStatus.preparing,
        viewerReady: true,
        opponentReady: false,
        serverNow: harness.clock.now(),
      );
      await harness.controller.submitReady();
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.ready);
      expect(harness.controller.snapshot.opponentReady, isFalse);

      // The server starts the countdown only when both are ready.
      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.countdown,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().add(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 65)),
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.countdown);
      harness.dispose();
    });
  });

  group('ranked queue', () {
    test('15 seconds offers the friend alternative without claiming anyone '
        'is online', () async {
      final harness = BattleHarness();
      await harness.controller.startRankedSearch();
      await pumpEventQueue();
      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );

      harness.clock.advance(const Duration(seconds: 15));
      await pumpEventQueue();
      expect(harness.controller.snapshot.queueExtended, isTrue);
      expect(harness.backend.callLog, isNot(contains('queueLeave')));
      harness.dispose();
    });

    test(
      'the visible window advances when the queue reply has no clock',
      () async {
        final harness = BattleHarness();
        final joined = harness.clock.now();
        harness.backend.queueJoinReply = BattleQueueState(
          joinedAt: joined,
          expiresAt: joined.add(const Duration(seconds: 60)),
          queued: true,
        );
        harness.backend.queuePollReply = BattleQueueState(
          joinedAt: joined,
          expiresAt: joined.add(const Duration(seconds: 60)),
          queued: true,
        );
        await harness.controller.startRankedSearch();
        await pumpEventQueue();
        expect(
          harness.controller.snapshot.queuePhase,
          BattleQueuePhase.searching,
        );

        harness.clock.advance(const Duration(seconds: 16));
        await pumpEventQueue();
        expect(
          harness.controller.snapshot.queueElapsed.inSeconds,
          greaterThanOrEqualTo(15),
        );
        expect(harness.controller.snapshot.queueExtended, isTrue);
        harness.dispose();
      },
    );

    test('switching to a friend challenge cancels the queue seat', () async {
      final harness = BattleHarness();
      await harness.controller.startRankedSearch();
      await pumpEventQueue();
      harness.clock.advance(const Duration(seconds: 16));
      await pumpEventQueue();

      await harness.controller.challengeFriend();
      await pumpEventQueue();
      expect(harness.backend.callLog, contains('queueLeave'));
      expect(harness.controller.snapshot.queuePhase, BattleQueuePhase.stopped);
      final sharer = harness.sharer as RecordingChallengeSharer;
      expect(sharer.invites, hasLength(1));
      harness.dispose();
    });

    test('search stops at 60 seconds with the seat cancelled', () async {
      final harness = BattleHarness();
      await harness.controller.startRankedSearch();
      await pumpEventQueue();

      harness.clock.advance(const Duration(seconds: 60));
      await pumpEventQueue();
      expect(harness.controller.snapshot.queuePhase, BattleQueuePhase.stopped);
      expect(harness.backend.callLog, contains('queueLeave'));
      expect(harness.controller.snapshot.notice, contains('60 seconds'));

      // Retry starts a new seat.
      await harness.controller.startRankedSearch();
      await pumpEventQueue();
      expect(
        harness.controller.snapshot.queuePhase,
        BattleQueuePhase.searching,
      );
      harness.dispose();
    });
  });

  group('live round degradation', () {
    Future<BattleHarness> enterLive() async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();
      await harness.completePracticeAndReady();
      expect(harness.controller.snapshot.phase, BattlePhase.countdown);
      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.live);
      return harness;
    }

    test(
      'tracking loss pauses this player count while the shared clock runs',
      () async {
        final harness = await enterLive();
        final before = harness.controller.phaseRemaining;

        harness.camera.emitTracking(BattleCameraStatus.trackingLost);
        await pumpEventQueue();
        expect(harness.controller.snapshot.phase, BattlePhase.reconnecting);
        expect(
          harness.controller.snapshot.connection,
          BattleConnection.selfTrackingLost,
        );

        harness.clock.advance(const Duration(seconds: 2));
        await pumpEventQueue();
        final heartbeat = harness.backend.callLog.lastWhere(
          (c) => c.startsWith('heartbeat'),
        );
        expect(heartbeat, 'heartbeat:false');
        // The clock kept running even while counting was paused.
        expect(harness.controller.phaseRemaining, lessThan(before!));

        harness.camera.emitTracking(BattleCameraStatus.tracking);
        await pumpEventQueue();
        expect(harness.controller.snapshot.phase, BattlePhase.live);
        harness.dispose();
      },
    );

    test('opponent forfeit is rendered only from the server receipt', () async {
      final harness = await enterLive();
      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.live,
        viewerReady: true,
        opponentReady: true,
        opponentTracking: false,
        startsAt: harness.clock.now().subtract(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 55)),
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.reconnecting);
      expect(harness.controller.snapshot.receipt, isNull);

      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.finished,
        viewerReady: true,
        opponentReady: true,
        receipt: testReceipt(),
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.result);
      expect(harness.controller.snapshot.receipt?.id, 'receipt-1');
      harness.dispose();
    });

    test('a ten-second outage expires the local recovery window and the '
        'server still owns the outcome', () async {
      final harness = await enterLive();
      harness.backend.heartbeatFailures = 100;
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(
        harness.controller.snapshot.connection,
        BattleConnection.serviceOutage,
      );
      expect(harness.controller.snapshot.phase, BattlePhase.reconnecting);

      harness.clock.advance(const Duration(seconds: 10));
      await pumpEventQueue();
      expect(harness.controller.snapshot.reconnectExpired, isTrue);
      // No local winner exists even after the recovery window.
      expect(harness.controller.snapshot.receipt, isNull);
      expect(harness.controller.snapshot.phase, BattlePhase.reconnecting);

      harness.backend.heartbeatFailures = 0;
      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.noResult,
        reason: 'service_unavailable',
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.noResult);
      expect(harness.controller.snapshot.receipt, isNull);
      harness.dispose();
    });

    test(
      'an outage that recovers before ten seconds returns to live',
      () async {
        final harness = await enterLive();
        harness.backend.heartbeatFailures = 2;
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();
        expect(
          harness.controller.snapshot.connection,
          BattleConnection.serviceOutage,
        );

        harness.backend.matchData = testMatch(
          status: ArenaMatchStatus.live,
          viewerReady: true,
          opponentReady: true,
          startsAt: harness.clock.now().subtract(const Duration(seconds: 3)),
          endsAt: harness.clock.now().add(const Duration(seconds: 57)),
          serverNow: harness.clock.now(),
        );
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();
        expect(harness.controller.snapshot.phase, BattlePhase.live);
        expect(harness.controller.snapshot.connection, BattleConnection.online);
        harness.dispose();
      },
    );
  });

  group('receipt and rep idempotency', () {
    test(
      'duplicate competitive events never double-count the displayed score',
      () async {
        final harness = BattleHarness();
        await harness.loadWithRequest();
        harness.backend.matchData = testMatch();
        await harness.controller.acceptRequest('request-1');
        await pumpEventQueue();
        await harness.completePracticeAndReady();
        harness.setLiveMatch();
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();

        harness.backend.repReply = testMatch(
          status: ArenaMatchStatus.live,
          viewerReady: true,
          opponentReady: true,
          viewerScore: 1,
          startsAt: harness.clock.now().subtract(const Duration(seconds: 2)),
          endsAt: harness.clock.now().add(const Duration(seconds: 58)),
          serverNow: harness.clock.now(),
        );
        harness.camera.emitCompetitiveRep(eventId: 'rep-1', sequence: 1);
        await pumpEventQueue();
        harness.camera.emitCompetitiveRep(eventId: 'rep-1', sequence: 1);
        await pumpEventQueue();

        expect(harness.backend.repCalls, hasLength(2));
        expect(harness.backend.repCalls.first.eventId, 'rep-1');
        expect(harness.backend.repCalls.last.eventId, 'rep-1');
        expect(harness.controller.snapshot.viewerPlayer?.score, 1);
        harness.dispose();
      },
    );

    test(
      'a rejected rep is dropped with honest copy and no local score',
      () async {
        final harness = BattleHarness();
        await harness.loadWithRequest();
        harness.backend.matchData = testMatch();
        await harness.controller.acceptRequest('request-1');
        await pumpEventQueue();
        await harness.completePracticeAndReady();
        harness.setLiveMatch(viewerScore: 4);
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();

        harness.backend.repConflicts = 1;
        harness.camera.emitCompetitiveRep(eventId: 'rep-late', sequence: 5);
        await pumpEventQueue();
        expect(harness.controller.snapshot.viewerPlayer?.score, 4);
        expect(
          harness.controller.snapshot.notice,
          contains('server-confirmed'),
        );
        harness.dispose();
      },
    );

    test('non-competitive counter events never score a match', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();
      await harness.completePracticeAndReady();
      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();

      harness.camera.emitPracticeRep();
      await pumpEventQueue();
      expect(harness.backend.repCalls, isEmpty);
      harness.dispose();
    });
  });

  group('lifecycle persistence', () {
    test('restores the match id after a process restart', () async {
      final store = InMemoryBattleSessionStore();
      await store.writeActiveMatchId('match-restored');
      final clock = ManualBattleClock();
      final backend = FakeBattleBackend(now: () => clock.now())
        ..matchData = testMatch(id: 'match-restored');
      final controller = BattleController(
        backend: backend,
        camera: FakeBattleCamera(),
        clock: clock,
        feedback: RecordingBattleFeedback(),
        sessionStore: store,
        viewer: ValueNotifier<ArenaProfile?>(testViewer),
      );

      await controller.restoreSession();
      await pumpEventQueue();
      expect(controller.snapshot.phase, BattlePhase.preparing);
      expect(controller.snapshot.activeMatchId, 'match-restored');
      controller.dispose();
    });

    test('pause stops the clock work; resume re-reads the server', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();
      await harness.completePracticeAndReady();
      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();

      harness.controller.pause();
      final heartbeatsBefore = harness.backend.heartbeatCalls;
      harness.clock.advance(const Duration(seconds: 5));
      await pumpEventQueue();
      expect(harness.backend.heartbeatCalls, heartbeatsBefore);

      await harness.controller.resume();
      await pumpEventQueue();
      expect(harness.backend.heartbeatCalls, greaterThan(heartbeatsBefore));
      expect(harness.controller.snapshot.match?.id, 'match-1');
      harness.dispose();
    });

    test(
      'shared-preferences store keeps the match id across store instances',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final first = SharedPreferencesBattleSessionStore();
        await first.writeActiveMatchId('match-persisted');
        final second = SharedPreferencesBattleSessionStore();
        expect(await second.readActiveMatchId(), 'match-persisted');
        await second.writeActiveMatchId(null);
        final third = SharedPreferencesBattleSessionStore();
        expect(await third.readActiveMatchId(), isNull);
      },
    );

    test('terminal receipts clear the persisted match id', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();
      await harness.completePracticeAndReady();
      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();

      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.finished,
        receipt: testReceipt(),
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.controller.snapshot.phase, BattlePhase.result);
      expect(await harness.store.readActiveMatchId(), isNull);
      harness.dispose();
    });
  });

  group('camera and cues', () {
    test('permission denial is surfaced and blocks the practice rep', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.camera.prepareResult = BattleCameraStatus.permissionDenied;
      harness.camera.prepareMessage = 'Camera access is blocked.';
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();

      expect(
        harness.controller.snapshot.cameraStatus,
        BattleCameraStatus.permissionDenied,
      );
      expect(
        harness.controller.snapshot.cameraMessage,
        'Camera access is blocked.',
      );

      await harness.controller.takePracticeRep();
      await pumpEventQueue();
      expect(harness.controller.snapshot.practice, PracticeState.counting);
      await harness.controller.requestReady();
      await pumpEventQueue();
      expect(harness.backend.readyCalls, isEmpty);
      harness.dispose();
    });

    test('countdown and final-threshold cues fire once', () async {
      final harness = BattleHarness();
      await harness.loadWithRequest();
      harness.backend.matchData = testMatch();
      await harness.controller.acceptRequest('request-1');
      await pumpEventQueue();
      await harness.completePracticeAndReady();
      expect(harness.controller.snapshot.phase, BattlePhase.countdown);
      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.countdown,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().add(const Duration(seconds: 5)),
        endsAt: harness.clock.now().add(const Duration(seconds: 65)),
        serverNow: harness.clock.now(),
      );

      for (var i = 0; i < 5; i++) {
        harness.clock.advance(const Duration(seconds: 1));
        await pumpEventQueue();
      }
      expect(
        harness.feedback.cues.where((cue) => cue.startsWith('countdown:')),
        isNotEmpty,
      );
      expect(harness.controller.snapshot.phase, BattlePhase.live);

      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.live,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().subtract(const Duration(seconds: 51)),
        endsAt: harness.clock.now().add(const Duration(seconds: 9)),
        serverNow: harness.clock.now(),
      );
      // First tick delivers the live snapshot, the next one evaluates the
      // remaining time against it.
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.feedback.cues, contains('ten'));

      harness.backend.matchData = testMatch(
        status: ArenaMatchStatus.live,
        viewerReady: true,
        opponentReady: true,
        startsAt: harness.clock.now().subtract(const Duration(seconds: 58)),
        endsAt: harness.clock.now().add(const Duration(seconds: 2)),
        serverNow: harness.clock.now(),
      );
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      harness.clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(harness.feedback.cues, contains('three'));
      harness.dispose();
    });
  });

  group('preview fixtures', () {
    test('fixtures never produce receipts or ranked seats', () async {
      final clock = ManualBattleClock();
      final controller = BattleController(
        backend: FixtureBattleBackend(clock: clock),
        camera: FixtureBattleCamera(clock: clock),
        clock: clock,
        feedback: const SilentBattleFeedback(),
        sessionStore: InMemoryBattleSessionStore(),
        viewer: ValueNotifier<ArenaProfile?>(BattleFixtureData.viewer),
        previewFixtures: true,
      );

      await controller.loadHome();
      await pumpEventQueue();
      expect(controller.snapshot.previewFixtures, isTrue);
      expect(controller.snapshot.incomingRequest, isNotNull);

      await controller.acceptRequest(BattleFixtureData.requestId);
      await pumpEventQueue();
      expect(controller.snapshot.phase, BattlePhase.preparing);

      await controller.takePracticeRep();
      clock.advance(const Duration(milliseconds: 600));
      await pumpEventQueue();
      expect(controller.snapshot.practice, PracticeState.completed);

      await controller.requestReady();
      await pumpEventQueue();
      expect(controller.snapshot.receipt, isNull);
      expect(controller.snapshot.phase, BattlePhase.preparing);
      expect(controller.snapshot.noticeKind, BattleNoticeKind.info);
      expect(
        controller.snapshot.notice,
        contains('Preview fixtures cannot report'),
      );

      await controller.startRankedSearch();
      await pumpEventQueue();
      // Preview mode refuses a ranked seat at the controller boundary, before
      // any backend is consulted; no ranked seat is ever made.
      expect(controller.snapshot.queuePhase, BattleQueuePhase.idle);
      expect(controller.snapshot.noticeKind, BattleNoticeKind.info);
      expect(
        controller.snapshot.notice,
        contains('Preview fixtures cannot start'),
      );
      expect(controller.snapshot.match, isNotNull);
      controller.dispose();
    });
  });
}
