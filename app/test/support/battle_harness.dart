/// Shared harness wiring the battle controller with deterministic doubles.
library;

import 'package:flutter/foundation.dart';
import 'package:training_arena/battle/ports/battle_analytics.dart';
import 'package:training_arena/battle/ports/battle_challenge_sharer.dart';
import 'package:training_arena/battle/ports/battle_session_store.dart';
import 'package:training_arena/battle/runtime/battle_controller.dart';
import 'package:training_arena/battle/runtime/battle_runtime.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'battle_fakes.dart';

/// One-call setup for controller and widget tests.
class BattleHarness {
  BattleHarness({
    ArenaProfile? viewerProfile = testViewer,
    BattleChallengeSharer? sharerOverride,
    BattleAnalyticsSink? analytics,
    bool observeLifecycle = false,
    bool rankedMatchmakingEnabled = true,
    this.previewFixtures = false,
  })  : clock = ManualBattleClock(),
        viewer = ValueNotifier<ArenaProfile?>(viewerProfile),
        store = InMemoryBattleSessionStore(),
        sharer = sharerOverride ?? RecordingChallengeSharer() {
    backend = FakeBattleBackend(now: () => clock.now());
    camera = FakeBattleCamera();
    feedback = RecordingBattleFeedback();
    controller = BattleController(
      backend: backend,
      camera: camera,
      clock: clock,
      feedback: feedback,
      sessionStore: store,
      sharer: sharer,
      analytics: analytics,
      viewer: viewer,
      previewFixtures: previewFixtures,
      rankedMatchmakingEnabled: rankedMatchmakingEnabled,
      observeLifecycle: observeLifecycle,
    );
  }

  final ManualBattleClock clock;
  final ValueNotifier<ArenaProfile?> viewer;
  final InMemoryBattleSessionStore store;
  final BattleChallengeSharer sharer;
  late final FakeBattleBackend backend;
  late final FakeBattleCamera camera;
  late final RecordingBattleFeedback feedback;
  late final BattleController controller;
  final bool previewFixtures;

  BattleRuntime get runtime => BattleRuntime.withController(
        controller: controller,
        viewer: viewer,
        previewFixtures: previewFixtures,
      );

  /// Loads the home inbox with a pending request.
  Future<void> loadWithRequest() async {
    backend.inboxData = BattleInbox(requests: [testRequest()]);
    await controller.loadHome();
  }

  /// Walks preparation to the ready gate with one practice rep.
  Future<void> completePracticeAndReady() async {
    await controller.takePracticeRep();
    camera.emitPracticeRep();
    await Future<void>.delayed(Duration.zero);
    backend.readyReply = testMatch(
      id: backend.matchData?.id ?? 'match-1',
      status: ArenaMatchStatus.countdown,
      viewerReady: true,
      opponentReady: true,
      startsAt: clock.now().add(const Duration(seconds: 5)),
      endsAt: clock.now().add(const Duration(seconds: 65)),
      serverNow: clock.now(),
    );
    await controller.submitReady();
    await Future<void>.delayed(Duration.zero);
  }

  /// Reports a live server snapshot and advances one heartbeat so the next
  /// tick fetches it.
  void setLiveMatch({
    int viewerScore = 0,
    int opponentScore = 0,
    bool opponentTracking = true,
  }) {
    backend.matchData = testMatch(
      id: backend.matchData?.id ?? 'match-1',
      status: ArenaMatchStatus.live,
      viewerReady: true,
      opponentReady: true,
      viewerScore: viewerScore,
      opponentScore: opponentScore,
      opponentTracking: opponentTracking,
      startsAt: clock.now().subtract(const Duration(seconds: 1)),
      endsAt: clock.now().add(const Duration(seconds: 59)),
      serverNow: clock.now(),
    );
  }

  void dispose() {
    controller.dispose();
    viewer.dispose();
  }
}
