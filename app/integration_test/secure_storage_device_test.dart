/// On-device exercise of the real Android Keystore-backed session store.
///
/// Scope: verifies that `SecureAuthSessionStore` writes, reads (including from
/// a fresh instance), migrates legacy plaintext and clears through the real
/// `flutter_secure_storage` platform implementation.
///
/// Isolation: every value lives in a dedicated secure-storage namespace and a
/// prefixed SharedPreferences namespace, so the test can never read, overwrite
/// or delete a real user's credential. It uses only synthetic values.
///
/// This runs on an emulator or a physical device and is a functional check of
/// the platform implementation, NOT hardware-security certification and not a
/// claim about hardware-backed key attestation. Emulator coverage is reported
/// separately from any physical-hardware result.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/auth/auth_store.dart';

/// Dedicated namespaces; never the production app namespace.
const String _secureNamespace = 'arena_device_test';
const String _prefsPrefix = 'arena.device.test.';

const FlutterSecureStorage _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    resetOnError: false,
    storageNamespace: _secureNamespace,
  ),
);

const FlutterSecureStorage _secondStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    resetOnError: false,
    storageNamespace: _secureNamespace,
  ),
);

SecureAuthSessionStore _isolatedStore() => SecureAuthSessionStore(
      secure: FlutterSecureKeyValueStore(storage: _storage),
    );

/// Clears only the isolated test keys; never deletes the whole app store.
Future<void> _clearIsolated() async {
  await _storage.delete(key: SecureAuthSessionStore.sessionKey);
  await _storage.delete(key: SecureAuthSessionStore.pkceKey);
  await _storage.delete(key: 'arena.device.probe');
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(SharedPreferencesAuthSessionStore.sessionKey);
  await prefs.remove(SharedPreferencesAuthSessionStore.pkceKey);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Prefix every legacy preference read/write so the migration path touches
    // a synthetic namespace instead of the installed app's real values.
    SharedPreferences.setPrefix(_prefsPrefix);
  });

  testWidgets('real secure storage round-trips and clears (isolated)',
      (tester) async {
    await _clearIsolated();

    // Direct plugin probe within the test namespace: a value written through
    // one instance survives a second instance and is removable.
    await _storage.write(key: 'arena.device.probe', value: 'probe-1');
    expect(await _storage.read(key: 'arena.device.probe'), 'probe-1');
    expect(await _secondStorage.read(key: 'arena.device.probe'), 'probe-1');
    await _storage.delete(key: 'arena.device.probe');
    expect(await _storage.read(key: 'arena.device.probe'), isNull);

    final store = _isolatedStore();
    await store.clearSession();
    await store.clearPkceVerifier();

    const session = ArenaAuthSession(
      accessToken: 'device-probe-access',
      userId: 'device-probe',
      refreshToken: 'device-probe-refresh',
    );
    await store.writeSession(session);
    await store.writePkceVerifier('device-probe-verifier');

    final read = await store.readSession();
    expect(read?.accessToken, 'device-probe-access');
    expect(read?.refreshToken, 'device-probe-refresh');
    expect(await store.readPkceVerifier(), 'device-probe-verifier');

    // A fresh store instance reads the same persisted Keystore values.
    final secondStore = _isolatedStore();
    expect((await secondStore.readSession())?.userId, 'device-probe');

    await store.clearSession();
    await store.clearPkceVerifier();
    expect(await store.readSession(), isNull);
    expect(await store.readPkceVerifier(), isNull);
  });

  testWidgets(
      'legacy plaintext migrates to isolated secure storage and is removed',
      (tester) async {
    await _clearIsolated();
    final store = _isolatedStore();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SharedPreferencesAuthSessionStore.sessionKey,
      '{"access_token":"legacy-access","user_id":"legacy-user"}',
    );
    await prefs.setString(
      SharedPreferencesAuthSessionStore.pkceKey,
      'legacy-verifier',
    );

    final migrated = await store.readSession();
    expect(migrated?.accessToken, 'legacy-access');
    expect(await store.readPkceVerifier(), 'legacy-verifier');
    expect(
      prefs.getString(SharedPreferencesAuthSessionStore.sessionKey),
      isNull,
      reason: 'plaintext is removed only after the secure copy is verified',
    );
    expect(prefs.getString(SharedPreferencesAuthSessionStore.pkceKey), isNull);

    final secondStore = _isolatedStore();
    expect((await secondStore.readSession())?.userId, 'legacy-user');

    await store.clearSession();
    await store.clearPkceVerifier();
  });
}
