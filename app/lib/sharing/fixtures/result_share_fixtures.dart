/// Deterministic review fixtures for result sharing.
///
/// These are labelled `SIMULATED FIXTURE` artwork for design review and
/// deterministic tests. They are [PreviewResultShareCard]s only: they can be
/// rendered and exported, but the share service accepts only
/// [ConfirmedResultShareCard]s built from a server receipt, so a fixture can
/// never be shared as a confirmed outcome.
library;

import '../../domain/arena_types.dart';
import '../../linking/challenge_link.dart';
import '../../linking/challenge_models.dart';
import '../result_share_models.dart';

/// Fixture profiles, receipts and preview cards for every result variant.
abstract final class ResultShareFixtures {
  /// Invented viewer identity, consistent with the battle fixtures.
  static const ArenaProfile viewer = ArenaProfile(
    id: 'fixture-viewer',
    username: 'azizbek',
    rating: 1042,
    rankedWins: 7,
    rankedBattles: 11,
  );

  /// Invented opponent identity, consistent with the battle fixtures.
  static const ArenaProfile opponent = ArenaProfile(
    id: 'fixture-opponent',
    username: 'zuhra',
    rating: 1060,
    rankedWins: 9,
    rankedBattles: 14,
  );

  /// Preview-only token. Never issued by a backend.
  static const String token = '9f2k4p7q';

  /// Preview-only link on the configured placeholder host.
  static final Uri link = Uri.parse('https://example.invalid/c/$token');

  static String get readableCode => ChallengeLink.readableCodeFor(token);

  /// Confirmed-account shape used by preview tests; the token is a fixture.
  static ChallengeAccountSnapshot get account =>
      const ChallengeAccountSnapshot(
        profile: viewer,
        link: ChallengeLinkInfo(token: token, code: token),
      );

  static ResultReceipt _receipt({
    required String id,
    required ArenaMatchMode mode,
    required int viewerScore,
    required int opponentScore,
    required ArenaMatchOutcome outcome,
    String? winnerId,
    int? viewerRatingAfter,
    int? viewerRatingChange,
    int? opponentRatingAfter,
    int? opponentRatingChange,
    String? reason,
  }) {
    return ResultReceipt(
      id: 'fixture-receipt-$id',
      matchId: 'fixture-match-$id',
      exercise: ArenaExercise.pushUps,
      mode: mode,
      players: <ArenaReceiptPlayer>[
        ArenaReceiptPlayer(
          profile: viewer,
          score: viewerScore,
          ratingAfter: viewerRatingAfter,
          ratingChange: viewerRatingChange,
        ),
        ArenaReceiptPlayer(
          profile: opponent,
          score: opponentScore,
          ratingAfter: opponentRatingAfter,
          ratingChange: opponentRatingChange,
        ),
      ],
      outcome: outcome,
      winnerId: winnerId,
      finishedAt: DateTime.utc(2026, 9, 18, 12),
      reason: reason,
    );
  }

  static PreviewResultShareCard _card(ResultReceipt receipt) =>
      previewResultShareCard(
        receipt: receipt,
        viewerId: viewer.id,
        challengeUrl: link,
        readableCode: readableCode,
      );

  /// Viewer won a casual match 26–23.
  static PreviewResultShareCard get winCasual => _card(_receipt(
        id: 'win-casual',
        mode: ArenaMatchMode.casual,
        viewerScore: 26,
        opponentScore: 23,
        outcome: ArenaMatchOutcome.win,
        winnerId: viewer.id,
      ));

  /// Viewer lost a casual match 18–24.
  static PreviewResultShareCard get lossCasual => _card(_receipt(
        id: 'loss-casual',
        mode: ArenaMatchMode.casual,
        viewerScore: 18,
        opponentScore: 24,
        outcome: ArenaMatchOutcome.win,
        winnerId: opponent.id,
      ));

  /// Casual draw, 24 each.
  static PreviewResultShareCard get drawCasual => _card(_receipt(
        id: 'draw-casual',
        mode: ArenaMatchMode.casual,
        viewerScore: 24,
        opponentScore: 24,
        outcome: ArenaMatchOutcome.draw,
      ));

  /// Ranked win with both confirmed rating after-values.
  static PreviewResultShareCard get winRanked => _card(_receipt(
        id: 'win-ranked',
        mode: ArenaMatchMode.ranked,
        viewerScore: 31,
        opponentScore: 28,
        outcome: ArenaMatchOutcome.win,
        winnerId: viewer.id,
        viewerRatingAfter: 1058,
        viewerRatingChange: 16,
        opponentRatingAfter: 1044,
        opponentRatingChange: -16,
      ));

  /// Ranked loss with both confirmed rating after-values.
  static PreviewResultShareCard get lossRanked => _card(_receipt(
        id: 'loss-ranked',
        mode: ArenaMatchMode.ranked,
        viewerScore: 20,
        opponentScore: 25,
        outcome: ArenaMatchOutcome.win,
        winnerId: opponent.id,
        viewerRatingAfter: 1042,
        viewerRatingChange: -16,
        opponentRatingAfter: 1060,
        opponentRatingChange: 16,
      ));

  /// Server-confirmed no-result; no winner, no rating change.
  static PreviewResultShareCard get noResult => _card(_receipt(
        id: 'no-result',
        mode: ArenaMatchMode.ranked,
        viewerScore: 12,
        opponentScore: 9,
        outcome: ArenaMatchOutcome.noResult,
        reason: 'service_outage',
      ));

  /// Every fixture, for gallery tests and export checks.
  static List<PreviewResultShareCard> get all => <PreviewResultShareCard>[
        winCasual,
        lossCasual,
        drawCasual,
        winRanked,
        lossRanked,
        noResult,
      ];
}
