/// Battle runtime controller.
///
/// Owns exactly one [BattleSnapshot], converts user commands, backend
/// replies, camera events and clock ticks into [BattleEvent]s, and drives
/// the timing rules: inbox polling, 1 Hz match heartbeats, queue windows
/// (15 s offer, 60 s stop), the 10-second single-player recovery window and
/// the server clock offset.
///
/// The controller never enters [BattlePhase.result] itself; only a server
/// receipt does through the state machine.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../domain/arena_types.dart';
import '../ports/battle_analytics.dart';
import '../ports/battle_backend.dart';
import '../ports/battle_camera.dart';
import '../ports/battle_challenge_entry.dart';
import '../ports/battle_challenge_sharer.dart';
import '../ports/battle_clock.dart';
import '../ports/battle_feedback.dart';
import '../ports/battle_session_store.dart';
import '../state/battle_events.dart';
import '../state/battle_failure.dart';
import '../state/battle_models.dart';
import '../state/battle_phase.dart';
import '../state/battle_snapshot.dart';
import '../state/battle_state_machine.dart';

/// Timing constants fixed by the product contract.
abstract final class BattleTimings {
  static const Duration inboxPoll = Duration(seconds: 4);
  static const Duration heartbeat = Duration(seconds: 1);

  /// Authoritative queue polling cadence while a seat is open.
  static const Duration queuePoll = Duration(seconds: 2);

  static const Duration queueAlternativeAfter = Duration(seconds: 15);
  static const Duration queueLimit = Duration(seconds: 60);
  static const Duration recoveryWindow = Duration(seconds: 10);
  static const Duration matchExpiry = Duration(minutes: 10);
}

