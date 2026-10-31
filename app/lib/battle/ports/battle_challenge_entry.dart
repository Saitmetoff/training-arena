/// Seam over task 05's challenge entry flow (links, codes, App Links).
///
/// The Battle tab delegates `Join with code` and link acceptance to this
/// interface so the linking controller stays the single place that resolves
/// tokens and sends requests.
library;

/// Minimal entry surface the battle runtime needs.
abstract interface class BattleChallengeEntryDelegate {
  /// Handles a typed code or pasted link. Returns false when the text is not
  /// a recognisable challenge.
  Future<bool> openCode(String text);
}
