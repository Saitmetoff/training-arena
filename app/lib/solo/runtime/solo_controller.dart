/// Solo max-reps set state machine.
///
/// A solo set is practice: it never creates a receipt, rating, leaderboard
/// entry or server match. Camera counting reuses the shared [CameraSession]
/// pipeline; when the camera is unavailable the player can enter reps
/// manually and the result is labelled self-reported.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../battle/ports/battle_clock.dart';
import '../../camera/camera_session.dart';
import '../../camera/camera_types.dart';
import '../../domain/arena_types.dart';
import '../data/solo_result_store.dart';
import '../domain/solo_result.dart';
import '../domain/solo_streak.dart';

/// Builds the camera session a solo set counts with; tests inject a fake.
typedef SoloCameraFactory = CameraSession Function(ArenaExercise exercise);

/// Owner diagnostics only. Release builds and trace-off builds stay push-ups.
ArenaExercise diagnosticSoloExercise({
  bool debug = kDebugMode,
  bool trace = const bool.fromEnvironment('ARENA_FEATURE_CAMERA_TRACE'),
  String requested = const String.fromEnvironment(
    'ARENA_DIAGNOSTIC_SOLO_EXERCISE',
  ),
}) => debug && trace && requested == 'squats'
    ? ArenaExercise.squats
    : ArenaExercise.pushUps;

/// Where the solo flow currently is.
enum SoloPhase { intro, countdown, practice, counting, manualEntry, result }

/// Immutable view of the solo flow for widgets and tests.
@immutable
class SoloSnapshot {
  const SoloSnapshot({
    this.phase = SoloPhase.intro,
    this.countdown = 0,
    this.reps = 0,
    this.elapsedSeconds = 0,
    this.cameraEnabled = false,
    this.result,
    this.saved = false,
    this.saving = false,
    this.message,
    this.stats = SoloStats.empty,
    this.streak = SoloStreak.empty,
    this.recentResults = const [],
    this.previousBestReps,
  });

  final SoloPhase phase;

  /// Seconds left in the 3-2-1 countdown.
  final int countdown;

  /// Live counted reps (camera path) or the value being entered (manual).
  final int reps;

  final int elapsedSeconds;
  final bool cameraEnabled;
  final SoloSetResult? result;
  final bool saved;
  final bool saving;
  final String? message;
  final SoloStats stats;

  /// Local daily-goal and streak view over the stored history.
  final SoloStreak streak;
  final List<SoloSetResult> recentResults;
  final int? previousBestReps;

  bool get inCameraFlow =>
      phase == SoloPhase.countdown ||
      phase == SoloPhase.practice ||
      phase == SoloPhase.counting;
}

class SoloController extends ChangeNotifier {
  SoloController({
    required SoloResultStore store,
    BattleClock? clock,
    SoloCameraFactory? cameraFactory,
    bool cameraEnabled = false,
  }) : _store = store,
       _clock = clock ?? const SystemBattleClock(),
       _cameraFactory = cameraFactory ?? _defaultCameraFactory,
       _cameraEnabled = cameraEnabled,
       exercise = diagnosticSoloExercise();

  final ArenaExercise exercise;

  static const int countdownFrom = 3;
  static const Duration countdownStep = Duration(seconds: 1);
  static const Duration tickStep = Duration(seconds: 1);
  static const int manualRepsCeiling = 1000;

  static CameraSession _defaultCameraFactory(ArenaExercise exercise) =>
      CameraSession.platform(exercise: exercise);

  final SoloResultStore _store;
  final BattleClock _clock;
  final SoloCameraFactory _cameraFactory;
  final bool _cameraEnabled;

  CameraSession? _session;
  StreamSubscription<CameraSessionSnapshot>? _cameraSub;
  BattleTimer? _tick;
  DateTime? _startedAt;
  List<SoloSetResult>? _results;
  SoloStats _stats = SoloStats.empty;
  SoloStreak _streak = SoloStreak.empty;
  SoloPhase _phase = SoloPhase.intro;
  int _countdown = 0;
  int _reps = 0;
  int _manualReps = 0;
  int _elapsedSeconds = 0;
  SoloSetResult? _result;
  bool _saved = false;
  bool _saving = false;
  Future<void>? _loading;
  bool _loadFailed = false;
  int? _previousBestReps;
  String? _message;
  bool _disposed = false;

