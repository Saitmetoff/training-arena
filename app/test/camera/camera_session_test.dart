import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fixture_replay.dart';
import 'trace_replay_test.dart' show replayTrace;

class FakeCameraBridge implements CameraBridge {
  final StreamController<PoseBridgeEvent> _poseController =
      StreamController<PoseBridgeEvent>.broadcast(sync: true);
  final StreamController<CameraCueEvent> _cueController =
      StreamController<CameraCueEvent>.broadcast(sync: true);

  final List<String> calls = [];
  CameraPermissionStatus checkResult = CameraPermissionStatus.granted;
  CameraPermissionStatus requestResult = CameraPermissionStatus.granted;
  CameraBridgeException? requestError;
  bool hasCameraResult = true;
  int textureId = 42;
  int disposeCount = 0;
  Completer<void>? pauseGate;
  CameraBridgeException? pauseError;
  CameraRuntimeInfo info = const CameraRuntimeInfo(
    detectorSdk: 'ML Kit pose-detection 18.0.0-beta5',
    detectorModel: 'base',
    cameraStack: 'CameraX 1.4.1',
    minSdk: 24,
    apiLevel: 34,
    deviceName: 'test',
  );

  @override
  Stream<PoseBridgeEvent> get poseEvents => _poseController.stream;

  @override
  Stream<CameraCueEvent> get cueEvents => _cueController.stream;

  void emitFrame(PoseFrame frame) =>
      _poseController.add(PoseFrameEvent(frame: frame));

  void emitTracking(CameraTrackingState state, TrackingPauseReason reason) {
    _poseController.add(
      PoseTrackingEvent(
        state: state,
        reason: reason,
        luminance: 0.5,
        timestampMicros: 0,
      ),
    );
  }

  void emitError(String code, String message) {
    _poseController.add(
      PoseErrorEvent(code: code, message: message, timestampMicros: 0),
    );
  }

  @override
  Future<CameraPermissionStatus> checkPermission() async {
    calls.add('checkPermission');
    return checkResult;
  }

  @override
  Future<CameraPermissionStatus> requestPermission() async {
    calls.add('requestPermission');
    if (requestError != null) {
      throw requestError!;
    }
    return requestResult;
  }

  @override
  Future<bool> openAppSettings() async {
    calls.add('openAppSettings');
    return true;
  }

  @override
  Future<bool> hasCamera() async {
    calls.add('hasCamera');
    return hasCameraResult;
  }

  @override
  Future<int> startPreview(ArenaExercise exercise) async {
    calls.add('startPreview:${exercise.wire}');
    return textureId;
  }

