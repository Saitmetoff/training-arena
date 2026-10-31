/// Public camera/counter value types consumed by the battle feature.
///
/// Nothing in this file carries an image, a frame buffer or a persisted
/// landmark. Rep events are the only output that may ever leave the camera
/// layer, and they contain a counter version plus timing metadata only.
library;

import '../domain/arena_types.dart';
import 'pose/pose_types.dart';

/// Version string attached to every rep event and sent to the server as
/// `counter_version` (`docs/API.md` rep action). Bump on any counting change.
///
/// 1.1.0 adds head-on (front-view) push-up counting and the `wrongView` pause
/// reason for front-view squats.
/// 1.2.0 gates on the visible counting chain and makes too-close a soft cue.
/// 1.2.1 normalises the detector's pixel coordinates against the upright
/// analysis frame in the bridge; on-device frames now reach the counter in the
/// documented 0..1 space instead of pixel units.
const String arenaCounterVersion = '1.3.0';

/// Numeric CameraX mapping from upright analysis coordinates to the cropped
/// preview. No detector input or image is retained here.
class CameraPreviewGeometry {
  const CameraPreviewGeometry({
    required this.width,
    required this.height,
    required this.crop,
    required this.analysisToPreview,
    required this.textureQuarterTurns,
    required this.mirrored,
  });

  final double width;
  final double height;
  final List<double> crop;
  final List<double> analysisToPreview;
  final int textureQuarterTurns;
  final bool mirrored;

  (double, double) project(double x, double y) {
    final m = analysisToPreview;
    return (m[0] * x + m[1] * y + m[2], m[3] * x + m[4] * y + m[5]);
  }

  @override
  bool operator ==(Object other) =>
      other is CameraPreviewGeometry &&
      width == other.width &&
      height == other.height &&
      textureQuarterTurns == other.textureQuarterTurns &&
      mirrored == other.mirrored &&
      _same(crop, other.crop) &&
      _same(analysisToPreview, other.analysisToPreview);

  static bool _same(List<double> a, List<double> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

  @override
  int get hashCode => Object.hash(
        width,
        height,
        textureQuarterTurns,
        mirrored,
        Object.hashAll(crop),
        Object.hashAll(analysisToPreview),
      );
}

/// Camera permission as seen by the Android runtime.
enum CameraPermissionStatus {
  unknown('unknown'),
  granted('granted'),
  denied('denied'),
  permanentlyDenied('permanently_denied');

  const CameraPermissionStatus(this.wire);

  final String wire;

  static CameraPermissionStatus fromWire(Object? value) {
    for (final status in values) {
      if (status.wire == value) {
        return status;
      }
    }
    return CameraPermissionStatus.unknown;
  }
}

/// Lifecycle phase of a [CameraSession].
enum CameraSessionPhase {
  idle,
  permissionRequired,
  practice,
  ready,
  live,
  paused,
  ended,
  error,
  disposed,
}

/// How the athlete is placed relative to the lens.
///
/// `side` is the profile view the counter was originally built for. `front`
/// is head-on: the athlete faces the lens, the torso is foreshortened and the
/// elbow bends towards the lens, so the 2D joint angle is degenerate and the
/// front-view signal is used instead. Detected from landmark geometry by
/// `detectCameraViewMode`; a frame that cannot be classified keeps the
/// previous mode.
enum CameraViewMode { side, front }

/// Coarse tracking state shown to the player.
enum CameraTrackingState {
  /// No camera stream yet.
  unknown('unknown'),

  /// Stream running, no usable pose.
  searching('lost'),

  /// Pose found but signal-chain framing is not stable yet.
  framing('framing'),

  /// Framing stable, counting is live.
  tracking('acquired'),

  /// Session paused by the player or by app lifecycle.
  paused('paused');

  const CameraTrackingState(this.wire);

  /// Wire value emitted by the native pose channel.
  final String wire;

  static CameraTrackingState fromWire(Object? value) {
    for (final state in values) {
      if (state.wire == value) {
        return state;
      }
    }
    return CameraTrackingState.unknown;
  }
}

/// Why counting is paused, or a soft non-blocking cue (too close, heels
/// lifted) while tracking continues.
enum TrackingPauseReason {
  none('none'),
  noPerson('noPerson'),
  lowLight('lowLight'),
  partialBody('partialBody'),
  tooClose('tooClose'),
  heelsLifted('heelsLifted'),
  tooFar('tooFar'),
  offCenter('offCenter'),
  lowConfidence('lowConfidence'),
  detectorStalled('detectorStalled'),
  wrongView('wrongView'),
  cameraUnavailable('cameraUnavailable'),
  cameraBusy('cameraBusy'),
  permissionBlocked('permissionBlocked'),
  paused('paused');

