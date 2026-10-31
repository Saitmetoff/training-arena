/// Google/email return continuity through the real Supabase gateway.
///
/// L06 requires that a provider redirect which survives process death lands on
/// exactly the same pending challenge, including an account that still has to
/// claim a username. These tests wire the production [SupabaseAuthGateway]
/// (PKCE verifier in the session store, redirect allowlist matching, token
/// exchange) to the real challenge entry controller. No hosted project is
/// touched: the HTTP client is a mock and the redirect arrives through a fake
/// link source.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/auth/auth_store.dart';
import 'package:training_arena/account/auth/supabase_auth_gateway.dart';
import 'package:training_arena/account/challenge/account_challenge_auth.dart';
import 'package:training_arena/account/runtime/account_controller.dart';
import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_auth.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_deep_links.dart';
import 'package:training_arena/linking/challenge_persistence.dart';

import '../linking/fakes.dart';
import 'fakes.dart';

const ArenaConfig _config = ArenaConfig(
  publicUrl: 'https://example.invalid',
  linkHost: 'example.invalid',
  supabaseUrl: 'https://project.invalid',
  supabaseAnonKey: 'anon-public',
  authRedirectUrl: 'trainingarena://challenge/auth',
  challengeLinksEnabled: true,
);

class _FakeBrowser implements ArenaAuthBrowser {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

class _FakeRedirectLinks implements ArenaAuthRedirectLinks {
  Uri? initial;

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => const Stream<Uri>.empty();
}

/// Both production wrappers subscribe to the same native app_links broadcast.
class _SharedNativeLinks implements ArenaAuthRedirectLinks, ChallengeDeepLinks {
  final events = StreamController<Uri>.broadcast(sync: true);
  Uri? initial;

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => events.stream;
}

String _sessionBody() {
  return jsonEncode(<String, Object?>{
    'access_token': 'access-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-token',
    'user': <String, Object?>{'id': fakeViewerId},
  });
}

class _Harness {
  _Harness({
    required MemoryAuthSessionStore store,
    required ArenaAuthRedirectLinks links,
    required _FakeBrowser browser,
    required MockClient client,
    String? username,
  }) : api = FakeAccountApi(profile: fakeViewer(username: username)),
       prompts = FakeChallengeAuthPrompts(
         emails: <String?>['player@example.invalid'],
         codes: <String?>['123456'],
         usernames: <String?>['Kokoro_2'],
       ),
       persistence = MemoryChallengePersistence() {
    gateway = SupabaseAuthGateway(
      config: _config,
      store: store,
      client: client,
      browser: browser,
      links: links,
    );
    controller = AccountController(auth: gateway, api: api);
    delegate = AccountChallengeAuthDelegate(
      controller: controller,
      prompts: prompts,
    );
  }

  final FakeAccountApi api;
  final FakeChallengeAuthPrompts prompts;
  final MemoryChallengePersistence persistence;
  late final SupabaseAuthGateway gateway;
  late final AccountController controller;
  late final AccountChallengeAuthDelegate delegate;

  ChallengeEntryController entry({ChallengeDeepLinks? deepLinks}) {
    return ChallengeEntryController(
      config: _config,
      api: FakeArenaChallengeApi(),
      persistence: persistence,
      deepLinks: deepLinks ?? FakeChallengeDeepLinks(),
      installReferrer: FakeInstallReferrerSource(),
      auth: delegate,
      analytics: MemoryChallengeAnalyticsSink(),
      matchPollInterval: Duration.zero,
    );
  }

