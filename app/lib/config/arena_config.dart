import 'package:flutter/widgets.dart';

/// Compile-time arena configuration.
///
/// Values come from `--dart-define`, for example:
///
/// ```sh
/// flutter run --dart-define=ARENA_LINK_HOST=arena.example
/// ```
///
/// Only public client values belong here. Service-role keys are server
/// side only and must never be committed to the app or its build flags.
/// Public URL, link host, Supabase URL/anon key and feature flags are
/// additive: later tasks add keys, they do not rename existing ones.
class ArenaConfig {
  const ArenaConfig({
    required this.publicUrl,
    required this.linkHost,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.playStoreUrl = defaultPlayStoreUrl,
    this.authRedirectUrl = '',
    this.cameraCountingEnabled = false,
    this.cameraTraceEnabled = false,
    this.challengeLinksEnabled = false,
    this.rankedMatchmakingEnabled = false,
    this.resultSharingEnabled = false,
    this.pushNotificationsEnabled = false,
    this.previewFixturesEnabled = false,
    this.soloModeEnabled = false,
  });

  /// Safe placeholder used until the owner supplies the real HTTPS
  /// challenge domain.
  static const String defaultLinkHost = 'example.invalid';
  static const String defaultPublicUrl = 'https://example.invalid';

  /// Supported Play route for installing or updating the app. The package
  /// name is the frozen application ID from `docs/CONTRACT.md`.
  static const String defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=app.trainingarena.mobile';

  /// Default instance evaluated at compile time.
  static const ArenaConfig fromEnvironment = ArenaConfig(
    publicUrl: String.fromEnvironment(
      'ARENA_PUBLIC_URL',
      defaultValue: defaultPublicUrl,
    ),
    linkHost: String.fromEnvironment(
      'ARENA_LINK_HOST',
      defaultValue: defaultLinkHost,
    ),
    supabaseUrl: String.fromEnvironment('ARENA_SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('ARENA_SUPABASE_ANON_KEY'),
    playStoreUrl: String.fromEnvironment(
      'ARENA_PLAY_STORE_URL',
      defaultValue: defaultPlayStoreUrl,
    ),
    authRedirectUrl: String.fromEnvironment('ARENA_AUTH_REDIRECT_URL'),
    cameraCountingEnabled:
        bool.fromEnvironment('ARENA_FEATURE_CAMERA_COUNTING'),
    cameraTraceEnabled: bool.fromEnvironment('ARENA_FEATURE_CAMERA_TRACE'),
    challengeLinksEnabled:
        bool.fromEnvironment('ARENA_FEATURE_CHALLENGE_LINKS'),
    rankedMatchmakingEnabled:
        bool.fromEnvironment('ARENA_FEATURE_RANKED_MATCHMAKING'),
    resultSharingEnabled: bool.fromEnvironment('ARENA_FEATURE_RESULT_SHARING'),
    pushNotificationsEnabled:
        bool.fromEnvironment('ARENA_FEATURE_PUSH_NOTIFICATIONS'),
    previewFixturesEnabled:
        bool.fromEnvironment('ARENA_FEATURE_PREVIEW_FIXTURES'),
    soloModeEnabled: bool.fromEnvironment('ARENA_FEATURE_SOLO_MODE'),
  );

  /// Public site URL (scheme + host) used for shared content.
  final String publicUrl;

  /// Host that serves challenge links; `example.invalid` until the owner
  /// provides a real domain.
  final String linkHost;

  /// Supabase project URL. Empty until a project exists.
  final String supabaseUrl;

  /// Supabase anon (public) key. Never a service-role key.
  final String supabaseAnonKey;

  /// Supported Play install/update URL (task `05` landing and recovery).
  final String playStoreUrl;

  /// OAuth redirect registered with the auth provider (task `06`). Empty
  /// until the release task supplies the allowlisted URL; sign-in then fails
  /// closed with plain copy instead of opening a broken redirect.
  final String authRedirectUrl;

  final bool cameraCountingEnabled;

  /// Debug-only landmark tracing (task F3): keeps the last minutes of landmark
  /// numbers and lets the owner export them for the replay harness. Numbers
  /// only, no image. Always false in a release build; the release hold check
  /// pins it.
  final bool cameraTraceEnabled;

  final bool challengeLinksEnabled;
  final bool rankedMatchmakingEnabled;
  final bool resultSharingEnabled;

  /// Enables request push notifications (permission prompt, token
  /// registration and tap routing). Default false: without a configured
  /// Firebase project the app stays fully usable through the inbox.
  final bool pushNotificationsEnabled;

  /// Deterministic preview fixtures for design review. Never enable in a
  /// release build; fixtures cannot produce receipts.
  final bool previewFixturesEnabled;

  /// Enables the local, non-competitive solo max-reps set (decision 12).
  /// It never creates a receipt, rating or leaderboard entry.
  final bool soloModeEnabled;

  bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// `https://<linkHost>/c/<token>` as fixed by `docs/API.md`.
  Uri challengeLink(String token) => Uri.https(linkHost, '/c/$token');

  /// `trainingarena://challenge/<token>` local fallback, never shared in
  /// messages and never used as the referral identity.
  Uri schemeChallengeLink(String token) =>
      Uri.parse('trainingarena://challenge/$token');

  /// Play URL carrying the install-referrer token so the app can recover the
  /// challenge after installation.
  Uri installReferrerUrl(String token) => Uri.parse(playStoreUrl).replace(
        queryParameters: <String, String>{
          ...Uri.parse(playStoreUrl).queryParameters,
          'referrer': 'challenge=$token',
        },
      );
}

/// Makes [ArenaConfig] available to the widget tree without touching the
/// Supabase or camera layers.
class ArenaConfigScope extends InheritedWidget {
  const ArenaConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  final ArenaConfig config;

  static ArenaConfig of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ArenaConfigScope>();
    assert(scope != null, 'No ArenaConfigScope above this widget.');
    return scope!.config;
  }

  /// Same as [of] but `null` when no scope is present (tests, previews).
  static ArenaConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ArenaConfigScope>()
        ?.config;
  }

  @override
  bool updateShouldNotify(ArenaConfigScope oldWidget) =>
      config != oldWidget.config;
}
