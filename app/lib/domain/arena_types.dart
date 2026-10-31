/// Core Training Arena value objects.
///
/// These types are the shared product contract between the Flutter shell,
/// the camera counter, the arena backend and the UI features built by
/// tasks 01-11. They are deliberately pure Dart: no Flutter, Supabase,
/// camera or platform imports. Wire values mirror `docs/API.md`; changing
/// one is a contract change that needs a `docs/decisions/` note.
library;

/// Ranked Elo starting rating from the product contract.
const int arenaStartingRating = 1000;

/// Ranked Elo K-factor from the product contract.
const int arenaEloKFactor = 32;

/// The only exercises the arena counts with the camera.
enum ArenaExercise {
  pushUps('pushups', 'Push-ups'),
  squats('squats', 'Squats');

  const ArenaExercise(this.wire, this.label);

  /// Stable value exchanged with the arena API.
  final String wire;

  /// Human readable name for UI.
  final String label;

  /// Parses an API wire value; returns null for unknown input.
  static ArenaExercise? tryFromWire(Object? value) {
    for (final exercise in ArenaExercise.values) {
      if (exercise.wire == value) {
        return exercise;
      }
    }
    return null;
  }
}

/// Whether a match can change the players' rating.
enum ArenaMatchMode {
  casual('casual', 'Casual'),
  ranked('ranked', 'Ranked');

  const ArenaMatchMode(this.wire, this.label);

  final String wire;
  final String label;

  static ArenaMatchMode? tryFromWire(Object? value) {
    for (final mode in ArenaMatchMode.values) {
      if (mode.wire == value) {
        return mode;
      }
    }
    return null;
  }
}

/// Server-authoritative lifecycle of a match (`docs/API.md`).
enum ArenaMatchStatus {
  preparing('preparing'),
  countdown('countdown'),
  live('live'),
  finished('finished'),
  noResult('no_result');

  const ArenaMatchStatus(this.wire);

  final String wire;

  static ArenaMatchStatus? tryFromWire(Object? value) {
    for (final status in ArenaMatchStatus.values) {
      if (status.wire == value) {
        return status;
      }
    }
    return null;
  }
}

/// How a finished match resolved for one viewer-independent result.
enum ArenaMatchOutcome {
  win('win'),
  draw('draw'),
  noResult('no_result');

  const ArenaMatchOutcome(this.wire);

  final String wire;

  static ArenaMatchOutcome? tryFromWire(Object? value) {
    for (final outcome in ArenaMatchOutcome.values) {
      if (outcome.wire == value) {
        return outcome;
      }
    }
    return null;
  }
}

/// Public arena identity. Auth email and notification tokens never live here.
class ArenaProfile {
  const ArenaProfile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.rating = arenaStartingRating,
    this.rankedWins = 0,
    this.rankedBattles = 0,
  });

  final String id;

  /// Null until a new user picks a unique username.
  final String? username;

  /// Optional avatar; upload can be deferred without blocking challenges.
  final String? avatarUrl;

  /// Elo rating; only server-confirmed ranked results change it.
  final int rating;

  final int rankedWins;
  final int rankedBattles;

  /// Display name used by the shell until a username is chosen.
  String get displayName => username ?? 'Arena athlete';

  @override
  bool operator ==(Object other) {
    return other is ArenaProfile &&
        other.id == id &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.rating == rating &&
        other.rankedWins == rankedWins &&
        other.rankedBattles == rankedBattles;
  }

  @override
  int get hashCode =>
      Object.hash(id, username, avatarUrl, rating, rankedWins, rankedBattles);
}

/// A challenge the app should resume: from an incoming link, a share or a
/// typed code. It must survive sign-in and username choice without a
/// generic onboarding detour.
class ChallengeContext {
  const ChallengeContext({
    required this.token,
    this.sender,
    this.matchId,
    this.receivedAt,
  });

  /// Random 12-character token from `docs/API.md` (case-insensitive).
  final String token;

  /// Resolved challenge owner, when the backend has one.
  final ArenaProfile? sender;

  /// Set once the challenge has been accepted into a match.
  final String? matchId;

  /// When the client received the challenge.
  final DateTime? receivedAt;

  /// True when the token has been resolved to its owner.
  bool get isResolved => sender != null;

  ChallengeContext copyWith({
    String? token,
    ArenaProfile? sender,
    String? matchId,
    DateTime? receivedAt,
  }) {
    return ChallengeContext(
      token: token ?? this.token,
      sender: sender ?? this.sender,
      matchId: matchId ?? this.matchId,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeContext &&
        other.token == token &&
        other.sender == sender &&
        other.matchId == matchId &&
        other.receivedAt == receivedAt;
  }

  @override
  int get hashCode => Object.hash(token, sender, matchId, receivedAt);
}

/// One player line inside an immutable [ResultReceipt].
class ArenaReceiptPlayer {
  const ArenaReceiptPlayer({
    required this.profile,
    required this.score,
    this.ratingAfter,
    this.ratingChange,
  });

  final ArenaProfile profile;

  /// Camera-counted reps confirmed by the server.
  final int score;

  /// Null for casual matches and no-result matches.
  final int? ratingAfter;
  final int? ratingChange;

  @override
  bool operator ==(Object other) {
    return other is ArenaReceiptPlayer &&
        other.profile == profile &&
        other.score == score &&
        other.ratingAfter == ratingAfter &&
        other.ratingChange == ratingChange;
  }

  @override
  int get hashCode => Object.hash(profile, score, ratingAfter, ratingChange);
}

/// Immutable server-confirmed result of a finished match.
///
/// [winnerId] is absolute, so win/loss can be derived viewer-relative.
/// [reason] carries the backend explanation for forfeits and no-results.
class ResultReceipt {
  const ResultReceipt({
    required this.id,
    required this.matchId,
    required this.exercise,
    required this.mode,
    required this.players,
    required this.outcome,
    this.winnerId,
    this.finishedAt,
    this.reason,
  });

  final String id;
  final String matchId;
  final ArenaExercise exercise;
  final ArenaMatchMode mode;
  final List<ArenaReceiptPlayer> players;
  final ArenaMatchOutcome outcome;

  /// Null unless [outcome] is [ArenaMatchOutcome.win].
  final String? winnerId;

  final DateTime? finishedAt;
  final String? reason;

  bool outcomeFor(String userId) {
    switch (outcome) {
      case ArenaMatchOutcome.win:
        return winnerId == userId;
      case ArenaMatchOutcome.draw:
      case ArenaMatchOutcome.noResult:
        return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is ResultReceipt &&
        other.id == id &&
        other.matchId == matchId &&
        other.exercise == exercise &&
        other.mode == mode &&
        _samePlayers(other.players) &&
        other.outcome == outcome &&
        other.winnerId == winnerId &&
        other.finishedAt == finishedAt &&
        other.reason == reason;
  }

  bool _samePlayers(List<ArenaReceiptPlayer> other) {
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
  int get hashCode => Object.hash(id, matchId, exercise, mode,
      Object.hashAll(players), outcome, winnerId, finishedAt, reason);
}
