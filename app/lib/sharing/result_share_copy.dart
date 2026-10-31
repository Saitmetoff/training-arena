/// Factual copy for result share cards.
///
/// Voice rules from `design/arena/DESIGN_SYSTEM.md` §8: direct, calm,
/// factual, second person, no hype and no exclamation marks. The copy never
/// implies a rematch, an asynchronous score comparison, a replay of the old
/// match or a referral.
library;

import '../domain/arena_types.dart';
import 'result_share_models.dart';

/// Card copy builders. Pure functions so tests can pin exact strings.
abstract final class ResultShareCopy {
  /// Perspective-aware headline from the validated receipt view.
  static String headline({
    required ResultShareOutcome outcome,
    required ArenaReceiptPlayer opponent,
    required int margin,
  }) {
    final handle = handleFor(opponent);
    switch (outcome) {
      case ResultShareOutcome.win:
        return 'I BEAT $handle BY $margin';
      case ResultShareOutcome.loss:
        return '$handle BEAT ME BY $margin';
      case ResultShareOutcome.draw:
        return 'DRAW';
      case ResultShareOutcome.noResult:
        return 'NO RESULT';
    }
  }

  /// Caption shared with the image (and used by the text-only system share).
  ///
  /// Destination apps that strip captions still get the URL and QR inside
  /// the artwork, so the caption is never the only route to the challenge.
  static String caption(ResultShareCard card) {
    final opponent = handleFor(card.opponentPlayer);
    final exercise = card.exerciseLabel;
    final url = card.challengeUrl;
    switch (card.outcome) {
      case ResultShareOutcome.win:
        return 'I beat $opponent by ${_margin(card)} in a 60-second $exercise '
            'battle. New live challenge: $url';
      case ResultShareOutcome.loss:
        return '$opponent beat me by ${_margin(card)} in a 60-second $exercise '
            'battle. New live challenge: $url';
      case ResultShareOutcome.draw:
        return '$opponent and I drew ${card.viewerPlayer.score}'
            '–${card.opponentPlayer.score} in a 60-second $exercise battle. '
            'New live challenge: $url';
      case ResultShareOutcome.noResult:
        return 'No result in our 60-second $exercise battle, so no rating '
            'changed. New live challenge: $url';
    }
  }

  static int _margin(ResultShareCard card) =>
      (card.viewerPlayer.score - card.opponentPlayer.score).abs();

  /// Accessible label for the QR block; always carries the exact URL.
  static String qrSemanticLabel(ResultShareCard card) =>
      'QR code that opens the live challenge ${card.challengeUrl}';

  /// Text copied by "Copy challenge link": the real destination only.
  static String copyText(ResultShareCard card) => card.challengeUrl.toString();

  /// Fixed honesty note rendered under the card and in the preview.
  static const String newChallengeNote =
      'New live challenge. It never replays this match or compares old '
      'scores.';

  /// Honesty note for the read-only link semantics.
  static const String readOnlyNote =
      'Opening the link is read-only until your friend accepts.';

  /// Label that marks review fixtures as simulated.
  static const String previewNote =
      'Simulated fixture for design review. It is not a live challenge and '
      'cannot be shared.';

  /// Kicker above the headline.
  static String kicker(ResultShareCard card) => card.isPreview
      ? 'FAULT · SIMULATED FIXTURE'
      : card.outcome == ResultShareOutcome.noResult
          ? 'FAULT · CONFIRMED OUTCOME'
          : 'FAULT · CONFIRMED RESULT';

  /// Mode chip copy. Casual never implies a rating change.
  static String modeChip(ResultShareCard card) {
    if (!card.ranked) {
      return 'Casual · rating unchanged';
    }
    if (!card.hasConfirmedScores) {
      return 'Ranked · no rating change';
    }
    return 'Ranked · rating confirmed';
  }

  /// One spoken summary for the rendered card image. Contains exactly the
  /// facts visible in the artwork: outcome, exercise, both identities and
  /// scores, ranked rating, CTA, URL and short code.
  static String cardSemanticSummary(ResultShareCard card) {
    final buffer = StringBuffer(
      card.isPreview ? 'Simulated share card. ' : 'Confirmed result card. ',
    )
      ..write('${card.headline}. ')
      ..write('${card.exerciseLabel}, ${card.durationLabel}. ');
    if (card.hasConfirmedScores) {
      buffer
        ..write('${handleFor(card.viewerPlayer)} ')
        ..write('${card.viewerPlayer.score} reps. ')
        ..write('${handleFor(card.opponentPlayer)} ')
        ..write('${card.opponentPlayer.score} reps. ');
    } else {
      buffer.write('No confirmed score. ');
    }
    final rating = card.viewerRatingAfter;
    if (rating != null) {
      buffer.write('Your arena rating $rating');
      final change = card.viewerRatingChange;
      if (change != null && change != 0) {
        buffer.write(
          ', ${change > 0 ? 'up' : 'down'} ${change.abs()}',
        );
      }
      buffer.write('. ');
    } else if (!card.ranked) {
      buffer.write('Casual match, rating unchanged. ');
    }
    buffer
      ..write('${card.cta}. ')
      ..write('Challenge link ${card.challengeUrl}. ')
      ..write('Code ${card.readableCode}.');
    return buffer.toString();
  }
}
