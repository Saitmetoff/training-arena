/// Composition root for the account feature.
///
/// Builds the auth gateway, the arena account client, the profile/leaderboard/
/// history controllers and the avatar picker (or accepts injected fakes), and
/// exposes them through [AccountRuntimeScope]. `ArenaApp` owns the runtime and
/// hands the access-token provider to the linking and battle HTTP clients.
library;

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../../config/arena_config.dart';
import '../../domain/arena_types.dart';
import '../auth/arena_auth.dart';
import '../auth/auth_store.dart';
import '../auth/supabase_auth_gateway.dart';
import '../avatar/avatar_picker.dart';
import '../challenge/auth_prompts.dart';
import '../data/account_api.dart';
import 'account_controller.dart';
import 'battle_history_controller.dart';
import 'leaderboard_controller.dart';

/// Account services shared by the shell and the challenge route.
class AccountRuntime {
  AccountRuntime({
    required this.controller,
    required this.api,
    required this.auth,
    required this.leaderboard,
    required this.history,
    required this.avatarPicker,
    required this.prompts,
  }) {
    controller.addListener(_onAccountChanged);
  }

  factory AccountRuntime.fromConfig(
    ArenaConfig config, {
    ArenaAuthGateway? auth,
    AccountApi? api,
    AvatarPicker? avatarPicker,
    ChallengeAuthPrompts? prompts,
    AuthSessionStore? sessionStore,
    http.Client? client,
    DateTime Function()? now,
  }) {
    final store = sessionStore ?? SecureAuthSessionStore();
    final resolvedAuth = auth ??
        (config.hasSupabaseCredentials
            ? SupabaseAuthGateway(
                config: config,
                store: store,
                client: client,
                now: now,
              )
            : const UnavailableArenaAuthGateway());
    late final AccountController controller;
    final resolvedApi = api ??
        HttpAccountApi(
          config: config,
          accessTokenProvider: () => controller.accessToken(),
          client: client,
        );
    controller = AccountController(
      auth: resolvedAuth,
      api: resolvedApi,
      now: now,
    );
    return AccountRuntime(
      controller: controller,
      api: resolvedApi,
      auth: resolvedAuth,
      leaderboard: LeaderboardController(
        api: resolvedApi,
        viewerId: () => controller.profile?.id,
      ),
      history: BattleHistoryController(api: resolvedApi),
      avatarPicker: avatarPicker ??
          (config.hasSupabaseCredentials
              ? const MethodChannelAvatarPicker()
              : const UnavailableAvatarPicker()),
      prompts: prompts ?? const CancellingChallengeAuthPrompts(),
    );
  }

  final AccountController controller;
  final AccountApi api;
  final ArenaAuthGateway auth;
  final LeaderboardController leaderboard;
  final BattleHistoryController history;
  final AvatarPicker avatarPicker;
  final ChallengeAuthPrompts prompts;

  /// Signed-in identity shared with the battle runtime.
  ValueNotifier<ArenaProfile?> get viewer => controller.viewer;

  /// Current access token for the linking and battle HTTP clients.
  Future<String?> accessToken() => controller.accessToken();

  /// Restores the session and loads the profile; never throws.
  Future<void> initialize() => controller.initialize();

  String? _lastUserId;

  void _onAccountChanged() {
    final id = controller.profile?.id;
    if (id != _lastUserId) {
      _lastUserId = id;
      leaderboard.reset();
      history.reset();
    }
    if (!controller.signedIn && controller.status != AccountStatus.restoring) {
      leaderboard.reset();
      history.reset();
    }
  }

  void dispose() {
    controller.removeListener(_onAccountChanged);
    controller.dispose();
    leaderboard.dispose();
    history.dispose();
  }
}

/// Provides [AccountRuntime] to the account surfaces.
class AccountRuntimeScope extends InheritedWidget {
  const AccountRuntimeScope({
    super.key,
    required this.runtime,
    required super.child,
  });

  final AccountRuntime runtime;

  static AccountRuntime of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AccountRuntimeScope>();
    assert(scope != null, 'No AccountRuntimeScope above this widget.');
    return scope!.runtime;
  }

  static AccountRuntime? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AccountRuntimeScope>()
        ?.runtime;
  }

  @override
  bool updateShouldNotify(AccountRuntimeScope oldWidget) =>
      !identical(runtime, oldWidget.runtime);
}
