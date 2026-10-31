/// Deterministic test doubles for the battle runtime.
///
/// These are test-only implementations of the battle ports. Production code
/// never references them; preview fixtures live in
/// `lib/battle/fixtures/battle_fixtures.dart` instead.
library;

import 'dart:async';

import 'package:training_arena/battle/ports/battle_backend.dart';
import 'package:training_arena/battle/ports/battle_camera.dart';
import 'package:training_arena/battle/ports/battle_challenge_sharer.dart';
import 'package:training_arena/battle/ports/battle_clock.dart';
import 'package:training_arena/battle/ports/battle_feedback.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_phase.dart';
import 'package:training_arena/domain/arena_types.dart';

/// Manually advanced clock; timers fire only inside [advance].
class ManualBattleClock implements BattleClock {
  ManualBattleClock([DateTime? start])
    : _now = start ?? DateTime.utc(2026, 9, 18, 12);

  DateTime _now;
  final List<_ManualTimer> _timers = <_ManualTimer>[];

  @override
  DateTime now() => _now;

  @override
  BattleTimer schedule(Duration delay, void Function() callback) {
    final timer = _ManualTimer(this, _now.add(delay), null, callback);
    _timers.add(timer);
    return timer;
  }

  @override
  BattleTimer periodic(Duration interval, void Function() callback) {
    final timer = _ManualTimer(this, _now.add(interval), interval, callback);
    _timers.add(timer);
    return timer;
  }

  /// Advances time, firing every due timer in order.
  void advance(Duration duration) {
    final target = _now.add(duration);
    while (true) {
      _ManualTimer? next;
      for (final timer in _timers) {
        if (timer.cancelled) {
          continue;
        }
        if (next == null || timer.due.isBefore(next.due)) {
          next = timer;
        }
      }
      if (next == null || next.due.isAfter(target)) {
        break;
      }
      _now = next.due;
      if (next.interval != null) {
        next.due = next.due.add(next.interval!);
      } else {
        next.cancelled = true;
      }
      next.callback();
    }
    _now = target;
  }
}

class _ManualTimer implements BattleTimer {
  _ManualTimer(this.clock, this.due, this.interval, this.callback);

  final ManualBattleClock clock;
  DateTime due;
  final Duration? interval;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;
}

/// Scriptable backend double.
class FakeBattleBackend implements BattleBackend {
  FakeBattleBackend({DateTime Function()? now})
    : _now = now ?? (() => DateTime.utc(2026, 9, 18, 12));

  final DateTime Function() _now;

  @override
  bool configured = true;

  /// When set, [inbox] waits for this gate before answering.
  Completer<void>? inboxGate;

  BattleInbox? inboxData;
  BattleFailure? inboxFailure;
  BattleMatch? matchData;
  BattleFailure? matchStateFailure;
  int matchStateFailures = 0;
  BattleFailure? readyFailure;
  BattleFailure? repFailure;
  int repConflicts = 0;
  BattleFailure? heartbeatFailure;
  int heartbeatFailures = 0;
  BattleMatch? readyReply;
  BattleMatch? repReply;
  BattleMatch? leaveReply;
  BattleQueueState? queueJoinReply;
  BattleQueueState? queuePollReply;
  BattleFailure? queueFailure;
  int queuePolls = 0;

  /// Server-side join timestamp kept stable across polls, like the real
  /// `queued_since` key.
  DateTime? queueJoinedAt;

  int heartbeatCalls = 0;
  Completer<void>? rematchGate;
  BattleFailure? rematchFailure;
  final List<String> callLog = <String>[];
  final List<Map<String, bool>> readyCalls = <Map<String, bool>>[];
  final List<PendingRepEvent> repCalls = <PendingRepEvent>[];

  /// Mutable server clock so tests can make replies monotonically newer.
  DateTime serverNow() => _now();

  /// Stamps a reply with the current fake server clock so offsets stay
  /// realistic across heartbeats.
  BattleMatch _stamped(BattleMatch match) =>
      match.copyWith(serverNow: serverNow());

  @override
  Future<ArenaProfile?> currentProfile() async => null;

