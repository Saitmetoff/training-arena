/// Widget tests for the account surfaces.
///
/// Covered here: the profile shows only the contract fields and stays
/// readable at 200% text, the leaderboard marks the viewer lime and explains
/// the first-ranked-match rule, battle history shows confirmed receipts with
/// rating only when ranked, and the public player card exposes report/block
/// without ever rendering an email or token.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/account/runtime/account_controller.dart';
import 'package:training_arena/account/runtime/account_runtime.dart';
import 'package:training_arena/account/runtime/battle_history_controller.dart';
import 'package:training_arena/account/runtime/leaderboard_controller.dart';
import 'package:training_arena/account/ui/account_widgets.dart';
import 'package:training_arena/account/ui/battle_history_page.dart';
import 'package:training_arena/account/ui/leaderboard_tab.dart';
import 'package:training_arena/account/ui/player_card_sheet.dart';
import 'package:training_arena/account/ui/profile_tab.dart';
import 'package:training_arena/battle/ui/battle_widgets.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/theme/arena_theme.dart';
import 'package:training_arena/theme/arena_tokens.dart';

import 'fakes.dart';

class _WaitingGoogleAuth extends FakeArenaAuthGateway {
  final pending = Completer<ArenaAuthSession>();

  @override
  Future<ArenaAuthSession> signInWithGoogle() => pending.future;
}

AccountRuntime buildRuntime({
  FakeArenaAuthGateway? auth,
  FakeAccountApi? api,
  AccountController? controller,
  bool signedIn = true,
}) {
  final resolvedAuth = auth ?? FakeArenaAuthGateway();
  if (signedIn && resolvedAuth.restoredSession == null) {
    resolvedAuth.restoredSession = resolvedAuth.session;
  }
  final resolvedApi = api ?? FakeAccountApi();
  final resolvedController = controller ??
      AccountController(auth: resolvedAuth, api: resolvedApi);
  return AccountRuntime(
    controller: resolvedController,
    api: resolvedApi,
    auth: resolvedAuth,
    leaderboard: LeaderboardController(
      api: resolvedApi,
      viewerId: () => resolvedController.profile?.id,
    ),
    history: BattleHistoryController(api: resolvedApi),
    avatarPicker: FakeAvatarPicker(),
    prompts: FakeChallengeAuthPrompts(),
  );
}