  void dispose() {
    controller.dispose();
  }
}

void main() {
  test(
    'shared warm Google callback never opens an invalid challenge route',
    () async {
      final links = _SharedNativeLinks();
      final browser = _FakeBrowser();
      final harness = _Harness(
        store: MemoryAuthSessionStore(),
        links: links,
        browser: browser,
        client: MockClient((_) async => http.Response(_sessionBody(), 200)),
        username: 'Owner',
      );
      final entry = harness.entry(deepLinks: links);
      await entry.start();
      final states = <ChallengeEntryState>[];
      entry.addListener(() => states.add(entry.state));
      final signingIn = harness.gateway.signInWithGoogle();
      while (browser.opened.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      links.events.add(
        Uri.parse('trainingarena://challenge/auth?code=warm-code'),
      );
      await signingIn;
      expect(entry.state, isA<ChallengeEntryIdle>());
      expect(states.whereType<ChallengeEntryUnavailable>(), isEmpty);
      entry.dispose();
      harness.dispose();
      await links.events.close();
    },
  );

  test(
    'shared OAuth callback leaves pending invitation intact throughout return',
    () async {
      final links = _SharedNativeLinks();
      final browser = _FakeBrowser();
      final harness = _Harness(
        store: MemoryAuthSessionStore(),
        links: links,
        browser: browser,
        client: MockClient((_) async => http.Response(_sessionBody(), 200)),
      );
      final entry = harness.entry(deepLinks: links);
      await entry.start();
      await entry.openCode(fakeToken);
      final states = <ChallengeEntryState>[];
      entry.addListener(() => states.add(entry.state));
      final signingIn = entry.signIn(ChallengeAuthMethod.google);
      while (browser.opened.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      links.events.add(
        Uri.parse('trainingarena://challenge/auth?code=invite-code'),
      );
      await signingIn;
      expect(entry.pendingChallenge?.token, fakeToken);
      expect(entry.state, isA<ChallengeEntryReview>());
      expect(states.whereType<ChallengeEntryUnavailable>(), isEmpty);
      entry.dispose();
      harness.dispose();
      await links.events.close();
    },
  );

  test('a Google redirect after process death returns to the same challenge', () async {
    final store = MemoryAuthSessionStore();
    final links = _FakeRedirectLinks()
      ..initial = Uri.parse('trainingarena://challenge/auth?code=auth-code');
    final browser = _FakeBrowser();
    late http.Request exchange;
    final client = MockClient((request) async {
      exchange = request;
      return http.Response(_sessionBody(), 200);
    });
    final harness = _Harness(
      store: store,
      links: links,
      browser: browser,
      client: client,
      username: null,
    );

    // First process: the invitation is pending and the user left for Google.
    // The PKCE verifier is already durable; the redirect never returned before
    // the process died.
    await store.writePkceVerifier('stored-verifier');
    final first = harness.entry();
    await first.handleUri(Uri.parse('https://example.invalid/c/$fakeToken'));
    expect(first.state, isA<ChallengeEntrySignIn>());
    expect(first.pendingChallenge!.token, fakeToken);
    first.dispose();

    // New process: the redirect is the cold-start link and completes the
    // sign-in before the challenge UI runs.
    await harness.controller.initialize();
    expect(harness.controller.signedIn, isTrue);
    expect(exchange.url.path, '/auth/v1/token');
    expect(exchange.url.query, 'grant_type=pkce');
    expect(jsonDecode(exchange.body), <String, Object?>{
      'auth_code': 'auth-code',
      'code_verifier': 'stored-verifier',
    });
    expect(await store.readPkceVerifier(), isNull);

    final second = harness.entry();
    await second.start();
    final restored = second.state;
    expect(restored, isA<ChallengeEntryReview>());
    expect((restored as ChallengeEntryReview).resolution.token, fakeToken);
    expect(second.pendingChallenge!.token, fakeToken);

    // Username-required account: the sign-in step claims the username without
    // losing the challenge.
    await second.signIn(ChallengeAuthMethod.google);
    final review = second.state;
    expect(review, isA<ChallengeEntryReview>());
    expect((review as ChallengeEntryReview).resolution.token, fakeToken);
    expect(harness.prompts.usernameCalls, 1);
    expect(harness.api.lastUsernameUpdate, 'Kokoro_2');

    await second.acceptChallenge();
    final waiting = second.state;
    expect(waiting, isA<ChallengeEntryWaiting>());
    expect((waiting as ChallengeEntryWaiting).token, fakeToken);

    second.dispose();
    harness.dispose();
  });

  test(
    'an email-code sign-in after process death keeps the same challenge',
    () async {
      final store = MemoryAuthSessionStore();
      final browser = _FakeBrowser();
      late http.Request verify;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/verify')) {
          verify = request;
          return http.Response(_sessionBody(), 200);
        }
        return http.Response('{}', 200);
      });
      final harness = _Harness(
        store: store,
        links: _FakeRedirectLinks(),
        browser: browser,
        client: client,
        username: null,
      );

      final first = harness.entry();
      await first.handleUri(Uri.parse('https://example.invalid/c/$fakeToken'));
      expect(first.state, isA<ChallengeEntrySignIn>());
      first.dispose();

      // New process: no session yet, the pending challenge is restored first.
      await harness.controller.initialize();
      expect(harness.controller.signedIn, isFalse);

      final second = harness.entry();
      await second.start();
      expect(second.state, isA<ChallengeEntrySignIn>());
      expect(second.pendingChallenge!.token, fakeToken);

      await second.signIn(ChallengeAuthMethod.email);

      final review = second.state;
      expect(review, isA<ChallengeEntryReview>());
      expect((review as ChallengeEntryReview).resolution.token, fakeToken);
      expect(verify.url.path, '/auth/v1/verify');
      expect(harness.prompts.emailCalls, 1);
      expect(harness.prompts.codeCalls, 1);
      expect(harness.prompts.usernameCalls, 1);
      expect(harness.api.lastUsernameUpdate, 'Kokoro_2');
      expect(second.pendingChallenge!.token, fakeToken);

      await second.acceptChallenge();
      expect(second.state, isA<ChallengeEntryWaiting>());

      second.dispose();
      harness.dispose();
    },
  );

  test('a redirect that does not match the allowlist is ignored', () async {
    final store = MemoryAuthSessionStore();
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      return http.Response(_sessionBody(), 200);
    });
    for (final wrong in <Uri>[
      Uri.parse('trainingarena://challenge/other?code=auth-code'),
      Uri.parse('trainingarena://other/auth?code=auth-code'),
      Uri.parse('https://example.invalid/challenge/auth?code=auth-code'),
    ]) {
      await store.writePkceVerifier('stored-verifier');
      final links = _FakeRedirectLinks()..initial = wrong;
      final gateway = SupabaseAuthGateway(
        config: _config,
        store: store,
        client: client,
        browser: _FakeBrowser(),
        links: links,
      );

      expect(await gateway.restoreSession(), isNull);
      expect(
        await store.readPkceVerifier(),
        'stored-verifier',
        reason: 'a non-matching link must not consume the verifier',
      );
    }
    expect(calls, 0, reason: 'no token exchange without a matching redirect');
  });
}
