/// Authentication boundary for the account feature.
///
/// The implementation (`SupabaseAuthGateway`) talks to the configured auth
/// provider; tests and previews use fakes. Nothing above this interface ever
/// sees a raw token beyond the access-token provider handed to the linking
/// and battle HTTP clients.
library;

import '../models/account_models.dart';

/// One signed-in session. Tokens are never logged, displayed or persisted
/// outside the auth session store.
class ArenaAuthSession {
  const ArenaAuthSession({
    required this.accessToken,
    required this.userId,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String userId;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool isExpired(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }
    return !now.isBefore(expiry.subtract(const Duration(seconds: 30)));
  }

  ArenaAuthSession copyWith({
    String? accessToken,
    String? userId,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return ArenaAuthSession(
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// The supported provider routes. Wire values match the analytics contract in
/// `docs/decisions/05-challenge-link-interface-decisions.md`.
enum ArenaAuthMethod {
  google('google'),
  emailCode('email');

  const ArenaAuthMethod(this.wire);

  final String wire;
}

/// Session operations behind which all provider-specific logic lives.
abstract interface class ArenaAuthGateway {
  /// Restores a persisted session, refreshing it when possible and finishing
  /// an interrupted OAuth redirect. Returns null when there is no session.
  Future<ArenaAuthSession?> restoreSession();

  /// Opens the Google provider and completes only after the redirect returns
  /// with a code that this app can exchange. Throws [AccountException]
  /// (`cancelled`, `unconfigured`, `network`, `expired`).
  Future<ArenaAuthSession> signInWithGoogle();

  /// Sends a one-time email code (`otp`). The email is never persisted.
  Future<void> requestEmailCode(String email);

  /// Verifies the emailed code and returns the session.
  Future<ArenaAuthSession> verifyEmailCode({
    required String email,
    required String code,
  });

  /// Exchanges a refresh token; throws `expired` when the session is gone.
  Future<ArenaAuthSession> refreshSession(ArenaAuthSession session);

  /// Best-effort server sign-out; local state is cleared by the caller.
  Future<void> signOut(ArenaAuthSession session);

  /// Clears every locally persisted credential without a server call or an
  /// in-memory session. Used to abandon pending restore/sign-in work before an
  /// identity exists; throws when the device refused the durable clear.
  Future<void> clearLocalAuth();
}

/// Fail-closed gateway used when no provider is configured or in tests that
/// only exercise signed-out surfaces.
class UnavailableArenaAuthGateway implements ArenaAuthGateway {
  const UnavailableArenaAuthGateway();

  static const AccountException _failure = AccountException.unconfigured();

  @override
  Future<ArenaAuthSession?> restoreSession() async => null;

  @override
  Future<ArenaAuthSession> signInWithGoogle() async => throw _failure;

  @override
  Future<void> requestEmailCode(String email) async => throw _failure;

  @override
  Future<ArenaAuthSession> verifyEmailCode({
    required String email,
    required String code,
  }) async =>
      throw _failure;

  @override
  Future<ArenaAuthSession> refreshSession(ArenaAuthSession session) async =>
      throw _failure;

  @override
  Future<void> signOut(ArenaAuthSession session) async {}

  @override
  Future<void> clearLocalAuth() async {}
}

/// Opens an external browser for the provider redirect.
abstract interface class ArenaAuthBrowser {
  Future<bool> open(Uri url);
}

/// Redirect sources delivered back to the app (App Links / custom scheme).
abstract interface class ArenaAuthRedirectLinks {
  Future<Uri?> initialLink();

  Stream<Uri> get links;
}
