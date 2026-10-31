import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/notifications/notification_models.dart';
import 'package:training_arena/notifications/notification_permission_store.dart';
import 'package:training_arena/notifications/notification_request_source.dart';
import 'package:training_arena/notifications/notification_service.dart';

import '../support/battle_fakes.dart';
import 'fakes.dart';

void main() {
  NotificationService buildService({
    required FakePushTransport transport,
    MemoryNotificationApi? api,
    FakeNotificationRequestSource? source,
    InMemoryNotificationPermissionStore? store,
    Future<void> Function(PushPayload payload)? onForegroundMessage,
  }) {
    return NotificationService(
      transport: transport,
      api: api ?? MemoryNotificationApi(),
      requests: source ?? FakeNotificationRequestSource(),
      permissionStore: store ?? InMemoryNotificationPermissionStore(),
      onForegroundMessage: onForegroundMessage,
    );
  }

  group('permission asked in context on the first request', () {
    test(
        'allowed path registers only the device token and preserves the '
        'request', () async {
      final transport = FakePushTransport(token: 'device-token-1');
      final api = MemoryNotificationApi();
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final store = InMemoryNotificationPermissionStore();
      final service = buildService(
        transport: transport,
        api: api,
        source: source,
        store: store,
      );
      await service.start();

      await service.noteRequestActivity();
      expect(service.shouldExplainPermission, isTrue);
      // A second activity while the rationale is up must not duplicate it.
      await service.noteRequestActivity();
      expect(service.shouldExplainPermission, isTrue);

      await service.resolvePermissionPrompt(allow: true);

      expect(service.shouldExplainPermission, isFalse);
      expect(transport.permissionRequests, 1);
      expect(api.registrations, hasLength(1));
      expect(api.registrations.single['token'], 'device-token-1');
      expect(api.registrations.single['platform'], 'android');
      expect(service.deviceRegistered, isTrue);
      expect(await store.hasAsked(), isTrue);

      // The in-app request is untouched and stays authoritative.
      final inbox = await source.inbox();
      expect(inbox.requests.single.id, 'request-1');

      // Later request activity never prompts or registers again.
      await service.noteRequestActivity();
      expect(transport.permissionRequests, 1);
      expect(api.registrations, hasLength(1));
      service.dispose();
    });

    test('not-now denial registers nothing and the request stays usable',
        () async {
      final transport = FakePushTransport(token: 'device-token-1');
      final api = MemoryNotificationApi();
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final service = buildService(
        transport: transport,
        api: api,
        source: source,
      );
      await service.start();

      await service.noteRequestActivity();
      await service.resolvePermissionPrompt(allow: false);

      expect(transport.permissionRequests, 0);
      expect(transport.tokenReads, 0);
      expect(api.registrations, isEmpty);
      expect(service.deviceRegistered, isFalse);
      final inbox = await source.inbox();
      expect(inbox.incoming?.id, 'request-1');
      service.dispose();
    });

    test('OS denial after Allow also keeps the request authoritative',
        () async {
      final transport = FakePushTransport(
        token: 'device-token-1',
        requestResult: PushPermissionStatus.denied,
      );
      final api = MemoryNotificationApi();
      final service = buildService(transport: transport, api: api);
      await service.start();

      await service.noteRequestActivity();
      await service.resolvePermissionPrompt(allow: true);

      expect(transport.permissionRequests, 1);
      expect(transport.tokenReads, 0);
      expect(api.registrations, isEmpty);
      expect(service.permission, PushPermissionStatus.denied);
      service.dispose();
    });

    test('an already-granted device registers without a prompt', () async {
      final transport = FakePushTransport(
        permission: PushPermissionStatus.granted,
        token: 'device-token-2',
      );
      final api = MemoryNotificationApi();
      final service = buildService(transport: transport, api: api);
      await service.start();

      await service.noteRequestActivity();

      expect(service.shouldExplainPermission, isFalse);
      expect(transport.permissionRequests, 0);
      expect(api.registrations.single['token'], 'device-token-2');
      service.dispose();
    });

    test('token rotation registers the new token without ever exposing it',
        () async {
      final transport = FakePushTransport(
        permission: PushPermissionStatus.granted,
        token: 'device-token-1',
      );
      final api = MemoryNotificationApi();
      final service = buildService(transport: transport, api: api);
      await service.start();
      await service.noteRequestActivity();
      expect(api.registrations, hasLength(1));

      transport.emitToken('device-token-2');
      await pumpEventQueue();
      transport.emitToken('device-token-2');
      await pumpEventQueue();
      transport.emitToken('device-token-3');
      await pumpEventQueue();

      expect(api.registrations, hasLength(3));
      expect(
        api.registrations.map((r) => r['token']),
        <String>['device-token-1', 'device-token-2', 'device-token-3'],
      );
      // Token values never leak into analytics.
      expect(api.analytics, isEmpty);
      service.dispose();
    });
  });

  group('tap routing', () {
    test('a pending request tap opens that exact request', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload()));

      expect(service.route, isA<NotificationRouteRequest>());
      final route = service.route as NotificationRouteRequest;
      expect(route.request.id, 'request-1');
      service.dispose();
    });

    test('duplicate tap deliveries are harmless', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      final tap = PushTap(requestPayload(messageId: 'message-9'));
      await service.handleTap(tap);
      final firstRoute = service.route;
      await service.handleTap(tap);
      await service.handleTap(PushTap(requestPayload(messageId: 'message-9')));
      await pumpEventQueue();

      expect(identical(service.route, firstRoute), isTrue);
      service.dispose();
    });

    test('cold-start tap is consumed once on launch', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final transport = FakePushTransport(
        initial: PushTap(requestPayload(messageId: 'cold-1'), coldStart: true),
      );
      final service = buildService(transport: transport, source: source);
      await service.start();

      expect(service.route, isA<NotificationRouteRequest>());
      expect(
        (service.route as NotificationRouteRequest).request.id,
        'request-1',
      );
      // The platform may also deliver the same tap on the warm stream.
      await service.handleTap(
        PushTap(requestPayload(messageId: 'cold-1'), coldStart: true),
      );
      expect(service.route, isA<NotificationRouteRequest>());
      service.dispose();
    });

    test('background tap stream opens the exact request', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final transport = FakePushTransport();
      final service = buildService(transport: transport, source: source);
      await service.start();

      transport.emitTap(PushTap(requestPayload(messageId: 'warm-1')));
      await pumpEventQueue();

      expect(service.route, isA<NotificationRouteRequest>());
      service.dispose();
    });

    test('expired request resolves to an explanatory screen', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[
          testRequest(kind: BattleRequestKind.expired),
        ]);
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(messageId: 'exp-1')));

      final route = service.route as NotificationRouteClosed;
      expect(route.title, 'Request expired');
      expect(route.message, contains('24 hours'));
      service.dispose();
    });

    test('cancelled request resolves to an explanatory screen', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[
          testRequest(kind: BattleRequestKind.cancelled),
        ]);
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(messageId: 'can-1')));

      expect((service.route as NotificationRouteClosed).title,
          'Request cancelled');
      service.dispose();
    });

    test('blocked request resolves to an explanatory screen', () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = BattleInbox(requests: <BattleRequest>[
          testRequest(kind: BattleRequestKind.blocked),
        ]);
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(messageId: 'blk-1')));

      expect(
        (service.route as NotificationRouteClosed).title,
        'Challenge blocked',
      );
      service.dispose();
    });

    test('already-accepted request explains and offers the active match',
        () async {
      final source = FakeNotificationRequestSource()
        ..inboxData = const BattleInbox(activeMatchId: 'match-accepted');
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(messageId: 'acc-1')));

      final route = service.route as NotificationRouteClosed;
      expect(route.title, 'Already accepted');
      expect(route.matchId, 'match-accepted');
      service.dispose();
    });

    test('a vanished request with no match explains that nothing exists',
        () async {
      final service = buildService(
        transport: FakePushTransport(),
        source: FakeNotificationRequestSource(),
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(messageId: 'gone-1')));

      final route = service.route as NotificationRouteClosed;
      expect(route.title, 'Request unavailable');
      expect(route.message, contains('Nothing was created'));
      service.dispose();
    });

    test('a declined request notification explains the update', () async {
      final service = buildService(
        transport: FakePushTransport(),
        source: FakeNotificationRequestSource(),
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(
        kind: 'request_declined',
        requestId: 'request-1',
        messageId: 'dec-1',
      )));

      expect(
          (service.route as NotificationRouteClosed).title, 'Challenge update');
      service.dispose();
    });

    test('a match tap opens only a server-confirmed match', () async {
      final source = FakeNotificationRequestSource()
        ..matchResolution = NotificationMatchOpen(
          testMatch(id: 'ranked-42', mode: ArenaMatchMode.ranked),
        );
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(
        kind: 'match_ready',
        requestId: null,
        matchId: 'ranked-42',
        messageId: 'ready-1',
      )));

      expect(service.route, isA<NotificationRouteMatch>());
      expect((service.route as NotificationRouteMatch).matchId, 'ranked-42');
      expect(source.matchChecks, <String>['ranked-42']);
      service.dispose();
    });

    test('a blocked match tap explains the block', () async {
      final source = FakeNotificationRequestSource()
        ..matchFailure = const BattleFailure(
          BattleFailureKind.blocked,
          'blocked',
        );
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(
        kind: 'match_ready',
        requestId: null,
        matchId: 'match-1',
        messageId: 'blocked-1',
      )));

      final route = service.route as NotificationRouteClosed;
      expect(route.title, 'Battle blocked');
      expect(route.message.toLowerCase(), contains('blocked'));
      service.dispose();
    });

    test('a closed match tap explains that it is unavailable', () async {
      final source = FakeNotificationRequestSource()
        ..matchResolution = const NotificationMatchClosed(
          'This match is no longer available.',
        );
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(
        kind: 'match_finished',
        requestId: null,
        matchId: 'match-1',
        messageId: 'closed-1',
      )));

      expect(
        (service.route as NotificationRouteClosed).title,
        'Battle unavailable',
      );
      service.dispose();
    });

    test('a retryable failure can retry and then open the request', () async {
      final source = FakeNotificationRequestSource()
        ..inboxFailure = const BattleFailure(BattleFailureKind.offline, 'down')
        ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
      final service = buildService(
        transport: FakePushTransport(),
        source: source,
      );
      await service.start();

      await service.handleTap(PushTap(requestPayload(messageId: 'retry-1')));
      expect(service.route, isA<NotificationRouteFailed>());

      source.inboxFailure = null;
      await service.retry();

      expect(service.route, isA<NotificationRouteRequest>());
      service.dispose();
    });

    test('an unknown notification opens an honest explanation', () async {
      final service = buildService(
        transport: FakePushTransport(),
        source: FakeNotificationRequestSource(),
      );
      await service.start();

      await service.handleTap(const PushTap(PushPayload(
        kind: PushNotificationKind.unknown,
        messageId: 'unknown-1',
      )));

      expect(
          (service.route as NotificationRouteClosed).title, 'Fault');
      service.dispose();
    });
  });

  group('foreground messages', () {
    test('a foreground message triggers one inbox refresh and is deduped',
        () async {
      var refreshes = 0;
      final transport = FakePushTransport();
      final service = buildService(
        transport: transport,
        onForegroundMessage: (_) async => refreshes++,
      );
      await service.start();

      final payload = requestPayload(messageId: 'fg-1');
      transport.emitMessage(payload);
      await pumpEventQueue();
      transport.emitMessage(payload);
      await pumpEventQueue();

      expect(refreshes, 1);
      // Foreground delivery never opens a request by itself.
      expect(service.route, isA<NotificationRouteIdle>());
      service.dispose();
    });
  });
}
