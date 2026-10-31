/// Tests for the public page links in Settings.
///
/// Covered here: the URL construction and the fail-closed placeholder host,
/// the three buttons that reach the privacy policy, support page and the
/// external deletion resource, and the honest notice when the pages are not
/// published yet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/account/runtime/account_controller.dart';
import 'package:training_arena/account/runtime/account_runtime.dart';
import 'package:training_arena/account/runtime/battle_history_controller.dart';
import 'package:training_arena/account/runtime/leaderboard_controller.dart';
import 'package:training_arena/account/ui/public_pages.dart';
import 'package:training_arena/account/ui/settings_page.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/theme/arena_theme.dart';

import 'fakes.dart';

class _RecordingLauncher implements PublicPageLauncher {
  final List<Uri> opened = <Uri>[];
  bool result = true;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return result;
  }
}

AccountRuntime buildRuntime({FakeAccountApi? api}) {
  final auth = FakeArenaAuthGateway()..restoredSession = null;
  final resolvedApi = api ?? FakeAccountApi();
  final controller = AccountController(auth: auth, api: resolvedApi);
  return AccountRuntime(
    controller: controller,
    api: resolvedApi,
    auth: auth,
    leaderboard: LeaderboardController(
      api: resolvedApi,
      viewerId: () => controller.profile?.id,
    ),
    history: BattleHistoryController(api: resolvedApi),
    avatarPicker: FakeAvatarPicker(),
    prompts: FakeChallengeAuthPrompts(),
  );
}

Future<void> pumpSettings(
  WidgetTester tester,
  AccountRuntime runtime, {
  PublicPages? pages,
}) async {
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    AccountRuntimeScope(
      runtime: runtime,
      child: MaterialApp(
        theme: ArenaTheme.dark,
        home: SettingsPage(runtime: runtime, publicPages: pages),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ArenaConfig configFor(String publicUrl) => ArenaConfig(
      publicUrl: publicUrl,
      linkHost: 'arena.example',
      supabaseUrl: 'https://project.example',
      supabaseAnonKey: 'anon-key',
    );

void main() {
  group('PublicPages', () {
    test('builds the three documented page URLs on a real host', () {
      final pages = PublicPages(
        config: configFor('https://arena.example'),
        launcher: _RecordingLauncher(),
      );
      expect(pages.configured, isTrue);
      expect(pages.privacyUrl.toString(),
          'https://arena.example/privacy.html');
      expect(pages.supportUrl.toString(),
          'https://arena.example/support.html');
      expect(pages.deletionRequestUrl.toString(),
          'https://arena.example/delete-account.html');
    });

    test('trims a trailing slash without doubling it', () {
      final pages = PublicPages(
        config: configFor('https://arena.example/'),
        launcher: _RecordingLauncher(),
      );
      expect(pages.privacyUrl.toString(),
          'https://arena.example/privacy.html');
    });

    test('fails closed on the placeholder and empty hosts', () async {
      final launcher = _RecordingLauncher();
      for (final host in ['https://example.invalid', '', 'http://arena.example']) {
        final pages = PublicPages(
          config: configFor(host),
          launcher: launcher,
        );
        expect(pages.configured, isFalse, reason: host);
        expect(await pages.open(pages.privacyUrl), isFalse);
      }
      expect(launcher.opened, isEmpty);
    });
  });

  group('SettingsPage public links', () {
    testWidgets('opens the privacy, support and deletion pages',
        (tester) async {
      final runtime = buildRuntime();
      final launcher = _RecordingLauncher();
      final pages = PublicPages(
        config: configFor('https://arena.example'),
        launcher: launcher,
      );
      await pumpSettings(tester, runtime, pages: pages);

      for (final key in const [
        'settings-privacy-policy',
        'settings-support',
        'settings-delete-account-web',
      ]) {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      expect(launcher.opened, <Uri>[
        Uri.parse('https://arena.example/privacy.html'),
        Uri.parse('https://arena.example/support.html'),
        Uri.parse('https://arena.example/delete-account.html'),
      ]);
    });

    testWidgets('shows an honest notice when the pages are not published',
        (tester) async {
      final runtime = buildRuntime();
      final launcher = _RecordingLauncher();
      final pages = PublicPages(
        config: configFor('https://example.invalid'),
        launcher: launcher,
      );
      await pumpSettings(tester, runtime, pages: pages);

      final finder = find.byKey(const ValueKey('settings-privacy-policy'));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(launcher.opened, isEmpty);
      expect(
        find.text('The public pages are not published for this build yet.'),
        findsOneWidget,
      );
    });
  });
}
