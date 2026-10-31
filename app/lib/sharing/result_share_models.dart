/// Result-share card value objects.
///
/// A share card is built only from an immutable, server-confirmed
/// [ResultReceipt] (task `04`) plus the owner's confirmed challenge link.
/// There is deliberately no local-result constructor: a receipt-less match or
/// an invented score cannot become a `ConfirmedResultShareCard`, so it can
/// never be shared as a confirmed outcome.
///
/// The sharer is always the left, lime player and the opponent is always the
/// right, violet player. Headlines are perspective-aware and factual:
/// `I BEAT @zuhra BY 3`, `@zuhra BEAT ME BY 3`, `DRAW`, `NO RESULT`.
library;

import '../config/arena_config.dart';
import '../domain/arena_types.dart';
import '../linking/challenge_link.dart';
import '../linking/challenge_models.dart';
import 'result_share_copy.dart';

/// Export sizes fixed by task `09`.
///
/// The renderer lays out at [logicalWidth]×[logicalHeight] and exports at
/// [pixelRatio], producing exactly [pixelWidth]×[pixelHeight] pixels.
enum ResultShareFormat {
  /// Instagram/TikTok story export: 1080×1920.
  stories('Stories', '9:16', 1080, 1920),

  /// Feed export: 1080×1350.
  feed('Feed', '4:5', 1080, 1350);

  const ResultShareFormat(
    this.label,
    this.ratioLabel,
    this.pixelWidth,
    this.pixelHeight,
  );

  final String label;
  final String ratioLabel;
  final int pixelWidth;
  final int pixelHeight;

  /// Fixed export density; 540 logical px → 1080 physical px.
  static const double pixelRatio = 2;

  double get logicalWidth => pixelWidth / pixelRatio;

  double get logicalHeight => pixelHeight / pixelRatio;

  String get dimensionsLabel => '$pixelWidth×$pixelHeight';
}

/// Viewer-relative outcome of a confirmed receipt.
enum ResultShareOutcome {
  win,
  loss,
  draw,
  noResult;

  String get wire => switch (this) {
        ResultShareOutcome.win => 'win',
        ResultShareOutcome.loss => 'loss',
        ResultShareOutcome.draw => 'draw',
        ResultShareOutcome.noResult => 'no_result',
      };
}

/// Raised when a card cannot be prepared from confirmed data.
class ResultShareException implements Exception {
  const ResultShareException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ResultShareException($code): $message';
}

/// Validated, viewer-relative view of one confirmed receipt.
class ResultShareReceiptView {
  const ResultShareReceiptView({
    required this.viewerPlayer,
    required this.opponentPlayer,
    required this.outcome,
    required this.margin,
  });

  final ArenaReceiptPlayer viewerPlayer;
  final ArenaReceiptPlayer opponentPlayer;
  final ResultShareOutcome outcome;

  /// Absolute score difference; `0` for draws and no-result.
  final int margin;

  int get viewerScore => viewerPlayer.score;

  int get opponentScore => opponentPlayer.score;
}

