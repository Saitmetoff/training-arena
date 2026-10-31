import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/battle/state/battle_models.dart';
import 'package:training_arena/notifications/notification_models.dart';
import 'package:training_arena/notifications/notification_permission_store.dart';
import 'package:training_arena/notifications/notification_service.dart';
import 'package:training_arena/notifications/ui/notification_gate.dart';
import 'package:training_arena/theme/arena_theme.dart';

import '../support/battle_fakes.dart';
import 'fakes.dart';

void main() {
  Future<NotificationService> serviceWithRoute(PushPayload payload) async {
    final source = FakeNotificationRequestSource()
      ..inboxData = BattleInbox(requests: <BattleRequest>[testRequest()]);
    final service = NotificationService(
      transport: FakePushTransport(),
      api: MemoryNotificationApi(),
      requests: source,
      permissionStore: InMemoryNotificationPermissionStore(),
    );
    await service.start();
    await service.handleTap(PushTap(payload));
    return service;
  }

  testWidgets('a pending request renders with accept and decline actions',
      (tester) async {
    final service = await serviceWithRoute(requestPayload());
    BattleRequest? accepted;
    BattleRequest? declined;
    await tester.pumpWidget(MaterialApp(
      theme: ArenaTheme.dark,
      home: NotificationGate(
        service: service,
        onAcceptRequest: (request) async => accepted = request,
        onDeclineRequest: (request) async => declined = request,
        onResumeMatch: (_) async {},
        onBackToBattle: () {},
      ),
    ));

    expect(
      find.byKey(const ValueKey('notification-request-card')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('notification-accept')));
    await tester.pump();
    expect(accepted?.id, 'request-1');

    await tester.tap(find.byKey(const ValueKey('notification-decline')));
    await tester.pump();
    expect(declined?.id, 'request-1');
    service.dispose();
  });

  testWidgets('an unavailable request renders the explanation and back',
      (tester) async {
    final source = FakeNotificationRequestSource()
      ..inboxData = BattleInbox(requests: <BattleRequest>[
        testRequest(kind: BattleRequestKind.expired),
      ]);
    final service = NotificationService(
      transport: FakePushTransport(),
      api: MemoryNotificationApi(),
      requests: source,
      permissionStore: InMemoryNotificationPermissionStore(),
    );
    await service.start();
    await service.handleTap(PushTap(requestPayload(messageId: 'gone')));

    var backTapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: ArenaTheme.dark,
      home: NotificationGate(
        service: service,
        onAcceptRequest: (_) async {},
        onDeclineRequest: (_) async {},
        onResumeMatch: (_) async {},
        onBackToBattle: () => backTapped = true,
      ),
    ));

    expect(find.byKey(const ValueKey('notification-closed')), findsOneWidget);
    expect(find.text('Request expired'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notification-back-to-battle')));
    await tester.pump();
    expect(backTapped, isTrue);
    service.dispose();
  });

  testWidgets('the permission rationale reports allow and not-now',
      (tester) async {
    for (final allow in <bool>[true, false]) {
      late Future<bool> pending;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              pending = showNotificationPermissionRationale(context);
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('notification-permission-dialog')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey(
        allow
            ? 'notification-permission-allow'
            : 'notification-permission-not-now',
      )));
      await tester.pumpAndSettle();
      expect(await pending, allow);
    }
  });
}
