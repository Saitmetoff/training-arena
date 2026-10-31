/// Widget-test wiring for the battle surfaces.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/arena_app.dart';
import 'package:training_arena/battle/runtime/battle_runtime.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/linking/arena_challenge_api.dart';
import 'package:training_arena/linking/arena_linking.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_persistence.dart';
import 'package:training_arena/linking/challenge_share.dart';

import '../linking/fakes.dart';
import 'battle_harness.dart';

/// Battle widget tests exercise the enabled production surfaces: the ranked
/// action and the camera-counted copy require both flags, while the shared
/// challenge-linking fixtures keep using the plain [testConfig].
ArenaConfig battleTestConfig() => testConfig(
      cameraCountingEnabled: true,
      rankedMatchmakingEnabled: true,
    );

/// Builds a fully in-memory linking bundle so widget tests never touch
/// platform channels.
ArenaLinking buildTestLinking({ArenaChallengeApi? api}) {
  final config = testConfig();
  final resolvedApi = api ?? FakeArenaChallengeApi();
  final analytics = MemoryChallengeAnalyticsSink();
  return ArenaLinking(
    config: config,
    controller: ChallengeEntryController(
      config: config,
      api: resolvedApi,
      persistence: MemoryChallengePersistence(),
      deepLinks: FakeChallengeDeepLinks(),
      installReferrer: FakeInstallReferrerSource(),
      auth: FakeChallengeAuthDelegate(),
      analytics: analytics,
      matchPollInterval: Duration.zero,
    ),
    shareService: ChallengeShareService(
      api: resolvedApi,
      config: config,
      launcher: FakeShareSheetLauncher(),
      analytics: analytics,
    ),
    installLauncher: FakeChallengeInstallLauncher(),
    analytics: analytics,
    auth: FakeChallengeAuthDelegate(),
  );
}

/// Pumps the real app shell with an injected battle runtime.
Future<void> pumpBattleApp(
  WidgetTester tester, {
  BattleHarness? harness,
  BattleRuntime? runtime,
  ArenaLinking? linking,
  ArenaConfig? config,
  bool settle = true,
}) async {
  final effectiveRuntime = runtime ?? harness!.runtime;
  await tester.pumpWidget(ArenaApp(
    config: config ?? battleTestConfig(),
    runtime: effectiveRuntime,
    linking: linking ?? buildTestLinking(),
  ));
  await tester.pump();
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  }
}