/// Controller for the battle feature.
class BattleController extends ChangeNotifier with WidgetsBindingObserver {
  BattleController({
    required this.backend,
    required this.camera,
    required this.clock,
    required this.feedback,
    required this.sessionStore,
    BattleChallengeSharer? sharer,
    BattleAnalyticsSink? analytics,
    ValueListenable<ArenaProfile?>? viewer,
    bool previewFixtures = false,
    this.rankedMatchmakingEnabled = true,
    this.observeLifecycle = true,
  }) : _viewer = viewer ?? ValueNotifier<ArenaProfile?>(null),
       _sharer = sharer ?? const PendingBattleChallengeSharer(),
       _analytics = analytics ?? const NoopBattleAnalyticsSink() {
    _snapshot = BattleSnapshot(previewFixtures: previewFixtures);
    final initialViewer = _viewer.value;
    if (initialViewer != null) {
      _snapshot = BattleStateMachine.apply(
        _snapshot,
        ViewerChanged(initialViewer),
      );
    }
    _viewer.addListener(_handleViewerChanged);
    if (observeLifecycle) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _observerAttached = true;
      } catch (_) {
        // No binding in pure Dart tests: lifecycle handling is skipped.
      }
    }
    _cameraUpdates = camera.updates.listen(
      _handleCameraUpdate,
      onError: (Object error) {
        _dispatch(
          const TrackingChanged(
            BattleCameraStatus.unavailable,
            message: 'Camera tracking stopped. No manual scoring exists.',
          ),
        );
      },
    );
    _cameraReps = camera.reps.listen(
      _handleRep,
      onError: (Object error) {
        _dispatch(
          const TrackingChanged(
            BattleCameraStatus.trackingLost,
            message: 'Camera counting stopped. The shared clock keeps running.',
          ),
        );
      },
    );
  }

  final BattleBackend backend;
  final BattleCamera camera;
  final BattleClock clock;
  final BattleFeedback feedback;
  final BattleSessionStore sessionStore;
  final BattleChallengeSharer _sharer;
  final BattleAnalyticsSink _analytics;
  BattleChallengeEntryDelegate? _entryDelegate;

  /// True when this controller pauses polling with the app lifecycle.
  final bool observeLifecycle;

  /// True when the release enables ranked matchmaking (`ARENA_FEATURE_RANKED_MATCHMAKING`).
  ///
  /// When false the controller refuses every queue join here, in one place, so
  /// no alternate entry point can start a ranked seat; friend challenges, the
  /// inbox and link acceptance are unaffected.
  final bool rankedMatchmakingEnabled;

  final ValueListenable<ArenaProfile?> _viewer;

  late BattleSnapshot _snapshot;

  StreamSubscription<BattleCameraUpdate>? _cameraUpdates;
  StreamSubscription<BattleRepEvent>? _cameraReps;

  BattleTimer? _tickTimer;
  BattleTimer? _inboxTimer;

  bool _disposed = false;
  bool _requiresUpdate = false;
  bool _paused = false;
  Future<void>? _cameraSuspension;
  bool _accepting = false;
  bool _rematching = false;
  bool get rematching => _rematching;
  bool _flushingReps = false;
  bool _observerAttached = false;
  bool _queueJoining = false;
  bool _queuePolling = false;

  Duration _serverOffset = Duration.zero;
  DateTime? _queueAnchorLocal;
  Duration _queueAnchorElapsed = Duration.zero;
  DateTime? _lastQueuePollLocal;
  String? _restoreAttempted;
  String? _cameraStartedMatchId;
  String? _storedMatchId;
  int? _lastCountdownSecond;
  bool _tenAnnounced = false;
  bool _threeAnnounced = false;
  final List<PendingRepEvent> _pendingReps = <PendingRepEvent>[];

  /// Immutable current state. UI reads this after every notification.
  BattleSnapshot get snapshot => _snapshot;

  /// Viewer source shared with the account feature (task 06).
  ValueListenable<ArenaProfile?> get viewerListenable => _viewer;

  /// Server clock offset applied to local time; zero until a server reply.
  Duration get serverOffset => _serverOffset;

  /// Server-side now, used for queue windows and the countdown.
  DateTime get serverNow => clock.now().add(_serverOffset);

  /// Remaining time for the active countdown or round, server-clocked.
  Duration? get phaseRemaining {
    final match = _snapshot.match;
    if (match == null) {
      return null;
    }
    final DateTime? target;
    if (_snapshot.phase == BattlePhase.countdown) {
      target = match.startsAt;
    } else if (_snapshot.phase == BattlePhase.live ||
        _snapshot.phase == BattlePhase.reconnecting) {
      target = match.endsAt;
    } else {
      target = null;
    }
    if (target == null) {
      return null;
    }
    final remaining = target.difference(serverNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Seconds left in the live round (60..0), or null outside a round.
  int? get liveSecondsRemaining {
    final remaining = phaseRemaining;
    if (remaining == null ||
        (_snapshot.phase != BattlePhase.live &&
            _snapshot.phase != BattlePhase.reconnecting)) {
      return null;
    }
    return remaining.inSeconds;
  }

  /// Countdown seconds left (5..0), or null outside the countdown.
  int? get countdownSecondsRemaining {
    if (_snapshot.phase != BattlePhase.countdown) {
      return null;
    }
    final remaining = phaseRemaining;
    if (remaining == null) {
      return null;
    }
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    return seconds < 0 ? 0 : seconds;
  }

  /// 0..1 round progress, used by the timer bar.
  double get roundProgress {
    final remaining = phaseRemaining;
    if (remaining == null ||
        (_snapshot.phase != BattlePhase.live &&
            _snapshot.phase != BattlePhase.reconnecting)) {
      return 1;
    }
    const total = 60;
    final value = remaining.inMilliseconds / (total * 1000);
    return value.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------- commands

  /// Loads the Battle tab inbox. Safe to call again for retry.
  Future<void> loadHome() async {
    if (_disposed) {
      return;
    }
    _dispatch(const HomeLoadStarted());
    await _loadInbox();
  }

  /// Opens the request inbox page.
  Future<void> openInbox() async {
    _dispatch(const InboxOpened());
    await refreshInbox();
  }

  /// Closes the request inbox page.
  void closeInbox() {
    _dispatch(const InboxClosed());
  }

  /// Reloads the inbox without leaving the current screen.
  Future<void> refreshInbox() async {
    _dispatch(const InboxLoadStarted());
    await _loadInbox();
  }

  Future<void> _loadInbox() async {
    if (_disposed) {
      return;
    }
    if (!backend.configured) {
      _dispatch(
        const InboxLoadFailed(
          BattleFailure(
            BattleFailureKind.unconfigured,
            'The arena service is not configured in this build. Challenge links '
            'and battles need backend credentials.',
          ),
        ),
      );
      return;
    }
    try {
      final inbox = await backend.inbox();
      if (_disposed) {
        return;
      }
      if (inbox.serverNow != null) {
        _serverOffset = inbox.serverNow!.difference(clock.now());
      }
      _dispatch(InboxLoaded(inbox));
      if (inbox.activeMatchId != null) {
        await _restoreIfNeeded(inbox.activeMatchId!);
      }
      if (_snapshot.match == null) {
        _ensureInboxTimer();
      }
    } on BattleFailure catch (failure) {
      _dispatch(InboxLoadFailed(failure));
    } catch (_) {
      _dispatch(
        const InboxLoadFailed(
          BattleFailure(
            BattleFailureKind.serverFailure,
            'The arena service could not be reached.',
          ),
        ),
      );
    }
  }

  /// Stores a resolved link/code and asks for sign-in only when needed.
  /// Returning users resume the same challenge after sign-in.
  Future<void> beginChallenge(ChallengeContext challenge) async {
    _dispatch(ChallengePending(challenge));
    if (_snapshot.viewer != null) {
      await acceptPendingChallenge();
    }
  }

  /// Accepts the pending challenge; the server creates the match.
  Future<void> acceptPendingChallenge() async {
    if (_requiresUpdate) return;
    final challenge = _snapshot.pendingChallenge;
    if (challenge == null || _snapshot.viewer == null || _accepting) {
      return;
    }
    _accepting = true;
    _dispatch(const ChallengeAcceptStarted());
    try {
      final match = await backend.acceptLink(challenge.token);
      if (_disposed) {
        return;
      }
      _notifyRequestActivity();
      _dispatch(MatchCreated(match, BattleMatchOrigin.challengeLink));
    } on BattleFailure catch (failure) {
      _dispatch(ChallengeAcceptFailed(failure));
    } catch (_) {
      _dispatch(
        const ChallengeAcceptFailed(
          BattleFailure(
            BattleFailureKind.serverFailure,
            'The arena service could not be reached. The challenge is kept.',
          ),
        ),
      );
    } finally {
      _accepting = false;
    }
  }

  /// Accepts an inbox request; creates a match but never starts unattended.
  Future<void> acceptRequest(String requestId) async {
    if (_requiresUpdate) return;
    if (_accepting) {
      return;
    }
    _accepting = true;
    _dispatch(const ChallengeAcceptStarted());
    try {
      final match = await backend.acceptRequest(requestId);
      if (_disposed) {
        return;
      }
      _dispatch(MatchCreated(match, BattleMatchOrigin.request));
      _dispatch(RequestResolved(requestId, BattleRequestKind.pending));
    } on BattleFailure catch (failure) {
      _dispatch(ChallengeAcceptFailed(failure));
    } catch (_) {
      _dispatch(
        const ChallengeAcceptFailed(
          BattleFailure(
            BattleFailureKind.serverFailure,
            'The arena service could not be reached. The request is still in '
            'your inbox.',
          ),
        ),
      );
    } finally {
      _accepting = false;
    }
  }

  /// Declines an inbox request.
  Future<void> declineRequest(String requestId) async {
    try {
      await backend.respondToRequest(requestId, BattleRequestResponse.decline);
      _dispatch(RequestResolved(requestId, BattleRequestKind.cancelled));
    } on BattleFailure catch (failure) {
      _dispatch(NoticeRaised(BattleNoticeKind.warning, failure.message));
    }
  }

  /// Sends a live challenge to a code or token.
  Future<void> sendChallenge(String target) async {
    try {
      await backend.sendChallenge(target);
      _notifyRequestActivity();
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.info,
          'Live challenge sent. It expires after 24 hours; nothing is replayed.',
        ),
      );
      await refreshInbox();
    } on BattleFailure catch (failure) {
      _dispatch(NoticeRaised(BattleNoticeKind.danger, failure.message));
    }
  }

  Future<void> requestRematch() async {
    final receipt = _snapshot.receipt;
    final viewerId = _snapshot.viewerId;
    if (_disposed ||
        _rematching ||
        receipt == null ||
        viewerId == null ||
        _snapshot.phase != BattlePhase.result ||
        _snapshot.previewFixtures) {
      return;
    }
    _rematching = true;
    notifyListeners();
    try {
      final request = await backend.requestRematch(receipt.matchId);
      if (_disposed ||
          _snapshot.viewerId != viewerId ||
          _snapshot.receipt?.id != receipt.id) {
        return;
      }
      exitToHome();
      _dispatch(InboxLoaded(BattleInbox(requests: [request])));
      _notifyRequestActivity();
      await refreshInbox();
    } on BattleFailure catch (failure) {
      _dispatch(NoticeRaised(BattleNoticeKind.warning, failure.message));
    } catch (_) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.warning,
          'Could not request another battle. Try again.',
        ),
      );
    } finally {
      _rematching = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await backend.respondToRequest(requestId, BattleRequestResponse.cancel);
      await refreshInbox();
    } on BattleFailure catch (failure) {
      _dispatch(NoticeRaised(BattleNoticeKind.warning, failure.message));
    }
  }

  /// Resolves and sends a live challenge from the Join with code fallback.
  /// Delegates to task 05's challenge entry flow when one is attached.
  Future<void> joinWithCode(String code) async {
    if (_requiresUpdate) return;
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.warning,
          'Enter the short code from the challenge link.',
        ),
      );
      return;
    }
    final delegate = _entryDelegate;
    if (delegate != null) {
      final handled = await delegate.openCode(trimmed);
      if (!handled) {
        _dispatch(
          const NoticeRaised(
            BattleNoticeKind.warning,
            'That does not look like a challenge code or link.',
          ),
        );
      }
      return;
    }
    await sendChallenge(trimmed);
  }

  /// Attaches task 05's challenge entry flow for `Join with code`.
  void attachEntryDelegate(BattleChallengeEntryDelegate? delegate) {
    _entryDelegate = delegate;
  }

  VoidCallback? _requestActivityListener;

  /// Registers a listener invoked once this device sends a challenge request
  /// (in-app send or mutual link accept). Task `08` uses it to offer the
  /// in-context notification prompt; it never changes the request itself.
  void attachRequestActivityListener(VoidCallback? listener) {
    _requestActivityListener = listener;
  }

  void _notifyRequestActivity() {
    try {
      _requestActivityListener?.call();
    } catch (_) {
      // A notification listener must never break the challenge flow.
    }
  }

  /// Enters a match the server already created (link acceptance, task 05's
  /// `ChallengeEntryMatchReady`). The server owns the match state.
  Future<void> attachMatch(
    String matchId, {
    BattleMatchOrigin origin = BattleMatchOrigin.challengeLink,
  }) async {
    if (_requiresUpdate) return;
    if (_disposed || matchId.isEmpty) {
      return;
    }
    _dispatch(const ChallengeAcceptStarted());
    try {
      final match = await backend.matchState(matchId);
      if (_disposed) {
        return;
      }
      _dispatch(MatchCreated(match, origin));
    } on BattleFailure catch (failure) {
      _dispatch(ChallengeAcceptFailed(failure));
    } catch (_) {
      _dispatch(
        const ChallengeAcceptFailed(
          BattleFailure(
            BattleFailureKind.serverFailure,
            'The match could not be opened. Try again from Battle.',
          ),
        ),
      );
    }
  }

  /// Starts (or restarts) ranked search. A queue seat is created.
  ///
  /// Guards keep the contract "one queue seat and no overlapping battles":
  /// a second tap while the join is in flight is ignored and a search cannot
  /// start while a match is active.
  Future<void> startRankedSearch() async {
    if (_requiresUpdate) return;
    if (_disposed) {
      return;
    }
    if (_snapshot.previewFixtures) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.info,
          'Preview fixtures cannot start a ranked search.',
        ),
      );
      return;
    }
    if (!rankedMatchmakingEnabled) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.info,
          'Ranked matchmaking is not available in this build. '
          'Challenge a friend instead.',
        ),
      );
      return;
    }
    if (_snapshot.viewer == null) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.warning,
          'Sign in to search for a ranked opponent.',
        ),
      );
      return;
    }
    if (_snapshot.match != null || _snapshot.isMatchActive) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.warning,
          'Finish the current battle before searching for a new opponent.',
        ),
      );
      return;
    }
    if (_queueJoining || _queueActive || _paused) {
      return;
    }
    _queueJoining = true;
    _queueAnchorLocal = null;
    _queueAnchorElapsed = Duration.zero;
    _dispatch(const QueueJoinStarted());
    _track(MatchmakingAnalyticsEvent.searchStarted, const <String, Object?>{
      'mode': 'ranked',
    });
    _ensureTickTimer();
    _lastQueuePollLocal = clock.now();
    try {
      final queue = await backend.queueJoin();
      if (_disposed || !_queueActive) {
        return;
      }
      _handleQueueUpdate(queue);
    } on BattleFailure catch (failure) {
      _dispatch(QueueSearchFailed(failure));
    } catch (_) {
      _dispatch(
        const QueueSearchFailed(
          BattleFailure(
            BattleFailureKind.serverFailure,
            'The ranked queue could not be reached.',
          ),
        ),
      );
    } finally {
      _queueJoining = false;
    }
  }

  /// Stops ranked search and cancels the queue seat. Idempotent: a second
  /// call after the seat is gone does nothing and never creates anything.
  Future<void> stopRankedSearch() async {
    if (!_queueActive) {
      return;
    }
    _track(MatchmakingAnalyticsEvent.searchCancelled, const <String, Object?>{
      'reason': 'manual',
    });
    _dispatch(
      const QueueCancelled('Search stopped. The queue seat was cancelled.'),
    );
    await _leaveQueue();
  }

  /// Challenges a friend; cancels any queue seat first.
  Future<void> challengeFriend({
    ArenaExercise? exercise,
    ArenaMatchMode mode = ArenaMatchMode.casual,
    ResultReceipt? receipt,
  }) async {
    if (_queueActive) {
      _track(MatchmakingAnalyticsEvent.searchCancelled, const <String, Object?>{
        'reason': 'friend_challenge',
      });
      _track(
        MatchmakingAnalyticsEvent.friendAlternative,
        const <String, Object?>{'action': 'switched'},
      );
      _dispatch(
        const QueueCancelled(
          'The queue seat was cancelled when you switched to a friend '
          'challenge.',
        ),
      );
      await _leaveQueue();
    }
    try {
      final message = await _sharer.shareChallenge(
        BattleChallengeInvite(exercise: exercise, mode: mode, receipt: receipt),
      );
      if (message != null) {
        _dispatch(NoticeRaised(BattleNoticeKind.info, message));
      }
    } catch (_) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.warning,
          'The challenge share surface could not be opened.',
        ),
      );
    }
  }

  /// Arms the single unscored practice rep on the camera.
  Future<void> takePracticeRep() async {
    final snapshot = _snapshot;
    if (snapshot.phase != BattlePhase.preparing ||
        snapshot.practice != PracticeState.notStarted) {
      return;
    }
    _dispatch(const PracticeArmed());
    feedback.tap();
    try {
      await camera.startPractice();
    } catch (_) {
      _dispatch(
        const TrackingChanged(
          BattleCameraStatus.unavailable,
          message:
              'Camera counting is not available. No manual scoring '
              'exists.',
        ),
      );
    }
  }

  /// Submits the ready gate. Both players must be ready before the server
  /// starts the countdown.
  Future<void> submitReady() async {
    final snapshot = _snapshot;
    if (snapshot.previewFixtures) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.info,
          'Preview fixtures cannot report a competitive result.',
        ),
      );
      return;
    }
    if (!snapshot.canSubmitReady) {
      return;
    }
    final matchId = snapshot.match!.id;
    feedback.tap();
    try {
      final match = await backend.ready(
        matchId,
        tracking: _cameraTracking,
        practiceComplete: true,
      );
      if (_disposed) {
        return;
      }
      _dispatch(ReadySubmitted(match));
      _contactRestored();
    } on BattleFailure catch (failure) {
      if (failure.kind == BattleFailureKind.updateRequired) {
        _stopForUpdate();
      } else {
        _dispatch(ReadyFailed(failure));
      }
    } catch (_) {
      _dispatch(
        const ReadyFailed(
          BattleFailure(
            BattleFailureKind.serverFailure,
            'Readiness could not be sent. Try again.',
          ),
        ),
      );
    }
  }

  /// Taps the ready gate; explains the blocked reason instead of failing
  /// silently.
  Future<void> requestReady() async {
    if (_snapshot.previewFixtures) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.info,
          'Preview fixtures cannot report a competitive result.',
        ),
      );
      return;
    }
    if (!_snapshot.canSubmitReady) {
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.info,
          'Take the practice rep first. It is unscored and required once.',
        ),
      );
      return;
    }
    await submitReady();
  }

  /// Re-arms the camera after tracking loss; the shared clock keeps running.
  Future<void> retryTracking() async {
    final match = _snapshot.match;
    if (match == null) {
      return;
    }
    _dispatch(
      const NoticeRaised(
        BattleNoticeKind.info,
        'Re-scanning for tracking. The shared clock keeps running.',
      ),
    );
    await camera.prepare(match.exercise);
    if (_snapshot.phase == BattlePhase.live ||
        _snapshot.phase == BattlePhase.reconnecting) {
      await camera.startMatch();
    }
  }

  /// Confirms leaving; the server owns the final outcome.
  Future<void> confirmLeave(BattleExitReason reason) async {
    final match = _snapshot.match;
    _dispatch(LeaveConfirmed(reason));
    unawaited(camera.stop());
    if (match == null) {
      _dispatch(LeaveCompleted(reason, null));
      return;
    }
    try {
      final replied = await backend.leave(match.id);
      if (_disposed) {
        return;
      }
      _dispatch(LeaveCompleted(reason, replied));
    } on BattleFailure catch (failure) {
      _dispatch(LeaveCompleted(reason, null));
      _dispatch(NoticeRaised(BattleNoticeKind.warning, failure.message));
    }
  }

  /// Retries the connection immediately and reports the attempt honestly.
  Future<void> retryConnection() async {
    _dispatch(
      const NoticeRaised(
        BattleNoticeKind.info,
        'Retrying the arena service. No local result is assumed.',
      ),
    );
    await _networkTick();
  }

  /// Restores an active match id persisted across lifecycle/process death.
  Future<void> restoreSession() async {
    final matchId = await sessionStore.readActiveMatchId();
    if (matchId == null || _disposed) {
      return;
    }
    await _restoreIfNeeded(matchId);
    _ensureTickTimer();
  }

  /// Pauses polling and the camera (app went to background).
  ///
  /// An open queue seat is released with the same idempotent leave path used
  /// by Back and friend-challenge switching: the UI never keeps searching
  /// while the app cannot answer, and a failed leave is harmless because the
  /// seat expires server-side after 60 seconds.
  void pause() {
    if (_paused || _disposed) {
      return;
    }
    if (_queueActive) {
      _track(MatchmakingAnalyticsEvent.searchCancelled, const <String, Object?>{
        'reason': 'app_paused',
      });
      _dispatch(
        const QueueCancelled(
          'Search stopped while the app was in the background. The queue seat '
          'was cancelled.',
        ),
      );
      unawaited(_leaveQueue());
      _lastQueuePollLocal = null;
    }
    _paused = true;
    _cameraSuspension = camera.suspend();
    _cancelTickTimer();
  }

  /// Resumes polling after backgrounding and re-reads the authoritative
  /// match state before showing anything.
  Future<void> resume() async {
    if (!_paused || _disposed) {
      return;
    }
    _paused = false;
    if (_snapshot.match != null) {
      _ensureTickTimer();
      await _networkTick();
      await _cameraSuspension;
      if (!_requiresUpdate && _snapshot.isMatchActive) await camera.resume();
      if (!_requiresUpdate &&
          (_snapshot.phase == BattlePhase.live ||
              _snapshot.phase == BattlePhase.reconnecting)) {
        await camera.startMatch();
      }
    } else if (_snapshot.phase == BattlePhase.home) {
      _ensureInboxTimer();
      await _pollInbox();
    }
  }

  /// Clears the local flow and returns to Battle.
  void exitToHome() {
    _dispatch(const ExitToHome());
    _persistMatchId(null);
    unawaited(camera.stop());
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observerAttached) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {
        // Binding already gone.
      }
      _observerAttached = false;
    }
    _viewer.removeListener(_handleViewerChanged);
    unawaited(_cameraUpdates?.cancel());
    unawaited(_cameraReps?.cancel());
    _tickTimer?.cancel();
    _inboxTimer?.cancel();
    unawaited(camera.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_observerAttached) {
      return;
    }
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        pause();
      case AppLifecycleState.resumed:
        unawaited(resume());
      case AppLifecycleState.detached:
        break;
    }
  }

  // ------------------------------------------------------------- internals

  void _dispatch(BattleEvent event) {
    if (_disposed) {
      return;
    }
    // Ignore late network/camera replies after an unsupported-build rejection.
    // A new process revalidates match_state with the current version before
    // restoring a camera; there is no persistent latch that can block an update.
    if (_requiresUpdate &&
        event is! BattleUpdateRequired &&
        event is! ExitToHome &&
        event is! ViewerChanged) {
      return;
    }
    final previousPhase = _snapshot.phase;
    final previousMatchId = _snapshot.match?.id;
    final previousServerNow = _snapshot.match?.serverNow;
    final next = BattleStateMachine.apply(_snapshot, event);
    if (identical(next, _snapshot)) {
      return;
    }
    _snapshot = next;
    final nextServerNow = next.match?.serverNow;
    if (nextServerNow != null && nextServerNow != previousServerNow) {
      _serverOffset = nextServerNow.difference(clock.now());
    }
    _afterTransition(previousPhase, previousMatchId);
    notifyListeners();
  }

  void _afterTransition(BattlePhase previousPhase, String? previousMatchId) {
    final snapshot = _snapshot;

    final matchId = snapshot.match?.id;
    if (matchId != previousMatchId) {
      _resetMatchCues();
      if (matchId != null) {
        _cameraStartedMatchId = null;
        _persistMatchId(matchId);
        unawaited(camera.prepare(snapshot.match!.exercise));
        _cancelInboxTimer();
      }
    }

    final phase = snapshot.phase;
    final roundPhase =
        phase == BattlePhase.live || phase == BattlePhase.reconnecting;
    if (roundPhase && matchId != null && _cameraStartedMatchId != matchId) {
      _cameraStartedMatchId = matchId;
      unawaited(camera.startMatch());
    }
    if (phase == BattlePhase.live && previousPhase != BattlePhase.live) {
      feedback.roundStarted();
      _tenAnnounced = false;
      _threeAnnounced = false;
    }
    if ((phase == BattlePhase.result || phase == BattlePhase.noResult) &&
        previousPhase != phase) {
      feedback.resultConfirmed();
      unawaited(camera.stop());
      _persistMatchId(null);
    }
    if (phase == BattlePhase.exited && previousPhase != BattlePhase.exited) {
      unawaited(camera.stop());
      _persistMatchId(null);
    }

    final searching =
        snapshot.queuePhase == BattleQueuePhase.searching ||
        snapshot.queuePhase == BattleQueuePhase.extended;
    if (phase == BattlePhase.result ||
        phase == BattlePhase.noResult ||
        phase == BattlePhase.exited) {
      // Terminal states are server-confirmed and immutable; stop all clocks.
      _cancelTickTimer();
      _cancelInboxTimer();
    } else if (snapshot.match != null || searching) {
      _ensureTickTimer();
    } else if (phase == BattlePhase.home) {
      _cancelTickTimer();
      _ensureInboxTimer();
    } else {
      _cancelTickTimer();
    }
  }

  void _resetMatchCues() {
    _pendingReps.clear();
    _tenAnnounced = false;
    _threeAnnounced = false;
    _lastCountdownSecond = null;
  }

  void _persistMatchId(String? matchId) {
    if (_storedMatchId == matchId) {
      return;
    }
    _storedMatchId = matchId;
    unawaited(sessionStore.writeActiveMatchId(matchId));
  }

  void _handleViewerChanged() {
    final viewer = _viewer.value;
    final awaitedSignIn = _snapshot.challengeAwaitingSignIn;
    _dispatch(ViewerChanged(viewer));
    if (viewer != null && awaitedSignIn && _snapshot.pendingChallenge != null) {
      unawaited(acceptPendingChallenge());
    }
    if (viewer == null) {
      _resetMatchCues();
    }
  }

  void _handleCameraUpdate(BattleCameraUpdate update) {
    if (_disposed) {
      return;
    }
    _dispatch(TrackingChanged(update.status, message: update.message));
    if (update.status == BattleCameraStatus.trackingLost) {
      feedback.trackingLost();
    } else if (update.status == BattleCameraStatus.tracking) {
      feedback.trackingRestored();
    }
    if (update.status == BattleCameraStatus.permissionDenied) {
      feedback.warning();
    }
  }

  bool get _cameraTracking =>
      _snapshot.cameraStatus == BattleCameraStatus.tracking;

  void _handleRep(BattleRepEvent rep) {
    if (_disposed) {
      return;
    }
    final snapshot = _snapshot;
    if (rep.practice ||
        (snapshot.phase == BattlePhase.preparing &&
            snapshot.practice == PracticeState.counting)) {
      if (snapshot.practice == PracticeState.counting ||
          snapshot.practice == PracticeState.notStarted) {
        _dispatch(const PracticeRepCounted());
        feedback.tap();
      }
      return;
    }
    final match = snapshot.match;
    if (match == null) {
      return;
    }
    if (snapshot.phase != BattlePhase.live &&
        snapshot.phase != BattlePhase.reconnecting) {
      return;
    }
    if (snapshot.connection == BattleConnection.selfTrackingLost) {
      return;
    }
    if (!rep.competitive || rep.eventId.isEmpty || rep.sequence <= 0) {
      // Labelled non-competitive or malformed counters never score a match.
      _dispatch(
        const NoticeRaised(
          BattleNoticeKind.warning,
          'A non-competitive counter event was ignored. Only camera-counted '
          'competitive reps can score.',
        ),
      );
      return;
    }
    _pendingReps.add(
      PendingRepEvent(
        eventId: rep.eventId,
        sequence: rep.sequence,
        observedAt: rep.observedAt ?? clock.now(),
        counterVersion: rep.counterVersion,
      ),
    );
    unawaited(_flushReps());
  }

  Future<void> _flushReps() async {
    if (_snapshot.previewFixtures) {
      // Fixture mode must never send a competitive rep, even when an injected
      // backend would accept it.
      _pendingReps.clear();
      return;
    }
    if (_flushingReps || _disposed) {
      return;
    }
    _flushingReps = true;
    try {
      while (_pendingReps.isNotEmpty && !_disposed) {
        final matchId = _snapshot.match?.id;
        if (matchId == null) {
          _pendingReps.clear();
          break;
        }
        final rep = _pendingReps.first;
        try {
          final match = await backend.reportRep(matchId, rep);
          if (_disposed) {
            return;
          }
          _pendingReps.removeAt(0);
          _applyServerMatch(match);
          _contactRestored();
        } on BattleFailure catch (failure) {
          if (failure.kind == BattleFailureKind.conflict ||
              failure.kind == BattleFailureKind.notFound) {
            _pendingReps.removeAt(0);
            _dispatch(
              const NoticeRaised(
                BattleNoticeKind.warning,
                'The server rejected a rep after the round changed. Only '
                'server-confirmed reps count.',
              ),
            );
            continue;
          }
          _contactLost(failure);
          break;
        } catch (_) {
          break;
        }
      }
    } finally {
      _flushingReps = false;
    }
  }

  void _applyServerMatch(BattleMatch match) {
    if (match.serverNow != null) {
      _serverOffset = match.serverNow!.difference(clock.now());
    }
    _dispatch(MatchUpdated(match));
  }

  void _contactLost(BattleFailure failure) {
    if (failure.kind == BattleFailureKind.updateRequired) {
      _stopForUpdate();
      return;
    }
    final firstFailure = _snapshot.consecutiveFailures == 0;
    _dispatch(ServerContactLost(failure, clock.now()));
    if (firstFailure &&
        (_snapshot.phase == BattlePhase.live ||
            _snapshot.phase == BattlePhase.reconnecting)) {
      feedback.warning();
    }
  }

  void _stopForUpdate() {
    if (_requiresUpdate || _disposed) return;
    _requiresUpdate = true;
    _resetMatchCues();
    _persistMatchId(null);
    _cancelTickTimer();
    _cancelInboxTimer();
    _dispatch(const BattleUpdateRequired());
    unawaited(camera.stop());
  }

  void _contactRestored() {
    if (_snapshot.consecutiveFailures > 0) {
      _dispatch(const ServerContactRestored());
    }
    if (_pendingReps.isNotEmpty) {
      unawaited(_flushReps());
    }
  }

  void _handleQueueUpdate(BattleQueueState queue, {Duration? elapsed}) {
    if (queue.joinedAt != null) {
      if (queue.serverNow != null) {
        // The window is monotonic: a reply from an older/odd server clock can
        // never rewind the local 60-second countdown and extend the search.
        final serverElapsed = queue.serverNow!.difference(queue.joinedAt!);
        if (_queueAnchorLocal == null || serverElapsed >= _queueElapsed()) {
          _queueAnchorLocal = clock.now();
          _queueAnchorElapsed = serverElapsed;
        }
      } else if (_queueAnchorLocal == null) {
        // `docs/API.md` queue replies carry no server clock, so anchor once
        // on the local clock and let the visible 15 s/60 s window advance.
        // The server still owns the seat expiry and the monotonic stop.
        _queueAnchorLocal = clock.now();
        _queueAnchorElapsed = Duration.zero;
      }
    }
    if (queue.matchId == null && !queue.seatActive) {
      _track(MatchmakingAnalyticsEvent.searchCancelled, const <String, Object?>{
        'reason': 'seat_closed',
      });
      _dispatch(const QueueSeatClosed());
      return;
    }
    _dispatch(QueueUpdated(queue, elapsed: elapsed ?? _queueElapsed()));
    final matchId = queue.matchId;
    if (matchId != null) {
      _track(MatchmakingAnalyticsEvent.matchFound, const <String, Object?>{
        'mode': 'ranked',
      });
      unawaited(_enterQueuedMatch(matchId));
    }
  }

  Future<void> _enterQueuedMatch(String matchId) async {
    try {
      final match = await backend.matchState(matchId);
      if (_disposed || _snapshot.queuePhase != BattleQueuePhase.matched) {
        // The player stopped the search before the match was fetched.
        return;
      }
      _dispatch(MatchCreated(match, BattleMatchOrigin.rankedQueue));
    } on BattleFailure catch (failure) {
      _dispatch(MatchUnavailable(failure));
    }
  }

  Duration _queueElapsed() {
    final anchor = _queueAnchorLocal;
    if (anchor == null) {
      return _queueAnchorElapsed;
    }
    return _queueAnchorElapsed + clock.now().difference(anchor);
  }

  Future<void> _leaveQueue() async {
    try {
      await backend.queueLeave();
    } catch (_) {
      // Idempotent by contract: the seat expires on its own after 60
      // seconds server-side, so a failed leave must never surface or block.
    }
  }

  Future<void> _restoreIfNeeded(String matchId) async {
    if (_requiresUpdate) return;
    if (_restoreAttempted == matchId) {
      return;
    }
    _restoreAttempted = matchId;
    try {
      final match = await backend.matchState(matchId);
      if (_disposed) {
        return;
      }
      _applyServerMatch(match);
      if (match.status == ArenaMatchStatus.live ||
          match.status == ArenaMatchStatus.countdown) {
        await camera.prepare(match.exercise);
        if (match.status == ArenaMatchStatus.live) {
          await camera.startMatch();
        }
      }
    } on BattleFailure catch (failure) {
      if (failure.kind == BattleFailureKind.updateRequired) {
        _stopForUpdate();
      } else {
        _dispatch(MatchUnavailable(failure));
      }
      await sessionStore.writeActiveMatchId(null);
    }
  }

  // -------------------------------------------------------------- ticking --

  void _ensureTickTimer() {
    if (_disposed || _paused || _requiresUpdate) {
      return;
    }
    _cancelInboxTimer();
    _tickTimer ??= clock.periodic(BattleTimings.heartbeat, _tick);
  }

  void _cancelTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _ensureInboxTimer() {
    if (_disposed || _paused || _requiresUpdate) {
      return;
    }
    _inboxTimer ??= clock.periodic(BattleTimings.inboxPoll, () {
      unawaited(_pollInbox());
    });
  }

  void _cancelInboxTimer() {
    _inboxTimer?.cancel();
    _inboxTimer = null;
  }

  void _tick() {
    if (_disposed || _paused) {
      return;
    }
    _dispatch(const BattleTick());
    _handleQueueSecond();
    _handleQueuePoll();
    _handleReconnectSecond();
    _handleCues();

    final snapshot = _snapshot;
    if (snapshot.match != null &&
        snapshot.phase != BattlePhase.result &&
        snapshot.phase != BattlePhase.noResult &&
        snapshot.phase != BattlePhase.exited) {
      unawaited(_networkTick());
    }
  }

  /// True while an authoritative queue seat is open.
  bool get _queueActive =>
      _snapshot.queuePhase == BattleQueuePhase.searching ||
      _snapshot.queuePhase == BattleQueuePhase.extended;

  void _handleQueueSecond() {
    final snapshot = _snapshot;
    if (snapshot.queuePhase != BattleQueuePhase.searching &&
        snapshot.queuePhase != BattleQueuePhase.extended) {
      return;
    }
    final elapsed = _queueElapsed();
    _dispatch(QueueElapsed(elapsed));
    if (elapsed >= BattleTimings.queueAlternativeAfter &&
        !_snapshot.queueExtended) {
      _track(
        MatchmakingAnalyticsEvent.friendAlternative,
        const <String, Object?>{'action': 'offered'},
      );
      _dispatch(const QueueAlternativeOffered());
      feedback.tap();
    }
    if (elapsed >= BattleTimings.queueLimit) {
      _track(MatchmakingAnalyticsEvent.searchTimedOut, const <String, Object?>{
        'elapsed_seconds': 60,
      });
      _dispatch(const QueueTimedOut());
      if (_snapshot.queueOffline) {
        // The local window ended while the arena was unreachable: say so
        // instead of implying that no ranked player was waiting.
        _dispatch(
          const NoticeRaised(
            BattleNoticeKind.warning,
            'The search ended after 60 seconds without a confirmed match. You '
            'were offline for part of it; start a new search to check again.',
          ),
        );
      }
      unawaited(_leaveQueue());
    }
  }

  /// Polls the authoritative queue at the documented cadence. A network
  /// failure keeps the seat and the local window; a business answer ends it
  /// honestly.
  void _handleQueuePoll() {
    if (!_queueActive || _paused || _disposed || _queuePolling) {
      return;
    }
    final now = clock.now();
    final last = _lastQueuePollLocal;
    if (last != null && now.difference(last) < BattleTimings.queuePoll) {
      return;
    }
    _lastQueuePollLocal = now;
    unawaited(_pollQueue());
  }

  Future<void> _pollQueue() async {
    if (_queuePolling || _disposed) {
      return;
    }
    _queuePolling = true;
    try {
      final queue = await backend.queuePoll();
      if (_disposed || !_queueActive) {
        return;
      }
      _dispatch(const QueueContactRestored());
      _handleQueueUpdate(queue, elapsed: _queueElapsed());
    } on BattleFailure catch (failure) {
      if (_disposed || !_queueActive) {
        return;
      }
      if (failure.kind == BattleFailureKind.offline ||
          failure.kind == BattleFailureKind.serverFailure) {
        _dispatch(const QueueContactLost());
      } else if (failure.kind == BattleFailureKind.conflict ||
          failure.kind == BattleFailureKind.notFound) {
        _track(
          MatchmakingAnalyticsEvent.searchCancelled,
          const <String, Object?>{'reason': 'seat_closed'},
        );
        _dispatch(const QueueSeatClosed());
      } else {
        _dispatch(QueueSearchFailed(failure));
      }
    } catch (_) {
      if (!_disposed && _queueActive) {
        _dispatch(const QueueContactLost());
      }
    } finally {
      _queuePolling = false;
    }
  }

  void _track(String event, [Map<String, Object?> properties = const {}]) {
    unawaited(_analytics.track(event, properties));
  }

  void _handleReconnectSecond() {
    final snapshot = _snapshot;
    if (snapshot.phase != BattlePhase.reconnecting ||
        snapshot.connection != BattleConnection.serviceOutage ||
        snapshot.reconnectExpired) {
      return;
    }
    final startedAt = snapshot.reconnectStartedAt;
    if (startedAt != null &&
        clock.now().difference(startedAt) >= BattleTimings.recoveryWindow) {
      _dispatch(const ReconnectWindowExpired());
      feedback.warning();
    }
  }

  void _handleCues() {
    final snapshot = _snapshot;
    if (snapshot.phase == BattlePhase.countdown) {
      final seconds = countdownSecondsRemaining;
      if (seconds != null && seconds > 0 && seconds != _lastCountdownSecond) {
        _lastCountdownSecond = seconds;
        feedback.countdownTick(seconds);
        feedback.announce('$seconds');
      }
      if (seconds == 0 &&
          snapshot.match?.status == ArenaMatchStatus.countdown) {
        _dispatch(const CountdownElapsed());
      }
    } else {
      _lastCountdownSecond = null;
    }
    if (snapshot.phase == BattlePhase.live ||
        snapshot.phase == BattlePhase.reconnecting) {
      final seconds = liveSecondsRemaining;
      if (seconds != null && seconds <= 10 && !_tenAnnounced) {
        _tenAnnounced = true;
        feedback.finalTenSeconds();
        feedback.announce('10 seconds left');
      }
      if (seconds != null && seconds <= 3 && !_threeAnnounced) {
        _threeAnnounced = true;
        feedback.finalThreeSeconds();
        feedback.announce('3 seconds left');
      }
    }
  }

  Future<void> _networkTick() async {
    final snapshot = _snapshot;
    final match = snapshot.match;
    if (match == null) {
      return;
    }
    try {
      final BattleMatch updated;
      if (snapshot.phase == BattlePhase.live ||
          snapshot.phase == BattlePhase.reconnecting) {
        updated = await backend.heartbeat(
          match.id,
          tracking:
              _cameraTracking &&
              snapshot.connection != BattleConnection.selfTrackingLost,
        );
      } else {
        updated = await backend.matchState(match.id);
      }
      if (_disposed) {
        return;
      }
      _applyServerMatch(updated);
      _contactRestored();
    } on BattleFailure catch (failure) {
      _contactLost(failure);
    } catch (_) {
      _contactLost(
        const BattleFailure(
          BattleFailureKind.serverFailure,
          'The arena service answered unexpectedly.',
        ),
      );
    }
  }

  Future<void> _pollInbox() async {
    if (_disposed || _paused || !backend.configured) {
      return;
    }
    final snapshot = _snapshot;
    if (snapshot.isMatchActive ||
        snapshot.phase == BattlePhase.resolving ||
        snapshot.queuePhase == BattleQueuePhase.searching ||
        snapshot.queuePhase == BattleQueuePhase.extended) {
      return;
    }
    try {
      final inbox = await backend.inbox();
      if (_disposed) {
        return;
      }
      _dispatch(InboxLoaded(inbox));
      if (inbox.activeMatchId != null && _snapshot.match == null) {
        await _restoreIfNeeded(inbox.activeMatchId!);
      }
    } on BattleFailure catch (_) {
      // Poll failures stay silent; explicit loads show the offline state.
    }
  }
}
