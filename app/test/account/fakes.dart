/// Test doubles for the account/auth/leaderboard feature.
///
/// Everything runs in memory: the auth gateway, the arena account API, the
/// avatar picker and the interactive prompts. No provider, network, platform
/// channel or token logging is involved.
library;

import 'dart:async';

import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/challenge/auth_prompts.dart';
import 'package:training_arena/account/data/account_api.dart';
import 'package:training_arena/account/avatar/avatar_picker.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/domain/arena_types.dart';

const String fakeViewerId = 'viewer-0001';
const String fakeOpponentId = 'opponent-0002';
const String fakeMatchId = 'match-0003';
const String fakeAccessToken = 'access-token-value';
const String fakeRefreshToken = 'refresh-token-value';

ArenaProfile fakeViewer({
  String? username = 'azizbek',
  String? avatarUrl,
  int rating = 1016,
  int rankedWins = 1,
  int rankedBattles = 2,
}) {
  return ArenaProfile(
    id: fakeViewerId,
    username: username,
    avatarUrl: avatarUrl,
    rating: rating,
    rankedWins: rankedWins,
    rankedBattles: rankedBattles,
  );
}

ArenaProfile fakeOpponent({String username = 'zuhra'}) {
  return ArenaProfile(
    id: fakeOpponentId,
    username: username,
    rating: 1060,
    rankedWins: 3,
    rankedBattles: 4,
  );
}

ResultReceipt fakeReceipt({
  String id = 'receipt-1',
  ArenaMatchMode mode = ArenaMatchMode.ranked,
  ArenaMatchOutcome outcome = ArenaMatchOutcome.win,
  String? winnerId = fakeViewerId,
  DateTime? finishedAt,
  String? reason,
  int viewerScore = 26,
  int opponentScore = 23,
  int? viewerRatingChange = 8,
  int? viewerRatingAfter = 1024,
}) {
  return ResultReceipt(
    id: id,
    matchId: fakeMatchId,
    exercise: ArenaExercise.pushUps,
    mode: mode,
    players: <ArenaReceiptPlayer>[
      ArenaReceiptPlayer(
        profile: fakeViewer(),
        score: viewerScore,
        ratingAfter: mode == ArenaMatchMode.ranked ? viewerRatingAfter : null,
        ratingChange: mode == ArenaMatchMode.ranked ? viewerRatingChange : null,
      ),
      ArenaReceiptPlayer(
        profile: fakeOpponent(),
        score: opponentScore,
        ratingAfter: mode == ArenaMatchMode.ranked ? 992 : null,
        ratingChange: mode == ArenaMatchMode.ranked ? -8 : null,
      ),
    ],
    outcome: outcome,
    winnerId: outcome == ArenaMatchOutcome.win ? winnerId : null,
    finishedAt: finishedAt,
    reason: reason,
  );
}

/// In-memory [ArenaAuthGateway]. Failures throw [AccountException] exactly as
/// the production gateway does; tokens and emails are only recorded for
/// assertions, never logged.
class FakeArenaAuthGateway implements ArenaAuthGateway {
  FakeArenaAuthGateway({
    this.restoredSession,
    ArenaAuthSession? session,
  }) : session = session ??
            const ArenaAuthSession(
              accessToken: fakeAccessToken,
              userId: fakeViewerId,
              refreshToken: fakeRefreshToken,
            );

  ArenaAuthSession? restoredSession;
  ArenaAuthSession session;

  Object? restoreError;
  Object? googleError;
  Object? requestEmailError;
  Object? verifyError;
  Object? refreshError;
  Object? signOutError;
  Object? clearLocalError;

  int clearLocalCalls = 0;
  int restoreCalls = 0;
  int googleCalls = 0;
  int requestEmailCalls = 0;
  int verifyCalls = 0;
  int refreshCalls = 0;
  int signOutCalls = 0;

  String? lastRequestedEmail;
  String? lastVerifiedEmail;
  String? lastVerifiedCode;
  ArenaAuthSession? lastSignedOutSession;

  @override
  Future<ArenaAuthSession?> restoreSession() async {
    restoreCalls += 1;
    final failure = restoreError;
    if (failure != null) {
      throw failure;
    }
    return restoredSession;
  }

