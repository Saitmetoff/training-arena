/// R11a regression: `ARENA_FEATURE_RANKED_MATCHMAKING` must actually gate the
/// queue at the controller boundary, not just be recorded in config.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/runtime/battle_runtime.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/battle/state/battle_phase.dart';

import '../linking/fakes.dart';
import '../support/battle_fakes.dart';
import '../support/battle_harness.dart';

void main() {
  group('ranked matchmaking flag', () {
    test('disabled ranked never joins the queue and says so honestly', () async {
      final harness = BattleHarness(rankedMatchmakingEnabled: false);
      addTearDown(harness.dispose);

      await harness.controller.startRankedSearch();
      await harness.controller.startRankedSearch();

      expect(harness.backend.callLog, isNot(contains('queueJoin')));
      expect(
        harness.controller.snapshot.queuePhase,
        isNot(BattleQueuePhase.searching),
      );
      expect(
        harness.controller.snapshot.queuePhase,
        isNot(BattleQueuePhase.extended),
      );
      expect(harness.controller.snapshot.match, isNull);
      expect(
        harness.controller.snapshot.notice,
        contains('Ranked matchmaking is not available'),
      );
    });

    test('enabled ranked still opens a queue seat', () async {
      final harness = BattleHarness(rankedMatchmakingEnabled: true);
      addTearDown(harness.dispose);

      await harness.controller.startRankedSearch();

      expect(harness.backend.callLog, contains('queueJoin'));
      expect(
        harness.controller.snapshot.queuePhase,
        anyOf(
          BattleQueuePhase.searching,
          BattleQueuePhase.extended,
        ),
      );
    });

    test('the disabled flag does not block friend challenges', () async {
      final harness = BattleHarness(rankedMatchmakingEnabled: false);
      addTearDown(harness.dispose);

      await harness.controller.challengeFriend();

      expect(
        (harness.sharer as RecordingChallengeSharer).invites,
        hasLength(1),
      );
      expect(harness.backend.callLog, isNot(contains('queueJoin')));
    });

    test('preview fixtures can never join the real ranked queue', () async {
      // Preview is a separate composition path; its fixture backend refuses
      // every competitive action even though the controller has no flag gate
      // applied here.
      final runtime = BattleRuntime.preview();
      addTearDown(runtime.dispose);

      await runtime.controller.startRankedSearch();

      expect(runtime.controller.snapshot.previewFixtures, isTrue);
      expect(runtime.controller.snapshot.match, isNull);
      expect(
        runtime.controller.snapshot.queuePhase,
        isNot(BattleQueuePhase.searching),
      );
    });

    test('camera counting off disables ranked through the composition root',
        () {
      final runtime = BattleRuntime.fromConfig(testConfig(
        cameraCountingEnabled: false,
        rankedMatchmakingEnabled: true,
      ));
      addTearDown(runtime.dispose);

      expect(runtime.controller.rankedMatchmakingEnabled, isFalse);
    });

    test('both flags on keep ranked enabled through the composition root', () {
      final runtime = BattleRuntime.fromConfig(testConfig(
        cameraCountingEnabled: true,
        rankedMatchmakingEnabled: true,
      ));
      addTearDown(runtime.dispose);

      expect(runtime.controller.rankedMatchmakingEnabled, isTrue);
    });

    test(
        'a permissive backend cannot make a preview controller queue, ready '
        'or report', () async {
      final harness = BattleHarness(previewFixtures: true);
      addTearDown(harness.dispose);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await harness.controller.acceptRequest('req-1');

      // Complete the required practice rep so ready eligibility is real: the
      // preview guard, not a blocked gate, must be what refuses the ready.
      await harness.controller.takePracticeRep();
      harness.camera.emitPracticeRep();
      await Future<void>.delayed(Duration.zero);
      expect(harness.controller.snapshot.practiceState, PracticeState.completed);
      expect(
        harness.controller.snapshot.canSubmitReady,
        isTrue,
        reason: 'the practice gate must be satisfied for this to test preview',
      );

      await harness.controller.startRankedSearch();
      await harness.controller.submitReady();
      await harness.controller.requestReady();

      // Drive the match to a genuinely eligible live round with tracking so a
      // rep would be accepted if the preview guard were missing.
      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect(harness.controller.snapshot.phase, BattlePhase.live);
      expect(
        harness.controller.snapshot.cameraStatus,
        BattleCameraStatus.tracking,
      );

      harness.camera.emitCompetitiveRep();
      await Future<void>.delayed(Duration.zero);

      expect(harness.backend.callLog, isNot(contains('queueJoin')));
      expect(
        harness.backend.callLog.where((call) => call.startsWith('ready')),
        isEmpty,
      );
      expect(
        harness.backend.callLog.where((call) => call.startsWith('rep:')),
        isEmpty,
      );
      expect(harness.controller.snapshot.match, isNotNull);
    });

    test(
        'the same permissive harness sends ready and a rep without preview',
        () async {
      final harness = BattleHarness(previewFixtures: false);
      addTearDown(harness.dispose);
      harness.backend.inboxData = BattleInbox(requests: [testRequest()]);
      harness.backend.matchData = testMatch();
      await harness.controller.loadHome();
      await harness.controller.acceptRequest('req-1');

      await harness.controller.takePracticeRep();
      harness.camera.emitPracticeRep();
      await Future<void>.delayed(Duration.zero);
      expect(harness.controller.snapshot.practiceState, PracticeState.completed);
      expect(harness.controller.snapshot.canSubmitReady, isTrue);

      await harness.controller.submitReady();
      await Future<void>.delayed(Duration.zero);
      expect(harness.backend.callLog, contains('ready'));

      harness.setLiveMatch();
      harness.clock.advance(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect(harness.controller.snapshot.phase, BattlePhase.live);
      expect(
        harness.controller.snapshot.cameraStatus,
        BattleCameraStatus.tracking,
      );

      harness.camera.emitCompetitiveRep();
      await Future<void>.delayed(Duration.zero);

      expect(harness.backend.callLog, contains('rep:1'));
    });
  });
}
