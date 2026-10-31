/// Camera-owned preview primitive for the battle feature.
///
/// The widget renders the local Android texture plus the current instruction,
/// rep count, the non-competitive demo label and, on top of the texture, the
/// [PoseSkeletonOverlay] showing the landmarks the counter consumes. It never
/// encodes or stores the preview; task `07` places it inside the live-round
/// screen.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/arena_tokens.dart';
import 'camera_session.dart';
import 'camera_types.dart';
import 'pose/pose_types.dart';
import 'pose_skeleton_overlay.dart';
import 'camera_trace_controls.dart';
export 'camera_trace_controls.dart';

class CameraPreview extends StatefulWidget {
  const CameraPreview({
    super.key,
    required this.session,
    this.fit = BoxFit.cover,
    this.showInstruction = true,
    this.traceDirectory,
    this.showDiagnostics = kDebugMode,
  });

  final CameraSession session;
  final BoxFit fit;
  final bool showInstruction;
  final bool showDiagnostics;

  /// The local preview uses the front camera, so the texture and the skeleton
  /// overlay are mirrored together like a selfie view; the analysis frame the
  /// counter consumes is not mirrored.
  static const bool previewMirrored = true;

  /// Test seam for the debug trace export; production resolves the
  /// app-private directory with `path_provider`.
  final Future<Directory> Function()? traceDirectory;

  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  /// Skeleton preference for this camera session; visible by default.
  bool _skeletonVisible = true;

  /// How long a `rep not counted` cue stays on screen. The session publishes
  /// the rejection; this widget owns how long the coaching stays visible.
  static const Duration repCueDuration = Duration(milliseconds: 2600);

  final ValueNotifier<RepRejection?> _repCue = ValueNotifier<RepRejection?>(
    null,
  );
  Timer? _repCueTimer;
  int? _lastCueMicros;
  StreamSubscription<CameraSessionSnapshot>? _repCueSubscription;

  @override
  void initState() {
    super.initState();
    _observeRepCues();
  }