  @override
  Future<ArenaAuthSession> signInWithGoogle() async {
    googleCalls += 1;
    final failure = googleError;
    if (failure != null) {
      throw failure;
    }
    return session;
  }

  @override
  Future<void> requestEmailCode(String email) async {
    requestEmailCalls += 1;
    lastRequestedEmail = email;
    final failure = requestEmailError;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<ArenaAuthSession> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    verifyCalls += 1;
    lastVerifiedEmail = email;
    lastVerifiedCode = code;
    final failure = verifyError;
    if (failure != null) {
      throw failure;
    }
    return session;
  }

  @override
  Future<ArenaAuthSession> refreshSession(ArenaAuthSession session) async {
    refreshCalls += 1;
    final failure = refreshError;
    if (failure != null) {
      throw failure;
    }
    final refreshed = session.copyWith(
      accessToken: 'refreshed-access-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    this.session = refreshed;
    return refreshed;
  }

  @override
  Future<void> signOut(ArenaAuthSession session) async {
    signOutCalls += 1;
    lastSignedOutSession = session;
    final failure = signOutError;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> clearLocalAuth() async {
    clearLocalCalls += 1;
    final failure = clearLocalError;
    if (failure != null) {
      throw failure;
    }
  }
}

/// In-memory [AccountApi] with scripted results and call recording.
class FakeAccountApi implements AccountApi {
  FakeAccountApi({ArenaProfile? profile})
      : profile = profile ?? fakeViewer();

  ArenaProfile profile;

  Object? profileError;
  Object? updateUsernameError;
  Object? updateAvatarError;
  Object? removeAvatarError;
  Object? leaderboardError;
  Object? historyError;
  Object? publicProfileError;
  Object? reportError;
  Object? blockError;
  Object? unblockError;
  Object? blockedError;
  Object? deleteError;

  List<ArenaLeaderboardEntry> leaderboardEntries =
      const <ArenaLeaderboardEntry>[];
  List<ResultReceipt> receipts = const <ResultReceipt>[];
  Map<String, ArenaProfile> publicProfiles = <String, ArenaProfile>{};
  List<ArenaProfile> blockedProfiles = const <ArenaProfile>[];

  int profileCalls = 0;
  int historyCalls = 0;
  int leaderboardCalls = 0;
  int publicProfileCalls = 0;
  int reportCalls = 0;
  int blockCalls = 0;
  int unblockCalls = 0;
  int blockedCalls = 0;
  int deleteCalls = 0;

  String? lastUsernameUpdate;
  String? lastAvatarBase64;
  String? lastAvatarMimeType;
  String? lastReportTarget;
  String? lastReportMatchId;
  String? lastReportReason;
  String? lastBlockTarget;
  String? lastUnblockTarget;
  String? lastPublicProfileId;

  @override
  Future<ArenaProfile> fetchProfile() async {
    profileCalls += 1;
    final failure = profileError;
    if (failure != null) {
      throw failure;
    }
    return profile;
  }

  @override
  Future<ArenaProfile> updateUsername(String username) async {
    lastUsernameUpdate = username;
    final failure = updateUsernameError;
    if (failure != null) {
      throw failure;
    }
    profile = ArenaProfile(
      id: profile.id,
      username: username,
      avatarUrl: profile.avatarUrl,
      rating: profile.rating,
      rankedWins: profile.rankedWins,
      rankedBattles: profile.rankedBattles,
    );
    return profile;
  }

  @override
  Future<ArenaProfile> updateAvatar({
    required String base64,
    required String mimeType,
  }) async {
    lastAvatarBase64 = base64;
    lastAvatarMimeType = mimeType;
    final failure = updateAvatarError;
    if (failure != null) {
      throw failure;
    }
    profile = ArenaProfile(
      id: profile.id,
      username: profile.username,
      avatarUrl: 'https://cdn.invalid/avatars/${profile.id}.jpg',
      rating: profile.rating,
      rankedWins: profile.rankedWins,
      rankedBattles: profile.rankedBattles,
    );
    return profile;
  }

  @override
  Future<ArenaProfile> removeAvatar() async {
    final failure = removeAvatarError;
    if (failure != null) {
      throw failure;
    }
    profile = ArenaProfile(
      id: profile.id,
      username: profile.username,
      rating: profile.rating,
      rankedWins: profile.rankedWins,
      rankedBattles: profile.rankedBattles,
    );
    return profile;
  }

  @override
  Future<List<ArenaLeaderboardEntry>> leaderboard() async {
    leaderboardCalls += 1;
    final failure = leaderboardError;
    if (failure != null) {
      throw failure;
    }
    return leaderboardEntries;
  }

  @override
  Future<List<ResultReceipt>> history() async {
    historyCalls += 1;
    final failure = historyError;
    if (failure != null) {
      throw failure;
    }
    return receipts;
  }

  @override
  Future<ArenaProfile> publicProfile(String userId) async {
    publicProfileCalls += 1;
    lastPublicProfileId = userId;
    final failure = publicProfileError;
    if (failure != null) {
      throw failure;
    }
    return publicProfiles[userId] ?? fakeOpponent();
  }

  @override
  Future<void> report({
    required String targetUserId,
    String? matchId,
    required String reason,
  }) async {
    reportCalls += 1;
    lastReportTarget = targetUserId;
    lastReportMatchId = matchId;
    lastReportReason = reason;
    final failure = reportError;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> block(String targetUserId) async {
    blockCalls += 1;
    lastBlockTarget = targetUserId;
    final failure = blockError;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> unblock(String targetUserId) async {
    unblockCalls += 1;
    lastUnblockTarget = targetUserId;
    final failure = unblockError;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<List<ArenaProfile>> blocked() async {
    blockedCalls += 1;
    final failure = blockedError;
    if (failure != null) {
      throw failure;
    }
    return blockedProfiles;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls += 1;
    final failure = deleteError;
    if (failure != null) {
      throw failure;
    }
  }
}

/// Picker that returns a scripted upload (or null for cancel) and records
/// every call. There is no camera path at all.
class FakeAvatarPicker implements AvatarPicker {
  FakeAvatarPicker({this.upload});

  AvatarUpload? upload;
  Object? pickError;
  int pickCalls = 0;

  @override
  Future<AvatarUpload?> pickFromLibrary() async {
    pickCalls += 1;
    final failure = pickError;
    if (failure != null) {
      throw failure;
    }
    return upload;
  }
}

/// Scripted [ChallengeAuthPrompts].
class FakeChallengeAuthPrompts implements ChallengeAuthPrompts {
  FakeChallengeAuthPrompts({
    List<String?>? emails,
    List<String?>? codes,
    List<String?>? usernames,
  })  : emails = emails ?? <String?>[],
        codes = codes ?? <String?>[],
        usernames = usernames ?? <String?>[];

  final List<String?> emails;
  final List<String?> codes;
  final List<String?> usernames;

  int emailCalls = 0;
  int codeCalls = 0;
  int usernameCalls = 0;
  final List<String?> usernameMessages = <String?>[];

  @override
  Future<String?> requestEmail() async {
    emailCalls += 1;
    if (emails.isEmpty) {
      return null;
    }
    return emails.removeAt(0);
  }

  @override
  Future<String?> requestCode(String email) async {
    codeCalls += 1;
    if (codes.isEmpty) {
      return null;
    }
    return codes.removeAt(0);
  }

  @override
  Future<String?> requestUsername({String? message}) async {
    usernameCalls += 1;
    usernameMessages.add(message);
    if (usernames.isEmpty) {
      return null;
    }
    return usernames.removeAt(0);
  }
}

/// A minimal valid JPEG byte sequence (header sniff only; never a camera
/// frame).
List<int> fakeJpegBytes({int length = 64}) {
  final bytes = List<int>.filled(length, 0);
  bytes[0] = 0xff;
  bytes[1] = 0xd8;
  bytes[2] = 0xff;
  bytes[length - 1] = 0xd9;
  return bytes;
}

/// Raw camera-like bytes: no image signature at all.
List<int> fakeCameraFrameBytes({int length = 64}) {
  return List<int>.generate(length, (index) => index % 256);
}