  const TrackingPauseReason(this.wire);

  /// Wire value emitted by the native pose/cue channels.
  final String wire;

  static TrackingPauseReason fromWire(Object? value) {
    for (final reason in values) {
      if (reason.wire == value) {
        return reason;
      }
    }
    return TrackingPauseReason.none;
  }
}

/// Why the last completed down/up transition did not count, as shown to the
/// player. This is the UI-facing translation of the counter's internal
/// rejection: the internal debounce guard folds into [RepRejection.tooFast]
/// because both mean the same thing to an athlete.
enum RepRejection {
  none('none'),

  /// Bottom dwell was too brief. Legacy wire name; this does not prove depth.
  shallow('shallow'),

  /// The rep was too fast, or bounced straight out of the debounce gap.
  tooFast('tooFast'),

  /// Push-ups: the body sagged or piked at the bottom.
  bodyNotStraight('bodyNotStraight'),

  /// Squats: the torso folded over at the bottom.
  torsoCollapsed('torsoCollapsed'),

  /// The counting landmarks were not readable well enough to judge the rep.
  lowConfidence('lowConfidence'),
  lockoutMissed('lockoutMissed'),
  notDeepEnough('notDeepEnough');

  const RepRejection(this.wire);

  /// Wire-stable value for diagnostics and tests.
  final String wire;
}

/// Stable failure codes mapped from native bridge errors.
abstract final class CameraFailureCodes {
  static const String cameraUnavailable = 'camera_unavailable';
  static const String cameraBusy = 'camera_busy';
  static const String cameraPermission = 'camera_permission';
  static const String detectorFailure = 'detector_failure';
  static const String bridgeFailure = 'bridge_failure';
  static const String noCamera = 'no_camera';
}

/// Actionable failure surfaced by the session snapshot.
class CameraFailure {
  const CameraFailure({
    required this.code,
    required this.message,
    required this.action,
    this.recoverable = true,
  });

  final String code;

  /// What happened.
  final String message;

  /// What the player can do about it.
  final String action;

  final bool recoverable;
}

/// Detector/runtime versions for QA reports. Public information only: no user
/// identifiers and nothing that leaves the device automatically.
class CameraRuntimeInfo {
  const CameraRuntimeInfo({
    required this.detectorSdk,
    required this.detectorModel,
    required this.cameraStack,
    required this.minSdk,
    required this.apiLevel,
    required this.deviceName,
    this.raw = const {},
  });

  /// Synthetic sessions answer with their fixture label instead.
  factory CameraRuntimeInfo.synthetic({String label = 'synthetic-fixture'}) {
    return CameraRuntimeInfo(
      detectorSdk: label,
      detectorModel: 'none',
      cameraStack: 'none',
      minSdk: 24,
      apiLevel: 0,
      deviceName: 'host',
    );
  }

  /// e.g. `ML Kit pose-detection 18.0.0-beta5`.
  final String detectorSdk;

  /// `base` or `accurate`.
  final String detectorModel;

  /// e.g. `CameraX 1.4.1`.
  final String cameraStack;

  final int minSdk;
  final int apiLevel;
  final String deviceName;
  final Map<String, Object?> raw;
}

/// One locally counted rep.
///
/// [eventId] is stable for the life of the event so retrying the same event is
/// idempotent server-side; [sequence] is monotonic per session phase;
/// [observedAt] is the wall-clock observation time and is never trusted as the
/// round clock; [monotonicMicros] is the local monotonic time used for tests
/// and diagnostics. Events never contain an image, a thumbnail or landmarks.
class RepEvent {
  const RepEvent({
    required this.eventId,
    required this.sequence,
    required this.observedAt,
    required this.monotonicMicros,
    required this.counterVersion,
    required this.confidence,
    required this.exercise,
    required this.competitive,
    required this.practice,
  });

  final String eventId;
  final int sequence;
  final DateTime observedAt;
  final int monotonicMicros;
  final String counterVersion;
  final double confidence;
  final ArenaExercise exercise;

