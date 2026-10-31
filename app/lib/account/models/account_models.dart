/// Account feature value objects.
///
/// These types stay inside task `06` paths: they add the leaderboard rank,
/// username/avatar rules and the account failure surface without changing the
/// shared `app/lib/domain/arena_types.dart` contract.
library;

import '../../domain/arena_types.dart';

/// One leaderboard row as returned by the `leaderboard` action.
///
/// The backend already appends the viewer's own profile when it falls outside
/// the top page, so the client renders exactly what the server confirmed.
class ArenaLeaderboardEntry {
  const ArenaLeaderboardEntry({required this.profile, required this.rank});

  final ArenaProfile profile;

  /// Dense-independent rank from the server (`rank()` over the full ladder).
  final int rank;

  bool isViewer(String? viewerId) =>
      viewerId != null && profile.id == viewerId;

  @override
  bool operator ==(Object other) {
    return other is ArenaLeaderboardEntry &&
        other.profile == profile &&
        other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(profile, rank);
}

/// A safe public player card: public profile fields plus optional ladder rank.
///
/// It deliberately has no email, token, camera or auth fields; the API never
/// returns them for `profile_public`.
class ArenaPublicPlayer {
  const ArenaPublicPlayer({required this.profile, this.rank});

  final ArenaProfile profile;
  final int? rank;

  String get displayName => profile.username ?? 'player';
}

/// The fixed arena round length from `docs/API.md` (60 seconds).
const int arenaRoundSeconds = 60;

/// A picked image waiting to be validated and uploaded.
class AvatarUpload {
  const AvatarUpload({required this.bytes, required this.mimeType});

  final List<int> bytes;

  /// Declared MIME type; the server also sniffs the bytes and rejects
  /// anything that is not JPEG/PNG/WebP.
  final String mimeType;

  int get sizeBytes => bytes.length;
}

/// Backend image limits from `supabase/functions/arena/lib/avatar.ts`.
abstract final class ArenaAvatarLimits {
  static const int maxBytes = 2 * 1024 * 1024;

  static const Set<String> mimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  /// Sniffs the file signature; null when the bytes are not a supported
  /// image. Camera frame data (YUV/raw) never matches.
  static String? sniffMimeType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  /// Actionable client message for an invalid upload; null when it is safe to
  /// send. The server remains the final authority.
  static String? validationMessage(AvatarUpload upload) {
    if (upload.bytes.isEmpty) {
      return 'That file is empty. Choose a JPEG, PNG or WebP photo.';
    }
    if (upload.sizeBytes > maxBytes) {
      return 'That photo is larger than 2 MB. Choose a smaller one.';
    }
    final sniffed = sniffMimeType(upload.bytes);
    if (sniffed == null) {
      return 'That file is not a supported image. Choose a JPEG, PNG or WebP photo.';
    }
    if (sniffed != upload.mimeType) {
      return 'That photo does not match its file type. Choose another.';
    }
    return null;
  }
}

/// Username rules mirrored from the backend (`arena_update_profile` in
/// `supabase/migrations`) so errors are actionable before the round trip.
/// Uniqueness is never decided locally: the database unique index owns it.
abstract final class ArenaUsername {
  static const int minLength = 3;
  static const int maxLength = 20;

  static final RegExp pattern = RegExp(r'^[A-Za-z0-9_]{3,20}$');

  static const Set<String> reserved = <String>{
    'arena',
    'admin',
    'administrator',
    'support',
    'moderator',
    'trainingarena',
    'system',
    'official',
    'mod',
    'staff',
  };

  /// Trims surrounding whitespace; no other transformation is applied.
  static String normalize(String raw) => raw.trim();

  /// True when two usernames are the same account name (case-insensitive).
  static bool isSame(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Null when [raw] can be sent to the server; otherwise an actionable
  /// sentence. The caller still handles `username_taken` from the server.
  static String? validationMessage(String raw) {
    final value = normalize(raw);
    if (value.isEmpty) {
      return 'Choose a username.';
    }
    if (value.length < minLength) {
      return 'Use at least $minLength characters.';
    }
    if (value.length > maxLength) {
      return 'Use at most $maxLength characters.';
    }
    if (!pattern.hasMatch(value)) {
      return 'Use letters, digits and underscore only.';
    }
    if (reserved.contains(value.toLowerCase())) {
      return 'That username is reserved. Try another.';
    }
    return null;
  }
}

/// Email-code sign-in input rules. The address is used only for the in-flight
/// code request and is never stored, displayed or logged.
abstract final class ArenaEmail {
  static final RegExp _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalize(String raw) => raw.trim();

  static String? validationMessage(String raw) {
    final value = normalize(raw);
    if (value.isEmpty) {
      return 'Enter your email address.';
    }
    if (value.length > 254 || !_pattern.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}

/// Failure surface for account and auth operations.
///
/// [code] follows the server catalogue when the backend answered
/// (`username_taken`, `username_invalid`, `avatar_too_large`, ...) or a
/// client code for local failures (`network`, `cancelled`, `unconfigured`,
/// `malformed_response`). Messages never include tokens or email addresses.
class AccountException implements Exception {
  const AccountException(this.code, this.message, {this.statusCode});

  const AccountException.network()
      : code = 'network',
        message = 'You are offline. Check your connection and try again.',
        statusCode = null;

  const AccountException.unauthenticated()
      : code = 'unauthenticated',
        message = 'Sign in to continue.',
        statusCode = null;

  const AccountException.unconfigured()
      : code = 'unconfigured',
        message = 'Accounts are not configured in this build.',
        statusCode = null;

  const AccountException.malformed()
      : code = 'malformed_response',
        message = 'The arena returned an unexpected response.',
        statusCode = null;

  final String code;
  final String message;
  final int? statusCode;

  bool get isUnauthenticated =>
      code == 'unauthenticated' ||
      code == 'unauthorized' ||
      statusCode == 401 ||
      statusCode == 403;

  bool get isRetryable =>
      code == 'network' ||
      code == 'malformed_response' ||
      (statusCode ?? 0) >= 500;

  @override
  String toString() => 'AccountException($code)';
}
