/// Client-side challenge link value objects.
///
/// Wire object shapes stay exactly as `docs/API.md` (task `04`) defines them:
/// a link resolves to `{owner, available}` and richer states arrive through
/// the documented `{error:{code,message}}` envelope. The enums below only
/// name those states for the UI; they are not new wire values.
library;

import '../domain/arena_types.dart';

/// Landing state of a challenge link.
enum ChallengeLinkStatus {
  /// The link resolves; the recipient can send a live challenge.
  available('available'),

  /// The sharer is reachable but not currently able to play.
  ownerOffline('owner_offline'),

  /// Link revoked by the owner.
  revoked('revoked'),

  /// A stored request ran past its 24-hour expiry.
  expired('expired'),

  /// The intended battle already happened; a link never replays a match.
  completed('completed'),

  /// The sharer is in another battle.
  busyPlayer('busy_player'),

  /// One side blocked the other.
  blocked('blocked'),

  /// Deleted account, unknown token or any other terminal failure.
  unavailable('unavailable');

  const ChallengeLinkStatus(this.wire);

  final String wire;

  /// True when the recipient may still act on the link.
  bool get canRespond =>
      this == ChallengeLinkStatus.available ||
      this == ChallengeLinkStatus.ownerOffline;
}

/// Result of the read-only `resolve_link` call.
class ChallengeResolution {
  const ChallengeResolution({
    required this.token,
    required this.status,
    this.owner,
    this.message,
  });

  /// The challenge token (never a match id).
  final String token;

  final ChallengeLinkStatus status;

  /// Public challenger identity; null when the link is unavailable before
  /// the backend reveals an owner.
  final ArenaProfile? owner;

  /// Optional server explanation shown verbatim when safe.
  final String? message;

  bool get isAvailable => status == ChallengeLinkStatus.available;

  bool get isOwnerOffline => status == ChallengeLinkStatus.ownerOffline;

  bool get canRespond => status.canRespond;

  ChallengeResolution copyWith({
    String? token,
    ChallengeLinkStatus? status,
    ArenaProfile? owner,
    String? message,
  }) {
    return ChallengeResolution(
      token: token ?? this.token,
      status: status ?? this.status,
      owner: owner ?? this.owner,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeResolution &&
        other.token == token &&
        other.status == status &&
        other.owner == owner &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(token, status, owner, message);
}

/// Lifecycle of one recipient's challenge request (`docs/API.md`).
enum ChallengeRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled'),
  expired('expired');

  const ChallengeRequestStatus(this.wire);

  final String wire;

  static ChallengeRequestStatus? tryFromWire(Object? value) {
    for (final status in ChallengeRequestStatus.values) {
      if (status.wire == value) {
        return status;
      }
    }
    return null;
  }
}

/// A challenge request returned by `request_send` / `request_respond`.
class ChallengeRequest {
  const ChallengeRequest({
    required this.id,
    required this.status,
    this.expiresAt,
    this.matchId,
  });

  final String id;
  final ChallengeRequestStatus status;

  /// Server expiry; requests last 24 hours.
  final DateTime? expiresAt;

  /// Set once mutual acceptance produced a match.
  final String? matchId;

  bool get isPending => status == ChallengeRequestStatus.pending;

  bool get isAccepted => status == ChallengeRequestStatus.accepted;

  @override
  bool operator ==(Object other) {
    return other is ChallengeRequest &&
        other.id == id &&
        other.status == status &&
        other.expiresAt == expiresAt &&
        other.matchId == matchId;
  }

  @override
  int get hashCode => Object.hash(id, status, expiresAt, matchId);
}

/// The owner's durable link from `profile` / `link_rotate`.
class ChallengeLinkInfo {
  const ChallengeLinkInfo({required this.token, required this.code});

  final String token;

  /// Same random identifier; `docs/API.md` keeps code == token.
  final String code;

  @override
  bool operator ==(Object other) {
    return other is ChallengeLinkInfo &&
        other.token == token &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(token, code);
}

/// Account snapshot needed by the share sheet and the waiting state.
class ChallengeAccountSnapshot {
  const ChallengeAccountSnapshot({
    required this.profile,
    required this.link,
    this.activeMatchId,
  });

  final ArenaProfile profile;
  final ChallengeLinkInfo link;
  final String? activeMatchId;
}

/// `request_respond` response value.
enum ChallengeRequestResponse {
  decline('decline'),
  cancel('cancel');

  const ChallengeRequestResponse(this.wire);

  final String wire;
}

/// Failure surface for the arena API.
///
/// [code] is the documented error code when the backend supplied one, or a
/// client code for transport failures (`network`, `malformed_response`).
class ChallengeApiException implements Exception {
  const ChallengeApiException(this.code, {this.message, this.statusCode});

  const ChallengeApiException.network()
      : code = 'network',
        message = 'The arena is unreachable right now.',
        statusCode = null;

  const ChallengeApiException.unauthenticated()
      : code = 'unauthenticated',
        message = 'Sign in is required for this action.',
        statusCode = null;

  const ChallengeApiException.malformed()
      : code = 'malformed_response',
        message = 'The arena returned an unexpected response.',
        statusCode = null;

  final String code;
  final String? message;
  final int? statusCode;

  bool get isUnauthenticated =>
      code == 'unauthenticated' ||
      code == 'unauthorized' ||
      statusCode == 401 ||
      statusCode == 403;

  bool get isRetryable =>
      code == 'network' || code == 'malformed_response' || (statusCode ?? 0) >= 500;

  /// Maps a documented server code (task `04`) to a landing status. Unknown
  /// codes fall back to the honest generic unavailable state.
  static ChallengeLinkStatus statusFromErrorCode(String? code) {
    switch (code) {
      case 'link_revoked':
      case 'revoked':
      case 'link_not_found':
      case 'not_found':
        return ChallengeLinkStatus.revoked;
      case 'request_expired':
      case 'expired':
        return ChallengeLinkStatus.expired;
      case 'challenge_completed':
      case 'match_completed':
      case 'completed':
      case 'request_closed':
        return ChallengeLinkStatus.completed;
      case 'player_busy':
      case 'busy':
        return ChallengeLinkStatus.busyPlayer;
      case 'blocked':
      case 'blocked_peer':
      case 'recipient_blocked':
        return ChallengeLinkStatus.blocked;
      case 'challenger_offline':
      case 'owner_offline':
        return ChallengeLinkStatus.ownerOffline;
      default:
        return ChallengeLinkStatus.unavailable;
    }
  }

  @override
  String toString() => 'ChallengeApiException($code)';
}
