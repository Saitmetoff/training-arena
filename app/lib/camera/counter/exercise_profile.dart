/// Per-exercise counting thresholds.
///
/// Push-up thresholds are derived from the media demonstration
/// (`docs/media/ATHLETE_SPEC.md` §5): start elbow 159.5°, bottom 91.2°.
/// Squat thresholds use the same structure adapted to knee angles: start
/// 175.5°, bottom 80.4°. Thresholds are deliberately wider than the authored
/// key poses because ML Kit landmark angles are noisier than the rendered
/// mannequin; the hysteresis band and dwell rules below are the protection
/// against jitter, not the exact angle.
library;

import '../../domain/arena_types.dart';
import '../pose/pose_types.dart';

// All candidate counter thresholds live here; SYNTHETIC tuning only.
const frontViewShoulderRatio = 0.75;
const sideViewShoulderRatio = 0.35;
const frontViewShoulderZSpread = 0.06;
const sideViewShoulderZSpread = 0.12;

/// Immutable threshold set for one exercise.
class ExerciseCounterProfile {
  const ExerciseCounterProfile({
    required this.exercise,
    required this.primaryJointName,
    required this.enterBottomAngle,
    required this.exitBottomAngle,
    required this.minimumBottomDwellMs,
    required this.minimumRepDurationMs,
    required this.minimumRepGapMs,
    required this.trackingConfidence,
    required this.framingConfidence,
    required this.framingStableMs,
    required this.trackingLossGraceMs,
    required this.maxFrameGapMs,
    required this.minimumBodySpan,
    required this.maximumBodySpan,
    this.supportsFrontView = false,
    this.frontEnterBottomSignal = 0.60,
    this.frontExitBottomSignal = 0.90,
    this.frontMinimumShoulderSpan = 0.12,
    this.frontMaximumShoulderSpan = 0.75,
    this.frontMaximumTorsoDrift = 0.30,
    this.heelsLiftedDeviationDeg = 0,
    this.smoothingTauMs = 60,
    this.attemptTimeoutMs = 5000,
    this.nearBottomDegrees = 25,
    this.directionChangeDegrees = 20,
    this.frontNearBottomSignal = 0.15,
    this.sideSwitchMargin = 0.12,
    this.minimumBodyLineAngle = 150,
    this.maximumTorsoLean = 60,
    this.centerMargin = 0.12,
    this.lowLightThreshold = 0.18,
  });

  /// Thresholds for the two supported exercises.
  ///
  /// Values are intentionally duplicated per exercise instead of computed so
  /// a reviewer can see exactly what ships.
  factory ExerciseCounterProfile.forExercise(ArenaExercise exercise) {
    switch (exercise) {
      case ArenaExercise.pushUps:
        return const ExerciseCounterProfile(
          exercise: ArenaExercise.pushUps,
          primaryJointName: 'elbow',
          enterBottomAngle: 105,
          exitBottomAngle: 145,
          minimumBottomDwellMs: 60,
          minimumRepDurationMs: 250,
          minimumRepGapMs: 350,
          trackingConfidence: 0.60,
          framingConfidence: 0.55,
          framingStableMs: 500,
          trackingLossGraceMs: 300,
          maxFrameGapMs: 600,
          minimumBodySpan: 0.35,
          maximumBodySpan: 0.98,
          supportsFrontView: true,
          frontEnterBottomSignal: 0.60,
          frontExitBottomSignal: 0.90,
          frontMinimumShoulderSpan: 0.12,
          frontMaximumShoulderSpan: 0.75,
          frontMaximumTorsoDrift: 0.30,
        );
      case ArenaExercise.squats:
        return const ExerciseCounterProfile(
          exercise: ArenaExercise.squats,
          primaryJointName: 'knee',
          enterBottomAngle: 105,
          exitBottomAngle: 155,
          minimumBottomDwellMs: 60,
          minimumRepDurationMs: 250,
          minimumRepGapMs: 400,
          trackingConfidence: 0.60,
          framingConfidence: 0.55,
          framingStableMs: 500,
          trackingLossGraceMs: 300,
          maxFrameGapMs: 600,
          minimumBodySpan: 0.35,
          maximumBodySpan: 0.98,
          heelsLiftedDeviationDeg: 12,
        );
    }
  }

