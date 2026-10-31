/// Battle-facing value objects.
///
/// These models are the only shapes the battle state machine and UI accept.
/// They are pure Dart and map onto `docs/API.md` objects: requests, inbox,
/// match state and the ranked queue. A real backend adapter (task 04) parses
/// API JSON into these; it never changes the state contract.
library;

import '../../domain/arena_types.dart';

/// Which inbox card variant a request renders as.
///
/// `docs/API.md` stores pending/accepted/declined/cancelled/expired; the UI
/// derives offline/busy/blocked/busy variants from presence and match state.
enum BattleRequestKind {
  pending,
  offlineChallenger,
  expired,
  busyPlayer,
  cancelled,
  blocked,
}

/// One challenge request, rendered by the request card.
class BattleRequest {
  const BattleRequest({
    required this.id,
    required this.kind,
    required this.sender,
    required this.exercise,
    this.recipient,
    this.isOutgoing = false,
    this.mode = ArenaMatchMode.casual,
    this.receivedAt,
    this.expiresAt,
    this.matchId,
    this.note,
  });

  final String id;
  final BattleRequestKind kind;
  final ArenaProfile sender;
  final ArenaProfile? recipient;
  final bool isOutgoing;
  final ArenaExercise exercise;
  final ArenaMatchMode mode;

  /// When the challenge arrived; shown as quiet meta.
  final DateTime? receivedAt;

  /// Requests last 24 hours; expired requests show "nothing was created".
  final DateTime? expiresAt;

  /// Set once the request has been accepted into a match.
  final String? matchId;

  /// Optional factual backend explanation (blocked/busy copy).
  final String? note;

  BattleRequest copyWith({
    BattleRequestKind? kind,
    String? matchId,
    DateTime? expiresAt,
  }) {
    return BattleRequest(
      id: id,
      kind: kind ?? this.kind,
      sender: sender,
      recipient: recipient,
      isOutgoing: isOutgoing,
      exercise: exercise,
      mode: mode,
      receivedAt: receivedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      matchId: matchId ?? this.matchId,
      note: note,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BattleRequest &&
        other.id == id &&
        other.kind == kind &&
        other.sender == sender &&
        other.recipient == recipient &&
        other.isOutgoing == isOutgoing &&
        other.exercise == exercise &&
        other.mode == mode &&
        other.receivedAt == receivedAt &&
        other.expiresAt == expiresAt &&
        other.matchId == matchId &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        sender,
        recipient,
        isOutgoing,
        exercise,
        mode,
        receivedAt,
        expiresAt,
        matchId,
        note,
      );
}

/// One authoritative server snapshot of the inbox (`inbox` action).
class BattleInbox {
  const BattleInbox({
    this.requests = const <BattleRequest>[],
    this.activeMatchId,
    this.viewerBusy = false,
    this.serverNow,
  });

  final List<BattleRequest> requests;

  /// A match the viewer is already in; the UI offers to resume it.
  final String? activeMatchId;

  /// True when the backend reports the viewer is in another battle.
  final bool viewerBusy;

  final DateTime? serverNow;

  /// Earliest live pending request; the Battle tab shows it first.
  BattleRequest? get incoming {
    for (final request in requests) {
      if (!request.isOutgoing && request.kind == BattleRequestKind.pending) {
        return request;
      }
    }
    return null;
  }