  /// False for practice reps and debug-fixture sessions.
  final bool competitive;

  /// True only for the unscored practice rep.
  final bool practice;

  /// Payload fields for the `rep` action in `docs/API.md`. The match id is
  /// added by the battle feature, not by the camera layer.
  Map<String, Object?> toArenaRepPayload() => {
        'event_id': eventId,
        'sequence': sequence,
        'observed_at': observedAt.toUtc().toIso8601String(),
        'counter_version': counterVersion,
      };

  @override
  String toString() =>
      'RepEvent($eventId, seq=$sequence, competitive=$competitive)';
}

/// Immutable view of a camera session for widgets and tests.
class CameraSessionSnapshot {
  const CameraSessionSnapshot({
    required this.exercise,
    required this.permission,
    required this.phase,
    required this.tracking,
    required this.pauseReason,
    required this.instruction,
    required this.practiceComplete,
    required this.reps,
    required this.framingLocked,
    required this.trackingConfidence,
    required this.isCompetitive,
    this.viewMode = CameraViewMode.side,
    this.countingSide,
    this.previewTextureId,
    this.previewGeometry,
    this.torchEnabled = false,
    this.demoLabel,
    this.failure,
    this.detectorSdk,
    this.lastRepRejection = RepRejection.none,
    this.lastRepRejectionMicros,
  });

  final ArenaExercise exercise;
  final CameraPermissionStatus permission;
  final CameraSessionPhase phase;
  final CameraTrackingState tracking;
  final TrackingPauseReason pauseReason;

  /// Player-facing instruction matching [tracking] and [pauseReason].
  final String instruction;

  /// True once the unscored practice rep has been completed.
  final bool practiceComplete;

  /// Reps counted in the current practice or round phase.
  final int reps;

  final bool framingLocked;
  final double trackingConfidence;

  /// Camera placement the counter is currently using. Drives the skeleton
  /// overlay's highlighted chain; it is not a new detection.
  final CameraViewMode viewMode;

  /// Body side of the side-view counting chain the counter selected, or `null`
  /// while no side-view signal has been measured or in a front view.
  final PoseSide? countingSide;

  /// False for debug-fixture sessions; a server result can never be built
  /// from a non-competitive session.
  final bool isCompetitive;

  /// Android texture id for the local preview; `null` when no preview runs.
  final int? previewTextureId;
  final CameraPreviewGeometry? previewGeometry;

  final bool torchEnabled;

  /// Visible label for non-competitive sessions, e.g.
  /// `DEMO FIXTURE — NOT COUNTED`.
  final String? demoLabel;

  final CameraFailure? failure;
  final String? detectorSdk;

  /// Why the most recent judged transition did not count, or [RepRejection.none]
  /// when the last rep counted. Coaching only: it never changes tracking or
  /// the score.
  final RepRejection lastRepRejection;

  /// Analysis-frame timestamp of the frame that judged the last rejected
  /// transition. Widgets use it to tell a new rejection apart from the
  /// previous one and show the cue once per event.
  final int? lastRepRejectionMicros;

  /// True only when this session may contribute to a competitive match.
  bool get canProduceMatchResult =>
      isCompetitive && phase == CameraSessionPhase.live;

  /// True when the player has finished practice and tracking is stable.
  bool get readyForMatch =>
      practiceComplete && tracking == CameraTrackingState.tracking;

