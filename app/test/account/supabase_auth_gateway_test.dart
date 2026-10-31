/// Supabase auth gateway tests.
///
/// These check the documented provider flow (email code, PKCE Google
/// redirect, refresh, logout) and that failures map to plain, safe messages.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/auth/auth_store.dart';
import 'package:training_arena/account/auth/supabase_auth_gateway.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/config/arena_config.dart';

const ArenaConfig _config = ArenaConfig(
  publicUrl: 'https://example.invalid',
  linkHost: 'example.invalid',
  supabaseUrl: 'https://project.invalid',
  supabaseAnonKey: 'anon-public',
  authRedirectUrl: 'trainingarena://auth',
);

class _FakeBrowser implements ArenaAuthBrowser {
  _FakeBrowser({this.result = true});

  bool result;
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return result;
  }
}

class _FakeRedirectLinks implements ArenaAuthRedirectLinks {
  Uri? initial;
  final StreamController<Uri> controller =
      StreamController<Uri>.broadcast(sync: true);

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => controller.stream;

  Future<void> close() => controller.close();
}

String _sessionBody({String userId = 'viewer-1'}) {
  return jsonEncode(<String, Object?>{
    'access_token': 'access-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-token',
    'user': <String, Object?>{'id': userId},
  });
}

void main() {
  late MemoryAuthSessionStore store;

  setUp(() {
    store = MemoryAuthSessionStore();
  });

  SupabaseAuthGateway gatewayWith(
    Future<http.Response> Function(http.Request request) handler, {
    ArenaConfig config = _config,
    _FakeBrowser? browser,
    _FakeRedirectLinks? links,
    DateTime Function()? now,
  }) {
    return SupabaseAuthGateway(
      config: config,
      store: store,
      client: MockClient(handler),
      browser: browser ?? _FakeBrowser(),
      links: links ?? _FakeRedirectLinks(),
      now: now,
    );
  }

  group('email code', () {
    test('requests the code without putting the address in the URL', () async {
      late http.Request captured;
      final gateway = gatewayWith((request) async {
        captured = request;
        return http.Response('{}', 200);
      });

      await gateway.requestEmailCode(' play@example.invalid ');

      expect(captured.url.path, '/auth/v1/otp');
      expect(captured.url.toString().contains('play@example.invalid'), isFalse);
      expect(
        jsonDecode(captured.body),
        <String, Object?>{'email': 'play@example.invalid', 'create_user': true},
      );
    });

    test('an expired code maps to a plain actionable message', () async {
      final gateway = gatewayWith((request) async {
        return http.Response(
          jsonEncode(<String, Object?>{'error_code': 'otp_expired'}),
          400,
        );
      });

      await expectLater(
        gateway.verifyEmailCode(email: 'a@b.co', code: '123456'),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'code_invalid')
              .having((e) => e.message.contains('@'), 'leaks address', isFalse),
        ),
      );
    });

    test('a too-short code is rejected without a request', () async {
      var called = false;
      final gateway = gatewayWith((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        gateway.verifyEmailCode(email: 'a@b.co', code: '12'),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'code_invalid'),
        ),
      );
      expect(called, isFalse);
    });

    test('a successful verify persists the session', () async {
      final gateway = gatewayWith(
        (request) async => http.Response(_sessionBody(), 200),
      );

      final session = await gateway.verifyEmailCode(
        email: 'a@b.co',
        code: '123456',
      );

      expect(session.userId, 'viewer-1');
      expect(session.refreshToken, 'refresh-token');
      expect(await store.readSession(), session);
    });
  });

  group('Google PKCE redirect', () {
    test(
      'clearing a browser wait rejects late callback before token exchange',
      () async {
        final links = _FakeRedirectLinks();
        addTearDown(links.close);
        final browser = _FakeBrowser();
        var tokenRequests = 0;
        final gateway = gatewayWith(
          (request) async {
            tokenRequests += 1;
            return http.Response(_sessionBody(), 200);
          },
          browser: browser,
          links: links,
        );
        final waiting = gateway.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        expect(browser.opened, hasLength(1));
        await gateway.clearLocalAuth();
        links.controller.add(Uri.parse('trainingarena://auth?code=late-code'));
        await expectLater(waiting, throwsA(isA<AccountException>()));
        expect(tokenRequests, 0);
        expect(await store.readPkceVerifier(), isNull);
        expect(await store.readSession(), isNull);

        final retry = gateway.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        links.controller.add(Uri.parse('trainingarena://auth?code=fresh-code'));
        await retry;
        expect(tokenRequests, 1);
        expect((await store.readSession())?.userId, 'viewer-1');
      },
    );

    test('fails closed when no redirect is configured', () async {
      final gateway = gatewayWith(
        (request) async => http.Response('{}', 200),
        config: const ArenaConfig(
          publicUrl: 'https://example.invalid',
          linkHost: 'example.invalid',
          supabaseUrl: 'https://project.invalid',
          supabaseAnonKey: 'anon-public',
        ),
      );

      await expectLater(
        gateway.signInWithGoogle(),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'unconfigured'),
        ),
      );
      expect(await store.readPkceVerifier(), isNull);
    });

    test('a failed browser launch cancels cleanly and clears the verifier',
        () async {
      final links = _FakeRedirectLinks();
      final gateway = gatewayWith(
        (request) async => http.Response(_sessionBody(), 200),
        browser: _FakeBrowser(result: false),
        links: links,
      );

      await expectLater(
        gateway.signInWithGoogle(),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'browser_unavailable'),
        ),
      );
      expect(await store.readPkceVerifier(), isNull);
      await links.close();
    });

    test('an interrupted redirect is finished from the initial link', () async {
      await store.writePkceVerifier('stored-verifier');
      final links = _FakeRedirectLinks()
        ..initial = Uri.parse('trainingarena://auth?code=auth-code');
      late http.Request captured;
      final gateway = gatewayWith(
        (request) async {
          captured = request;
          return http.Response(_sessionBody(), 200);
        },
        links: links,
      );

      final session = await gateway.restoreSession();

      expect(session, isNotNull);
      expect(captured.url.path, '/auth/v1/token');
      expect(captured.url.query, 'grant_type=pkce');
      expect(
        jsonDecode(captured.body),
        <String, Object?>{
          'auth_code': 'auth-code',
          'code_verifier': 'stored-verifier',
        },
      );
      expect(await store.readPkceVerifier(), isNull);
      await links.close();
    });
  });

  group('restore and refresh', () {
    test('no stored session restores to null', () async {
      final gateway = gatewayWith((request) async => http.Response('{}', 200));
      expect(await gateway.restoreSession(), isNull);
    });

    test('a fresh stored session is returned without a network call', () async {
      var called = false;
      final gateway = gatewayWith((request) async {
        called = true;
        return http.Response('{}', 200);
      });
      final session = ArenaAuthSession(
        accessToken: 'stored',
        userId: 'viewer-1',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await store.writeSession(session);

      expect(await gateway.restoreSession(), session);
      expect(called, isFalse);
    });

    test('an expired session refreshes and persists the new tokens', () async {
      await store.writeSession(
        ArenaAuthSession(
          accessToken: 'old',
          userId: 'viewer-1',
          refreshToken: 'refresh',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      final gateway = gatewayWith(
        (request) async => http.Response(_sessionBody(), 200),
      );

      final session = await gateway.restoreSession();

      expect(session, isNotNull);
      expect(session!.accessToken, 'access-token');
      expect(await store.readSession(), session);
    });

    test('an expired session without a refresh token clears and reports null',
        () async {
      await store.writeSession(
        ArenaAuthSession(
          accessToken: 'old',
          userId: 'viewer-1',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      final gateway = gatewayWith((request) async => http.Response('{}', 200));

      expect(await gateway.restoreSession(), isNull);
      expect(await store.readSession(), isNull);
    });

    test('a refused refresh maps to expired and clears the store', () async {
      final gateway = gatewayWith(
        (request) async => http.Response(
          jsonEncode(<String, Object?>{'error': 'invalid_grant'}),
          400,
        ),
      );

      await expectLater(
        gateway.refreshSession(
          const ArenaAuthSession(
            accessToken: 'old',
            userId: 'viewer-1',
            refreshToken: 'refresh',
          ),
        ),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'expired'),
        ),
      );
      expect(await store.readSession(), isNull);
    });
  });

  group('sign-out', () {
    test('clears local state first and posts a best-effort logout', () async {
      late http.Request captured;
      final gateway = gatewayWith((request) async {
        captured = request;
        return http.Response('{}', 204);
      });
      await store.writeSession(
        const ArenaAuthSession(
          accessToken: 'access',
          userId: 'viewer-1',
          refreshToken: 'refresh',
        ),
      );

      await gateway.signOut(
        const ArenaAuthSession(accessToken: 'access', userId: 'viewer-1'),
      );

      expect(await store.readSession(), isNull);
      expect(captured.url.path, '/auth/v1/logout');
      expect(captured.headers['authorization'], 'Bearer access');
    });

    test('a network failure during logout still signs the user out locally',
        () async {
      final gateway = gatewayWith((request) async {
        throw http.ClientException('offline');
      });

      await gateway.signOut(
        const ArenaAuthSession(accessToken: 'access', userId: 'viewer-1'),
      );

      expect(await store.readSession(), isNull);
    });
  });

  group('secure storage failure', () {
    test('a failed secure write fails sign-in closed with a plain message',
        () async {
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: _WriteFailingStore(),
        client: MockClient((request) async {
          return http.Response(_sessionBody(), 200);
        }),
        browser: _FakeBrowser(),
        links: _FakeRedirectLinks(),
      );

      await expectLater(
        gateway.verifyEmailCode(email: 'a@b.co', code: '123456'),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'storage')
              .having(
                (e) => e.message.contains('securely'),
                'plain message',
                isTrue,
              ),
        ),
      );
    });
  });

  group('durable sign-out and PKCE retention', () {
    test('a local clear failure still revokes server-side and is reported',
        () async {
      late http.Request captured;
      final failing = _DeleteFailingStore();
      await failing.writeSession(
        const ArenaAuthSession(accessToken: 'access', userId: 'viewer-1'),
      );
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: failing,
        client: MockClient((request) async {
          captured = request;
          return http.Response('{}', 204);
        }),
        browser: _FakeBrowser(),
        links: _FakeRedirectLinks(),
      );

      await expectLater(
        gateway.signOut(
          const ArenaAuthSession(accessToken: 'access', userId: 'viewer-1'),
        ),
        throwsA(isA<AuthStorageException>()),
      );

      expect(captured.url.path, '/auth/v1/logout');
      expect(
        await failing.readSession(),
        isNotNull,
        reason: 'the refused delete leaves a restorable token, so this must '
            'not be reported as a durable sign-out',
      );
    });

    test(
        'a consumed authorization code is not retried after a storage failure',
        () async {
      final failing = _WriteFailingStore();
      final links = _FakeRedirectLinks()
        ..initial = Uri.parse('trainingarena://auth?code=abc');
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: failing,
        client: MockClient((request) async {
          return http.Response(_sessionBody(), 200);
        }),
        browser: _FakeBrowser(),
        links: links,
      );
      await failing.writePkceVerifier('verifier-1');

      final restored = await gateway.restoreSession();

      expect(restored, isNull);
      expect(
        await failing.readPkceVerifier(),
        isNull,
        reason: 'the token exchange consumed the single-use code; the user '
            'must start a fresh sign-in instead of replaying this redirect',
      );
    });

    test('a retryable transport failure keeps the verifier for a later retry',
        () async {
      await store.writePkceVerifier('stored-verifier');
      final links = _FakeRedirectLinks()
        ..initial = Uri.parse('trainingarena://auth?code=auth-code');
      var attempts = 0;
      final gateway = gatewayWith(
        (request) async {
          attempts += 1;
          if (attempts == 1) {
            throw http.ClientException('offline');
          }
          return http.Response(_sessionBody(), 200);
        },
        links: links,
      );

      expect(await gateway.restoreSession(), isNull);
      expect(
        await store.readPkceVerifier(),
        'stored-verifier',
        reason: 'a transport failure must not consume the pending sign-in',
      );

      final session = await gateway.restoreSession();
      expect(session?.userId, 'viewer-1');
      expect(await store.readPkceVerifier(), isNull);
      await links.close();
    });

    test('a retryable server error keeps the verifier for a later retry',
        () async {
      await store.writePkceVerifier('stored-verifier');
      final links = _FakeRedirectLinks()
        ..initial = Uri.parse('trainingarena://auth?code=auth-code');
      final gateway = gatewayWith(
        (request) async => http.Response('unavailable', 503),
        links: links,
      );

      expect(await gateway.restoreSession(), isNull);
      expect(await store.readPkceVerifier(), 'stored-verifier');
      await links.close();
    });
  });
}

class _DeleteFailingStore extends MemoryAuthSessionStore {
  @override
  Future<void> clearSession() async {
    throw const AuthStorageException('secure delete unavailable');
  }
}

class _WriteFailingStore extends MemoryAuthSessionStore {
  @override
  Future<void> writeSession(ArenaAuthSession session) async {
    throw const AuthStorageException('secure storage unavailable');
  }
}
