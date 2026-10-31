/// Local rep state machine for push-ups and squats.
///
/// The counter consumes [PoseFrame]s (in memory only) and answers with a
/// [RepCounterResult]. Two camera placements are supported: a side view (the
/// original joint-angle bands) and a head-on front view for push-ups (shoulder
/// height above the hands, normalised by shoulder width). The placement comes
/// from landmark geometry; an ambiguous frame keeps the previous mode and
/// never invents one.
///
/// It protects against the failure modes the task calls out:
///
/// * signal-chain framing must be stable for a continuous window before any rep
///   can count;
/// * a rep needs a complete down/up transition with a hysteresis band, a
///   bottom dwell, a minimum rep duration and a debounce gap;
/// * tracking loss or low confidence resets the in-progress rep, so a rep
///   split across an occlusion never counts;
/// * duplicate or out-of-order frames are ignored by timestamp, and detector
///   stalls (a large timestamp gap) reset the in-progress rep;
/// * the squat heels-lifted coaching cue (ported from the Squat-Analysis-Model
///   reference, MIT) rides on the result and never blocks a count.
///
/// The state machine is pure Dart so the host tests can drive it with noisy
/// landmark fixtures.
library;

import 'dart:math' as math;
import '../../domain/arena_types.dart';
import '../camera_types.dart';
import '../pose/pose_math.dart';
import '../pose/pose_types.dart';
import 'exercise_profile.dart';

/// Internal counting phase exposed for diagnostics and tests.
enum CounterPhase { awaitingFraming, up, bottom, paused }

/// Why the last bottom transition did not count. `none` when it did.
enum CounterRejection {
  none,
  dwellTooShort,
  repTooFast,
  debounce,
  bodyNotStraight,
  torsoCollapsed,
  lowConfidence,
  lockoutMissed,
  notDeepEnough,
}

/// Result of one [RepCounter.addFrame] call.
class RepCounterResult {
  const RepCounterResult({
    required this.phase,
    required this.tracking,
    required this.pauseReason,
    required this.framingLocked,
    required this.confidence,
    required this.countedReps,
    required this.repCounted,
    required this.rejection,
    required this.duplicateFrame,
    required this.viewMode,
    this.side,
    this.signal,
    this.repConfidence = 0,
    this.outcome = false,
    this.rawSignal,
  });

  final CounterPhase phase;
  final CameraTrackingState tracking;
  final TrackingPauseReason pauseReason;
  final bool framingLocked;

  /// Mean likelihood of the counting landmarks for this frame.
  final double confidence;
  final int countedReps;
  final bool repCounted;
  final CounterRejection rejection;
  final bool duplicateFrame;

  /// Camera placement the counter is currently using.
  final CameraViewMode viewMode;

  /// Body side of the side-view counting chain the counter selected, or `null`
  /// while no side-view signal has been measured. Always `null` in a front
  /// view, which uses both sides.
  final PoseSide? side;

  /// Smoothed primary counting signal, when the frame had one: the primary
  /// joint angle in a side view, the shoulder height above the hands in
  /// shoulder widths in a front view.
  final double? signal;

  /// Mean confidence sampled during the completed bottom phase.
  final double repConfidence;
  final bool outcome;
  final double? rawSignal;
}

class RepCounter {
  RepCounter(this.profile);

  final ExerciseCounterProfile profile;

  bool _suspended = false;
  bool _countingEnabled = true;
  CounterPhase _phase = CounterPhase.awaitingFraming;
  bool _framingLocked = false;
  bool _trackingLost = false;
  TrackingPauseReason _lastLossReason = TrackingPauseReason.none;

  int? _stableSinceMicros;
  int? _invalidSinceMicros;
  int? _lastTimestampMicros;
  int? _lastAcceptedMicros;

  int? _repStartMicros;
  int? _lastCountedMicros;

  int _countedReps = 0;
  int _bottomFrames = 0;
  int _bottomPasses = 0;
  int _bottomConfidenceCount = 0;
  double _bottomConfidenceSum = 0;

  CameraViewMode _viewMode = CameraViewMode.side;
  PoseSide? _side;
  double? _signal;
  double? _rawSignal;
  double? _frontTopTorsoOffset;
  double? _standingHeelAngle;
  int _rawBandMs = 0;
  int? _rawBandStartedAt;

