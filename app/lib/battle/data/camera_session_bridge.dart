/// Adapter from task 03's [CameraSession] to the battle [BattleCamera] port.
///
/// The camera layer owns permission, pose tracking, rep counting and its
/// private preview; the battle runtime only receives tracking states and
/// counted [BattleRepEvent]s. Debug-fixture sessions stay non-competitive and
/// keep their visible label.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../camera/camera.dart';
import '../../domain/arena_types.dart';
import '../ports/battle_camera.dart';
import '../state/battle_phase.dart';

/// Builds the platform session for one exercise.
typedef CameraSessionFactory = CameraSession Function(ArenaExercise exercise);

/// [BattleCamera] over a [CameraSession].
class CameraSessionBattleCamera implements BattleCamera {
  CameraSessionBattleCamera({
    CameraSessionFactory? sessionFactory,
    this.observeLifecycle = true,
  }) : _sessionFactory = sessionFactory;

  final CameraSessionFactory? _sessionFactory;
  final bool observeLifecycle;

  final StreamController<BattleCameraUpdate> _updates =
      StreamController<BattleCameraUpdate>.broadcast();
  final StreamController<BattleRepEvent> _reps =
      StreamController<BattleRepEvent>.broadcast();

  CameraSession? _session;
  StreamSubscription<CameraSessionSnapshot>? _snapshotSubscription;
  StreamSubscription<RepEvent>? _repSubscription;
  bool _disposed = false;

  /// The live session, exposed so task 03's `CameraPreview` can render the
  /// local-only preview.
  CameraSession? get session => _session;

  @override
  Future<BattleCameraStatus> prepare(ArenaExercise exercise) async {
    if (_disposed) {
      return BattleCameraStatus.unavailable;
    }
    final current = _session;
    if (current != null && current.exercise != exercise) {
      await _detach();
    }
    final session = _session ??= _create(exercise);
    if (_snapshotSubscription == null) {
      _snapshotSubscription = session.snapshots.listen(
        _onSnapshot,
        onError: (Object error) {
          _emitFailure('Camera tracking stopped: $error');
        },
      );
      _repSubscription = session.repEvents.listen(
        _onRep,
        onError: (Object error) {
          _emitFailure('Camera counting stopped: $error');
        },
      );
      _onSnapshot(session.snapshot);
    }
    if (session.permission != CameraPermissionStatus.granted) {
      await session.requestPermission();
      _onSnapshot(session.snapshot);
    }
    return _statusFrom(session.snapshot);
  }

  CameraSession _create(ArenaExercise exercise) {
    final factory = _sessionFactory;
    if (factory != null) {
      return factory(exercise);
    }
    return CameraSession.platform(
      exercise: exercise,
      observeLifecycle: observeLifecycle,
    );
  }

  @override
  Stream<BattleCameraUpdate> get updates => _updates.stream;

  @override
  Stream<BattleRepEvent> get reps => _reps.stream;

  @override
  Future<void> startPractice() async {
    await _session?.startPractice();
  }

  @override
  Future<void> startMatch() async {
    final session = _session;
    if (session == null) {
      return;
    }
    // Re-scan/reconnect must resume the same live counter and trace. A second
    // beginRound would otherwise fail from paused-live or reset round state.
    if (session.phase == CameraSessionPhase.paused &&
        session.practiceComplete) {
      await session.resume();
    }
    if (session.phase == CameraSessionPhase.live) return;
    // beginRound requires the completed practice rep; re-arm practice when a
    // resumed session has not completed it yet so the flow never deadlocks.
    if (!session.practiceComplete) {
      await session.startPractice();
    }
    await session.beginRound();
  }

  @override
  Future<void> stop() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await session.endRound();
    await session.pause();
  }

  @override
  Future<void> suspend() async => _session?.pause();

  @override
  Future<void> resume() async => _session?.resume();

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _detach();
    await _updates.close();
    await _reps.close();
  }

  Future<void> _detach() async {
    await _snapshotSubscription?.cancel();
    await _repSubscription?.cancel();
    _snapshotSubscription = null;
    _repSubscription = null;
    final session = _session;
    _session = null;
    await session?.dispose();
  }

  void _onSnapshot(CameraSessionSnapshot snapshot) {
    if (_disposed) {
      return;
    }
    _updates.add(
      BattleCameraUpdate(
        _statusFrom(snapshot),
        message: snapshot.failure != null
            ? '${snapshot.failure!.message} ${snapshot.failure!.action}'
            : snapshot.instruction,
      ),
    );
  }

  void _onRep(RepEvent event) {
    if (_disposed) {
      return;
    }
    _reps.add(
      BattleRepEvent(
        eventId: event.eventId,
        sequence: event.sequence,
        counterVersion: event.counterVersion,
        observedAt: event.observedAt,
        practice: event.practice,
        competitive: event.competitive,
      ),
    );
  }

  void _emitFailure(String message) {
    if (_disposed) {
      return;
    }
    _updates.add(
      BattleCameraUpdate(BattleCameraStatus.unavailable, message: message),
    );
  }

  BattleCameraStatus _statusFrom(CameraSessionSnapshot snapshot) {
    if (snapshot.permission == CameraPermissionStatus.permanentlyDenied ||
        snapshot.permission == CameraPermissionStatus.denied) {
      return BattleCameraStatus.permissionDenied;
    }
    if (snapshot.phase == CameraSessionPhase.error ||
        snapshot.failure != null && !snapshot.failure!.recoverable) {
      return BattleCameraStatus.unavailable;
    }
    switch (snapshot.tracking) {
      case CameraTrackingState.unknown:
        return BattleCameraStatus.preparing;
      case CameraTrackingState.paused:
        return snapshot.pauseReason == TrackingPauseReason.paused
            ? BattleCameraStatus.unknown
            : BattleCameraStatus.trackingLost;
      case CameraTrackingState.searching:
        return BattleCameraStatus.framing;
      case CameraTrackingState.framing:
        return BattleCameraStatus.framing;
      case CameraTrackingState.tracking:
        return BattleCameraStatus.tracking;
    }
  }
}

/// Widget preview helper: returns the task-03 preview for an adapter, or null
/// for other camera implementations.
Widget? battleCameraPreview(BattleCamera camera) {
  if (camera is CameraSessionBattleCamera) {
    final session = camera.session;
    if (session != null) {
      return CameraPreview(session: session);
    }
  }
  return null;
}

/// Result-page diagnostics use the retained session, without mounting a camera.
Widget battleCameraTraceControls(BattleCamera camera) {
  final session = camera is CameraSessionBattleCamera ? camera.session : null;
  return session == null
      ? const SizedBox.shrink()
      : CameraTraceControls(session: session);
}