/// Validates one receipt for sharing and derives the viewer-relative view.
///
/// Fails closed on anything the server could not have confirmed:
/// - only two player lines;
/// - the viewer must be one of them;
/// - a `win` must carry a winner id and a strictly higher winner score;
/// - a `draw` must carry equal scores and no winner;
/// - a `no_result` must not carry a winner and exposes no scores;
/// - scores are never negative, and ratings are only read for ranked
///   non-no-result receipts.
ResultShareReceiptView validateResultReceipt({
  required ResultReceipt receipt,
  required String viewerId,
}) {
  if (receipt.players.length != 2) {
    throw const ResultShareException(
      'invalid_receipt',
      'The receipt does not contain exactly two players, so it cannot be '
          'shared.',
    );
  }
  ArenaReceiptPlayer? viewer;
  ArenaReceiptPlayer? opponent;
  for (final player in receipt.players) {
    if (player.profile.id == viewerId) {
      viewer = player;
    } else {
      opponent = player;
    }
  }
  if (viewer == null || opponent == null) {
    throw const ResultShareException(
      'viewer_not_in_receipt',
      'This receipt does not belong to the signed-in player.',
    );
  }
  if (viewer.score < 0 || opponent.score < 0) {
    throw const ResultShareException(
      'invalid_receipt',
      'The receipt contains a negative score, so it cannot be shared.',
    );
  }

  switch (receipt.outcome) {
    case ArenaMatchOutcome.win:
      final winnerId = receipt.winnerId;
      if (winnerId == null) {
        throw const ResultShareException(
          'invalid_receipt',
          'The receipt claims a win without a server winner, so it cannot be '
              'shared.',
        );
      }
      final winner = winnerId == viewer.profile.id ? viewer : opponent;
      if (winnerId != viewer.profile.id && winnerId != opponent.profile.id) {
        throw const ResultShareException(
          'invalid_receipt',
          'The receipt winner is not one of the players, so it cannot be '
              'shared.',
        );
      }
      if (winner.score <=
          (winnerId == viewer.profile.id ? opponent.score : viewer.score)) {
        throw const ResultShareException(
          'invalid_receipt',
          'The receipt scores contradict the confirmed winner, so it cannot '
              'be shared.',
        );
      }
      final won = winnerId == viewer.profile.id;
      return ResultShareReceiptView(
        viewerPlayer: viewer,
        opponentPlayer: opponent,
        outcome: won ? ResultShareOutcome.win : ResultShareOutcome.loss,
        margin: (viewer.score - opponent.score).abs(),
      );
    case ArenaMatchOutcome.draw:
      if (receipt.winnerId != null) {
        throw const ResultShareException(
          'invalid_receipt',
          'The receipt claims a draw and a winner, so it cannot be shared.',
        );
      }
      if (viewer.score != opponent.score) {
        throw const ResultShareException(
          'invalid_receipt',
          'The receipt scores contradict the confirmed draw, so it cannot be '
              'shared.',
        );
      }
      return ResultShareReceiptView(
        viewerPlayer: viewer,
        opponentPlayer: opponent,
        outcome: ResultShareOutcome.draw,
        margin: 0,
      );
    case ArenaMatchOutcome.noResult:
      if (receipt.winnerId != null) {
        throw const ResultShareException(
          'invalid_receipt',
          'The receipt claims no result and a winner, so it cannot be '
              'shared.',
        );
      }
      return ResultShareReceiptView(
        viewerPlayer: viewer,
        opponentPlayer: opponent,
        outcome: ResultShareOutcome.noResult,
        margin: 0,
      );
  }
}

/// Base card model shared by confirmed and preview cards.
sealed class ResultShareCard {
  const ResultShareCard._({
    required this.receipt,
    required this.viewerPlayer,
    required this.opponentPlayer,
    required this.outcome,
    required this.headline,
    required this.exerciseLabel,
    required this.mode,
    required this.challengeUrl,
    required this.readableCode,
    this.noResultReason,
    this.isPreview = false,
  });

  /// Immutable server receipt this card renders. Never re-derived.
  final ResultReceipt receipt;

  /// Receipt snapshot of the sharer; always rendered left and lime.
  final ArenaReceiptPlayer viewerPlayer;

  /// Receipt snapshot of the opponent; always rendered right and violet.
  final ArenaReceiptPlayer opponentPlayer;

  final ResultShareOutcome outcome;

  /// Perspective-aware factual headline, for example `I BEAT @zuhra BY 3`.
  final String headline;

  final String exerciseLabel;

  final ArenaMatchMode mode;

  /// Real short challenge URL (`https://<host>/c/<token>`) for a new live
  /// casual battle. Never a match replay.
  final Uri challengeUrl;

  /// Readable short code, grouped in fours.
  final String readableCode;

  /// Server explanation for a no-result; null otherwise.
  final String? noResultReason;

  /// True for review fixtures. Preview cards are render/export-only and are
  /// rejected by the share service.
  final bool isPreview;

  /// Duration is fixed by the product contract.
  String get durationLabel => '60 seconds';

  bool get ranked => mode == ArenaMatchMode.ranked;

  bool get hasConfirmedScores => outcome != ResultShareOutcome.noResult;

  /// Ranked rating after the match; null for casual and no-result receipts.
  int? get viewerRatingAfter =>
      ranked && hasConfirmedScores ? viewerPlayer.ratingAfter : null;

  int? get viewerRatingChange =>
      ranked && hasConfirmedScores ? viewerPlayer.ratingChange : null;

  int? get opponentRatingAfter =>
      ranked && hasConfirmedScores ? opponentPlayer.ratingAfter : null;

  int? get opponentRatingChange =>
      ranked && hasConfirmedScores ? opponentPlayer.ratingChange : null;

  /// Exact `@username` from the receipt snapshot, or a factual fallback when
  /// the account never chose one. Never invented.
  String get opponentName => handleFor(opponentPlayer);

  /// `CHALLENGE @zuhra`; the fixed word is uppercase, the handle keeps its
  /// exact case so identity stays readable.
  String get cta => ctaFor(opponentPlayer);

  /// Caption shared with the image and used by the system share action.
  String get caption => ResultShareCopy.caption(this);

  /// QR payload: always the same URL as the visible link.
  String get qrPayload => challengeUrl.toString();

  /// Accessible label for the QR block.
  String get qrSemanticLabel => ResultShareCopy.qrSemanticLabel(this);

