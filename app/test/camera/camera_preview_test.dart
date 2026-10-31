import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/trace/pose_trace_recorder.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fixture_replay.dart';

/// Fixture bridge that reports a real texture id, so the preview renders the
/// overlay path instead of the synthetic placeholder.
class _TextureFixtureBridge extends FixtureCameraBridge {
  _TextureFixtureBridge({required super.exercise, super.script, super.autoPlay})
      : super(
          previewGeometry: const CameraPreviewGeometry(
            width: 480,
            height: 640,
            crop: [0, 0, 480, 640],
            analysisToPreview: [1, 0, 0, 0, 1, 0],
            textureQuarterTurns: 0,
            mirrored: true,
          ),
        );

  @override
  Future<int> startPreview(ArenaExercise exercise) async {
    await super.startPreview(exercise);
    return 42;
  }
}

void main() {
  testWidgets('preview shows the demo label and never a fake texture', (
    tester,
  ) async {
    final source = SyntheticPoseSource.pushups(seed: 71);
    final frames = [...source.holdTop(800), ...source.rep()];
    final bridge = FixtureCameraBridge(
      exercise: ArenaExercise.pushUps,
      script: FixtureScript(label: 'preview-fixture', frames: frames),
    );
    final session = CameraSession.debugFixture(
      exercise: ArenaExercise.pushUps,
      bridge: bridge,
      autoPlay: false,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(MaterialApp(home: CameraPreview(session: session)));
    await session.startPractice();
    await tester.pump();

    expect(find.text('DEMO FIXTURE — NOT COUNTED'), findsOneWidget);
    expect(find.text('Synthetic fixture preview'), findsOneWidget);
    expect(find.byType(Texture), findsNothing);
    expect(find.byKey(const ValueKey('pose-skeleton')), findsNothing);
  });

  testWidgets('preview instruction follows tracking loss', (tester) async {
    final bridge = FixtureCameraBridge(
      exercise: ArenaExercise.squats,
      script: const FixtureScript(label: 'empty', frames: []),
    );
    final session = CameraSession.debugFixture(
      exercise: ArenaExercise.squats,
      bridge: bridge,
      autoPlay: false,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(MaterialApp(home: CameraPreview(session: session)));
    await session.startPractice();
    await session.pause();
    await tester.pump();

    expect(find.textContaining('battle clock keeps running'), findsOneWidget);
  });

  testWidgets(
    'the skeleton overlays the texture and the hide control toggles it',
    (tester) async {
      final source = SyntheticPoseSource.pushups(
        seed: 91,
        intervalMicros: 66000,
      );
      final script = FixtureScript(
        label: 'overlay',
        frames: [...source.holdTop(800), ...source.rep()],
      );
      final bridge = _TextureFixtureBridge(
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

      await tester.pumpWidget(
        MaterialApp(home: CameraPreview(session: session)),
      );
      await session.startPractice();
      for (final _ in script.frames) {
        bridge.emitNext();
      }
      await tester.pump();

      expect(find.byType(Texture), findsOneWidget);
      expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);
      final toggle = find.byKey(const ValueKey('camera-skeleton-toggle'));
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pump();
      expect(find.byKey(const ValueKey('pose-skeleton')), findsNothing);

      await tester.tap(toggle);
      await tester.pump();
      expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);

      // The practice rep completes and the phase moves to ready: the choice
      // persists for the camera session.
      expect(session.phase, CameraSessionPhase.ready);
      expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);
    },
  );

  testWidgets('a paused session draws no skeleton', (tester) async {
    final source = SyntheticPoseSource.pushups(seed: 93, intervalMicros: 66000);
    final script = FixtureScript(label: 'pause', frames: source.holdTop(800));
    final bridge = _TextureFixtureBridge(
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

    await tester.pumpWidget(MaterialApp(home: CameraPreview(session: session)));
    await session.startPractice();
    for (final _ in script.frames) {
      bridge.emitNext();
    }
    await tester.pump();
    expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);

    await session.pause();
    await tester.pump();
    expect(find.byKey(const ValueKey('pose-skeleton')), findsNothing);
  });

  testWidgets('the debug trace bar records, exports and deletes a trace', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'arena-preview-trace',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = SyntheticPoseSource.pushups(seed: 95, intervalMicros: 66000);
    final script = FixtureScript(label: 'trace', frames: source.holdTop(800));
    final bridge = _TextureFixtureBridge(
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

    await tester.pumpWidget(
      MaterialApp(
        home: ArenaConfigScope(
          config: const ArenaConfig(
            publicUrl: 'https://example.invalid',
            linkHost: 'example.invalid',
            supabaseUrl: '',
            supabaseAnonKey: '',
            cameraTraceEnabled: true,
          ),
          child: CameraPreview(
            session: session,
            traceDirectory: () async => directory,
          ),
        ),
      ),
    );
    await session.startPractice();
    for (final _ in script.frames) {
      bridge.emitNext();
    }
    await tester.pump();

    expect(find.textContaining('TRACE ON'), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-trace-export')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('camera-trace-export')));
    await tester.pump();
    await tester.pump();

    final files = PoseTraceRecorder.storedFiles(directory);
    expect(files, hasLength(1));
    final exported = files.single.readAsStringSync();
    expect(exported, contains('# exercise: pushups'));
    expect(exported, contains('# in_app_reps: 0'));
    final fixture = parsePoseFixture(exported, name: 'exported');
    expect(fixture.frames, hasLength(script.frames.length));
    expect(find.textContaining('trace-pushups-'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('camera-trace-delete')));
    await tester.pump();
    await tester.pump();
    expect(find.text('TRACE CLEARED'), findsOneWidget);
    expect(PoseTraceRecorder.storedFiles(directory), isEmpty);
  });

  testWidgets(
    'the front-camera preview and the skeleton are mirrored together',
    (tester) async {
      final script = FixtureScript(
        label: 'mirror',
        frames: SyntheticPoseSource.pushups(seed: 99).holdTop(200),
      );
      final bridge = _TextureFixtureBridge(
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

      await tester.pumpWidget(
        MaterialApp(home: CameraPreview(session: session)),
      );
      await session.startPractice();
      await tester.pump();

      expect(CameraPreview.previewMirrored, isTrue);
      final overlay = tester.widget<PoseSkeletonOverlay>(
        find.byType(PoseSkeletonOverlay),
      );
      expect(overlay.mirrored, isTrue);
      expect(
        find.descendant(
          of: find.byType(Transform),
          matching: find.byType(Texture),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('tracing stays off without the compile-time flag', (
    tester,
  ) async {
    final script = FixtureScript(
      label: 'no-trace',
      frames: SyntheticPoseSource.pushups(seed: 97).holdTop(200),
    );
    final bridge = _TextureFixtureBridge(
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

    await tester.pumpWidget(MaterialApp(home: CameraPreview(session: session)));
    await session.startPractice();
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-trace-label')), findsNothing);
  });

  testWidgets('a judged rep that fails the check shows a transient cue card', (
    tester,
  ) async {
    final source = SyntheticPoseSource.squats();
    final practice = [...source.holdTop(800), ...source.rep()];
    final tail = source.holdTop(200);
    // Every bottom frame folds the torso past the lean limit: judged, rejected.
    final badRep = [
      ...source.rep(
        descendMs: 800,
        bottomHoldMs: 300,
        ascendMs: 800,
        torsoLean: 70,
      ),
    ];
    final bridge = _TextureFixtureBridge(
      exercise: ArenaExercise.squats,
      script: FixtureScript(
        label: 'rep-cue',
        frames: [...practice, ...tail, ...badRep],
      ),
    );
    final session = CameraSession.debugFixture(
      exercise: ArenaExercise.squats,
      bridge: bridge,
      autoPlay: false,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(MaterialApp(home: CameraPreview(session: session)));
    await session.startPractice();

    for (var i = 0; i < practice.length + tail.length; i++) {
      bridge.emitNext();
      await tester.pump();
    }
    expect(session.practiceComplete, isTrue);
    await session.beginRound();
    await tester.pump();

    for (var i = 0; i < badRep.length; i++) {
      bridge.emitNext();
      await tester.pump();
    }

    expect(find.byKey(const ValueKey('camera-rep-cue')), findsOneWidget);
    expect(find.textContaining('chest up'), findsOneWidget);

    // The cue is transient: it dismisses itself after its window.
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump();
    expect(find.byKey(const ValueKey('camera-rep-cue')), findsNothing);
  });
}
