/// Pure battle state machine.
///
/// `apply` is total and side-effect free: every event returns a snapshot.
/// Guards encode the product rules:
///
/// * the ready gate requires a completed unscored practice rep;
/// * countdown/live are only entered from server match status;
/// * [BattlePhase.result] is reached only from a server receipt;
/// * tracking loss pauses counting but never declares an outcome;
/// * stale or duplicate match snapshots never regress state.
library;

import '../../domain/arena_types.dart';
import 'battle_events.dart';
import 'battle_failure.dart';
import 'battle_models.dart';
import 'battle_phase.dart';
import 'battle_snapshot.dart';

/// Applies battle events to immutable snapshots.
abstract final class BattleStateMachine {
  static BattleSnapshot apply(BattleSnapshot state, BattleEvent event) {
    switch (event) {
      case BattleUpdateRequired():
        return state.copyWith(
          phase: BattlePhase.updateRequired,
          match: null,
          activeMatchId: null,
          receipt: null,
          readySubmitted: false,
          practice: PracticeState.notStarted,
          queuePhase: BattleQueuePhase.idle,
          queue: null,
          connection: BattleConnection.online,
          reconnectStartedAt: null,
          reconnectExpired: false,
          notice:
              'Update Fault on both phones with the latest owner-test APK. '
              'This build cannot continue the battle. Check history after updating for the server outcome.',
          noticeKind: BattleNoticeKind.warning,
        );
      case ViewerChanged(:final viewer):
        return _onViewerChanged(state, viewer);
      case HomeLoadStarted():
        return state.copyWith(
          phase: _homePhase(state),
          inboxStatus: BattleLoadStatus.loading,
          notice: null,
          noticeKind: null,
        );
      case InboxLoadStarted():
        return state.copyWith(
          inboxStatus: BattleLoadStatus.loading,
          inboxMessage: null,
        );
      case InboxLoaded(:final inbox):
        return _onInboxLoaded(state, inbox);
      case InboxLoadFailed(:final failure):
        return _onInboxFailed(state, failure.kind, failure.message);
      case InboxBlocked(:final message):
        return state.copyWith(
          inboxStatus: BattleLoadStatus.blocked,
          inboxMessage: message,
          phase: BattlePhase.home,
        );
      case ChallengePending(:final challenge):
        return state.copyWith(
          pendingChallenge: challenge,
          challengeAwaitingSignIn: state.viewer == null,
          notice: null,
          noticeKind: null,
        );
      case ChallengeCleared():
        return state.copyWith(
          pendingChallenge: null,
          challengeAwaitingSignIn: false,
        );
      case ChallengeAcceptStarted():
        return state.copyWith(
          phase: BattlePhase.resolving,
          notice: 'Creating the match',
          noticeKind: BattleNoticeKind.info,
        );
      case ChallengeAcceptFailed(:final failure):
        return state.copyWith(
          phase: BattlePhase.home,
          notice: failure.message,
          noticeKind: failure.kind == BattleFailureKind.blocked
              ? BattleNoticeKind.warning
              : BattleNoticeKind.danger,
        );
      case MatchCreated(:final match, :final origin):
        return _onMatchCreated(state, match, origin);
      case QueueJoinStarted():
        return state.copyWith(
          queuePhase: BattleQueuePhase.searching,
          queue: null,
          queueExtended: false,
          queueElapsed: Duration.zero,
          queueOffline: false,
          notice: null,
          noticeKind: null,
        );
      case QueueUpdated(:final queue, :final elapsed):
        return _onQueueUpdated(state, queue, elapsed);
      case QueueMatched(:final match):
        return _onMatchCreated(state, match, BattleMatchOrigin.rankedQueue);
      case QueueElapsed(:final elapsed):
        return state.copyWith(queueElapsed: elapsed);
      case QueueAlternativeOffered():
        if (state.queuePhase != BattleQueuePhase.searching) {
          return state;
        }
        return state.copyWith(queueExtended: true);
      case QueueTimedOut():
        if (state.queuePhase != BattleQueuePhase.searching &&
            state.queuePhase != BattleQueuePhase.extended) {
          return state;
        }
        return state.copyWith(
          queuePhase: BattleQueuePhase.stopped,
          queue: null,
          queueOffline: false,
          notice:
              'No opponent found in 60 seconds. The queue stopped. '
              'Nothing was created and no rating changed.',
          noticeKind: BattleNoticeKind.warning,
        );
      case QueueCancelled(:final reason):
        if (state.queuePhase == BattleQueuePhase.idle) {
          return state;
        }
        return state.copyWith(
          queuePhase: BattleQueuePhase.stopped,
          queue: null,
          queueOffline: false,
          notice: reason,
          noticeKind: BattleNoticeKind.info,
        );
      case QueueSearchFailed(:final failure):
        return state.copyWith(
          queuePhase: BattleQueuePhase.idle,
          queue: null,
          queueOffline: false,
          notice: failure.message,
          noticeKind: BattleNoticeKind.danger,
        );
      case QueueSeatClosed():
        if (state.queuePhase != BattleQueuePhase.searching &&
            state.queuePhase != BattleQueuePhase.extended) {
          return state;
        }
        return state.copyWith(
          queuePhase: BattleQueuePhase.stopped,
          queue: null,
          queueOffline: false,
          notice:
              'The queue seat is no longer active. Nothing was created '
              'and no rating changed. Start a new search to keep looking.',
          noticeKind: BattleNoticeKind.info,
        );
      case QueueContactLost():
        if ((state.queuePhase != BattleQueuePhase.searching &&
                state.queuePhase != BattleQueuePhase.extended) ||
            state.queueOffline) {
          return state;
        }
        return state.copyWith(queueOffline: true);
      case QueueContactRestored():
        if (!state.queueOffline) {
          return state;
        }
        return state.copyWith(queueOffline: false);
      case MatchUpdated(:final match):
        return _applyMatch(state, match);
      case MatchUnavailable(:final failure):
        return state.copyWith(
          phase: BattlePhase.home,
          match: null,
          activeMatchId: null,
          origin: BattleMatchOrigin.none,
          readySubmitted: false,
          practice: PracticeState.notStarted,
          connection: BattleConnection.online,
          reconnectStartedAt: null,
          reconnectExpired: false,
          cameraStatus: BattleCameraStatus.unknown,
          notice: failure.message,
          noticeKind: BattleNoticeKind.warning,
        );
      case RequestResolved(:final requestId, :final kind):
        return _onRequestResolved(state, requestId, kind);
      case InboxOpened():
        return state.copyWith(phase: BattlePhase.inbox);
      case InboxClosed():
        return state.copyWith(
          phase: state.phase == BattlePhase.inbox
              ? BattlePhase.home
              : state.phase,
        );
      case CountdownElapsed():
        if (state.phase != BattlePhase.countdown) {
          return state;
        }
        return state.copyWith(phase: BattlePhase.live);
      case PracticeArmed():
        if (state.phase != BattlePhase.preparing ||
            state.practice != PracticeState.notStarted) {
          return state;
        }
        return state.copyWith(practice: PracticeState.counting);
      case PracticeRepCounted():
        if (state.phase != BattlePhase.preparing ||
            state.practice == PracticeState.completed) {
          return state;
        }
        return state.copyWith(practice: PracticeState.completed);
      case ReadySubmitted(:final match):
        if (state.phase != BattlePhase.preparing ||
            state.practice != PracticeState.completed) {
          return state;
        }
        return _applyMatch(
          state.copyWith(readySubmitted: true, phase: BattlePhase.ready),
          match,
        );
      case ReadyFailed(:final failure):
        return state.copyWith(
          readySubmitted: false,
          notice: failure.message,
          noticeKind: BattleNoticeKind.danger,
        );
      case TrackingChanged(:final status, :final message):
        return _onTrackingChanged(state, status, message);
      case OpponentTrackingChanged(:final tracking):
        return _onOpponentTracking(state, tracking);
      case ServerContactLost(at: final at):
        return _onServerContactLost(state, at);
      case ServerContactRestored():
        return _onServerContactRestored(state);
      case ReconnectWindowExpired():
        if (state.phase != BattlePhase.reconnecting) {
          return state;
        }
        return state.copyWith(reconnectExpired: true);
      case ResultConfirmed(:final receipt):
        return state.copyWith(
          phase: BattlePhase.result,
          receipt: receipt,
          activeMatchId: null,
          connection: BattleConnection.online,
          reconnectStartedAt: null,
          reconnectExpired: false,
          queuePhase: BattleQueuePhase.matched,
        );
      case NoResultConfirmed(:final reason):
        return state.copyWith(
          phase: BattlePhase.noResult,
          noResultReason:
              reason ??
              'The battle service could not confirm a score, so no result '
                  'and no rating change were recorded.',
          match: null,
          activeMatchId: null,
          connection: BattleConnection.online,
          reconnectStartedAt: null,
          reconnectExpired: false,
        );
      case LeaveConfirmed(:final reason):
        return state.copyWith(
          phase: BattlePhase.exiting,
          exitReason: reason,
          notice: 'Leaving the match',
          noticeKind: BattleNoticeKind.info,
        );
      case LeaveCompleted(:final reason, :final match):
        return _onLeaveCompleted(state, reason, match);
      case ExitToHome():
        return state.copyWith(
          phase: BattlePhase.home,
          match: null,
          receipt: null,
          noResultReason: null,
          readySubmitted: false,
          practice: PracticeState.notStarted,
          origin: BattleMatchOrigin.none,
          connection: BattleConnection.online,
          cameraStatus: BattleCameraStatus.unknown,
          cameraMessage: null,
          queue: null,
          queuePhase: BattleQueuePhase.idle,
          queueExtended: false,
          queueElapsed: Duration.zero,
          queueOffline: false,
          reconnectStartedAt: null,
          reconnectExpired: false,
          activeMatchId: null,
          exitReason: state.exitReason,
          notice: state.phase == BattlePhase.updateRequired
              ? state.notice
              : null,
          noticeKind: state.phase == BattlePhase.updateRequired
              ? state.noticeKind
              : null,
        );
      case NoticeRaised(:final kind, :final message):
        return state.copyWith(notice: message, noticeKind: kind);
      case NoticeCleared():
        return state.copyWith(notice: null, noticeKind: null);
      case BattleTick():
        return state.copyWith(tick: state.tick + 1);
    }
  }

