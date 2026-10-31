/// Share-sheet entry for "Challenge a friend".
///
/// The message shape is fixed by task `05`:
/// `@<username> challenges you. Push-ups or squats. 60 seconds. Accept the
/// challenge: <https link>`. Values come from the confirmed runtime account
/// snapshot, never from placeholders.
///
/// Opening the share sheet is not a referral: no recipient profile exists
/// until a recipient sends a request, and the durable link stays valid when
/// the sender leaves the waiting screen.
library;

import 'package:share_plus/share_plus.dart';

import '../config/arena_config.dart';
import '../domain/arena_types.dart';
import 'arena_challenge_api.dart';
import 'challenge_analytics.dart';
import 'challenge_models.dart';

/// Raised when a share cannot be prepared (auth, username, transport).
class ChallengeShareException implements Exception {
  const ChallengeShareException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ChallengeShareException($code): $message';
}

/// Confirmed values used to build one share.
class ChallengeShareResult {
  const ChallengeShareResult({
    required this.message,
    required this.snapshot,
    required this.link,
  });

  final String message;
  final ChallengeAccountSnapshot snapshot;
  final Uri link;

  String get token => snapshot.link.token;

  ArenaProfile get profile => snapshot.profile;
}

/// Builds the exact share message for confirmed runtime values.
String buildChallengeMessage({
  required ArenaProfile profile,
  required Uri link,
}) {
  final username = profile.username?.trim();
  if (username == null || username.isEmpty) {
    throw const ChallengeShareException(
      'username_required',
      'Choose a username before challenging a friend.',
    );
  }
  return '@$username challenges you. Push-ups or squats. 60 seconds. '
      'Accept the challenge: $link';
}

/// Testable boundary around the platform share sheet.
abstract class ShareSheetLauncher {
  Future<void> shareText(String text, {String? subject});
}

/// `share_plus` implementation: opens the Android system share sheet.
class PlatformShareSheetLauncher implements ShareSheetLauncher {
  const PlatformShareSheetLauncher();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}

/// Generates the message and hands it to the platform share sheet.
class ChallengeShareService {
  const ChallengeShareService({
    required ArenaChallengeApi api,
    required ArenaConfig config,
    required ShareSheetLauncher launcher,
    required ChallengeAnalyticsSink analytics,
  })  : _api = api,
        _config = config,
        _launcher = launcher,
        _analytics = analytics;

  final ArenaChallengeApi _api;
  final ArenaConfig _config;
  final ShareSheetLauncher _launcher;
  final ChallengeAnalyticsSink _analytics;

  /// Loads the durable link and username for the share sheet.
  Future<ChallengeAccountSnapshot> loadSnapshot() async {
    try {
      return await _api.accountSnapshot();
    } on ChallengeApiException catch (error) {
      if (error.isUnauthenticated) {
        throw const ChallengeShareException(
          'unauthenticated',
          'Sign in before challenging a friend.',
        );
      }
      throw ChallengeShareException(
        error.code,
        error.message ?? 'The challenge link could not be loaded.',
      );
    }
  }

  /// Opens the share sheet with the confirmed message. [snapshot] may be
  /// passed when the caller prefetched it so the sheet opens without a
  /// visible delay.
  Future<ChallengeShareResult> shareChallenge({
    ChallengeAccountSnapshot? snapshot,
    String source = 'battle',
  }) async {
    final result = await prepareChallenge(snapshot: snapshot);
    await _analytics.track(
      ChallengeAnalyticsEvent.shareSheetOpened,
      <String, Object?>{'source': source},
    );
    await _launcher.shareText(
      result.message,
      subject: 'Fault challenge',
    );
    return result;
  }

  /// Loads the account link without opening a share sheet or sending a request.
  Future<ChallengeShareResult> prepareChallenge({
    ChallengeAccountSnapshot? snapshot,
  }) async {
    final confirmed = snapshot ?? await loadSnapshot();
    final link = _config.challengeLink(confirmed.link.token);
    final message = buildChallengeMessage(
      profile: confirmed.profile,
      link: link,
    );
    return ChallengeShareResult(
      message: message,
      snapshot: confirmed,
      link: link,
    );
  }
}