  @override
  Future<BattleInbox> inbox() async {
    callLog.add('inbox');
    final gate = inboxGate;
    if (gate != null) {
      await gate.future;
    }
    if (inboxFailure != null) {
      throw inboxFailure!;
    }
    return inboxData ?? BattleInbox(serverNow: serverNow());
  }

  @override
  Future<BattleMatch> acceptLink(String token) async {
    callLog.add('acceptLink:$token');
    final match = matchData;
    if (match == null) {
      throw const BattleFailure(
        BattleFailureKind.conflict,
        'No fixture match configured.',
      );
    }
    return _stamped(match);
  }

  @override
  Future<BattleRequest> sendChallenge(String target) async {
    callLog.add('sendChallenge:$target');
    return BattleRequest(
      id: 'sent-1',
      kind: BattleRequestKind.pending,
      sender: testViewer,
      exercise: ArenaExercise.pushUps,
      expiresAt: serverNow().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<BattleRequest> requestRematch(String matchId) async {
    callLog.add('rematch:$matchId');
    if (rematchGate != null) await rematchGate!.future;
    if (rematchFailure != null) throw rematchFailure!;
    final request = BattleRequest(
      id: 'rematch-pending',
      kind: BattleRequestKind.pending,
      sender: testViewer,
      recipient: testOpponent,
      isOutgoing: true,
      exercise: ArenaExercise.pushUps,
      expiresAt: serverNow().add(const Duration(hours: 24)),
    );
    inboxData = BattleInbox(requests: [request], serverNow: serverNow());
    return request;
  }

  @override
  Future<BattleMatch> acceptRequest(String requestId) async {
    callLog.add('acceptRequest:$requestId');
    final match = matchData;
    if (match == null) {
      throw const BattleFailure(
        BattleFailureKind.conflict,
        'No fixture match configured.',
      );
    }
    return _stamped(match);
  }

  @override
  Future<BattleRequest> respondToRequest(
    String requestId,
    BattleRequestResponse response,
  ) async {
    callLog.add('respond:${response.name}');
    return BattleRequest(
      id: requestId,
      kind: response == BattleRequestResponse.decline
          ? BattleRequestKind.cancelled
          : BattleRequestKind.cancelled,
      sender: testOpponent,
      exercise: ArenaExercise.pushUps,
    );
  }

  @override
  Future<BattleQueueState> queueJoin() async {
    callLog.add('queueJoin');
    if (queueFailure != null) {
      throw queueFailure!;
    }
    if (queueJoinReply != null) {
      queueJoinedAt ??= queueJoinReply!.joinedAt ?? serverNow();
      return queueJoinReply!;
    }
    queueJoinedAt ??= serverNow();
    return BattleQueueState(
      joinedAt: queueJoinedAt,
      expiresAt: queueJoinedAt!.add(const Duration(seconds: 60)),
      serverNow: serverNow(),
      queued: true,
    );
  }

  @override
  Future<BattleQueueState> queuePoll() async {
    callLog.add('queuePoll');
    queuePolls++;
    if (queueFailure != null) {
      throw queueFailure!;
    }
    final joined = queueJoinedAt ?? serverNow();
    return queuePollReply ??
        BattleQueueState(
          joinedAt: joined,
          expiresAt: joined.add(const Duration(seconds: 60)),
          serverNow: serverNow(),
          queued: true,
        );
  }

  @override
  Future<void> queueLeave() async {
    callLog.add('queueLeave');
  }

  @override
  Future<BattleMatch> matchState(String matchId) async {
    callLog.add('matchState');
    if (matchStateFailures > 0) {
      matchStateFailures--;
      throw matchStateFailure ??
          const BattleFailure(BattleFailureKind.offline, 'offline');
    }
    final match = matchData;
    if (match == null) {
      throw const BattleFailure(
        BattleFailureKind.notFound,
        'This match is no longer available.',
      );
    }
    return _stamped(match);
  }

  @override
  Future<BattleMatch> ready(
    String matchId, {
    required bool tracking,
    required bool practiceComplete,
  }) async {
    callLog.add('ready');
    readyCalls.add(<String, bool>{
      'tracking': tracking,
      'practiceComplete': practiceComplete,
    });
    if (readyFailure != null) {
      throw readyFailure!;
    }
    return _stamped(readyReply ?? matchData!);
  }

  @override
  Future<BattleMatch> heartbeat(
    String matchId, {
    required bool tracking,
  }) async {
    callLog.add('heartbeat:$tracking');
    heartbeatCalls++;
    if (heartbeatFailures > 0) {
      heartbeatFailures--;
      throw heartbeatFailure ??
          const BattleFailure(BattleFailureKind.offline, 'offline');
    }
    final match = matchData;
    if (match == null) {
      throw const BattleFailure(
        BattleFailureKind.notFound,
        'This match is no longer available.',
      );
    }
    return _stamped(match);
  }

  @override
  Future<BattleMatch> reportRep(String matchId, PendingRepEvent event) async {
    callLog.add('rep:${event.sequence}');
    repCalls.add(event);
    if (repConflicts > 0) {
      repConflicts--;
      throw const BattleFailure(BattleFailureKind.conflict, 'match_not_live');
    }
    if (repFailure != null) {
      throw repFailure!;
    }
    return _stamped(repReply ?? matchData!);
  }

  @override
  Future<BattleMatch> leave(String matchId) async {
    callLog.add('leave');
    final reply = leaveReply ?? matchData;
    if (reply == null) {
      throw const BattleFailure(
        BattleFailureKind.notFound,
        'This match is no longer available.',
      );
    }
    return _stamped(reply);
  }
}

/// Scriptable camera double.
class FakeBattleCamera implements BattleCamera {
  final StreamController<BattleCameraUpdate> _updates =
      StreamController<BattleCameraUpdate>.broadcast();
  final StreamController<BattleRepEvent> _reps =
      StreamController<BattleRepEvent>.broadcast();

  BattleCameraStatus prepareResult = BattleCameraStatus.tracking;
  String? prepareMessage;
  bool disposed = false;
  final List<String> callLog = <String>[];

  @override
  Future<BattleCameraStatus> prepare(ArenaExercise exercise) async {
    callLog.add('prepare:${exercise.wire}');
    emitTracking(prepareResult, prepareMessage);
    return prepareResult;
  }

  @override
  Stream<BattleCameraUpdate> get updates => _updates.stream;

  @override
  Stream<BattleRepEvent> get reps => _reps.stream;

  @override
  Future<void> startPractice() async {
    callLog.add('startPractice');
  }

  @override
  Future<void> startMatch() async {
    callLog.add('startMatch');
  }

  @override
  Future<void> suspend() async {
    callLog.add('suspend');
  }

  @override
  Future<void> resume() async {
    callLog.add('resume');
  }

  @override
  Future<void> stop() async {
    callLog.add('stop');
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!_updates.isClosed) {
      await _updates.close();
    }
    if (!_reps.isClosed) {
      await _reps.close();
    }
  }

  void emitTracking(BattleCameraStatus status, [String? message]) {
    if (!_updates.isClosed) {
      _updates.add(BattleCameraUpdate(status, message: message));
    }
  }

  void emitPracticeRep({String? eventId, int sequence = 1}) {
    if (!_reps.isClosed) {
      _reps.add(
        BattleRepEvent(
          eventId: eventId ?? 'practice-1',
          sequence: sequence,
          practice: true,
          competitive: false,
          observedAt: DateTime.utc(
            2026,
            9,
            18,
            12,
          ).add(Duration(seconds: sequence)),
        ),
      );
    }
  }

  void emitCompetitiveRep({String? eventId, int sequence = 1}) {
    if (!_reps.isClosed) {
      _reps.add(
        BattleRepEvent(
          eventId: eventId ?? 'rep-$sequence',
          sequence: sequence,
          observedAt: DateTime.utc(
            2026,
            9,
            18,
            12,
          ).add(Duration(seconds: sequence)),
        ),
      );
    }
  }
}

/// Records native cues instead of firing haptics.
class RecordingBattleFeedback implements BattleFeedback {
  final List<String> cues = <String>[];
  final List<String> announcements = <String>[];

