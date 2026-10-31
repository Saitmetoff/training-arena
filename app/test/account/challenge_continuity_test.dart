/// Challenge sign-in continuity through the real account controller.
///
/// The challenge landing (task `05`) keeps the pending token; this test wires
/// the real [AccountChallengeAuthDelegate] over an [AccountController] with
/// fakes to prove the round trip returns to the exact same challenge after
/// Google sign-in, email-code sign-in and a process restart, with no generic
/// onboarding inserted.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/account/challenge/account_challenge_auth.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/account/runtime/account_controller.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_auth.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_persistence.dart';

import '../linking/fakes.dart';
import 'fakes.dart';

/// Fails the first username claim with the server's duplicate code, then
/// delegates to the normal fake. Mirrors a real uniqueness race.
class _FailOnceAccountApi extends FakeAccountApi {
  _FailOnceAccountApi({super.profile});

  int failures = 0;

  @override
  Future<ArenaProfile> updateUsername(String username) {
    if (failures == 0) {
      failures += 1;
      throw const AccountException(
        'username_taken',
        'That username is taken. Try another.',
      );
    }
    return super.updateUsername(username);
  }
}

class _Harness {
  _Harness({String? username, FakeAccountApi? api})
      : api = api ?? FakeAccountApi(profile: fakeViewer(username: username)) {
    controller = AccountController(auth: auth, api: this.api);
    delegate = AccountChallengeAuthDelegate(
      controller: controller,
      prompts: prompts,
    );
    entry = _buildEntry(delegate);
  }

  final FakeArenaAuthGateway auth = FakeArenaAuthGateway();
  final FakeAccountApi api;
  final MemoryChallengePersistence persistence = MemoryChallengePersistence();
  final FakeArenaChallengeApi challengeApi = FakeArenaChallengeApi();
  final FakeChallengeDeepLinks deepLinks = FakeChallengeDeepLinks();
  final MemoryChallengeAnalyticsSink analytics = MemoryChallengeAnalyticsSink();
  final FakeChallengeAuthPrompts prompts = FakeChallengeAuthPrompts(
    emails: <String?>['player@example.invalid'],
    codes: <String?>['123456'],
    usernames: <String?>['Kokoro_2'],
  );

  late final AccountController controller;
  late final AccountChallengeAuthDelegate delegate;
  late final ChallengeEntryController entry;

  ChallengeEntryController _buildEntry(ChallengeAuthDelegate auth) {
    return ChallengeEntryController(
      config: testConfig(),
      api: challengeApi,
      persistence: persistence,
      deepLinks: deepLinks,
      installReferrer: FakeInstallReferrerSource(),
      auth: auth,
      analytics: analytics,
      matchPollInterval: Duration.zero,
    );
  }

  Future<void> openChallenge() async {
    await entry.handleUri(Uri.parse('https://example.invalid/c/$fakeToken'));
  }

  Future<void> dispose() async {
    entry.dispose();
    controller.dispose();
    await deepLinks.close();
  }
}

void main() {
  test('Google sign-in returns to the same challenge and claims a username',
      () async {
    final harness = _Harness(username: null);
    await harness.openChallenge();

    expect(harness.entry.state, isA<ChallengeEntrySignIn>());
    expect(harness.entry.pendingChallenge!.token, fakeToken);
    expect(harness.challengeApi.sendCalls, 0);

    await harness.entry.signIn(ChallengeAuthMethod.google);

    final review = harness.entry.state;
    expect(review, isA<ChallengeEntryReview>());
    expect((review as ChallengeEntryReview).resolution.token, fakeToken);
    expect(harness.auth.googleCalls, 1);
    expect(harness.api.lastUsernameUpdate, 'Kokoro_2');
    expect(harness.prompts.usernameCalls, 1);
    // The username prompt is a sign-in step, not a separate questionnaire.
    expect(harness.prompts.emailCalls, 0);
    expect(harness.challengeApi.sendCalls, 0);

    await harness.entry.acceptChallenge();

    final waiting = harness.entry.state;
    expect(waiting, isA<ChallengeEntryWaiting>());
    expect((waiting as ChallengeEntryWaiting).token, fakeToken);
    expect(harness.challengeApi.lastSentToken, fakeToken);
    expect(harness.challengeApi.sendCalls, 1);

    await harness.dispose();
  });

  test('email-code sign-in keeps the same token through both prompts',
      () async {
    final harness = _Harness(username: null);
    await harness.openChallenge();

    await harness.entry.signIn(ChallengeAuthMethod.email);

    final state = harness.entry.state;
    expect(state, isA<ChallengeEntryReview>());
    expect((state as ChallengeEntryReview).resolution.token, fakeToken);
    expect(harness.prompts.emailCalls, 1);
    expect(harness.prompts.codeCalls, 1);
    expect(harness.api.lastUsernameUpdate, 'Kokoro_2');
    expect(harness.entry.pendingChallenge!.token, fakeToken);

    await harness.dispose();
  });

  test('a duplicate username re-prompts without losing the challenge',
      () async {
    final harness = _Harness(
      api: _FailOnceAccountApi(profile: fakeViewer(username: null)),
    );
    harness.prompts.usernames.add('Kokoro_2');

    await harness.openChallenge();
    await harness.entry.signIn(ChallengeAuthMethod.google);

    expect(harness.entry.state, isA<ChallengeEntryReview>());
    expect(
      (harness.entry.state as ChallengeEntryReview).resolution.token,
      fakeToken,
    );
    expect(harness.entry.pendingChallenge!.token, fakeToken);
    expect(harness.prompts.usernameCalls, 2);
    expect(harness.prompts.usernameMessages.last, contains('taken'));
    expect(harness.api.lastUsernameUpdate, 'Kokoro_2');

    await harness.dispose();
  });

  test('restart restores the waiting challenge with the same token', () async {
    final harness = _Harness(username: 'azizbek');
    harness.auth.restoredSession = harness.auth.session;
    await harness.controller.initialize();
    await harness.openChallenge();
    await harness.entry.acceptChallenge();

    expect(harness.entry.state, isA<ChallengeEntryWaiting>());
    expect(harness.entry.pendingChallenge!.token, fakeToken);

    // Process restart: a new controller over the same durable store.
    final restarted = ChallengeEntryController(
      config: testConfig(),
      api: harness.challengeApi,
      persistence: harness.persistence,
      deepLinks: FakeChallengeDeepLinks(),
      installReferrer: FakeInstallReferrerSource(),
      auth: harness.delegate,
      analytics: MemoryChallengeAnalyticsSink(),
      matchPollInterval: Duration.zero,
    );
    await restarted.start();

    final state = restarted.state;
    expect(state, isA<ChallengeEntryWaiting>());
    expect((state as ChallengeEntryWaiting).token, fakeToken);
    expect(state.restored, isTrue);
    expect(harness.challengeApi.sendCalls, 1);

    restarted.dispose();
    await harness.dispose();
  });
}
