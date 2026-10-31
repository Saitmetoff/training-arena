import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/notifications/notification_models.dart';
import 'package:training_arena/notifications/platform_push_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const method = MethodChannel(PushChannels.method);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockStreamHandler(
        const EventChannel(PushChannels.messages), null);
    messenger.setMockStreamHandler(const EventChannel(PushChannels.taps), null);
    messenger.setMockStreamHandler(
        const EventChannel(PushChannels.tokens), null);
  });

  test('reads permission, token and cold-start taps from the native bridge',
      () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(method, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'permissionStatus' => 'granted',
        'requestPermission' => 'denied',
        'deviceToken' => 'token-abc',
        'initialTap' => <String, Object?>{
            'kind': 'challenge_request',
            'request_id': 'request-1',
            'message_id': 'cold-1',
          },
        _ => null,
      };
    });

    final transport = PlatformPushTransport();
    expect(
      await transport.permissionStatus(),
      PushPermissionStatus.granted,
    );
    expect(
      await transport.requestPermission(),
      PushPermissionStatus.denied,
    );
    expect(await transport.deviceToken(), 'token-abc');

    final tap = await transport.initialTap();
    expect(tap, isNotNull);
    expect(tap!.coldStart, isTrue);
    expect(tap.payload.kind, PushNotificationKind.challengeRequest);
    expect(tap.payload.requestId, 'request-1');

    await transport.dispose();
    expect(calls, contains('dispose'));
  });

  test('a missing native bridge degrades to no-push instead of throwing',
      () async {
    messenger.setMockMethodCallHandler(
      method,
      (call) async => throw MissingPluginException('no bridge'),
    );

    final transport = PlatformPushTransport();
    expect(
      await transport.permissionStatus(),
      PushPermissionStatus.notDetermined,
    );
    expect(await transport.deviceToken(), isNull);
    expect(await transport.initialTap(), isNull);
  });

  test('event streams parse foreground messages, taps and token refreshes',
      () async {
    final messageController =
        StreamController<Map<Object?, Object?>>.broadcast();
    final tapController = StreamController<Map<Object?, Object?>>.broadcast();
    final tokenController = StreamController<Object?>.broadcast();

    messenger.setMockStreamHandler(
      const EventChannel(PushChannels.messages),
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          messageController.stream.listen(events.success);
        },
      ),
    );
    messenger.setMockStreamHandler(
      const EventChannel(PushChannels.taps),
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          tapController.stream.listen(events.success);
        },
      ),
    );
    messenger.setMockStreamHandler(
      const EventChannel(PushChannels.tokens),
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          tokenController.stream.listen(events.success);
        },
      ),
    );

    final transport = PlatformPushTransport();
    final messages = <PushPayload>[];
    final taps = <PushTap>[];
    final tokens = <String>[];
    final messageSubscription =
        transport.foregroundMessages.listen(messages.add);
    final tapSubscription = transport.notificationTaps.listen(taps.add);
    final tokenSubscription = transport.tokenRefreshes.listen(tokens.add);
    await pumpEventQueue();

    messageController.add(<String, Object?>{
      'kind': 'match_ready',
      'match_id': 'match-1',
      'message_id': 'm-1',
    });
    tapController.add(<String, Object?>{
      'kind': 'challenge_request',
      'request_id': 'request-1',
      'message_id': 'm-1',
    });
    tokenController.add('token-refreshed');
    await pumpEventQueue();

    expect(messages.single.kind, PushNotificationKind.matchReady);
    expect(messages.single.matchId, 'match-1');
    expect(taps.single.payload.requestId, 'request-1');
    expect(tokens, <String>['token-refreshed']);

    await messageSubscription.cancel();
    await tapSubscription.cancel();
    await tokenSubscription.cancel();
    await messageController.close();
    await tapController.close();
    await tokenController.close();
    await transport.dispose();
  });
}
