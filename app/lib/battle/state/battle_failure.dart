/// Typed failure from a battle port.
///
/// Transport exceptions are converted at the port boundary so the state
/// machine and UI only ever see honest, actionable categories.
library;

/// Failure categories shared by backend, camera and session adapters.
enum BattleFailureKind {
  /// This build cannot participate; updating both phones is required.
  updateRequired,

  /// No network path to the arena service.
  offline,

  /// Backend not configured in this build (missing Supabase values).
  unconfigured,

  /// The session is missing or expired; sign-in is required.
  unauthorized,

  /// The request/match/link does not exist or is no longer usable.
  notFound,

  /// The server correctly refused because of state (busy, expired, blocked).
  conflict,

  /// The other player blocked this viewer.
  blocked,

  /// The service answered with an error it owns.
  serverFailure,

  /// The camera permission was denied by the platform.
  permissionDenied,

  /// The camera/counter is not available on this device or build.
  cameraUnavailable,
}

/// A failure with a stable kind and a factual message safe to show.
class BattleFailure implements Exception {
  const BattleFailure(this.kind, this.message);

  final BattleFailureKind kind;
  final String message;

  bool get isTransient =>
      kind == BattleFailureKind.offline ||
      kind == BattleFailureKind.serverFailure;

  @override
  String toString() => 'BattleFailure(${kind.name}): $message';
}
