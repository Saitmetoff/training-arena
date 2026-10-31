import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_auth.dart';
import 'package:training_arena/linking/challenge_entry_controller.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/linking/challenge_persistence.dart';

import 'fakes.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 9, 18, 12);

  ChallengeEntryController buildController({
    required FakeArenaChallengeApi api,
    required ChallengePersistence persistence,
    FakeChallengeDeepLinks? deepLinks,
    FakeInstallReferrerSource? referrer,
    FakeChallengeAuthDelegate? auth,
    MemoryChallengeAnalyticsSink? analytics,
    bool challengeLinksEnabled = true,
  }) {
    return ChallengeEntryController(
      config: testConfig(challengeLinksEnabled: challengeLinksEnabled),
      api: api,
      persistence: persistence,
      deepLinks: deepLinks ?? FakeChallengeDeepLinks(),
      installReferrer: referrer ?? FakeInstallReferrerSource(),
      auth: auth ?? FakeChallengeAuthDelegate(),
      analytics: analytics ?? MemoryChallengeAnalyticsSink(),
      now: () => fixedNow,
      matchPollInterval: Duration.zero,
    );
  }

  test('cold signed-in link resolves read-only and opens the challenge', () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final analytics = MemoryChallengeAnalyticsSink();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
      analytics: analytics,
    );

    await controller.start();

    expect(controller.state, isA<ChallengeEntryReview>());
    final review = controller.state as ChallengeEntryReview;
    expect(review.resolution.owner!.username, 'zuhra');
    expect(review.signedIn, isTrue);
    expect(api.resolveCalls, 1);
    expect(api.sendCalls, 0, reason: 'opening a link must not send a request');
    expect(analytics.eventNames, contains(ChallengeAnalyticsEvent.linkOpened));
    final pending = await persistence.readPending();
    expect(pending!.token, fakeToken);
    expect(pending.sender!.username, 'zuhra');

    controller.dispose();
    await deepLinks.close();
  });

  test('signed-out link keeps context and resumes after sign-in', () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final analytics = MemoryChallengeAnalyticsSink();
    final auth = FakeChallengeAuthDelegate(signedIn: false);
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('trainingarena://challenge/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
      auth: auth,
      analytics: analytics,
    );

    await controller.start();
    expect(controller.state, isA<ChallengeEntrySignIn>());

    await controller.signIn(ChallengeAuthMethod.google);
    expect(auth.signInCalls, 1);
    expect(controller.state, isA<ChallengeEntryReview>());
    expect(
      analytics.eventNames,
      contains(ChallengeAnalyticsEvent.signInCompleted),
    );
    final pending = await persistence.readPending();
    expect(pending!.token, fakeToken, reason: 'same challenge after sign-in');

    controller.dispose();
    await deepLinks.close();
  });

  test('accept sends exactly one request and waits for the challenger',
      () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final analytics = MemoryChallengeAnalyticsSink();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
      analytics: analytics,
    );

    await controller.start();
    await controller.acceptChallenge();

    expect(api.sendCalls, 1);
    expect(api.lastSentToken, fakeToken);
    expect(controller.state, isA<ChallengeEntryWaiting>());
    final waiting = controller.state as ChallengeEntryWaiting;
    expect(waiting.requestId, 'req-1');
    expect(
      analytics.eventNames,
      contains(ChallengeAnalyticsEvent.requestSent),
    );
    final pending = await persistence.readPending();
    expect(pending!.requestId, 'req-1');
    expect(pending.requestStatus, ChallengeRequestStatus.pending);

    controller.dispose();
    await deepLinks.close();
  });

  test('request_exists recovers the pending request instead of failing',
      () async {
    final api = FakeArenaChallengeApi()
      ..sendError = const ChallengeApiException('request_exists')
      ..existingOutgoing = ChallengeRequest(
        id: 'req-9',
        status: ChallengeRequestStatus.pending,
        expiresAt: DateTime.utc(2030),
      );
    final persistence = MemoryChallengePersistence();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
    );

    await controller.start();
    await controller.acceptChallenge();

    expect(controller.state, isA<ChallengeEntryWaiting>());
    expect((controller.state as ChallengeEntryWaiting).requestId, 'req-9');

    controller.dispose();
    await deepLinks.close();
  });

  test('polling detects mutual acceptance and clears pending context',
      () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final analytics = MemoryChallengeAnalyticsSink();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
      analytics: analytics,
    );

    await controller.start();
    await controller.acceptChallenge();
    api.activeMatchId = fakeMatchId;
    await controller.checkForAcceptedMatch();

    expect(controller.state, isA<ChallengeEntryMatchReady>());
    expect(
      (controller.state as ChallengeEntryMatchReady).matchId,
      fakeMatchId,
    );
    expect(
      analytics.eventNames,
      contains(ChallengeAnalyticsEvent.requestAccepted),
    );
    expect(await persistence.readPending(), isNull);

    controller.dispose();
    await deepLinks.close();
  });

  test('cancel clears the request only after the backend confirms', () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
    );

    await controller.start();
    await controller.acceptChallenge();
    await controller.cancelPendingRequest();

    expect(api.respondCalls, 1);
    expect(api.lastRespondRequestId, 'req-1');
    expect(api.lastRespondResponse, ChallengeRequestResponse.cancel);
    expect(controller.state, isA<ChallengeEntryIdle>());
    expect(await persistence.readPending(), isNull);

    controller.dispose();
    await deepLinks.close();
  });

  test('restart restores a pending request without a new send', () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final firstLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final first = buildController(
      api: api,
      persistence: persistence,
      deepLinks: firstLinks,
    );
    await first.start();
    await first.acceptChallenge();
    expect(first.state, isA<ChallengeEntryWaiting>());
    first.dispose();
    await firstLinks.close();

    final secondApi = FakeArenaChallengeApi();
    final second = buildController(
      api: secondApi,
      persistence: persistence,
      deepLinks: FakeChallengeDeepLinks(),
    );
    await second.start();

    expect(second.state, isA<ChallengeEntryWaiting>());
    expect((second.state as ChallengeEntryWaiting).restored, isTrue);
    expect(secondApi.sendCalls, 0, reason: 'no duplicate request on restart');
    second.dispose();
  });

  test('expired persisted request clears context and explains why', () async {
    final persistence = MemoryChallengePersistence();
    await persistence.writePending(
      PendingChallengeState(
        token: fakeToken,
        requestId: 'req-1',
        requestStatus: ChallengeRequestStatus.pending,
        expiresAt: fixedNow.subtract(const Duration(hours: 1)),
      ),
    );
    final api = FakeArenaChallengeApi();
    final controller = buildController(api: api, persistence: persistence);

    await controller.start();

    expect(controller.state, isA<ChallengeEntryUnavailable>());
    final unavailable = controller.state as ChallengeEntryUnavailable;
    expect(unavailable.status, ChallengeLinkStatus.expired);
    expect(await persistence.readPending(), isNull);
    expect(api.sendCalls, 0);

    controller.dispose();
  });

  test('revoked link clears pending context and promises no replay', () async {
    final api = FakeArenaChallengeApi()
      ..resolution = const ChallengeResolution(
        token: fakeToken,
        status: ChallengeLinkStatus.revoked,
      );
    final persistence = MemoryChallengePersistence();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
    );

    await controller.start();

    expect(controller.state, isA<ChallengeEntryUnavailable>());
    expect(
      (controller.state as ChallengeEntryUnavailable).status,
      ChallengeLinkStatus.revoked,
    );
    expect(await persistence.readPending(), isNull);

    controller.dispose();
    await deepLinks.close();
  });

  test('network failure is retryable and keeps the pending token', () async {
    final api = FakeArenaChallengeApi()
      ..resolveError = const ChallengeApiException.network();
    final persistence = MemoryChallengePersistence();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
    );

    await controller.start();
    expect(controller.state, isA<ChallengeEntryFailure>());
    expect((await persistence.readPending())!.token, fakeToken);

    api.resolveError = null;
    await controller.retry();
    expect(controller.state, isA<ChallengeEntryReview>());

    controller.dispose();
    await deepLinks.close();
  });

  test('warm links open the focused experience while the shell runs',
      () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final deepLinks = FakeChallengeDeepLinks();
    final controller = buildController(
      api: api,
      persistence: persistence,
      deepLinks: deepLinks,
    );

    await controller.start();
    expect(controller.state, isA<ChallengeEntryIdle>());

    deepLinks.emit(Uri.parse('https://example.invalid/c/$fakeToken'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, isA<ChallengeEntryReview>());

    controller.dispose();
    await deepLinks.close();
  });

  test('foreign links never open a challenge', () async {
    final api = FakeArenaChallengeApi();
    final deepLinks = FakeChallengeDeepLinks();
    final controller = buildController(
      api: api,
      persistence: MemoryChallengePersistence(),
      deepLinks: deepLinks,
    );

    await controller.start();
    await controller.handleUri(Uri.parse('https://other.example/c/$fakeToken'));
    expect(controller.state, isA<ChallengeEntryIdle>());
    expect(api.resolveCalls, 0);

    controller.dispose();
    await deepLinks.close();
  });

  test('malformed arena links show unavailable instead of crashing', () async {
    final deepLinks = FakeChallengeDeepLinks();
    final controller = buildController(
      api: FakeArenaChallengeApi(),
      persistence: MemoryChallengePersistence(),
      deepLinks: deepLinks,
    );

    await controller.start();
    await controller.handleUri(Uri.parse('https://example.invalid/c/'));
    expect(controller.state, isA<ChallengeEntryUnavailable>());

    controller.dispose();
    await deepLinks.close();
  });

  test('install referrer recovers a challenge exactly once', () async {
    final api = FakeArenaChallengeApi();
    final persistence = MemoryChallengePersistence();
    final analytics = MemoryChallengeAnalyticsSink();
    final referrer = FakeInstallReferrerSource(
      referrer: 'challenge%3D$fakeToken',
    );
    final first = buildController(
      api: api,
      persistence: persistence,
      referrer: referrer,
      analytics: analytics,
    );

    await first.start();
    expect(first.state, isA<ChallengeEntryReview>());
    expect(
      analytics.eventNames,
      contains(ChallengeAnalyticsEvent.linkOpened),
    );
    final sourceIndex =
        analytics.eventNames.indexOf(ChallengeAnalyticsEvent.linkOpened);
    expect(
      analytics.records[sourceIndex].properties['source'],
      'install_referrer',
    );
    expect(await persistence.isInstallReferrerHandled(), isTrue);
    first.dispose();

    await persistence.clearPending();
    final secondApi = FakeArenaChallengeApi();
    final second = buildController(
      api: secondApi,
      persistence: persistence,
      referrer: referrer,
    );
    await second.start();
    expect(second.state, isA<ChallengeEntryIdle>());
    expect(secondApi.resolveCalls, 0, reason: 'referrer is consumed once');
    second.dispose();
  });

  test('disabled link feature routes to install/update recovery', () async {
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: FakeArenaChallengeApi(),
      persistence: MemoryChallengePersistence(),
      deepLinks: deepLinks,
      challengeLinksEnabled: false,
    );

    await controller.start();
    expect(controller.state, isA<ChallengeEntryInstallRequired>());
    expect(
      (controller.state as ChallengeEntryInstallRequired).token,
      fakeToken,
    );

    controller.dispose();
    await deepLinks.close();
  });

  test('typed code opens the same challenge read-only', () async {
    final api = FakeArenaChallengeApi();
    final controller = buildController(
      api: api,
      persistence: MemoryChallengePersistence(),
      deepLinks: FakeChallengeDeepLinks(),
    );

    await controller.start();
    final opened = await controller.openCode('AB12-CD34-EF56');
    expect(opened, isTrue);
    expect(controller.state, isA<ChallengeEntryReview>());
    expect(api.sendCalls, 0);

    controller.dispose();
  });

  test('dismiss keeps the durable link and pending request', () async {
    final persistence = MemoryChallengePersistence();
    final deepLinks = FakeChallengeDeepLinks(
      initial: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    final controller = buildController(
      api: FakeArenaChallengeApi(),
      persistence: persistence,
      deepLinks: deepLinks,
    );

    await controller.start();
    await controller.acceptChallenge();
    controller.dismiss();

    expect(controller.state, isA<ChallengeEntryIdle>());
    expect((await persistence.readPending())!.requestId, 'req-1');

    controller.dispose();
    await deepLinks.close();
  });
}