  CounterRejection _lastRejection = CounterRejection.none;
  bool _outcome = false;
  int? _signalTimestamp;
  double? _attemptMinimum;
  double? _attemptPeak;
  bool _rising = false;
  int? _attemptSince;

  bool get countingEnabled => _countingEnabled;

  bool get suspended => _suspended;

  bool get framingLocked => _framingLocked;

  int get countedReps => _countedReps;

  /// Enables or disables new counts without losing framing state. Used after
  /// the practice rep so a ready player cannot bank unscored reps.
  void setCountingEnabled(bool enabled) {
    _countingEnabled = enabled;
  }

  /// Clears counters and any in-progress rep. Framing survives when
  /// [keepFraming] is true (the athlete has not moved).
  void reset({bool keepFraming = true}) {
    _phase = CounterPhase.awaitingFraming;
    _clearInProgressRep();
    _countedReps = 0;
    _lastCountedMicros = null;
    _lastRejection = CounterRejection.none;
    _signal = null;
    _rawSignal = null;
    _frontTopTorsoOffset = null;
    _standingHeelAngle = null;
    _lastTimestampMicros = null;
    _lastAcceptedMicros = null;
    _invalidSinceMicros = null;
    _trackingLost = false;
    if (!keepFraming) {
      _framingLocked = false;
      _stableSinceMicros = null;
      _viewMode = CameraViewMode.side;
    } else if (_framingLocked) {
      _phase = CounterPhase.up;
    }
  }

  /// Pauses counting. Any in-progress rep is discarded and the framing lock
  /// is dropped so the player reframes on resume.
  void pause() {
    _suspended = true;
    _clearInProgressRep();
    _phase = CounterPhase.paused;
    _framingLocked = false;
    _stableSinceMicros = null;
    _invalidSinceMicros = null;
    _trackingLost = false;
    _signal = null;
    _rawSignal = null;
    _frontTopTorsoOffset = null;
    _standingHeelAngle = null;
    _viewMode = CameraViewMode.side;
  }

  /// Resumes counting; signal-chain framing must stabilise again.
  void resume() {
    _suspended = false;
    _phase = CounterPhase.awaitingFraming;
    _framingLocked = false;
    _stableSinceMicros = null;
    _invalidSinceMicros = null;
    _trackingLost = false;
    _signal = null;
    _rawSignal = null;
    _frontTopTorsoOffset = null;
    _standingHeelAngle = null;
    _viewMode = CameraViewMode.side;
  }

