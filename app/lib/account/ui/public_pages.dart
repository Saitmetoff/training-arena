/// Public page links (privacy policy, support, external account deletion).
///
/// The pages are static files served from `ARENA_PUBLIC_URL` (the same host as
/// the challenge landing): `/privacy.html`, `/support.html` and
/// `/delete-account.html`. Google Play requires the privacy policy, the
/// support route and a deletion resource reachable without the app, so the
/// Settings screen links all three.
///
/// Until the owner supplies the real host, `ARENA_PUBLIC_URL` stays
/// `https://example.invalid`; [configured] is false and the UI says the pages
/// are not published instead of opening a dead address.
library;

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/arena_config.dart';

/// Testable boundary around the browser/launcher.
abstract class PublicPageLauncher {
  Future<bool> open(Uri url);
}

/// `url_launcher` implementation; failures are non-fatal.
class UrlLauncherPublicPageLauncher implements PublicPageLauncher {
  const UrlLauncherPublicPageLauncher();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Builds and opens the public page URLs for the configured host.
class PublicPages {
  PublicPages({required this.config, PublicPageLauncher? launcher})
      : launcher = launcher ?? const UrlLauncherPublicPageLauncher();

  final ArenaConfig config;
  final PublicPageLauncher launcher;

  /// True only for a real HTTPS host; `example.invalid` and empty values fail
  /// closed so no button opens a placeholder address.
  bool get configured {
    final base = config.publicUrl.trim();
    return base.startsWith('https://') && !base.contains('example.invalid');
  }

  Uri get privacyUrl => _page('privacy.html');
  Uri get supportUrl => _page('support.html');
  Uri get deletionRequestUrl => _page('delete-account.html');

  Uri _page(String name) {
    final base = config.publicUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/$name');
  }

  /// Opens [url] when the host is real; returns false otherwise so the caller
  /// can show an honest notice.
  Future<bool> open(Uri url) {
    if (!configured) {
      return Future<bool>.value(false);
    }
    return launcher.open(url);
  }

  /// Resolves the pages from the ambient [ArenaConfigScope], or `null` when
  /// the scope is absent (tests and previews without configuration).
  static PublicPages? maybeOf(BuildContext context) {
    final config = ArenaConfigScope.maybeOf(context);
    return config == null ? null : PublicPages(config: config);
  }
}
