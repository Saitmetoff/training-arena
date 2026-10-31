/// Battle/matchmaking analytics boundary.
///
/// Added by task `08` so the ranked search can report the events required by
/// the product contract without the controller knowing about HTTP. Analytics
/// is always best effort: it must never block, fail or alter a battle, a
/// queue seat or a result. Opening a share sheet is never tracked as a
/// successful referral — `matchmaking_friend_alternative` only records that
/// the alternative was offered or chosen.
library;

/// Stable event names sent through the `analytics` action.
///
/// Format matches the server rule `^[a-z][a-z0-9_]{1,48}$`.
abstract final class MatchmakingAnalyticsEvent {
  /// The player created a queue seat.
  static const String searchStarted = 'matchmaking_search_started';

  /// The authoritative server issued a ranked match.
  static const String matchFound = 'matchmaking_match_found';

  /// The seat ended before a match: manual stop, app pause, seat expiry or
  /// switching to a friend challenge.
  static const String searchCancelled = 'matchmaking_search_cancelled';

  /// The 60-second window elapsed with no server-issued match.
  static const String searchTimedOut = 'matchmaking_search_timed_out';

  /// The 15-second friend-challenge alternative was offered or chosen.
  static const String friendAlternative = 'matchmaking_friend_alternative';
}

/// Sink consumed by the battle controller.
abstract interface class BattleAnalyticsSink {
  Future<void> track(String event, Map<String, Object?> properties);
}

/// Discards events (unconfigured builds, preview fixtures, tests).
class NoopBattleAnalyticsSink implements BattleAnalyticsSink {
  const NoopBattleAnalyticsSink();

  @override
  Future<void> track(String event, Map<String, Object?> properties) async {}
}
