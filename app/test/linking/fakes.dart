import 'dart:async';

import 'package:training_arena/config/arena_config.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/arena_challenge_api.dart';
import 'package:training_arena/linking/challenge_auth.dart';
import 'package:training_arena/linking/challenge_deep_links.dart';
import 'package:training_arena/linking/challenge_install_view.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/linking/challenge_share.dart';
import 'package:training_arena/linking/install_referrer.dart';

const String fakeToken = 'ab12cd34ef56';
const String fakeOtherToken = 'ff99ee88dd77';
const String fakeOwnerId = 'u-zuhra';
const String fakeMatchId = '11111111-2222-3333-4444-555555555555';

ArenaProfile fakeOwner({String username = 'zuhra'}) => ArenaProfile(
      id: fakeOwnerId,
      username: username,
      rating: 1060,
    );

ArenaConfig testConfig({
  bool challengeLinksEnabled = true,
  bool cameraCountingEnabled = false,
  bool rankedMatchmakingEnabled = false,
  bool soloModeEnabled = false,
  String linkHost = 'example.invalid',
  String supabaseUrl = 'https://project.invalid',
  String supabaseAnonKey = 'anon-public',
}) {
  return ArenaConfig(
    publicUrl: 'https://example.invalid',
    linkHost: linkHost,
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
    challengeLinksEnabled: challengeLinksEnabled,
    cameraCountingEnabled: cameraCountingEnabled,
    rankedMatchmakingEnabled: rankedMatchmakingEnabled,
    soloModeEnabled: soloModeEnabled,
  );
}

class FakeArenaChallengeApi implements ArenaChallengeApi {
  ChallengeResolution resolution = ChallengeResolution(
    token: fakeToken,
    status: ChallengeLinkStatus.available,
    owner: fakeOwner(),
  );

  Object? resolveError;
  Object? sendError;
  Object? respondError;
  Object? snapshotError;

  ChallengeRequest request = ChallengeRequest(
    id: 'req-1',
    status: ChallengeRequestStatus.pending,
    expiresAt: DateTime.utc(2030),
  );

  ChallengeRequest? existingOutgoing;
  String? activeMatchId;

  int resolveCalls = 0;
  int sendCalls = 0;
  int respondCalls = 0;
  int snapshotCalls = 0;
  String? lastSentToken;
  String? lastRespondRequestId;
  ChallengeRequestResponse? lastRespondResponse;
  final List<String> trackedEvents = <String>[];
  final List<Map<String, Object?>> trackedProperties =
      <Map<String, Object?>>[];

  @override
  Future<ChallengeResolution> resolveLink(String token) async {
    resolveCalls += 1;
    final failure = resolveError;
    if (failure != null) {
      throw failure;
    }
    return resolution.copyWith(token: token);
  }

  @override
  Future<ChallengeRequest> sendRequest(String token) async {
    sendCalls += 1;
    lastSentToken = token;
    final failure = sendError;
    if (failure != null) {
      throw failure;
    }
    return request;
  }

  @override
  Future<ChallengeRequest> respondToRequest(
    String requestId,
    ChallengeRequestResponse response,
  ) async {
    respondCalls += 1;
    lastRespondRequestId = requestId;
    lastRespondResponse = response;
    final failure = respondError;
    if (failure != null) {
      throw failure;
    }
    return ChallengeRequest(
      id: requestId,
      status: response == ChallengeRequestResponse.cancel
          ? ChallengeRequestStatus.cancelled
          : ChallengeRequestStatus.declined,
    );
  }

  @override
  Future<ChallengeAccountSnapshot> accountSnapshot() async {
    snapshotCalls += 1;
    final failure = snapshotError;
    if (failure != null) {
      throw failure;
    }
    return ChallengeAccountSnapshot(
      profile: fakeOwner(username: 'azizbek'),
      link: const ChallengeLinkInfo(token: fakeToken, code: fakeToken),
      activeMatchId: activeMatchId,
    );
  }

  @override
  Future<ChallengeRequest?> pendingOutgoingRequestTo(String ownerId) async {
    return existingOutgoing;
  }

  @override
  Future<void> trackEvent(
    String event,
    Map<String, Object?> properties,
  ) async {
    trackedEvents.add(event);
    trackedProperties.add(properties);
  }
}

class FakeChallengeDeepLinks implements ChallengeDeepLinks {
  FakeChallengeDeepLinks({this.initial});

  Uri? initial;
  final StreamController<Uri> controller =
      StreamController<Uri>.broadcast(sync: true);

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => controller.stream;

  void emit(Uri uri) => controller.add(uri);

  Future<void> close() => controller.close();
}

class FakeInstallReferrerSource implements InstallReferrerSource {
  FakeInstallReferrerSource({this.referrer});

  String? referrer;

  @override
  Future<String?> getInstallReferrer() async => referrer;
}

class FakeChallengeAuthDelegate implements ChallengeAuthDelegate {
  FakeChallengeAuthDelegate({this.signedIn = true, ArenaProfile? profile})
      : profile = profile ?? fakeOwner(username: 'azizbek');

  bool signedIn;
  ArenaProfile profile;
  ChallengeAuthException? signInFailure;
  int signInCalls = 0;

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<ArenaProfile?> currentProfile() async => signedIn ? profile : null;

  @override
  Future<ArenaProfile> signIn(ChallengeAuthMethod method) async {
    signInCalls += 1;
    final failure = signInFailure;
    if (failure != null) {
      throw failure;
    }
    signedIn = true;
    return profile;
  }
}

class FakeShareSheetLauncher implements ShareSheetLauncher {
  final List<String> sharedTexts = <String>[];
  final List<String?> subjects = <String?>[];

  @override
  Future<void> shareText(String text, {String? subject}) async {
    sharedTexts.add(text);
    subjects.add(subject);
  }
}

class FakeChallengeInstallLauncher implements ChallengeInstallLauncher {
  final List<Uri> opened = <Uri>[];
  bool result = true;

  @override
  Future<bool> openPlayStore(Uri url) async {
    opened.add(url);
    return result;
  }
}
