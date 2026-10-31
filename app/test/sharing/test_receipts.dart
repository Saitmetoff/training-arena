/// Shared receipt builders for result-sharing tests.
library;

import 'package:training_arena/domain/arena_types.dart';

const ArenaProfile testViewerProfile = ArenaProfile(
  id: 'u-you',
  username: 'azizbek',
  rating: 1042,
);

const ArenaProfile testOpponentProfile = ArenaProfile(
  id: 'u-opp',
  username: 'zuhra',
  rating: 1060,
);

ArenaReceiptPlayer receiptPlayer(
  ArenaProfile profile,
  int score, {
  int? ratingAfter,
  int? ratingChange,
}) {
  return ArenaReceiptPlayer(
    profile: profile,
    score: score,
    ratingAfter: ratingAfter,
    ratingChange: ratingChange,
  );
}

ResultReceipt testReceipt({
  String id = 'receipt-1',
  String matchId = 'match-1',
  ArenaExercise exercise = ArenaExercise.pushUps,
  ArenaMatchMode mode = ArenaMatchMode.casual,
  ArenaReceiptPlayer? viewer,
  ArenaReceiptPlayer? opponent,
  ArenaMatchOutcome outcome = ArenaMatchOutcome.win,
  String? winnerId = 'u-you',
  String? reason,
  DateTime? finishedAt,
}) {
  return ResultReceipt(
    id: id,
    matchId: matchId,
    exercise: exercise,
    mode: mode,
    players: <ArenaReceiptPlayer>[
      viewer ?? receiptPlayer(testViewerProfile, 26),
      opponent ?? receiptPlayer(testOpponentProfile, 23),
    ],
    outcome: outcome,
    winnerId: winnerId,
    reason: reason,
    finishedAt: finishedAt ?? DateTime.utc(2026, 9, 18, 12),
  );
}