  SoloSnapshot get snapshot => SoloSnapshot(
    phase: _phase,
    countdown: _countdown,
    reps: _phase == SoloPhase.manualEntry ? _manualReps : _reps,
    elapsedSeconds: _elapsedSeconds,
    cameraEnabled: _cameraEnabled,
    result: _result,
    saved: _saved,
    saving: _saving,
    message: _message,
    stats: _stats,
    streak: _streak,
    recentResults: recentSoloResults(_results ?? const [], _clock.now()),
    previousBestReps: _previousBestReps,
  );

  /// The live camera session, for the shared preview widget.
  CameraSession? get cameraSession => _session;

  /// Loads the stored history and derives [SoloStats].
  Future<void> load() => _loading = _readHistory();

  Future<void> _readHistory() async {
    List<SoloSetResult> results;
    try {
      results = await _store.read();
      _loadFailed = false;
    } catch (_) {
      _loadFailed = true;
      _message =
          'Could not load saved sets. Your history has not been changed.';
      _notify();
      return;
    }
    if (_disposed) {
      return;
    }
    _results = results;
    final result = _result;
    if (result != null && !_saved) {
      _previousBestReps = soloPersonalBest(
        results,
        exercise: result.exercise,
        source: result.source,
      );
    }
    _stats = SoloStats.from(results);
    _streak = SoloStreak.from(results, _clock.now());
    _notify();
  }

  /// Starts the camera path: 3-2-1, one practice rep, then the set.
  void startCamera() {
    if (!_cameraEnabled || _phase != SoloPhase.intro) {
      return;
    }
    _message = null;
    _countdown = countdownFrom;
    _phase = SoloPhase.countdown;
    _notify();
    _tick?.cancel();
    _tick = _clock.periodic(countdownStep, _onCountdownTick);
  }

  void _onCountdownTick() {
    if (_phase != SoloPhase.countdown) {
      return;
    }
    _countdown -= 1;
    if (_countdown > 0) {
      _notify();
      return;
    }
    _tick?.cancel();
    _tick = null;
    unawaited(_openCamera());
  }

  Future<void> _openCamera() async {
    final session = _cameraFactory(exercise);
    _session = session;
    _cameraSub = session.snapshots.listen(_onCameraSnapshot);
    try {
      final granted = await session.requestPermission();
      if (_disposed) {
        return;
      }
      if (!granted) {
        await _disposeSession();
        _message =
            'Camera permission was not granted. Enter reps manually instead.';
        _phase = SoloPhase.intro;
        _notify();
        return;
      }
      final started = await session.startPractice();
      if (_disposed) {
        return;
      }
      if (!started) {
        await _disposeSession();
        _message = 'The camera could not start. Enter reps manually instead.';
        _phase = SoloPhase.intro;
        _notify();
        return;
      }
      _phase = SoloPhase.practice;
      _notify();
    } catch (_) {
      if (_disposed) {
        return;
      }
      await _disposeSession();
      _message = 'The camera could not start. Enter reps manually instead.';
      _phase = SoloPhase.intro;
      _notify();
    }
  }

  void _onCameraSnapshot(CameraSessionSnapshot snapshot) {
    if (_disposed) {
      return;
    }
    _reps = snapshot.reps;
    if (_phase == SoloPhase.practice && snapshot.practiceComplete) {
      // Deferred: starting the round emits another snapshot, and the camera
      // session may deliver updates synchronously. Re-entering the stream
      // listener from inside its own add would throw.
      scheduleMicrotask(() => unawaited(_beginRound()));
    }
    _notify();
  }

  Future<void> _beginRound() async {
    final session = _session;
    if (session == null || _phase != SoloPhase.practice) {
      return;
    }
    // Enter the phase before awaiting so a repeated snapshot cannot begin the
    // round twice.
    _phase = SoloPhase.counting;
    final started = await session.beginRound();
    if (_disposed) {
      return;
    }
    if (!started) {
      _phase = SoloPhase.practice;
      _message = 'The round could not start. Try again.';
      _notify();
      return;
    }
    _startedAt = _clock.now();
    _elapsedSeconds = 0;
    _tick = _clock.periodic(tickStep, _onElapsedTick);
    _notify();
  }