  // ---------------------------------------------------------------- inbox --

  static BattleSnapshot _onViewerChanged(
    BattleSnapshot state,
    ArenaProfile? viewer,
  ) {
    if (viewer == null) {
      return state.copyWith(
        viewer: null,
        inboxStatus: BattleLoadStatus.signedOut,
        inboxMessage: 'Sign in to send or accept challenges.',
        phase: state.isMatchActive ? BattlePhase.home : state.phase,
        match: state.isMatchActive ? null : state.match,
        activeMatchId: state.isMatchActive ? null : state.activeMatchId,
        challengeAwaitingSignIn: state.pendingChallenge != null,
        queue: null,
        queuePhase: BattleQueuePhase.idle,
        viewerBusy: false,
        readySubmitted: false,
        practice: PracticeState.notStarted,
        receipt: state.phase == BattlePhase.result ? state.receipt : null,
      );
    }
    return state.copyWith(
      viewer: viewer,
      viewerBusy: state.viewerBusy,
      challengeAwaitingSignIn: false,
      inboxStatus: state.inboxStatus == BattleLoadStatus.signedOut
          ? BattleLoadStatus.initial
          : state.inboxStatus,
      inboxMessage: state.inboxStatus == BattleLoadStatus.signedOut
          ? null
          : state.inboxMessage,
    );
  }

