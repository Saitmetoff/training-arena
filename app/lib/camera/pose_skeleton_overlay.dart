/// Skeleton overlay for the local camera preview (task F4).
///
/// The overlay draws the landmarks the rep counter already consumes. It runs
/// no detector and holds no image: landmarks arrive as normalised numbers in
/// the upright analysis frame, so the work here is mapping them onto the
/// displayed preview and emphasising the chain the counter is measuring for
/// the current exercise and camera placement. Nothing is written, logged or
/// exported; a frame is drawn and forgotten.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/arena_types.dart';
import '../theme/arena_tokens.dart';
import 'camera_session.dart';
import 'camera_types.dart';
import 'counter/exercise_profile.dart';
import 'pose/pose_types.dart';

/// Standalone fixture fallback. Production uses native preview metadata.
const Size posePreviewFrameSize = Size(720, 1280);

/// Maps one normalised landmark into the displayed preview box.
///
/// [normalised] is in the upright analysis frame (`x`/`y` in 0..1, `y` down),
/// the same frame the counter consumes. [frameSize] is the size the frame
/// content is displayed at after [quarterTurns] rotation, and [boxSize] is the
/// widget showing it. [quarterTurns] rotates the frame clockwise like
/// `RotatedBox`; [mirrored] flips it horizontally in display space, after the
/// rotation. The fit follows `FittedBox` semantics: cover crops the
/// overflowing axis, contain letterboxes, both keep the frame centred.
Offset poseOverlayPoint({
  required Offset normalised,
  required Size boxSize,
  required Size frameSize,
  BoxFit fit = BoxFit.cover,
  int quarterTurns = 0,
  bool mirrored = false,
  CameraPreviewGeometry? geometry,
}) {
  if (geometry != null) {
    final mapped = geometry.project(normalised.dx, normalised.dy);
    normalised = Offset(mapped.$1, mapped.$2);
    frameSize = Size(
      geometry.crop[2] - geometry.crop[0],
      geometry.crop[3] - geometry.crop[1],
    );
    mirrored = geometry.mirrored;
    quarterTurns =
        0; // The affine transform already includes analysis rotation.
  }
  var x = normalised.dx;
  var y = normalised.dy;
  switch (quarterTurns & 3) {
    case 1:
      final rotatedX = 1 - y;
      y = x;
      x = rotatedX;
    case 2:
      x = 1 - x;
      y = 1 - y;
    case 3:
      final rotatedX = y;
      y = 1 - x;
      x = rotatedX;
  }
  if (mirrored) {
    x = 1 - x;
  }
  final fitted = applyBoxFit(fit, frameSize, boxSize);
  final sourceLeft = (frameSize.width - fitted.source.width) / 2;
  final sourceTop = (frameSize.height - fitted.source.height) / 2;
  final u = fitted.source.width <= 0
      ? 0.0
      : (x * frameSize.width - sourceLeft) / fitted.source.width;
  final v = fitted.source.height <= 0
      ? 0.0
      : (y * frameSize.height - sourceTop) / fitted.source.height;
  return Offset(
    (boxSize.width - fitted.destination.width) / 2 +
        u * fitted.destination.width,
    (boxSize.height - fitted.destination.height) / 2 +
        v * fitted.destination.height,
  );
}

