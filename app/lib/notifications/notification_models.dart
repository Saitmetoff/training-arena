/// Push notification value objects and payload parsing.
///
/// The wire keys mirror the server outbox payloads created by task `04`
/// (`arena_notify` in `supabase/migrations/..._arena_rpc.sql`):
///
/// | kind | payload keys |
/// | --- | --- |
/// | `challenge_request` | `request_id`, `sender_id`, `sender_username` |
/// | `request_accepted` | `request_id`, `match_id` |
/// | `request_declined` | `request_id`, `status` |
/// | `match_ready` | `match_id` |
/// | `match_finished` | `match_id`, `receipt_id` |
///
/// Parsing never throws: unknown kinds and malformed values degrade to
/// [PushNotificationKind.unknown] with null targets, so a bad payload can
/// never break the app or invent a request.
library;

/// OS-level notification permission state for this device.
enum PushPermissionStatus {
  /// The user has not been asked yet (or the platform has no answer).
  notDetermined,

  /// Notifications are allowed.
  granted,

  /// The user denied notifications; the in-app inbox stays usable.
  denied;

  /// Parses the native bridge wire value; unknown input is `notDetermined`.
  static PushPermissionStatus fromWire(Object? value) {
    if (value is PushPermissionStatus) {
      return value;
    }
    return switch (value?.toString()) {
      'granted' => PushPermissionStatus.granted,
      'denied' => PushPermissionStatus.denied,
      _ => PushPermissionStatus.notDetermined,
    };
  }
}

/// Notification categories the server can send.
enum PushNotificationKind {
  challengeRequest('challenge_request'),
  requestAccepted('request_accepted'),
  requestDeclined('request_declined'),
  matchReady('match_ready'),
  matchFinished('match_finished'),

  /// Unrecognised kind; the tap resolves to an honest explanation.
  unknown('unknown');

  const PushNotificationKind(this.wire);

  final String wire;

  /// Parses a server kind; unknown input is [unknown].
  static PushNotificationKind fromWire(Object? value) {
    for (final kind in PushNotificationKind.values) {
      if (kind.wire == value) {
        return kind;
      }
    }
    return PushNotificationKind.unknown;
  }

  /// True when the notification is about one specific challenge request.
  bool get isRequest =>
      this == challengeRequest ||
      this == requestAccepted ||
      this == requestDeclined;

  /// True when the notification is about one specific match.
  bool get isMatch =>
      this == requestAccepted || this == matchReady || this == matchFinished;
}

/// One parsed push payload. [messageId] is stable per delivery when the
/// platform supplies one and is used to make duplicate taps harmless.
class PushPayload {
  const PushPayload({
    required this.kind,
    this.requestId,
    this.matchId,
    this.token,
    this.messageId,
    this.title,
    this.body,
  });

  final PushNotificationKind kind;

  /// The exact request this notification refers to, when present.
  final String? requestId;

  /// The exact match this notification refers to, when present.
  final String? matchId;

  /// Challenge link token, when the server included one.
  final String? token;

  /// Platform message id, used for duplicate suppression.
  final String? messageId;

  final String? title;
  final String? body;

  /// True when the payload can open a specific target.
  bool get isActionable =>
      kind != PushNotificationKind.unknown &&
      ((requestId?.isNotEmpty ?? false) || (matchId?.isNotEmpty ?? false));

  /// Stable key that identifies one logical notification delivery.
  String get dedupeKey {
    final id = messageId;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final target = requestId?.isNotEmpty == true
        ? requestId
        : (matchId?.isNotEmpty == true ? matchId : token);
    return '${kind.wire}:${target ?? 'none'}';
  }

  /// Parses an FCM/notification data map. All values are coerced to strings
  /// and missing keys stay null; this method never throws.
  static PushPayload fromData(Map<Object?, Object?> data) {
    String? stringOf(List<String> keys) {
      for (final key in keys) {
        final value = data[key] ?? data[key.toUpperCase()];
        if (value == null) {
          continue;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return null;
    }

    return PushPayload(
      kind: PushNotificationKind.fromWire(
        stringOf(const ['kind', 'type', 'notification_kind']),
      ),
      requestId: stringOf(const ['request_id', 'requestId']),
      matchId: stringOf(const ['match_id', 'matchId']),
      token: stringOf(const ['token', 'challenge_token']),
      messageId:
          stringOf(const ['message_id', 'messageId', 'google.message_id']),
      title: stringOf(const ['title']),
      body: stringOf(const ['body', 'message']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PushPayload &&
        other.kind == kind &&
        other.requestId == requestId &&
        other.matchId == matchId &&
        other.token == token &&
        other.messageId == messageId &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode =>
      Object.hash(kind, requestId, matchId, token, messageId, title, body);

  @override
  String toString() =>
      'PushPayload(${kind.wire}, request: $requestId, match: $matchId)';
}

/// One notification tap. Duplicate deliveries of the same tap share the
/// [PushPayload.dedupeKey], so handling them twice is harmless.
class PushTap {
  const PushTap(this.payload, {this.coldStart = false});

  final PushPayload payload;

  /// True when this tap launched the app (cold start).
  final bool coldStart;

  String get dedupeKey => payload.dedupeKey;
}