  @override
  void countdownTick(int secondsLeft) => cues.add('countdown:$secondsLeft');

  @override
  void roundStarted() => cues.add('roundStarted');

  @override
  void finalTenSeconds() => cues.add('ten');

  @override
  void finalThreeSeconds() => cues.add('three');

  @override
  void trackingLost() => cues.add('trackingLost');

  @override
  void trackingRestored() => cues.add('trackingRestored');

  @override
  void warning() => cues.add('warning');

  @override
  void resultConfirmed() => cues.add('result');

  @override
  void tap() => cues.add('tap');

  @override
  void announce(String message) => announcements.add(message);
}

/// Records challenge share requests.
class RecordingChallengeSharer implements BattleChallengeSharer {
  RecordingChallengeSharer({this.message});

  String? message;
  final List<BattleChallengeInvite> invites = <BattleChallengeInvite>[];

  @override
  Future<String?> shareChallenge(BattleChallengeInvite invite) async {
    invites.add(invite);
    return message;
  }
}

/// Common profiles/matches for tests.
const ArenaProfile testViewer = ArenaProfile(
  id: 'viewer-1',
  username: 'azizbek',
  rating: 1042,
  rankedWins: 7,
  rankedBattles: 11,
);

const ArenaProfile testOpponent = ArenaProfile(
  id: 'opponent-1',
  username: 'zuhra',
  rating: 1060,
  rankedWins: 9,
  rankedBattles: 14,
);

BattleRequest testRequest({
  String id = 'request-1',
  BattleRequestKind kind = BattleRequestKind.pending,
  ArenaProfile sender = testOpponent,
  ArenaExercise exercise = ArenaExercise.pushUps,
}) {
  return BattleRequest(
    id: id,
    kind: kind,
    sender: sender,
    exercise: exercise,
    receivedAt: DateTime.utc(2026, 9, 18, 11),
    expiresAt: DateTime.utc(2026, 9, 19, 11),
  );
}

BattleMatch testMatch({
  String id = 'match-1',
  ArenaMatchStatus status = ArenaMatchStatus.preparing,
  ArenaExercise exercise = ArenaExercise.pushUps,
  ArenaMatchMode mode = ArenaMatchMode.casual,
  bool opponentReady = false,
  bool viewerReady = false,
  int viewerScore = 0,
  int opponentScore = 0,
  bool viewerTracking = true,
  bool opponentTracking = true,
  DateTime? startsAt,
  DateTime? endsAt,
  DateTime? serverNow,
  ResultReceipt? receipt,
  String? reason,
}) {
  return BattleMatch(
    id: id,
    exercise: exercise,
    mode: mode,
    status: status,
    players: <BattleMatchPlayer>[
      BattleMatchPlayer(
        profile: testViewer,
        score: viewerScore,
        ready: viewerReady,
        tracking: viewerTracking,
      ),
      BattleMatchPlayer(
        profile: testOpponent,
        score: opponentScore,
        ready: opponentReady,
        tracking: opponentTracking,
      ),
    ],
    startsAt: startsAt,
    endsAt: endsAt,
    serverNow: serverNow ?? DateTime.utc(2026, 9, 18, 12),
    receipt: receipt,
    reason: reason,
  );
}

ResultReceipt testReceipt({
  String id = 'receipt-1',
  String matchId = 'match-1',
  ArenaMatchMode mode = ArenaMatchMode.casual,
  ArenaMatchOutcome outcome = ArenaMatchOutcome.win,
  String? winnerId = 'viewer-1',
  int viewerScore = 26,
  int opponentScore = 23,
  int? ratingAfter,
  int? ratingChange,
  String? reason,
}) {
  return ResultReceipt(
    id: id,
    matchId: matchId,
    exercise: ArenaExercise.pushUps,
    mode: mode,
    players: <ArenaReceiptPlayer>[
      ArenaReceiptPlayer(
        profile: testViewer.copyWithRating(1042),
        score: viewerScore,
        ratingAfter: ratingAfter,
        ratingChange: ratingChange,
      ),
      ArenaReceiptPlayer(profile: testOpponent, score: opponentScore),
    ],
    outcome: outcome,
    winnerId: winnerId,
    finishedAt: DateTime.utc(2026, 9, 18, 12, 1),
    reason: reason,
  );
}

extension on ArenaProfile {
  ArenaProfile copyWithRating(int rating) => ArenaProfile(
    id: id,
    username: username,
    avatarUrl: avatarUrl,
    rating: rating,
    rankedWins: rankedWins,
    rankedBattles: rankedBattles,
  );
}
