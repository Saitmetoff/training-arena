import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:training_arena/linking/arena_challenge_api.dart';
import 'package:training_arena/linking/challenge_models.dart';

import 'fakes.dart';

void main() {
  HttpArenaChallengeApi build(
    MockClient client, {
    String? accessToken = 'access-token',
    bool configured = true,
  }) {
    return HttpArenaChallengeApi(
      config: testConfig(
        supabaseUrl: configured ? 'https://project.invalid' : '',
        supabaseAnonKey: configured ? 'anon-public' : '',
      ),
      accessTokenProvider: () async => accessToken,
      client: client,
    );
  }

  test('resolveLink uses the anonymous read-only GET contract', () async {
    late http.Request captured;
    final api = build(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'owner': <String, Object?>{
                'id': fakeOwnerId,
                'username': 'zuhra',
                'rating': 1060,
              },
              'available': true,
            },
          }),
          200,
        );
      }),
    );

    final resolution = await api.resolveLink(fakeToken);
    expect(captured.method, 'GET');
    expect(captured.url.path, '/functions/v1/arena');
    expect(captured.url.queryParameters['token'], fakeToken);
    expect(captured.headers['apikey'], 'anon-public');
    expect(resolution.status, ChallengeLinkStatus.available);
    expect(resolution.owner!.username, 'zuhra');
  });

  test('resolveLink fails closed for unavailable without inventing an owner',
      () async {
    final api = build(
      MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{'owner': null, 'available': false},
          }),
          200,
        ),
      ),
    );
    final resolution = await api.resolveLink(fakeToken);
    expect(resolution.status, ChallengeLinkStatus.unavailable);
    expect(resolution.owner, isNull);
  });

  test('sendRequest posts the documented envelope and parses the request',
      () async {
    late http.Request captured;
    final api = build(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'request': <String, Object?>{
                'id': 'req-1',
                'status': 'pending',
                'expires_at': '2030-01-01T00:00:00.000Z',
                'match_id': null,
              },
            },
          }),
          200,
        );
      }),
    );

    final request = await api.sendRequest(fakeToken);
    final body = jsonDecode(captured.body) as Map<String, Object?>;
    expect(captured.method, 'POST');
    expect(captured.headers['authorization'], 'Bearer access-token');
    expect(body['action'], 'request_send');
    expect((body['params'] as Map<String, Object?>)['token'], fakeToken);
    expect(request.id, 'req-1');
    expect(request.status, ChallengeRequestStatus.pending);
  });

  test('missing auth fails closed before any network call', () async {
    var called = false;
    final api = build(
      MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
      accessToken: null,
    );
    expect(
      () => api.sendRequest(fakeToken),
      throwsA(
        isA<ChallengeApiException>()
            .having((error) => error.code, 'code', 'unauthenticated'),
      ),
    );
    expect(called, isFalse);
  });

  test('error envelopes map to coded exceptions', () async {
    final api = build(
      MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'blocked',
              'message': 'challenge is not available',
            },
          }),
          200,
        ),
      ),
    );
    expect(
      () => api.sendRequest(fakeToken),
      throwsA(
        isA<ChallengeApiException>()
            .having((error) => error.code, 'code', 'blocked'),
      ),
    );
  });

  test('401 unauthorized is treated as missing sign-in', () async {
    final api = build(
      MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'unauthorized',
              'message': 'missing bearer token',
            },
          }),
          401,
        ),
      ),
    );
    expect(
      () => api.accountSnapshot(),
      throwsA(
        isA<ChallengeApiException>()
            .having((error) => error.isUnauthenticated, 'unauthenticated', true),
      ),
    );
  });

  test('accountSnapshot rotates a missing durable link instead of failing',
      () async {
    final actions = <String>[];
    final api = build(
      MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final action = body['action'] as String;
        actions.add(action);
        if (action == 'profile') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': <String, Object?>{
                'profile': <String, Object?>{
                  'id': fakeOwnerId,
                  'username': 'new_player',
                  'rating': 1000,
                  'ranked_wins': 0,
                  'ranked_battles': 0,
                },
                'link': null,
                'active_match_id': null,
              },
            }),
            200,
          );
        }
        expect(action, 'link_rotate');
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'link': <String, Object?>{
                'token': 'newlink12345',
                'code': 'newlink12345',
              },
            },
          }),
          200,
        );
      }),
    );

    final snapshot = await api.accountSnapshot();
    expect(actions, <String>['profile', 'link_rotate']);
    expect(snapshot.link.token, 'newlink12345');
    expect(snapshot.profile.username, 'new_player');
    expect(snapshot.activeMatchId, isNull);
  });

  test('accountSnapshot fails closed when rotation yields no link', () async {
    final api = build(
      MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        if (body['action'] == 'link_rotate') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': <String, Object?>{'link': null},
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'profile': <String, Object?>{'id': fakeOwnerId},
              'link': null,
            },
          }),
          200,
        );
      }),
    );
    expect(
      () => api.accountSnapshot(),
      throwsA(
        isA<ChallengeApiException>()
            .having((error) => error.code, 'code', 'malformed_response'),
      ),
    );
  });

  test('unconfigured backend throws not_configured without network', () async {
    var called = false;
    final api = build(
      MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
      configured: false,
    );
    expect(
      () => api.resolveLink(fakeToken),
      throwsA(
        isA<ChallengeApiException>()
            .having((error) => error.code, 'code', 'not_configured'),
      ),
    );
    expect(called, isFalse);
  });

  test('pendingOutgoingRequestTo reads inbox without creating anything',
      () async {
    final api = build(
      MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'requests': <Object?>[
                <String, Object?>{
                  'id': 'req-9',
                  'status': 'pending',
                  'expires_at': '2030-01-01T00:00:00.000Z',
                  'recipient': <String, Object?>{'id': fakeOwnerId},
                },
              ],
            },
          }),
          200,
        ),
      ),
    );
    final request = await api.pendingOutgoingRequestTo(fakeOwnerId);
    expect(request!.id, 'req-9');
    expect(request.status, ChallengeRequestStatus.pending);
  });

  test('trackEvent posts the analytics action', () async {
    late http.Request captured;
    final api = build(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{'data': <String, Object?>{'ok': true}}),
          200,
        );
      }),
    );
    await api.trackEvent('challenge_link_opened', <String, Object?>{
      'source': 'https',
    });
    final body = jsonDecode(captured.body) as Map<String, Object?>;
    expect(body['action'], 'analytics');
    final params = body['params'] as Map<String, Object?>;
    expect(params['event'], 'challenge_link_opened');
    expect((params['properties'] as Map<String, Object?>)['source'], 'https');
  });
}
