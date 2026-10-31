import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/arena_app.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/shell/arena_shell.dart';
import 'package:training_arena/theme/arena_tokens.dart';

void main() {
  testWidgets('shell shows Leaderboard/Battle/Profile and opens on Battle',
      (tester) async {
    await tester.pumpWidget(const ArenaApp());
    await tester.pumpAndSettle();

    final barFinder = find.byKey(const ValueKey('arena-bottom-nav'));
    expect(barFinder, findsOneWidget);

    final bar = tester.widget<NavigationBar>(barFinder);
    expect(bar.selectedIndex, ArenaTab.battle.index);
    expect(
      bar.destinations
          .map((destination) => (destination as NavigationDestination).label)
          .toList(),
      const ['Leaderboard', 'Battle', 'Profile'],
    );
    expect(find.byKey(const ValueKey('arena-page-battle')), findsOneWidget);
    expect(find.byKey(const ValueKey('arena-page-leaderboard')), findsNothing);
    expect(find.byKey(const ValueKey('arena-page-profile')), findsNothing);
  });

  testWidgets('tapping a destination switches the visible page',
      (tester) async {
    await tester.pumpWidget(const ArenaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('arena-tab-profile')));
    await tester.pumpAndSettle();

    var bar = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('arena-bottom-nav')),
    );
    expect(bar.selectedIndex, ArenaTab.profile.index);
    expect(find.byKey(const ValueKey('arena-page-profile')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('arena-tab-leaderboard')));
    await tester.pumpAndSettle();

    bar = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('arena-bottom-nav')),
    );
    expect(bar.selectedIndex, ArenaTab.leaderboard.index);
    expect(
      find.byKey(const ValueKey('arena-page-leaderboard')),
      findsOneWidget,
    );
  });

  testWidgets('shell colors are sourced from ArenaColors', (tester) async {
    await tester.pumpWidget(const ArenaApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = app.theme!;
    expect(theme.scaffoldBackgroundColor, ArenaColors.charcoal);
    expect(theme.colorScheme.primary, ArenaColors.lime);
    expect(theme.colorScheme.secondary, ArenaColors.violet);
    expect(theme.navigationBarTheme.indicatorColor, ArenaColors.lime);
    expect(theme.colorScheme.surface, ArenaColors.graphite);
    expect(theme.colorScheme.onSurface, ArenaColors.softWhite);
  });

  test('ArenaConfig defaults stay safe until the owner supplies values', () {
    const config = ArenaConfig.fromEnvironment;
    expect(config.linkHost, ArenaConfig.defaultLinkHost);
    expect(ArenaConfig.defaultLinkHost, 'example.invalid');
    expect(
      config.challengeLink('abcdef123456').toString(),
      'https://example.invalid/c/abcdef123456',
    );
    expect(config.hasSupabaseCredentials, isFalse);
    expect(config.cameraCountingEnabled, isFalse);
    expect(config.challengeLinksEnabled, isFalse);
    expect(config.rankedMatchmakingEnabled, isFalse);
    expect(config.resultSharingEnabled, isFalse);
  });
}
