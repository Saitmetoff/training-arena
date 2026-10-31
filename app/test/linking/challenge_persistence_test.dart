import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_link.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/linking/challenge_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const state = PendingChallengeState(
    token: 'ab12cd34ef56',
    sender: ArenaProfile(id: 'u-zuhra', username: 'zuhra', rating: 1060),
    requestId: 'req-1',
    requestStatus: ChallengeRequestStatus.pending,
    source: ChallengeLinkSource.https,
    receivedAt: null,
  );

  test('memory store round-trips and clears', () async {
    final store = MemoryChallengePersistence();
    expect(await store.readPending(), isNull);
    await store.writePending(state);
    final loaded = await store.readPending();
    expect(loaded!.token, 'ab12cd34ef56');
    expect(loaded.sender!.username, 'zuhra');
    expect(loaded.requestId, 'req-1');
    expect(await store.isInstallReferrerHandled(), isFalse);
    await store.markInstallReferrerHandled();
    expect(await store.isInstallReferrerHandled(), isTrue);
    await store.clearPending();
    expect(await store.readPending(), isNull);
  });

  test('pending state JSON survives a restart round trip', () {
    final json = state.toJson();
    final restored = PendingChallengeState.fromJson(json);
    expect(restored!.token, state.token);
    expect(restored.sender, state.sender);
    expect(restored.requestStatus, ChallengeRequestStatus.pending);
    expect(restored.source, ChallengeLinkSource.https);
  });

  test('expiry only applies to requests without a match', () {
    final expired = state.copyWith(
      expiresAt: DateTime.utc(2020),
    );
    expect(expired.isExpired(DateTime.utc(2026)), isTrue);
    final withMatch = expired.copyWith(matchId: 'm1');
    expect(withMatch.isExpired(DateTime.utc(2026)), isFalse);
    final bareLink = state.copyWith(token: 'ff99ee88dd77');
    expect(bareLink.isExpired(DateTime.utc(2026)), isFalse);
  });

  test('shared preferences store persists pending context and referrer flag',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPreferencesChallengePersistence();
    await store.writePending(state);
    final loaded = await store.readPending();
    expect(loaded!.token, 'ab12cd34ef56');
    expect(await store.isInstallReferrerHandled(), isFalse);
    await store.markInstallReferrerHandled();
    expect(await store.isInstallReferrerHandled(), isTrue);
    await store.clearPending();
    expect(await store.readPending(), isNull);
  });

  test('malformed stored JSON is ignored rather than thrown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesChallengePersistence.pendingKey: '{not json',
    });
    final store = SharedPreferencesChallengePersistence();
    expect(await store.readPending(), isNull);
  });
}
