/// Durable sign-out and deletion through the real gateway, secure store and
/// controller boundaries (L03 review).
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/auth/auth_store.dart';
import 'package:training_arena/account/auth/supabase_auth_gateway.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/account/runtime/account_controller.dart';
import 'package:training_arena/config/arena_config.dart';

import 'fakes.dart';

const ArenaConfig _config = ArenaConfig(
  publicUrl: 'https://example.invalid',
  linkHost: 'example.invalid',
  supabaseUrl: 'https://project.invalid',
  supabaseAnonKey: 'anon-public',
  authRedirectUrl: 'trainingarena://auth',
);

class _FakeBrowser implements ArenaAuthBrowser {
  @override
  Future<bool> open(Uri url) async => true;
}

class _NoLinks implements ArenaAuthRedirectLinks {
  @override
  Future<Uri?> initialLink() async => null;

  @override
  Stream<Uri> get links => const Stream<Uri>.empty();
}

/// Secure store whose deletes always fail, so durable cleanup cannot succeed.
class _DeleteFailingSecure implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    throw StateError('secure delete refused');
  }
}

String _sessionBody() => jsonEncode(<String, Object?>{
      'access_token': 'access',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh',
      'user': <String, Object?>{'id': 'viewer-1'},
    });

Future<AccountController> _signedInController({
  required SecureAuthSessionStore store,
  required FakeAccountApi api,
}) async {
  final gateway = SupabaseAuthGateway(
    config: _config,
    store: store,
    client: MockClient((request) async => http.Response(_sessionBody(), 200)),
    browser: _FakeBrowser(),
    links: _NoLinks(),
  );
  final controller = AccountController(auth: gateway, api: api);
  await controller.verifyEmailCode(email: 'a@b.co', code: '123456');
  return controller;
}

void main() {
  test('signOut reports a durable failure when the secure copy cannot be erased',
      () async {
    final secure = _DeleteFailingSecure();
    final store = SecureAuthSessionStore(secure: secure);
    final controller = await _signedInController(
      store: store,
      api: FakeAccountApi(),
    );
    expect(controller.signedIn, isTrue);

    await controller.signOut();

    expect(controller.status, AccountStatus.signedOut);
    expect(controller.notice, contains('could not erase'));
    expect(
      await store.readSession(),
      isNotNull,
      reason: 'the refused delete means a restart could restore the token',
    );
  });

  test('deleteAccount does not claim durable removal when storage fails',
      () async {
    final secure = _DeleteFailingSecure();
    final store = SecureAuthSessionStore(secure: secure);
    final api = FakeAccountApi();
    final controller = await _signedInController(store: store, api: api);

    await controller.deleteAccount();

    expect(api.deleteCalls, 1);
    expect(controller.status, AccountStatus.signedOut);
    expect(controller.notice, contains('could not erase'));
    expect(await store.readSession(), isNotNull);
  });

  test('a failed server deletion keeps the valid session', () async {
    final secure = _DeleteFailingSecure();
    final store = SecureAuthSessionStore(secure: secure);
    final api = FakeAccountApi()..deleteError = const AccountException.network();
    final controller = await _signedInController(store: store, api: api);

    await expectLater(
      controller.deleteAccount(),
      throwsA(isA<AccountException>()),
    );

    expect(controller.signedIn, isTrue);
    expect(await store.readSession(), isNotNull);
  });
}