  static BattleSnapshot _onInboxLoaded(
    BattleSnapshot state,
    BattleInbox inbox,
  ) {
    final status = inbox.requests.isEmpty
        ? BattleLoadStatus.empty
        : BattleLoadStatus.ready;
    return state.copyWith(
      requests: inbox.requests,
      viewerBusy: inbox.viewerBusy,
      inboxStatus: status,
      inboxMessage: null,
      phase: _homePhase(state),
      activeMatchId: inbox.activeMatchId ?? state.activeMatchId,
    );
  }

  /// Keeps an active or terminal match phase while the inbox reloads; only
  /// idle surfaces fall back to [BattlePhase.home].
  static BattlePhase _homePhase(BattleSnapshot state) {
    if (state.phase == BattlePhase.inbox) {
      return BattlePhase.inbox;
    }
    if (state.isMatchActive ||
        state.phase == BattlePhase.result ||
        state.phase == BattlePhase.noResult ||
        state.phase == BattlePhase.exiting ||
        state.phase == BattlePhase.resolving) {
      return state.phase;
    }
    return BattlePhase.home;
  }

  static BattleSnapshot _onInboxFailed(
    BattleSnapshot state,
    BattleFailureKind kind,
    String message,
  ) {
    final status = switch (kind) {
      BattleFailureKind.offline => BattleLoadStatus.offline,
      BattleFailureKind.unauthorized => BattleLoadStatus.signedOut,
      BattleFailureKind.blocked => BattleLoadStatus.blocked,
      BattleFailureKind.unconfigured => BattleLoadStatus.unconfigured,
      _ => BattleLoadStatus.error,
    };
    return state.copyWith(
      inboxStatus: status,
      inboxMessage: message,
      phase: _homePhase(state),
    );
  }