  /// Text copied by "Copy challenge link".
  String get copyText => ResultShareCopy.copyText(this);

  /// `Mode` helper for analytics; no identity, score, token or URL.
  String get analyticsMode => mode.wire;

  String get analyticsOutcome => outcome.wire;
}

/// A card built only by [confirmResultShareCard] from confirmed data.
final class ConfirmedResultShareCard extends ResultShareCard {
  const ConfirmedResultShareCard._({
    required super.receipt,
    required super.viewerPlayer,
    required super.opponentPlayer,
    required super.outcome,
    required super.headline,
    required super.exerciseLabel,
    required super.mode,
    required super.challengeUrl,
    required super.readableCode,
    super.noResultReason,
  }) : super._();
}

/// Review-only card. Never passes the share service boundary.
final class PreviewResultShareCard extends ResultShareCard {
  const PreviewResultShareCard({
    required super.receipt,
    required super.viewerPlayer,
    required super.opponentPlayer,
    required super.outcome,
    required super.headline,
    required super.exerciseLabel,
    required super.mode,
    required super.challengeUrl,
    required super.readableCode,
    super.noResultReason,
  }) : super._(isPreview: true);
}

/// Builds the only production card type from a confirmed receipt.
///
/// [account] is the owner's confirmed account snapshot; its link token is the
/// identity the challenge URL carries. [config] supplies the HTTPS link host.
/// Nothing here is generated locally: a missing/blank token or an unparseable
/// link fails closed.
ConfirmedResultShareCard confirmResultShareCard({
  required ResultReceipt receipt,
  required String viewerId,
  required ChallengeAccountSnapshot account,
  required ArenaConfig config,
}) {
  final view = validateResultReceipt(receipt: receipt, viewerId: viewerId);

  final username = account.profile.username?.trim();
  if (username == null || username.isEmpty) {
    throw const ResultShareException(
      'username_required',
      'Choose a username before sharing a challenge.',
    );
  }
  final token = account.link.token.trim();
  if (token.isEmpty) {
    throw const ResultShareException(
      'link_unavailable',
      'The arena did not return a challenge link. Reconnect and try again.',
    );
  }
  final url = config.challengeLink(token);
  final parsed = ChallengeLink.tryParse(url, expectedHost: config.linkHost);
  if (parsed == null || url.scheme != 'https') {
    throw const ResultShareException(
      'invalid_link',
      'The challenge link could not be built from the server link, so nothing '
          'was shared.',
    );
  }

  return ConfirmedResultShareCard._(
    receipt: receipt,
    viewerPlayer: view.viewerPlayer,
    opponentPlayer: view.opponentPlayer,
    outcome: view.outcome,
    headline: ResultShareCopy.headline(
      outcome: view.outcome,
      opponent: view.opponentPlayer,
      margin: view.margin,
    ),
    exerciseLabel: receipt.exercise.label,
    mode: receipt.mode,
    challengeUrl: url,
    readableCode: parsed.readableCode,
    noResultReason: view.outcome == ResultShareOutcome.noResult
        ? receipt.reason
        : null,
  );
}

/// Builds a review-only card from structurally valid data.
///
/// Preview cards render and export in tests and design review but are
/// rejected by the share service because only
/// [ConfirmedResultShareCard] crosses the share boundary.
PreviewResultShareCard previewResultShareCard({
  required ResultReceipt receipt,
  required String viewerId,
  required Uri challengeUrl,
  required String readableCode,
}) {
  final view = validateResultReceipt(receipt: receipt, viewerId: viewerId);
  return PreviewResultShareCard(
    receipt: receipt,
    viewerPlayer: view.viewerPlayer,
    opponentPlayer: view.opponentPlayer,
    outcome: view.outcome,
    headline: ResultShareCopy.headline(
      outcome: view.outcome,
      opponent: view.opponentPlayer,
      margin: view.margin,
    ),
    exerciseLabel: receipt.exercise.label,
    mode: receipt.mode,
    challengeUrl: challengeUrl,
    readableCode: readableCode,
    noResultReason: view.outcome == ResultShareOutcome.noResult
        ? receipt.reason
        : null,
  );
}

/// `@username` for a receipt snapshot, or the factual fallback name.
String handleFor(ArenaReceiptPlayer player) {
  final username = player.profile.username?.trim();
  if (username == null || username.isEmpty) {
    return player.profile.displayName;
  }
  return '@$username';
}

/// Prominent card CTA for the opponent identity.
String ctaFor(ArenaReceiptPlayer opponent) {
  final username = opponent.profile.username?.trim();
  if (username == null || username.isEmpty) {
    return 'CHALLENGE OPPONENT';
  }
  return 'CHALLENGE @$username';
}