  @override
  void didUpdateWidget(covariant CameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _resetRepCue();
    }
  }

  @override
  void dispose() {
    _repCueSubscription?.cancel();
    _repCueTimer?.cancel();
    _repCue.dispose();
    super.dispose();
  }

  /// Shows the coaching cue once per new rejection event and hides it again
  /// after [repCueDuration]. A repeated identical rejection (a new frame time)
  /// restarts the window.
  void _observeRepCues() {
    _repCueSubscription = widget.session.snapshots.listen((snapshot) {
      final micros = snapshot.lastRepRejectionMicros;
      if (snapshot.lastRepRejection == RepRejection.none ||
          micros == null ||
          micros == _lastCueMicros) {
        return;
      }
      _lastCueMicros = micros;
      _repCue.value = snapshot.lastRepRejection;
      _repCueTimer?.cancel();
      _repCueTimer = Timer(repCueDuration, () => _repCue.value = null);
    });
  }

  void _resetRepCue() {
    _repCueSubscription?.cancel();
    _repCueSubscription = null;
    _repCueTimer?.cancel();
    _repCueTimer = null;
    _lastCueMicros = null;
    _repCue.value = null;
    _observeRepCues();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraSessionSnapshot>(
      stream: widget.session.snapshots,
      initialData: widget.session.snapshot,
      builder: (context, asyncSnapshot) {
        final snapshot = asyncSnapshot.data ?? widget.session.snapshot;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: snapshot.failure == null
                  ? ArenaColors.graphite
                  : ArenaColors.charcoal,
              child:
                  snapshot.previewTextureId == null ||
                      snapshot.previewGeometry == null
                  ? _placeholder(snapshot)
                  : _texture(snapshot),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<RepRejection?>(
                valueListenable: _repCue,
                builder: (context, rejection, _) => PoseSkeletonOverlay(
                  session: widget.session,
                  viewMode: snapshot.viewMode,
                  side: snapshot.countingSide,
                  active: _skeletonActive(snapshot),
                  visible: _skeletonVisible,
                  fit: widget.fit,
                  mirrored: CameraPreview.previewMirrored,
                  rejectFlash: rejection != null,
                  geometry: snapshot.previewGeometry,
                ),
              ),
            ),
            if (snapshot.demoLabel != null)
              Positioned(
                left: 12,
                top: 12,
                child: _DemoBadge(label: snapshot.demoLabel!),
              ),
            if (snapshot.phase == CameraSessionPhase.practice ||
                snapshot.phase == CameraSessionPhase.live ||
                snapshot.phase == CameraSessionPhase.ready)
              Positioned(
                right: 12,
                top: 12,
                child: _RepBadge(
                  reps: snapshot.reps,
                  practice: !snapshot.practiceComplete,
                ),
              ),
            if (_showsSkeletonToggle(snapshot))
              Positioned(
                left: 12,
                top: snapshot.demoLabel != null ? 56 : 12,
                child: _SkeletonToggle(
                  visible: _skeletonVisible,
                  onPressed: () {
                    setState(() => _skeletonVisible = !_skeletonVisible);
                  },
                ),
              ),
            Positioned(
              right: 12,
              top: 56,
              child: CameraTraceControls(
                session: widget.session,
                traceDirectory: widget.traceDirectory,
              ),
            ),
            if (widget.showInstruction)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: ValueListenableBuilder<RepRejection?>(
                  valueListenable: _repCue,
                  builder: (context, rejection, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rejection != null) ...[
                        _RepCueCard(rejection: rejection),
                        const SizedBox(height: 8),
                      ],
                      _InstructionCard(snapshot: snapshot),
                    ],
                  ),
                ),
              ),
            if (widget.showDiagnostics)
              Positioned(
                left: 12,
                right: 12,
                top: 100,
                child: _DiagnosticsHud(session: widget.session),
              ),
          ],
        );
      },
    );
  }

  Widget _texture(CameraSessionSnapshot snapshot) {
    final geometry = snapshot.previewGeometry!;
    final crop = geometry.crop;
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: Transform.flip(
        flipX: geometry.mirrored,
        child: SizedBox(
          width: crop[2] - crop[0],
          height: crop[3] - crop[1],
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -crop[0],
                  top: -crop[1],
                  width: geometry.width,
                  height: geometry.height,
                  child: RotatedBox(
                    quarterTurns: geometry.textureQuarterTurns,
                    child: Texture(textureId: snapshot.previewTextureId!),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The skeleton is drawn only over a live texture, while the counter is
  /// practising or counting, and while it has a usable pose. Lost tracking
  /// leaves the existing guidance card visible and the overlay empty.
  bool _skeletonActive(CameraSessionSnapshot snapshot) =>
      snapshot.previewTextureId != null &&
      (snapshot.phase == CameraSessionPhase.practice ||
          snapshot.phase == CameraSessionPhase.ready ||
          snapshot.phase == CameraSessionPhase.live) &&
      (snapshot.tracking == CameraTrackingState.tracking ||
          snapshot.tracking == CameraTrackingState.framing);

  bool _showsSkeletonToggle(CameraSessionSnapshot snapshot) =>
      snapshot.previewTextureId != null &&
      (snapshot.phase == CameraSessionPhase.practice ||
          snapshot.phase == CameraSessionPhase.ready ||
          snapshot.phase == CameraSessionPhase.live);

  Widget _placeholder(CameraSessionSnapshot snapshot) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              snapshot.isCompetitive
                  ? Icons.videocam_outlined
                  : Icons.smart_display_outlined,
              size: 40,
              color: ArenaColors.quiet,
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.isCompetitive
                  ? 'Camera preview'
                  : 'Synthetic fixture preview',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ArenaColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsHud extends StatefulWidget {
  const _DiagnosticsHud({required this.session});
  final CameraSession session;
  @override
  State<_DiagnosticsHud> createState() => _DiagnosticsHudState();
}

class _DiagnosticsHudState extends State<_DiagnosticsHud> {
  int? previousMicros;
  double fps = 0;
  @override
  Widget build(BuildContext context) => StreamBuilder<PoseFrame>(
    stream: widget.session.poseFrames,
    builder: (context, snapshot) {
      final timestamp = snapshot.data?.timestampMicros;
      if (timestamp != null && timestamp != previousMicros) {
        if (previousMicros != null && timestamp > previousMicros!) {
          fps = 1000000 / (timestamp - previousMicros!);
        }
        previousMicros = timestamp;
      }
      final session = widget.session;
      final result = session is CameraSessionController
          ? session.diagnostics
          : null;
      return ColoredBox(
        color: const Color(0xCC000000),
        child: Text(
          'view: ${result?.viewMode.name ?? session.snapshot.viewMode.name} '
          'side: ${result?.side?.name ?? "none"} phase: ${result?.phase.name ?? "awaitingFraming"}\n'
          'raw: ${result?.rawSignal?.toStringAsFixed(1) ?? "-"} '
          'smoothed: ${result?.signal?.toStringAsFixed(1) ?? "-"}\n'
          'pause: ${session.pauseReason.name} rejection: ${result?.rejection.name ?? "none"} '
          'analysis fps: ${fps.toStringAsFixed(1)}',
          key: const ValueKey('camera-diagnostics'),
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    },
  );
}

class _SkeletonToggle extends StatelessWidget {
  const _SkeletonToggle({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('camera-skeleton-toggle'),
      onPressed: onPressed,
      tooltip: visible ? 'Hide skeleton' : 'Show skeleton',
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: ArenaColors.charcoal.withValues(alpha: 0.7),
        foregroundColor: ArenaColors.softWhite,
      ),
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ArenaColors.warning.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ArenaColors.charcoal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RepBadge extends StatelessWidget {
  const _RepBadge({required this.reps, required this.practice});

  final int reps;
  final bool practice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ArenaColors.charcoal.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        practice ? 'Practice: $reps' : 'Reps: $reps',
        style: const TextStyle(
          color: ArenaColors.lime,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Transient coaching card shown above the guidance while a rep was judged
/// but not counted. The preview dismisses it after [CameraPreview] state's
/// `repCueDuration`; a new rejection restarts the window.
class _RepCueCard extends StatelessWidget {
  const _RepCueCard({required this.rejection});

  final RepRejection rejection;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('camera-rep-cue'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArenaColors.charcoal.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ArenaColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: ArenaColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rejectionInstruction(rejection),
              style: const TextStyle(color: ArenaColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.snapshot});

  final CameraSessionSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final paused =
        snapshot.pauseReason != TrackingPauseReason.none &&
        snapshot.pauseReason != TrackingPauseReason.paused;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArenaColors.charcoal.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: paused ? ArenaColors.warning : ArenaColors.raised,
        ),
      ),
      child: Text(
        snapshot.instruction,
        style: TextStyle(
          color: paused ? ArenaColors.warning : ArenaColors.softWhite,
          fontSize: 14,
        ),
      ),
    );
  }
}