Future<void> pumpSurface(
  WidgetTester tester,
  AccountRuntime runtime,
  Widget child, {
  double textScale = 1.0,
}) async {
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    AccountRuntimeScope(
      runtime: runtime,
      child: MaterialApp(
        theme: ArenaTheme.dark,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: widget!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpPlayerCard(
  WidgetTester tester,
  AccountRuntime runtime, {
  int? rank,
  String? matchId,
}) async {
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    AccountRuntimeScope(
      runtime: runtime,
      child: MaterialApp(
        theme: ArenaTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () {
                  showPlayerCardSheet(
                    context,
                    runtime: runtime,
                    userId: fakeOpponentId,
                    rank: rank,
                    matchId: matchId,
                  );
                },
                child: const Text('open card'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open card'));
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileTab', () {
    for (final provider in <String>['email', 'Google']) {
      testWidgets('$provider first sign-in saves the prompted username',
          (tester) async {
        final auth = FakeArenaAuthGateway();
        final api = FakeAccountApi(profile: fakeViewer(username: null));
        final runtime = buildRuntime(auth: auth, api: api, signedIn: false);
        await runtime.initialize();
        await pumpSurface(tester, runtime, const Scaffold(body: ProfileTab()));

        if (provider == 'email') {
          await tester.tap(find.byKey(const ValueKey('profile-sign-in-email')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('sign-in-email-field')),
            'player@private.invalid',
          );
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('sign-in-code-field')),
            '12345678',
          );
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await tester.tap(find.byKey(const ValueKey('profile-sign-in-google')));
        }
        await tester.pumpAndSettle();

        // The runtime notification has replaced the signed-out controls while
        // the first-sign-in username sheet is still open.
        expect(runtime.controller.signedIn, isTrue);
        expect(find.byKey(const ValueKey('profile-signed-out')), findsNothing);
        expect(
          find.byKey(const ValueKey('sign-in-username-field')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('sign-in-username-field')),
          'new_player',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(api.lastUsernameUpdate, 'new_player');
        expect(api.profile.username, 'new_player');
        expect(runtime.controller.profile?.username, 'new_player');
        expect(runtime.controller.usernameRequired, isFalse);
        expect(find.text('@new_player'), findsOneWidget);
        expect(find.byKey(const ValueKey('sign-in-username-field')), findsNothing);
        expect(auth.verifyCalls, provider == 'email' ? 1 : 0);
        expect(auth.googleCalls, provider == 'Google' ? 1 : 0);
      });
    }

    testWidgets('browser wait has a cancel action that enables email retry', (
      tester,
    ) async {
      final auth = _WaitingGoogleAuth();
      final runtime = buildRuntime(auth: auth, signedIn: false);
      await runtime.initialize();
      await pumpSurface(tester, runtime, const Scaffold(body: ProfileTab()));
      await tester.tap(find.byKey(const ValueKey('profile-sign-in-google')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-cancel-sign-in')));
      await tester.pumpAndSettle();
      expect(auth.clearLocalCalls, 1);
      expect(runtime.controller.busy, isFalse);
      await tester.tap(find.byKey(const ValueKey('profile-sign-in-email')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sign-in-email-field')), findsOneWidget);
      auth.pending.complete(auth.session);
      await tester.pumpAndSettle();
      expect(runtime.controller.signedIn, isFalse);
    });

    testWidgets('shows exactly the contract fields and actions',
        (tester) async {
      final auth = FakeArenaAuthGateway()..restoredSession = null;
      final api = FakeAccountApi();
      final runtime = buildRuntime(auth: auth, api: api);
      await runtime.initialize();

      await pumpSurface(tester, runtime, const ProfileTab());

      expect(find.text('@azizbek'), findsOneWidget);
      expect(find.text('Arena rating 1016'), findsOneWidget);
      expect(find.text('Ranked wins 1'), findsOneWidget);
      expect(find.text('Ranked battles 2'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Battle history'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // No unrelated social or fitness surfaces.
      for (final forbidden in <String>[
        'Followers',
        'Following',
        'Chat',
        'Messages',
        'Badges',
        'Training plan',
        'Coins',
        'Currency',
        'Level',
      ]) {
        expect(find.text(forbidden), findsNothing, reason: forbidden);
      }

      // The signed-in player is lime.
      final kicker = tester.widget<Text>(find.text('Signed-in player'));
      expect(kicker.style!.color, ArenaColors.lime);
    });

    testWidgets('reflows at 200% text size without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final auth = FakeArenaAuthGateway();
      final runtime = buildRuntime(auth: auth, api: FakeAccountApi());
      await runtime.initialize();

      await pumpSurface(
        tester,
        runtime,
        const ProfileTab(),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Edit profile'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Settings'),
        find.byType(ListView),
        const Offset(0, -80),
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('signed out offers only Google and email sign-in',
        (tester) async {
      final runtime = buildRuntime(signedIn: false);
      await runtime.initialize();

      await pumpSurface(tester, runtime, const ProfileTab());

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
      expect(find.textContaining('Avatar upload is optional'), findsOneWidget);
    });

    testWidgets('a first sign-in without a username asks for one in place',
        (tester) async {
      final api = FakeAccountApi(profile: fakeViewer(username: null));
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(tester, runtime, const ProfileTab());

      expect(find.text('Choose a username'), findsOneWidget);
      expect(find.text('Choose username'), findsOneWidget);
    });
  });

  group('LeaderboardTab', () {
    testWidgets('empty ladder explains when participation appears',
        (tester) async {
      final runtime = buildRuntime();
      await runtime.initialize();

      await pumpSurface(tester, runtime, const LeaderboardTab());

      expect(find.text('No ranked players yet'), findsOneWidget);
      expect(
        find.textContaining('first completed ranked match'),
        findsOneWidget,
      );
    });

    testWidgets('rows carry username, rating and viewer identity',
        (tester) async {
      final api = FakeAccountApi()
        ..leaderboardEntries = <ArenaLeaderboardEntry>[
          ArenaLeaderboardEntry(profile: fakeOpponent(), rank: 1),
          ArenaLeaderboardEntry(profile: fakeViewer(), rank: 2),
        ];
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(tester, runtime, const LeaderboardTab());

      expect(find.text('@zuhra'), findsOneWidget);
      expect(find.text('@azizbek'), findsOneWidget);
      expect(find.text('1060'), findsOneWidget);
      expect(find.text('Ranked players. Only server-confirmed ranked results '
          'change rating; friend challenges are casual.'), findsOneWidget);

      final viewerRow = tester.widget<LeaderboardRow>(
        find.byKey(const ValueKey('leaderboard-row-$fakeViewerId')),
      );
      final opponentRow = tester.widget<LeaderboardRow>(
        find.byKey(const ValueKey('leaderboard-row-$fakeOpponentId')),
      );
      expect(viewerRow.isViewer, isTrue);
      expect(opponentRow.isViewer, isFalse);

      final viewerIdentity = tester.widget<BattleIdentity>(
        find.descendant(
          of: find.byKey(const ValueKey('leaderboard-row-$fakeViewerId')),
          matching: find.byType(BattleIdentity),
        ),
      );
      final opponentIdentity = tester.widget<BattleIdentity>(
        find.descendant(
          of: find.byKey(const ValueKey('leaderboard-row-$fakeOpponentId')),
          matching: find.byType(BattleIdentity),
        ),
      );
      expect(viewerIdentity.accent, isFalse, reason: 'viewer is lime');
      expect(opponentIdentity.accent, isTrue, reason: 'opponent is violet');
    });

    testWidgets('the viewer row outside the top page is separated',
        (tester) async {
      final api = FakeAccountApi()
        ..leaderboardEntries = <ArenaLeaderboardEntry>[
          ArenaLeaderboardEntry(profile: fakeOpponent(), rank: 1),
          ArenaLeaderboardEntry(profile: fakeViewer(), rank: 137),
        ];
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(tester, runtime, const LeaderboardTab());

      expect(find.text('Your position'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('leaderboard-row-$fakeViewerId')),
        findsOneWidget,
      );
    });

    testWidgets('an offline refresh keeps the confirmed page visible',
        (tester) async {
      final api = FakeAccountApi()
        ..leaderboardEntries = <ArenaLeaderboardEntry>[
          ArenaLeaderboardEntry(profile: fakeOpponent(), rank: 1),
        ];
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(tester, runtime, const LeaderboardTab());
      expect(find.text('@zuhra'), findsOneWidget);

      api.leaderboardError = const AccountException.network();
      await runtime.leaderboard.load(force: true);
      await tester.pumpAndSettle();

      expect(find.text('You are offline'), findsOneWidget);
      expect(find.text('@zuhra'), findsOneWidget);
    });
  });

  group('BattleHistoryPage', () {
    testWidgets('empty history explains what will appear', (tester) async {
      final runtime = buildRuntime();
      await pumpSurface(
        tester,
        runtime,
        BattleHistoryPage(runtime: runtime),
      );

      expect(find.text('No battles yet'), findsOneWidget);
      expect(find.textContaining('after your first match'), findsOneWidget);
    });

    testWidgets('ranked receipt shows mode, scores and rating change',
        (tester) async {
      final api = FakeAccountApi()
        ..receipts = <ResultReceipt>[
          fakeReceipt(finishedAt: DateTime.utc(2026, 9, 18, 12)),
        ];
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(
        tester,
        runtime,
        BattleHistoryPage(runtime: runtime),
      );

      expect(find.text('Ranked'), findsOneWidget);
      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.text('Win'), findsOneWidget);
      expect(find.text('You beat @zuhra'), findsOneWidget);
      expect(find.text('You 26 — 23 @zuhra'), findsOneWidget);
      expect(find.text('Rating +8 · now 1024'), findsOneWidget);
    });

    testWidgets('receipt snapshots keep the confirmed identity after a rename',
        (tester) async {
      final api = FakeAccountApi()
        ..receipts = <ResultReceipt>[
          ResultReceipt(
            id: 'receipt-old',
            matchId: fakeMatchId,
            exercise: ArenaExercise.squats,
            mode: ArenaMatchMode.casual,
            players: <ArenaReceiptPlayer>[
              ArenaReceiptPlayer(
                profile: fakeViewer(username: 'old_name'),
                score: 20,
              ),
              ArenaReceiptPlayer(
                profile: fakeOpponent(username: 'old_opponent'),
                score: 19,
              ),
            ],
            outcome: ArenaMatchOutcome.win,
            winnerId: fakeViewerId,
          ),
        ]
        ..profile = fakeViewer(username: 'renamed_today');
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(
        tester,
        runtime,
        BattleHistoryPage(runtime: runtime),
      );

      expect(find.text('You beat @old_opponent'), findsOneWidget);
      expect(find.text('You 20 — 19 @old_opponent'), findsOneWidget);
      expect(find.textContaining('renamed_today'), findsNothing);
    });

    testWidgets('casual receipt never shows a rating change', (tester) async {
      final api = FakeAccountApi()
        ..receipts = <ResultReceipt>[
          fakeReceipt(
            mode: ArenaMatchMode.casual,
            outcome: ArenaMatchOutcome.draw,
            winnerId: null,
            viewerRatingChange: null,
            viewerRatingAfter: null,
          ),
        ];
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(
        tester,
        runtime,
        BattleHistoryPage(runtime: runtime),
      );

      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Draw — 26 each'), findsOneWidget);
      expect(find.textContaining('Rating'), findsNothing);
    });

    testWidgets('no-result receipt is labelled and explains nothing changed',
        (tester) async {
      final api = FakeAccountApi()
        ..receipts = <ResultReceipt>[
          fakeReceipt(
            mode: ArenaMatchMode.ranked,
            outcome: ArenaMatchOutcome.noResult,
            winnerId: null,
            viewerRatingChange: null,
            viewerRatingAfter: null,
            reason: 'service_outage',
          ),
        ];
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(
        tester,
        runtime,
        BattleHistoryPage(runtime: runtime),
      );

      expect(find.text('No result'), findsWidgets);
      expect(find.text('service_outage'), findsOneWidget);
      expect(find.textContaining('Rating'), findsNothing);
    });

    testWidgets('offline history offers a retry without inventing rows',
        (tester) async {
      final api = FakeAccountApi()
        ..historyError = const AccountException.network();
      final runtime = buildRuntime(api: api);
      await runtime.initialize();

      await pumpSurface(
        tester,
        runtime,
        BattleHistoryPage(runtime: runtime),
      );

      expect(find.text('You are offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No battles yet'), findsNothing);
    });
  });

  group('public player card', () {
    testWidgets('shows safe public identity, rating context and actions',
        (tester) async {
      final api = FakeAccountApi()
        ..publicProfiles = <String, ArenaProfile>{
          fakeOpponentId: fakeOpponent(),
        };
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime, rank: 3);

      expect(find.text('@zuhra'), findsOneWidget);
      expect(find.text('ranked #3'), findsOneWidget);
      expect(find.text('Arena rating 1060'), findsOneWidget);
      expect(find.text('Ranked wins 3'), findsOneWidget);
      expect(find.text('Ranked battles 4'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
      expect(api.lastPublicProfileId, fakeOpponentId);

      // No private identity ever reaches the card.
      expect(find.textContaining('@private'), findsNothing);
      expect(find.textContaining('private.invalid'), findsNothing);
      expect(find.textContaining('token'), findsNothing);
    });

    testWidgets('report validates the reason before sending', (tester) async {
      final api = FakeAccountApi();
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime);

      await tester.tap(find.byKey(const ValueKey('player-card-report')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('report-reason-field')),
        'ab',
      );
      await tester.tap(find.byKey(const ValueKey('report-send')));
      await tester.pumpAndSettle();

      expect(find.text('Describe the problem in a few words.'), findsOneWidget);
      expect(api.reportCalls, 0);

      await tester.enterText(
        find.byKey(const ValueKey('report-reason-field')),
        'inappropriate username',
      );
      await tester.tap(find.byKey(const ValueKey('report-send')));
      await tester.pumpAndSettle();

      expect(api.reportCalls, 1);
      expect(api.lastReportReason, 'inappropriate username');
      expect(api.lastReportTarget, fakeOpponentId);
      expect(find.text('Report sent.'), findsOneWidget);
    });

    testWidgets('report carries the match id only from a receipt',
        (tester) async {
      final api = FakeAccountApi();
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime, matchId: 'match-9');

      await tester.tap(find.byKey(const ValueKey('player-card-report')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('report-reason-field')),
        'left early',
      );
      await tester.tap(find.byKey(const ValueKey('report-send')));
      await tester.pumpAndSettle();

      expect(api.lastReportMatchId, 'match-9');
    });

    testWidgets('block confirms and can be undone from the card',
        (tester) async {
      final api = FakeAccountApi();
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime);

      await tester.tap(find.byKey(const ValueKey('player-card-block')));
      await tester.pumpAndSettle();
      expect(find.text('Block this player?'), findsOneWidget);
      expect(api.blockCalls, 0);

      await tester.tap(find.byKey(const ValueKey('player-block-confirm')));
      await tester.pumpAndSettle();

      expect(api.blockCalls, 1);
      expect(api.lastBlockTarget, fakeOpponentId);
      expect(
        find.textContaining('Their challenges and queue matches are hidden'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('player-card-unblock')));
      await tester.pumpAndSettle();

      expect(api.unblockCalls, 1);
      expect(find.text('Unblocked.'), findsOneWidget);
    });

    testWidgets('a deleted player shows the unavailable state',
        (tester) async {
      final api = FakeAccountApi()
        ..publicProfileError = const AccountException(
          'not_found',
          'This player is gone.',
        );
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime);

      expect(find.text('Player unavailable'), findsOneWidget);
      expect(find.text('Report'), findsNothing);
      expect(find.text('Block'), findsNothing);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      final api = FakeAccountApi()
        ..publicProfileError = const AccountException.network();
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime);

      expect(find.text('Could not load this player'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-retry')), findsOneWidget);

      api.publicProfileError = null;
      await tester.tap(find.byKey(const ValueKey('account-retry')));
      await tester.pumpAndSettle();

      expect(find.text('@zuhra'), findsOneWidget);
    });

    testWidgets('a signed-out viewer still gets no email or token surface',
        (tester) async {
      final api = FakeAccountApi();
      final runtime = buildRuntime(api: api);

      await pumpPlayerCard(tester, runtime);

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ');
      expect(rendered.contains(fakeAccessToken), isFalse);
      expect(rendered.contains(fakeRefreshToken), isFalse);
      expect(rendered.contains('@example'), isFalse);
    });
  });
}
