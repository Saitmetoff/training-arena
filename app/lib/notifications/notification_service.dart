/// Notification permission, token registration and tap routing.
///
/// Contract rules encoded here:
///
/// - The permission prompt is offered once, in context, when the user first
///   sends or receives a challenge request ([noteRequestActivity]).
/// - Denying permission never blocks the request: the in-app inbox stays
///   authoritative and untouched.
/// - A device token is registered only through `device_register`, is never
///   logged and never appears in analytics properties.
/// - A notification tap opens the exact server-confirmed request or match.
///   Expired, cancelled, blocked and already-accepted requests resolve to an
///   explanatory [NotificationRouteClosed] instead of a generic home screen.
/// - Duplicate deliveries of the same payload are harmless: each
///   [PushPayload.dedupeKey] is handled at most once per session.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../battle/state/battle_failure.dart';
import '../battle/state/battle_models.dart';
import 'notification_api.dart';
import 'notification_models.dart';
import 'notification_permission_store.dart';
import 'notification_request_source.dart';
import 'push_transport.dart';

/// What the focused notification gate should render.
sealed class NotificationRoute {
  const NotificationRoute();
}

/// Nothing to show; the shell stays in charge.
class NotificationRouteIdle extends NotificationRoute {
  const NotificationRouteIdle();
}

/// The tap arrived and the authoritative request/match is resolving.
class NotificationRouteOpening extends NotificationRoute {
  const NotificationRouteOpening(this.targetLabel);

  final String targetLabel;
}

/// The exact pending request the notification referred to.
class NotificationRouteRequest extends NotificationRoute {
  const NotificationRouteRequest(this.request);

  final BattleRequest request;
}

/// The exact server-issued match the notification referred to.
class NotificationRouteMatch extends NotificationRoute {
  const NotificationRouteMatch(this.matchId);

  final String matchId;
}

/// The notification cannot be opened; [title]/[message] explain why.
class NotificationRouteClosed extends NotificationRoute {
  const NotificationRouteClosed(this.title, this.message, {this.matchId});

  final String title;
  final String message;

  /// Set when the explanation can hand off to an already-created match.
  final String? matchId;
}

/// The arena could not be reached; retry is safe and creates nothing.
class NotificationRouteFailed extends NotificationRoute {
  const NotificationRouteFailed(this.message);

  final String message;
}

/// Orchestrates permission, registration and tap routing.
class NotificationService extends ChangeNotifier {
  NotificationService({
    required PushTransport transport,
    required NotificationApi api,
    required NotificationRequestSource requests,
    required NotificationPermissionStore permissionStore,
    this.onForegroundMessage,
    this.platform = 'android',
  }) : _transport = transport,
       _api = api,
       _requests = requests,
       _permissionStore = permissionStore;

  final PushTransport _transport;
  final NotificationApi _api;
  final NotificationRequestSource _requests;
  final NotificationPermissionStore _permissionStore;

  /// Called for a foreground message so the app can refresh the inbox; the
  /// inbox action remains the source of truth.
  final Future<void> Function(PushPayload payload)? onForegroundMessage;

  /// Platform value sent to `device_register`.
  final String platform;

  StreamSubscription<PushTap>? _tapsSubscription;
  StreamSubscription<PushPayload>? _messagesSubscription;
  StreamSubscription<String>? _tokensSubscription;

  PushPermissionStatus _permission = PushPermissionStatus.notDetermined;
  bool _asked = false;
  bool _promptVisible = false;
  bool _deviceRegistered = false;
  bool _registrationInFlight = false;
  bool _started = false;
  bool _disposed = false;
  String? _lastRegisteredToken;

  NotificationRoute _route = const NotificationRouteIdle();
  PushTap? _lastTap;
  final Set<String> _handledTaps = <String>{};
  final Set<String> _handlingTaps = <String>{};
  final Set<String> _seenForeground = <String>{};

  /// Current OS permission answer.
  PushPermissionStatus get permission => _permission;

  /// True while the in-context rationale should be shown.
  bool get shouldExplainPermission => _promptVisible;

  /// True when this device token has been accepted by `device_register`.
  bool get deviceRegistered => _deviceRegistered;

  /// True once the one-time prompt has been answered.
  bool get permissionAsked => _asked;

  /// Current gate route.
  NotificationRoute get route => _route;