  /// Processes one frame. Frames must arrive in monotonic order; duplicates
  /// and older timestamps are ignored.
  RepCounterResult addFrame(PoseFrame frame) {
    _outcome = false;
    final timestamp = frame.timestampMicros;

    if (_suspended) {
      return _result(
        tracking: CameraTrackingState.paused,
        reason: TrackingPauseReason.paused,
      );
    }

    final previousTimestamp = _lastTimestampMicros;
    _lastTimestampMicros = timestamp;
    if (previousTimestamp != null && timestamp <= previousTimestamp) {
      return _result(duplicateFrame: true);
    }

    final lastAccepted = _lastAcceptedMicros;
    final stalled =
        lastAccepted != null &&
        _elapsedMs(timestamp, lastAccepted) > profile.maxFrameGapMs;
    if (stalled) {
      _registerLoss(timestamp, TrackingPauseReason.detectorStalled);
    }

    _updateViewMode(frame);
    final side = _viewMode == CameraViewMode.side ? _selectSide(frame) : null;
    final chain = _viewMode == CameraViewMode.front
        ? profile.frontSignalChain
        : side == null
        ? <PoseLandmarkType>[]
        : profile.signalChain(side);
    final confidence = frame.confidenceOf(chain);
    final invalidReason = _evaluateFrame(frame, chain, confidence);
    if (invalidReason != null) {
      _invalidSinceMicros ??= timestamp;
      _lastAcceptedMicros = timestamp;
      if (_elapsedMs(timestamp, _invalidSinceMicros!) >=
          profile.trackingLossGraceMs) {
        _registerLoss(timestamp, invalidReason);
      }
      return _result(
        tracking: _trackingLost
            ? CameraTrackingState.searching
            : (_framingLocked
                  ? CameraTrackingState.tracking
                  : CameraTrackingState.framing),
        reason: _trackingLost ? invalidReason : TrackingPauseReason.none,
        confidence: confidence,
      );
    }

    _invalidSinceMicros = null;
    _lastAcceptedMicros = timestamp;
    final cue = _softCue(frame);
    if (stalled) {
      _stableSinceMicros = timestamp;
      return _result(
        tracking: CameraTrackingState.searching,
        reason: TrackingPauseReason.detectorStalled,
        confidence: confidence,
      );
    }
    if (_trackingLost) {
      _trackingLost = false;
      _framingLocked = false;
      _stableSinceMicros = timestamp;
      _phase = CounterPhase.awaitingFraming;
    }

    if (!_framingLocked) {
      _stableSinceMicros ??= timestamp;
      if (_elapsedMs(timestamp, _stableSinceMicros!) >=
          profile.framingStableMs) {
        _framingLocked = true;
        _lastLossReason = TrackingPauseReason.none;
      } else {
        return _result(
          tracking: CameraTrackingState.framing,
          confidence: confidence,
          reason: cue,
        );
      }
    }

    if (!_countingEnabled) {
      return _result(
        tracking: CameraTrackingState.tracking,
        confidence: confidence,
        reason: cue,
      );
    }

    final signal = _updateSignal(frame);
    if (signal == null) {
      _registerLoss(timestamp, TrackingPauseReason.lowConfidence);
      return _result(
        tracking: CameraTrackingState.searching,
        reason: TrackingPauseReason.lowConfidence,
        confidence: confidence,
      );
    }

    if (_phase == CounterPhase.awaitingFraming) {
      _phase = CounterPhase.up;
    }

    final enterBottom = _viewMode == CameraViewMode.front
        ? profile.frontEnterBottomSignal
        : profile.enterBottomAngle;
    final exitBottom = _viewMode == CameraViewMode.front
        ? profile.frontExitBottomSignal
        : profile.exitBottomAngle;

    if (_viewMode == CameraViewMode.front &&
        _frontTopTorsoOffset == null &&
        _phase == CounterPhase.up &&
        _rawSignal != null &&
        _rawSignal! >= exitBottom) {
      // Capture the straight-body reference once per framing episode. The
      // first high-signal frame after the framing lock is the stable top hold;
      // re-recording later would capture the sag mid-descent.
      _frontTopTorsoOffset = _frontTorsoOffset(frame);
    }

    if (_viewMode == CameraViewMode.side &&
        profile.exercise == ArenaExercise.squats &&
        profile.heelsLiftedDeviationDeg > 0 &&
        _phase == CounterPhase.up &&
        (_rawSignal ?? 0) >= exitBottom) {
      // Refresh the heels-down reference on every standing frame so a
      // repositioned athlete re-baselines, as the ported reference does; the
      // cue then fires only when the heel rises above the standing angle.
      final heelAngle = _heelLiftAngle(frame);
      if (heelAngle != null) {
        _standingHeelAngle = heelAngle;
      }
    }

    var repCounted = false;
    var repConfidence = 0.0;
    if (_phase == CounterPhase.up && signal <= enterBottom +
        (_viewMode == CameraViewMode.front ? profile.frontNearBottomSignal : profile.nearBottomDegrees) &&
        _attemptSince == null) {
      _attemptSince = timestamp;
      _attemptMinimum = signal;
    }
    if (_attemptSince != null) {
      _attemptMinimum = math.min(_attemptMinimum ?? signal, signal);
    }
    if (_phase == CounterPhase.up) {
      if (signal <= enterBottom) {
        _phase = CounterPhase.bottom;
        _repStartMicros = timestamp;
        _bottomConfidenceSum = confidence;
        _bottomConfidenceCount = 1;
        _bottomFrames = 0;
        _bottomPasses = 0;
        _rising = false;
        _attemptPeak = signal;
        if (_rawSignal != null && _rawSignal! <= enterBottom) {
          _rawBandStartedAt = timestamp;
        }
      } else if (_attemptSince != null &&
          signal >= (_attemptMinimum ?? signal) + profile.directionChangeDegrees &&
          signal >= exitBottom) {
        _lastRejection = CounterRejection.notDeepEnough;
        _outcome = true;
        _clearInProgressRep();
      }
    } else if (_phase == CounterPhase.bottom) {
      if (signal >= enterBottom +
          (_viewMode == CameraViewMode.front ? profile.frontNearBottomSignal : profile.directionChangeDegrees)) {
        _rising = true;
      }
      _attemptPeak = math.max(_attemptPeak ?? signal, signal);
      if (signal <= enterBottom && _rising ||
          _elapsedMs(timestamp, _repStartMicros ?? timestamp) >= profile.attemptTimeoutMs) {
        _lastRejection = CounterRejection.lockoutMissed;
        _outcome = true;
        _phase = CounterPhase.up;
        _clearInProgressRep();
        return _result(tracking: CameraTrackingState.tracking, confidence: confidence, reason: cue);
      }
      _bottomConfidenceSum += confidence;
      _bottomConfidenceCount++;
      _bottomFrames++;
      if (_validateBottom(frame)) {
        _bottomPasses++;
      }
      final raw = _rawSignal;
      if (raw != null) {
        if (raw <= enterBottom) {
          _rawBandStartedAt ??= timestamp;
        } else if (_rawBandStartedAt != null) {
          _rawBandMs += _elapsedMs(timestamp, _rawBandStartedAt!);
          _rawBandStartedAt = null;
        }
      }
      if (signal >= exitBottom) {
        _outcome = true;
        final dwellMs =
            _rawBandMs +
            (_rawBandStartedAt == null
                ? 0
                : _elapsedMs(timestamp, _rawBandStartedAt!));
        final durationMs = _elapsedMs(timestamp, _repStartMicros ?? timestamp);
        final gapMs = _lastCountedMicros == null
            ? 1 << 30
            : _elapsedMs(timestamp, _lastCountedMicros!);
        final enoughPasses = _bottomPasses * 2 >= _bottomFrames;
        final repConfidenceValue =
            _bottomConfidenceSum /
            (_bottomConfidenceCount == 0 ? 1 : _bottomConfidenceCount);
        if (dwellMs < profile.minimumBottomDwellMs) {
          _lastRejection = CounterRejection.dwellTooShort;
        } else if (durationMs < profile.minimumRepDurationMs) {
          _lastRejection = CounterRejection.repTooFast;
        } else if (gapMs < profile.minimumRepGapMs) {
          _lastRejection = CounterRejection.debounce;
        } else if (!enoughPasses) {
          _lastRejection = _validationRejection(frame);
        } else if (repConfidenceValue < profile.trackingConfidence) {
          _lastRejection = CounterRejection.lowConfidence;
        } else {
          _lastRejection = CounterRejection.none;
          _countedReps++;
          _lastCountedMicros = timestamp;
          repCounted = true;
          repConfidence = repConfidenceValue;
        }
        _phase = CounterPhase.up;
        _clearInProgressRep();
      }
    }

    return _result(
      tracking: CameraTrackingState.tracking,
      confidence: confidence,
      reason: cue,
      signal: signal,
      repCounted: repCounted,
      repConfidence: repConfidence,
    );
  }

