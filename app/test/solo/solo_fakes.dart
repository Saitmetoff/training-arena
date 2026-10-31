/// Test double for the solo camera seam.
///
/// Scripts the [CameraSession] contract without a platform bridge so the solo
/// controller can be driven deterministically. Counting itself is covered by
/// `test/camera/`; this fake only reports scripted state.
library;

import 'dart:async';

import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/domain/arena_types.dart';

class FakeSoloCamera implements CameraSession {
  FakeSoloCamera({this.exercise = ArenaExercise.pushUps});

  final StreamController<CameraSessionSnapshot> _snapshots =
      StreamController<CameraSessionSnapshot>.broadcast(sync: true);
  final StreamController<RepEvent> _repEvents =
      StreamController<RepEvent>.broadcast(sync: true);

  @override
  final ArenaExercise exercise;

  final List<String> calls = <String>[];
  bool permissionGranted = true;
  bool practiceStarts = true;
  bool roundStarts = true;
  int countedReps = 0;
  bool practiceDone = false;
  CameraSessionPhase currentPhase = CameraSessionPhase.idle;
  int disposeCount = 0;

  @override
  CameraPermissionStatus get permission => permissionGranted
      ? CameraPermissionStatus.granted
      : CameraPermissionStatus.denied;

  @override
  CameraSessionPhase get phase => currentPhase;

  @override
  CameraTrackingState get tracking => CameraTrackingState.tracking;

  @override
  TrackingPauseReason get pauseReason => TrackingPauseReason.none;

  @override
  String get instruction => 'test instruction';

  @override
  bool get practiceComplete => practiceDone;

  @override
  int get reps => countedReps;

  @override
  bool get isCompetitive => true;

  @override
  String? get demoLabel => null;

  @override
  int? get previewTextureId => null;

  @override
  PoseFrame? get latestFrame => null;

  @override
  Stream<PoseFrame> get poseFrames => const Stream<PoseFrame>.empty();

  @override
  CameraFailure? get failure => null;

  @override
  CameraSessionSnapshot get snapshot => CameraSessionSnapshot(
        exercise: exercise,
        permission: permission,
        phase: currentPhase,
        tracking: tracking,
        pauseReason: pauseReason,
        instruction: instruction,
        practiceComplete: practiceDone,
        reps: countedReps,
        framingLocked: true,
        trackingConfidence: 1,
        isCompetitive: true,
      );

  @override
  Stream<CameraSessionSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<RepEvent> get repEvents => _repEvents.stream;

  /// Publishes the current scripted state to [snapshots].
  void emit() => _snapshots.add(snapshot);

  /// Completes the practice rep and moves the session to ready.
  void completePractice() {
    practiceDone = true;
    currentPhase = CameraSessionPhase.ready;
    emit();
  }

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return permissionGranted;
  }

  @override
  Future<bool> openAppSettings() async {
    calls.add('openAppSettings');
    return true;
  }

  @override
  Future<bool> startPractice() async {
    calls.add('startPractice');
    if (!practiceStarts) {
      return false;
    }
    currentPhase = CameraSessionPhase.practice;
    emit();
    return true;
  }

  @override
  Future<bool> beginRound() async {
    calls.add('beginRound');
    if (!roundStarts) {
      return false;
    }
    currentPhase = CameraSessionPhase.live;
    emit();
    return true;
  }

  @override
  Future<bool> endRound() async {
    calls.add('endRound');
    currentPhase = CameraSessionPhase.ended;
    emit();
    return true;
  }

  @override
  Future<bool> resetPractice() async {
    calls.add('resetPractice');
    practiceDone = false;
    return true;
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> setTorch(bool enabled) async => calls.add('setTorch:$enabled');

  @override
  Future<CameraRuntimeInfo> runtimeInfo() async => const CameraRuntimeInfo(
        detectorSdk: 'test',
        detectorModel: 'test',
        cameraStack: 'test',
        minSdk: 24,
        apiLevel: 34,
        deviceName: 'test',
      );

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    disposeCount += 1;
    await _snapshots.close();
    await _repEvents.close();
  }
}
