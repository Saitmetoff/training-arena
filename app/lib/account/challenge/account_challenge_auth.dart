/// Challenge sign-in delegate backed by the account controller.
///
/// Task `05` keeps the pending challenge alive across the redirect; this
/// bridge runs the real provider sign-in, claims the first username when the
/// backend has none, and returns the public profile. No generic onboarding is
/// inserted: every prompt is a step of this sign-in and the exact challenge
/// token is preserved by the caller.
library;

import '../../domain/arena_types.dart';
import '../../linking/challenge_auth.dart';
import '../models/account_models.dart';
import '../runtime/account_controller.dart';
import 'auth_prompts.dart';

/// [ChallengeAuthDelegate] over [AccountController].
class AccountChallengeAuthDelegate implements ChallengeAuthDelegate {
  AccountChallengeAuthDelegate({
    required AccountController controller,
    ChallengeAuthPrompts prompts = const CancellingChallengeAuthPrompts(),
  })  : _controller = controller,
        _prompts = prompts;

  final AccountController _controller;
  final ChallengeAuthPrompts _prompts;

  @override
  Future<bool> isSignedIn() async => _controller.signedIn;

  @override
  Future<ArenaProfile?> currentProfile() async => _controller.profile;

  @override
  Future<ArenaProfile> signIn(ChallengeAuthMethod method) async {
    try {
      return await _run(method);
    } on AccountException catch (error) {
      throw ChallengeAuthException(_codeFor(error), error.message);
    }
  }

  Future<ArenaProfile> _run(ChallengeAuthMethod method) async {
    if (!_controller.signedIn) {
      switch (method) {
        case ChallengeAuthMethod.google:
          await _controller.signInWithGoogle();
        case ChallengeAuthMethod.email:
          final email = await _prompts.requestEmail();
          if (email == null) {
            throw const AccountException(
              'cancelled',
              'Sign-in was cancelled. Your challenge is still saved.',
            );
          }
          await _controller.requestEmailCode(email);
          final code = await _prompts.requestCode(email);
          if (code == null) {
            throw const AccountException(
              'cancelled',
              'Sign-in was cancelled. Your challenge is still saved.',
            );
          }
          await _controller.verifyEmailCode(email: email, code: code);
      }
    }

    var profile = _controller.profile ?? await _controller.refreshProfile();
    var message = profile.username == null
        ? 'Choose a username to accept the challenge.'
        : null;
    var attempts = 0;
    while (profile.username == null || profile.username!.isEmpty) {
      if (attempts >= 4) {
        throw AccountException(
          'username_invalid',
          message ?? 'That username is not accepted. Try another.',
        );
      }
      attempts += 1;
      final raw = await _prompts.requestUsername(message: message);
      if (raw == null) {
        throw const AccountException(
          'username_required',
          'Choose a username to accept the challenge. Your challenge is saved.',
        );
      }
      try {
        profile = await _controller.claimUsername(raw);
      } on AccountException catch (error) {
        if (error.code == 'username_taken' ||
            error.code == 'username_invalid') {
          message = error.message;
          continue;
        }
        rethrow;
      }
    }
    return profile;
  }

  static String _codeFor(AccountException error) {
    switch (error.code) {
      case 'unconfigured':
        return 'unavailable';
      case 'cancelled':
        return 'cancelled';
      case 'expired':
        return 'expired';
      case 'network':
        return 'network';
      case 'username_taken':
        return 'username_taken';
      case 'username_invalid':
        return 'username_invalid';
      case 'username_required':
        return 'username_required';
      default:
        return 'error';
    }
  }
}