  // --- internals -----------------------------------------------------------

  /// Whole milliseconds between two microsecond timestamps.
  static int _elapsedMs(int nowMicros, int thenMicros) =>
      (nowMicros - thenMicros) ~/ 1000;

  /// Detects the camera placement and keeps the previous mode on an
  /// ambiguous or incomplete frame.
  void _updateViewMode(PoseFrame frame) {
    final detected = detectCameraViewMode(
      frame,
      minLikelihood: profile.framingConfidence,
    );
    if (detected == null || detected == _viewMode) {
      return;
    }
    _viewMode = detected;
    // The two modes measure different quantities, so a signal carried over
    // from the other mode is meaningless: drop it and the in-progress rep.
    // An interrupted attempt still needs an outcome, just like tracking loss.
    // Otherwise a single noisy view change silently swallows a full descent.
    if (_attemptSince != null || _phase == CounterPhase.bottom) {
      _outcome = true;
      _lastRejection = CounterRejection.lowConfidence;
    }
    _signal = null;
    _rawSignal = null;
    _frontTopTorsoOffset = null;
    _standingHeelAngle = null;
    _clearInProgressRep();
    if (_phase == CounterPhase.bottom) {
      _phase = CounterPhase.up;
    }
  }

  /// Returns a pause reason when the frame cannot be counted, else `null`.
  TrackingPauseReason? _evaluateFrame(
    PoseFrame frame,
    List<PoseLandmarkType> chain,
    double confidence,
  ) {
    if (!frame.hasPose) {
      return frame.luminance < profile.lowLightThreshold
          ? TrackingPauseReason.lowLight
          : TrackingPauseReason.noPerson;
    }
    if (_viewMode == CameraViewMode.front) {
      if (!profile.supportsFrontView) {
        return TrackingPauseReason.wrongView;
      }
      return _evaluateFrontFrame(frame, chain, confidence);
    }
    if (!_chainVisible(frame, chain)) {
      return TrackingPauseReason.partialBody;
    }
    final bounds = frame.boundsOf(chain)!;
    final visibleBody = PoseLandmarkType.values.where((type) {
      final point = frame.point(type);
      return point != null &&
          point.likelihood >= profile.framingConfidence &&
          point.x >= 0 && point.x <= 1 &&
          point.y >= 0 && point.y <= 1;
    });
    if ((frame.boundsOf(visibleBody)?.span ?? 0) <
        profile.minimumBodySpan) {
      return TrackingPauseReason.tooFar;
    }
    if (bounds.centerX < profile.centerMargin ||
        bounds.centerX > 1 - profile.centerMargin ||
        bounds.centerY < profile.centerMargin ||
        bounds.centerY > 1 - profile.centerMargin) {
      return TrackingPauseReason.offCenter;
    }
    if (confidence < profile.trackingConfidence) {
      return TrackingPauseReason.lowConfidence;
    }
    return null;
  }

