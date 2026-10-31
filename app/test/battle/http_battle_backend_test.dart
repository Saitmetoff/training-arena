import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:training_arena/battle/data/http_battle_backend.dart';
import 'package:training_arena/battle/state/battle_failure.dart';
import 'package:training_arena/config/arena_config.dart';

void main() {
  test('ready, restore and heartbeat send the current numeric version and map update recovery', () async {
    final calls = <Map<String, dynamic>>[];
    final backend = HttpBattleBackend(
      config: const ArenaConfig(
        publicUrl: 'https://arena.example',
        linkHost: 'arena.example',
        supabaseUrl: 'https://project.example',
        supabaseAnonKey: 'public-test-key',
      ),
      accessTokenProvider: () async => 'session-test-token',
      client: MockClient((wire) async {
        calls.add(jsonDecode(wire.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'update_required',
              'message': 'Update both phones',
            },
          }),
          200,
        );
      }),
    );
    for (final action in [
      () => backend.matchState('match-1'),
      () => backend.ready('match-1', tracking: true, practiceComplete: true),
      () => backend.heartbeat('match-1', tracking: true),
    ]) {
      await expectLater(
        action(),
        throwsA(
          isA<BattleFailure>()
              .having((e) => e.kind, 'kind', BattleFailureKind.updateRequired)
              .having((e) => e.isTransient, 'retryable', false),
        ),
      );
      expect(calls.last['params']['counter_version'], '1.3.0');
    }
  });
  test('rematch and inbox preserve outgoing server requests', () async {
    var accessToken = 'session-test-token';
    var viewerId = 'me';
    final calls = <Map<String, dynamic>>[];
    final request = {
      'id': 'request-new',
      'status': 'pending',
      'sender': {'id': 'me', 'username': 'me'},
      'recipient': {'id': 'peer', 'username': 'peer'},
      'created_at': '2026-09-30T12:00:00Z',
      'expires_at': '2026-10-01T12:00:00Z',
    };
    final backend = HttpBattleBackend(
      config: const ArenaConfig(
        publicUrl: 'https://arena.example',
        linkHost: 'arena.example',
        supabaseUrl: 'https://project.example',
        supabaseAnonKey: 'public-test-key',
      ),
      accessTokenProvider: () async => accessToken,
      client: MockClient((wire) async {
        expect(wire.headers['authorization'], 'Bearer $accessToken');
        final body = jsonDecode(wire.body) as Map<String, dynamic>;
        calls.add(body);
        final data = switch (body['action']) {
          'profile' => {
            'profile': {'id': viewerId, 'username': 'me'},
          },
          'request_rematch' => {'request': request},
          'inbox' => {
            'requests': [request],
          },
          _ => throw StateError('unexpected action'),
        };
        return http.Response(jsonEncode({'data': data}), 200);
      }),
    );
    final pending = await backend.requestRematch('finished-match');
    expect(calls.last, {
      'action': 'request_rematch',
      'params': {'match_id': 'finished-match'},
    });
    expect(pending.isOutgoing, isTrue);
    expect(pending.recipient?.id, 'peer');
    final inbox = await backend.inbox();
    expect(inbox.requests.single, pending);
    expect(inbox.incoming, isNull);

    accessToken = 'refreshed-session-test-token';
    final refreshed = await backend.requestRematch('finished-match');
    expect(refreshed.isOutgoing, isTrue);

    accessToken = 'another-session';
    viewerId = 'peer';
    final switched = await backend.inbox();
    expect(switched.incoming?.id, 'request-new');
    expect(switched.requests.single.isOutgoing, isFalse);

    request['sender'] = {'id': 'outsider'};
    request['recipient'] = {'id': 'another-outsider'};
    await expectLater(
      backend.requestRematch('finished-match'),
      throwsA(isA<BattleFailure>()),
    );
  });
}
