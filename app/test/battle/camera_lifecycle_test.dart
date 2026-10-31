import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/data/camera_session_bridge.dart';
import 'package:training_arena/battle/ports/battle_session_store.dart';
import 'package:training_arena/battle/runtime/battle_controller.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

import '../camera/camera_session_test.dart'
    show FakeCameraBridge, buildSession, practiceOn, feed;
import '../camera/trace_replay_test.dart' show replayTrace;
import '../support/battle_fakes.dart';

void main() {
  for (final phase in ['practice', 'ready', 'countdown', 'live']) {
    test(
      'real adapter background/resume preserves $phase and fresh rematch',
      () async {
        final bridge = FakeCameraBridge();
        final session = buildSession(bridge)..enableDiagnosticTrace();
        final camera = CameraSessionBattleCamera(
          observeLifecycle: false,
          sessionFactory: (_) => session,
        );
        final clock = ManualBattleClock();
        final backend = FakeBattleBackend(now: clock.now)
          ..matchData = testMatch();
        final viewer = ValueNotifier<ArenaProfile?>(testViewer);
        final controller = BattleController(
          backend: backend,
          camera: camera,
          clock: clock,
          feedback: RecordingBattleFeedback(),
          sessionStore: InMemoryBattleSessionStore(),
          viewer: viewer,
          observeLifecycle: false,
        );
        addTearDown(() {
          controller.dispose();
          viewer.dispose();
        });
        await controller.attachMatch('match-1');
        await pumpEventQueue();
        await controller.takePracticeRep();
        final source = SyntheticPoseSource.pushups(seed: 77);
        if (phase != 'practice') {
          await feed(bridge, practiceOn(source));
          await pumpEventQueue();
          expect(session.phase, CameraSessionPhase.ready);
        }
        if (phase == 'countdown' || phase == 'live') {
          backend.readyReply = testMatch(
            status: ArenaMatchStatus.countdown,
            viewerReady: true,
            opponentReady: true,
            startsAt: clock.now().add(const Duration(seconds: 5)),
            endsAt: clock.now().add(const Duration(seconds: 65)),
          );
          await controller.submitReady();
        }
        if (phase == 'live') {
          backend.matchData = testMatch(
            status: ArenaMatchStatus.live,
            startsAt: clock.now().subtract(const Duration(seconds: 1)),
            endsAt: clock.now().add(const Duration(seconds: 59)),
          );
          clock.advance(const Duration(seconds: 6));
          await pumpEventQueue();
          await feed(bridge, source.rep());
        } else if (phase == 'countdown') {
          backend.matchData = backend.readyReply;
        }
        final before = session.phase;
        final reps = session.reps;
        final trace = session.diagnosticTrace;
        controller.pause();
        await pumpEventQueue();
        expect(session.phase, CameraSessionPhase.paused);
        expect(trace!.completed, isFalse);
        await controller.resume();
        await pumpEventQueue();
        expect(session.phase, before);
        expect(session.diagnosticTrace, same(trace));
        expect(session.reps, reps);
        if (phase == 'live') {
          await feed(bridge, [...source.holdTop(900), ...source.rep()]);
          await pumpEventQueue();
          expect(session.reps, reps + 1);
          expect(backend.repCalls.last.sequence, 2);
          await camera.stop();
          expect(
            replayTrace(trace.text(), ArenaExercise.pushUps)['counted_reps'],
            2,
          );
          expect(trace.completed, isTrue);
          controller.exitToHome();
          await pumpEventQueue();
          backend.matchData = testMatch(id: 'fresh-match');
          await controller.attachMatch('fresh-match');
          await controller.takePracticeRep();
          await feed(bridge, practiceOn(source));
          await camera.startMatch();
          expect(session.phase, CameraSessionPhase.live);
          expect(session.reps, 0);
          expect(trace.completed, isFalse);
          await feed(bridge, source.rep());
          expect(session.reps, 1);
        }
      },
    );
  }
}
