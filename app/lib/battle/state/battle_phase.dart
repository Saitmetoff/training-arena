/// Explicit runtime states for the battle feature.
///
/// The model mirrors `design/arena/SCREEN_MAP.md` section "Runtime state
/// model" and is the contract every backend, camera and UI adapter plugs
/// into. Adding a value is additive; renaming one is a contract change that
/// needs a `docs/decisions/` note.
library;

/// Where the battle flow is right now.
enum BattlePhase {
  /// Unsupported build stopped locally; no server result is inferred.
  updateRequired,

  /// Nothing loaded yet; the home tab is resolving viewer/inbox.
  loading,

  /// A challenge link or request is being accepted; the server owns the
  /// transition and no match exists until it answers.
  resolving,

  /// Battle tab idle. Incoming requests may exist.
  home,

  /// The full request inbox is open.
  inbox,

  /// Preparation: exercise revealed, demonstration, framing and the single
  /// unscored practice rep. The match already exists.
  preparing,

  /// Ready gate submitted by this player; waiting for the opponent.
  ready,

  /// Server countdown before the round starts (1-5 seconds, server clock).
  countdown,

  /// The 60-second round is running for both players.
  live,

  /// Live round with a degraded connection: this player's tracking is lost,
  /// the opponent is reconnecting/lost, or the shared service is unreachable.
  /// The shared clock keeps running; no local outcome is ever inferred.
  reconnecting,

  /// A server-confirmed receipt exists and is rendered.
  result,

  /// The server closed the match with `no_result`; no rating change.
  noResult,

  /// Leave/cancel was confirmed locally and is being reported to the server.
  exiting,

  /// The flow is closed; the player is back on Battle or has left the match.
  exited,
}

/// The connection quality that drives the [BattlePhase.reconnecting] banner.
enum BattleConnection {
  /// Both sides healthy.
  online,

  /// This device's camera tracking is lost; only this player's count pauses.
  selfTrackingLost,

  /// The opponent lost tracking and has a recovery window.
  opponentReconnecting,

  /// The opponent missed heartbeats and the server forfeit window is open.
  opponentLost,

  /// The arena service cannot be reached from this device.
  serviceOutage,
}

/// Practice rep progress during preparation. Exactly one unscored rep.
enum PracticeState { notStarted, counting, completed }

/// Camera/tracking state surfaced by the preparation and live surfaces.
enum BattleCameraStatus {
  unknown,
  preparing,
  permissionDenied,
  unavailable,
  framing,
  tracking,
  trackingLost,
}

/// Request inbox load state; covers the required loading/empty/offline states.
enum BattleLoadStatus {
  initial,
  loading,
  ready,
  empty,
  offline,
  error,
  unconfigured,
  signedOut,
  blocked,
}

/// Ranked search state. A queue seat exists only in [searching]/[extended].
enum BattleQueuePhase { idle, searching, extended, matched, stopped, cancelled }

/// Which entry point created the active match.
enum BattleMatchOrigin {
  none,
  battleTab,
  rankedQueue,
  challengeLink,
  joinCode,
  request,
}

/// Why the player is leaving or has left.
enum BattleExitReason {
  none,
  leftPreparation,
  cancelledMatch,
  leftCountdown,
  leftLive,
  declinedRequest,
  cancelledRequest,
  blockedPlayer,
  matchExpired,
}

/// Severity of a factual status notice shown on Battle.
enum BattleNoticeKind { info, warning, danger, positive }
