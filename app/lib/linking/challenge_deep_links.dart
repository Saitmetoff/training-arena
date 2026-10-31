/// Deep link sources for challenge links.
///
/// Cold links arrive once at startup; warm links arrive on the stream while
/// the app is running (`singleTop` + `onNewIntent`). Both are the same URI
/// shapes parsed by `ChallengeLink`.
library;

import 'dart:async';

import 'package:app_links/app_links.dart';

/// Testable boundary around the platform deep-link plugin.
abstract class ChallengeDeepLinks {
  /// The link that cold-started the app, if any.
  Future<Uri?> initialLink();

  /// Warm links delivered while the app runs.
  Stream<Uri> get links;
}

/// `app_links`-backed implementation. Platform failures degrade to "no
/// link" instead of crashing the shell.
class AppLinksChallengeDeepLinks implements ChallengeDeepLinks {
  AppLinksChallengeDeepLinks({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> initialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Uri> get links {
    try {
      return _appLinks.uriLinkStream.handleError((Object _) {});
    } catch (_) {
      return const Stream<Uri>.empty();
    }
  }
}