  @override
  String toString() =>
      'CameraSessionSnapshot(${exercise.wire}, $phase, $tracking, reps=$reps)';
}

/// Player-facing copy for the tracking state and pause reason.
String trackingInstruction({
  required ArenaExercise exercise,
  required CameraTrackingState tracking,
  required TrackingPauseReason reason,
  required bool practiceComplete,
}) {
  if (tracking == CameraTrackingState.paused) {
    return 'Paused. The battle clock keeps running while you are paused.';
  }
  switch (reason) {
    case TrackingPauseReason.none:
      break;
    case TrackingPauseReason.noPerson:
      return exercise == ArenaExercise.pushUps
          ? 'Counting paused: I cannot see you. Lie sideways (best for '
              'depth) or face the phone head-on, with your shoulders and '
              'hands visible.'
          : 'Counting paused: I cannot see you. Stand sideways in frame with '
              'your hip, knee and ankle visible.';
    case TrackingPauseReason.lowLight:
      return 'Counting paused: it is too dark to track you. Move to better '
          'light or turn on the torch.';
    case TrackingPauseReason.partialBody:
      return exercise == ArenaExercise.pushUps
          ? 'Counting paused: part of you is outside the frame. Move the '
              'phone back until your counting arm, hip and ankle are visible '
              'side-on, or both hands and hips head-on.'
          : 'Counting paused: part of you is outside the frame. Step back '
              'until your hip, knee and ankle are visible.';
    case TrackingPauseReason.tooClose:
      return tracking == CameraTrackingState.tracking
          ? 'Counting. You are too close to the camera. Move the phone back.'
          : 'You are too close to the camera. Move the phone back.';
    case TrackingPauseReason.heelsLifted:
      return tracking == CameraTrackingState.tracking
          ? 'Counting. Your heels are lifting off the floor. Push through '
              'your whole foot.'
          : 'Keep your heels on the floor.';
    case TrackingPauseReason.tooFar:
      return 'Counting paused: you are too far away. Move closer so your '
          'body fills the frame.';
    case TrackingPauseReason.offCenter:
      return 'Counting paused: you are off centre. Move to the middle of '
          'the frame.';
    case TrackingPauseReason.lowConfidence:
      return 'Counting paused: your joints are hard to read. Hold still and '
          'check the light.';
    case TrackingPauseReason.detectorStalled:
      return 'Counting paused: pose tracking stalled. Keep the phone steady '
          'and stay in frame.';
    case TrackingPauseReason.wrongView:
      return 'Counting paused: this exercise is counted from the side. Turn '
          'so the phone sees your side.';
    case TrackingPauseReason.cameraUnavailable:
      return 'Counting paused: the camera is not available. Close other '
          'camera apps and try again.';
    case TrackingPauseReason.cameraBusy:
      return 'Counting paused: another app is using the camera. Close it '
          'and resume.';
    case TrackingPauseReason.permissionBlocked:
      return 'Camera access is blocked. Open Settings and allow the camera '
          'for Fault.';
    case TrackingPauseReason.paused:
      return 'Paused. The battle clock keeps running while you are paused.';
  }
  if (tracking == CameraTrackingState.searching) {
    return exercise == ArenaExercise.pushUps
        ? 'Looking for you: lie sideways (best for depth) or face the phone '
            'head-on, shoulders and hands visible.'
        : 'Looking for you: stand sideways in frame, hip to ankle visible.';
  }
  if (tracking == CameraTrackingState.framing) {
    return 'Hold still while I lock onto your body.';
  }
  return practiceComplete
      ? 'Framed and counting. Give it everything.'
      : 'Framed and counting. This first rep is practice and is not scored.';
}

/// Player-facing coaching copy for a rep that was judged but not counted.
/// Empty for [RepRejection.none]. Every line names the fix, not the fault:
/// silently skipped reps are this category's most common complaint.
String rejectionInstruction(RepRejection rejection) {
  switch (rejection) {
    case RepRejection.none:
      return '';
    case RepRejection.shallow:
      return 'Not counted: the bottom was too brief. Pause briefly at the bottom '
          'before coming up.';
    case RepRejection.tooFast:
      return 'Not counted: too fast. Slow, full reps only.';
    case RepRejection.bodyNotStraight:
      return 'Not counted: keep your body in one straight line.';
    case RepRejection.torsoCollapsed:
      return 'Not counted: keep your chest up as you drive back up.';
    case RepRejection.lowConfidence:
      return 'Not counted: I lost a clear view of the counting joints. '
          'Check your framing and the light.';
    case RepRejection.lockoutMissed:
      return 'Straighten fully at the top.';
    case RepRejection.notDeepEnough:
      return 'Go lower.';
  }
}

/// Player-facing copy for the permission state.
String permissionInstruction(CameraPermissionStatus permission) {
  switch (permission) {
    case CameraPermissionStatus.granted:
      return 'Camera ready. Everything is processed privately on this phone.';
    case CameraPermissionStatus.unknown:
      return 'Fault counts reps privately on this phone. No video '
          'ever leaves the device.';
    case CameraPermissionStatus.denied:
      return 'Camera access is needed to count reps. Tap allow to continue.';
    case CameraPermissionStatus.permanentlyDenied:
      return 'Camera access is blocked. Open Settings and allow the camera '
          'for Fault.';
  }
}
