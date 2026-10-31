/// Interactive steps the auth flows need from the UI.
///
/// The [ArenaAuthGateway] owns provider calls; prompts own the screens that
/// collect an email, an emailed code and the first username. Tests inject
/// scripted prompts, and the production implementation lives in
/// `account/ui/sign_in_flow.dart`.
library;

/// Prompt surface used by [AccountChallengeAuthDelegate] and the sign-in
/// flows. Returning null always means "the user cancelled".
abstract interface class ChallengeAuthPrompts {
  Future<String?> requestEmail();

  Future<String?> requestCode(String email);

  /// Asks for a username; [message] carries the last actionable error so a
  /// duplicate or invalid choice can be corrected in place.
  Future<String?> requestUsername({String? message});
}

/// Prompt set that cancels every step; used when no UI is wired.
class CancellingChallengeAuthPrompts implements ChallengeAuthPrompts {
  const CancellingChallengeAuthPrompts();

  @override
  Future<String?> requestEmail() async => null;

  @override
  Future<String?> requestCode(String email) async => null;

  @override
  Future<String?> requestUsername({String? message}) async => null;
}
