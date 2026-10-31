/// Challenge entry controller.
///
/// One controller drives every route into a challenge: cold and warm App
/// Links, the custom-scheme fallback, typed codes and Play Install Referrer
/// recovery. It is the only place that talks to the API, persistence and
/// analytics, so the widgets stay declarative and testable.
///
/// Rules encoded here:
/// - opening/resolving a link is read-only;
/// - a request is sent only by an explicit accept tap;
/// - pending context survives auth redirect, restart and install recovery;
/// - it is cleared only on accept-into-match, decline/cancel or expiry;
/// - the UI never invents a match or an async replay promise.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/arena_config.dart';
import '../domain/arena_types.dart';
import 'arena_challenge_api.dart';
import 'challenge_analytics.dart';
import 'challenge_auth.dart';
import 'challenge_deep_links.dart';
import 'challenge_link.dart';
import 'challenge_models.dart';
import 'challenge_persistence.dart';
import 'install_referrer.dart';

/// States the challenge host can render.
sealed class ChallengeEntryState {
  const ChallengeEntryState();
}

/// No active challenge: the normal shell is in charge.
class ChallengeEntryIdle extends ChallengeEntryState {
  const ChallengeEntryIdle();
}

/// A link was received; identity is resolving read-only.
class ChallengeEntryResolving extends ChallengeEntryState {
  const ChallengeEntryResolving(this.token);

  final String token;
}

/// The challenger is known and the viewer can act.
class ChallengeEntryReview extends ChallengeEntryState {
  const ChallengeEntryReview({
    required this.resolution,
    required this.signedIn,
    this.sending = false,
    this.errorMessage,
    this.restored = false,
  });

  final ChallengeResolution resolution;
  final bool signedIn;

  /// True while the request send is in flight.
  final bool sending;

  final String? errorMessage;

  /// True when this state came back from persisted context.
  final bool restored;

  ChallengeEntryReview copyWith({
    ChallengeResolution? resolution,
    bool? signedIn,
    bool? sending,
    String? errorMessage,
    bool clearError = false,
    bool? restored,
  }) {
    return ChallengeEntryReview(
      resolution: resolution ?? this.resolution,
      signedIn: signedIn ?? this.signedIn,
      sending: sending ?? this.sending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      restored: restored ?? this.restored,
    );
  }
}

/// Sign-in is required before the request can be sent.
class ChallengeEntrySignIn extends ChallengeEntryState {
  const ChallengeEntrySignIn({
    required this.resolution,
    this.signingIn = false,
    this.errorMessage,
  });

  final ChallengeResolution resolution;
  final bool signingIn;
  final String? errorMessage;

