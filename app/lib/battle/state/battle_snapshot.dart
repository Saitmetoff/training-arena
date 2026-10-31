/// The complete immutable battle snapshot.
///
/// One object carries every screen the battle feature can render: the home
/// inbox, the preparation/ready/countdown/live flow, reconnect banners and
/// the server-confirmed result. The controller owns exactly one snapshot and
/// the reducer replaces it atomically.
library;

import '../../domain/arena_types.dart';
import 'battle_models.dart';
import 'battle_phase.dart';

const Object _unset = Object();

/// Battle feature state. All fields are server-derived or locally held
/// intentions; no field ever holds a locally inferred winner.
class BattleSnapshot {
  const BattleSnapshot({
    this.phase = BattlePhase.loading,
    this.previewFixtures = false,
    this.viewer,
    this.inboxStatus = BattleLoadStatus.initial,
    this.inboxMessage,
    this.requests = const <BattleRequest>[],
    this.viewerBusy = false,
    this.pendingChallenge,
    this.challengeAwaitingSignIn = false,
    this.match,
    this.origin = BattleMatchOrigin.none,
    this.practice = PracticeState.notStarted,
    this.readySubmitted = false,
    this.connection = BattleConnection.online,
    this.cameraStatus = BattleCameraStatus.unknown,
    this.cameraMessage,
    this.queuePhase = BattleQueuePhase.idle,
    this.queue,
    this.queueExtended = false,
    this.queueElapsed = Duration.zero,
    this.queueOffline = false,
    this.reconnectStartedAt,
    this.reconnectExpired = false,
    this.consecutiveFailures = 0,
    this.receipt,
    this.noResultReason,
    this.exitReason = BattleExitReason.none,
    this.notice,
    this.noticeKind,
    this.activeMatchId,
    this.tick = 0,
  });

  // ------------------------------------------------------------- identity --
  final BattlePhase phase;

  /// True when deterministic preview fixtures are driving this snapshot;
  /// the UI labels it and fixtures never produce receipts.
  final bool previewFixtures;

  /// Signed-in profile from the account feature (task 06). Null until then.
  final ArenaProfile? viewer;

  // ---------------------------------------------------------------- inbox --
  final BattleLoadStatus inboxStatus;

  /// Factual explanation for offline/error/unconfigured/blocked states.
  final String? inboxMessage;

  final List<BattleRequest> requests;

  /// Backend hint that the viewer is already in another battle.
  final bool viewerBusy;

  /// A challenge link/code waiting for sign-in or acceptance. Survives
  /// sign-in so a returning user lands back on the same challenge.
  final ChallengeContext? pendingChallenge;

  /// True while the pending challenge waits for a signed-in viewer.
  final bool challengeAwaitingSignIn;

  // ------------------------------------------------------------- match --
  final BattleMatch? match;

  /// How the active match was created.
  final BattleMatchOrigin origin;

  final PracticeState practice;

  /// True once this player submitted their ready check.
  final bool readySubmitted;

  // ----------------------------------------------------- connection/health --
  final BattleConnection connection;

  final BattleCameraStatus cameraStatus;
  final String? cameraMessage;

  // -------------------------------------------------------------- queue --
  final BattleQueuePhase queuePhase;
  final BattleQueueState? queue;
  final bool queueExtended;
  final Duration queueElapsed;

  /// True while the queue poll cannot reach the arena. The seat and the
  /// local 60-second window stay in place; nothing is inferred offline.
  final bool queueOffline;

  // -------------------------------------------------- reconnection window --
  final DateTime? reconnectStartedAt;
  final bool reconnectExpired;
  final int consecutiveFailures;

  // ------------------------------------------------------------- result --
  final ResultReceipt? receipt;
  final String? noResultReason;

  // --------------------------------------------------------------- exit --
  final BattleExitReason exitReason;

  // -------------------------------------------------------------- notice --
  final String? notice;
  final BattleNoticeKind? noticeKind;

  /// Server match id kept for lifecycle restoration. Cleared only when a
  /// terminal receipt/no-result/exit is confirmed.
  final String? activeMatchId;

  /// Monotonic tick counter so a 1 Hz tick still notifies listeners.
  final int tick;

  // ------------------------------------------------------------ getters --

  String? get viewerId => viewer?.id;

  /// First live pending request; the Battle tab renders it before anything
  /// else.
  BattleRequest? get incomingRequest {
    for (final request in requests) {
      if (!request.isOutgoing && request.kind == BattleRequestKind.pending) {
        return request;
      }
    }
    return null;
  }

  BattleMatchPlayer? get viewerPlayer => match?.playerFor(viewerId);

  BattleMatchPlayer? get opponentPlayer => match?.opponentFor(viewerId);

