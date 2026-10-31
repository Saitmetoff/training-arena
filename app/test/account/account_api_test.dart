/// HTTP account API tests over the documented arena envelope.
///
/// The client must fail closed: malformed rows are dropped, error messages
/// never carry an email or token back to the UI, and no request uses a body
/// field as a user id.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:training_arena/account/data/account_api.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/domain/arena_types.dart';

const ArenaConfig _config = ArenaConfig(
  publicUrl: 'https://example.invalid',
  linkHost: 'example.invalid',
  supabaseUrl: 'https://project.invalid',
  supabaseAnonKey: 'anon-public',
);

void main() {
  HttpAccountApi apiWith(
    Future<http.Response> Function(http.Request request) handler, {
    Future<String?> Function()? token,
    ArenaConfig config = _config,
  }) {
    return HttpAccountApi(
      config: config,
      accessTokenProvider: token ?? () async => 'access-token',
      client: MockClient(handler),
    );
  }

  group('envelope and transport', () {
    test('fetchProfile posts the action envelope with bearer and anon key',
        () async {
      late http.Request captured;
      final api = apiWith((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'profile': <String, Object?>{
                'id': 'viewer-1',
                'username': 'azizbek',
                'avatar_url': null,
                'rating': 1016,
                'ranked_wins': 3,
                'ranked_battles': 5,
              },
            },
          }),
          200,
        );
      });

      final profile = await api.fetchProfile();

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'https://project.invalid/functions/v1/arena');
      expect(captured.headers['authorization'], 'Bearer access-token');
      expect(captured.headers['apikey'], 'anon-public');
      expect(
        jsonDecode(captured.body),
        <String, Object?>{'action': 'profile', 'params': <String, Object?>{}},
      );
      expect(profile.id, 'viewer-1');
      expect(profile.username, 'azizbek');
      expect(profile.rating, 1016);
      expect(profile.rankedWins, 3);
      expect(profile.rankedBattles, 5);
    });

    test('unconfigured builds never touch the network', () async {
      var called = false;
      final api = apiWith(
        (request) async {
          called = true;
          return http.Response('{}', 200);
        },
        config: const ArenaConfig(
          publicUrl: '',
          linkHost: '',
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
      );

      await expectLater(
        api.fetchProfile(),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'unconfigured'),
        ),
      );
      expect(called, isFalse);
    });

    test('a missing token fails closed as unauthenticated', () async {
      final api = apiWith(
        (request) async => http.Response('{}', 200),
        token: () async => null,
      );

      await expectLater(
        api.fetchProfile(),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'unauthenticated')
              .having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue),
        ),
      );
    });

    test('transport failures surface as retryable network errors', () async {
      final api = apiWith((request) async {
        throw const SocketException('offline');
      });

      await expectLater(
        api.fetchProfile(),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'network')
              .having((e) => e.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });

    test('a TLS handshake failure is an offline retry, not a raw IO error',
        () async {
      final api = apiWith((request) async {
        throw const HandshakeException('certificate rejected');
      });

      await expectLater(
        api.fetchProfile(),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'network')
              .having((e) => e.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });

    test('401 answers are unauthenticated; 500 answers are retryable', () async {
      final unauthorized = apiWith((request) async => http.Response('{}', 401));
      final serverError = apiWith((request) async => http.Response('{}', 500));

      await expectLater(
        unauthorized.fetchProfile(),
        throwsA(
          isA<AccountException>()
              .having((e) => e.isUnauthenticated, 'isUnauthenticated', isTrue),
        ),
      );
      await expectLater(
        serverError.fetchProfile(),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'internal_error')
              .having((e) => e.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });

    test('business errors use the server code and actionable copy', () async {
      final api = apiWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'username_taken',
              'message': 'username already exists for a@b.co',
            },
          }),
          200,
        );
      });

      await expectLater(
        api.updateUsername('taken_name'),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'username_taken')
              .having((e) => e.message, 'message', 'That username is taken. Try another.')
              .having(
                (e) => e.message.contains('@'),
                'leaks an address',
                isFalse,
              ),
        ),
      );
    });

    test('server messages mentioning tokens are replaced', () async {
      final api = apiWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'internal_error',
              'message': 'bearer token rejected for session',
            },
          }),
          200,
        );
      });

      await expectLater(
        api.fetchProfile(),
        throwsA(
          isA<AccountException>().having(
            (e) => e.message.toLowerCase().contains('token'),
            'mentions token',
            isFalse,
          ),
        ),
      );
    });
  });

  group('profile mutations', () {
    test('profile_update normalizes nothing and sends the given name',
        () async {
      late http.Request captured;
      final api = apiWith((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'profile': <String, Object?>{'id': 'viewer-1', 'username': 'Kokoro_2'},
            },
          }),
          200,
        );
      });

      final profile = await api.updateUsername('Kokoro_2');
      expect(
        jsonDecode(captured.body),
        <String, Object?>{
          'action': 'profile_update',
          'params': <String, Object?>{'username': 'Kokoro_2'},
        },
      );
      expect(profile.username, 'Kokoro_2');
      expect(profile.rating, arenaStartingRating);
    });

    test('avatar_update sends base64 and mime_type from the picker', () async {
      late http.Request captured;
      final api = apiWith((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'profile': <String, Object?>{
                'id': 'viewer-1',
                'username': 'azizbek',
                'avatar_url': 'https://cdn.invalid/a.jpg',
              },
            },
          }),
          200,
        );
      });

      final profile = await api.updateAvatar(
        base64: 'ZmFrZQ==',
        mimeType: 'image/jpeg',
      );
      expect(
        jsonDecode(captured.body),
        <String, Object?>{
          'action': 'avatar_update',
          'params': <String, Object?>{
            'base64': 'ZmFrZQ==',
            'mime_type': 'image/jpeg',
          },
        },
      );
      expect(profile.avatarUrl, 'https://cdn.invalid/a.jpg');
    });
  });

  group('leaderboard and history parsing', () {
    test('leaderboard keeps only rows with an id and a positive rank', () async {
      final api = apiWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'profiles': <Object?>[
                <String, Object?>{
                  'id': 'rank-1',
                  'username': 'alpha',
                  'rating': 1100,
                  'rank': 1,
                },
                <String, Object?>{
                  'id': 'rank-2',
                  'username': 'beta',
                  'rating': 1080,
                  'rank': 2,
                },
                <String, Object?>{'username': 'no-id', 'rank': 3},
                <String, Object?>{'id': 'no-rank', 'username': 'x'},
                <String, Object?>{'id': 'bad-rank', 'rank': 0},
              ],
            },
          }),
          200,
        );
      });

      final entries = await api.leaderboard();
      expect(entries.length, 2);
      expect(entries.first.rank, 1);
      expect(entries.first.profile.username, 'alpha');
      expect(entries.last.profile.rating, 1080);
    });

    test('history parses a ranked receipt and drops malformed rows', () async {
      final api = apiWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'receipts': <Object?>[
                <String, Object?>{
                  'id': 'receipt-1',
                  'match_id': 'match-1',
                  'exercise': 'pushups',
                  'mode': 'ranked',
                  'outcome': 'win',
                  'winner_id': 'viewer-1',
                  'finished_at': '2026-09-18T12:00:00+00:00',
                  'players': <Object?>[
                    <String, Object?>{
                      'id': 'viewer-1',
                      'username': 'azizbek',
                      'score': 26,
                      'rating_after': 1024,
                      'rating_change': 8,
                    },
                    <String, Object?>{
                      'id': 'opponent-2',
                      'username': 'zuhra',
                      'score': 23,
                      'rating_after': 992,
                      'rating_change': -8,
                    },
                  ],
                },
                <String, Object?>{'id': 'broken'},
                <String, Object?>{
                  'id': 'casual-1',
                  'match_id': 'match-2',
                  'exercise': 'squats',
                  'mode': 'casual',
                  'outcome': 'draw',
                  'players': <Object?>[
                    <String, Object?>{'id': 'viewer-1', 'score': 20},
                    <String, Object?>{'id': 'opponent-2', 'score': 20},
                  ],
                },
              ],
            },
          }),
          200,
        );
      });

      final receipts = await api.history();
      expect(receipts.length, 2);
      final ranked = receipts.first;
      expect(ranked.exercise, ArenaExercise.pushUps);
      expect(ranked.mode, ArenaMatchMode.ranked);
      expect(ranked.winnerId, 'viewer-1');
      expect(ranked.players.first.ratingChange, 8);
      final casual = receipts.last;
      expect(casual.mode, ArenaMatchMode.casual);
      expect(casual.players.first.ratingChange, isNull);
      expect(casual.players.first.ratingAfter, isNull);
    });

    test('a win without a winner id is dropped', () async {
      final api = apiWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'receipts': <Object?>[
                <String, Object?>{
                  'id': 'receipt-1',
                  'match_id': 'match-1',
                  'exercise': 'pushups',
                  'mode': 'ranked',
                  'outcome': 'win',
                  'players': <Object?>[
                    <String, Object?>{'id': 'viewer-1', 'score': 26},
                    <String, Object?>{'id': 'opponent-2', 'score': 23},
                  ],
                },
              ],
            },
          }),
          200,
        );
      });

      expect(await api.history(), isEmpty);
    });
  });

  group('public profile, report and block', () {
    test('publicProfile never surfaces extra private fields', () async {
      final api = apiWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'profile': <String, Object?>{
                'id': 'opponent-2',
                'username': 'zuhra',
                'avatar_url': null,
                'rating': 1060,
                'ranked_wins': 3,
                'ranked_battles': 4,
                'email': 'zuhra@private.invalid',
                'access_token': 'secret-token',
              },
            },
          }),
          200,
        );
      });

      final profile = await api.publicProfile('opponent-2');
      expect(profile.username, 'zuhra');
      expect(profile.rating, 1060);
      expect(profile.toString().contains('private'), isFalse);
      expect(profile.toString().contains('secret'), isFalse);
    });

    test('report sends target, optional match and the reason', () async {
      late http.Request captured;
      final api = apiWith((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{'data': <String, Object?>{'ok': true}}),
          200,
        );
      });

      await api.report(
        targetUserId: 'opponent-2',
        matchId: 'match-1',
        reason: 'used inappropriate name',
      );
      expect(
        jsonDecode(captured.body),
        <String, Object?>{
          'action': 'report',
          'params': <String, Object?>{
            'target_user_id': 'opponent-2',
            'match_id': 'match-1',
            'reason': 'used inappropriate name',
          },
        },
      );
    });

    test('block, unblock and blocked use the documented actions', () async {
      final actions = <String>[];
      final api = apiWith((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        actions.add(body['action']! as String);
        if (body['action'] == 'blocked') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': <String, Object?>{
                'profiles': <Object?>[
                  <String, Object?>{'id': 'opponent-2', 'username': 'zuhra'},
                ],
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode(<String, Object?>{'data': <String, Object?>{'ok': true}}),
          200,
        );
      });

      await api.block('opponent-2');
      await api.unblock('opponent-2');
      final blocked = await api.blocked();

      expect(actions, <String>['block', 'unblock', 'blocked']);
      expect(blocked.single.username, 'zuhra');
    });

    test('deleteAccount posts the documented action', () async {
      late http.Request captured;
      final api = apiWith((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{'data': <String, Object?>{'ok': true}}),
          200,
        );
      });

      await api.deleteAccount();
      expect(
        jsonDecode(captured.body),
        <String, Object?>{
          'action': 'delete_account',
          'params': <String, Object?>{},
        },
      );
    });
  });
}
