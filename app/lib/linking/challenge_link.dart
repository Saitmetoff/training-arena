/// Challenge link parsing and formatting.
///
/// These functions are pure Dart so the app, the web landing page parity
/// checks and every test share one interpretation of a link:
///
/// - shared form: `https://<ARENA_LINK_HOST>/c/<token>`
/// - local fallback: `trainingarena://challenge/<token>`
/// - short code: the token itself, case-insensitive (`docs/API.md`)
///
/// Opening a link never mutates anything. Parsing only extracts identity.
library;

/// Where a challenge link came from. Used by analytics and persistence; the
/// token is the same in every case.
enum ChallengeLinkSource {
  /// HTTPS App Link (`https://<host>/c/<token>`).
  https('https'),

  /// Custom scheme fallback (`trainingarena://challenge/<token>`).
  scheme('scheme'),

  /// Install Referrer recovery after a Play install.
  installReferrer('install_referrer'),

  /// Typed or pasted short code.
  code('code');

  const ChallengeLinkSource(this.wire);

  final String wire;
}

/// A parsed, validated challenge link.
class ChallengeLink {
  const ChallengeLink({
    required this.token,
    required this.source,
    this.raw,
  });

  /// Custom scheme from `docs/decisions/05-challenge-link-interface-decisions.md`.
  static const String scheme = 'trainingarena';

  /// Host component used by [scheme] links.
  static const String schemeHost = 'challenge';

  /// HTTPS path prefix fixed by `docs/API.md`.
  static const String httpsPathPrefix = '/c/';

  /// Canonical 12-character token, but the backend accepts the identifier it
  /// issued; 6-32 characters keeps older/fake tokens parseable while still
  /// rejecting unrelated text.
  static final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9]{6,32}$');

  /// Lowercased token; `docs/API.md` defines input as case-insensitive.
  final String token;

  final ChallengeLinkSource source;

  /// The original URI, when the link came from a deep link.
  final Uri? raw;

  /// Human-readable fallback shown under the landing page and on install.
  /// Groups the code so it can be read aloud; input stays case-insensitive.
  String get readableCode => readableCodeFor(token);

  /// Groups a token into blocks of four for reading aloud.
  static String readableCodeFor(String token) {
    final upper = token.toUpperCase();
    final buffer = StringBuffer();
    for (var i = 0; i < upper.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(upper[i]);
    }
    return buffer.toString();
  }

  /// True when [text] is a bare token (a short code) rather than a link.
  static bool isLikelyCode(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _whitespacePattern.hasMatch(trimmed)) {
      return false;
    }
    return _tokenPattern.hasMatch(trimmed.replaceAll('-', ''));
  }

  static final RegExp _whitespacePattern = RegExp(r'\s');

  /// Parses a deep link.
  ///
  /// [expectedHost] is the configured `ARENA_LINK_HOST`. HTTPS links only
  /// match that host; custom-scheme links only match [schemeHost]. Returns
  /// `null` for unrelated URIs so foreign links never open a landing page.
  static ChallengeLink? tryParse(Uri uri, {String? expectedHost}) {
    final uriScheme = uri.scheme.toLowerCase();
    if (uriScheme == scheme) {
      if (uri.host.toLowerCase() != schemeHost) {
        return null;
      }
      final token = _firstPathSegment(uri);
      if (token == null || !_isValidToken(token)) {
        return null;
      }
      return ChallengeLink(
        token: _normalize(token),
        source: ChallengeLinkSource.scheme,
        raw: uri,
      );
    }
    if (uriScheme == 'https') {
      if (expectedHost != null &&
          expectedHost.isNotEmpty &&
          uri.host.toLowerCase() != expectedHost.toLowerCase()) {
        return null;
      }
      if (!uri.path.startsWith(httpsPathPrefix)) {
        return null;
      }
      final remainder = uri.path.substring(httpsPathPrefix.length);
      final token = remainder.split('/').first;
      if (!_isValidToken(token)) {
        return null;
      }
      return ChallengeLink(
        token: _normalize(token),
        source: ChallengeLinkSource.https,
        raw: uri,
      );
    }
    return null;
  }

  /// Parses pasted text: either a full link or a bare short code.
  static ChallengeLink? tryParseText(String text, {String? expectedHost}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final parsed = tryParse(uri, expectedHost: expectedHost);
      if (parsed != null) {
        return parsed;
      }
      if (uri.scheme.toLowerCase() == scheme ||
          uri.scheme.toLowerCase() == 'https') {
        return null;
      }
    }
    if (_whitespacePattern.hasMatch(trimmed)) {
      return null;
    }
    final code = trimmed.replaceAll('-', '');
    if (!_isValidToken(code)) {
      return null;
    }
    return ChallengeLink(
      token: _normalize(code),
      source: ChallengeLinkSource.code,
    );
  }

  static bool _isValidToken(String token) => _tokenPattern.hasMatch(token);

  static String _normalize(String token) => token.toLowerCase();

  static String? _firstPathSegment(Uri uri) {
    for (final segment in uri.pathSegments) {
      if (segment.isNotEmpty) {
        return segment;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeLink &&
        other.token == token &&
        other.source == source &&
        other.raw == raw;
  }

  @override
  int get hashCode => Object.hash(token, source, raw);

  @override
  String toString() => 'ChallengeLink($token, ${source.wire})';
}