/// The standard skeleton: both arms, both legs, the shoulder and hip lines and
/// the nose-to-shoulder lines. Drawn dim under the counting chain.
const List<(PoseLandmarkType, PoseLandmarkType)> poseSkeletonSegments = [
  (PoseLandmarkType.nose, PoseLandmarkType.leftShoulder),
  (PoseLandmarkType.nose, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
  (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
];

/// The chain the counter is currently measuring, emphasised over the dim
/// skeleton. [primaryJoint] is the vertex of the counted angle (elbow or knee)
/// and is ringed; the front-view signal has no single vertex.
class PoseCountingChain {
  const PoseCountingChain({required this.segments, this.primaryJoint});

  /// Nothing measured yet: the skeleton stays dim.
  static const PoseCountingChain none = PoseCountingChain(segments: []);

  final List<(PoseLandmarkType, PoseLandmarkType)> segments;
  final PoseLandmarkType? primaryJoint;
}

/// Picks the chain for the counter's exercise and camera placement. Reuses the
/// counter's own profile, so the emphasised landmarks are exactly the ones it
/// consumes: the selected side's angle chain in a side view, and the shoulder
/// line, hand line and torso in a front view.
PoseCountingChain poseCountingChain({
  required ArenaExercise exercise,
  required CameraViewMode viewMode,
  required PoseSide? side,
}) {
  final profile = ExerciseCounterProfile.forExercise(exercise);
  if (viewMode == CameraViewMode.front) {
    if (!profile.supportsFrontView) {
      return PoseCountingChain.none;
    }
    return const PoseCountingChain(
      segments: [
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
        (PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist),
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
        (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      ],
    );
  }
  if (side == null) {
    return PoseCountingChain.none;
  }
  final chain = profile.primaryChain(side);
  return PoseCountingChain(
    segments: [(chain[0], chain[1]), (chain[1], chain[2])],
    primaryJoint: chain[1],
  );
}

/// Paints the skeleton over the preview.
///
/// The frame is read through a [ValueListenable] so a new frame repaints the
/// canvas without rebuilding the widget tree, and the [Paint] objects are
/// created once and reused. Missing landmarks, or landmarks below
/// [minLikelihood] (the counter's framing gate), are skipped, so a partial
/// body paints safely and the overlay never invents a joint.
class PoseSkeletonPainter extends CustomPainter {
  PoseSkeletonPainter({
    required ValueListenable<PoseFrame?> frame,
    required this.exercise,
    this.viewMode = CameraViewMode.side,
    this.side,
    this.fit = BoxFit.cover,
    this.frameSize = posePreviewFrameSize,
    this.quarterTurns = 0,
    this.mirrored = false,
    this.minLikelihood = 0.5,
    this.rejectFlash = false,
    this.geometry,
  })  : _frame = frame,
        super(repaint: frame) {
    _dimLine.color = ArenaColors.quiet.withValues(alpha: 0.45);
    _activeLine.color = rejectFlash ? ArenaColors.warning : ArenaColors.lime;
    _joint.color = rejectFlash ? ArenaColors.warning : ArenaColors.lime;
    _ring.color = rejectFlash ? ArenaColors.warning : ArenaColors.softWhite;
  }

  static const double _dimStroke = 2;
  static const double _activeStroke = 4;
  static const double _jointRadius = 4;
  static const double _ringRadius = 8;

  final ValueListenable<PoseFrame?> _frame;
  final ArenaExercise exercise;
  final CameraViewMode viewMode;
  final PoseSide? side;
  final BoxFit fit;
  final Size frameSize;
  final int quarterTurns;
  final bool mirrored;
  final double minLikelihood;

  /// True while the most recent down/up transition was rejected: the counting
  /// chain and joint ring turn the warning colour so the player sees exactly
  /// which joints failed the check while the coaching cue is on screen.
  final bool rejectFlash;
  final CameraPreviewGeometry? geometry;

  final Paint _dimLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _dimStroke
    ..strokeCap = StrokeCap.round;
  final Paint _activeLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _activeStroke
    ..strokeCap = StrokeCap.round;
  final Paint _joint = Paint()..style = PaintingStyle.fill;
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = _frame.value;
    if (frame == null || !frame.hasPose || size.isEmpty) {
      return;
    }
    final chain = poseCountingChain(
      exercise: exercise,
      viewMode: viewMode,
      side: side,
    );
    for (final (first, second) in poseSkeletonSegments) {
      _drawSegment(canvas, frame, size, first, second, _dimLine);
    }
    final activeJoints = <PoseLandmarkType>{};
    for (final (first, second) in chain.segments) {
      if (_drawSegment(canvas, frame, size, first, second, _activeLine)) {
        activeJoints.add(first);
        activeJoints.add(second);
      }
    }
    for (final joint in activeJoints) {
      canvas.drawCircle(_pointOf(frame, size, joint)!, _jointRadius, _joint);
    }
    final primary = chain.primaryJoint;
    if (primary != null) {
      final centre = _pointOf(frame, size, primary);
      if (centre != null) {
        canvas.drawCircle(centre, _ringRadius, _ring);
      }
    }
  }

  bool _drawSegment(
    Canvas canvas,
    PoseFrame frame,
    Size size,
    PoseLandmarkType first,
    PoseLandmarkType second,
    Paint paint,
  ) {
    final a = _pointOf(frame, size, first);
    final b = _pointOf(frame, size, second);
    if (a == null || b == null) {
      return false;
    }
    canvas.drawLine(a, b, paint);
    return true;
  }

  Offset? _pointOf(PoseFrame frame, Size size, PoseLandmarkType type) {
    final point = frame.point(type);
    if (point == null || point.likelihood < minLikelihood) {
      return null;
    }
    return poseOverlayPoint(
      normalised: Offset(point.x, point.y),
      boxSize: size,
      frameSize: frameSize,
      fit: fit,
      quarterTurns: quarterTurns,
      mirrored: mirrored,
      geometry: geometry,
    );
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) =>
      oldDelegate.exercise != exercise ||
      oldDelegate.viewMode != viewMode ||
      oldDelegate.side != side ||
      oldDelegate.fit != fit ||
      oldDelegate.frameSize != frameSize ||
      oldDelegate.quarterTurns != quarterTurns ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.minLikelihood != minLikelihood ||
      oldDelegate.rejectFlash != rejectFlash ||
      oldDelegate.geometry != geometry;
}

/// Draws the counter's landmarks over a [CameraPreview].
///
/// The widget listens to [CameraSession.poseFrames] and repaints through a
/// [ValueNotifier], so incoming frames do not rebuild the surrounding card.
/// It paints nothing when [active] or [visible] is false, before the first
/// frame, and when the frame has no pose at all. [viewMode] and [side] come
/// from the session snapshot, so the highlight matches the counter instead of
/// re-detecting anything.
class PoseSkeletonOverlay extends StatefulWidget {
  const PoseSkeletonOverlay({
    super.key,
    required this.session,
    this.viewMode = CameraViewMode.side,
    this.side,
    this.active = true,
    this.visible = true,
    this.fit = BoxFit.cover,
    this.frameSize = posePreviewFrameSize,
    this.quarterTurns = 0,
    this.mirrored = false,
    this.rejectFlash = false,
    this.geometry,
  });

  final CameraSession session;
  final CameraViewMode viewMode;
  final PoseSide? side;
  final bool active;
  final bool visible;
  final BoxFit fit;
  final Size frameSize;
  final int quarterTurns;
  final bool mirrored;

  /// Paints the counting chain in the warning colour while a rep was just
  /// rejected; see [PoseSkeletonPainter.rejectFlash].
  final bool rejectFlash;
  final CameraPreviewGeometry? geometry;

  @override
  State<PoseSkeletonOverlay> createState() => _PoseSkeletonOverlayState();
}

class _PoseSkeletonOverlayState extends State<PoseSkeletonOverlay> {
  late final ValueNotifier<PoseFrame?> _frame = ValueNotifier<PoseFrame?>(
    widget.session.latestFrame,
  );
  StreamSubscription<PoseFrame>? _subscription;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant PoseSkeletonOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _subscription?.cancel();
      _listen();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _frame.dispose();
    super.dispose();
  }

  void _listen() {
    _frame.value = widget.session.latestFrame;
    _subscription = widget.session.poseFrames.listen((frame) {
      _frame.value = frame;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || !widget.visible) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      key: const ValueKey('pose-skeleton'),
      size: Size.infinite,
      painter: PoseSkeletonPainter(
        frame: _frame,
        exercise: widget.session.exercise,
        viewMode: widget.viewMode,
        side: widget.side,
        fit: widget.fit,
        frameSize: widget.frameSize,
        quarterTurns: widget.quarterTurns,
        mirrored: widget.mirrored,
        rejectFlash: widget.rejectFlash,
        geometry: widget.geometry,
      ),
    );
  }
}
