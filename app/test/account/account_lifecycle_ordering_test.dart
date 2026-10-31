/// Auth lifecycle ordering regressions (Batch A).
///
/// Controlled futures reproduce the real overlap between a restore/refresh and
/// a sign-out, between two sign-ins, and between store writes and a clear. The
/// guards live in the shared owners (controller, gateway, store); no UI caller
/// is special-cased.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/auth/auth_store.dart';
import 'package:training_arena/account/auth/supabase_auth_gateway.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/account/runtime/account_controller.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fakes.dart';

const ArenaConfig _config = ArenaConfig(
  publicUrl: 'https://example.invalid',
  linkHost: 'example.invalid',
  supabaseUrl: 'https://project.invalid',
  supabaseAnonKey: 'anon-public',
  authRedirectUrl: 'trainingarena://auth',
);

/// Auth gateway whose provider calls resolve on test-controlled completers.
class _GatedAuth implements ArenaAuthGateway {
  final List<Completer<ArenaAuthSession>> googleQueue =
      <Completer<ArenaAuthSession>>[];
  final List<Completer<ArenaAuthSession>> refreshQueue =
      <Completer<ArenaAuthSession>>[];
  Completer<ArenaAuthSession?>? restoreCompleter;
  Completer<ArenaAuthSession>? refreshCompleter;
  Completer<void>? signOutGate;
  int signOutCalls = 0;
  int clearLocalCalls = 0;
  ArenaAuthSession? lastSignedOut;

  @override
  Future<ArenaAuthSession?> restoreSession() {
    final completer = restoreCompleter;
    return completer?.future ?? Future<ArenaAuthSession?>.value(null);
  }

  @override
  Future<ArenaAuthSession> signInWithGoogle() {
    if (googleQueue.isEmpty) {
      throw StateError('no queued sign-in');
    }
    return googleQueue.removeAt(0).future;
  }

  @override
  Future<ArenaAuthSession> verifyEmailCode({
    required String email,
    required String code,
  }) {
    return signInWithGoogle();
  }

  @override
  Future<void> requestEmailCode(String email) async {}

  @override
  Future<ArenaAuthSession> refreshSession(ArenaAuthSession session) {
    if (refreshQueue.isNotEmpty) {
      return refreshQueue.removeAt(0).future;
    }
    final completer = refreshCompleter;
    if (completer == null) {
      throw StateError('no queued refresh');
    }
    return completer.future;
  }

  @override
  Future<void> signOut(ArenaAuthSession session) async {
    signOutCalls += 1;
    lastSignedOut = session;
    final gate = signOutGate;
    if (gate != null) {
      await gate.future;
    }
  }

  @override
  Future<void> clearLocalAuth() async {
    clearLocalCalls += 1;
  }
}

/// Account API whose calls can be held open per call.
class _GatedApi extends FakeAccountApi {
  _GatedApi();

  final List<Completer<ArenaProfile>> profileQueue =
      <Completer<ArenaProfile>>[];
  final List<Object> profileErrorQueue = <Object>[];
  Completer<void>? deleteGate;
  Completer<void>? updateUsernameGate;

  @override
  Future<ArenaProfile> fetchProfile() async {
    profileCalls += 1;
    if (profileErrorQueue.isNotEmpty) {
      final error = profileErrorQueue.removeAt(0);
      throw error;
    }
    if (profileQueue.isEmpty) {
      return super.fetchProfile();
    }
    return profileQueue.removeAt(0).future;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls += 1;
    final gate = deleteGate;
    if (gate != null) {
      await gate.future;
    }
  }

  @override
  Future<ArenaProfile> updateUsername(String username) async {
    lastUsernameUpdate = username;
    final gate = updateUsernameGate;
    if (gate != null) {
      await gate.future;
    }
    return fakeViewer(username: username);
  }
}

class _MemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};
  bool failDeletes = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) {
      throw StateError('secure delete refused');
    }
    values.remove(key);
  }
}

