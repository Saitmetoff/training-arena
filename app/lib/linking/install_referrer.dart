/// Play Install Referrer recovery.
///
/// The web landing page sends installs to Play with
/// `referrer=challenge%3D<token>`. The native bridge (task `05` Android
/// config) returns that raw referrer string; parsing stays in Dart so it is
/// testable with fake tokens. Data is best effort: when the referrer is
/// missing the user reopens the App Link or types the short code.
library;

import 'package:flutter/services.dart';

import 'challenge_link.dart';

/// Testable boundary around the Play Install Referrer library.
abstract class InstallReferrerSource {
  /// Raw referrer string from Play, or null when unavailable.
  Future<String?> getInstallReferrer();
}

/// MethodChannel bridge to `InstallReferrerBridge` on Android. Any platform
/// error degrades to null and never blocks startup.
class MethodChannelInstallReferrerSource implements InstallReferrerSource {
  const MethodChannelInstallReferrerSource();

  static const MethodChannel channel =
      MethodChannel('app.trainingarena.mobile/install_referrer');

  @override
  Future<String?> getInstallReferrer() async {
    try {
      return await channel.invokeMethod<String>('getInstallReferrer');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// Extracts a challenge token from a Play referrer string.
///
/// Accepts `challenge=<token>`, `token=<token>`, an encoded
/// `/c/<token>` URL, or an embedded `trainingarena://challenge/<token>`.
/// Returns the normalized token or null. This function performs no I/O.
String? challengeTokenFromReferrer(String? referrer) {
  if (referrer == null || referrer.trim().isEmpty) {
    return null;
  }
  final decoded = _decodeAll(referrer.trim());

  final direct = _directParameter(decoded, 'challenge') ??
      _directParameter(decoded, 'token');
  if (direct != null) {
    final link = ChallengeLink.tryParseText(direct);
    if (link != null) {
      return link.token;
    }
  }

  final uriMatches = RegExp(
    r'(?:trainingarena://challenge/|https?://[^\s"&]+/c/)([A-Za-z0-9]{6,32})',
  ).allMatches(decoded);
  for (final match in uriMatches) {
    final link = ChallengeLink.tryParseText(match.group(1)!);
    if (link != null) {
      return link.token;
    }
  }

  final looseMatch =
      RegExp(r'(?:challenge|token)=([A-Za-z0-9]{6,32})').firstMatch(decoded);
  if (looseMatch != null) {
    final link = ChallengeLink.tryParseText(looseMatch.group(1)!);
    if (link != null) {
      return link.token;
    }
  }
  return null;
}

/// Play may hand back single- or double-encoded values; decode twice so the
/// parser sees real separators without ever throwing.
String _decodeAll(String value) {
  var current = value;
  for (var i = 0; i < 2; i++) {
    try {
      final next = Uri.decodeComponent(current);
      if (next == current) {
        break;
      }
      current = next;
    } on ArgumentError {
      break;
    } on FormatException {
      break;
    }
  }
  return current;
}

String? _directParameter(String value, String key) {
  final uri = Uri.tryParse(value);
  if (uri != null) {
    final fromUri = uri.queryParameters[key];
    if (fromUri != null && fromUri.isNotEmpty) {
      return fromUri;
    }
  }
  final match = RegExp('(?:^|[?&])$key=([^&\\s]+)').firstMatch(value);
  return match?.group(1);
}