  /// Begins listening for taps/tokens. Idempotent.
  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    _asked = await _permissionStore.hasAsked();
    _permission = await _safePermissionStatus();
    if (_permission == PushPermissionStatus.granted) {
      // Permission already granted (for example before reinstalling): no
      // prompt is needed, the token can be registered straight away.
      _promptVisible = false;
      await _markAsked();
    }
    _tapsSubscription = _transport.notificationTaps.listen(
      (tap) => unawaited(handleTap(tap)),
    );
    _messagesSubscription = _transport.foregroundMessages.listen(
      _onForegroundMessage,
    );
    _tokensSubscription = _transport.tokenRefreshes.listen(
      (token) => unawaited(_registerToken(token)),
    );
    final initial = await _transport.initialTap();
    if (initial != null) {
      await handleTap(initial);
    }
    if (_permission == PushPermissionStatus.granted) {
      unawaited(registerDevice());
    }
    _notify();
  }

  /// Called when the user first sends or receives a challenge request.
  ///
  /// This is the only trigger for the in-context permission prompt. It never
  /// touches the request itself, so a denial leaves the inbox unchanged.
  Future<void> noteRequestActivity() async {
    if (_disposed) {
      return;
    }
    if (_permission == PushPermissionStatus.granted) {
      await _markAsked();
      await registerDevice();
      return;
    }
    if (_permission == PushPermissionStatus.denied) {
      // The OS will not prompt again; the in-app inbox stays authoritative.
      await _markAsked();
      return;
    }
    if (_asked || _promptVisible) {
      return;
    }
    _promptVisible = true;
    _notify();
  }

  /// Records the user's answer to the in-context rationale.
  Future<void> resolvePermissionPrompt({required bool allow}) async {
    if (_disposed || !_promptVisible) {
      return;
    }
    _promptVisible = false;
    await _markAsked();
    if (allow) {
      _permission = await _safeRequestPermission();
      if (_permission == PushPermissionStatus.granted) {
        await registerDevice();
      }
    }
    _notify();
  }

  /// Registers the current device token. Returns whether the server accepted
  /// a token in this call. Safe to call repeatedly.
  Future<bool> registerDevice() async {
    if (_disposed ||
        _permission != PushPermissionStatus.granted ||
        _registrationInFlight) {
      return false;
    }
    _registrationInFlight = true;
    try {
      final token = await _safeDeviceToken();
      if (token == null) {
        return false;
      }
      return await _registerToken(token);
    } finally {
      _registrationInFlight = false;
    }
  }

  /// Handles one notification tap. Duplicate taps are ignored once resolved.
  Future<void> handleTap(PushTap tap) async {
    if (_disposed) {
      return;
    }
    final key = tap.dedupeKey;
    if (_handledTaps.contains(key) || _handlingTaps.contains(key)) {
      return;
    }
    _handlingTaps.add(key);
    _lastTap = tap;
    _route = NotificationRouteOpening(_targetLabel(tap.payload));
    _notify();
    try {
      await _resolveTap(tap.payload);
      _handledTaps.add(key);
    } on BattleFailure catch (failure) {
      if (_isRetryable(failure.kind)) {
        _route = NotificationRouteFailed(failure.message);
      } else {
        final blocked = failure.kind == BattleFailureKind.blocked;
        _route = NotificationRouteClosed(
          blocked
              ? (tap.payload.kind.isMatch
                    ? 'Battle blocked'
                    : 'Challenge blocked')
              : 'Request unavailable',
          failure.message,
        );
        _handledTaps.add(key);
      }
    } catch (_) {
      _route = const NotificationRouteFailed(
        'The arena could not be reached. Your inbox is unchanged.',
      );
    } finally {
      _handlingTaps.remove(key);
      _notify();
    }
  }

  /// Retries the failed tap resolution without inventing anything.
  Future<void> retry() async {
    final tap = _lastTap;
    if (tap == null) {
      return;
    }
    _handledTaps.remove(tap.dedupeKey);
    await handleTap(tap);
  }

  /// Leaves the focused gate and returns to the shell.
  void closeRoute() {
    _route = const NotificationRouteIdle();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_tapsSubscription?.cancel());
    unawaited(_messagesSubscription?.cancel());
    unawaited(_tokensSubscription?.cancel());
    unawaited(_transport.dispose());
    super.dispose();
  }

  // ------------------------------------------------------------- internals

  Future<void> _resolveTap(PushPayload payload) async {
    switch (payload.kind) {
      case PushNotificationKind.challengeRequest:
        await _resolveRequestTap(payload);
      case PushNotificationKind.requestAccepted:
      case PushNotificationKind.matchReady:
      case PushNotificationKind.matchFinished:
        await _resolveMatchTap(payload);
      case PushNotificationKind.requestDeclined:
        _route = const NotificationRouteClosed(
          'Challenge update',
          'That challenge is no longer pending. It was declined or cancelled '
              'and nothing was created.',
        );
      case PushNotificationKind.unknown:
        _route = const NotificationRouteClosed(
          'Fault',
          'This notification does not open a request in this build. Open '
              'Battle to see your inbox.',
        );
    }
  }

  Future<void> _resolveRequestTap(PushPayload payload) async {
    final inbox = await _requests.inbox();
    BattleRequest? match;
    for (final request in inbox.requests) {
      if (request.id == payload.requestId) {
        match = request;
        break;
      }
    }
    if (match == null) {
      final activeMatchId = inbox.activeMatchId;
      if (activeMatchId != null && activeMatchId.isNotEmpty) {
        _route = NotificationRouteClosed(
          'Already accepted',
          'This challenge was already accepted. Open Battle to resume the '
              'match.',
          matchId: activeMatchId,
        );
      } else {
        _route = const NotificationRouteClosed(
          'Request unavailable',
          'This challenge is no longer pending. It may have expired, been '
              'cancelled, or the players blocked each other. Nothing was '
              'created.',
        );
      }
      return;
    }
    switch (match.kind) {
      case BattleRequestKind.pending:
        _route = NotificationRouteRequest(match);
      case BattleRequestKind.expired:
        _route = const NotificationRouteClosed(
          'Request expired',
          'This challenge expired after 24 hours. Nothing was created and no '
              'rating changed.',
        );
      case BattleRequestKind.cancelled:
        _route = const NotificationRouteClosed(
          'Request cancelled',
          'This challenge was cancelled or declined. Nothing was created.',
        );
      case BattleRequestKind.blocked:
        _route = const NotificationRouteClosed(
          'Challenge blocked',
          'One player blocked the other, so this challenge cannot be opened. '
              'Nothing was created.',
        );
      case BattleRequestKind.offlineChallenger:
        _route = const NotificationRouteClosed(
          'Challenger offline',
          'The challenger is not reachable right now. The request stays in '
              'your inbox until it expires.',
        );
      case BattleRequestKind.busyPlayer:
        _route = const NotificationRouteClosed(
          'Player busy',
          'That player is in another battle. The request stays in your inbox '
              'until it expires.',
        );
    }
  }

  Future<void> _resolveMatchTap(PushPayload payload) async {
    final matchId = payload.matchId;
    if (matchId == null || matchId.isEmpty) {
      _route = const NotificationRouteClosed(
        'Battle unavailable',
        'This notification does not identify a battle. Open Battle for your '
            'requests.',
      );
      return;
    }
    final inbox = await _requests.inbox();
    if (inbox.activeMatchId == matchId) {
      _route = NotificationRouteMatch(matchId);
      return;
    }
    final resolution = await _requests.matchStatus(matchId);
    switch (resolution) {
      case NotificationMatchOpen():
        _route = NotificationRouteMatch(matchId);
      case NotificationMatchClosed(:final message, :final blocked):
        _route = NotificationRouteClosed(
          blocked ? 'Battle blocked' : 'Battle unavailable',
          message,
        );
    }
  }

  bool _isRetryable(BattleFailureKind kind) {
    return switch (kind) {
      BattleFailureKind.offline ||
      BattleFailureKind.unauthorized ||
      BattleFailureKind.unconfigured ||
      BattleFailureKind.serverFailure => true,
      BattleFailureKind.notFound ||
      BattleFailureKind.updateRequired ||
      BattleFailureKind.conflict ||
      BattleFailureKind.blocked ||
      BattleFailureKind.permissionDenied ||
      BattleFailureKind.cameraUnavailable => false,
    };
  }

  bool _onForegroundMessage(PushPayload payload) {
    if (_disposed || !_seenForeground.add(payload.dedupeKey)) {
      return false;
    }
    final handler = onForegroundMessage;
    if (handler != null) {
      unawaited(handler(payload));
    }
    _notify();
    return true;
  }

  Future<bool> _registerToken(String token) async {
    final trimmed = token.trim();
    if (_disposed ||
        trimmed.isEmpty ||
        _permission != PushPermissionStatus.granted ||
        trimmed == _lastRegisteredToken) {
      return false;
    }
    try {
      await _api.registerDevice(token: trimmed, platform: platform);
      _lastRegisteredToken = trimmed;
      _deviceRegistered = true;
      _notify();
      return true;
    } on NotificationApiException {
      // Best effort; the next token refresh or request activity retries.
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markAsked() async {
    _asked = true;
    await _permissionStore.markAsked();
  }

  Future<PushPermissionStatus> _safePermissionStatus() async {
    try {
      return await _transport.permissionStatus();
    } catch (_) {
      return PushPermissionStatus.notDetermined;
    }
  }

  Future<PushPermissionStatus> _safeRequestPermission() async {
    try {
      return await _transport.requestPermission();
    } catch (_) {
      return PushPermissionStatus.denied;
    }
  }

  Future<String?> _safeDeviceToken() async {
    try {
      return await _transport.deviceToken();
    } catch (_) {
      return null;
    }
  }

  String _targetLabel(PushPayload payload) {
    return switch (payload.kind) {
      PushNotificationKind.challengeRequest => 'the challenge request',
      PushNotificationKind.requestAccepted => 'the accepted challenge',
      PushNotificationKind.matchReady => 'the battle',
      PushNotificationKind.matchFinished => 'the result',
      PushNotificationKind.requestDeclined => 'the challenge update',
      PushNotificationKind.unknown => 'the notification',
    };
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