/// Secure store that can hold a write open so store ordering is observable.
class _BlockingSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};
  final Map<String, Completer<void>> writeGates =
      <String, Completer<void>>{};
  final Map<String, Completer<void>> deleteGates =
      <String, Completer<void>>{};
  bool failDeletes = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    final gate = writeGates.remove(key);
    if (gate != null) {
      await gate.future;
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    final gate = deleteGates.remove(key);
    if (gate != null) {
      await gate.future;
    }
    if (failDeletes) {
      throw StateError('secure delete refused');
    }
    values.remove(key);
  }
}

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

String _sessionBodyFor(String userId, String accessToken) =>
    jsonEncode(<String, Object?>{
      'access_token': accessToken,
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh',
      'user': <String, Object?>{'id': userId},
    });

ArenaAuthSession _expiredSession() => ArenaAuthSession(
      accessToken: 'old',
      userId: 'viewer-1',
      refreshToken: 'refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

ArenaAuthSession _session(String token, {String userId = 'viewer-1'}) =>
    ArenaAuthSession(accessToken: token, userId: userId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The plaintext legacy path is part of the real store; give it an empty
    // in-memory persisted store instead of an unavailable platform channel.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('controller identity invalidation', () {
    test('a refresh that finishes after sign-out cannot resurrect the session',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final signIn = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signIn);
      final profile = Completer<ArenaProfile>();
      api.profileQueue.add(profile);
      final signInFuture = controller.signInWithGoogle();
      signIn.complete(_expiredSession());
      profile.complete(fakeViewer());
      await signInFuture;
      expect(controller.signedIn, isTrue);

      auth.refreshCompleter = Completer<ArenaAuthSession>();
      final tokenFuture = controller.accessToken();

      await controller.signOut();
      expect(controller.signedIn, isFalse);

      auth.refreshCompleter!.complete(
        const ArenaAuthSession(
          accessToken: 'refreshed',
          userId: 'viewer-1',
          refreshToken: 'refresh-2',
        ),
      );

      expect(await tokenFuture, isNull);
      expect(await controller.accessToken(), isNull);
      expect(controller.viewer.value, isNull);
      expect(auth.signOutCalls, 1);
    });

    test('sign-out drops the session immediately, before the gateway answers',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final signIn = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signIn);
      final profile = Completer<ArenaProfile>();
      api.profileQueue.add(profile);
      final signInFuture = controller.signInWithGoogle();
      signIn.complete(_expiredSession());
      profile.complete(fakeViewer());
      await signInFuture;

      auth.signOutGate = Completer<void>();
      final signOut = controller.signOut();

      // The gateway has not answered yet, but the identity is already gone.
      expect(controller.signedIn, isFalse);
      expect(controller.viewer.value, isNull);
      expect(await controller.accessToken(), isNull);

      auth.signOutGate!.complete();
      await signOut;
      expect(controller.notice, 'You are signed out.');
    });

    test('sign-out without an in-memory session clears pending durable auth',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      await controller.signOut();

      expect(auth.clearLocalCalls, 1);
      expect(auth.signOutCalls, 0);
      expect(controller.status, AccountStatus.signedOut);
      expect(controller.notice, 'You are signed out.');
    });

    test('a restore that finishes after sign-out cannot sign the user back in',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final restore = Completer<ArenaAuthSession?>();
      auth.restoreCompleter = restore;
      final initFuture = controller.initialize();
      await Future<void>.delayed(Duration.zero);

      await controller.signOut();
      expect(controller.signedIn, isFalse);

      restore.complete(
        const ArenaAuthSession(accessToken: 'late', userId: 'viewer-1'),
      );
      await initFuture;

      expect(controller.signedIn, isFalse);
      expect(controller.profile, isNull);
      expect(controller.viewer.value, isNull);
      expect(api.profileCalls, 0);
    });

    test('a delayed older sign-in cannot overwrite a newer account', () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final first = Completer<ArenaAuthSession>();
      final second = Completer<ArenaAuthSession>();
      auth.googleQueue.addAll(<Completer<ArenaAuthSession>>[first, second]);
      final profileB = Completer<ArenaProfile>();
      api.profileQueue.add(profileB);

      final futureA = controller.signInWithGoogle();
      final futureB = controller.signInWithGoogle();

      second.complete(
        const ArenaAuthSession(accessToken: 'token-b', userId: 'viewer-b'),
      );
      profileB.complete(fakeViewer(username: 'b_user'));
      await futureB;
      expect(controller.profile?.username, 'b_user');

      first.complete(
        const ArenaAuthSession(accessToken: 'token-a', userId: 'viewer-a'),
      );
      await expectLater(
        futureA,
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(controller.profile?.username, 'b_user');
      expect(await controller.accessToken(), 'token-b');
    });

    test(
      'cancelled browser wait permits retry and rejects its late session',
      () async {
        final auth = _GatedAuth();
        final api = _GatedApi();
        final controller = AccountController(auth: auth, api: api);
        addTearDown(controller.dispose);
        await controller.initialize();
        final first = Completer<ArenaAuthSession>();
        final second = Completer<ArenaAuthSession>();
        auth.googleQueue.addAll([first, second]);
        final oldSignIn = controller.signInWithGoogle();
        expect(controller.canCancelSignIn, isTrue);

        await controller.cancelSignIn();

        expect(auth.clearLocalCalls, 1);
        expect(controller.busy, isFalse);
        expect(controller.canCancelSignIn, isFalse);
        expect(controller.status, AccountStatus.signedOut);
        final profile = Completer<ArenaProfile>();
        api.profileQueue.add(profile);
        final retry = controller.verifyEmailCode(
          email: 'owner@example.invalid',
          code: '12345678',
        );
        second.complete(
          const ArenaAuthSession(
            accessToken: 'retry-token',
            userId: 'retry-viewer',
          ),
        );
        profile.complete(fakeViewer(username: 'retry_user'));
        await retry;
        first.complete(
          const ArenaAuthSession(
            accessToken: 'late-token',
            userId: 'late-viewer',
          ),
        );
        await expectLater(oldSignIn, throwsA(isA<AccountException>()));
        expect(controller.profile?.username, 'retry_user');
        expect(await controller.accessToken(), 'retry-token');
      },
    );


    test('a newer identity does not join the prior account pending refresh',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      // A signs in with an expired session and the refresh stays pending.
      final signInA = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInA);
      final profileA = Completer<ArenaProfile>();
      api.profileQueue.add(profileA);
      final futureA = controller.signInWithGoogle();
      signInA.complete(
        ArenaAuthSession(
          accessToken: 'old-a',
          userId: 'viewer-a',
          refreshToken: 'r-a',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      profileA.complete(fakeViewer(username: 'a_user'));
      await futureA;

      final refreshA = Completer<ArenaAuthSession>();
      auth.refreshQueue.add(refreshA);
      final tokenA = controller.accessToken();

      await controller.signOut();

      // B signs in with a distinct id and expired session.
      final refreshB = Completer<ArenaAuthSession>();
      auth.refreshQueue.add(refreshB);
      final signInB = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInB);
      final profileB = Completer<ArenaProfile>();
      api.profileQueue.add(profileB);
      final futureB = controller.signInWithGoogle();
      signInB.complete(
        ArenaAuthSession(
          accessToken: 'old-b',
          userId: 'viewer-b',
          refreshToken: 'r-b',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      profileB.complete(fakeViewer(username: 'b_user'));
      await futureB;

      final tokenB = controller.accessToken();
      refreshB.complete(
        const ArenaAuthSession(
          accessToken: 'token-b',
          userId: 'viewer-b',
          refreshToken: 'r-b2',
        ),
      );
      expect(await tokenB, 'token-b');

      refreshA.complete(
        const ArenaAuthSession(
          accessToken: 'token-a',
          userId: 'viewer-a',
          refreshToken: 'r-a2',
        ),
      );
      expect(await tokenA, isNull);
      expect(await controller.accessToken(), 'token-b');
      expect(controller.viewer.value?.username, 'b_user');
    });

    test('a delayed expired-response logout cannot clear a newer sign-in',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final signInA = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInA);
      final profileA = Completer<ArenaProfile>();
      api.profileQueue.add(profileA);
      final futureA = controller.signInWithGoogle();
      signInA.complete(_session('token-a', userId: 'viewer-a'));
      profileA.complete(fakeViewer(username: 'a_user'));
      await futureA;

      // A profile reload reports an expired session; the resulting logout is
      // held open at the gateway.
      api.profileErrorQueue.add(
        const AccountException('unauthorized', 'expired', statusCode: 401),
      );
      auth.signOutGate = Completer<void>();
      final expiredReload = controller.refreshProfile();
      // Let the expired response reach the gated logout before B signs in.
      await Future<void>.delayed(Duration.zero);

      final signInB = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInB);
      final profileB = Completer<ArenaProfile>();
      api.profileQueue.add(profileB);
      final futureB = controller.signInWithGoogle();
      signInB.complete(_session('token-b', userId: 'viewer-b'));
      profileB.complete(fakeViewer(username: 'b_user'));
      await futureB;
      expect(controller.profile?.username, 'b_user');

      auth.signOutGate!.complete();
      await expectLater(
        expiredReload,
        throwsA(isA<AccountException>()),
      );

      expect(controller.signedIn, isTrue);
      expect(controller.profile?.username, 'b_user');
      expect(controller.viewer.value?.username, 'b_user');
    });
  });

  group('deletion and profile ordering', () {
    test('a deletion that finishes after a newer sign-in cannot clear it',
        () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final signInA = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInA);
      final profileA = Completer<ArenaProfile>();
      api.profileQueue.add(profileA);
      final futureA = controller.signInWithGoogle();
      signInA.complete(_session('token-a', userId: 'viewer-a'));
      profileA.complete(fakeViewer(username: 'a_user'));
      await futureA;
      expect(controller.profile?.username, 'a_user');

      api.deleteGate = Completer<void>();
      final deletion = controller.deleteAccount();

      final signInB = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInB);
      final profileB = Completer<ArenaProfile>();
      api.profileQueue.add(profileB);
      final futureB = controller.signInWithGoogle();
      signInB.complete(_session('token-b', userId: 'viewer-b'));
      profileB.complete(fakeViewer(username: 'b_user'));
      await futureB;
      expect(controller.profile?.username, 'b_user');

      // The delayed deletion server call now returns success for the old
      // account; it must not sign the newer account out.
      api.deleteGate!.complete();
      await deletion;

      expect(controller.signedIn, isTrue);
      expect(controller.profile?.username, 'b_user');
      expect(await controller.accessToken(), 'token-b');
    });

    test('a stale profile mutation cannot overwrite a newer account', () async {
      final auth = _GatedAuth();
      final api = _GatedApi();
      final controller = AccountController(auth: auth, api: api);
      addTearDown(controller.dispose);

      final signInA = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInA);
      final profileA = Completer<ArenaProfile>();
      api.profileQueue.add(profileA);
      final futureA = controller.signInWithGoogle();
      signInA.complete(_session('token-a', userId: 'viewer-a'));
      profileA.complete(fakeViewer(username: 'a_user'));
      await futureA;

      api.updateUsernameGate = Completer<void>();
      final staleClaim = controller.claimUsername('stale_name');

      final signInB = Completer<ArenaAuthSession>();
      auth.googleQueue.add(signInB);
      final profileB = Completer<ArenaProfile>();
      api.profileQueue.add(profileB);
      final futureB = controller.signInWithGoogle();
      signInB.complete(_session('token-b', userId: 'viewer-b'));
      profileB.complete(fakeViewer(username: 'b_user'));
      await futureB;

      api.updateUsernameGate!.complete();
      await expectLater(
        staleClaim,
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(controller.profile?.username, 'b_user');
      expect(controller.signedIn, isTrue);
    });
  });

  group('durable store ordering', () {
    test('a delayed write cannot outlive a later clear or a newer write',
        () async {
      final secure = _BlockingSecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final gate = Completer<void>();
      secure.writeGates[SecureAuthSessionStore.sessionKey] = gate;

      final writeA = store.writeSession(_session('a'));
      final clear = store.clearSession();
      final writeB = store.writeSession(_session('b'));

      gate.complete();
      await writeA;
      await clear;
      await writeB;

      expect((await store.readSession())?.accessToken, 'b');
      expect(secure.values[SecureAuthSessionStore.sessionKey], isNotNull);
    });

    test('a delayed migration cannot survive a later clear and newer write',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAuthSessionStore.sessionKey: jsonEncode(
          <String, Object?>{
            'access_token': 'legacy',
            'user_id': 'user-l',
          },
        ),
      });
      final secure = _BlockingSecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final gate = Completer<void>();
      secure.writeGates[SecureAuthSessionStore.sessionKey] = gate;

      final migrate = store.readSession();
      final clear = store.clearSession();
      final writeB = store.writeSession(_session('b'));

      gate.complete();
      expect((await migrate)?.accessToken, 'legacy');
      await clear;
      await writeB;

      expect((await store.readSession())?.accessToken, 'b');
    });

    test('a refused delete during clear still lets the newer write win',
        () async {
      final secure = _BlockingSecureStore()..failDeletes = true;
      final store = SecureAuthSessionStore(secure: secure);
      final gate = Completer<void>();
      secure.writeGates[SecureAuthSessionStore.sessionKey] = gate;

      final writeA = store.writeSession(_session('a'));
      final clear = store.clearSession();
      final writeB = store.writeSession(_session('b'));

      gate.complete();
      await writeA;
      await expectLater(clear, throwsA(isA<AuthStorageException>()));
      await writeB;

      expect((await store.readSession())?.accessToken, 'b');
    });

    test('PKCE ordering holds for a delayed write, clear and newer write',
        () async {
      final secure = _BlockingSecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final gate = Completer<void>();
      secure.writeGates[SecureAuthSessionStore.pkceKey] = gate;

      final writeA = store.writePkceVerifier('verifier-a');
      final clear = store.clearPkceVerifier();
      final writeB = store.writePkceVerifier('verifier-b');

      gate.complete();
      await writeA;
      await clear;
      await writeB;

      expect(await store.readPkceVerifier(), 'verifier-b');
    });

    test('a refresh that finishes after logout cannot rewrite the cleared '
        'session', () async {
      final secure = _MemorySecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final gate = Completer<void>();
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/token')) {
          await gate.future;
          return http.Response(_sessionBodyFor('viewer-1', 'access'), 200);
        }
        return http.Response('{}', 204);
      });
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: store,
        client: client,
        browser: _FakeBrowser(),
        links: _NoLinks(),
      );
      final expired = _expiredSession();
      await store.writeSession(expired);

      final restore = gateway.restoreSession();
      await Future<void>.delayed(Duration.zero);
      await gateway.signOut(expired);
      expect(await store.readSession(), isNull);

      gate.complete();
      expect(await restore, isNull);
      expect(
        await store.readSession(),
        isNull,
        reason: 'the in-flight refresh must not write the credential back',
      );
    });

    test('a superseded sign-in cannot persist over the newer account',
        () async {
      final secure = _MemorySecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final gateA = Completer<void>();
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        if (body['token'] == 'aaaa') {
          await gateA.future;
          return http.Response(_sessionBodyFor('user-a', 'token-a'), 200);
        }
        return http.Response(_sessionBodyFor('user-b', 'token-b'), 200);
      });
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: store,
        client: client,
        browser: _FakeBrowser(),
        links: _NoLinks(),
      );

      final signInA = gateway.verifyEmailCode(email: 'a@b.co', code: 'aaaa');
      final signInB = gateway.verifyEmailCode(email: 'a@b.co', code: 'bbbb');
      expect((await signInB).userId, 'user-b');

      gateA.complete();
      await expectLater(
        signInA,
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );

      // A fresh store instance restores the newer account, not the late one.
      final restarted = SecureAuthSessionStore(secure: secure);
      expect((await restarted.readSession())?.userId, 'user-b');
    });

    test('a stale restore cannot clear the verifier of a newer sign-in',
        () async {
      final secure = _MemorySecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final links = _ControllableLinks()
        ..initial = Uri.parse('trainingarena://auth?code=bad');
      final gateBad = Completer<void>();
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        if (body['auth_code'] == 'bad') {
          await gateBad.future;
          return http.Response(
            jsonEncode(<String, Object?>{'error_code': 'invalid_grant'}),
            400,
          );
        }
        return http.Response(_sessionBodyFor('user-b', 'token-b'), 200);
      });
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: store,
        client: client,
        browser: _FakeBrowser(),
        links: links,
      );

      await store.writePkceVerifier('verifier-a');
      final restoreA = gateway.restoreSession();
      await Future<void>.delayed(Duration.zero);

      final signInB = gateway.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      final verifierB = await store.readPkceVerifier();
      expect(verifierB, isNotNull);
      expect(verifierB, isNot('verifier-a'));

      gateBad.complete();
      expect(await restoreA, isNull);
      expect(
        await store.readPkceVerifier(),
        verifierB,
        reason: 'a superseded exchange must not clear the newer verifier',
      );

      links.controller.add(Uri.parse('trainingarena://auth?code=good'));
      expect((await signInB).userId, 'user-b');
      await links.close();
    });

    test('a pending refresh cannot overwrite a newer sign-in in storage',
        () async {
      final secure = _MemorySecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final gate = Completer<void>();
      final client = MockClient((request) async {
        if (request.url.query.contains('grant_type=refresh_token')) {
          await gate.future;
          return http.Response(_sessionBodyFor('user-a', 'token-a'), 200);
        }
        return http.Response(_sessionBodyFor('user-b', 'token-b'), 200);
      });
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: store,
        client: client,
        browser: _FakeBrowser(),
        links: _NoLinks(),
      );
      await store.writeSession(
        ArenaAuthSession(
          accessToken: 'old-a',
          userId: 'user-a',
          refreshToken: 'r-a',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      final restoreA = gateway.restoreSession();
      await Future<void>.delayed(Duration.zero);

      final signInB = gateway.verifyEmailCode(email: 'a@b.co', code: 'bbbb');
      expect((await signInB).userId, 'user-b');

      gate.complete();
      expect(await restoreA, isNull);

      final restarted = SecureAuthSessionStore(secure: secure);
      expect((await restarted.readSession())?.userId, 'user-b');
    });

    test('a delayed logout cannot erase a verifier saved after it', () async {
      final secure = _BlockingSecureStore();
      final store = SecureAuthSessionStore(secure: secure);
      final deleteGate = Completer<void>();
      secure.deleteGates[SecureAuthSessionStore.sessionKey] = deleteGate;
      final client = MockClient((request) async => http.Response('{}', 204));
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: store,
        client: client,
        browser: _FakeBrowser(),
        links: _NoLinks(),
      );
      final session = _session('token-a', userId: 'user-a');
      await store.writeSession(session);

      final signOut = gateway.signOut(session);
      await Future<void>.delayed(Duration.zero);
      // The clear is blocked on the session delete; a newer sign-in stores its
      // verifier now.
      final newerVerifier = store.writePkceVerifier('verifier-b');
      await Future<void>.delayed(Duration.zero);

      deleteGate.complete();
      await signOut;
      await newerVerifier;

      expect(await store.readPkceVerifier(), 'verifier-b');
      expect(await store.readSession(), isNull);
    });
  });
}

/// Redirect source whose link stream can be driven by the test.
class _ControllableLinks implements ArenaAuthRedirectLinks {
  Uri? initial;
  final StreamController<Uri> controller =
      StreamController<Uri>.broadcast(sync: true);

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => controller.stream;

  Future<void> close() => controller.close();
}
