/// Deterministic, visibly non-competitive fixture session.
///
/// The fixture replays synthetic landmarks through the same counter as the
/// real camera, so the counting logic can be demonstrated offline. It is not
/// a detector, never touches the native channels, and every event it produces
/// is flagged `competitive: false`. It exists for tests, UI development and
/// labeled offline demos; it must never be used to claim device accuracy.
library;

import 'dart:async';

import '../../domain/arena_types.dart';
import '../camera_types.dart';
import '../debug/synthetic_pose.dart';
import '../pose/pose_types.dart';
import 'camera_bridge.dart';

/// One scripted cue at a frame index.
class FixtureCue {
  const FixtureCue({required this.frameIndex, required this.event});

  final int frameIndex;
  final CameraCueEvent event;
}

/// Deterministic frame list plus interleaved cues.
class FixtureScript {
  const FixtureScript({
    required this.label,
    required this.frames,
    this.cues = const [],
  });

  final String label;
  final List<PoseFrame> frames;
  final List<FixtureCue> cues;
}

/// Builds the labeled demo script for one exercise. The script contains a
/// framing lead-in, complete reps, a dark tracking-loss segment (the player
/// must reframe) and top-of-movement jitter.
FixtureScript buildFixtureScript(
  ArenaExercise exercise, {
  int seed = 7,
  int intervalMicros = 66000,
}) {
  final source = exercise == ArenaExercise.pushUps
      ? SyntheticPoseSource.pushups(intervalMicros: intervalMicros, seed: seed)
      : SyntheticPoseSource.squats(intervalMicros: intervalMicros, seed: seed);

  source.holdTop(1000);
  source.rep();
  source.rep();
  final lostAt = source.frames.length;
  source.trackingLoss(700, dark: true);
  source.holdTop(900);
  source.rep();
  source.jitterTop(400);
  source.rep();

  final cues = <FixtureCue>[
    FixtureCue(
      frameIndex: 0,
      event: CameraCueEvent(
        code: 'cameraReady',
        message: 'Synthetic fixture: no camera and no detector are used.',
        timestampMicros: source.frames.first.timestampMicros,
      ),
    ),
    FixtureCue(
      frameIndex: lostAt,
      event: CameraCueEvent(
        code: TrackingPauseReason.lowLight.wire,
        message: 'Synthetic low-light segment for the reframing cue.',
        timestampMicros: source.frames[lostAt].timestampMicros,
      ),
    ),
  ];

  return FixtureScript(
    label: 'synthetic-${exercise.wire}-v1',
    frames: List<PoseFrame>.unmodifiable(source.frames),
    cues: List<FixtureCue>.unmodifiable(cues),
  );
}

/// A [CameraBridge] that replays a [FixtureScript] instead of the camera.
///
/// It answers permission checks as granted so the practice/live flow can be
/// exercised offline, and `startPreview` returns `-1` because there is no
/// texture: the preview widget renders a labeled synthetic placeholder.
class FixtureCameraBridge implements CameraBridge {
  FixtureCameraBridge({
    required this.exercise,
    FixtureScript? script,
    this.intervalMicros = 66000,
    bool autoPlay = false,
    this.previewGeometry,
  }) : script = script ??
            buildFixtureScript(exercise, intervalMicros: intervalMicros) {
    if (autoPlay) {
      play();
    }
  }

  final ArenaExercise exercise;
  final FixtureScript script;
  final int intervalMicros;
  final CameraPreviewGeometry? previewGeometry;

  final StreamController<PoseBridgeEvent> _poseController =
      StreamController<PoseBridgeEvent>.broadcast();
  final StreamController<CameraCueEvent> _cueController =
      StreamController<CameraCueEvent>.broadcast();

  Timer? _timer;
  int _index = 0;
  bool _disposed = false;

  @override
  Stream<PoseBridgeEvent> get poseEvents => _poseController.stream;

  @override
  Stream<CameraCueEvent> get cueEvents => _cueController.stream;

  /// Starts replaying at [intervalMicros]. Safe to call twice.
  void play() {
    if (_disposed) {
      return;
    }
    _timer ??= Timer.periodic(
      Duration(microseconds: intervalMicros),
      (_) => emitNext(),
    );
  }

  void stopPlayback() {
    _timer?.cancel();
    _timer = null;
  }

  /// Emits the next scripted frame (and any cue attached to it), looping at
  /// the end of the script. Returns the emitted frame or `null` when disposed.
  PoseFrame? emitNext() {
    if (_disposed || script.frames.isEmpty) {
      return null;
    }
    if (_index >= script.frames.length) {
      _index = 0;
    }
    final index = _index;
    final frame = script.frames[index];
    for (final cue in script.cues) {
      if (cue.frameIndex == index) {
        _cueController.add(cue.event);
      }
    }
    _poseController.add(PoseFrameEvent(frame: frame));
    _index++;
    return frame;
  }

  @override
  Future<CameraPermissionStatus> checkPermission() async =>
      CameraPermissionStatus.granted;

  @override
  Future<CameraPermissionStatus> requestPermission() async =>
      CameraPermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> hasCamera() async => false;

  @override
  Future<int> startPreview(ArenaExercise exercise) async {
    final geometry = previewGeometry;
    if (geometry != null) {
      _poseController.add(
        PosePreviewEvent(geometry: geometry, timestampMicros: 0),
      );
    }
    return -1;
  }

  @override
  Future<void> setTorch(bool enabled) async {}

  @override
  Future<void> pause() async {
    stopPlayback();
  }

  @override
  Future<void> resume() async {
    play();
  }

  @override
  Future<void> stop() async {
    stopPlayback();
  }

  @override
  Future<CameraRuntimeInfo> runtimeInfo() async =>
      CameraRuntimeInfo.synthetic(label: script.label);

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    stopPlayback();
    await _poseController.close();
    await _cueController.close();
  }
}
