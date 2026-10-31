/// Adapters from task 05's linking/challenge services to battle ports.
library;

import '../../linking/challenge_entry_controller.dart';
import '../../linking/challenge_share.dart';
import '../ports/battle_challenge_entry.dart';
import '../ports/battle_challenge_sharer.dart';

/// [BattleChallengeSharer] over task 05's system share-sheet service.
class ChallengeShareServiceSharer implements BattleChallengeSharer {
  const ChallengeShareServiceSharer(this.service);

  final ChallengeShareService service;

  @override
  Future<String?> shareChallenge(BattleChallengeInvite invite) async {
    try {
      // Result-based challenges use the confirmed receipt; the share card
      // itself is task 09's surface and never replays the match.
      await service.shareChallenge(
        source: invite.receipt != null ? 'result' : 'battle',
      );
      return null;
    } on ChallengeShareException catch (error) {
      return error.message;
    } catch (_) {
      return 'The challenge share sheet could not be opened.';
    }
  }
}

/// [BattleChallengeEntryDelegate] over task 05's [ChallengeEntryController].
class ChallengeEntryDelegate implements BattleChallengeEntryDelegate {
  const ChallengeEntryDelegate(this.controller);

  final ChallengeEntryController controller;

  @override
  Future<bool> openCode(String text) => controller.openCode(text);
}
