import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/camera/pose/pose_types.dart';
import 'package:training_arena/camera/trace/pose_trace_format.dart';
import 'package:training_arena/camera/trace/pose_trace_recorder.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fixture_replay.dart';

void main() {
  group('PoseTraceRecorder', () {
    test('keeps the last window of frames and writes the replay format', () {
      final source = SyntheticPoseSource.pushups(seed: 11, intervalMicros: 33000);
      final frames = source.holdTop(800);
      final recorder = PoseTraceRecorder(
        exercise: ArenaExercise.pushUps,
        window: const Duration(milliseconds: 200),
      );

      for (final frame in frames) {
        recorder.add(frame);
      }

      // 200 ms of a 33 ms stream: the newest frames only.
      expect(recorder.frameCount, inInclusiveRange(6, 8));
      expect(recorder.frameCount, lessThan(frames.length));

      final fixture = parsePoseFixture(recorder.text(), name: 'ring');
      expect(fixture.frames, hasLength(recorder.frameCount));
      expect(fixture.frames.last.timestampMicros, frames.last.timestampMicros);
      expect(fixture.frames.last.luminance, closeTo(frames.last.luminance, 1e-4));

      final original = frames.last;
      final parsed = fixture.frames.last;
      for (final type in original.landmarks.asMap().keys) {
        final point = original.landmarks[type];
        final roundTripped = parsed.landmarks[type];
        if (point == null) {
          expect(roundTripped, isNull);
          continue;
        }
        expect(roundTripped, isNotNull);
        expect(roundTripped!.x, closeTo(point.x, 1e-6));
        expect(roundTripped.y, closeTo(point.y, 1e-6));
        expect(roundTripped.likelihood, closeTo(point.likelihood, 1e-4));
      }
    });

    test('an empty frame is written as a person-less frame', () {
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.squats);
      recorder.add(SyntheticPose.noPerson(1000));

      final fixture = parsePoseFixture(recorder.text(), name: 'empty');
      expect(fixture.frames, hasLength(1));
      expect(fixture.frames.single.hasPose, isFalse);
    });

    test('a partial frame omits the missing landmarks', () {
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.pushUps);
      recorder.add(
        SyntheticPose.pushupFrontFrame(timestampMicros: 1000, elbowAngle: 160),
      );

      final fixture = parsePoseFixture(recorder.text(), name: 'partial');
      final frame = fixture.frames.single;
      expect(frame.hasPose, isTrue);
      expect(frame.point(PoseLandmarkType.leftWrist), isNotNull);
      expect(frame.point(PoseLandmarkType.leftAnkle), isNull);
    });

    test('the trace header names the exercise and the in-app count', () {
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.pushUps);
      recorder.add(
        SyntheticPose.pushupFrame(timestampMicros: 1000, elbowAngle: 160),
      );

      final text = recorder.text(inAppReps: 20);
      expect(text, contains('# exercise: pushups'));
      expect(text, contains('# in_app_reps: 20'));
      expect(parsePoseFixture(text, name: 'header').frames, hasLength(1));
    });

    test('clear forgets the window without touching stored files', () {
      final directory = Directory.systemTemp.createTempSync('arena-trace');
      addTearDown(() => directory.deleteSync(recursive: true));
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.pushUps);
      recorder.add(
        SyntheticPose.pushupFrame(timestampMicros: 1000, elbowAngle: 160),
      );
      final file = recorder.save(directory, now: DateTime(2026, 9, 24, 14, 30));

      recorder.clear();

      expect(recorder.isEmpty, isTrue);
      expect(file.existsSync(), isTrue);
    });

    test('save writes an app-private file whose name has no device value', () {
      final directory = Directory.systemTemp.createTempSync('arena-trace');
      addTearDown(() => directory.deleteSync(recursive: true));
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.squats);
      recorder.add(
        SyntheticPose.squatFrame(timestampMicros: 1000, kneeAngle: 175),
      );

      final file = recorder.save(
        directory,
        inAppReps: 5,
        now: DateTime(2026, 9, 24, 14, 30, 5),
      );

      expect(
        file.uri.pathSegments.last,
        'trace-squats-20260924-143005.txt',
      );
      expect(
        PoseTraceRecorder.storedFiles(directory).map((f) => f.path),
        contains(file.path),
      );
      final fixture = parsePoseFixture(file.readAsStringSync(), name: 'saved');
      expect(fixture.frames, hasLength(1));
      expect(fixture.frames.single.point(PoseLandmarkType.leftKnee), isNotNull);
    });

    test('two saves in the same second get distinct files', () {
      final directory = Directory.systemTemp.createTempSync('arena-trace');
      addTearDown(() => directory.deleteSync(recursive: true));
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.pushUps);
      recorder.add(
        SyntheticPose.pushupFrame(timestampMicros: 1000, elbowAngle: 160),
      );
      final now = DateTime(2026, 9, 24, 14, 30, 5);

      final first = recorder.save(directory, now: now);
      final second = recorder.save(directory, now: now);

      expect(first.path, isNot(second.path));
      expect(PoseTraceRecorder.storedFiles(directory), hasLength(2));
    });

    test('deleteStored removes the traces and nothing else', () {
      final directory = Directory.systemTemp.createTempSync('arena-trace');
      addTearDown(() => directory.deleteSync(recursive: true));
      final unrelated = File('${directory.path}${Platform.pathSeparator}notes.txt')
        ..writeAsStringSync('keep me');
      final recorder = PoseTraceRecorder(exercise: ArenaExercise.pushUps);
      recorder.add(
        SyntheticPose.pushupFrame(timestampMicros: 1000, elbowAngle: 160),
      );
      recorder.save(directory, now: DateTime(2026, 9, 24, 14, 30));

      PoseTraceRecorder.deleteStored(directory);

      expect(PoseTraceRecorder.storedFiles(directory), isEmpty);
      expect(unrelated.existsSync(), isTrue);
    });

    test('directoryFor stays under the given documents directory', () {
      final documents = Directory.systemTemp.createTempSync('arena-docs');
      addTearDown(() => documents.deleteSync(recursive: true));

      final traces = PoseTraceRecorder.directoryFor(documents);

      expect(traces.path, startsWith(documents.path));
      expect(traces.path, endsWith('camera-traces'));
    });
  });

  group('pose_trace_format', () {
    test('writes the documented v1 layout byte for byte', () {
      final frame = PoseFrame.of(
        timestampMicros: 1234,
        luminance: 0.5,
        points: {
          PoseLandmarkType.nose:
              const PosePoint(x: 0.25, y: 0.5, likelihood: 0.9),
          PoseLandmarkType.leftWrist:
              const PosePoint(x: 1.5, y: 0.75, likelihood: 0.8),
        },
      );

      expect(
        serializePoseFrames([frame]),
        '# Training Arena pose fixture v1\n'
        '# timestampMicros,luminance|index,x,y,likelihood|...\n'
        '1234,0.5000|0,0.250000,0.500000,0.9000'
        '|15,1.500000,0.750000,0.8000\n',
      );
    });

    test('the format stays numbers-only', () {
      final frames = [
        SyntheticPose.pushupFrame(timestampMicros: 33000, elbowAngle: 160),
      ];

      final text = serializePoseTrace(frames, exercise: ArenaExercise.pushUps);
      for (final line in text.split('\n')) {
        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }
        expect(line, matches(RegExp(r'^[0-9.,|\-]+$')));
      }
    });
  });
}