  final ArenaExercise exercise;
  final double smoothingTauMs;
  final double frontNearBottomSignal;
  final int attemptTimeoutMs;
  final double nearBottomDegrees, directionChangeDegrees, sideSwitchMargin;
  final double minimumBodyLineAngle, maximumTorsoLean, centerMargin, lowLightThreshold;

  /// Human readable primary joint for diagnostics (`elbow` / `knee`).
  final String primaryJointName;

  /// Angle at or below which the bottom phase is entered.
  final double enterBottomAngle;

  /// Angle at or above which the bottom phase is left and a rep completes.
  final double exitBottomAngle;

  /// Minimum time the athlete must stay in the bottom band.
  final int minimumBottomDwellMs;

  /// Minimum time from smoothed bottom entry to top lockout, not a whole rep.
  final int minimumRepDurationMs;

  /// Debounce between two counted reps.
  final int minimumRepGapMs;

  /// Minimum mean likelihood of the counting landmarks for a frame to count.
  final double trackingConfidence;

  /// Minimum likelihood of each signal-chain landmark for framing to lock.
  final double framingConfidence;

  /// Continuous stable framing required before counting unlocks.
  final int framingStableMs;

  /// Invalid frames tolerated before the counter reports loss.
  final int trackingLossGraceMs;

  /// Largest in-stream gap before the counter treats detection as stalled.
  final int maxFrameGapMs;

  /// Smallest visible body span and body span that prompts a move-back cue.
  final double minimumBodySpan;
  final double maximumBodySpan;

  /// True when a head-on placement is counted (push-ups). Squats are
  /// side-view only: the knee bends towards the lens, so the side-view knee
  /// signal is degenerate head-on and the counter asks the athlete to turn.
  final bool supportsFrontView;

  /// Front-view counting signal: shoulder height above the hands divided by
  /// the shoulder width. Enter/exit follow the same low-bottom/high-top shape
  /// as the angle bands. Candidate values until F3 replays real traces.
  final double frontEnterBottomSignal;
  final double frontExitBottomSignal;

  /// Smallest and largest shoulder width accepted while framing head-on. The
  /// shoulder line is the only body axis that stays in the image plane when
  /// the body is foreshortened, so it is the front-view size proxy.
  final double frontMinimumShoulderSpan;
  final double frontMaximumShoulderSpan;

  /// Largest allowed drift of the projected shoulder-to-hip offset (in
  /// shoulder widths) between the top of the rep and the bottom. A straight
  /// body keeps the offset; sag or pike moves it.
  final double frontMaximumTorsoDrift;

  /// Deviation of the heel-to-toe angle from the standing baseline above
  /// which a squat athlete gets a heels-lifted cue. A coaching cue, never a
  /// rejection: the rep is still judged by the knee band. Ported from the
  /// Squat-Analysis-Model reference (rohanx01, MIT), which gates at +3° on
  /// pixel-space landmarks; ML Kit foot landmarks are noisier, so the band is
  /// wider. 0 disables the cue (push-ups). Candidate value until F3 replays
  /// real traces.
  final double heelsLiftedDeviationDeg;

  /// Per-view joints used for framing, tracking confidence and counting.
  List<PoseLandmarkType> signalChain(PoseSide side) => switch (exercise) {
    ArenaExercise.pushUps => [
      side.shoulder(),
      side.elbow(),
      side.wrist(),
      side.hip(),
      side.ankle(),
    ],
    ArenaExercise.squats => [side.hip(), side.knee(), side.ankle()],
  };

  List<PoseLandmarkType> get frontSignalChain => const [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
  ];

  /// The three landmarks forming the primary joint angle on one side.
  List<PoseLandmarkType> primaryChain(PoseSide side) {
    switch (exercise) {
      case ArenaExercise.pushUps:
        return [side.shoulder(), side.elbow(), side.wrist()];
      case ArenaExercise.squats:
        return [side.hip(), side.knee(), side.ankle()];
    }
  }
}