  static BattleSnapshot _onRequestResolved(
    BattleSnapshot state,
    String requestId,
    BattleRequestKind kind,
  ) {
    final next = <BattleRequest>[];
    for (final request in state.requests) {
      if (request.id != requestId) {
        next.add(request);
        continue;
      }
      if (kind == BattleRequestKind.cancelled) {
        continue;
      }
      next.add(request.copyWith(kind: kind));
    }
    var result = state.copyWith(
      requests: next,
      inboxStatus: next.isEmpty ? BattleLoadStatus.empty : state.inboxStatus,
    );
    if (kind == BattleRequestKind.cancelled) {
      result = result.copyWith(
        notice: 'Request declined. No match was created.',
        noticeKind: BattleNoticeKind.info,
      );
    }
    return result;
  }

  // ---------------------------------------------------------------- match --

  static BattleSnapshot _onMatchCreated(
    BattleSnapshot state,
    BattleMatch match,
    BattleMatchOrigin origin,
  ) {
    return state.copyWith(
      phase: BattlePhase.preparing,
      match: match,
      origin: origin,
      practice: PracticeState.notStarted,
      readySubmitted: false,
      connection: BattleConnection.online,
      reconnectStartedAt: null,
      reconnectExpired: false,
      receipt: null,
      noResultReason: null,
      activeMatchId: match.id,
      queue: state.queue,
      queueOffline: false,
      queuePhase:
          state.queuePhase == BattleQueuePhase.searching ||
              state.queuePhase == BattleQueuePhase.extended
          ? BattleQueuePhase.matched
          : state.queuePhase,
      pendingChallenge: null,
      challengeAwaitingSignIn: false,
      viewerBusy: true,
      notice: null,
      noticeKind: null,
      exitReason: BattleExitReason.none,
    );
  }

  /// Ordering of terminal/advancing match statuses for staleness checks.
  static int _statusRank(ArenaMatchStatus status) => switch (status) {
    ArenaMatchStatus.preparing => 0,
    ArenaMatchStatus.countdown => 1,
    ArenaMatchStatus.live => 2,
    ArenaMatchStatus.finished => 3,
    ArenaMatchStatus.noResult => 3,
  };

  static bool _isStale(BattleMatch? current, BattleMatch incoming) {
    if (current == null || current.id != incoming.id) {
      return false;
    }
    final currentAt = current.serverNow;
    final incomingAt = incoming.serverNow;
    if (currentAt != null && incomingAt != null) {
      if (incomingAt.isBefore(currentAt)) {
        return true;
      }
      if (incomingAt.isAfter(currentAt)) {
        return false;
      }
    }
    return _statusRank(incoming.status) < _statusRank(current.status);
  }

