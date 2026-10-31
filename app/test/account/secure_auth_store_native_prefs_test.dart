/// Native plaintext-removal failure regressions for [SecureAuthSessionStore].
///
/// These exercise the real `SharedPreferences` legacy path through its
/// platform method-channel seam (`SharedPreferencesStorePlatform`), so a
/// refused native removal is reproduced without a production abstraction.
/// `SharedPreferences.resetStatic()` gives each test a fresh persisted view.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/account/auth/auth_store.dart';

const MethodChannel _prefsChannel =
    MethodChannel('plugins.flutter.io/shared_preferences');

const String _legacySessionJson =
    '{"access_token":"legacy-access","user_id":"user-1",'
    '"refresh_token":"legacy-refresh"}';

/// In-memory secure store whose deletes can be forced to fail.
class _FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

/// Fake native preference store behind the platform method channel.
class _NativePrefs {
  final Map<String, Object> data = <String, Object>{};
  bool failRemoves = false;
  bool throwOnRemoves = false;
  bool failGetAll = false;
  int removeCalls = 0;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_prefsChannel, _handle);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_prefsChannel, null);
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'getAll':
        if (failGetAll) {
          throw PlatformException(code: 'prefs_unavailable');
        }
        return Map<String, Object>.from(data);
      case 'setString':
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        data[args['key']! as String] = args['value']!;
        return true;
      case 'remove':
        removeCalls += 1;
        if (throwOnRemoves) {
          throw PlatformException(code: 'remove_failed');
        }
        if (failRemoves) {
          return false;
        }
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        data.remove(args['key']! as String);
        return true;
      case 'clear':
        data.clear();
        return true;
    }
    throw MissingPluginException(call.method);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _NativePrefs native;

  setUp(() {
    SharedPreferences.resetStatic();
    native = _NativePrefs()..install();
  });

  tearDown(() {
    native.uninstall();
    SharedPreferences.resetStatic();
  });

  Future<void> seed(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void refuseRemoval({required bool thrown}) {
    native.failRemoves = !thrown;
    native.throwOnRemoves = thrown;
  }

  void allowRemoval() {
    native.failRemoves = false;
    native.throwOnRemoves = false;
  }

  for (final thrown in <bool>[false, true]) {
    final label = thrown ? 'thrown' : 'false';
    test('a $label native removal fails session clear, then retries on the '
        'same cached store', () async {
      await seed(
        SharedPreferencesAuthSessionStore.sessionKey,
        _legacySessionJson,
      );
      refuseRemoval(thrown: thrown);
      final store = SecureAuthSessionStore(secure: _FakeSecureStore());

      await expectLater(
        store.clearSession(),
        throwsA(isA<AuthStorageException>()),
        reason: 'a durable clear must not claim success while plaintext remains',
      );
      expect(
        native.data.containsValue(_legacySessionJson),
        isTrue,
        reason: 'the native refusal must not be disclosed as a cleared value',
      );

      // Retry on the same store and cached preferences: the reload restores
      // the cache entry that SharedPreferences dropped before the failed write.
      allowRemoval();
      await store.clearSession();

      SharedPreferences.resetStatic();
      final disk = await SharedPreferences.getInstance();
      expect(
        disk.getString(SharedPreferencesAuthSessionStore.sessionKey),
        isNull,
        reason: 'the retry must have actually removed the persisted value',
      );
    });

    test('a $label native removal fails PKCE clear, then retries on the same '
        'cached store', () async {
      await seed(SharedPreferencesAuthSessionStore.pkceKey, 'legacy-verifier');
      refuseRemoval(thrown: thrown);
      final store = SecureAuthSessionStore(secure: _FakeSecureStore());

      await expectLater(
        store.clearPkceVerifier(),
        throwsA(isA<AuthStorageException>()),
      );
      expect(native.data.containsValue('legacy-verifier'), isTrue);

      allowRemoval();
      await store.clearPkceVerifier();

      SharedPreferences.resetStatic();
      final disk = await SharedPreferences.getInstance();
      expect(
        disk.getString(SharedPreferencesAuthSessionStore.pkceKey),
        isNull,
      );
    });
  }

  test('an unavailable preference store fails the clear closed', () async {
    native.failGetAll = true;
    final store = SecureAuthSessionStore(secure: _FakeSecureStore());

    await expectLater(
      store.clearSession(),
      throwsA(isA<AuthStorageException>()),
    );
    await expectLater(
      store.clearPkceVerifier(),
      throwsA(isA<AuthStorageException>()),
    );
  });

  test('an unavailable reload fails the clear closed', () async {
    // Initialize the singleton while the platform still answers, then break
    // the fresh persisted read that the retry depends on.
    await SharedPreferences.getInstance();
    native.failGetAll = true;
    final store = SecureAuthSessionStore(secure: _FakeSecureStore());

    await expectLater(
      store.clearSession(),
      throwsA(isA<AuthStorageException>()),
    );
    await expectLater(
      store.clearPkceVerifier(),
      throwsA(isA<AuthStorageException>()),
    );
  });
}