  bool get opponentReady => opponentPlayer?.ready ?? false;

  bool get opponentTracking => opponentPlayer?.tracking ?? false;

  ArenaProfile? get opponent {
    final current = match;
    if (current == null) {
      return null;
    }
    return current.opponentFor(viewerId)?.profile;
  }

  bool get signedIn => viewer != null;

  bool get isMatchActive {
    final current = match;
    if (current == null) {
      return false;
    }
    return phase == BattlePhase.preparing ||
        phase == BattlePhase.ready ||
        phase == BattlePhase.countdown ||
        phase == BattlePhase.live ||
        phase == BattlePhase.reconnecting;
  }

  bool get canSubmitReady =>
      phase == BattlePhase.preparing &&
      practice == PracticeState.completed &&
      !readySubmitted &&
      viewer != null;

  PracticeState get practiceState => practice;

  BattleSnapshot copyWith({
    BattlePhase? phase,
    bool? previewFixtures,
    Object? viewer = _unset,
    BattleLoadStatus? inboxStatus,
    Object? inboxMessage = _unset,
    List<BattleRequest>? requests,
    bool? viewerBusy,
    Object? pendingChallenge = _unset,
    bool? challengeAwaitingSignIn,
    Object? match = _unset,
    BattleMatchOrigin? origin,
    PracticeState? practice,
    bool? readySubmitted,
    BattleConnection? connection,
    BattleCameraStatus? cameraStatus,
    Object? cameraMessage = _unset,
    BattleQueuePhase? queuePhase,
    Object? queue = _unset,
    bool? queueExtended,
    Duration? queueElapsed,
    bool? queueOffline,
    Object? reconnectStartedAt = _unset,
    bool? reconnectExpired,
    int? consecutiveFailures,
    Object? receipt = _unset,
    Object? noResultReason = _unset,
    BattleExitReason? exitReason,
    Object? notice = _unset,
    Object? noticeKind = _unset,
    Object? activeMatchId = _unset,
    int? tick,
  }) {
    return BattleSnapshot(
      phase: phase ?? this.phase,
      previewFixtures: previewFixtures ?? this.previewFixtures,
      viewer: identical(viewer, _unset) ? this.viewer : viewer as ArenaProfile?,
      inboxStatus: inboxStatus ?? this.inboxStatus,
      inboxMessage: identical(inboxMessage, _unset)
          ? this.inboxMessage
          : inboxMessage as String?,
      requests: requests ?? this.requests,
      viewerBusy: viewerBusy ?? this.viewerBusy,
      pendingChallenge: identical(pendingChallenge, _unset)
          ? this.pendingChallenge
          : pendingChallenge as ChallengeContext?,
      challengeAwaitingSignIn:
          challengeAwaitingSignIn ?? this.challengeAwaitingSignIn,
      match: identical(match, _unset) ? this.match : match as BattleMatch?,
      origin: origin ?? this.origin,
      practice: practice ?? this.practice,
      readySubmitted: readySubmitted ?? this.readySubmitted,
      connection: connection ?? this.connection,
      cameraStatus: cameraStatus ?? this.cameraStatus,
      cameraMessage: identical(cameraMessage, _unset)
          ? this.cameraMessage
          : cameraMessage as String?,
      queuePhase: queuePhase ?? this.queuePhase,
      queue: identical(queue, _unset) ? this.queue : queue as BattleQueueState?,
      queueExtended: queueExtended ?? this.queueExtended,
      queueElapsed: queueElapsed ?? this.queueElapsed,
      queueOffline: queueOffline ?? this.queueOffline,
      reconnectStartedAt: identical(reconnectStartedAt, _unset)
          ? this.reconnectStartedAt
          : reconnectStartedAt as DateTime?,
      reconnectExpired: reconnectExpired ?? this.reconnectExpired,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      receipt:
          identical(receipt, _unset) ? this.receipt : receipt as ResultReceipt?,
      noResultReason: identical(noResultReason, _unset)
          ? this.noResultReason
          : noResultReason as String?,
      exitReason: exitReason ?? this.exitReason,
      notice: identical(notice, _unset) ? this.notice : notice as String?,
      noticeKind: identical(noticeKind, _unset)
          ? this.noticeKind
          : noticeKind as BattleNoticeKind?,
      activeMatchId: identical(activeMatchId, _unset)
          ? this.activeMatchId
          : activeMatchId as String?,
      tick: tick ?? this.tick,
    );
  }

  /// Storyteller copy used by tests and diagnostics; never rendered raw.
  @override
  String toString() => 'BattleSnapshot(phase: ${phase.name}, '
      'match: ${match?.id}, receipt: ${receipt?.id}, '
      'queue: ${queuePhase.name}, connection: ${connection.name})';
}