  static BattleSnapshot _applyMatch(
    BattleSnapshot state,
    BattleMatch incoming, {
    BattleMatchOrigin? origin,
  }) {
    if (_isStale(state.match, incoming)) {
      return state;
    }
    var next = state.copyWith(
      match: incoming,
      activeMatchId: incoming.id,
      origin: origin ?? state.origin,
    );

    final receipt = incoming.receipt;
    if (receipt != null && incoming.status == ArenaMatchStatus.finished) {
      return next.copyWith(
        phase: BattlePhase.result,
        receipt: receipt,
        activeMatchId: null,
        connection: BattleConnection.online,
        reconnectStartedAt: null,
        reconnectExpired: false,
        readySubmitted: true,
      );
    }
    if (incoming.status == ArenaMatchStatus.noResult) {
      return next.copyWith(
        phase: BattlePhase.noResult,
        noResultReason:
            incoming.reason ??
            'The match ended without a confirmed score. No rating changed.',
        activeMatchId: null,
        connection: BattleConnection.online,
        reconnectStartedAt: null,
        reconnectExpired: false,
      );
    }
    if (state.phase == BattlePhase.exiting) {
      return next;
    }

    // Opponent tracking is derived from the authoritative snapshot.
    final opponent = incoming.opponentFor(state.viewerId);
    if (opponent != null &&
        state.connection != BattleConnection.serviceOutage &&
        state.connection != BattleConnection.selfTrackingLost) {
      if (!opponent.tracking && incoming.status == ArenaMatchStatus.live) {
        next = next.copyWith(
          connection: BattleConnection.opponentReconnecting,
          phase: BattlePhase.reconnecting,
        );
      } else if (opponent.tracking &&
          state.connection == BattleConnection.opponentReconnecting) {
        next = next.copyWith(
          connection: BattleConnection.online,
          phase: incoming.status == ArenaMatchStatus.live
              ? BattlePhase.live
              : next.phase,
        );
      }
    }

    switch (incoming.status) {
      case ArenaMatchStatus.preparing:
        if (next.phase == BattlePhase.loading ||
            next.phase == BattlePhase.home ||
            next.phase == BattlePhase.resolving) {
          next = next.copyWith(phase: BattlePhase.preparing);
        }
      case ArenaMatchStatus.countdown:
        if (next.phase != BattlePhase.live &&
            next.phase != BattlePhase.reconnecting) {
          next = next.copyWith(
            phase: BattlePhase.countdown,
            connection: BattleConnection.online,
            reconnectStartedAt: null,
            reconnectExpired: false,
          );
        }
      case ArenaMatchStatus.live:
        if (next.phase != BattlePhase.reconnecting) {
          next = next.copyWith(
            phase: BattlePhase.live,
            connection: BattleConnection.online,
            reconnectStartedAt: null,
            reconnectExpired: false,
          );
        }
      case ArenaMatchStatus.finished:
      case ArenaMatchStatus.noResult:
        break;
    }
    return next;
  }

  static BattleSnapshot _onQueueUpdated(
    BattleSnapshot state,
    BattleQueueState queue,
    Duration elapsed,
  ) {
    if (queue.matchId != null) {
      // The controller fetches the match and dispatches MatchCreated; here
      // the queue seat is simply done.
      return state.copyWith(
        queue: queue,
        queueElapsed: elapsed,
        queuePhase: BattleQueuePhase.matched,
      );
    }
    return state.copyWith(
      queue: queue,
      queueElapsed: elapsed,
      queuePhase: state.queuePhase == BattleQueuePhase.extended
          ? BattleQueuePhase.extended
          : BattleQueuePhase.searching,
    );
  }

  // ------------------------------------------------------------- tracking --

