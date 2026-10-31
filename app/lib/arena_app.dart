import 'dart:async';

import 'package:flutter/material.dart';

import 'account/challenge/account_challenge_auth.dart';
import 'account/runtime/account_runtime.dart';
import 'account/ui/sign_in_flow.dart';
import 'battle/data/challenge_adapters.dart';
import 'battle/ports/battle_challenge_sharer.dart';
import 'battle/runtime/battle_runtime.dart';
import 'battle/state/battle_models.dart';
import 'config/arena_config.dart';
import 'linking/arena_linking.dart';
import 'linking/challenge_entry_controller.dart';
import 'linking/challenge_entry_view.dart';
import 'notifications/notification_runtime.dart';
import 'notifications/notification_service.dart';
import 'notifications/ui/notification_gate.dart';
import 'sharing/result_share_challenge_sharer.dart';
import 'sharing/result_share_service.dart';
import 'shell/arena_shell.dart';
import 'theme/arena_theme.dart';

/// Root widget.
///
/// Builds the battle runtime, the account runtime and the challenge-linking
/// bundle (or accepts injected ones for tests), starts deep-link handling and
/// account restore, and shows the focused challenge experience instead of the
/// shell while a link is being resolved.
class ArenaApp extends StatefulWidget {
  const ArenaApp({
    super.key,
    this.config = ArenaConfig.fromEnvironment,
    this.runtime,
    this.linking,
    this.account,
    this.notifications,
    this.onMatchReady,
  });

  final ArenaConfig config;

  /// Injectable battle runtime for tests and integration hosts. When null,
  /// the app builds production defaults from [config].
  final BattleRuntime? runtime;

  /// Injectable challenge linking bundle. When null, platform defaults are
  /// built from [config].
  final ArenaLinking? linking;

  /// Injectable account runtime for tests and integration hosts. When null,
  /// production defaults are built from [config] and the app owns it.
  final AccountRuntime? account;

  /// Injectable notification runtime for tests and integration hosts. When
  /// null, production defaults are built from [config] and the battle
  /// backend.
  final NotificationRuntime? notifications;

  /// Called when the server confirmed a mutual-acceptance match. When null,
  /// the app opens the battle flow directly.
  final void Function(String matchId)? onMatchReady;

  @override
  State<ArenaApp> createState() => _ArenaAppState();
}

