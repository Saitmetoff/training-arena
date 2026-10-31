/// Sign-in boundary for the challenge landing.
///
/// Account/auth implementation is owned by task `06`; this task only keeps
/// the pending challenge alive across the redirect and resumes the exact
/// link afterwards. Until a real delegate is injected, the default fails
/// closed with an honest message.
library;

import '../domain/arena_types.dart';

/// Supported sign-in routes on the challenge landing.
enum ChallengeAuthMethod {
  google('google'),
  email('email');

  const ChallengeAuthMethod(this.wire);

  final String wire;
}

/// Raised when sign-in cannot proceed (unavailable plugin, cancelled, error).
class ChallengeAuthException implements Exception {
  const ChallengeAuthException(this.code, this.message);

  final String code;
  final String message;

  bool get isUnavailable => code == 'unavailable';

  @override
  String toString() => 'ChallengeAuthException($code): $message';
}

/// Injected by task `06`. Implementations own sessions; task `05` only asks
/// whether a user is signed in and triggers the redirect.
abstract class ChallengeAuthDelegate {
  Future<bool> isSignedIn();

  Future<ArenaProfile?> currentProfile();

  /// Completes after the provider redirect returns. The pending challenge is
  /// persisted by the caller, so a process restart mid-redirect recovers.
  Future<ArenaProfile> signIn(ChallengeAuthMethod method);
}

/// Safe default while task `06` is not wired: no session, no fake sign-in.
class UnavailableChallengeAuthDelegate implements ChallengeAuthDelegate {
  const UnavailableChallengeAuthDelegate();

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<ArenaProfile?> currentProfile() async => null;

  @override
  Future<ArenaProfile> signIn(ChallengeAuthMethod method) async {
    throw const ChallengeAuthException(
      'unavailable',
      'Sign-in arrives with the account task in this build.',
    );
  }
}