  BattleInbox copyWith({
    List<BattleRequest>? requests,
    String? activeMatchId,
    bool? viewerBusy,
    DateTime? serverNow,
  }) {
    return BattleInbox(
      requests: requests ?? this.requests,
      activeMatchId: activeMatchId ?? this.activeMatchId,
      viewerBusy: viewerBusy ?? this.viewerBusy,
      serverNow: serverNow ?? this.serverNow,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BattleInbox &&
        _sameRequests(other.requests) &&
        other.activeMatchId == activeMatchId &&
        other.viewerBusy == viewerBusy &&
        other.serverNow == serverNow;
  }

  bool _sameRequests(List<BattleRequest> other) {
    if (other.length != requests.length) {
      return false;
    }
    for (var i = 0; i < requests.length; i++) {
      if (other[i] != requests[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
      Object.hashAll(requests), activeMatchId, viewerBusy, serverNow);
}

/// One player line inside a [BattleMatch].
class BattleMatchPlayer {
  const BattleMatchPlayer({
    required this.profile,
    this.score = 0,
    this.ready = false,
    this.tracking = false,
    this.lastSeen,
  });

  final ArenaProfile profile;

  /// Server-confirmed reps only. Camera events never write this directly.
  final int score;

  final bool ready;
  final bool tracking;
  final DateTime? lastSeen;

  BattleMatchPlayer copyWith({
    int? score,
    bool? ready,
    bool? tracking,
    DateTime? lastSeen,
  }) {
    return BattleMatchPlayer(
      profile: profile,
      score: score ?? this.score,
      ready: ready ?? this.ready,
      tracking: tracking ?? this.tracking,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BattleMatchPlayer &&
        other.profile == profile &&
        other.score == score &&
        other.ready == ready &&
        other.tracking == tracking &&
        other.lastSeen == lastSeen;
  }

  @override
  int get hashCode => Object.hash(profile, score, ready, tracking, lastSeen);
}

/// Server-authoritative match snapshot (`match_state`, `ready`, `rep`,
/// `heartbeat`, `leave` replies).
class BattleMatch {
  const BattleMatch({
    required this.id,
    required this.exercise,
    required this.mode,
    required this.status,
    this.players = const <BattleMatchPlayer>[],
    this.startsAt,
    this.endsAt,
    this.serverNow,
    this.receipt,
    this.reason,
  });

  final String id;
  final ArenaExercise exercise;
  final ArenaMatchMode mode;
  final ArenaMatchStatus status;
  final List<BattleMatchPlayer> players;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? serverNow;

  /// Present only when the server has confirmed the final result.
  final ResultReceipt? receipt;

  /// Backend explanation for no-result or forfeits.
  final String? reason;

  bool get hasReceipt => receipt != null;

  bool get bothReady =>
      players.length == 2 && players.every((player) => player.ready);

  BattleMatchPlayer? playerFor(String? userId) {
    if (userId == null) {
      return null;
    }
    for (final player in players) {
      if (player.profile.id == userId) {
        return player;
      }
    }
    return null;
  }

  BattleMatchPlayer? opponentFor(String? userId) {
    for (final player in players) {
      if (player.profile.id != userId) {
        return player;
      }
    }
    return null;
  }

  BattleMatch copyWith({
    ArenaMatchStatus? status,
    List<BattleMatchPlayer>? players,
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
      status: status ?? this.status,
      players: players ?? this.players,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      serverNow: serverNow ?? this.serverNow,
      receipt: receipt ?? this.receipt,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BattleMatch &&
        other.id == id &&
        other.exercise == exercise &&
        other.mode == mode &&
        other.status == status &&
        _samePlayers(other.players) &&
        other.startsAt == startsAt &&
        other.endsAt == endsAt &&
        other.serverNow == serverNow &&
        other.receipt == receipt &&
        other.reason == reason;
  }

  bool _samePlayers(List<BattleMatchPlayer> other) {
    if (other.length != players.length) {
      return false;
    }
    for (var i = 0; i < players.length; i++) {
      if (other[i] != players[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, exercise, mode, status,
      Object.hashAll(players), startsAt, endsAt, serverNow, receipt, reason);
}

/// Ranked queue snapshot (`queue_join` / `queue_poll`).
///
/// `queued` is the additive wire key from `docs/API.md` (#04): false means the
/// server no longer holds a seat for this player. Null is treated as unknown,
/// so older replies keep working.
class BattleQueueState {
  const BattleQueueState({
    this.matchId,
    this.joinedAt,
    this.expiresAt,
    this.serverNow,
    this.queued,
  });

  /// Present when matchmaking paired the player; the queue then ends.
  final String? matchId;
  final DateTime? joinedAt;
  final DateTime? expiresAt;
  final DateTime? serverNow;

  /// Whether the authoritative server still holds the queue seat.
  final bool? queued;

  /// True unless the server explicitly reported the seat gone.
  bool get seatActive => queued ?? true;

  BattleQueueState copyWith({
    String? matchId,
    DateTime? joinedAt,
    DateTime? expiresAt,
    DateTime? serverNow,
    bool? queued,
  }) {
    return BattleQueueState(
      matchId: matchId ?? this.matchId,
      joinedAt: joinedAt ?? this.joinedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      serverNow: serverNow ?? this.serverNow,
      queued: queued ?? this.queued,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BattleQueueState &&
        other.matchId == matchId &&
        other.joinedAt == joinedAt &&
        other.expiresAt == expiresAt &&
        other.serverNow == serverNow &&
        other.queued == queued;
  }

  @override
  int get hashCode =>
      Object.hash(matchId, joinedAt, expiresAt, serverNow, queued);
}

/// A competitive rep event queued for the server. `event_id` stays stable
/// across retries so the API can dedupe it.
class PendingRepEvent {
  const PendingRepEvent({
    required this.eventId,
    required this.sequence,
    required this.observedAt,
    required this.counterVersion,
  });

  final String eventId;
  final int sequence;
  final DateTime observedAt;
  final String counterVersion;
}
