/// Every input the battle state machine accepts.
///
/// The controller converts backend replies, camera updates, clock ticks and
/// user commands into these events; the reducer is the only place phase
/// transitions happen. Nothing in the UI mutates state directly.
library;

import '../../domain/arena_types.dart';
import 'battle_failure.dart';
import 'battle_models.dart';
import 'battle_phase.dart';

/// Base type for all battle events.
sealed class BattleEvent {
  const BattleEvent();
}

class BattleUpdateRequired extends BattleEvent {
  const BattleUpdateRequired();
}

/// Account state changed (sign-in, sign-out, profile refresh).
class ViewerChanged extends BattleEvent {
  const ViewerChanged(this.viewer);

  final ArenaProfile? viewer;
}

/// The Battle tab started loading (or retried) its inbox.
class HomeLoadStarted extends BattleEvent {
  const HomeLoadStarted();
}

/// A background/stay-in-place inbox reload started.
class InboxLoadStarted extends BattleEvent {
  const InboxLoadStarted();
}

/// The inbox action answered.
class InboxLoaded extends BattleEvent {
  const InboxLoaded(this.inbox);

  final BattleInbox inbox;
}

/// The inbox action failed with a typed failure.
class InboxLoadFailed extends BattleEvent {
  const InboxLoadFailed(this.failure);

  final BattleFailure failure;
}

/// The viewer is blocked from challenging the request sender.
class InboxBlocked extends BattleEvent {
  const InboxBlocked(this.blocker, this.message);

  final ArenaProfile? blocker;
  final String message;
}

/// A challenge link or code resolved and is waiting for sign-in/accept.
class ChallengePending extends BattleEvent {
  const ChallengePending(this.challenge);

  final ChallengeContext challenge;
}

/// The pending challenge was cleared (cancelled or consumed).
class ChallengeCleared extends BattleEvent {
  const ChallengeCleared();
}

/// A link/request accept is in flight; the server owns match creation.
class ChallengeAcceptStarted extends BattleEvent {
  const ChallengeAcceptStarted();
}

/// A link/request accept failed; no match exists.
class ChallengeAcceptFailed extends BattleEvent {
  const ChallengeAcceptFailed(this.failure);

  final BattleFailure failure;
}

/// The server created a match (link accept, request accept or matchmaking).
class MatchCreated extends BattleEvent {
  const MatchCreated(this.match, this.origin);

  final BattleMatch match;
  final BattleMatchOrigin origin;
}

/// The player started or retried the ranked search.
class QueueJoinStarted extends BattleEvent {
  const QueueJoinStarted();
}

/// The ranked queue seat was created or polled.
class QueueUpdated extends BattleEvent {
  const QueueUpdated(this.queue, {this.elapsed = Duration.zero});

  final BattleQueueState queue;

  /// Time this seat has been waiting, measured against the server clock.
  final Duration elapsed;
}

/// The queue search clock ticked; no queue reply arrived yet.
class QueueElapsed extends BattleEvent {
  const QueueElapsed(this.elapsed);

  final Duration elapsed;
}

/// The queue paired the viewer; the server created a ranked match.
class QueueMatched extends BattleEvent {
  const QueueMatched(this.match);

  final BattleMatch match;
}

/// 15 seconds elapsed: offer the friend challenge as an alternative.
class QueueAlternativeOffered extends BattleEvent {
  const QueueAlternativeOffered();
}

/// 60 seconds elapsed: stop the search; the queue seat is cancelled.
class QueueTimedOut extends BattleEvent {
  const QueueTimedOut();
}

/// The player stopped the search or switched to a friend challenge.
class QueueCancelled extends BattleEvent {
  const QueueCancelled(this.reason);

  final String reason;
}

/// The queue action failed.
class QueueSearchFailed extends BattleEvent {
  const QueueSearchFailed(this.failure);

  final BattleFailure failure;
}

/// The server reported that the queue seat no longer exists (expired or
/// released). Nothing was created and no rating changed.
class QueueSeatClosed extends BattleEvent {
  const QueueSeatClosed();
}

/// The queue poll could not reach the arena. The local timer keeps running;
/// no opponent is ever inferred locally.
class QueueContactLost extends BattleEvent {
  const QueueContactLost();
}

