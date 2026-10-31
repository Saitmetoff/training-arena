/// Test doubles for the notification layer.
library;

import 'dart:async';

import 'package:training_arena/battle/ports/battle_analytics.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/notifications/notification_api.dart';
import 'package:training_arena/notifications/notification_models.dart';
import 'package:training_arena/notifications/notification_request_source.dart';
import 'package:training_arena/notifications/push_transport.dart';

import '../support/battle_fakes.dart';

/// Scriptable [PushTransport] that never touches a platform channel.
class FakePushTransport implements PushTransport {
  FakePushTransport({
    PushPermissionStatus permission = PushPermissionStatus.notDetermined,
    PushPermissionStatus requestResult = PushPermissionStatus.granted,
    this.token,
    this.initial,
  })  : _permission = permission,
        _requestResult = requestResult;

  PushPermissionStatus _permission;
  final PushPermissionStatus _requestResult;

  /// The token reported by [deviceToken] and [tokenRefreshes].
  String? token;

  /// Cold-start tap reported by [initialTap].
  PushTap? initial;

  int permissionReads = 0;
  int permissionRequests = 0;
  int tokenReads = 0;
  bool disposed = false;

  final StreamController<PushPayload> _messages =
      StreamController<PushPayload>.broadcast();
  final StreamController<PushTap> _taps = StreamController<PushTap>.broadcast();
  final StreamController<String> _tokens = StreamController<String>.broadcast();

  @override
  Future<PushPermissionStatus> permissionStatus() async {
    permissionReads++;
    return _permission;
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    permissionRequests++;
    _permission = _requestResult;
    return _requestResult;
  }

  @override
  Future<String?> deviceToken() async {
    tokenReads++;
    return token;
  }

  @override
  Stream<PushPayload> get foregroundMessages => _messages.stream;

  @override
  Stream<PushTap> get notificationTaps => _taps.stream;

  @override
  Stream<String> get tokenRefreshes => _tokens.stream;

  @override
  Future<PushTap?> initialTap() async => initial;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _messages.close();
    await _taps.close();
    await _tokens.close();
  }

  void emitMessage(PushPayload payload) => _messages.add(payload);

  void emitTap(PushTap tap) => _taps.add(tap);

  void emitToken(String value) => _tokens.add(value);
}

/// Records `device_register` and `analytics` traffic.
class MemoryNotificationApi implements NotificationApi {
  final List<Map<String, Object?>> registrations = <Map<String, Object?>>[];
  final List<Map<String, Object?>> analytics = <Map<String, Object?>>[];

  bool failRegistration = false;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    if (failRegistration) {
      throw const NotificationApiException('offline');
    }
    registrations.add(<String, Object?>{'token': token, 'platform': platform});
  }

  @override
  Future<void> trackEvent(
    String event,
    Map<String, Object?> properties,
  ) async {
    analytics.add(<String, Object?>{'event': event, ...properties});
  }
}

/// Scriptable authoritative request/match source.
class FakeNotificationRequestSource implements NotificationRequestSource {
  BattleInbox inboxData = const BattleInbox();
  BattleFailure? inboxFailure;
  NotificationMatchResolution? matchResolution;
  BattleFailure? matchFailure;
  final List<String> matchChecks = <String>[];

  @override
  Future<BattleInbox> inbox() async {
    if (inboxFailure != null) {
      throw inboxFailure!;
    }
    return inboxData;
  }

  @override
  Future<NotificationMatchResolution> matchStatus(String matchId) async {
    matchChecks.add(matchId);
    if (matchFailure != null) {
      throw matchFailure!;
    }
    return matchResolution ?? NotificationMatchOpen(testMatch(id: matchId));
  }
}

/// Records matchmaking analytics in call order.
class RecordingBattleAnalyticsSink implements BattleAnalyticsSink {
  final List<String> events = <String>[];
  final List<Map<String, Object?>> properties = <Map<String, Object?>>[];

  Map<String, Object?>? lastFor(String event) {
    for (var i = events.length - 1; i >= 0; i--) {
      if (events[i] == event) {
        return properties[i];
      }
    }
    return null;
  }

  int countOf(String event) => events.where((e) => e == event).length;

  @override
  Future<void> track(String event, Map<String, Object?> values) async {
    events.add(event);
    properties.add(Map<String, Object?>.of(values));
  }
}

/// Convenience payload builders.
PushPayload requestPayload({
  String kind = 'challenge_request',
  String? requestId = 'request-1',
  String? matchId,
  String? messageId = 'message-1',
}) {
  return PushPayload(
    kind: PushNotificationKind.fromWire(kind),
    requestId: requestId,
    matchId: matchId,
    messageId: messageId,
  );
}
