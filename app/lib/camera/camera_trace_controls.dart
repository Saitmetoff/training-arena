/// Voluntary numeric diagnostics. No image recording or automatic upload.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/arena_config.dart';
import '../theme/arena_tokens.dart';
import 'camera_session.dart';
import 'camera_types.dart';
import 'pose/pose_types.dart';
import 'trace/pose_trace_recorder.dart';

/// Can be mounted on preparation, preview or result without owning recording.
class CameraTraceControls extends StatefulWidget {
  const CameraTraceControls({
    super.key,
    required this.session,
    this.traceDirectory,
  });

  final CameraSession session;
  final Future<Directory> Function()? traceDirectory;

  @override
  State<CameraTraceControls> createState() => _CameraTraceControlsState();
}

class _CameraTraceControlsState extends State<CameraTraceControls> {
  final _frames = ValueNotifier<int>(0);
  StreamSubscription<PoseFrame>? _subscription;
  String? _note;
  bool _busy = false;

  PoseTraceRecorder? get _trace => widget.session is CameraSessionController
      ? (widget.session as CameraSessionController).diagnosticTrace
      : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  @override
  void didUpdateWidget(covariant CameraTraceControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _subscription?.cancel();
      _subscription = null;
      _note = null;
      _attach();
    }
  }

  void _attach() {
    final enabled =
        ArenaConfigScope.maybeOf(context)?.cameraTraceEnabled ??
        const bool.fromEnvironment('ARENA_FEATURE_CAMERA_TRACE');
    if (!enabled || widget.session is! CameraSessionController) return;
    (widget.session as CameraSessionController).enableDiagnosticTrace();
    _frames.value = _trace?.frameCount ?? 0;
    _subscription ??= widget.session.poseFrames.listen((_) {
      _frames.value = _trace?.frameCount ?? 0;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _frames.dispose();
    super.dispose();
  }

  Future<Directory> _directory() async => widget.traceDirectory != null
      ? widget.traceDirectory!()
      : PoseTraceRecorder.directoryFor(
          await getApplicationDocumentsDirectory(),
        );

  Future<void> _export() async {
    final trace = _trace;
    if (trace == null || trace.isEmpty || trace.roundActive || _busy) return;
    setState(() => _busy = true);
    try {
      final directory = await _directory();
      if (!mounted || trace.roundActive) return;
      final file = trace.save(directory, inAppReps: widget.session.reps);
      setState(() => _note = file.uri.pathSegments.last);
      // Only this explicit post-round/pre-practice tap opens the OS share UI.
      // The saved numeric file remains available if there is no share target.
      unawaited(
        SharePlus.instance
            .share(
              ShareParams(
                files: [XFile(file.path, mimeType: 'text/plain')],
                subject: 'Fault landmark trace',
              ),
            )
            .then<void>((_) {}, onError: (Object _) {}),
      );
    } catch (_) {
      if (mounted) setState(() => _note = 'TRACE EXPORT FAILED');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final trace = _trace;
    if (trace == null || trace.roundActive || _busy) return;
    setState(() => _busy = true);
    try {
      final directory = await _directory();
      if (!mounted || trace.roundActive) return;
      PoseTraceRecorder.deleteStored(directory);
      trace.clear();
      _frames.value = 0;
      setState(() => _note = 'TRACE CLEARED');
    } catch (_) {
      if (mounted) setState(() => _note = 'TRACE DELETE FAILED');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ArenaConfigScope.maybeOf(context)?.cameraTraceEnabled ??
        const bool.fromEnvironment('ARENA_FEATURE_CAMERA_TRACE');
    if (!enabled || _trace == null) return const SizedBox.shrink();
    return StreamBuilder<CameraSessionSnapshot>(
      stream: widget.session.snapshots,
      initialData: widget.session.snapshot,
      builder: (context, _) {
        final trace = _trace!;
        return ValueListenableBuilder<int>(
          valueListenable: _frames,
          builder: (context, count, _) => Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _note ??
                    '${trace.completed ? 'TRACE READY' : 'TRACE ON'} · $count',
                key: const ValueKey('camera-trace-label'),
                style: const TextStyle(
                  color: ArenaColors.warning,
                  fontSize: 11,
                ),
              ),
              IconButton(
                key: const ValueKey('camera-trace-export'),
                tooltip: trace.roundActive
                    ? 'Export after the round'
                    : 'Export landmark trace',
                onPressed: _busy || trace.roundActive || trace.isEmpty
                    ? null
                    : _export,
                icon: const Icon(Icons.ios_share),
              ),
              IconButton(
                key: const ValueKey('camera-trace-delete'),
                tooltip: 'Delete exported traces',
                onPressed: _busy || trace.roundActive ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        );
      },
    );
  }
}
