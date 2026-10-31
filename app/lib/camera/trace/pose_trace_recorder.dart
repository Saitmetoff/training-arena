/// Debug-only landmark trace recorder (task F3).
///
/// When `ARENA_FEATURE_CAMERA_TRACE` is on (never in a release build), the
/// camera session feeds the counter's landmark frames here. The recorder keeps
/// the last [window] of frames in memory and writes them on demand as the
/// text format the replay harness parses (`pose_trace_format.dart`). It holds
/// numbers only: no frame, image, device identifier or account value, and
/// nothing is written until the owner exports a trace.
library;

import 'dart:collection';
import 'dart:io';

import '../../domain/arena_types.dart';
import '../pose/pose_types.dart';
import 'pose_trace_format.dart';

/// In-memory ring of the most recent landmark frames.
class PoseTraceRecorder {
  PoseTraceRecorder({
    required this.exercise,
    this.window = const Duration(seconds: 180),
  });

  /// App-private subdirectory the exported traces live in.
  static const String directoryName = 'camera-traces';

  /// File-name prefix; trace names never carry a device or account value.
  static const String filePrefix = 'trace-';

  /// Resolves the trace directory under an app-private documents directory.
  static Directory directoryFor(Directory documents) =>
      Directory('${documents.path}${Platform.pathSeparator}$directoryName');

  /// Fixture/exercise this recording belongs to; written as a comment line.
  final ArenaExercise exercise;

  /// How much of the stream is kept. Older frames are dropped as new ones
  /// arrive, so the export is always the last [window].
  final Duration window;

  final Queue<PoseFrame> _frames = Queue<PoseFrame>();
  int? _roundStartAfterMicros;
  int? _completedReps;
  bool _roundActive = false;
  final List<String> _counterEvents = [];

  void counterEvent(String event) {
    if (!completed) {
      _counterEvents.add(
        '# counter_event: ${_frames.isEmpty ? -1 : _frames.last.timestampMicros},$event',
      );
    }
  }

  bool get roundActive => _roundActive;
  bool get completed => _completedReps != null;

  /// Keep the framing lead-in, but distinguish it from scored round frames.
  /// A fresh round replaces the previous completed recording.
  void beginRound() {
    if (completed) clear();
    _roundStartAfterMicros = _frames.isEmpty
        ? -1
        : _frames.last.timestampMicros;
    _completedReps = null;
    _roundActive = true;
  }

  /// Freeze the completed recording before the result screen replaces preview.
  void endRound(int reps) {
    _roundActive = false;
    _completedReps = reps;
  }

  int get frameCount => _frames.length;

  bool get isEmpty => _frames.isEmpty;

  /// Appends one frame and drops everything older than [window].
  void add(PoseFrame frame) {
    if (completed) return;
    _frames.addLast(frame);
    final cutoff = frame.timestampMicros - window.inMicroseconds;
    while (_frames.isNotEmpty && _frames.first.timestampMicros < cutoff) {
      _frames.removeFirst();
    }
  }

  /// Forgets the current window (the stored files are untouched).
  void clear() {
    _frames.clear();
    _counterEvents.clear();
    _roundStartAfterMicros = null;
    _completedReps = null;
    _roundActive = false;
  }

  /// The recorded window in the C05 text format. [inAppReps] is the count the
  /// app showed at export time, written as a comment for the agreement check.
  String text({int? inAppReps}) {
    final body = serializePoseTrace(
      _frames,
      exercise: exercise,
      inAppReps: _completedReps ?? inAppReps,
    );
    final start = _roundStartAfterMicros;
    return '${_counterEvents.join('\n')}\n${start == null ? '' : '# round_start_after_us: $start\n# round_completed: ${completed ? 1 : 0}\n'}$body';
  }

  /// Writes the window to [directory] and returns the file. Synchronous: the
  /// export happens on a user tap and the ring is a few megabytes at most.
  File save(Directory directory, {int? inAppReps, DateTime? now}) {
    directory.createSync(recursive: true);
    final stamp = _stamp(now ?? DateTime.now());
    String path(String name) =>
        '${directory.path}${Platform.pathSeparator}$name';
    var file = File(path('$filePrefix${exercise.wire}-$stamp.txt'));
    var suffix = 1;
    while (file.existsSync()) {
      file = File(path('$filePrefix${exercise.wire}-$stamp-$suffix.txt'));
      suffix++;
    }
    file.writeAsStringSync(text(inAppReps: inAppReps));
    return file;
  }

  /// Exported trace files under [directory], oldest name first.
  static List<File> storedFiles(Directory directory) {
    if (!directory.existsSync()) {
      return const <File>[];
    }
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.uri.pathSegments.last.startsWith(filePrefix))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Deletes every exported trace file under [directory].
  static void deleteStored(Directory directory) {
    for (final file in storedFiles(directory)) {
      file.deleteSync();
    }
  }

  static String _stamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}'
        '-${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
