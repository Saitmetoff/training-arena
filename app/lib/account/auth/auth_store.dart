/// Durable auth session and PKCE state.
///
/// Only the session tokens and the one in-flight PKCE verifier are stored;
/// the email address used for a code is never persisted or logged.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_auth.dart';

/// Storage behind the auth gateway so tests can run entirely in memory.
abstract class AuthSessionStore {
  Future<ArenaAuthSession?> readSession();

  Future<void> writeSession(ArenaAuthSession session);

  Future<void> clearSession();

  Future<String?> readPkceVerifier();

  Future<void> writePkceVerifier(String verifier);

  Future<void> clearPkceVerifier();
}

/// Deterministic in-memory store.
class MemoryAuthSessionStore implements AuthSessionStore {
  ArenaAuthSession? _session;
  String? _verifier;

  @override
  Future<ArenaAuthSession?> readSession() async => _session;

  @override
  Future<void> writeSession(ArenaAuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<String?> readPkceVerifier() async => _verifier;

  @override
  Future<void> writePkceVerifier(String verifier) async {
    _verifier = verifier;
  }

  @override
  Future<void> clearPkceVerifier() async {
    _verifier = null;
  }
}

/// SharedPreferences-backed store with a memory fallback so the shell keeps
/// working when the platform channel is unavailable.
class SharedPreferencesAuthSessionStore implements AuthSessionStore {
  SharedPreferencesAuthSessionStore({MemoryAuthSessionStore? fallback})
      : _fallback = fallback ?? MemoryAuthSessionStore();

  static const String sessionKey = 'arena.auth.session.v1';
  static const String pkceKey = 'arena.auth.pkce.v1';

  final MemoryAuthSessionStore _fallback;
  SharedPreferences? _prefs;
  bool _prefsUnavailable = false;

  Future<SharedPreferences?> _open() async {
    if (_prefsUnavailable) {
      return null;
    }
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      return prefs;
    } catch (_) {
      _prefsUnavailable = true;
      return null;
    }
  }

  @override
  Future<ArenaAuthSession?> readSession() async {
    final prefs = await _open();
    final raw = prefs?.getString(sessionKey);
    if (raw == null) {
      return _fallback.readSession();
    }
    try {
      return _sessionFromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeSession(ArenaAuthSession session) async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.writeSession(session);
    }
    await prefs.setString(sessionKey, jsonEncode(_sessionToJson(session)));
  }

  @override
  Future<void> clearSession() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.clearSession();
    }
    await prefs.remove(sessionKey);
  }

  @override
  Future<String?> readPkceVerifier() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.readPkceVerifier();
    }
    return prefs.getString(pkceKey);
  }

  @override
  Future<void> writePkceVerifier(String verifier) async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.writePkceVerifier(verifier);
    }
    await prefs.setString(pkceKey, verifier);
  }

  @override
  Future<void> clearPkceVerifier() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.clearPkceVerifier();
    }
    await prefs.remove(pkceKey);
  }

  static Map<String, Object?> _sessionToJson(ArenaAuthSession session) {
    return <String, Object?>{
      'access_token': session.accessToken,
      if (session.refreshToken != null) 'refresh_token': session.refreshToken,
      if (session.expiresAt != null)
        'expires_at': session.expiresAt!.toIso8601String(),
      'user_id': session.userId,
    };
  }

  static ArenaAuthSession? _sessionFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final accessToken = value['access_token']?.toString();
    final userId = value['user_id']?.toString();
    if (accessToken == null ||
        accessToken.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }
    final rawExpiry = value['expires_at']?.toString();
    return ArenaAuthSession(
      accessToken: accessToken,
      userId: userId,
      refreshToken: value['refresh_token']?.toString(),
      expiresAt: rawExpiry == null ? null : DateTime.tryParse(rawExpiry),
    );
  }
}

/// Thrown when the platform secure store cannot persist or delete a value.
class AuthStorageException implements Exception {
  const AuthStorageException(this.message);

  final String message;

  @override
  String toString() => 'AuthStorageException: $message';
}

/// Minimal port over the platform secure key/value store so tests can run in
/// memory and force failures deterministically.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Android Keystore-backed implementation (`flutter_secure_storage`).
///
/// `resetOnError` is disabled so a read that fails (corrupt ciphertext,
/// Keystore mismatch) throws instead of silently deleting the stored value;
/// [SecureAuthSessionStore] then fails closed rather than falling back to
/// stale plaintext.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: false),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Result of a secure read: absence and failure are different states.
enum _SecureReadStatus { found, missing, failed }

class _SecureReadResult {
  const _SecureReadResult(this.status, [this.value]);

