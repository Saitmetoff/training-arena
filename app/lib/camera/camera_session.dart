/// Dart-facing camera session consumed by the battle feature.
///
/// A session wraps one exercise, one bridge and one [RepCounter]. It owns
/// permission handling, camera lifecycle (including app background/foreground
/// and Settings return), practice/round transitions and event emission. It
/// exposes no way to increment reps manually: reps only increase when the
/// pose state machine counts a complete, confident repetition.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/arena_types.dart';
import 'bridge/camera_bridge.dart';
import 'bridge/debug_fixture.dart';
import 'bridge/platform_camera_bridge.dart';
import 'camera_types.dart';
import 'counted_rep_feedback.dart';
import 'counter/exercise_profile.dart';
import 'counter/rep_counter.dart';
import 'pose/pose_types.dart';
import 'trace/pose_trace_recorder.dart';

/// Creates a stable event id for one counted rep.
typedef RepEventIdFactory = String Function();

/// Generates an RFC 4122 version 4 identifier without adding a dependency.
String generateRepEventId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// Stable camera interface for the battle runtime (task `07`).
///
/// Competitive results require `isCompetitive == true` plus a server-confirmed
/// match; the camera layer never scores a match itself. Debug-fixture sessions
/// are labeled and their events carry `competitive: false`.
abstract class CameraSession {
  /// Opens the real camera pipeline with the Android pose bridge.
  static CameraSession platform({
    required ArenaExercise exercise,
    CameraBridge? bridge,
    bool observeLifecycle = true,
    RepEventIdFactory? eventIdFactory,
    DateTime Function()? clock,
    bool traceEnabled = const bool.fromEnvironment(
      'ARENA_FEATURE_CAMERA_TRACE',
    ),
  }) => CameraSessionController(
    bridge: bridge ?? PlatformCameraBridge(),
    exercise: exercise,
    isCompetitive: true,
    observeLifecycle: observeLifecycle,
    eventIdFactory: eventIdFactory,
    clock: clock,
    traceEnabled: traceEnabled,
  );

  /// Offline, visibly non-competitive synthetic session.
  static CameraSession debugFixture({
    required ArenaExercise exercise,
    FixtureCameraBridge? bridge,
    bool autoPlay = true,
  }) {
    final fixtureBridge =
        bridge ?? FixtureCameraBridge(exercise: exercise, autoPlay: false);
    if (autoPlay) {
      fixtureBridge.play();
    }
    return CameraSessionController(
      bridge: fixtureBridge,
      exercise: exercise,
      isCompetitive: false,
      demoLabel: 'DEMO FIXTURE — NOT COUNTED',
      observeLifecycle: false,
    );
  }

  ArenaExercise get exercise;

  CameraPermissionStatus get permission;

  CameraSessionPhase get phase;

  CameraTrackingState get tracking;

  TrackingPauseReason get pauseReason;

  /// Player-facing instruction for the current state.
  String get instruction;

  /// True once the unscored practice rep is complete.
  bool get practiceComplete;

  /// Reps counted in the current practice or round phase (read-only).
  int get reps;

  /// False for debug-fixture sessions.
  bool get isCompetitive;

  /// Visible demo label for non-competitive sessions.
  String? get demoLabel;

  /// Android texture id for the local preview, when one exists.
  int? get previewTextureId;

  /// Latest pose frame the counter consumed, or `null` before the first
  /// counted frame. This is the same in-memory value the counter sees: numbers
  /// only, not copied, not retained past the next frame, never logged or
  /// written.
  PoseFrame? get latestFrame;

  /// Frames exactly as the counter consumes them, in arrival order. Broadcast:
  /// no replay, no buffering, and the stream holds no frame.
  Stream<PoseFrame> get poseFrames;

  CameraFailure? get failure;

  /// Current immutable view; safe to read at any time.
  CameraSessionSnapshot get snapshot;

  /// Session updates; emits when a visible field changes.
  Stream<CameraSessionSnapshot> get snapshots;

  /// Locally counted reps. Examples and practice reps are flagged.
  Stream<RepEvent> get repEvents;

  /// Requests the Android camera permission. Returns true when granted.
  Future<bool> requestPermission();

  /// Opens the OS Settings page so the player can unblock the camera.
  Future<bool> openAppSettings();

  /// Starts the unscored practice rep flow.
  Future<bool> startPractice();

