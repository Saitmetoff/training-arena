import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/arena_app.dart';
import 'package:training_arena/linking/arena_linking.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_persistence.dart';
import 'package:training_arena/linking/challenge_share.dart';

import 'fakes.dart';

/// Verifies the real [ArenaApp] composition: a cold link must land on the
/// challenge route instead of the shell, and closing must restore the shell.
void main() {
  testWidgets('ArenaApp opens a cold challenge link before the shell',
      (tester) async {
    final api = FakeArenaChallengeApi();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final config = testConfig();
    final analytics = MemoryChallengeAnalyticsSink();
    final controller = ChallengeEntryController(
      config: config,
      api: api,
      persistence: MemoryChallengePersistence(),
      deepLinks: deepLinks,
      installReferrer: FakeInstallReferrerSource(),
      auth: FakeChallengeAuthDelegate(),
      analytics: analytics,
      matchPollInterval: Duration.zero,
    );
    final linking = ArenaLinking(
      config: config,
      controller: controller,
      shareService: ChallengeShareService(
        api: api,
        config: config,
        launcher: FakeShareSheetLauncher(),
        analytics: analytics,
      ),
      installLauncher: FakeChallengeInstallLauncher(),
      analytics: analytics,
      auth: FakeChallengeAuthDelegate(),
    );

    await tester.pumpWidget(ArenaApp(config: config, linking: linking));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('challenge-landing-review')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('arena-bottom-nav')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('challenge-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('arena-bottom-nav')), findsOneWidget);

    linking.dispose();
    await deepLinks.close();
  });
}