  ChallengeEntrySignIn copyWith({
    ChallengeResolution? resolution,
    bool? signingIn,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChallengeEntrySignIn(
      resolution: resolution ?? this.resolution,
      signingIn: signingIn ?? this.signingIn,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// This device sent its request; the challenger must accept it.
class ChallengeEntryWaiting extends ChallengeEntryState {
  const ChallengeEntryWaiting({
    required this.token,
    required this.requestId,
    this.sender,
    this.expiresAt,
    this.restored = false,
    this.checking = false,
    this.errorMessage,
  });

  final String token;
  final String requestId;
  final ArenaProfile? sender;
  final DateTime? expiresAt;

  /// True when the waiting state was restored from persistence.
  final bool restored;

  final bool checking;
  final String? errorMessage;

  ChallengeEntryWaiting copyWith({
    String? token,
    String? requestId,
    ArenaProfile? sender,
    DateTime? expiresAt,
    bool? restored,
    bool? checking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChallengeEntryWaiting(
      token: token ?? this.token,
      requestId: requestId ?? this.requestId,
      sender: sender ?? this.sender,
      expiresAt: expiresAt ?? this.expiresAt,
      restored: restored ?? this.restored,
      checking: checking ?? this.checking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Mutual acceptance produced a live casual match; both players still have
/// to return and confirm readiness (task `07`).
class ChallengeEntryMatchReady extends ChallengeEntryState {
  const ChallengeEntryMatchReady({required this.matchId, this.sender});

  final String matchId;
  final ArenaProfile? sender;
}

/// Terminal link states with honest copy; no replay is promised.
class ChallengeEntryUnavailable extends ChallengeEntryState {
  const ChallengeEntryUnavailable({
    required this.token,
    required this.status,
    this.message,
  });

  final String token;
  final ChallengeLinkStatus status;
  final String? message;
}

/// The installed build cannot handle links yet; offer the Play route,
/// reopen instruction and readable code.
class ChallengeEntryInstallRequired extends ChallengeEntryState {
  const ChallengeEntryInstallRequired({required this.token, this.message});

  final String token;
  final String? message;
}

/// Recoverable failure (network, malformed response).
class ChallengeEntryFailure extends ChallengeEntryState {
  const ChallengeEntryFailure({
    required this.token,
    required this.message,
    this.retryable = true,
  });

  final String token;
  final String message;
  final bool retryable;
}

/// Drives `docs/decisions/05-challenge-link-interface-decisions.md`.
class ChallengeEntryController extends ChangeNotifier {
  ChallengeEntryController({
    required this.config,
    required ArenaChallengeApi api,
    required ChallengePersistence persistence,
    required ChallengeDeepLinks deepLinks,
    required InstallReferrerSource installReferrer,
    required ChallengeAuthDelegate auth,
    required ChallengeAnalyticsSink analytics,
    DateTime Function()? now,
    this.matchPollInterval = const Duration(seconds: 3),
  }) : _api = api,
       _persistence = persistence,
       _deepLinks = deepLinks,
       _installReferrer = installReferrer,
       _auth = auth,
       _analytics = analytics,
       _now = now ?? DateTime.now;

  static const Duration requestLifetime = Duration(hours: 24);

  final ArenaConfig config;
  final ArenaChallengeApi _api;
  final ChallengePersistence _persistence;
  final ChallengeDeepLinks _deepLinks;
  final InstallReferrerSource _installReferrer;
  final ChallengeAuthDelegate _auth;
  final ChallengeAnalyticsSink _analytics;
  final DateTime Function() _now;

  /// Poll cadence while waiting for the challenger to accept. Set to
  /// [Duration.zero] to disable polling (tests drive checks explicitly).
  final Duration matchPollInterval;

  ChallengeEntryState _state = const ChallengeEntryIdle();
  ChallengeEntryState get state => _state;

  PendingChallengeState? _pending;
  PendingChallengeState? get pendingChallenge => _pending;

  ChallengeResolution? _resolution;
  ChallengeResolution? get resolution => _resolution;

  bool _started = false;
  bool _disposed = false;
  StreamSubscription<Uri>? _linkSubscription;
  Timer? _pollTimer;

  /// Begins listening for links and restores any pending context.
  /// Idempotent so tests can preconfigure the controller.
  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    _linkSubscription = _deepLinks.links.listen((uri) {
      unawaited(handleUri(uri));
    }, onError: (Object _) {});

    final pending = await _persistence.readPending();
    if (pending != null) {
      await _resumePending(pending);
      return;
    }

    final initial = await _deepLinks.initialLink();
    if (initial != null) {
      await handleUri(initial);
      return;
    }

    if (!await _persistence.isInstallReferrerHandled()) {
      final referrer = await _installReferrer.getInstallReferrer();
      final token = challengeTokenFromReferrer(referrer);
      if (token != null) {
        await _persistence.markInstallReferrerHandled();
        await _handleToken(token, source: ChallengeLinkSource.installReferrer);
      }
    }
  }

  /// Handles a cold or warm link. Foreign links are ignored.
  Future<void> handleUri(Uri uri) async {
    // Auth and challenge wrappers observe the same native app_links stream.
    // Only the configured OAuth callback belongs to the auth gateway; parsing
    // it as a short challenge code would replace the active invitation UI.
    final authRedirect = Uri.tryParse(config.authRedirectUrl.trim());
    if (authRedirect != null &&
        authRedirect.hasScheme &&
        uri.scheme.toLowerCase() == authRedirect.scheme.toLowerCase() &&
        uri.host.toLowerCase() == authRedirect.host.toLowerCase() &&
        uri.path == authRedirect.path) {
      return;
    }
    final link = ChallengeLink.tryParse(uri, expectedHost: config.linkHost);
    if (link == null) {
      if (_matchesArenaNamespace(uri)) {
        _setState(
          ChallengeEntryUnavailable(
            token: _tokenHint(uri),
            status: ChallengeLinkStatus.unavailable,
            message: 'This is not a readable Fault challenge link.',
          ),
        );
      }
      return;
    }
    await _handleToken(link.token, source: link.source);
  }

  /// Handles a typed or pasted short code / link (Join with code).
  Future<bool> openCode(String text) async {
    final link = ChallengeLink.tryParseText(
      text,
      expectedHost: config.linkHost,
    );
    if (link == null) {
      return false;
    }
    await _handleToken(link.token, source: link.source);
    return true;
  }

  /// Retries the last recoverable failure.
  Future<void> retry() async {
    final token = switch (_state) {
      ChallengeEntryFailure(:final token) => token,
      ChallengeEntryUnavailable(:final token) => token,
      ChallengeEntryInstallRequired(:final token) => token,
      _ => _pending?.token,
    };
    if (token == null) {
      return;
    }
    await _handleToken(token, source: _pending?.source);
  }

  /// Explicit accept on the landing: send one request for this device.
  Future<void> acceptChallenge() async {
    final current = _state;
    if (current is! ChallengeEntryReview || current.sending) {
      return;
    }
    _setState(current.copyWith(sending: true, clearError: true));
    try {
      final request = await _api.sendRequest(current.resolution.token);
      final base =
          _pending ?? PendingChallengeState(token: current.resolution.token);
      final pending = base.copyWith(
        sender: current.resolution.owner,
        requestId: request.id,
        requestStatus: request.status,
        matchId: request.matchId,
        expiresAt: request.expiresAt ?? _now().add(requestLifetime),
      );
      await _persistence.writePending(pending);
      _pending = pending;
      await _analytics.track(
        ChallengeAnalyticsEvent.requestSent,
        <String, Object?>{
          'source': pending.source == ChallengeLinkSource.installReferrer
              ? 'reopen'
              : 'link',
        },
      );
      if (request.matchId != null && request.matchId!.isNotEmpty) {
        await _enterMatch(request.matchId!, current.resolution.owner, 'return');
        return;
      }
      _setState(
        ChallengeEntryWaiting(
          token: current.resolution.token,
          requestId: request.id,
          sender: current.resolution.owner,
          expiresAt: pending.expiresAt,
        ),
      );
      _startPolling();
    } on ChallengeApiException catch (error) {
      if (error.isUnauthenticated) {
        _setState(
          ChallengeEntrySignIn(
            resolution: current.resolution,
            errorMessage: 'Sign in to accept this challenge.',
          ),
        );
        return;
      }
      if (error.code == 'not_configured') {
        _setState(
          ChallengeEntryFailure(
            token: current.resolution.token,
            message:
                error.message ??
                'The arena backend is not configured in this build.',
            retryable: false,
          ),
        );
        return;
      }
      if (error.code == 'request_exists') {
        final existing = await _recoverExistingRequest(current.resolution);
        if (existing) {
          return;
        }
        _setState(
          current.copyWith(
            sending: false,
            errorMessage: error.message ?? 'A request to this player is already pending. It is in their inbox.',
          ),
        );
        return;
      }
      if (error.code == 'username_required') {
        _setState(
          current.copyWith(
            sending: false,
            errorMessage:
                error.message ??
                'Choose a username before challenging a friend.',
          ),
        );
        return;
      }
      if (error.isRetryable) {
        _setState(
          current.copyWith(
            sending: false,
            errorMessage:
                error.message ?? 'The request could not be sent. Try again.',
          ),
        );
        return;
      }
      await _clearPending();
      _setState(
        ChallengeEntryUnavailable(
          token: current.resolution.token,
          status: ChallengeApiException.statusFromErrorCode(error.code),
          message: error.message,
        ),
      );
    }
  }

  /// Recovers the waiting state when the backend says a pending request for
  /// this challenger already exists (`request_exists`). Never invents an id.
  Future<bool> _recoverExistingRequest(ChallengeResolution resolution) async {
    final owner = resolution.owner;
    if (owner == null) {
      return false;
    }
    ChallengeRequest? existing;
    try {
      existing = await _api.pendingOutgoingRequestTo(owner.id);
    } on ChallengeApiException {
      return false;
    }
    if (existing == null) {
      return false;
    }
    final base = _pending ?? PendingChallengeState(token: resolution.token);
    final pending = base.copyWith(
      sender: owner,
      requestId: existing.id,
      requestStatus: existing.status,
      matchId: existing.matchId,
      expiresAt: existing.expiresAt ?? _now().add(requestLifetime),
    );
    await _persistence.writePending(pending);
    _pending = pending;
    _setState(
      ChallengeEntryWaiting(
        token: resolution.token,
        requestId: existing.id,
        sender: owner,
        expiresAt: pending.expiresAt,
        restored: true,
      ),
    );
    _startPolling();
    return true;
  }

  /// Runs the injected session delegate and returns to the same challenge.
  Future<void> signIn(ChallengeAuthMethod method) async {
    final current = _state;
    final resolution = switch (current) {
      ChallengeEntrySignIn(:final resolution) => resolution,
      ChallengeEntryReview(:final resolution) => resolution,
      _ => null,
    };
    if (resolution == null) {
      return;
    }
    _setState(ChallengeEntrySignIn(resolution: resolution, signingIn: true));
    try {
      final profile = await _auth.signIn(method);
      await _analytics.track(
        ChallengeAnalyticsEvent.signInCompleted,
        <String, Object?>{'method': method.wire, 'pending_challenge': true},
      );
      final pending = _pending;
      if (pending != null) {
        final updated = pending.copyWith(sender: resolution.owner ?? profile);
        await _persistence.writePending(updated);
        _pending = updated;
      }
      _setState(
        ChallengeEntryReview(
          resolution: resolution.copyWith(owner: resolution.owner ?? profile),
          signedIn: true,
        ),
      );
    } on ChallengeAuthException catch (error) {
      _setState(
        ChallengeEntrySignIn(
          resolution: resolution,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      _setState(
        ChallengeEntrySignIn(
          resolution: resolution,
          errorMessage: 'Sign-in did not complete. Try again.',
        ),
      );
    }
  }

  /// Explicit cancel of this device's own request.
  Future<void> cancelPendingRequest() async {
    final current = _state;
    if (current is! ChallengeEntryWaiting) {
      return;
    }
    try {
      await _api.respondToRequest(
        current.requestId,
        ChallengeRequestResponse.cancel,
      );
      await _clearPending();
      _stopPolling();
      _setState(const ChallengeEntryIdle());
    } on ChallengeApiException catch (error) {
      if (error.isUnauthenticated || error.isRetryable) {
        _setState(
          current.copyWith(
            errorMessage:
                error.message ?? 'The request could not be cancelled.',
          ),
        );
        return;
      }
      // The server no longer knows the request: clearing locally is safe.
      await _clearPending();
      _stopPolling();
      _setState(const ChallengeEntryIdle());
    }
  }

  /// Checks whether mutual acceptance produced a match. Polling calls this.
  Future<void> checkForAcceptedMatch() async {
    final current = _state;
    if (current is! ChallengeEntryWaiting || current.checking) {
      return;
    }
    _setState(current.copyWith(checking: true, clearError: true));
    try {
      final snapshot = await _api.accountSnapshot();
      final matchId = snapshot.activeMatchId;
      if (matchId != null && matchId.isNotEmpty) {
        await _enterMatch(matchId, current.sender, 'poll');
        return;
      }
      _setState(current.copyWith(checking: false));
    } on ChallengeApiException catch (error) {
      _setState(
        current.copyWith(
          checking: false,
          errorMessage: error.isRetryable ? error.message : null,
          clearError: !error.isRetryable,
        ),
      );
    }
  }

  /// Leaves the focused experience without cancelling the durable link or
  /// this device's request. Persisted context stays for the next open.
  void dismiss() {
    _stopPolling();
    _setState(const ChallengeEntryIdle());
  }

  /// Explicit decline of an incoming request (inbox path, task `07`).
  Future<void> declineIncomingRequest(String requestId) async {
    try {
      await _api.respondToRequest(requestId, ChallengeRequestResponse.decline);
    } on ChallengeApiException {
      // The inbox owns its retry UI; no local match is ever created.
    }
  }

  Future<void> _resumePending(PendingChallengeState pending) async {
    _pending = pending;
    if (pending.isExpired(_now())) {
      await _clearPending();
      _setState(
        ChallengeEntryUnavailable(
          token: pending.token,
          status: ChallengeLinkStatus.expired,
          message: 'This challenge request expired before it was accepted.',
        ),
      );
      return;
    }
    if (pending.matchId != null && pending.matchId!.isNotEmpty) {
      _setState(
        ChallengeEntryMatchReady(
          matchId: pending.matchId!,
          sender: pending.sender,
        ),
      );
      return;
    }
    if (pending.hasRequest) {
      _setState(
        ChallengeEntryWaiting(
          token: pending.token,
          requestId: pending.requestId!,
          sender: pending.sender,
          expiresAt: pending.expiresAt,
          restored: true,
        ),
      );
      _startPolling();
      unawaited(_refreshOwnerIdentity(pending));
      return;
    }
    await _handleToken(pending.token, source: pending.source, restored: true);
  }

  Future<void> _refreshOwnerIdentity(PendingChallengeState pending) async {
    try {
      final resolution = await _api.resolveLink(pending.token);
      final current = _state;
      if (current is ChallengeEntryWaiting && current.token == pending.token) {
        _resolution = resolution;
        final updatedPending = pending.copyWith(sender: resolution.owner);
        await _persistence.writePending(updatedPending);
        _pending = updatedPending;
        _setState(current.copyWith(sender: resolution.owner));
      }
    } catch (_) {
      // Identity refresh is cosmetic; the waiting state stays usable.
    }
  }

  Future<void> _handleToken(
    String token, {
    ChallengeLinkSource? source,
    bool restored = false,
  }) async {
    if (!config.challengeLinksEnabled) {
      _setState(ChallengeEntryInstallRequired(token: token));
      return;
    }
    await _analytics.track(
      ChallengeAnalyticsEvent.linkOpened,
      <String, Object?>{
        'source': (source ?? ChallengeLinkSource.https).wire,
        'installed': true,
      },
    );
    var pending = _pending?.token == token
        ? _pending!.copyWith(source: source ?? _pending!.source)
        : PendingChallengeState(
            token: token,
            receivedAt: _now(),
            source: source,
          );
    await _persistence.writePending(pending);
    _pending = pending;
    _setState(ChallengeEntryResolving(token));

    try {
      final resolution = await _api.resolveLink(token);
      _resolution = resolution;
      if (!resolution.canRespond) {
        await _clearPending();
        _setState(
          ChallengeEntryUnavailable(
            token: token,
            status: resolution.status,
            message: resolution.message,
          ),
        );
        return;
      }
      pending = pending.copyWith(sender: resolution.owner);
      await _persistence.writePending(pending);
      _pending = pending;
      final signedIn = await _auth.isSignedIn();
      if (!signedIn) {
        _setState(ChallengeEntrySignIn(resolution: resolution));
        return;
      }
      _setState(
        ChallengeEntryReview(
          resolution: resolution,
          signedIn: true,
          restored: restored,
        ),
      );
    } on ChallengeApiException catch (error) {
      await _handleResolveError(token, error);
    } catch (_) {
      _setState(
        ChallengeEntryFailure(
          token: token,
          message: 'The challenge could not be opened. Try again.',
        ),
      );
    }
  }

  Future<void> _handleResolveError(
    String token,
    ChallengeApiException error,
  ) async {
    if (error.isUnauthenticated) {
      _setState(
        ChallengeEntrySignIn(
          resolution: ChallengeResolution(
            token: token,
            status: ChallengeLinkStatus.available,
            owner: _pending?.sender,
          ),
        ),
      );
      return;
    }
    if (error.code == 'not_configured') {
      _setState(
        ChallengeEntryFailure(
          token: token,
          message:
              error.message ??
              'The arena backend is not configured in this build.',
          retryable: false,
        ),
      );
      return;
    }
    if (error.isRetryable) {
      _setState(
        ChallengeEntryFailure(
          token: token,
          message: error.message ?? 'The arena is unreachable right now.',
        ),
      );
      return;
    }
    await _clearPending();
    _setState(
      ChallengeEntryUnavailable(
        token: token,
        status: ChallengeApiException.statusFromErrorCode(error.code),
        message: error.message,
      ),
    );
  }

  Future<void> _enterMatch(
    String matchId,
    ArenaProfile? sender,
    String source,
  ) async {
    await _analytics.track(
      ChallengeAnalyticsEvent.requestAccepted,
      <String, Object?>{'source': source},
    );
    await _clearPending();
    _stopPolling();
    _setState(ChallengeEntryMatchReady(matchId: matchId, sender: sender));
  }

  Future<void> _clearPending() async {
    await _persistence.clearPending();
    _pending = null;
  }

  void _startPolling() {
    _stopPolling();
    if (matchPollInterval <= Duration.zero) {
      return;
    }
    _pollTimer = Timer.periodic(matchPollInterval, (_) {
      unawaited(checkForAcceptedMatch());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool _matchesArenaNamespace(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == ChallengeLink.scheme) {
      return true;
    }
    return scheme == 'https' &&
        uri.host.toLowerCase() == config.linkHost.toLowerCase();
  }

  String _tokenHint(Uri uri) {
    for (final segment in uri.pathSegments) {
      if (segment.isNotEmpty) {
        return segment;
      }
    }
    return '';
  }

  void _setState(ChallengeEntryState next) {
    if (_disposed) {
      return;
    }
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }
}