  void _onElapsedTick() {
    if (_phase != SoloPhase.counting || _startedAt == null) {
      return;
    }
    _elapsedSeconds = _clock.now().difference(_startedAt!).inSeconds;
    _notify();
  }

  /// Ends the camera-counted set and freezes the counted reps.
  Future<void> endSet() async {
    if (_phase != SoloPhase.counting) {
      return;
    }
    _tick?.cancel();
    _tick = null;
    final session = _session;
    final reps = session?.reps ?? _reps;
    await session?.endRound();
    if (_disposed) {
      return;
    }
    _finish(
      reps: reps,
      durationSeconds: _elapsedSeconds,
      source: SoloCountSource.camera,
    );
  }

  /// Opens the manual entry path (the working pilot path with the camera off).
  void startManualEntry() {
    if (_phase != SoloPhase.intro) {
      return;
    }
    _message = null;
    _manualReps = 0;
    _phase = SoloPhase.manualEntry;
    _notify();
  }

  void adjustManualReps(int delta) => setManualReps(_manualReps + delta);

  void setManualReps(int reps) {
    if (_phase != SoloPhase.manualEntry) {
      return;
    }
    _manualReps = reps.clamp(0, manualRepsCeiling).toInt();
    _notify();
  }

  /// Saves the self-reported set; requires at least one rep.
  void submitManual() {
    if (_phase != SoloPhase.manualEntry || _manualReps <= 0) {
      return;
    }
    _finish(
      reps: _manualReps,
      durationSeconds: 0,
      source: SoloCountSource.manual,
    );
  }

  void _finish({
    required int reps,
    required int durationSeconds,
    required SoloCountSource source,
  }) {
    _result = SoloSetResult(
      exercise: exercise,
      reps: reps,
      durationSeconds: durationSeconds,
      completedAt: _clock.now().toUtc(),
      source: source,
    );
    _previousBestReps = _results == null
        ? null
        : soloPersonalBest(
            _results!,
            exercise: _result!.exercise,
            source: source,
          );
    _saved = false;
    _phase = SoloPhase.result;
    _notify();
  }

  /// Persists the finished set to this device and updates the stats.
  Future<void> save() async {
    final result = _result;
    if (result == null || _saved || _saving) {
      return;
    }
    _saving = true;
    _message = null;
    _notify();
    try {
      if (_loading == null) await load();
      await _loading;
      if (_loadFailed) await load();
      if (_disposed) return;
      if (_loadFailed) throw StateError('History unavailable');
      _previousBestReps = soloPersonalBest(
        _results!,
        exercise: result.exercise,
        source: result.source,
      );
      final updated = trimSoloResults(<SoloSetResult>[result, ..._results!]);
      await _store.write(updated);
      if (_disposed) return;
      _results = updated;
      _stats = SoloStats.from(updated);
      _streak = SoloStreak.from(updated, _clock.now());
      _saved = true;
    } catch (_) {
      _message =
          'Could not save this set. Your count is still here. Try again.';
    } finally {
      _saving = false;
      _notify();
    }
  }

  /// Returns to the intro without saving the current result.
  Future<void> restart() async {
    if (_saving) return;
    await _disposeSession();
    if (_disposed) {
      return;
    }
    _phase = SoloPhase.intro;
    _countdown = 0;
    _reps = 0;
    _manualReps = 0;
    _elapsedSeconds = 0;
    _result = null;
    _saved = false;
    _message = null;
    _notify();
  }

  Future<void> _disposeSession() async {
    _tick?.cancel();
    _tick = null;
    final sub = _cameraSub;
    _cameraSub = null;
    await sub?.cancel();
    final session = _session;
    _session = null;
    await session?.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    unawaited(_cameraSub?.cancel());
    unawaited(_session?.dispose());
    super.dispose();
  }
}
