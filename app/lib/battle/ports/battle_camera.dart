/// Camera/counter contract consumed by the battle runtime.
///
/// Task 03 owns the real pose-tracking implementation under `app/lib/camera/`
/// and adapts it to this interface. The battle runtime only ever sees tracking
/// states and counted rep events: no frames, no manual entry.
library;

import '../../domain/arena_types.dart';
import '../state/battle_failure.dart';
import '../state/battle_phase.dart';

/// One tracking update from the camera layer.
class BattleCameraUpdate {
  const BattleCameraUpdate(this.status, {this.message});

  final BattleCameraStatus status;

  /// Factual explanation safe to render (for example framing guidance).
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is BattleCameraUpdate &&
      other.status == status &&
      other.message == message;

  @override
  int get hashCode => Object.hash(status, message);
}

/// One camera-counted rep. The camera layer owns counting; this event is the
/// only rep source in the product. Field names mirror task 03's `RepEvent`.
class BattleRepEvent {
  const BattleRepEvent({
    required this.eventId,
    required this.sequence,
    this.counterVersion = 'unknown',
    this.observedAt,
    this.practice = false,
    this.competitive = true,
  });

  /// Stable event id from the counter; reused on retry so the server dedupes.
  final String eventId;

  /// Positive per-phase sequence from the counter.
  final int sequence;

  /// Counter/model version so the backend can reject stale counters.
  final String counterVersion;

  /// Local observation time; the server checks it but owns the clock.
  final DateTime? observedAt;

  /// True for the single unscored practice rep.
  final bool practice;

  /// False for labelled synthetic/demo sessions.
  final bool competitive;
}

/// Camera port used before and during a battle.
abstract interface class BattleCamera {
  /// Requests permission and starts the preview for [exercise]. Returns the
  /// resulting status; failures are reported through [updates] as well.
  Future<BattleCameraStatus> prepare(ArenaExercise exercise);

  /// Tracking updates, including permission denials and framing guidance.
  Stream<BattleCameraUpdate> get updates;

  /// Counted reps only; the camera never emits competitive events while
  /// tracking is lost.
  Stream<BattleRepEvent> get reps;

  /// Switches the counter to the single unscored practice rep.
  Future<void> startPractice();

  /// Switches the counter to competitive counting for the live round.
  Future<void> startMatch();

  /// Releases the preview temporarily, preserving the same live round.
  Future<void> suspend();

  /// Resumes the preview without starting or resetting a scored round.
  Future<void> resume();

  /// Stops counting/preview without disposing the camera.
  Future<void> stop();

  /// Releases platform resources.
  Future<void> dispose();
}

/// Honest default when no camera implementation is wired (for example a
/// desktop test host or a build without task 03). It never invents a rep.
class UnavailableBattleCamera implements BattleCamera {
  UnavailableBattleCamera({String? message})
    : _message =
          message ??
          'Camera counting is not available in this build. No manual score '
              'entry exists.';

  final String _message;

  @override
  Future<BattleCameraStatus> prepare(ArenaExercise exercise) async {
    return BattleCameraStatus.unavailable;
  }

  @override
  Stream<BattleCameraUpdate> get updates => Stream<BattleCameraUpdate>.value(
    BattleCameraUpdate(BattleCameraStatus.unavailable, message: _message),
  );

  @override
  Stream<BattleRepEvent> get reps => const Stream<BattleRepEvent>.empty();

  @override
  Future<void> startPractice() async {}

  @override
  Future<void> startMatch() async {}

  @override
  Future<void> suspend() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Throws a typed failure for camera commands that a host cannot serve.
class CameraFailure implements Exception {
  const CameraFailure(this.failure);

  final BattleFailure failure;

  @override
  String toString() => failure.toString();
}
