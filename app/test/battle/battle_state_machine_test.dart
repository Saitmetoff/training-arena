import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/state/battle_events.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/battle/state/battle_snapshot.dart';
import 'package:training_arena/battle/state/battle_state_machine.dart';
import 'package:training_arena/domain/arena_types.dart';

import '../support/battle_fakes.dart';

void main() {
  BattleSnapshot home({bool signedIn = true}) {
    var state = BattleSnapshot(viewer: signedIn ? testViewer : null);
    state = BattleStateMachine.apply(
      state,
      const InboxLoaded(BattleInbox()),
    );
    return state;
  }

  BattleSnapshot active({ArenaMatchStatus status = ArenaMatchStatus.preparing}) {
    var state = home();
    state = BattleStateMachine.apply(
      state,
      MatchCreated(testMatch(status: status), BattleMatchOrigin.request),
    );
    return state;
  }

  BattleSnapshot live() {
    var state = active();
    state = BattleStateMachine.apply(
      state,
      MatchUpdated(testMatch(
        status: ArenaMatchStatus.live,
        startsAt: DateTime.utc(2026, 9, 18, 12),
        endsAt: DateTime.utc(2026, 9, 18, 12, 1),
        serverNow: DateTime.utc(2026, 9, 18, 12, 0, 1),
      )),
    );
    return state;
  }

  group('link/request/inbox', () {
    test('inbox load success enters home', () {
      final state = BattleStateMachine.apply(
        const BattleSnapshot(viewer: testViewer),
        InboxLoaded(BattleInbox(requests: [testRequest()])),
      );
      expect(state.phase, BattlePhase.home);
      expect(state.inboxStatus, BattleLoadStatus.ready);
      expect(state.incomingRequest?.id, 'request-1');
    });

    test('empty inbox is the empty state, not an error', () {
      final state = BattleStateMachine.apply(
        const BattleSnapshot(viewer: testViewer),
        const InboxLoaded(BattleInbox()),
      );
      expect(state.inboxStatus, BattleLoadStatus.empty);
      expect(state.incomingRequest, isNull);
    });

    test('offline/unconfigured/unauthorized/blocked map to distinct states',
        () {
      final offline = BattleStateMachine.apply(
        home(),
        const InboxLoadFailed(BattleFailure(BattleFailureKind.offline, 'off')),
      );
      expect(offline.inboxStatus, BattleLoadStatus.offline);

      final unconfigured = BattleStateMachine.apply(
        home(),
        const InboxLoadFailed(
          BattleFailure(BattleFailureKind.unconfigured, 'none'),
        ),
      );
      expect(unconfigured.inboxStatus, BattleLoadStatus.unconfigured);

      final signedOut = BattleStateMachine.apply(
        home(),
        const InboxLoadFailed(
          BattleFailure(BattleFailureKind.unauthorized, 'auth'),
        ),
      );
      expect(signedOut.inboxStatus, BattleLoadStatus.signedOut);

      final blocked = BattleStateMachine.apply(
        home(),
        const InboxBlocked(testOpponent, 'blocked'),
      );
      expect(blocked.inboxStatus, BattleLoadStatus.blocked);
    });

    test('challenge pending waits for sign-in and keeps the context', () {
      final state = BattleStateMachine.apply(
        const BattleSnapshot(),
        const ChallengePending(
          ChallengeContext(token: '9f2k4p7q', sender: testOpponent),
        ),
      );
      expect(state.pendingChallenge?.token, '9f2k4p7q');
      expect(state.challengeAwaitingSignIn, isTrue);

      final signedIn = BattleStateMachine.apply(
        state,
        const ViewerChanged(testViewer),
      );
      expect(signedIn.challengeAwaitingSignIn, isFalse);
      expect(signedIn.pendingChallenge?.token, '9f2k4p7q');
    });

    test('accept failure keeps the challenge for retry; no match is created',
        () {
      var state = BattleStateMachine.apply(
        const BattleSnapshot(viewer: testViewer),
        const ChallengePending(ChallengeContext(token: 't')),
      );
      state = BattleStateMachine.apply(state, const ChallengeAcceptStarted());
      expect(state.phase, BattlePhase.resolving);
      state = BattleStateMachine.apply(
        state,
        const ChallengeAcceptFailed(
          BattleFailure(BattleFailureKind.offline, 'offline'),
        ),
      );
      expect(state.phase, BattlePhase.home);
      expect(state.match, isNull);
      expect(state.pendingChallenge, isNotNull);
      expect(state.noticeKind, BattleNoticeKind.danger);
    });

    test('request resolved renders cancelled without a match', () {
      var state = home();
      state = BattleStateMachine.apply(
        state,
        InboxLoaded(BattleInbox(requests: [testRequest()])),
      );
      state = BattleStateMachine.apply(
        state,
        const RequestResolved('request-1', BattleRequestKind.cancelled),
      );
      expect(state.requests, isEmpty);
      expect(state.inboxStatus, BattleLoadStatus.empty);
      expect(state.notice, contains('No match was created'));
    });

    test('inbox open/close toggles the inbox phase only', () {
      var state = home();
      state = BattleStateMachine.apply(state, const InboxOpened());
      expect(state.phase, BattlePhase.inbox);
      state = BattleStateMachine.apply(state, const InboxClosed());
      expect(state.phase, BattlePhase.home);
    });
  });

  group('preparation, practice, ready', () {
    test('match creation always starts in preparation, never in live', () {
      final state = BattleStateMachine.apply(
        home(),
        MatchCreated(testMatch(), BattleMatchOrigin.challengeLink),
      );
      expect(state.phase, BattlePhase.preparing);
      expect(state.practice, PracticeState.notStarted);
      expect(state.readySubmitted, isFalse);
      expect(state.activeMatchId, 'match-1');
    });

    test('practice arms only in preparation and completes exactly once', () {
      var state = active();
      state = BattleStateMachine.apply(state, const PracticeArmed());
      expect(state.practice, PracticeState.counting);
      state = BattleStateMachine.apply(state, const PracticeRepCounted());
      expect(state.practice, PracticeState.completed);
      state = BattleStateMachine.apply(state, const PracticeRepCounted());
      expect(state.practice, PracticeState.completed);
      expect(state.match?.status, ArenaMatchStatus.preparing);
    });

    test('ready gate requires the completed practice rep', () {
      var state = active();
      state = BattleStateMachine.apply(state, const ReadySubmitted(
        BattleMatch(
          id: 'match-1',
          exercise: ArenaExercise.pushUps,
          mode: ArenaMatchMode.casual,
          status: ArenaMatchStatus.preparing,
          players: [],
        ),
      ));
      expect(state.phase, BattlePhase.preparing);
      expect(state.readySubmitted, isFalse);

      state = BattleStateMachine.apply(state, const PracticeArmed());
      state = BattleStateMachine.apply(state, const PracticeRepCounted());
      state = BattleStateMachine.apply(
        state,
        ReadySubmitted(testMatch(viewerReady: true)),
      );
      expect(state.phase, BattlePhase.ready);
      expect(state.readySubmitted, isTrue);
    });

    test('countdown only starts from the server match status', () {
      var state = active();
      state = BattleStateMachine.apply(state, const PracticeArmed());
      state = BattleStateMachine.apply(state, const PracticeRepCounted());
      state = BattleStateMachine.apply(
        state,
        ReadySubmitted(testMatch(viewerReady: true)),
      );
      // Local readiness alone must not start the countdown.
      expect(state.phase, BattlePhase.ready);

      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.countdown,
          viewerReady: true,
          opponentReady: true,
          startsAt: DateTime.utc(2026, 9, 18, 12, 0, 5),
          serverNow: DateTime.utc(2026, 9, 18, 12),
        )),
      );
      expect(state.phase, BattlePhase.countdown);
    });

    test('ready failure keeps preparation and reports the reason', () {
      var state = active();
      state = BattleStateMachine.apply(state, const PracticeArmed());
      state = BattleStateMachine.apply(state, const PracticeRepCounted());
      state = BattleStateMachine.apply(
        state,
        const ReadyFailed(BattleFailure(BattleFailureKind.offline, 'offline')),
      );
      expect(state.phase, BattlePhase.preparing);
      expect(state.readySubmitted, isFalse);
      expect(state.notice, 'offline');
    });
  });

  group('countdown and live', () {
    test('CountdownElapsed moves a server countdown to live', () {
      var state = active();
      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.countdown,
          startsAt: DateTime.utc(2026, 9, 18, 12, 0, 5),
          serverNow: DateTime.utc(2026, 9, 18, 12, 0, 1),
        )),
      );
      expect(state.phase, BattlePhase.countdown);
      state = BattleStateMachine.apply(state, const CountdownElapsed());
      expect(state.phase, BattlePhase.live);
    });

    test('round end without a receipt never reaches result', () {
      final elapsed = testMatch(
        status: ArenaMatchStatus.live,
        startsAt: DateTime.utc(2026, 9, 18, 12),
        endsAt: DateTime.utc(2026, 9, 18, 12, 1),
        serverNow: DateTime.utc(2026, 9, 18, 12, 1, 1),
      );
      var state = live();
      state = BattleStateMachine.apply(state, MatchUpdated(elapsed));
      expect(state.phase, BattlePhase.live);
      expect(state.receipt, isNull);

      // Even a "finished" status without a receipt stays unresolved.
      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.finished,
          serverNow: DateTime.utc(2026, 9, 18, 12, 1, 2),
        )),
      );
      expect(state.phase, BattlePhase.live);
      expect(state.receipt, isNull);
    });

    test('server receipt is the only path to result', () {
      var state = live();
      final receipt = testReceipt();
      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.finished,
          receipt: receipt,
          viewerScore: 26,
          opponentScore: 23,
          serverNow: DateTime.utc(2026, 9, 18, 12, 1, 2),
        )),
      );
      expect(state.phase, BattlePhase.result);
      expect(state.receipt, receipt);
      expect(state.activeMatchId, isNull);
    });

    test('tracking loss pauses only this player and keeps the round phase '
        'recoverable', () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        const TrackingChanged(BattleCameraStatus.trackingLost),
      );
      expect(state.phase, BattlePhase.reconnecting);
      expect(state.connection, BattleConnection.selfTrackingLost);

      state = BattleStateMachine.apply(
        state,
        const TrackingChanged(BattleCameraStatus.tracking),
      );
      expect(state.phase, BattlePhase.live);
      expect(state.connection, BattleConnection.online);
    });

    test('opponent tracking loss and recovery follow the server snapshot',
        () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.live,
          opponentTracking: false,
          serverNow: DateTime.utc(2026, 9, 18, 12, 0, 2),
        )),
      );
      expect(state.phase, BattlePhase.reconnecting);
      expect(state.connection, BattleConnection.opponentReconnecting);

      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.live,
          opponentTracking: true,
          serverNow: DateTime.utc(2026, 9, 18, 12, 0, 3),
        )),
      );
      expect(state.phase, BattlePhase.live);
      expect(state.connection, BattleConnection.online);
    });

    test('two failures open the outage window; recovery clears it', () {
      var state = live();
      final at = DateTime.utc(2026, 9, 18, 12, 0, 2);
      state = BattleStateMachine.apply(
        state,
        ServerContactLost(
          const BattleFailure(BattleFailureKind.offline, 'offline'),
          at,
        ),
      );
      expect(state.phase, BattlePhase.live);
      state = BattleStateMachine.apply(
        state,
        ServerContactLost(
          const BattleFailure(BattleFailureKind.offline, 'offline'),
          at.add(const Duration(seconds: 1)),
        ),
      );
      expect(state.phase, BattlePhase.reconnecting);
      expect(state.connection, BattleConnection.serviceOutage);
      expect(state.reconnectStartedAt, at);

      state = BattleStateMachine.apply(state, const ReconnectWindowExpired());
      expect(state.reconnectExpired, isTrue);

      state = BattleStateMachine.apply(state, const ServerContactRestored());
      expect(state.phase, BattlePhase.live);
      expect(state.connection, BattleConnection.online);
      expect(state.reconnectExpired, isFalse);
    });

    test('shared outage resolves as no result and never as a winner', () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        MatchUpdated(testMatch(
          status: ArenaMatchStatus.noResult,
          reason: 'service_unavailable',
          serverNow: DateTime.utc(2026, 9, 18, 12, 1, 2),
        )),
      );
      expect(state.phase, BattlePhase.noResult);
      expect(state.noResultReason, 'service_unavailable');
      expect(state.receipt, isNull);
      expect(state.activeMatchId, isNull);
    });

    test('stale and duplicate snapshots never regress the live phase', () {
      var state = live();
      final stale = testMatch(
        status: ArenaMatchStatus.preparing,
        serverNow: DateTime.utc(2026, 9, 18, 11, 59),
      );
      state = BattleStateMachine.apply(state, MatchUpdated(stale));
      expect(state.phase, BattlePhase.live);
      expect(state.match?.status, ArenaMatchStatus.live);

      // Duplicate live update keeps the same authoritative values.
      final duplicate = testMatch(
        status: ArenaMatchStatus.live,
        startsAt: DateTime.utc(2026, 9, 18, 12),
        endsAt: DateTime.utc(2026, 9, 18, 12, 1),
        serverNow: DateTime.utc(2026, 9, 18, 12, 0, 1),
        viewerScore: 5,
      );
      state = BattleStateMachine.apply(state, MatchUpdated(duplicate));
      state = BattleStateMachine.apply(state, MatchUpdated(duplicate));
      expect(state.viewerPlayer?.score, 5);
      expect(state.phase, BattlePhase.live);
    });
  });

  group('exit', () {
    test('leave confirmation exits until the server replies', () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        const LeaveConfirmed(BattleExitReason.leftLive),
      );
      expect(state.phase, BattlePhase.exiting);

      state = BattleStateMachine.apply(
        state,
        const LeaveCompleted(BattleExitReason.leftLive, null),
      );
      expect(state.phase, BattlePhase.exited);
      expect(state.activeMatchId, isNull);
      expect(state.match, isNull);
    });

    test('leave that the server resolves with a receipt renders the result',
        () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        const LeaveConfirmed(BattleExitReason.leftLive),
      );
      final receipt = testReceipt();
      state = BattleStateMachine.apply(
        state,
        LeaveCompleted(
          BattleExitReason.leftLive,
          testMatch(
            status: ArenaMatchStatus.finished,
            receipt: receipt,
            serverNow: DateTime.utc(2026, 9, 18, 12, 1, 5),
          ),
        ),
      );
      expect(state.phase, BattlePhase.result);
      expect(state.receipt, receipt);
    });

    test('leave that the server resolves as no result shows no rating change',
        () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        const LeaveConfirmed(BattleExitReason.leftLive),
      );
      state = BattleStateMachine.apply(
        state,
        LeaveCompleted(
          BattleExitReason.leftLive,
          testMatch(
            status: ArenaMatchStatus.noResult,
            reason: 'left',
            serverNow: DateTime.utc(2026, 9, 18, 12, 1, 5),
          ),
        ),
      );
      expect(state.phase, BattlePhase.noResult);
      expect(state.noResultReason, 'left');
      expect(state.activeMatchId, isNull);
    });

    test('match unavailable returns home with no active match', () {
      var state = live();
      state = BattleStateMachine.apply(
        state,
        const MatchUnavailable(
          BattleFailure(BattleFailureKind.notFound, 'expired'),
        ),
      );
      expect(state.phase, BattlePhase.home);
      expect(state.match, isNull);
      expect(state.activeMatchId, isNull);
      expect(state.notice, 'expired');
    });

    test('exit to home clears the match, receipt and queue', () {
      var state = live();
      final receipt = testReceipt();
      state = BattleStateMachine.apply(
        state,
        ResultConfirmed(receipt),
      );
      state = BattleStateMachine.apply(state, const ExitToHome());
      expect(state.phase, BattlePhase.home);
      expect(state.receipt, isNull);
      expect(state.match, isNull);
      expect(state.queuePhase, BattleQueuePhase.idle);
    });
  });

  group('ranked queue', () {
    test('join, elapsed and alternative offer follow the fixed timings', () {
      var state = home();
      state = BattleStateMachine.apply(state, const QueueJoinStarted());
      expect(state.queuePhase, BattleQueuePhase.searching);
      state = BattleStateMachine.apply(
        state,
        const QueueElapsed(Duration(seconds: 15)),
      );
      state = BattleStateMachine.apply(state, const QueueAlternativeOffered());
      expect(state.queueExtended, isTrue);
      expect(state.queueElapsed, const Duration(seconds: 15));
    });

    test('timeout stops the search with explicit copy', () {
      var state = home();
      state = BattleStateMachine.apply(state, const QueueJoinStarted());
      state = BattleStateMachine.apply(state, const QueueTimedOut());
      expect(state.queuePhase, BattleQueuePhase.stopped);
      expect(state.notice, contains('60 seconds'));
      expect(state.match, isNull);
    });

    test('switching to a friend challenge cancels the seat', () {
      var state = home();
      state = BattleStateMachine.apply(state, const QueueJoinStarted());
      state = BattleStateMachine.apply(
        state,
        const QueueCancelled('cancelled for a friend challenge'),
      );
      expect(state.queuePhase, BattleQueuePhase.stopped);
      expect(state.notice, 'cancelled for a friend challenge');
    });

    test('queue match creates a ranked match in preparation only', () {
      var state = home();
      state = BattleStateMachine.apply(state, const QueueJoinStarted());
      state = BattleStateMachine.apply(
        state,
        QueueMatched(testMatch(mode: ArenaMatchMode.ranked)),
      );
      expect(state.phase, BattlePhase.preparing);
      expect(state.match?.mode, ArenaMatchMode.ranked);
      expect(state.origin, BattleMatchOrigin.rankedQueue);
    });
  });
}