  static BattleSnapshot _onTrackingChanged(
    BattleSnapshot state,
    BattleCameraStatus status,
    String? message,
  ) {
    var next = state.copyWith(cameraStatus: status, cameraMessage: message);
    final inRound =
        state.phase == BattlePhase.live ||
        state.phase == BattlePhase.reconnecting;
    if (inRound) {
      if (status == BattleCameraStatus.trackingLost) {
        return next.copyWith(
          connection: BattleConnection.selfTrackingLost,
          phase: BattlePhase.reconnecting,
        );
      }
      if (status == BattleCameraStatus.tracking) {
        final opponent =
            state.match?.opponentFor(state.viewerId)?.tracking ?? true;
        return next.copyWith(
          connection: opponent
              ? BattleConnection.online
              : BattleConnection.opponentReconnecting,
          phase: opponent ? BattlePhase.live : BattlePhase.reconnecting,
        );
      }
    }
    return next;
  }

  static BattleSnapshot _onOpponentTracking(
    BattleSnapshot state,
    bool tracking,
  ) {
    if (state.phase != BattlePhase.live &&
        state.phase != BattlePhase.reconnecting) {
      return state;
    }
    if (!tracking) {
      return state.copyWith(
        connection: BattleConnection.opponentReconnecting,
        phase: BattlePhase.reconnecting,
      );
    }
    if (state.connection == BattleConnection.opponentReconnecting ||
        state.connection == BattleConnection.opponentLost) {
      return state.copyWith(
        connection: BattleConnection.online,
        phase: BattlePhase.live,
      );
    }
    return state;
  }

  static BattleSnapshot _onServerContactLost(
    BattleSnapshot state,
    DateTime at,
  ) {
    final failures = state.consecutiveFailures + 1;
    var next = state.copyWith(
      consecutiveFailures: failures,
      reconnectStartedAt: state.reconnectStartedAt ?? at,
    );
    final inRound =
        state.phase == BattlePhase.live ||
        state.phase == BattlePhase.reconnecting;
    if (inRound && failures >= 2) {
      next = next.copyWith(
        connection: BattleConnection.serviceOutage,
        phase: BattlePhase.reconnecting,
      );
    }
    return next;
  }

  static BattleSnapshot _onServerContactRestored(BattleSnapshot state) {
    if (state.phase != BattlePhase.reconnecting ||
        state.connection != BattleConnection.serviceOutage) {
      return state.copyWith(consecutiveFailures: 0);
    }
    final status = state.match?.status;
    final recovered = status == ArenaMatchStatus.live
        ? BattlePhase.live
        : state.phase;
    return state.copyWith(
      consecutiveFailures: 0,
      connection: BattleConnection.online,
      phase: recovered,
      reconnectStartedAt: null,
      reconnectExpired: false,
    );
  }

  // ---------------------------------------------------------------- exit --

  static BattleSnapshot _onLeaveCompleted(
    BattleSnapshot state,
    BattleExitReason reason,
    BattleMatch? match,
  ) {
    if (match != null) {
      final withMatch = state.copyWith(match: match, activeMatchId: match.id);
      if (match.receipt != null && match.status == ArenaMatchStatus.finished) {
        return _applyMatch(
          withMatch,
          match,
        ).copyWith(exitReason: reason, phase: BattlePhase.result);
      }
      if (match.status == ArenaMatchStatus.noResult) {
        return withMatch.copyWith(
          phase: BattlePhase.noResult,
          noResultReason:
              match.reason ??
              'The match ended without a confirmed score. No rating changed.',
          activeMatchId: null,
        );
      }
    }
    return state.copyWith(
      phase: BattlePhase.exited,
      match: null,
      receipt: null,
      noResultReason: null,
      readySubmitted: false,
      practice: PracticeState.notStarted,
      origin: BattleMatchOrigin.none,
      activeMatchId: null,
      connection: BattleConnection.online,
      reconnectStartedAt: null,
      reconnectExpired: false,
      exitReason: reason,
      notice:
          'You left the match. The server keeps the final outcome in '
          'history.',
      noticeKind: BattleNoticeKind.info,
    );
  }
}
