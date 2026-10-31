/// Sharing seam for "Challenge a friend" and result-based challenges.
///
/// Task 09 owns the real share card, system share sheet and challenge URL.
/// The battle UI only asks the sharer to open; a returned message is rendered
/// as a factual notice and never implies a referral.
library;

import '../../domain/arena_types.dart';

/// Everything the sharer may use to build a new invite. Factual only.
class BattleChallengeInvite {
  const BattleChallengeInvite({
    this.exercise,
    this.mode = ArenaMatchMode.casual,
    this.opponent,
    this.receipt,
  });

  /// Preferred exercise for the new challenge; null lets the server choose.
  final ArenaExercise? exercise;

  final ArenaMatchMode mode;

  /// Opponent username for result-based challenges.
  final String? opponent;

  /// Confirmed receipt when the invite follows a battle; never replayed.
  final ResultReceipt? receipt;
}

/// Opens the challenge share surface.
abstract interface class BattleChallengeSharer {
  /// Returns null when a share surface opened, or a factual message why it
  /// could not. Never records a referral.
  Future<String?> shareChallenge(BattleChallengeInvite invite);
}

/// Honest default until task 09 lands.
class PendingBattleChallengeSharer implements BattleChallengeSharer {
  const PendingBattleChallengeSharer();

  @override
  Future<String?> shareChallenge(BattleChallengeInvite invite) async {
    return 'Challenge cards arrive with task 09. No share sheet opened and '
        'no referral was recorded.';
  }
}