/// The queue poll reached the arena again.
class QueueContactRestored extends BattleEvent {
  const QueueContactRestored();
}

/// The server sent a newer match snapshot. Stale snapshots are ignored by
/// the reducer, so duplicate polling cannot regress state.
class MatchUpdated extends BattleEvent {
  const MatchUpdated(this.match);

  final BattleMatch match;
}

/// The match is no longer available to this viewer (expired/cancelled).
class MatchUnavailable extends BattleEvent {
  const MatchUnavailable(this.failure);

  final BattleFailure failure;
}

/// A request card was resolved locally after the server answered.
class RequestResolved extends BattleEvent {
  const RequestResolved(this.requestId, this.kind);

  final String requestId;
  final BattleRequestKind kind;
}

/// The request inbox screen was opened/closed.
class InboxOpened extends BattleEvent {
  const InboxOpened();
}

/// The request inbox screen was closed.
class InboxClosed extends BattleEvent {
  const InboxClosed();
}

/// The server countdown reached zero; the round is live. The shared clock
/// still comes from server timestamps, never from a local winner.
class CountdownElapsed extends BattleEvent {
  const CountdownElapsed();
}

/// The single unscored practice rep was armed on the camera.
class PracticeArmed extends BattleEvent {
  const PracticeArmed();
}

/// The single unscored practice rep landed.
class PracticeRepCounted extends BattleEvent {
  const PracticeRepCounted();
}

/// The player submitted the ready gate; `match` is the server reply.
class ReadySubmitted extends BattleEvent {
  const ReadySubmitted(this.match);

  final BattleMatch match;
}

/// The ready call failed; readiness is not submitted.
class ReadyFailed extends BattleEvent {
  const ReadyFailed(this.failure);

  final BattleFailure failure;
}

/// Camera tracking changed (applies to preparation and live).
class TrackingChanged extends BattleEvent {
  const TrackingChanged(this.status, {this.message});

  final BattleCameraStatus status;
  final String? message;
}

/// The server reported the opponent's tracking/heartbeat state.
class OpponentTrackingChanged extends BattleEvent {
  const OpponentTrackingChanged({required this.tracking});

  final bool tracking;
}

/// Server contact was lost while a round is active.
class ServerContactLost extends BattleEvent {
  const ServerContactLost(this.failure, this.at);

  final BattleFailure failure;

  /// Local clock time of the first lost contact; starts the 10-second window.
  final DateTime at;
}

/// Server contact resumed.
class ServerContactRestored extends BattleEvent {
  const ServerContactRestored();
}

/// The ten-second single-player recovery window expired. The server still
/// owns the outcome; the UI only stops promising a local recovery.
class ReconnectWindowExpired extends BattleEvent {
  const ReconnectWindowExpired();
}

/// A server-confirmed receipt arrived. This is the only way to reach
/// [BattlePhase.result].
class ResultConfirmed extends BattleEvent {
  const ResultConfirmed(this.receipt);

  final ResultReceipt receipt;
}

/// The server closed the match with no result. Rating never changes.
class NoResultConfirmed extends BattleEvent {
  const NoResultConfirmed(this.reason);

  final String? reason;
}

/// The player confirmed leaving; the controller reports it to the server.
class LeaveConfirmed extends BattleEvent {
  const LeaveConfirmed(this.reason);

  final BattleExitReason reason;
}

/// The leave call finished; `match` is the server reply when it answered.
class LeaveCompleted extends BattleEvent {
  const LeaveCompleted(this.reason, this.match);

  final BattleExitReason reason;
  final BattleMatch? match;
}

/// Close the flow and return to Battle.
class ExitToHome extends BattleEvent {
  const ExitToHome();
}

/// A factual notice for the Battle surface.
class NoticeRaised extends BattleEvent {
  const NoticeRaised(this.kind, this.message);

  final BattleNoticeKind kind;
  final String message;
}

/// Clear the current notice.
class NoticeCleared extends BattleEvent {
  const NoticeCleared();
}

/// The clock ticked (1 Hz while a match is active, queue search, or home).
class BattleTick extends BattleEvent {
  const BattleTick();
}