  /// Head-on framing: the shoulder line is the size proxy because the rest of
  /// the body is foreshortened. A missing hand is a partial body, never a
  /// locked frame.
  TrackingPauseReason? _evaluateFrontFrame(
    PoseFrame frame,
    List<PoseLandmarkType> chain,
    double confidence,
  ) {
    final allVisible = _chainVisible(frame, chain);
    final span = _frontGeometry(frame)?.shoulderWidth;
    if (!allVisible) {
      return TrackingPauseReason.partialBody;
    }
    if (span == null) {
      return TrackingPauseReason.noPerson;
    }
    if (span < profile.frontMinimumShoulderSpan) {
      return TrackingPauseReason.tooFar;
    }
    final bounds = frame.boundsOf(chain);
    if (bounds == null) {
      return TrackingPauseReason.noPerson;
    }
    if (bounds.centerX < profile.centerMargin ||
        bounds.centerX > 1 - profile.centerMargin ||
        bounds.centerY < profile.centerMargin ||
        bounds.centerY > 1 - profile.centerMargin) {
      return TrackingPauseReason.offCenter;
    }
    if (confidence < profile.trackingConfidence) {
      return TrackingPauseReason.lowConfidence;
    }
    return null;
  }

  bool _chainVisible(PoseFrame frame, List<PoseLandmarkType> chain) {
    if (chain.isEmpty ||
        !frame.allVisible(chain, minLikelihood: profile.framingConfidence)) {
      return false;
    }
    final bounds = frame.boundsOf(chain)!;
    return bounds.left >= 0 &&
        bounds.right <= 1 &&
        bounds.top >= 0 &&
        bounds.bottom <= 1;
  }

  TrackingPauseReason? _softCue(PoseFrame frame) {
    final tooClose = _viewMode == CameraViewMode.front
        ? (_frontGeometry(frame)?.shoulderWidth ?? 0) >
              profile.frontMaximumShoulderSpan
        : (frame.boundsOf(PoseLandmarkType.values)?.span ?? 0) >
              profile.maximumBodySpan;
    if (tooClose) {
      return TrackingPauseReason.tooClose;
    }
    if (_standingHeelAngle != null) {
      final heelAngle = _heelLiftAngle(frame);
      if (heelAngle != null &&
          heelAngle - _standingHeelAngle! >=
              profile.heelsLiftedDeviationDeg) {
        return TrackingPauseReason.heelsLifted;
      }
    }
    return null;
  }

