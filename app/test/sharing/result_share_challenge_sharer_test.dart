import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/ports/battle_challenge_sharer.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/sharing/fixtures/result_share_fixtures.dart';
import 'package:training_arena/sharing/result_share_challenge_sharer.dart';
import 'package:training_arena/sharing/result_share_models.dart';
import 'package:training_arena/sharing/result_share_service.dart';

import '../linking/fakes.dart';
import 'fakes.dart';
import 'test_receipts.dart';

void main() {
  late ValueNotifier<ArenaProfile?> viewer;
  late FakeResultSharePresenter presenter;
  late RecordingFallbackSharer fallback;
  late MemoryChallengeAnalyticsSink analytics;
  late ResultShareService service;
  late ResultShareChallengeSharer sharer;

  setUp(() {
    viewer = ValueNotifier<ArenaProfile?>(
      const ArenaProfile(id: 'u-you', username: 'azizbek'),
    );
    presenter = FakeResultSharePresenter();
    fallback = RecordingFallbackSharer();
    analytics = MemoryChallengeAnalyticsSink();
    service = ResultShareService(
      account: FakeResultShareAccountSource(),
      config: testConfig(),
      launcher: FakeResultShareLauncher(),
      clipboard: FakeResultShareClipboard(),
      analytics: analytics,
    );
    sharer = ResultShareChallengeSharer(
      service: service,
      presenter: presenter,
      viewer: viewer,
      fallback: fallback,
    );
  });

  tearDown(() {
    viewer.dispose();
  });

  test('a confirmed receipt opens the preview and claims no outcome itself',
      () async {
    final message = await sharer.shareChallenge(
      BattleChallengeInvite(receipt: testReceipt()),
    );
    expect(message, isNull);
    expect(fallback.invites, isEmpty);
    expect(presenter.requests, hasLength(1));
    expect(presenter.requests.single.viewerId, 'u-you');
    expect(presenter.requests.single.receipt.id, 'receipt-1');
  });

  test('an invite without a receipt never opens the result preview', () async {
    final message = await sharer.shareChallenge(
      const BattleChallengeInvite(),
    );
    expect(message, 'fallback text share');
    expect(fallback.invites, hasLength(1));
    expect(presenter.requests, isEmpty);
  });

  test('a local match with no server receipt falls back, never a card',
      () async {
    // A finished-looking local match with local scores but no server receipt
    // must not become a confirmed outcome.
    const localMatch = BattleMatch(
      id: 'local-match',
      exercise: ArenaExercise.pushUps,
      mode: ArenaMatchMode.casual,
      status: ArenaMatchStatus.finished,
      players: <BattleMatchPlayer>[
        BattleMatchPlayer(
          profile: ArenaProfile(id: 'u-you', username: 'azizbek'),
          score: 40,
        ),
        BattleMatchPlayer(
          profile: ArenaProfile(id: 'u-opp', username: 'zuhra'),
          score: 4,
        ),
      ],
    );
    expect(localMatch.hasReceipt, isFalse);
    final message = await sharer.shareChallenge(
      BattleChallengeInvite(receipt: localMatch.receipt),
    );
    expect(message, 'fallback text share');
    expect(presenter.requests, isEmpty);
  });

  test('signed-out sharing is refused with factual copy', () async {
    viewer.value = null;
    final message = await sharer.shareChallenge(
      BattleChallengeInvite(receipt: testReceipt()),
    );
    expect(message, 'Sign in before sharing a confirmed result.');
    expect(presenter.requests, isEmpty);
    expect(analytics.eventNames, contains(ResultShareAnalyticsEvent.blocked));
  });

  test('a malformed receipt is refused before any preview', () async {
    final message = await sharer.shareChallenge(
      BattleChallengeInvite(receipt: testReceipt(winnerId: null)),
    );
    expect(message, contains('cannot be shared'));
    expect(presenter.requests, isEmpty);
    final blocked = analytics.records.last;
    expect(blocked.event, ResultShareAnalyticsEvent.blocked);
    expect(blocked.properties['reason'], 'invalid_receipt');
  });

  test('a receipt that is not the viewer\'s is refused', () async {
    viewer.value = const ArenaProfile(id: 'u-stranger', username: 'other');
    final refused = await sharer.shareChallenge(
      BattleChallengeInvite(receipt: testReceipt()),
    );
    expect(refused, contains('does not belong'));
    expect(presenter.requests, isEmpty);
  });

  test('a presenter that cannot open returns factual copy', () async {
    presenter.result = false;
    final message = await sharer.shareChallenge(
      BattleChallengeInvite(receipt: testReceipt()),
    );
    expect(message, 'The share preview could not be opened.');
  });

  test('without a fallback an invite without a receipt stays honest',
      () async {
    final lonely = ResultShareChallengeSharer(
      service: service,
      presenter: presenter,
      viewer: viewer,
    );
    final message = await lonely.shareChallenge(
      const BattleChallengeInvite(),
    );
    expect(message, contains('No confirmed result to share'));
    expect(presenter.requests, isEmpty);
  });

  test('service.prepare returns the confirmed card type for a server receipt',
      () async {
    final card = await service.prepare(
      receipt: testReceipt(),
      viewerId: 'u-you',
    );
    expect(card, isA<ConfirmedResultShareCard>());
    expect(card.isPreview, isFalse);
  });

  test('fixture cards stay preview-only and cannot cross the share boundary',
      () {
    for (final fixture in ResultShareFixtures.all) {
      expect(fixture.isPreview, isTrue);
      expect(fixture, isA<PreviewResultShareCard>());
      expect(fixture, isNot(isA<ConfirmedResultShareCard>()));
    }
  });
}
