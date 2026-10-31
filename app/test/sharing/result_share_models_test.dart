import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/sharing/fixtures/result_share_fixtures.dart';
import 'package:training_arena/sharing/result_share_copy.dart';
import 'package:training_arena/sharing/result_share_models.dart';

import '../linking/fakes.dart';
import 'test_receipts.dart';

void main() {
  const account = ChallengeAccountSnapshot(
    profile: ArenaProfile(id: 'u-you', username: 'azizbek'),
    link: ChallengeLinkInfo(token: 'ab12cd34ef56', code: 'ab12cd34ef56'),
  );

  ConfirmedResultShareCard confirm(
    ResultReceipt receipt, {
    String viewerId = 'u-you',
    ChallengeAccountSnapshot? snapshot,
    ArenaConfig? config,
  }) {
    return confirmResultShareCard(
      receipt: receipt,
      viewerId: viewerId,
      account: snapshot ?? account,
      config: config ?? testConfig(),
    );
  }

  group('confirmResultShareCard', () {
    test('win headline is perspective-aware and exact', () {
      final card = confirm(testReceipt());
      expect(card.outcome, ResultShareOutcome.win);
      expect(card.headline, 'I BEAT @zuhra BY 3');
      expect(card.isPreview, isFalse);
      expect(card.exerciseLabel, 'Push-ups');
      expect(card.durationLabel, '60 seconds');
      expect(card.viewerPlayer.score, 26);
      expect(card.opponentPlayer.score, 23);
    });

    test('loss swaps perspective without swapping panels', () {
      final card = confirm(testReceipt(
        viewer: receiptPlayer(testViewerProfile, 18),
        opponent: receiptPlayer(testOpponentProfile, 24),
        winnerId: 'u-opp',
      ));
      expect(card.outcome, ResultShareOutcome.loss);
      expect(card.headline, '@zuhra BEAT ME BY 6');
      expect(card.viewerPlayer.profile.id, 'u-you');
      expect(card.opponentPlayer.profile.id, 'u-opp');
    });

    test('draw headline is DRAW with equal scores', () {
      final card = confirm(testReceipt(
        viewer: receiptPlayer(testViewerProfile, 24),
        opponent: receiptPlayer(testOpponentProfile, 24),
        outcome: ArenaMatchOutcome.draw,
        winnerId: null,
      ));
      expect(card.outcome, ResultShareOutcome.draw);
      expect(card.headline, 'DRAW');
      expect(card.hasConfirmedScores, isTrue);
    });

    test('no-result exposes no scores and no rating', () {
      final card = confirm(testReceipt(
        mode: ArenaMatchMode.ranked,
        viewer: receiptPlayer(testViewerProfile, 12),
        opponent: receiptPlayer(testOpponentProfile, 9),
        outcome: ArenaMatchOutcome.noResult,
        winnerId: null,
        reason: 'service_outage',
      ));
      expect(card.outcome, ResultShareOutcome.noResult);
      expect(card.headline, 'NO RESULT');
      expect(card.hasConfirmedScores, isFalse);
      expect(card.viewerRatingAfter, isNull);
      expect(card.viewerRatingChange, isNull);
      expect(card.noResultReason, 'service_outage');
    });

    test('ranked receipts carry the confirmed rating after-values', () {
      final card = confirm(testReceipt(
        mode: ArenaMatchMode.ranked,
        viewer: receiptPlayer(testViewerProfile, 31,
            ratingAfter: 1058, ratingChange: 16),
        opponent: receiptPlayer(testOpponentProfile, 28,
            ratingAfter: 1044, ratingChange: -16),
      ));
      expect(card.ranked, isTrue);
      expect(card.viewerRatingAfter, 1058);
      expect(card.viewerRatingChange, 16);
      expect(card.opponentRatingAfter, 1044);
      expect(card.opponentRatingChange, -16);
    });

    test('casual receipts never expose a rating change', () {
      final card = confirm(testReceipt(
        viewer: receiptPlayer(testViewerProfile, 31,
            ratingAfter: 1058, ratingChange: 16),
        opponent: receiptPlayer(testOpponentProfile, 28,
            ratingAfter: 1044, ratingChange: -16),
      ));
      expect(card.ranked, isFalse);
      expect(card.viewerRatingAfter, isNull);
      expect(card.viewerRatingChange, isNull);
      expect(card.opponentRatingAfter, isNull);
      expect(ResultShareCopy.modeChip(card), 'Casual · rating unchanged');
    });

    test('builds the configured challenge URL and readable code', () {
      final card = confirm(testReceipt());
      expect(
        card.challengeUrl.toString(),
        'https://example.invalid/c/ab12cd34ef56',
      );
      expect(card.readableCode, 'AB12-CD34-EF56');
      expect(card.qrPayload, card.challengeUrl.toString());
      expect(card.copyText, card.challengeUrl.toString());
      expect(card.cta, 'CHALLENGE @zuhra');
    });

    test('caption mentions the new challenge and never promises a rematch',
        () {
      final card = confirm(testReceipt());
      final caption = card.caption;
      expect(caption, contains('I beat @zuhra by 3'));
      expect(caption, contains('60-second Push-ups battle'));
      expect(caption, contains('New live challenge:'));
      expect(caption, contains(card.challengeUrl.toString()));
      expect(caption.toLowerCase(), isNot(contains('rematch')));
      expect(caption.toLowerCase(), isNot(contains('replay')));
      expect(caption.toLowerCase(), isNot(contains('beat this score')));
      expect(caption.toLowerCase(), isNot(contains('async')));
    });

    test('semantic summary carries outcome, scores, CTA, URL and code', () {
      final card = confirm(testReceipt());
      final summary = ResultShareCopy.cardSemanticSummary(card);
      expect(summary, contains('Confirmed result card.'));
      expect(summary, contains('I BEAT @zuhra BY 3'));
      expect(summary, contains('26 reps'));
      expect(summary, contains('23 reps'));
      expect(summary, contains('CHALLENGE @zuhra'));
      expect(summary, contains(card.challengeUrl.toString()));
      expect(summary, contains(card.readableCode));
    });

    test('missing username refuses to invent a handle', () {
      expect(
        () => confirm(
          testReceipt(),
          snapshot: const ChallengeAccountSnapshot(
            profile: ArenaProfile(id: 'u-you'),
            link: ChallengeLinkInfo(token: 'ab12cd34ef56', code: 'ab12cd34ef56'),
          ),
        ),
        throwsA(
          isA<ResultShareException>()
              .having((error) => error.code, 'code', 'username_required'),
        ),
      );
    });

    test('blank link token fails closed', () {
      expect(
        () => confirm(
          testReceipt(),
          snapshot: const ChallengeAccountSnapshot(
            profile: ArenaProfile(id: 'u-you', username: 'azizbek'),
            link: ChallengeLinkInfo(token: '', code: ''),
          ),
        ),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('a token that cannot form a challenge URL fails closed', () {
      expect(
        () => confirm(
          testReceipt(),
          snapshot: const ChallengeAccountSnapshot(
            profile: ArenaProfile(id: 'u-you', username: 'azizbek'),
            link: ChallengeLinkInfo(token: 'x', code: 'x'),
          ),
        ),
        throwsA(
          isA<ResultShareException>()
              .having((error) => error.code, 'code', 'invalid_link'),
        ),
      );
    });

    test('viewer must be a receipt player', () {
      expect(
        () => confirm(testReceipt(), viewerId: 'u-stranger'),
        throwsA(
          isA<ResultShareException>()
              .having((error) => error.code, 'code', 'viewer_not_in_receipt'),
        ),
      );
    });
  });

  group('unconfirmed and malformed receipts cannot be shared', () {
    test('win without a server winner id is rejected', () {
      expect(
        () => confirm(testReceipt(winnerId: null)),
        throwsA(
          isA<ResultShareException>()
              .having((error) => error.code, 'code', 'invalid_receipt'),
        ),
      );
    });

    test('win whose winner is not a player is rejected', () {
      expect(
        () => confirm(testReceipt(winnerId: 'u-someone-else')),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('win whose winner has the lower score is rejected', () {
      expect(
        () => confirm(testReceipt(
          viewer: receiptPlayer(testViewerProfile, 10),
          opponent: receiptPlayer(testOpponentProfile, 30),
          winnerId: 'u-you',
        )),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('draw with unequal scores is rejected', () {
      expect(
        () => confirm(testReceipt(
          viewer: receiptPlayer(testViewerProfile, 24),
          opponent: receiptPlayer(testOpponentProfile, 22),
          outcome: ArenaMatchOutcome.draw,
          winnerId: null,
        )),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('draw with a winner is rejected', () {
      expect(
        () => confirm(testReceipt(
          viewer: receiptPlayer(testViewerProfile, 24),
          opponent: receiptPlayer(testOpponentProfile, 24),
          outcome: ArenaMatchOutcome.draw,
          winnerId: 'u-you',
        )),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('no-result with a winner is rejected', () {
      expect(
        () => confirm(testReceipt(
          outcome: ArenaMatchOutcome.noResult,
          winnerId: 'u-you',
        )),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('negative scores are rejected', () {
      expect(
        () => confirm(testReceipt(
          viewer: receiptPlayer(testViewerProfile, -1),
        )),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('a receipt without exactly two players is rejected', () {
      final receipt = testReceipt();
      final malformed = ResultReceipt(
        id: receipt.id,
        matchId: receipt.matchId,
        exercise: receipt.exercise,
        mode: receipt.mode,
        players: <ArenaReceiptPlayer>[receipt.players.first],
        outcome: receipt.outcome,
        winnerId: receipt.winnerId,
      );
      expect(
        () => confirm(malformed),
        throwsA(isA<ResultShareException>()),
      );
    });
  });

  group('fixtures', () {
    test('every fixture is preview-only and never confirmed', () {
      for (final card in ResultShareFixtures.all) {
        expect(card, isA<PreviewResultShareCard>());
        expect(card.isPreview, isTrue);
        expect(ResultShareCopy.kicker(card), contains('SIMULATED FIXTURE'));
      }
    });

    test('fixtures cover win, loss, draw, ranked, casual and no-result', () {
      final outcomes =
          ResultShareFixtures.all.map((card) => card.outcome).toSet();
      expect(
        outcomes,
        <ResultShareOutcome>{
          ResultShareOutcome.win,
          ResultShareOutcome.loss,
          ResultShareOutcome.draw,
          ResultShareOutcome.noResult,
        },
      );
      expect(
        ResultShareFixtures.all.map((card) => card.mode).toSet(),
        <ArenaMatchMode>{ArenaMatchMode.casual, ArenaMatchMode.ranked},
      );
      expect(ResultShareFixtures.winRanked.ranked, isTrue);
      expect(ResultShareFixtures.winRanked.viewerRatingAfter, 1058);
      expect(ResultShareFixtures.winCasual.viewerRatingAfter, isNull);
      expect(
        ResultShareFixtures.noResult.hasConfirmedScores,
        isFalse,
      );
    });

    test('fixture URLs stay on the configured preview host', () {
      for (final card in ResultShareFixtures.all) {
        expect(card.challengeUrl.host, 'example.invalid');
        expect(card.challengeUrl.path, '/c/${ResultShareFixtures.token}');
      }
    });
  });
}