  /// Heel-to-toe inclination of the selected side, or `null` when either foot
  /// landmark is missing or below the framing likelihood. Foot landmarks are
  /// the first to leave the frame, so a `null` here simply disables the cue.
  double? _heelLiftAngle(PoseFrame frame) {
    final side = _side;
    if (side == null) {
      return null;
    }
    final heel = frame.point(side.heel());
    final toe = frame.point(side.footIndex());
    if (heel == null ||
        toe == null ||
        heel.likelihood < profile.framingConfidence ||
        toe.likelihood < profile.framingConfidence) {
      return null;
    }
    return heelToToeAngleDegrees(heel, toe, aspectRatio: frame.aspectRatio);
  }

  double? _updateSignal(PoseFrame frame) {
    if (_viewMode == CameraViewMode.front) {
      return _updateFrontSignal(frame);
    }
    final side = _selectSide(frame);
    if (side == null) {
      return null;
    }
    final chain = profile.primaryChain(side);
    final first = frame.point(chain[0]);
    final vertex = frame.point(chain[1]);
    final second = frame.point(chain[2]);
    if (first == null || vertex == null || second == null) {
      return null;
    }
    final raw = angleDegrees(first, vertex, second, aspectRatio: frame.aspectRatio);
    _rawSignal = raw;
    final switched = _side != side;
    _side = side;
    _signal = switched ? raw : smoothValue(_signal, raw, _alpha(frame));
    _signalTimestamp = frame.timestampMicros;
    return _signal;
  }

  /// Shoulder height above the hands, in shoulder widths. High at the top of
  /// a head-on push-up, low at the bottom.
  double? _updateFrontSignal(PoseFrame frame) {
    final geometry = _frontGeometry(frame);
    if (geometry == null) {
      return null;
    }
    final raw =
        (geometry.wristMidY - geometry.shoulderMidY) / geometry.shoulderWidth;
    _rawSignal = raw;
    _signal = smoothValue(_signal, raw, _alpha(frame));
    _signalTimestamp = frame.timestampMicros;
    return _signal;
  }