class _ArenaAppState extends State<ArenaApp> {
  late final BattleRuntime _runtime;
  late final ArenaLinking _linking;
  late final AccountRuntime _account;
  late final NotificationRuntime _notifications;
  late final bool _ownsRuntime;
  late final bool _ownsLinking;
  late final bool _ownsAccount;
  late final bool _ownsNotifications;
  bool _permissionDialogOpen = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _ownsAccount = widget.account == null;
    _account = widget.account ??
        AccountRuntime.fromConfig(
          widget.config,
          prompts: NavigatorChallengeAuthPrompts(_navigatorKey),
        );
    final accountAuth = AccountChallengeAuthDelegate(
      controller: _account.controller,
      prompts: _account.prompts,
    );
    _ownsLinking = widget.linking == null;
    _linking = widget.linking ??
        ArenaLinking.createDefault(
          widget.config,
          accessTokenProvider: _account.accessToken,
          auth: accountAuth,
        );
    _ownsRuntime = widget.runtime == null;
    _runtime = widget.runtime ??
        BattleRuntime.fromConfig(
          widget.config,
          accessTokenProvider: _account.accessToken,
          shareService: _linking.shareService,
          resultShareSharer: _resultShareSharer(),
        );
    _ownsNotifications = widget.notifications == null;
    _notifications = widget.notifications ??
        NotificationRuntime.fromConfig(
          widget.config,
          backend: _runtime.controller.backend,
          accessTokenProvider: _account.accessToken,
          onForegroundMessage: (_) => _runtime.controller.refreshInbox(),
        );
    // The app owns the navigation handoff; the runtime still gets the entry
    // delegate so `Join with code` resolves links through task 05.
    _runtime.attachChallengeEntry(_linking.controller,
        autoAttachMatches: false);
    _linking.controller.addListener(_onChallengeEntryChanged);
    _runtime.controller.addListener(_onBattleChanged);
    _runtime.controller.attachRequestActivityListener(_onRequestActivity);
    _notifications.service.addListener(_onNotificationChanged);
    if (_ownsRuntime) {
      _account.viewer.addListener(_onViewerChanged);
    }
    unawaited(_account.initialize());
    unawaited(_linking.controller.start());
    unawaited(_runtime.initialize());
    unawaited(_notifications.initialize());
  }

  /// Task 09: build the preview-first result sharer when the feature flag is
  /// on. Plain friend challenges fall through to task 05's text share.
  BattleChallengeSharer? _resultShareSharer() {
    if (!widget.config.resultSharingEnabled) {
      return null;
    }
    final service = ResultShareService(
      account: ChallengeShareAccountSource(_linking.shareService),
      config: widget.config,
      launcher: const SharePlusResultShareLauncher(),
      clipboard: const SystemResultShareClipboard(),
      analytics: _linking.analytics,
    );
    return ResultShareChallengeSharer(
      service: service,
      presenter: NavigatorResultSharePresenter(_navigatorKey),
      viewer: _account.viewer,
      fallback: ChallengeShareServiceSharer(_linking.shareService),
    );
  }

  @override
  void dispose() {
    _linking.controller.removeListener(_onChallengeEntryChanged);
    _notifications.service.removeListener(_onNotificationChanged);
    _runtime.controller.removeListener(_onBattleChanged);
    _runtime.controller.attachRequestActivityListener(null);
    if (_ownsRuntime) {
      _account.viewer.removeListener(_onViewerChanged);
      _runtime.dispose();
    }
    if (_ownsLinking) {
      _linking.dispose();
    }
    if (_ownsNotifications) {
      _notifications.dispose();
    }
    if (_ownsAccount) {
      _account.dispose();
    }
    super.dispose();
  }

  void _onViewerChanged() {
    _runtime.setViewer(_account.viewer.value);
  }

  void _onChallengeEntryChanged() {
    if (!mounted) {
      return;
    }
    if (_linking.controller.state is ChallengeEntryWaiting) {
      _onRequestActivity();
    }
    setState(() {});
    _maybeShowPermissionRationale();
  }

  void _onBattleChanged() {
    if (!_notifications.enabled) {
      return;
    }
    if (_runtime.controller.snapshot.incomingRequest != null) {
      _onRequestActivity();
    }
  }

  /// The user first sent or received a challenge request: this is the only
  /// moment the in-context notification prompt is offered.
  void _onRequestActivity() {
    if (!_notifications.enabled) {
      return;
    }
    unawaited(_notifications.service.noteRequestActivity());
  }

  void _onNotificationChanged() {
    if (!mounted) {
      return;
    }
    _maybeShowPermissionRationale();
  }

  void _maybeShowPermissionRationale() {
    if (!_notifications.enabled ||
        _permissionDialogOpen ||
        !_notifications.service.shouldExplainPermission ||
        _linking.controller.state is! ChallengeEntryIdle) {
      return;
    }
    _permissionDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _permissionDialogOpen = false;
        return;
      }
      final context = _navigatorKey.currentContext;
      if (context == null || !_notifications.service.shouldExplainPermission) {
        _permissionDialogOpen = false;
        return;
      }
      try {
        final allow = await showNotificationPermissionRationale(context);
        await _notifications.service.resolvePermissionPrompt(allow: allow);
      } finally {
        _permissionDialogOpen = false;
      }
    });
  }

  void _openMatch(String matchId) {
    final handler = widget.onMatchReady;
    if (handler != null) {
      handler(matchId);
      return;
    }
    unawaited(_runtime.controller.attachMatch(matchId));
  }

  Future<void> _resumeMatch(String matchId) async {
    _notifications.service.closeRoute();
    _openMatch(matchId);
  }

  Future<void> _acceptNotificationRequest(BattleRequest request) async {
    await _runtime.controller.acceptRequest(request.id);
    final match = _runtime.controller.snapshot.match;
    if (match != null && match.id.isNotEmpty) {
      _notifications.service.closeRoute();
      return;
    }
    // The server refused or the request changed; re-check authoritatively.
    await _notifications.service.retry();
  }

  Future<void> _declineNotificationRequest(BattleRequest request) async {
    await _runtime.controller.declineRequest(request.id);
    _notifications.service.closeRoute();
  }

  @override
  Widget build(BuildContext context) {
    return ArenaConfigScope(
      config: widget.config,
      child: AccountRuntimeScope(
        runtime: _account,
        child: ArenaLinkingScope(
          linking: _linking,
          child: BattleRuntimeScope(
            controller: _runtime.controller,
            child: MaterialApp(
              title: 'Fault',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navigatorKey,
              theme: ArenaTheme.dark,
              home: AnimatedBuilder(
                animation: Listenable.merge(
                  <Listenable>[
                    _linking.controller,
                    _notifications.service,
                  ],
                ),
                builder: (context, _) {
                  final focused =
                      _linking.controller.state is! ChallengeEntryIdle;
                  if (focused) {
                    return ChallengeEntryView(
                      controller: _linking.controller,
                      installLauncher: _linking.installLauncher,
                      analytics: _linking.analytics,
                      onMatchReady: _openMatch,
                    );
                  }
                  if (_notifications.service.route is! NotificationRouteIdle) {
                    return NotificationGate(
                      service: _notifications.service,
                      onAcceptRequest: _acceptNotificationRequest,
                      onDeclineRequest: _declineNotificationRequest,
                      onResumeMatch: _resumeMatch,
                      onBackToBattle: _notifications.service.closeRoute,
                    );
                  }
                  return const ArenaShell();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
