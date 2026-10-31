/// Composition root for the battle feature.
///
/// Picks production defaults from [ArenaConfig] (HTTP backend against the
/// arena Edge Function, task 03's camera session, task 05's share/entry
/// adapters) or the labelled preview fixture mode when
/// `ARENA_FEATURE_PREVIEW_FIXTURES` is compiled in. Tasks 03, 04, 05 and 06
/// plug their adapters into [BattleController] here without touching the
/// state contract.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../config/arena_config.dart';
import '../../domain/arena_types.dart';
import '../../linking/challenge_entry_controller.dart';
import '../../linking/challenge_share.dart';
import '../../notifications/matchmaking_analytics.dart';
import '../../notifications/notification_api.dart';
import 'battle_controller.dart';
import '../data/camera_session_bridge.dart';
import '../data/challenge_adapters.dart';
import '../data/http_battle_backend.dart';
import '../fixtures/battle_fixtures.dart';
import '../ports/battle_analytics.dart';
import '../ports/battle_backend.dart';
import '../ports/battle_camera.dart';
import '../ports/battle_challenge_sharer.dart';
import '../ports/battle_clock.dart';
import '../ports/battle_feedback.dart';
import '../ports/battle_session_store.dart';

/// Owns the battle controller and the viewer identity source.
class BattleRuntime {
  BattleRuntime._({
    required this.controller,
    ValueNotifier<ArenaProfile?>? viewer,
    this.previewFixtures = false,
  }) : viewer = viewer ?? ValueNotifier<ArenaProfile?>(null);

  /// Production defaults.
  factory BattleRuntime.fromConfig(
    ArenaConfig config, {
    BattleAccessTokenProvider? accessTokenProvider,
    ChallengeShareService? shareService,
    ChallengeEntryController? challengeEntry,
    BattleAnalyticsSink? matchmakingAnalytics,
    BattleChallengeSharer? resultShareSharer,
  }) {
    if (config.previewFixturesEnabled) {
      return BattleRuntime.preview();
    }
    final tokenProvider = accessTokenProvider ?? () async => null;
    final BattleBackend backend = config.hasSupabaseCredentials
        ? HttpBattleBackend(config: config, accessTokenProvider: tokenProvider)
        : const UnconfiguredBattleBackend();
    final BattleCamera camera = config.cameraCountingEnabled
        ? CameraSessionBattleCamera(observeLifecycle: false)
        : UnavailableBattleCamera();
    final analytics =
        matchmakingAnalytics ??
        (config.hasSupabaseCredentials
            ? ApiBattleAnalyticsSink(
                HttpNotificationApi(
                  config: config,
                  accessTokenProvider: tokenProvider,
                ),
              )
            : const NoopBattleAnalyticsSink());
    final viewer = ValueNotifier<ArenaProfile?>(null);
    final runtime = BattleRuntime._(
      viewer: viewer,
      controller: BattleController(
        backend: backend,
        camera: camera,
        clock: const SystemBattleClock(),
        feedback: const NativeBattleFeedback(),
        sessionStore: SharedPreferencesBattleSessionStore(),
        sharer:
            resultShareSharer ??
            (shareService == null
                ? const PendingBattleChallengeSharer()
                : ChallengeShareServiceSharer(shareService)),
        analytics: analytics,
        viewer: viewer,
        // Effective gate: a ranked round needs camera counting, so the
        // controller refuses the queue whenever either flag is off. This is
        // the same condition the Battle tab renders.
        rankedMatchmakingEnabled:
            config.rankedMatchmakingEnabled && config.cameraCountingEnabled,
      ),
    );
    if (challengeEntry != null) {
      runtime.attachChallengeEntry(challengeEntry);
    }
    return runtime;
  }

  /// Deterministic preview fixtures. Labelled in the UI and blocked from
  /// producing receipts.
  factory BattleRuntime.preview() {
    const clock = SystemBattleClock();
    final viewer = ValueNotifier<ArenaProfile?>(BattleFixtureData.viewer);
    return BattleRuntime._(
      previewFixtures: true,
      viewer: viewer,
      controller: BattleController(
        backend: FixtureBattleBackend(clock: clock),
        camera: FixtureBattleCamera(clock: clock),
        clock: clock,
        feedback: const SilentBattleFeedback(),
        sessionStore: InMemoryBattleSessionStore(),
        viewer: viewer,
        previewFixtures: true,
      ),
    );
  }

