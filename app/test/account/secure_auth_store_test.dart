/// Secure session storage: authoritative secure reads, safe migration, failure
/// behavior and logout clearing (R10 / L03 review).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/auth/auth_store.dart';

/// In-memory secure store whose reads/writes/deletes can be forced to fail.
class _FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};
  bool failReads = false;
  bool failWrites = false;
  bool failDeletes = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) {
      throw StateError('secure read unavailable');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) {
      throw StateError('secure write unavailable');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) {
      throw StateError('secure delete unavailable');
    }
    values.remove(key);
  }
}

const String _legacySessionJson =
    '{"access_token":"legacy-access","user_id":"user-1",'
    '"refresh_token":"legacy-refresh"}';

const String _otherSessionJson =
    '{"access_token":"other-access","user_id":"user-2",'
    '"refresh_token":"other-refresh"}';

const String _secureSessionJson =
    '{"access_token":"access","user_id":"user-1",'
    '"refresh_token":"refresh"}';

ArenaAuthSession _session() => const ArenaAuthSession(
      accessToken: 'access',
      userId: 'user-1',
      refreshToken: 'refresh',
    );

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStore secure;

  setUp(() {
    secure = _FakeSecureStore();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('writes sessions and PKCE verifiers to the secure store only', () async {
    final store = SecureAuthSessionStore(secure: secure);

    await store.writeSession(_session());
    await store.writePkceVerifier('verifier-1');

    expect(secure.values.keys, contains(SecureAuthSessionStore.sessionKey));
    expect(secure.values.keys, contains(SecureAuthSessionStore.pkceKey));
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);

    final restored = await store.readSession();
    expect(restored?.accessToken, 'access');
    expect(restored?.refreshToken, 'refresh');
    expect(await store.readPkceVerifier(), 'verifier-1');
  });

  test('migrates a legacy plaintext session and removes it after verification',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);

    final session = await store.readSession();

    expect(session?.accessToken, 'legacy-access');
    expect(
      secure.values[SecureAuthSessionStore.sessionKey],
      _legacySessionJson,
    );
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
    );

    expect(await store.readPkceVerifier(), 'legacy-verifier');
    expect(secure.values[SecureAuthSessionStore.pkceKey], 'legacy-verifier');
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);
  });

  test('the secure value wins over a legacy plaintext identity', () async {
    secure.values[SecureAuthSessionStore.sessionKey] = _secureSessionJson;
    secure.values[SecureAuthSessionStore.pkceKey] = 'secure-verifier';
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _otherSessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);

    final session = await store.readSession();

    expect(session?.accessToken, 'access');
    expect(await store.readPkceVerifier(), 'secure-verifier');
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
      reason: 'leftover plaintext is cleaned up once secure data exists',
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);
  });

  test('a secure read failure never falls back to stale plaintext', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);
    secure.failReads = true;

    expect(await store.readSession(), isNull);
    expect(await store.readPkceVerifier(), isNull);
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      _legacySessionJson,
      reason: 'a read failure must not delete or shadow recoverable state',
    );
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.pkceKey),
      'legacy-verifier',
    );
  });

  test('a corrupt secure value is authoritative and blocks legacy fallback',
      () async {
    final store = SecureAuthSessionStore(secure: secure);
    secure.values[SecureAuthSessionStore.sessionKey] = 'not-json';
    secure.values[SecureAuthSessionStore.pkceKey] = '';
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });

    expect(await store.readSession(), isNull);
    expect(await store.readPkceVerifier(), isNull);
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      _legacySessionJson,
      reason: 'the corrupt secure value must not be replaced by plaintext',
    );
  });

  test('a secure write failure surfaces instead of falling back to plaintext',
      () async {
    final store = SecureAuthSessionStore(secure: secure);
    secure.failWrites = true;

    await expectLater(
      store.writeSession(_session()),
      throwsA(isA<AuthStorageException>()),
    );
    await expectLater(
      store.writePkceVerifier('verifier-1'),
      throwsA(isA<AuthStorageException>()),
    );

    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);
  });

  test('a failed migration keeps the legacy copy and still restores',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);
    secure.failWrites = true;

    final session = await store.readSession();

    expect(session?.accessToken, 'legacy-access');
    expect(await store.readPkceVerifier(), 'legacy-verifier');
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      _legacySessionJson,
    );
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.pkceKey),
      'legacy-verifier',
    );
    expect(secure.values, isEmpty);
  });

  test('a successful write removes the obsolete plaintext copy', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);

    await store.writeSession(_session());
    await store.writePkceVerifier('verifier-1');

    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);
  });

  test('clear removes the secure and legacy copies', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);
    await store.writeSession(_session());
    await store.writePkceVerifier('verifier-1');

    await store.clearSession();
    await store.clearPkceVerifier();

    expect(secure.values, isEmpty);
    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);
    expect(await store.readSession(), isNull);
  });

  test('a delete failure is reported and the legacy copy is still removed',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesAuthSessionStore.sessionKey: _legacySessionJson,
      SharedPreferencesAuthSessionStore.pkceKey: 'legacy-verifier',
    });
    final store = SecureAuthSessionStore(secure: secure);
    await store.writeSession(_session());
    await store.writePkceVerifier('verifier-1');
    secure.failDeletes = true;

    await expectLater(
      store.clearSession(),
      throwsA(isA<AuthStorageException>()),
    );
    await expectLater(
      store.clearPkceVerifier(),
      throwsA(isA<AuthStorageException>()),
    );

    final prefs = await _prefs();
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);
    expect(
      secure.values,
      isNotEmpty,
      reason: 'the fake refused the delete, so the secure copy remains',
    );
  });
}
