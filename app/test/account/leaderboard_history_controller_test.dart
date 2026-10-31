/// Leaderboard and battle-history controller tests.
///
/// Both lists are server-confirmed only: a failed refresh keeps the last
/// confirmed page, a sign-out resets to empty, and no row is ever invented,
/// reordered or re-rated on the client.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/account/runtime/battle_history_controller.dart';
import 'package:training_arena/account/runtime/leaderboard_controller.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fakes.dart';

void main() {
  group('LeaderboardController', () {
    late FakeAccountApi api;
    late LeaderboardController controller;

    setUp(() {
      api = FakeAccountApi();
      controller = LeaderboardController(
        api: api,
        viewerId: () => fakeViewerId,
      );
    });

    tearDown(() => controller.dispose());

    test('loads exactly the confirmed rows', () async {
      api.leaderboardEntries = <ArenaLeaderboardEntry>[
        ArenaLeaderboardEntry(profile: fakeOpponent(), rank: 1),
        ArenaLeaderboardEntry(profile: fakeViewer(), rank: 2),
      ];

      await controller.load();

      expect(controller.status, AccountLoadStatus.ready);
      expect(controller.entries.length, 2);
      expect(controller.entries.first.profile.username, 'zuhra');
      expect(controller.viewerEntry!.rank, 2);
      expect(controller.viewerOutsideTopPage, isFalse);
    });

    test('an empty ladder is an honest empty state, not an error', () async {
      await controller.load();
      expect(controller.status, AccountLoadStatus.empty);
      expect(controller.entries, isEmpty);
    });

    test('the viewer row outside the top page is surfaced as-is', () async {
      api.leaderboardEntries = <ArenaLeaderboardEntry>[
        ArenaLeaderboardEntry(profile: fakeOpponent(), rank: 1),
        ArenaLeaderboardEntry(profile: fakeViewer(), rank: 137),
      ];

      await controller.load();

      expect(controller.viewerOutsideTopPage, isTrue);
      expect(controller.viewerEntry!.profile.id, fakeViewerId);
      expect(controller.viewerEntry!.rank, 137);
    });

    test('an offline refresh keeps the last confirmed page', () async {
      api.leaderboardEntries = <ArenaLeaderboardEntry>[
        ArenaLeaderboardEntry(profile: fakeViewer(), rank: 4),
      ];
      await controller.load();

      api.leaderboardError = const AccountException.network();
      await controller.load(force: true);

      expect(controller.status, AccountLoadStatus.offline);
      expect(controller.message, contains('offline'));
      expect(controller.entries.length, 1);
      expect(controller.entries.single.rank, 4);
    });

    test('a server error is not retryable and keeps the confirmed page',
        () async {
      api.leaderboardEntries = <ArenaLeaderboardEntry>[
        ArenaLeaderboardEntry(profile: fakeViewer(), rank: 4),
      ];
      await controller.load();

      api.leaderboardError = const AccountException(
        'internal_error',
        'The arena is unavailable right now.',
        statusCode: 500,
      );
      await controller.load(force: true);

      expect(controller.status, AccountLoadStatus.offline);
      expect(controller.entries.length, 1);
    });

    test('an unconfigured build reports the flag without inventing rows',
        () async {
      api.leaderboardError = const AccountException.unconfigured();
      await controller.load();

      expect(controller.status, AccountLoadStatus.unconfigured);
      expect(controller.entries, isEmpty);
    });

    test('reset drops every row and goes back to initial', () async {
      api.leaderboardEntries = <ArenaLeaderboardEntry>[
        ArenaLeaderboardEntry(profile: fakeViewer(), rank: 4),
      ];
      await controller.load();

      controller.reset();

      expect(controller.status, AccountLoadStatus.initial);
      expect(controller.entries, isEmpty);
      expect(controller.viewerEntry, isNull);
    });
  });

  group('BattleHistoryController', () {
    late FakeAccountApi api;
    late BattleHistoryController controller;

    setUp(() {
      api = FakeAccountApi();
      controller = BattleHistoryController(api: api);
    });

    tearDown(() => controller.dispose());

    test('loads confirmed receipts unchanged', () async {
      api.receipts = <ResultReceipt>[
        fakeReceipt(id: 'r1'),
        fakeReceipt(
          id: 'r2',
          mode: ArenaMatchMode.casual,
          outcome: ArenaMatchOutcome.draw,
          winnerId: null,
        ),
      ];

      await controller.load();

      expect(controller.status, AccountLoadStatus.ready);
      expect(controller.receipts.length, 2);
      expect(controller.receipts.first.mode, ArenaMatchMode.ranked);
      expect(controller.receipts.last.mode, ArenaMatchMode.casual);
      expect(controller.receipts.last.players.first.ratingChange, isNull);
    });

    test('an empty history is an honest empty state', () async {
      await controller.load();
      expect(controller.status, AccountLoadStatus.empty);
      expect(controller.receipts, isEmpty);
    });

    test('an offline refresh keeps the last confirmed receipts', () async {
      api.receipts = <ResultReceipt>[fakeReceipt(id: 'r1')];
      await controller.load();

      api.historyError = const AccountException.network();
      await controller.load(force: true);

      expect(controller.status, AccountLoadStatus.offline);
      expect(controller.receipts.length, 1);
      expect(controller.receipts.single.id, 'r1');
    });

    test('reset drops every receipt on sign-out', () async {
      api.receipts = <ResultReceipt>[fakeReceipt(id: 'r1')];
      await controller.load();

      controller.reset();

      expect(controller.status, AccountLoadStatus.initial);
      expect(controller.receipts, isEmpty);
    });
  });
}