  /// Shared head-on geometry; `null` when any of the joints is missing.
  ({
    double shoulderWidth,
    double shoulderMidY,
    double hipMidY,
    double wristMidY,
  })?
  _frontGeometry(PoseFrame frame) {
    final leftShoulder = frame.point(PoseLandmarkType.leftShoulder);
    final rightShoulder = frame.point(PoseLandmarkType.rightShoulder);
    final leftWrist = frame.point(PoseLandmarkType.leftWrist);
    final rightWrist = frame.point(PoseLandmarkType.rightWrist);
    final leftHip = frame.point(PoseLandmarkType.leftHip);
    final rightHip = frame.point(PoseLandmarkType.rightHip);
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }
    final shoulderWidth = pointDistance(leftShoulder, rightShoulder, aspectRatio: frame.aspectRatio);
    if (shoulderWidth <= 0) {
      return null;
    }
    return (
      shoulderWidth: shoulderWidth,
      shoulderMidY: (leftShoulder.y + rightShoulder.y) / 2,
      hipMidY: (leftHip.y + rightHip.y) / 2,
      wristMidY: (leftWrist.y + rightWrist.y) / 2,
    );
  }

  /// Projected shoulder-to-hip offset in shoulder widths. Straight body
  /// keeps it; sag or pike moves it.
  double? _frontTorsoOffset(PoseFrame frame) {
    final geometry = _frontGeometry(frame);
    if (geometry == null) {
      return null;
    }
    return (geometry.hipMidY - geometry.shoulderMidY) / geometry.shoulderWidth;
  }

  PoseSide? _selectSide(PoseFrame frame) {
    double score(PoseSide side) => frame.confidenceOf(profile.signalChain(side));
    final left = score(PoseSide.left);
    final right = score(PoseSide.right);
    final best = left >= right ? PoseSide.left : PoseSide.right;
    final current = _side;
    if (current == null) {
      return best;
    }
    final currentScore = score(current);
    final bestScore = score(best);
    if (best != current && (bestScore > currentScore + profile.sideSwitchMargin ||
        !frame.allVisible(profile.signalChain(current), minLikelihood: profile.framingConfidence))) {
      return best;
    }
    if (currentScore <= 0) {
      return bestScore > 0 ? best : null;
    }
    return current;
  }

  bool _validateBottom(PoseFrame frame) {
    if (_viewMode == CameraViewMode.front) {
      if (!profile.supportsFrontView) {
        return false;
      }
      final reference = _frontTopTorsoOffset;
      if (reference == null) {
        // No straight top was observed yet. Counting stays open so the first
        // rep of a set is not lost; F3 traces decide whether to fail closed.
        return true;
      }
      final current = _frontTorsoOffset(frame);
      if (current == null) {
        return false;
      }
      return (current - reference).abs() <= profile.frontMaximumTorsoDrift;
    }
    final side = _side;
    if (side == null) {
      return false;
    }
    switch (profile.exercise) {
      case ArenaExercise.pushUps:
        final shoulder = frame.point(side.shoulder());
        final hip = frame.point(side.hip());
        final ankle = frame.point(side.ankle());
        if (shoulder == null || hip == null || ankle == null) {
          return false;
        }
        return angleDegrees(shoulder, hip, ankle, aspectRatio: frame.aspectRatio) >= profile.minimumBodyLineAngle;
      case ArenaExercise.squats:
        final shoulder = frame.point(side.shoulder());
        final hip = frame.point(side.hip());
        if (shoulder == null || hip == null) {
          return false;
        }
        // Reject a folded-over torso; depth itself is guarded by the knee
        // angle band, so the centre-of-joint check would be wrong here.
        return leanDegrees(hip, shoulder, aspectRatio: frame.aspectRatio).abs() <= profile.maximumTorsoLean;
    }
  }

  CounterRejection _validationRejection(PoseFrame frame) {
    if (_viewMode == CameraViewMode.front) {
      // Only push-ups count head-on; a front failure is a body-line failure.
      return CounterRejection.bodyNotStraight;
    }
    final side = _side;
    if (side == null) {
      return CounterRejection.lowConfidence;
    }
    switch (profile.exercise) {
      case ArenaExercise.pushUps:
        return CounterRejection.bodyNotStraight;
      case ArenaExercise.squats:
        return CounterRejection.torsoCollapsed;
    }
  }

  void _registerLoss(int timestamp, TrackingPauseReason reason) {
    _signal = null;
    _rawSignal = null;
    _signalTimestamp = null;
    if (_attemptSince != null || _phase == CounterPhase.bottom) {
      _outcome = true;
      _lastRejection = CounterRejection.lowConfidence;
    }
    _trackingLost = true;
    _framingLocked = false;
    _stableSinceMicros = null;
    _phase = CounterPhase.awaitingFraming;
    _lastLossReason = reason;
    _frontTopTorsoOffset = null;
    _standingHeelAngle = null;
    _clearInProgressRep();
  }

  void _clearInProgressRep() {
    _attemptSince = null;
    _attemptMinimum = null;
    _attemptPeak = null;
    _rising = false;
    _repStartMicros = null;
    _bottomFrames = 0;
    _bottomPasses = 0;
    _bottomConfidenceCount = 0;
    _bottomConfidenceSum = 0;
    _rawBandMs = 0;
    _rawBandStartedAt = null;
  }

  RepCounterResult _result({
    CameraTrackingState? tracking,
    TrackingPauseReason? reason,
    double confidence = 0,
    double? signal,
    bool repCounted = false,
    double repConfidence = 0,
    bool duplicateFrame = false,
  }) {
    final resolvedTracking =
        tracking ??
        (_trackingLost
            ? CameraTrackingState.searching
            : (_framingLocked
                  ? CameraTrackingState.tracking
                  : CameraTrackingState.framing));
    final resolvedReason =
        reason ??
        (_trackingLost
            ? _lastLossReason
            : (_suspended
                  ? TrackingPauseReason.paused
                  : TrackingPauseReason.none));
    return RepCounterResult(
      phase: _phase,
      tracking: resolvedTracking,
      pauseReason: resolvedReason,
      framingLocked: _framingLocked,
      confidence: confidence,
      countedReps: _countedReps,
      repCounted: repCounted,
      rejection: _lastRejection,
      duplicateFrame: duplicateFrame,
      viewMode: _viewMode,
      side: _side,
      signal: signal ?? _signal,
      repConfidence: repConfidence,
      outcome: _outcome,
      rawSignal: _rawSignal,
    );
  }

  double _alpha(PoseFrame frame) {
    final previous = _signalTimestamp;
    return previous == null ? 1 :
        1 - math.exp(-(frame.timestampMicros - previous) / (profile.smoothingTauMs * 1000));
  }
}