  /// Begins competitive counting; requires a completed practice rep.
  Future<bool> beginRound();

  /// Stops competitive counting and freezes the rep count.
  Future<bool> endRound();

  /// Resets practice without touching any match score.
  Future<bool> resetPractice();

  /// Pauses counting and releases the camera; the battle clock keeps running.
  Future<void> pause();

  /// Resumes a paused session; framing must stabilise again.
  Future<void> resume();

  Future<void> setTorch(bool enabled);

  Future<CameraRuntimeInfo> runtimeInfo();

  /// Releases the camera, the detector and all listeners. Idempotent.
  Future<void> dispose();
}

/// Default [CameraSession] implementation.
class CameraSessionController extends CameraSession
    with WidgetsBindingObserver {
  CameraSessionController({
    required CameraBridge bridge,
    required ArenaExercise exercise,
    bool isCompetitive = true,
    this.demoLabel,
    bool observeLifecycle = true,
    RepEventIdFactory? eventIdFactory,
    DateTime Function()? clock,
    bool traceEnabled = const bool.fromEnvironment(
      'ARENA_FEATURE_CAMERA_TRACE',
    ),
  }) : _bridge = bridge,
       _exercise = exercise,
       _isCompetitive = isCompetitive,
       _observeLifecycle = observeLifecycle,
       _eventIdFactory = eventIdFactory ?? generateRepEventId,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _counter = RepCounter(ExerciseCounterProfile.forExercise(exercise)) {
    if (traceEnabled) enableDiagnosticTrace();
    _poseSubscription = _bridge.poseEvents.listen(
      _onPoseEvent,
      onError: _onPoseStreamError,
    );
    _cueSubscription = _bridge.cueEvents.listen(_onCueEvent);
    if (_observeLifecycle) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _observerAttached = true;
      } catch (_) {
        // No binding in a pure Dart test: lifecycle handling is skipped.
      }
    }
    unawaited(_refreshRuntimeInfo());
  }

  final CameraBridge _bridge;
  final ArenaExercise _exercise;
  final bool _isCompetitive;
  final bool _observeLifecycle;
  final RepEventIdFactory _eventIdFactory;
  final DateTime Function() _clock;
  final RepCounter _counter;
  PoseTraceRecorder? _diagnosticTrace;
  bool _previewPausedAtEnd = false;
  Future<void>? _endPause;

  /// Numeric, opt-in diagnostics follow the session, never the preview widget.
  PoseTraceRecorder? get diagnosticTrace => _diagnosticTrace;

  void enableDiagnosticTrace() {
    if (!_disposed) {
      _diagnosticTrace ??= PoseTraceRecorder(exercise: _exercise);
    }
  }

  final StreamController<CameraSessionSnapshot> _snapshotsController =
      StreamController<CameraSessionSnapshot>.broadcast();
  final StreamController<RepEvent> _repEventsController =
      StreamController<RepEvent>.broadcast();
  final StreamController<PoseFrame> _poseFramesController =
      StreamController<PoseFrame>.broadcast();

  StreamSubscription<PoseBridgeEvent>? _poseSubscription;
  StreamSubscription<CameraCueEvent>? _cueSubscription;

  bool _observerAttached = false;
  bool _disposed = false;
  bool _previewStarted = false;
  int? _previewTextureId;
  bool _torchEnabled = false;

  CameraPermissionStatus _permission = CameraPermissionStatus.unknown;
  CameraSessionPhase _phase = CameraSessionPhase.idle;
  CameraSessionPhase? _resumePhase;
  CameraTrackingState _tracking = CameraTrackingState.unknown;
  TrackingPauseReason _pauseReason = TrackingPauseReason.none;
  bool _practiceComplete = false;
  int _reps = 0;
  bool _framingLocked = false;
  double _trackingConfidence = 0;
  RepRejection _lastRepRejection = RepRejection.none;
  int? _lastRepRejectionMicros;
  int _practiceSequence = 0;
  int _roundSequence = 0;
  int _lastFrameMicros = 0;
  CameraFailure? _failure;
  CameraRuntimeInfo? _runtimeInfo;
  CameraSessionSnapshot? _lastSnapshot;
  PoseFrame? _latestFrame;
  CameraPreviewGeometry? _previewGeometry;
  CameraViewMode _viewMode = CameraViewMode.side;
  PoseSide? _countingSide;

  bool _autoPaused = false;
  bool _awaitingSettingsReturn = false;
  bool _startPracticeOnPermission = false;

  @override
  ArenaExercise get exercise => _exercise;

  @override
  CameraPermissionStatus get permission => _permission;

  @override
  CameraSessionPhase get phase => _phase;

  @override
  CameraTrackingState get tracking => _tracking;

  @override
  TrackingPauseReason get pauseReason => _pauseReason;

  @override
  bool get practiceComplete => _practiceComplete;

  @override
  int get reps => _reps;

  @override
  bool get isCompetitive => _isCompetitive;

  @override
  final String? demoLabel;

  @override
  int? get previewTextureId => _previewTextureId;

  @override
  PoseFrame? get latestFrame => _latestFrame;

  @override
  Stream<PoseFrame> get poseFrames => _poseFramesController.stream;

  @override
  CameraFailure? get failure => _failure;

  @override
  String get instruction {
    final snapshot = _lastSnapshot ?? _buildSnapshot();
    return snapshot.instruction;
  }

  @override
  CameraSessionSnapshot get snapshot => _lastSnapshot ?? _buildSnapshot();

  @override
  Stream<CameraSessionSnapshot> get snapshots => _snapshotsController.stream;

  @override
  Stream<RepEvent> get repEvents => _repEventsController.stream;

  @override
  Future<bool> requestPermission() async {
    if (_disposed) {
      return false;
    }
    if (_permission == CameraPermissionStatus.granted) {
      return true;
    }
    if (_permission == CameraPermissionStatus.permanentlyDenied) {
      _phase = CameraSessionPhase.permissionRequired;
      _publish();
      return false;
    }
    _phase = CameraSessionPhase.permissionRequired;
    _publish();
    try {
      final status = await _bridge.requestPermission();
      _permission = status;
      if (status == CameraPermissionStatus.granted) {
        _failure = null;
        if (_phase == CameraSessionPhase.permissionRequired) {
          _phase = CameraSessionPhase.idle;
        }
        _pauseReason = TrackingPauseReason.none;
      } else if (status == CameraPermissionStatus.permanentlyDenied) {
        _pauseReason = TrackingPauseReason.permissionBlocked;
      }
      _publish();
      return status == CameraPermissionStatus.granted;
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
      _publish();
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (_disposed) {
      return false;
    }
    _awaitingSettingsReturn = true;
    try {
      return await _bridge.openAppSettings();
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
      _publish();
      return false;
    }
  }

  @override
  Future<bool> startPractice() async {
    await _endPause;
    if (_disposed || _phase == CameraSessionPhase.live) {
      return false;
    }
    _startPracticeOnPermission = true;
    final granted =
        _permission == CameraPermissionStatus.granted ||
        await requestPermission();
    if (!granted) {
      return false;
    }
    _startPracticeOnPermission = false;
    if (_phase == CameraSessionPhase.paused || _previewPausedAtEnd) {
      // The camera was released by pause(); restart practice on a live camera
      // instead of counting while no frames can arrive.
      if (!await _resumeBridgeAfterPause()) {
        return false;
      }
    } else if (_phase == CameraSessionPhase.idle ||
        _phase == CameraSessionPhase.permissionRequired) {
      try {
        if (!_previewStarted) {
          final textureId = await _bridge.startPreview(_exercise);
          _previewStarted = true;
          _previewTextureId = textureId >= 0 ? textureId : null;
        }
      } on CameraBridgeException catch (error) {
        _applyBridgeFailure(error);
        _publish();
        return false;
      }
    }
    _counter.resume();
    if (_diagnosticTrace?.completed ?? false) _diagnosticTrace?.clear();
    _counter.reset(keepFraming: false);
    _counter.setCountingEnabled(true);
    _practiceComplete = false;
    _practiceSequence = 0;
    _roundSequence = 0;
    _reps = 0;
    _lastRepRejection = RepRejection.none;
    _lastRepRejectionMicros = null;
    _framingLocked = false;
    _tracking = CameraTrackingState.searching;
    _pauseReason = TrackingPauseReason.none;
    _failure = null;
    _phase = CameraSessionPhase.practice;
    _publish();
    return true;
  }

  @override
  Future<bool> beginRound() async {
    if (_disposed || !_practiceComplete) {
      return false;
    }
    // A round may begin from `ready`, or from a paused session that was ready
    // when the player paused (the battle clock keeps running meanwhile).
    final canBegin =
        _phase == CameraSessionPhase.ready ||
        (_phase == CameraSessionPhase.paused &&
            _resumePhase == CameraSessionPhase.ready);
    if (!canBegin) {
      return false;
    }
    if (_phase == CameraSessionPhase.paused &&
        !await _resumeBridgeAfterPause()) {
      return false;
    }
    if (_counter.suspended) {
      _counter.resume();
    }
    _counter.reset(keepFraming: true);
    _counter.setCountingEnabled(true);
    _diagnosticTrace?.beginRound();
    _roundSequence = 0;
    _reps = 0;
    _lastRepRejection = RepRejection.none;
    _lastRepRejectionMicros = null;
    _phase = CameraSessionPhase.live;
    _publish();
    return true;
  }

  @override
  Future<bool> endRound() async {
    // The shared battle clock keeps running while the local counter is paused,
    // so a round must be able to end from `paused` too. The camera stays
    // released in that case; dispose() or resume() handles later lifecycle.
    final roundLive =
        _phase == CameraSessionPhase.live ||
        (_phase == CameraSessionPhase.paused &&
            _resumePhase == CameraSessionPhase.live);
    if (_disposed || !roundLive) {
      return false;
    }
    _counter.setCountingEnabled(false);
    _diagnosticTrace?.endRound(_reps);
    _phase = CameraSessionPhase.ended;
    _resumePhase = null;
    _autoPaused = false;
    _previewPausedAtEnd = true;
    _endPause = _pauseFinishedPreview();
    _publish();
    // The result has no live preview. Release the native camera while retaining
    // numeric diagnostics; sharing the finished trace cannot interrupt a round.
    await _endPause;
    return true;
  }

  Future<void> _pauseFinishedPreview() async {
    try {
      await _bridge.pause();
    } catch (_) {
      // Camera teardown cannot rewrite a completed round or its trace.
      // The next practice rechecks/resumes the native bridge before counting.
    }
  }

  @override
  Future<bool> resetPractice() async {
    await _endPause;
    if (_disposed) {
      return false;
    }
    if (_phase == CameraSessionPhase.live) {
      throw StateError('Cannot reset practice while a round is live.');
    }
    if ((_phase == CameraSessionPhase.paused || _previewPausedAtEnd) &&
        !await _resumeBridgeAfterPause()) {
      return false;
    }
    _practiceComplete = false;
    _practiceSequence = 0;
    _reps = 0;
    _lastRepRejection = RepRejection.none;
    _lastRepRejectionMicros = null;
    _counter.resume();
    _counter.reset(keepFraming: true);
    _counter.setCountingEnabled(true);
    _phase = _previewStarted
        ? CameraSessionPhase.practice
        : CameraSessionPhase.idle;
    _publish();
    return true;
  }

  @override
  Future<void> pause() async {
    if (_disposed || _phase == CameraSessionPhase.paused) {
      return;
    }
    final active =
        _phase == CameraSessionPhase.practice ||
        _phase == CameraSessionPhase.ready ||
        _phase == CameraSessionPhase.live;
    if (!active) {
      return;
    }
    _resumePhase = _phase;
    _phase = CameraSessionPhase.paused;
    _tracking = CameraTrackingState.paused;
    _pauseReason = TrackingPauseReason.paused;
    _counter.pause();
    _diagnosticTrace?.counterEvent('pause');
    _publish();
    try {
      await _bridge.pause();
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
    }
    _publish();
  }

  @override
  Future<void> resume() async {
    if (_disposed || _phase != CameraSessionPhase.paused) {
      return;
    }
    try {
      await _bridge.resume();
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
      _publish();
      return;
    }
    _counter.resume();
    _phase = _resumePhase ?? CameraSessionPhase.ready;
    _diagnosticTrace?.counterEvent('resume');
    _tracking = CameraTrackingState.unknown;
    _pauseReason = TrackingPauseReason.none;
    _publish();
  }

  @override
  Future<void> setTorch(bool enabled) async {
    if (_disposed) {
      return;
    }
    try {
      await _bridge.setTorch(enabled);
      _torchEnabled = enabled;
      _publish();
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
      _publish();
    }
  }

  @override
  Future<CameraRuntimeInfo> runtimeInfo() async {
    if (_runtimeInfo != null) {
      return _runtimeInfo!;
    }
    try {
      _runtimeInfo = await _bridge.runtimeInfo();
    } on CameraBridgeException {
      _runtimeInfo = CameraRuntimeInfo.synthetic(label: 'unavailable');
    }
    return _runtimeInfo!;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_observerAttached) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {
        // Binding already gone.
      }
      _observerAttached = false;
    }
    await _poseSubscription?.cancel();
    await _cueSubscription?.cancel();
    try {
      await _bridge.dispose();
    } on CameraBridgeException {
      // Best effort release.
    }
    _phase = CameraSessionPhase.disposed;
    _tracking = CameraTrackingState.unknown;
    _latestFrame = null;
    _diagnosticTrace?.clear();
    _diagnosticTrace = null;
    final finalSnapshot = _buildSnapshot();
    if (!_snapshotsController.isClosed) {
      _snapshotsController.add(finalSnapshot);
      await _snapshotsController.close();
    }
    if (!_repEventsController.isClosed) {
      await _repEventsController.close();
    }
    if (!_poseFramesController.isClosed) {
      await _poseFramesController.close();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_observeLifecycle) {
      return;
    }
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_phase == CameraSessionPhase.practice ||
            _phase == CameraSessionPhase.ready ||
            _phase == CameraSessionPhase.live) {
          _autoPaused = true;
          unawaited(pause());
        }
      case AppLifecycleState.resumed:
        if (_awaitingSettingsReturn) {
          _awaitingSettingsReturn = false;
          unawaited(_refreshPermissionAfterSettings());
        } else if (_autoPaused) {
          _autoPaused = false;
          unawaited(resume());
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  // --- internals -----------------------------------------------------------

  /// Rebinds the native camera after a `paused` phase so an explicit command
  /// (practice, round or reset) never runs against a released camera. Returns
  /// false and surfaces the failure when the bridge refuses to resume.
  Future<bool> _resumeBridgeAfterPause() async {
    try {
      await _bridge.resume();
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
      _publish();
      return false;
    }
    _autoPaused = false;
    _previewPausedAtEnd = false;
    _tracking = CameraTrackingState.unknown;
    _pauseReason = TrackingPauseReason.none;
    return true;
  }

  Future<void> _refreshPermissionAfterSettings() async {
    try {
      final status = await _bridge.checkPermission();
      _permission = status;
      if (status == CameraPermissionStatus.granted) {
        _failure = null;
        _pauseReason = TrackingPauseReason.none;
        if (_phase == CameraSessionPhase.permissionRequired) {
          _phase = CameraSessionPhase.idle;
        }
        _publish();
        if (_startPracticeOnPermission && !_practiceComplete) {
          await startPractice();
        }
      } else {
        _pauseReason = TrackingPauseReason.permissionBlocked;
        _publish();
      }
    } on CameraBridgeException catch (error) {
      _applyBridgeFailure(error);
      _publish();
    }
  }

  Future<void> _refreshRuntimeInfo() async {
    if (_disposed) {
      return;
    }
    await runtimeInfo();
    _publish();
  }

  void _onPoseEvent(PoseBridgeEvent event) {
    if (_disposed) {
      return;
    }
    switch (event) {
      case PosePreviewEvent(:final geometry):
        _previewGeometry = geometry;
        _publish();
      case PoseFrameEvent(:final frame):
        _consumeFrame(frame);
      case PoseTrackingEvent():
        if (_phase == CameraSessionPhase.paused ||
            _phase == CameraSessionPhase.disposed) {
          return;
        }
        if (event.state == CameraTrackingState.paused) {
          _tracking = CameraTrackingState.paused;
          _pauseReason = TrackingPauseReason.paused;
        } else if (event.state == CameraTrackingState.searching) {
          if (_isActivePhase) {
            _tracking = CameraTrackingState.searching;
            if (event.reason != TrackingPauseReason.none) {
              _pauseReason = event.reason;
            }
          }
        }
        _publish();
      case PoseErrorEvent():
        _applyBridgeFailure(CameraBridgeException(event.code, event.message));
        _publish();
    }
  }

  void _onPoseStreamError(Object error) {
    if (_disposed) {
      return;
    }
    if (error is CameraBridgeException) {
      _applyBridgeFailure(error);
    } else if (error is PlatformException) {
      _applyBridgeFailure(
        CameraBridgeException(error.code, error.message ?? ''),
      );
    } else {
      _applyBridgeFailure(
        CameraBridgeException(
          CameraFailureCodes.bridgeFailure,
          error.toString(),
        ),
      );
    }
    _publish();
  }

  void _onCueEvent(CameraCueEvent cue) {
    if (_disposed) {
      return;
    }
    switch (cue.code) {
      case 'lowLight':
        if (_isActivePhase) {
          _pauseReason = TrackingPauseReason.lowLight;
        }
      case 'cameraError':
        _applyBridgeFailure(
          CameraBridgeException(
            CameraFailureCodes.cameraUnavailable,
            cue.message ?? 'camera error',
          ),
        );
      case 'detectorError':
        _applyBridgeFailure(
          CameraBridgeException(
            CameraFailureCodes.detectorFailure,
            cue.message ?? 'pose detector error',
          ),
        );
      default:
        break;
    }
    _publish();
  }

  bool get _isActivePhase =>
      _phase == CameraSessionPhase.practice ||
      _phase == CameraSessionPhase.ready ||
      _phase == CameraSessionPhase.live;

  void _consumeFrame(PoseFrame frame) {
    _lastFrameMicros = frame.timestampMicros;
    if (!_isActivePhase) {
      return;
    }
    final result = _counter.addFrame(frame);
    _diagnosticTrace?.add(frame);
    diagnostics = result;
    // The overlay draws the exact frame the counter just consumed.
    _latestFrame = frame;
    _viewMode = result.viewMode;
    _countingSide = result.side;
    _tracking = result.tracking;
    _pauseReason = result.pauseReason;
    _framingLocked = result.framingLocked;
    _trackingConfidence = result.confidence;
    _reps = result.countedReps;
    if (result.repCounted) {
      _lastRepRejection = RepRejection.none;
      _onCountedRep(result);
    } else if (result.outcome && result.rejection != CounterRejection.none) {
      _lastRepRejection = _repRejectionFor(result.rejection);
      _lastRepRejectionMicros = frame.timestampMicros;
    }
    _publish();
    if (!_poseFramesController.isClosed) {
      _poseFramesController.add(frame);
    }
  }

  /// Latest counter verdict for the opt-in local diagnostics HUD.
  RepCounterResult? diagnostics;

  /// Translates the counter's internal rejection into the player-facing
  /// verdict. The debounce guard is a bounce control, not a form fault, so it
  /// reads as `tooFast`.
  RepRejection _repRejectionFor(CounterRejection rejection) =>
      switch (rejection) {
        CounterRejection.none => RepRejection.none,
        CounterRejection.dwellTooShort => RepRejection.shallow,
        CounterRejection.repTooFast ||
        CounterRejection.debounce => RepRejection.tooFast,
        CounterRejection.bodyNotStraight => RepRejection.bodyNotStraight,
        CounterRejection.torsoCollapsed => RepRejection.torsoCollapsed,
        CounterRejection.lowConfidence => RepRejection.lowConfidence,
        CounterRejection.lockoutMissed => RepRejection.lockoutMissed,
        CounterRejection.notDeepEnough => RepRejection.notDeepEnough,
      };

  void _onCountedRep(RepCounterResult result) {
    unawaited(playCountedRepCue());
    final practice =
        _phase == CameraSessionPhase.practice && !_practiceComplete;
    final sequence = practice ? ++_practiceSequence : ++_roundSequence;
    final event = RepEvent(
      eventId: _eventIdFactory(),
      sequence: sequence,
      observedAt: _clock(),
      monotonicMicros: _lastFrameMicros,
      counterVersion: arenaCounterVersion,
      confidence: result.repConfidence,
      exercise: _exercise,
      competitive: _isCompetitive && !practice,
      practice: practice,
    );
    if (!_repEventsController.isClosed) {
      _repEventsController.add(event);
    }
    if (practice) {
      _practiceComplete = true;
      _counter.setCountingEnabled(false);
      _phase = CameraSessionPhase.ready;
    }
  }

  void _applyBridgeFailure(CameraBridgeException error) {
    final code = error.code;
    switch (code) {
      case CameraFailureCodes.cameraBusy:
        _failure = CameraFailure(
          code: code,
          message: 'The camera is busy.',
          action: 'Close other camera apps and tap resume.',
        );
        _pauseReason = TrackingPauseReason.cameraBusy;
      case CameraFailureCodes.cameraPermission:
        _failure = CameraFailure(
          code: code,
          message: 'Camera access is blocked.',
          action: 'Open Settings and allow the camera for Fault.',
        );
        _pauseReason = TrackingPauseReason.permissionBlocked;
        _phase = CameraSessionPhase.permissionRequired;
      case CameraFailureCodes.detectorFailure:
        _failure = CameraFailure(
          code: code,
          message: 'The on-device pose detector could not start.',
          action:
              'Restart the app. If it keeps failing, this phone cannot '
              'count reps.',
          recoverable: false,
        );
        _pauseReason = TrackingPauseReason.cameraUnavailable;
        _phase = CameraSessionPhase.error;
      case CameraFailureCodes.noCamera:
      case CameraFailureCodes.cameraUnavailable:
        _failure = CameraFailure(
          code: code,
          message: 'No usable camera is available.',
          action: 'Use a phone with a working camera for scored battles.',
          recoverable: false,
        );
        _pauseReason = TrackingPauseReason.cameraUnavailable;
        _phase = CameraSessionPhase.error;
      default:
        _failure = CameraFailure(
          code: code,
          message: error.message,
          action: 'Try again, or restart the app.',
        );
        _pauseReason = TrackingPauseReason.cameraUnavailable;
    }
  }

  CameraSessionSnapshot _buildSnapshot() {
    return CameraSessionSnapshot(
      exercise: _exercise,
      permission: _permission,
      phase: _phase,
      tracking: _tracking,
      pauseReason: _pauseReason,
      instruction: _instructionForState(),
      practiceComplete: _practiceComplete,
      reps: _reps,
      framingLocked: _framingLocked,
      trackingConfidence: _trackingConfidence,
      isCompetitive: _isCompetitive,
      viewMode: _viewMode,
      countingSide: _countingSide,
      previewTextureId: _previewTextureId,
      previewGeometry: _previewGeometry,
      torchEnabled: _torchEnabled,
      demoLabel: demoLabel,
      failure: _failure,
      detectorSdk: _runtimeInfo?.detectorSdk,
      lastRepRejection: _lastRepRejection,
      lastRepRejectionMicros: _lastRepRejectionMicros,
    );
  }

  String _instructionForState() {
    if (_failure != null) {
      return '${_failure!.message} ${_failure!.action}';
    }
    switch (_phase) {
      case CameraSessionPhase.disposed:
        return 'Camera session closed.';
      case CameraSessionPhase.error:
        return _failure?.message ?? 'Camera error.';
      case CameraSessionPhase.idle:
      case CameraSessionPhase.permissionRequired:
        return permissionInstruction(_permission);
      case CameraSessionPhase.paused:
        return 'Paused. The battle clock keeps running while you are paused.';
      case CameraSessionPhase.ended:
        return 'Round finished: $_reps reps counted.';
      case CameraSessionPhase.practice:
      case CameraSessionPhase.ready:
      case CameraSessionPhase.live:
        return trackingInstruction(
          exercise: _exercise,
          tracking: _tracking,
          reason: _pauseReason,
          practiceComplete: _practiceComplete,
        );
    }
  }

  void _publish() {
    if (_disposed && _snapshotsController.isClosed) {
      return;
    }
    final next = _buildSnapshot();
    final previous = _lastSnapshot;
    if (previous != null && _sameSnapshot(previous, next)) {
      return;
    }
    _lastSnapshot = next;
    if (!_snapshotsController.isClosed) {
      _snapshotsController.add(next);
    }
  }

  bool _sameSnapshot(CameraSessionSnapshot a, CameraSessionSnapshot b) {
    return a.exercise == b.exercise &&
        a.permission == b.permission &&
        a.phase == b.phase &&
        a.tracking == b.tracking &&
        a.pauseReason == b.pauseReason &&
        a.instruction == b.instruction &&
        a.practiceComplete == b.practiceComplete &&
        a.reps == b.reps &&
        a.framingLocked == b.framingLocked &&
        a.trackingConfidence == b.trackingConfidence &&
        a.isCompetitive == b.isCompetitive &&
        a.viewMode == b.viewMode &&
        a.countingSide == b.countingSide &&
        a.previewTextureId == b.previewTextureId &&
        a.previewGeometry == b.previewGeometry &&
        a.torchEnabled == b.torchEnabled &&
        a.demoLabel == b.demoLabel &&
        identical(a.failure, b.failure) &&
        a.detectorSdk == b.detectorSdk &&
        a.lastRepRejection == b.lastRepRejection &&
        a.lastRepRejectionMicros == b.lastRepRejectionMicros;
  }
}
