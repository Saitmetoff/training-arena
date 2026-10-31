import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/notifications/notification_models.dart';

void main() {
  group('PushPayload parsing', () {
    test('parses a server challenge_request data map', () {
      final payload = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'challenge_request',
        'request_id': 'request-1',
        'sender_id': 'user-2',
        'sender_username': 'zuhra',
      });

      expect(payload.kind, PushNotificationKind.challengeRequest);
      expect(payload.requestId, 'request-1');
      expect(payload.matchId, isNull);
      expect(payload.isActionable, isTrue);
    });

    test('parses request_accepted and match payloads', () {
      final accepted = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'request_accepted',
        'request_id': 'request-1',
        'match_id': 'match-1',
      });
      expect(accepted.kind, PushNotificationKind.requestAccepted);
      expect(accepted.requestId, 'request-1');
      expect(accepted.matchId, 'match-1');

      final ready = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'match_ready',
        'match_id': 'match-1',
      });
      expect(ready.kind, PushNotificationKind.matchReady);
      expect(ready.matchId, 'match-1');
      expect(ready.isActionable, isTrue);
    });

    test('unknown kinds and malformed values fail closed', () {
      expect(
        PushPayload.fromData(const <Object?, Object?>{}).kind,
        PushNotificationKind.unknown,
      );
      expect(
        PushPayload.fromData(const <Object?, Object?>{'kind': 'future_thing'})
            .kind,
        PushNotificationKind.unknown,
      );
      expect(
        PushPayload.fromData(const <Object?, Object?>{'kind': 'match_ready'})
            .isActionable,
        isFalse,
      );
      // Non-string values are coerced, never thrown on.
      final coerced = PushPayload.fromData(
        const <Object?, Object?>{'kind': 'challenge_request', 'request_id': 7},
      );
      expect(coerced.requestId, '7');
    });

    test('dedupe keys prefer the platform message id', () {
      final withId = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'challenge_request',
        'request_id': 'request-1',
        'message_id': 'm-1',
      });
      expect(withId.dedupeKey, 'm-1');

      final withoutId = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'challenge_request',
        'request_id': 'request-1',
      });
      final same = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'challenge_request',
        'request_id': 'request-1',
      });
      final different = PushPayload.fromData(const <Object?, Object?>{
        'kind': 'challenge_request',
        'request_id': 'request-2',
      });
      expect(withoutId.dedupeKey, same.dedupeKey);
      expect(withoutId.dedupeKey, isNot(different.dedupeKey));
    });
  });

  test('permission status wire parsing fails closed to notDetermined', () {
    expect(
      PushPermissionStatus.fromWire('granted'),
      PushPermissionStatus.granted,
    );
    expect(
      PushPermissionStatus.fromWire('denied'),
      PushPermissionStatus.denied,
    );
    expect(
      PushPermissionStatus.fromWire('something-else'),
      PushPermissionStatus.notDetermined,
    );
    expect(
      PushPermissionStatus.fromWire(null),
      PushPermissionStatus.notDetermined,
    );
  });
}
