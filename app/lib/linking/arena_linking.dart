/// Wiring bundle for task `05` surfaces.
///
/// `ArenaApp` builds one [ArenaLinking] per process and exposes it through
/// [ArenaLinkingScope]. Tests construct the bundle with fakes; task `06`
/// injects a real access-token provider and auth delegate later.
library;

import 'package:flutter/widgets.dart';

import '../config/arena_config.dart';
import 'arena_challenge_api.dart';
import 'challenge_analytics.dart';
import 'challenge_auth.dart';
import 'challenge_deep_links.dart';
import 'challenge_entry_controller.dart';
import 'challenge_install_view.dart';
import 'challenge_persistence.dart';
import 'challenge_share.dart';
import 'install_referrer.dart';

/// Services used by the challenge entry route and the share flow.
class ArenaLinking {
  ArenaLinking({
    required this.config,
    required this.controller,
    required this.shareService,
    required this.installLauncher,
    required this.analytics,
    required this.auth,
  });

  final ArenaConfig config;
  final ChallengeEntryController controller;
  final ChallengeShareService shareService;
  final ChallengeInstallLauncher installLauncher;
  final ChallengeAnalyticsSink analytics;
  final ChallengeAuthDelegate auth;

  /// Real platform wiring with safe degradation:
  /// - no Supabase credentials => API calls fail closed with `not_configured`;
  /// - no auth delegate => honest "sign-in arrives later" state with links
  ///   and the share sheet still working;
  /// - platform channels unavailable (tests) => no crash.
  static ArenaLinking createDefault(
    ArenaConfig config, {
    AccessTokenProvider? accessTokenProvider,
    ChallengeAuthDelegate auth = const UnavailableChallengeAuthDelegate(),
  }) {
    final api = HttpArenaChallengeApi(
      config: config,
      accessTokenProvider: accessTokenProvider ?? () async => null,
    );
    final analytics = config.hasSupabaseCredentials
        ? ApiChallengeAnalyticsSink(api)
        : const NoopChallengeAnalyticsSink();
    final controller = ChallengeEntryController(
      config: config,
      api: api,
      persistence: SharedPreferencesChallengePersistence(),
      deepLinks: AppLinksChallengeDeepLinks(),
      installReferrer: const MethodChannelInstallReferrerSource(),
      auth: auth,
      analytics: analytics,
    );
    return ArenaLinking(
      config: config,
      controller: controller,
      shareService: ChallengeShareService(
        api: api,
        config: config,
        launcher: const PlatformShareSheetLauncher(),
        analytics: analytics,
      ),
      installLauncher: const UrlLauncherChallengeInstallLauncher(),
      analytics: analytics,
      auth: auth,
    );
  }

  void dispose() {
    controller.dispose();
  }
}

/// Provides [ArenaLinking] to the challenge widgets.
class ArenaLinkingScope extends InheritedWidget {
  const ArenaLinkingScope({
    super.key,
    required this.linking,
    required super.child,
  });

  final ArenaLinking linking;

  static ArenaLinking of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ArenaLinkingScope>();
    assert(scope != null, 'No ArenaLinkingScope above this widget.');
    return scope!.linking;
  }

  static ArenaLinking? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ArenaLinkingScope>()
        ?.linking;
  }

  @override
  bool updateShouldNotify(ArenaLinkingScope oldWidget) =>
      !identical(linking, oldWidget.linking);
}
