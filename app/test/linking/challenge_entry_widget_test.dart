import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/linking/arena_linking.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_link_host.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/linking/challenge_persistence.dart';
import 'package:training_arena/linking/challenge_share.dart';
import 'package:training_arena/linking/challenge_share_view.dart';
import 'package:training_arena/theme/arena_theme.dart';

import 'fakes.dart';

/// Mirrors ArenaApp's composition (config scope + linking scope + host)
/// without importing the shell, so link tests stay independent of the
/// concurrently developed battle module.
Widget harness(
  ArenaLinking linking, {
  void Function(String matchId)? onMatchReady,
}) {
  return ArenaConfigScope(
    config: linking.config,
    child: ArenaLinkingScope(
      linking: linking,
      child: MaterialApp(
        theme: ArenaTheme.dark,
        home: ChallengeLinkHost(
          onMatchReady: onMatchReady,
          child: const Scaffold(
            body: Center(
              child: Text('shell-content', key: ValueKey('test-shell')),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final analytics = MemoryChallengeAnalyticsSink();

  ArenaLinking buildLinking({
    FakeArenaChallengeApi? api,
    FakeChallengeDeepLinks? deepLinks,
    FakeChallengeAuthDelegate? auth,
    FakeShareSheetLauncher? shareLauncher,
    FakeChallengeInstallLauncher? installLauncher,
    bool challengeLinksEnabled = true,
    ChallengeEntryController? controller,
  }) {
    final resolvedApi = api ?? FakeArenaChallengeApi();
    final config = testConfig(challengeLinksEnabled: challengeLinksEnabled);
    final resolvedController = controller ??
        ChallengeEntryController(
          config: config,
          api: resolvedApi,
          persistence: MemoryChallengePersistence(),
          deepLinks: deepLinks ?? FakeChallengeDeepLinks(),
          installReferrer: FakeInstallReferrerSource(),
          auth: auth ?? FakeChallengeAuthDelegate(),
          analytics: analytics,
          matchPollInterval: Duration.zero,
        );
    return ArenaLinking(
      config: config,
      controller: resolvedController,
      shareService: ChallengeShareService(
        api: resolvedApi,
        config: config,
        launcher: shareLauncher ?? FakeShareSheetLauncher(),
        analytics: analytics,
      ),
      installLauncher: installLauncher ?? FakeChallengeInstallLauncher(),
      analytics: analytics,
      auth: auth ?? FakeChallengeAuthDelegate(),
    );
  }

  testWidgets('cold link lands on the challenger without visiting a tab',
      (tester) async {
    final api = FakeArenaChallengeApi();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final linking = buildLinking(api: api, deepLinks: deepLinks);

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('challenge-landing-review')),
      findsOneWidget,
    );
    expect(find.textContaining('@zuhra challenges you'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('test-shell')),
      findsNothing,
      reason: 'the focused challenge replaces the shell',
    );

    await tester.tap(find.byKey(const ValueKey('challenge-accept-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('challenge-waiting-view')), findsOneWidget);
    expect(find.text('Request sent'), findsOneWidget);
    expect(api.sendCalls, 1);

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('signed-out link returns to the same challenge after sign-in',
      (tester) async {
    final auth = FakeChallengeAuthDelegate(signedIn: false);
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final linking = buildLinking(auth: auth, deepLinks: deepLinks);

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('challenge-signin-view')), findsOneWidget);
    expect(find.text('Sign in to accept'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('challenge-signin-google')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('challenge-landing-review')),
      findsOneWidget,
    );
    expect(auth.signInCalls, 1);

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('closing the challenge returns to the shell', (tester) async {
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final linking = buildLinking(deepLinks: deepLinks);

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('challenge-landing-review')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('challenge-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('test-shell')), findsOneWidget);

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('warm link interrupts the shell with the same landing',
      (tester) async {
    final deepLinks = FakeChallengeDeepLinks();
    final linking = buildLinking(deepLinks: deepLinks);

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('test-shell')), findsOneWidget);

    deepLinks.emit(Uri.parse('trainingarena://challenge/$fakeToken'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('challenge-landing-review')),
      findsOneWidget,
    );

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('revoked link shows the honest unavailable state',
      (tester) async {
    final api = FakeArenaChallengeApi()
      ..resolution = const ChallengeResolution(
        token: fakeToken,
        status: ChallengeLinkStatus.revoked,
      );
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final linking = buildLinking(api: api, deepLinks: deepLinks);

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('challenge-unavailable-view')),
      findsOneWidget,
    );
    expect(find.text('This challenge link was revoked'), findsWidgets);
    expect(find.textContaining('never stores or replays'), findsOneWidget);

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('offline challenger offers a live request with no replay promise',
      (tester) async {
    final api = FakeArenaChallengeApi()
      ..resolution = ChallengeResolution(
        token: fakeToken,
        status: ChallengeLinkStatus.ownerOffline,
        owner: fakeOwner(),
      );
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final linking = buildLinking(api: api, deepLinks: deepLinks);

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();

    expect(find.text('Send live challenge'), findsOneWidget);
    expect(find.text('Challenger offline'), findsOneWidget);
    expect(find.textContaining('no old score to beat'), findsWidgets);

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('disabled links offer Play, reopen instruction and short code',
      (tester) async {
    final installLauncher = FakeChallengeInstallLauncher();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final linking = buildLinking(
      deepLinks: deepLinks,
      installLauncher: installLauncher,
      challengeLinksEnabled: false,
    );

    await tester.pumpWidget(harness(linking));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('challenge-install-view')), findsOneWidget);
    expect(find.text('Reopen this link after installing'), findsOneWidget);
    expect(find.text('AB12-CD34-EF56'), findsOneWidget);

    final playButton = find.byKey(const ValueKey('challenge-play-button'));
    await tester.ensureVisible(playButton);
    await tester.pumpAndSettle();
    await tester.tap(playButton);
    await tester.pumpAndSettle();
    expect(installLauncher.opened, hasLength(1));
    expect(
      installLauncher.opened.single.queryParameters['referrer'],
      'challenge=$fakeToken',
    );

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('accepted match offers the preparation handoff', (tester) async {
    final api = FakeArenaChallengeApi();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = ChallengeEntryController(
      config: testConfig(),
      api: api,
      persistence: MemoryChallengePersistence(),
      deepLinks: deepLinks,
      installReferrer: FakeInstallReferrerSource(),
      auth: FakeChallengeAuthDelegate(),
      analytics: analytics,
      matchPollInterval: Duration.zero,
    );
    final linking = buildLinking(
      api: api,
      deepLinks: deepLinks,
      controller: controller,
    );
    final readyMatches = <String>[];

    await tester.pumpWidget(
      harness(linking, onMatchReady: readyMatches.add),
    );
    await tester.pumpAndSettle();

    await controller.acceptChallenge();
    api.activeMatchId = fakeMatchId;
    await controller.checkForAcceptedMatch();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('challenge-match-ready-view')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('challenge-open-battle-button')),
    );
    await tester.pumpAndSettle();
    expect(readyMatches, <String>[fakeMatchId]);
    expect(find.byKey(const ValueKey('test-shell')), findsOneWidget);

    linking.dispose();
    await deepLinks.close();
  });

  testWidgets('Challenge a friend shares the exact message then waits',
      (tester) async {
    final api = FakeArenaChallengeApi();
    final shareLauncher = FakeShareSheetLauncher();
    final linking = buildLinking(api: api, shareLauncher: shareLauncher);

    await tester.pumpWidget(
      MaterialApp(
        theme: ArenaTheme.dark,
        home: ArenaLinkingScope(
          linking: linking,
          child: const Scaffold(body: ChallengeFriendButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('challenge-friend-button')));
    await tester.pumpAndSettle();

    expect(shareLauncher.sharedTexts, hasLength(1));
    expect(
      shareLauncher.sharedTexts.single,
      '@azizbek challenges you. Push-ups or squats. 60 seconds. '
      'Accept the challenge: https://example.invalid/c/$fakeToken',
    );
    expect(
      find.byKey(const ValueKey('challenge-share-waiting-view')),
      findsOneWidget,
    );
    expect(find.text('Your link is live'), findsOneWidget);
    expect(
      analytics.eventNames,
      contains(ChallengeAnalyticsEvent.shareSheetOpened),
    );
    expect(
      analytics.eventNames,
      isNot(contains('referral')),
      reason: 'a share sheet opening is never a referral',
    );

    linking.dispose();
  });
}