  @override
  Future<void> setTorch(bool enabled) async {
    calls.add('setTorch:$enabled');
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    await pauseGate?.future;
    if (pauseError != null) throw pauseError!;
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<CameraRuntimeInfo> runtimeInfo() async {
    calls.add('runtimeInfo');
    return info;
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    disposeCount++;
    await _poseController.close();
    await _cueController.close();
  }
}

CameraSessionController buildSession(
  FakeCameraBridge bridge, {
  ArenaExercise exercise = ArenaExercise.pushUps,
  DateTime Function()? clock,
  bool isCompetitive = true,
}) {
  var eventNumber = 0;
  return CameraSessionController(
    bridge: bridge,
    exercise: exercise,
    isCompetitive: isCompetitive,
    observeLifecycle: false,
    eventIdFactory: () => 'event-${++eventNumber}',
    clock: clock,
  );
}

/// Frames for one complete practice rep on [source], one source per flow so
/// timestamps stay monotonic across every rep in a session test.
List<PoseFrame> practiceOn(SyntheticPoseSource source) => [
  ...source.holdTop(800),
  ...source.rep(),
];

List<PoseFrame> roundOn(SyntheticPoseSource source) => [
  ...source.rep(),
  ...source.holdTop(200),
];

Future<void> feed(FakeCameraBridge bridge, Iterable<PoseFrame> frames) async {
  for (final frame in frames) {
    bridge.emitFrame(frame);
  }
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'completed numeric trace survives reconnect and replays only scored reps',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge)..enableDiagnosticTrace();
      addTearDown(session.dispose);
      final source = SyntheticPoseSource.pushups(seed: 95);
      await session.startPractice();
      for (final f in practiceOn(source)) {
        bridge.emitFrame(f);
      }
      expect(session.practiceComplete, isTrue);
      await session.beginRound();
      for (final f in source.rep()) {
        bridge.emitFrame(f);
      }
      // Lifecycle interruption in an unfinished attempt must not bank a rep.
      for (final f in source.segment(160, to: 95, durationMs: 400)) {
        bridge.emitFrame(f);
      }
      await session.pause();
      await session.resume();
      for (final f in [...source.holdTop(900), ...source.rep()]) {
        bridge.emitFrame(f);
      }
      await session.endRound();
      final trace = session.diagnosticTrace!;
      final frozen = trace.text();
      expect(session.reps, 2);
      expect(
        replayTrace(frozen, ArenaExercise.pushUps)['counted_reps'],
        session.reps,
      );
      expect(frozen, contains('# round_completed: 1'));
      bridge.emitFrame(source.rep().last);
      expect(trace.text(), frozen);
    },
  );

  test(
    'end teardown cannot corrupt completed state or race fresh practice',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge)..enableDiagnosticTrace();
      addTearDown(session.dispose);
      final source = SyntheticPoseSource.pushups();
      await session.startPractice();
      for (final f in practiceOn(source)) {
        bridge.emitFrame(f);
      }
      await session.beginRound();
      bridge.pauseGate = Completer<void>();
      bridge.pauseError = const CameraBridgeException(
        CameraFailureCodes.cameraUnavailable,
        'teardown failed',
      );
      final ending = session.endRound();
      final next = session.startPractice();
      await Future<void>.delayed(Duration.zero);
      expect(session.phase, CameraSessionPhase.ended);
      expect(bridge.calls.where((c) => c == 'resume'), isEmpty);
      bridge.pauseGate!.complete();
      await ending;
      expect(await next, isTrue);
      expect(session.phase, CameraSessionPhase.practice);
      expect(session.snapshot.failure, isNull);
      expect(bridge.calls.last, 'resume');
    },
  );
  test(
    'short bottom dwell coaching describes timing without claiming depth',
    () {
      final message = rejectionInstruction(RepRejection.shallow);
      expect(message, contains('Pause briefly at the bottom'));
      expect(message, isNot(contains('too shallow')));
    },
  );
  test('unknown permission explains private on-device processing', () {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);

    expect(session.permission, CameraPermissionStatus.unknown);
    expect(session.instruction, contains('privately on this phone'));
    expect(session.instruction, contains('ever leaves the device'));
  });

  test('denied permission blocks practice and keeps the camera off', () async {
    final bridge = FakeCameraBridge()
      ..requestResult = CameraPermissionStatus.denied;
    final session = buildSession(bridge);
    addTearDown(session.dispose);

    final started = await session.startPractice();

    expect(started, isFalse);
    expect(session.phase, CameraSessionPhase.permissionRequired);
    expect(session.instruction, contains('Camera access is needed'));
    expect(bridge.calls, contains('requestPermission'));
    expect(bridge.calls, isNot(contains('startPreview:pushups')));
  });

  test(
    'permanent denial points at Settings and opens the settings page',
    () async {
      final bridge = FakeCameraBridge()
        ..requestResult = CameraPermissionStatus.permanentlyDenied
        ..checkResult = CameraPermissionStatus.permanentlyDenied;
      final session = buildSession(bridge);
      addTearDown(session.dispose);

      await session.requestPermission();
      expect(session.permission, CameraPermissionStatus.permanentlyDenied);
      expect(session.instruction, contains('Settings'));

      await session.openAppSettings();
      expect(bridge.calls, contains('openAppSettings'));
    },
  );

  test(
    'granted permission starts practice and exposes the preview texture',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);

      final started = await session.startPractice();

      expect(started, isTrue);
      expect(session.phase, CameraSessionPhase.practice);
      expect(session.previewTextureId, 42);
      expect(session.practiceComplete, isFalse);
      expect(session.reps, 0);
    },
  );

  test('practice rep completes practice and is flagged unscored', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    await session.startPractice();
    final events = <RepEvent>[];
    session.repEvents.listen(events.add);
    final source = SyntheticPoseSource.pushups(seed: 31);

    await feed(bridge, practiceOn(source));

    expect(session.practiceComplete, isTrue);
    expect(session.phase, CameraSessionPhase.ready);
    expect(events, hasLength(1));
    expect(events.single.practice, isTrue);
    expect(events.single.competitive, isFalse);
    expect(events.single.sequence, 1);
    expect(session.snapshot.readyForMatch, isTrue);
  });

  test(
    'readable partial-frame push-up completes practice with move-back cue',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);
      await session.startPractice();
      final events = <RepEvent>[];
      session.repEvents.listen(events.add);

      await feed(
        bridge,
        partialBodyFrames(loadPoseFixture('pushups_clean_rep.txt').frames),
      );

      expect(session.practiceComplete, isTrue);
      expect(events, hasLength(1));
      expect(events.single.practice, isTrue);
      expect(session.snapshot.readyForMatch, isTrue);
      expect(session.pauseReason, TrackingPauseReason.tooClose);
      expect(session.instruction, contains('Move the phone back'));
    },
  );

  test('a round cannot begin before the practice rep', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    await session.startPractice();

    expect(await session.beginRound(), isFalse);
    expect(session.phase, CameraSessionPhase.practice);
  });

  test('competitive round emits sequenced idempotent events', () async {
    final bridge = FakeCameraBridge();
    final observedAt = DateTime.utc(2026, 9, 18, 12);
    final session = buildSession(bridge, clock: () => observedAt);
    addTearDown(session.dispose);
    final source = SyntheticPoseSource.pushups(seed: 43);
    await session.startPractice();
    final events = <RepEvent>[];
    session.repEvents.listen(events.add);
    await feed(bridge, practiceOn(source));
    expect(await session.beginRound(), isTrue);
    expect(session.phase, CameraSessionPhase.live);
    expect(session.reps, 0);

    await feed(bridge, roundOn(source));
    await feed(bridge, roundOn(source));

    expect(session.reps, 2);
    expect(events, hasLength(3));
    final competitive = events.where((event) => event.competitive).toList();
    expect(competitive, hasLength(2));
    expect(competitive.map((event) => event.sequence), [1, 2]);
    expect(competitive.map((event) => event.eventId).toSet(), hasLength(2));
    for (final event in competitive) {
      expect(event.counterVersion, arenaCounterVersion);
      expect(event.observedAt, observedAt);
      expect(
        event.toArenaRepPayload().keys,
        containsAll(<String>[
          'event_id',
          'sequence',
          'observed_at',
          'counter_version',
        ]),
      );
      expect(event.toArenaRepPayload().keys, isNot(contains('match_id')));
    }
  });

  test('resetPractice clears practice without touching a live round', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final source = SyntheticPoseSource.pushups(seed: 45);
    await session.startPractice();
    await feed(bridge, practiceOn(source));
    expect(session.practiceComplete, isTrue);

    expect(await session.resetPractice(), isTrue);
    expect(session.practiceComplete, isFalse);
    expect(session.reps, 0);
    expect(session.phase, CameraSessionPhase.practice);

    await feed(bridge, practiceOn(source));
    expect(await session.beginRound(), isTrue);
    final events = <RepEvent>[];
    session.repEvents.listen(events.add);
    await feed(bridge, roundOn(source));
    final repsBefore = session.reps;
    final eventsBefore = events.length;

    await expectLater(session.resetPractice(), throwsStateError);

    expect(session.reps, repsBefore);
    expect(events, hasLength(eventsBefore));
    expect(session.phase, CameraSessionPhase.live);
  });

  test('pause discards the in-progress rep and resume reframes', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final source = SyntheticPoseSource.pushups(seed: 51);
    await session.startPractice();
    await feed(bridge, practiceOn(source));
    await session.beginRound();
    final events = <RepEvent>[];
    session.repEvents.listen(events.add);

    await feed(bridge, [
      ...source.holdTop(700),
      ...source.segment(
        source.topAngle,
        to: source.bottomAngle,
        durationMs: 700,
      ),
    ]);
    expect(session.reps, 0);

    await session.pause();
    expect(session.phase, CameraSessionPhase.paused);
    expect(session.instruction, contains('battle clock keeps running'));
    expect(bridge.calls, contains('pause'));

    await session.resume();
    expect(session.phase, CameraSessionPhase.live);
    expect(bridge.calls, contains('resume'));

    final continuation = source.segment(
      source.bottomAngle,
      to: source.topAngle,
      durationMs: 900,
    );
    await feed(bridge, continuation);
    expect(session.reps, 0);

    await feed(bridge, roundOn(source));
    expect(session.reps, 1);
    expect(events.where((event) => event.competitive), hasLength(1));
  });

  test('endRound freezes the count and stops counting frames', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final source = SyntheticPoseSource.pushups(seed: 53);
    await session.startPractice();
    await feed(bridge, practiceOn(source));
    await session.beginRound();
    await feed(bridge, roundOn(source));
    expect(session.reps, 1);

    expect(await session.endRound(), isTrue);
    await feed(bridge, roundOn(source));

    expect(session.reps, 1);
    expect(session.phase, CameraSessionPhase.ended);
  });

  test('endRound works while paused and keeps the camera released', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final source = SyntheticPoseSource.pushups(seed: 57);
    await session.startPractice();
    await feed(bridge, practiceOn(source));
    await session.beginRound();
    await feed(bridge, roundOn(source));
    expect(session.reps, 1);

    await session.pause();
    expect(await session.endRound(), isTrue);
    expect(session.phase, CameraSessionPhase.ended);
    expect(session.reps, 1);
    expect(bridge.calls, isNot(contains('resume')));

    await feed(bridge, roundOn(source));
    expect(session.reps, 1);
  });

  test('endRound while paused before the round started is refused', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final source = SyntheticPoseSource.pushups(seed: 59);
    await session.startPractice();
    await feed(bridge, practiceOn(source));
    expect(session.practiceComplete, isTrue);

    await session.pause();
    expect(await session.endRound(), isFalse);
    expect(session.phase, CameraSessionPhase.paused);
  });

  test('beginRound after a pause resumes the camera and counts', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final practiceSource = SyntheticPoseSource.pushups(seed: 63);
    await session.startPractice();
    await feed(bridge, practiceOn(practiceSource));
    expect(session.practiceComplete, isTrue);

    await session.pause();
    expect(await session.beginRound(), isTrue);
    expect(session.phase, CameraSessionPhase.live);
    expect(bridge.calls, contains('resume'));

    final roundSource = SyntheticPoseSource.pushups(seed: 64);
    final events = <RepEvent>[];
    session.repEvents.listen(events.add);
    await feed(bridge, roundOn(roundSource));
    expect(session.reps, 1);
    expect(events.where((event) => event.competitive), hasLength(1));
  });

  test('startPractice after a pause rebinds the camera', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    final firstSource = SyntheticPoseSource.pushups(seed: 65);
    await session.startPractice();
    await feed(bridge, practiceOn(firstSource));
    await session.pause();

    expect(await session.startPractice(), isTrue);
    expect(session.phase, CameraSessionPhase.practice);
    expect(bridge.calls, contains('resume'));

    final secondSource = SyntheticPoseSource.pushups(seed: 66);
    await feed(bridge, practiceOn(secondSource));
    expect(session.practiceComplete, isTrue);
  });

  test('resetPractice after a pause rebinds the camera', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    addTearDown(session.dispose);
    await session.startPractice();
    await session.pause();

    expect(await session.resetPractice(), isTrue);
    expect(session.phase, CameraSessionPhase.practice);
    expect(bridge.calls, contains('resume'));
  });

  test(
    'tracking loss keeps the round live and explains how to reframe',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);
      final source = SyntheticPoseSource.pushups(seed: 55);
      await session.startPractice();
      await feed(bridge, practiceOn(source));
      await session.beginRound();

      bridge.emitTracking(
        CameraTrackingState.searching,
        TrackingPauseReason.noPerson,
      );
      await Future<void>.delayed(Duration.zero);

      expect(session.phase, CameraSessionPhase.live);
      expect(session.tracking, CameraTrackingState.searching);
      expect(session.instruction, contains('I cannot see you'));
      expect(session.instruction, contains('shoulders and hands'));
    },
  );

  test('camera busy and missing camera failures are actionable', () async {
    final busyBridge = FakeCameraBridge()
      ..requestError = const CameraBridgeException('camera_busy', 'busy');
    final busySession = buildSession(busyBridge);
    addTearDown(busySession.dispose);
    expect(await busySession.startPractice(), isFalse);
    expect(busySession.instruction, contains('Close other camera apps'));

    final noCameraBridge = FakeCameraBridge()
      ..requestError = const CameraBridgeException('no_camera', 'none');
    final noCameraSession = buildSession(noCameraBridge);
    addTearDown(noCameraSession.dispose);
    expect(await noCameraSession.startPractice(), isFalse);
    expect(noCameraSession.phase, CameraSessionPhase.error);
    expect(noCameraSession.instruction, contains('working camera'));
  });

  test(
    'a detached pose stream surfaces its error instead of crashing',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);
      await session.startPractice();

      bridge.emitError('detector_failure', 'native detector unavailable');
      await Future<void>.delayed(Duration.zero);

      expect(session.phase, CameraSessionPhase.error);
      expect(session.instruction, contains('on-device pose detector'));
    },
  );

  test('dispose releases the bridge once and is idempotent', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge);
    await session.startPractice();
    var streamClosed = false;
    session.snapshots.listen(null, onDone: () => streamClosed = true);

    await session.dispose();
    await session.dispose();
    await session.pause();
    await session.resume();

    expect(bridge.disposeCount, 1);
    expect(session.phase, CameraSessionPhase.disposed);
    await Future<void>.delayed(Duration.zero);
    expect(streamClosed, isTrue);
    expect(
      bridge.calls.where((call) => call == 'startPreview:pushups'),
      hasLength(1),
    );
  });

  test(
    'lifecycle background pauses and foreground resumes the camera',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bridge = FakeCameraBridge();
      final session = CameraSessionController(
        bridge: bridge,
        exercise: ArenaExercise.squats,
        observeLifecycle: true,
        eventIdFactory: () => 'e',
      );
      addTearDown(session.dispose);
      await session.startPractice();

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await Future<void>.delayed(Duration.zero);
      expect(session.phase, CameraSessionPhase.paused);
      expect(bridge.calls, contains('pause'));

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await Future<void>.delayed(Duration.zero);
      expect(session.phase, CameraSessionPhase.practice);
      expect(bridge.calls, contains('resume'));
    },
  );

  test('debug fixture sessions are labeled and never competitive', () async {
    final source = SyntheticPoseSource.pushups(seed: 61);
    final frames = practiceOn(source);
    final script = FixtureScript(label: 'test-fixture', frames: frames);
    final bridge = FixtureCameraBridge(
      exercise: ArenaExercise.pushUps,
      script: script,
      autoPlay: false,
    );
    final session = CameraSession.debugFixture(
      exercise: ArenaExercise.pushUps,
      bridge: bridge,
      autoPlay: false,
    );
    addTearDown(session.dispose);
    expect(session.isCompetitive, isFalse);
    expect(session.demoLabel, contains('DEMO'));

    await session.startPractice();
    final events = <RepEvent>[];
    session.repEvents.listen(events.add);
    for (var i = 0; i < frames.length; i++) {
      bridge.emitNext();
    }
    await Future<void>.delayed(Duration.zero);

    expect(session.practiceComplete, isTrue);
    expect(events, isNotEmpty);
    expect(events.every((event) => !event.competitive), isTrue);
    expect(session.snapshot.canProduceMatchResult, isFalse);
  });

  test(
    'fixture bridge and debug session work without platform channels',
    () async {
      final bridge = FixtureCameraBridge(
        exercise: ArenaExercise.squats,
        autoPlay: false,
      );
      final session = CameraSession.debugFixture(
        exercise: ArenaExercise.squats,
        bridge: bridge,
        autoPlay: false,
      );
      addTearDown(session.dispose);

      expect(await session.startPractice(), isTrue);
      final info = await session.runtimeInfo();
      expect(info.detectorSdk, contains('synthetic'));
    },
  );

  test(
    'the landmark seam exposes exactly the frames the counter consumes',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);
      final source = SyntheticPoseSource.pushups(seed: 71);
      final seen = <PoseFrame>[];
      session.poseFrames.listen(seen.add);

      // No practice yet: the counter is not consuming frames, so nothing is
      // exposed to the UI.
      bridge.emitFrame(source.holdTop(100).first);
      await Future<void>.delayed(Duration.zero);
      expect(session.latestFrame, isNull);
      expect(seen, isEmpty);

      await session.startPractice();
      final frames = source.holdTop(200);
      await feed(bridge, frames);

      expect(seen, hasLength(frames.length));
      for (var i = 0; i < frames.length; i++) {
        expect(seen[i], same(frames[i]));
      }
      expect(session.latestFrame, same(frames.last));
    },
  );

  test(
    'the snapshot carries the counter view mode and counting side',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);
      await session.startPractice();
      final source = SyntheticPoseSource.pushups(seed: 73);

      await feed(bridge, [
        ...source.holdTop(800),
        ...source.segment(
          source.topAngle,
          to: source.bottomAngle,
          durationMs: 200,
        ),
      ]);

      expect(session.snapshot.viewMode, CameraViewMode.side);
      expect(session.snapshot.countingSide, PoseSide.left);
    },
  );

  test(
    'a head-on session reports the front view mode and no counting side',
    () async {
      final bridge = FakeCameraBridge();
      final session = buildSession(bridge);
      addTearDown(session.dispose);
      await session.startPractice();
      final source = SyntheticPoseSource.pushupsFront(seed: 75);

      await feed(bridge, source.holdTop(800));

      expect(session.snapshot.viewMode, CameraViewMode.front);
      expect(session.snapshot.countingSide, isNull);
    },
  );

  test('a recreated session starts a fresh preview and disposes its own bridge', () async {
    // Contract lock for the 2026-09-23 reopen bug: every session owns a bridge
    // and must run the full start/dispose cycle itself, so the native plugin
    // can drop its controller and rebuild on the next start. The native
    // regression itself is covered on-device by
    // `integration_test/camera_reopen_test.dart`.
    final firstBridge = FakeCameraBridge();
    final firstSession = buildSession(firstBridge);
    expect(await firstSession.startPractice(), isTrue);
    expect(firstBridge.calls, contains('startPreview:pushups'));
    await firstSession.dispose();
    expect(firstBridge.calls, contains('dispose'));

    final secondBridge = FakeCameraBridge();
    final secondSession = buildSession(secondBridge);
    expect(await secondSession.startPractice(), isTrue);
    expect(secondBridge.calls, contains('startPreview:pushups'));
    expect(secondBridge.disposeCount, 0);
    await secondSession.dispose();
    expect(secondBridge.disposeCount, 1);
  });

  test('a judged-but-rejected rep rides the snapshot and is cleared by the next count', () async {
    final bridge = FakeCameraBridge();
    final session = buildSession(bridge, exercise: ArenaExercise.squats);
    addTearDown(session.dispose);
    await session.startPractice();

    await feed(bridge, practiceOn(SyntheticPoseSource.squats()));
    expect(session.practiceComplete, isTrue);
    expect(await session.beginRound(), isTrue);

    // Every bottom frame of this rep folds the torso past the lean limit, so
    // the rep is judged and rejected, never counted.
    final source = SyntheticPoseSource.squats();
    await feed(bridge, [
      ...source.rep(
        descendMs: 800,
        bottomHoldMs: 300,
        ascendMs: 800,
        torsoLean: 70,
      ),
      ...source.holdTop(200),
    ]);

    expect(session.snapshot.lastRepRejection, RepRejection.torsoCollapsed);
    expect(session.snapshot.lastRepRejectionMicros, isNotNull);
    expect(session.reps, 0);
    expect(
      rejectionInstruction(session.snapshot.lastRepRejection),
      contains('chest up'),
    );

    // The next clean rep counts and clears the rejection.
    await feed(bridge, [...source.rep(), ...source.holdTop(200)]);

    expect(session.reps, 1);
    expect(session.snapshot.lastRepRejection, RepRejection.none);
    expect(rejectionInstruction(session.snapshot.lastRepRejection), isEmpty);
  });
}
