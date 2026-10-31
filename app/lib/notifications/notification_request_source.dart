/// Authoritative source for resolving a notification tap.
///
/// A tap only opens what the server confirms: the inbox is fetched again and
/// the exact request or match is looked up. The client never invents a
/// request, a match or an opponent from a notification payload.
library;

import '../battle/ports/battle_backend.dart';
import '../battle/state/battle_failure.dart';
import '../battle/state/battle_models.dart';

/// Result of checking whether a tapped match is still available.
sealed class NotificationMatchResolution {
  const NotificationMatchResolution();
}

/// The server issued this match and the viewer may open it.
class NotificationMatchOpen extends NotificationMatchResolution {
  const NotificationMatchOpen(this.match);

  final BattleMatch match;
}

/// The match cannot be opened; [message] explains why.
class NotificationMatchClosed extends NotificationMatchResolution {
  const NotificationMatchClosed(this.message, {this.blocked = false});

  final String message;

  /// True when the arena reports a block between the players.
  final bool blocked;
}

/// Reads requests and matches for the notification router.
abstract interface class NotificationRequestSource {
  /// Current authoritative inbox (`inbox` action).
  Future<BattleInbox> inbox();

  /// Checks one match (`match_state` action).
  ///
  /// Throws [BattleFailure] for retryable transport problems; availability
  /// answers are returned, never guessed.
  Future<NotificationMatchResolution> matchStatus(String matchId);
}

/// Production adapter over the battle backend.
class BattleBackendNotificationSource implements NotificationRequestSource {
  const BattleBackendNotificationSource(this._backend);

  final BattleBackend _backend;

  @override
  Future<BattleInbox> inbox() => _backend.inbox();

  @override
  Future<NotificationMatchResolution> matchStatus(String matchId) async {
    try {
      final match = await _backend.matchState(matchId);
      return NotificationMatchOpen(match);
    } on BattleFailure catch (failure) {
      switch (failure.kind) {
        case BattleFailureKind.blocked:
          return const NotificationMatchClosed(
            'This battle cannot be opened because one player blocked the '
            'other. Nothing was created.',
            blocked: true,
          );
        case BattleFailureKind.offline:
        case BattleFailureKind.unauthorized:
        case BattleFailureKind.unconfigured:
          rethrow;
        case BattleFailureKind.notFound:
        case BattleFailureKind.updateRequired:
        case BattleFailureKind.conflict:
        case BattleFailureKind.serverFailure:
        case BattleFailureKind.permissionDenied:
        case BattleFailureKind.cameraUnavailable:
          return NotificationMatchClosed(failure.message);
      }
    }
  }
}