  /// Injectable variant for tests, integration hosts and future task wiring.
  factory BattleRuntime.withPorts({
    required BattleBackend backend,
    required BattleCamera camera,
    required BattleClock clock,
    required BattleFeedback feedback,
    required BattleSessionStore sessionStore,
    BattleChallengeSharer? sharer,
    BattleAnalyticsSink? matchmakingAnalytics,
    ValueNotifier<ArenaProfile?>? viewer,
    bool previewFixtures = false,
  }) {
    return BattleRuntime._(
      previewFixtures: previewFixtures,
      viewer: viewer,
      controller: BattleController(
        backend: backend,
        camera: camera,
        clock: clock,
        feedback: feedback,
        sessionStore: sessionStore,
        sharer: sharer,
        analytics: matchmakingAnalytics,
        viewer: viewer,
        previewFixtures: previewFixtures,
      ),
    );
  }

  /// Wraps an already-built controller (used by tests and integration hosts
  /// that share one controller across the shell and the flow page).
  factory BattleRuntime.withController({
    required BattleController controller,
    ValueNotifier<ArenaProfile?>? viewer,
    bool previewFixtures = false,
  }) {
    return BattleRuntime._(
      controller: controller,
      viewer: viewer,
      previewFixtures: previewFixtures,
    );
  }

  final BattleController controller;
  final ValueNotifier<ArenaProfile?> viewer;

  /// True when deterministic preview fixtures are active.
  final bool previewFixtures;

  ChallengeEntryController? _challengeEntry;
  String? _attachedMatchId;

  /// Updates the signed-in identity shared with the account feature.
  void setViewer(ArenaProfile? profile) {
    viewer.value = profile;
  }

  /// Attaches task 05's challenge entry controller so `ChallengeEntryMatchReady`
  /// opens the battle flow, and `Join with code` goes through link resolution.
  ///
  /// Hosts that own the match handoff (for example [ArenaApp] wiring
  /// `onMatchReady`) pass [autoAttachMatches] false.
  void attachChallengeEntry(
    ChallengeEntryController? entry, {
    bool autoAttachMatches = true,
  }) {
    _challengeEntry?.removeListener(_onChallengeEntryChanged);
    _challengeEntry = entry;
    if (autoAttachMatches) {
      entry?.addListener(_onChallengeEntryChanged);
    }
    controller.attachEntryDelegate(
      entry == null ? null : ChallengeEntryDelegate(entry),
    );
    if (autoAttachMatches) {
      _onChallengeEntryChanged();
    }
  }

  void _onChallengeEntryChanged() {
    final state = _challengeEntry?.state;
    if (state is ChallengeEntryMatchReady &&
        state.matchId.isNotEmpty &&
        state.matchId != _attachedMatchId) {
      _attachedMatchId = state.matchId;
      unawaited(controller.attachMatch(state.matchId));
    }
  }

  /// Loads the Battle tab and restores any persisted match id.
  Future<void> initialize() async {
    await controller.restoreSession();
    await controller.loadHome();
  }

  void dispose() {
    _challengeEntry?.removeListener(_onChallengeEntryChanged);
    controller.dispose();
    viewer.dispose();
  }
}

/// Exposes the [BattleController] to the widget tree and rebuilds dependents
/// whenever the battle snapshot changes.
class BattleRuntimeScope extends InheritedNotifier<BattleController> {
  const BattleRuntimeScope({
    super.key,
    required BattleController controller,
    required super.child,
  }) : super(notifier: controller);

  static BattleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BattleRuntimeScope>();
    assert(scope != null, 'No BattleRuntimeScope above this widget.');
    return scope!.notifier!;
  }

  static BattleController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BattleRuntimeScope>();
    return scope?.notifier;
  }
}
