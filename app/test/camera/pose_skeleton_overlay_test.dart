import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  group('poseOverlayPoint', () {
    test('native crop mapping and mirror override fixture geometry', () {
      const geometry = CameraPreviewGeometry(
        width: 480,
        height: 640,
        crop: [60, 0, 420, 640],
        textureQuarterTurns: 1,
        mirrored: true,
        analysisToPreview: [1.5, 0, -0.25, 0, 1, 0],
      );
      final point = poseOverlayPoint(
        normalised: const Offset(1 / 6, 0.25),
        boxSize: const Size(360, 640),
        frameSize: const Size(1, 1),
        geometry: geometry,
      );
      expect(point.dx, closeTo(360, 0.001));
      expect(point.dy, closeTo(160, 0.001));
    });
    test('identity: a box the size of the frame maps 1:1', () {
      const box = Size(400, 400);
      const frame = Size(400, 400);
      Offset at(double x, double y) => poseOverlayPoint(
            normalised: Offset(x, y),
            boxSize: box,
            frameSize: frame,
          );

      expect(at(0, 0), const Offset(0, 0));
      expect(at(0.5, 0.5), const Offset(200, 200));
      expect(at(1, 1), const Offset(400, 400));
      expect(at(0.25, 0.75), const Offset(100, 300));
    });

    test('cover crops the overflowing axis and keeps the centre', () {
      // A 200x200 frame in a 400x200 box: the middle vertical half is shown.
      const box = Size(400, 200);
      const frame = Size(200, 200);
      Offset at(double x, double y) => poseOverlayPoint(
            normalised: Offset(x, y),
            boxSize: box,
            frameSize: frame,
          );

      expect(at(0.5, 0.5), const Offset(200, 100));
      expect(at(0.5, 0.25), const Offset(200, 0));
      expect(at(0.5, 0.75), const Offset(200, 200));
      expect(at(0.25, 0.5), const Offset(100, 100));
      // The frame top (y = 0) is cropped above the box.
      expect(at(0, 0), const Offset(0, -100));
    });

    test('contain letterboxes and shrinks the frame', () {
      // A 200x200 frame in a 400x200 box: 100px bars on each side.
      const box = Size(400, 200);
      const frame = Size(200, 200);
      Offset at(double x, double y) => poseOverlayPoint(
            normalised: Offset(x, y),
            boxSize: box,
            frameSize: frame,
            fit: BoxFit.contain,
          );

      expect(at(0, 0), const Offset(100, 0));
      expect(at(0.5, 0.5), const Offset(200, 100));
      expect(at(1, 1), const Offset(300, 200));
    });

    test('mirror flips x in display space', () {
      const box = Size(400, 400);
      const frame = Size(400, 400);
      Offset at(double x, double y) => poseOverlayPoint(
            normalised: Offset(x, y),
            boxSize: box,
            frameSize: frame,
            mirrored: true,
          );

      expect(at(0.25, 0.75), const Offset(300, 300));
      expect(at(0, 0), const Offset(400, 0));
      expect(at(1, 1), const Offset(0, 400));
    });

    test('rotation is clockwise quarter turns', () {
      const box = Size(400, 400);
      const frame = Size(400, 400);
      Offset at(int turns, double x, double y) => poseOverlayPoint(
            normalised: Offset(x, y),
            boxSize: box,
            frameSize: frame,
            quarterTurns: turns,
          );

      expect(at(0, 0.25, 0.75), const Offset(100, 300));
      expect(at(1, 0.25, 0.75), const Offset(100, 100));
      expect(at(2, 0.25, 0.75), const Offset(300, 100));
      expect(at(3, 0.25, 0.75), const Offset(300, 300));
      expect(at(4, 0.25, 0.75), const Offset(100, 300));
    });

    test('rotation swaps the displayed frame size', () {
      // A portrait 100x200 frame rotated 90 degrees is displayed landscape.
      const box = Size(400, 400);
      const frame = Size(200, 100);
      final centred = poseOverlayPoint(
        normalised: const Offset(0.5, 0.5),
        boxSize: box,
        frameSize: frame,
        quarterTurns: 1,
      );

      expect(centred, const Offset(200, 200));
    });

    test('mirror applies after rotation', () {
      const box = Size(400, 400);
      const frame = Size(400, 400);
      final point = poseOverlayPoint(
        normalised: const Offset(0.25, 0.75),
        boxSize: box,
        frameSize: frame,
        quarterTurns: 1,
        mirrored: true,
      );

      // Rotate 90 degrees: (0.25, 0.75) -> (0.25, 0.25); mirror -> (0.75, 0.25).
      expect(point, const Offset(300, 100));
    });
  });

  group('skeleton chains', () {
    test('the standard skeleton connects both sides and the nose', () {
      expect(
        poseSkeletonSegments,
        containsAll(const [
          (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
          (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
          (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
          (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
          (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
          (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
          (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
          (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
          (PoseLandmarkType.nose, PoseLandmarkType.leftShoulder),
          (PoseLandmarkType.nose, PoseLandmarkType.rightShoulder),
        ]),
      );
    });

    test('side-view push-ups highlight the selected arm chain and elbow', () {
      final chain = poseCountingChain(
        exercise: ArenaExercise.pushUps,
        viewMode: CameraViewMode.side,
        side: PoseSide.right,
      );

      expect(chain.segments, const [
        (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
        (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      ]);
      expect(chain.primaryJoint, PoseLandmarkType.rightElbow);
    });

    test('side-view squats highlight the selected leg chain and knee', () {
      final chain = poseCountingChain(
        exercise: ArenaExercise.squats,
        viewMode: CameraViewMode.side,
        side: PoseSide.left,
      );

      expect(chain.segments, const [
        (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
        (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
      ]);
      expect(chain.primaryJoint, PoseLandmarkType.leftKnee);
    });

    test('side view before a side is selected highlights nothing', () {
      final chain = poseCountingChain(
        exercise: ArenaExercise.pushUps,
        viewMode: CameraViewMode.side,
        side: null,
      );

      expect(chain.segments, isEmpty);
      expect(chain.primaryJoint, isNull);
    });

    test('front view highlights the shoulder line, hand line and torso', () {
      final chain = poseCountingChain(
        exercise: ArenaExercise.pushUps,
        viewMode: CameraViewMode.front,
        side: PoseSide.left,
      );

      expect(chain.segments, const [
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
        (PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist),
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
        (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      ]);
      expect(chain.primaryJoint, isNull);
    });

    test(
      'front-view squats are refused by the counter, so nothing highlights',
      () {
        final chain = poseCountingChain(
          exercise: ArenaExercise.squats,
          viewMode: CameraViewMode.front,
          side: PoseSide.left,
        );

        expect(chain.segments, isEmpty);
      },
    );
  });

  group('PoseSkeletonOverlay', () {
    Future<CameraSession> sessionWith(
      WidgetTester tester,
      FixtureScript script,
    ) async {
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
      await session.startPractice();
      return session;
    }

    testWidgets('paints a synthetic session frame without errors', (
      tester,
    ) async {
      final source = SyntheticPoseSource.pushups(seed: 81);
      final session = await sessionWith(
        tester,
        FixtureScript(label: 'overlay', frames: source.holdTop(200)),
      );

      await tester.pumpWidget(
        MaterialApp(home: PoseSkeletonOverlay(session: session)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);
    });

    testWidgets('an empty landmark frame paints safely', (tester) async {
      final session = await sessionWith(
        tester,
        FixtureScript(label: 'empty', frames: [SyntheticPose.noPerson(1000)]),
      );

      await tester.pumpWidget(
        MaterialApp(home: PoseSkeletonOverlay(session: session)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);
    });

    testWidgets('a partial head-on frame paints safely', (tester) async {
      // The front fixture omits knees and ankles, as a real head-on detection
      // of a floor-level push-up does.
      final frame = SyntheticPose.pushupFrontFrame(
        timestampMicros: 1000,
        elbowAngle: 160,
      );
      final session = await sessionWith(
        tester,
        FixtureScript(label: 'partial', frames: [frame]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PoseSkeletonOverlay(
            session: session,
            viewMode: CameraViewMode.front,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('pose-skeleton')), findsOneWidget);
    });

    testWidgets('active false and visible false draw nothing', (tester) async {
      final source = SyntheticPoseSource.pushups(seed: 83);
      final session = await sessionWith(
        tester,
        FixtureScript(label: 'hidden', frames: source.holdTop(200)),
      );

      await tester.pumpWidget(
        MaterialApp(home: PoseSkeletonOverlay(session: session, active: false)),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pose-skeleton')), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: PoseSkeletonOverlay(session: session, visible: false),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pose-skeleton')), findsNothing);
    });

    testWidgets('a later frame repaints the canvas', (tester) async {
      final source = SyntheticPoseSource.pushups(seed: 85);
      final session = await sessionWith(
        tester,
        FixtureScript(label: 'repaint', frames: source.holdTop(200)),
      );
      await tester.pumpWidget(
        MaterialApp(home: PoseSkeletonOverlay(session: session)),
      );
      await tester.pump();
      final paint = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('pose-skeleton')),
      );
      final painter = paint.painter! as PoseSkeletonPainter;

      expect(painter.shouldRepaint(painter), isFalse);
      expect(
        painter.shouldRepaint(
          PoseSkeletonPainter(
            frame: ValueNotifier<PoseFrame?>(null),
            exercise: ArenaExercise.squats,
          ),
        ),
        isTrue,
      );
    });

    testWidgets('the selected chain is painted in lime', (tester) async {
      final boundaryKey = GlobalKey();
      final bridge = FixtureCameraBridge(
        exercise: ArenaExercise.pushUps,
        script: FixtureScript(
          label: 'pixels',
          frames: [
            SyntheticPose.pushupFrame(timestampMicros: 1000, elbowAngle: 160),
          ],
        ),
        autoPlay: false,
      );
      final session = CameraSession.debugFixture(
        exercise: ArenaExercise.pushUps,
        bridge: bridge,
        autoPlay: false,
      );
      addTearDown(session.dispose);
      await session.startPractice();

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 300,
                height: 600,
                child: PoseSkeletonOverlay(
                  session: session,
                  side: PoseSide.left,
                ),
              ),
            ),
          ),
        ),
      );
      bridge.emitNext();
      await tester.pump();

      final data = await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes;
      });
      final pixels = data!.buffer.asUint8List();
      var lime = 0;
      for (var i = 0; i + 3 < pixels.length; i += 4) {
        if (pixels[i] > 200 &&
            pixels[i + 1] > 240 &&
            pixels[i + 2] < 90 &&
            pixels[i + 3] > 200) {
          lime++;
        }
      }

      expect(lime, greaterThan(20), reason: 'the lime chain should be visible');
    });

    testWidgets('the counting chain flashes warning while a rep is rejected', (
      tester,
    ) async {
      final boundaryKey = GlobalKey();
      final bridge = FixtureCameraBridge(
        exercise: ArenaExercise.pushUps,
        script: FixtureScript(
          label: 'pixels-reject',
          frames: [
            SyntheticPose.pushupFrame(timestampMicros: 1000, elbowAngle: 160),
          ],
        ),
        autoPlay: false,
      );
      final session = CameraSession.debugFixture(
        exercise: ArenaExercise.pushUps,
        bridge: bridge,
        autoPlay: false,
      );
      addTearDown(session.dispose);
      await session.startPractice();

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 300,
                height: 600,
                child: PoseSkeletonOverlay(
                  session: session,
                  side: PoseSide.left,
                  rejectFlash: true,
                ),
              ),
            ),
          ),
        ),
      );
      bridge.emitNext();
      await tester.pump();

      final data = await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes;
      });
      final pixels = data!.buffer.asUint8List();
      var lime = 0;
      var warning = 0;
      for (var i = 0; i + 3 < pixels.length; i += 4) {
        final isLime = pixels[i] > 200 &&
            pixels[i + 1] > 240 &&
            pixels[i + 2] < 90 &&
            pixels[i + 3] > 200;
        final isWarning = pixels[i] > 240 &&
            pixels[i + 1] > 180 &&
            pixels[i + 1] < 235 &&
            pixels[i + 2] > 80 &&
            pixels[i + 2] < 140 &&
            pixels[i + 3] > 200;
        if (isLime) {
          lime++;
        }
        if (isWarning) {
          warning++;
        }
      }

      expect(
        warning,
        greaterThan(20),
        reason: 'the flashing chain should be visible',
      );
      expect(lime, 0, reason: 'no lime chain should remain while flashing');
    });
  });
}
