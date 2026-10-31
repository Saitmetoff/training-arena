import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/linking/challenge_share.dart';

import 'fakes.dart';

void main() {
  test('message matches the contract shape with confirmed runtime values', () {
    final message = buildChallengeMessage(
      profile: const ArenaProfile(id: 'u-you', username: 'azizbek'),
      link: Uri.parse('https://example.invalid/c/$fakeToken'),
    );
    expect(
      message,
      '@azizbek challenges you. Push-ups or squats. 60 seconds. '
      'Accept the challenge: https://example.invalid/c/$fakeToken',
    );
  });

  test('missing username refuses to invent a handle', () {
    expect(
      () => buildChallengeMessage(
        profile: const ArenaProfile(id: 'u-you'),
        link: Uri.parse('https://example.invalid/c/$fakeToken'),
      ),
      throwsA(
        isA<ChallengeShareException>()
            .having((error) => error.code, 'code', 'username_required'),
      ),
    );
  });

  test('share service opens the sheet with the API-confirmed link', () async {
    final api = FakeArenaChallengeApi();
    final launcher = FakeShareSheetLauncher();
    final analytics = MemoryChallengeAnalyticsSink();
    final service = ChallengeShareService(
      api: api,
      config: testConfig(),
      launcher: launcher,
      analytics: analytics,
    );

    final result = await service.shareChallenge(source: 'battle');

    expect(launcher.sharedTexts, hasLength(1));
    expect(launcher.sharedTexts.single, contains('@azizbek challenges you.'));
    expect(launcher.sharedTexts.single, contains('/c/$fakeToken'));
    expect(result.token, fakeToken);
    expect(
      analytics.eventNames,
      contains(ChallengeAnalyticsEvent.shareSheetOpened),
    );
    expect(api.sendCalls, 0, reason: 'sharing never creates a request');
  });

  test('signed-out sharing asks for sign-in without inventing a link',
      () async {
    final api = FakeArenaChallengeApi()
      ..snapshotError = const ChallengeApiException.unauthenticated();
    final service = ChallengeShareService(
      api: api,
      config: testConfig(),
      launcher: FakeShareSheetLauncher(),
      analytics: MemoryChallengeAnalyticsSink(),
    );

    expect(
      () => service.shareChallenge(),
      throwsA(
        isA<ChallengeShareException>()
            .having((error) => error.code, 'code', 'unauthenticated'),
      ),
    );
  });
}