  final _SecureReadStatus status;
  final String? value;
}

/// Secure session store with a one-time migration from the legacy
/// SharedPreferences plaintext store.
///
/// Rules:
/// - the secure value is authoritative: a legacy plaintext value never
///   replaces or shadows a secure value, including a corrupt one;
/// - only absence triggers legacy migration; a read failure (Keystore/decrypt
///   error) fails closed to signed-out and leaves the legacy value untouched;
/// - migration writes the secure copy, reads it back to verify, and only then
///   removes the plaintext copy; a failed migration keeps the original
///   plaintext for a retry on the next read;
/// - a successful write removes the obsolete plaintext copy so it cannot be
///   used as a fallback later; a failed legacy removal is retried on later
///   reads even when secure data already exists;
/// - a secure write failure throws [AuthStorageException] (no plaintext
///   fallback); session and PKCE deletions are strict, so logout cannot
///   silently leave a restorable token behind;
/// - every operation is serialized in request order, so a successful clear
///   completes after the mutations it was issued after and cannot delete a
///   newer write. The store never holds that ordering across network work.
class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({
    SecureKeyValueStore? secure,
    MemoryAuthSessionStore? fallback,
  })  : _secure = secure ?? FlutterSecureKeyValueStore(),
        _fallback = fallback ?? MemoryAuthSessionStore();

  static const String sessionKey = 'arena.auth.session.v2';
  static const String pkceKey = 'arena.auth.pkce.v2';

  final SecureKeyValueStore _secure;
  final MemoryAuthSessionStore _fallback;

  /// Tail of the mutation queue. Every public operation runs to completion in
  /// the order it was requested, so a clear that was requested later runs after
  /// the writes it must erase and never after a newer write.
  Future<void> _tail = Future<void>.value();

  /// Runs [action] after every previously queued operation. The returned
  /// future carries [action]'s result or error, while [_tail] always continues
  /// so one failure cannot stall the queue. No store action performs network
  /// work, so the queue never holds a lock across a provider call.
  Future<T> _ordered<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then<void>((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<SharedPreferences?> _legacyPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<_SecureReadResult> _readSecure(String key) async {
    try {
      final value = await _secure.read(key);
      return value == null
          ? const _SecureReadResult(_SecureReadStatus.missing)
          : _SecureReadResult(_SecureReadStatus.found, value);
    } catch (_) {
      return const _SecureReadResult(_SecureReadStatus.failed);
    }
  }

  Future<void> _writeSecure(String key, String value) async {
    try {
      await _secure.write(key, value);
    } catch (_) {
      throw const AuthStorageException(
        'The session could not be saved in the device secure storage.',
      );
    }
  }

  /// Removes a legacy key, reporting whether the plaintext copy is gone.
  ///
  /// A native `false` result or a thrown error means the removal did not
  /// complete and the caller must not treat the delete as durable.
  Future<bool> _removeLegacy(SharedPreferences? prefs, String key) async {
    if (prefs == null) {
      return false;
    }
    try {
      return await prefs.remove(key);
    } catch (_) {
      return false;
    }
  }

  /// Removes a leftover plaintext key and reports whether it is gone.
  ///
  /// The persisted value is reloaded before the check: `SharedPreferences`
  /// drops its in-memory entry before the platform write, so a previous failed
  /// removal would otherwise look like success and never be retried. Missing or
  /// unavailable preferences cannot be verified and report `false`.
  Future<bool> _cleanupLegacyKey(String key) async {
    final prefs = await _legacyPrefs();
    if (prefs == null) {
      return false;
    }
    try {
      await prefs.reload();
    } catch (_) {
      return false;
    }
    if (!prefs.containsKey(key)) {
      return true;
    }
    return _removeLegacy(prefs, key);
  }

  @override
  Future<ArenaAuthSession?> readSession() => _ordered(_readSession);

  Future<ArenaAuthSession?> _readSession() async {
    final secure = await _readSecure(sessionKey);
    switch (secure.status) {
      case _SecureReadStatus.found:
        final parsed = _decodeSession(secure.value!);
        if (parsed == null) {
          // A present-but-unreadable secure value is authoritative: never
          // resurrect the legacy plaintext session over it.
          return null;
        }
        await _cleanupLegacyKey(SharedPreferencesAuthSessionStore.sessionKey);
        return parsed;
      case _SecureReadStatus.failed:
        // Storage failure: fail closed, leave any legacy value untouched.
        return null;
      case _SecureReadStatus.missing:
        break;
    }
    final prefs = await _legacyPrefs();
    final legacy =
        prefs?.getString(SharedPreferencesAuthSessionStore.sessionKey);
    if (legacy == null) {
      return _fallback.readSession();
    }
    final session = _decodeSession(legacy);
    if (session == null) {
      await _removeLegacy(
        prefs,
        SharedPreferencesAuthSessionStore.sessionKey,
      );
      return _fallback.readSession();
    }
    try {
      await _secure.write(sessionKey, legacy);
      final verify = await _secure.read(sessionKey);
      if (verify != legacy) {
        throw const AuthStorageException('secure write verification failed');
      }
    } catch (_) {
      // Keep the plaintext original so the session survives and the migration
      // is retried; never claim the migration succeeded.
      return session;
    }
    await _removeLegacy(
      prefs,
      SharedPreferencesAuthSessionStore.sessionKey,
    );
    return session;
  }

  @override
  Future<void> writeSession(ArenaAuthSession session) => _ordered(
        () => _writeSession(session),
      );

  Future<void> _writeSession(ArenaAuthSession session) async {
    await _writeSecure(sessionKey, jsonEncode(_sessionToJson(session)));
    // A new secure session makes any plaintext copy obsolete.
    await _cleanupLegacyKey(SharedPreferencesAuthSessionStore.sessionKey);
  }

  @override
  Future<void> clearSession() => _ordered(_clearSession);

  Future<void> _clearSession() async {
    Object? failure;
    try {
      await _secure.delete(sessionKey);
    } catch (_) {
      failure = const AuthStorageException(
        'The session could not be removed from the device secure storage.',
      );
    }
    final legacyCleared = await _cleanupLegacyKey(
      SharedPreferencesAuthSessionStore.sessionKey,
    );
    await _fallback.clearSession();
    if (failure != null) {
      throw failure;
    }
    if (!legacyCleared) {
      throw const AuthStorageException(
        'The saved session could not be erased from plaintext storage on this '
        'device.',
      );
    }
  }

  @override
  Future<String?> readPkceVerifier() => _ordered(_readPkceVerifier);

  Future<String?> _readPkceVerifier() async {
    final secure = await _readSecure(pkceKey);
    switch (secure.status) {
      case _SecureReadStatus.found:
        if (secure.value!.isEmpty) {
          // Present-but-empty is corrupt; do not fall back to legacy.
          return null;
        }
        await _cleanupLegacyKey(SharedPreferencesAuthSessionStore.pkceKey);
        return secure.value;
      case _SecureReadStatus.failed:
        return null;
      case _SecureReadStatus.missing:
        break;
    }
    final prefs = await _legacyPrefs();
    final legacy = prefs?.getString(SharedPreferencesAuthSessionStore.pkceKey);
    if (legacy == null || legacy.isEmpty) {
      return _fallback.readPkceVerifier();
    }
    try {
      await _secure.write(pkceKey, legacy);
      final verify = await _secure.read(pkceKey);
      if (verify != legacy) {
        throw const AuthStorageException('secure write verification failed');
      }
    } catch (_) {
      // Keep the legacy verifier so an in-flight redirect still completes.
      return legacy;
    }
    await _removeLegacy(
      prefs,
      SharedPreferencesAuthSessionStore.pkceKey,
    );
    return legacy;
  }

  @override
  Future<void> writePkceVerifier(String verifier) => _ordered(
        () => _writePkceVerifier(verifier),
      );

  Future<void> _writePkceVerifier(String verifier) async {
    await _writeSecure(pkceKey, verifier);
    await _cleanupLegacyKey(SharedPreferencesAuthSessionStore.pkceKey);
  }

  @override
  Future<void> clearPkceVerifier() => _ordered(_clearPkceVerifier);

  Future<void> _clearPkceVerifier() async {
    Object? failure;
    try {
      await _secure.delete(pkceKey);
    } catch (_) {
      failure = const AuthStorageException(
        'The sign-in state could not be removed from the device secure '
        'storage.',
      );
    }
    final legacyCleared = await _cleanupLegacyKey(
      SharedPreferencesAuthSessionStore.pkceKey,
    );
    await _fallback.clearPkceVerifier();
    if (failure != null) {
      throw failure;
    }
    if (!legacyCleared) {
      throw const AuthStorageException(
        'The sign-in state could not be erased from plaintext storage on this '
        'device.',
      );
    }
  }

  static ArenaAuthSession? _decodeSession(String raw) {
    try {
      return SharedPreferencesAuthSessionStore._sessionFromJson(
        jsonDecode(raw),
      );
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?> _sessionToJson(ArenaAuthSession session) =>
      SharedPreferencesAuthSessionStore._sessionToJson(session);
}
