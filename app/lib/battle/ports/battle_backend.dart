/// Battle-facing backend contract.
///
/// This is the seam task 04's arena client implements (or adapts to). It
/// carries exactly the battle-relevant actions from `docs/API.md` and speaks
/// battle models, never raw JSON. The state machine depends only on this
/// interface, so a real backend can plug in without changing the contract.
library;

import '../../domain/arena_types.dart';
import '../state/battle_failure.dart';
import '../state/battle_models.dart';

/// Response options for `request_respond`.
enum BattleRequestResponse { decline, cancel }

/// Authoritative arena operations used by the battle runtime.
abstract interface class BattleBackend {
  /// False when this build has no arena credentials; the UI then renders an
  /// honest unconfigured state instead of polling.
  bool get configured;

  /// Current public profile (`profile` action), or null when signed out.
  Future<ArenaProfile?> currentProfile();

  /// Inbox snapshot (`inbox` action). Polled every 3-5 seconds on Battle.
  Future<BattleInbox> inbox();

  /// Accepts a challenge link/code. The server creates the match; the future
  /// completes only once a match id exists (`request_send`/link semantics).
  Future<BattleMatch> acceptLink(String token);

  /// Sends a live challenge to a link token or code
  /// (`request_send`).
  Future<BattleRequest> sendChallenge(String target);

  /// Requests a fresh casual battle with a finished match's opponent.
  Future<BattleRequest> requestRematch(String matchId);

  /// Accepts an inbox request; the reply is the created match
  /// (`request_accept`). Countdown never starts from this call alone.
  Future<BattleMatch> acceptRequest(String requestId);

  /// Declines or cancels a request (`request_respond`).
  Future<BattleRequest> respondToRequest(
    String requestId,
    BattleRequestResponse response,
  );

  /// Joins the ranked queue and returns the seat (`queue_join`).
  Future<BattleQueueState> queueJoin();

  /// Polls the ranked queue seat (`queue_poll`).
  Future<BattleQueueState> queuePoll();

  /// Cancels the queue seat (`queue_leave`); safe to call twice.
  Future<void> queueLeave();

  /// Authoritative match snapshot (`match_state`).
  Future<BattleMatch> matchState(String matchId);

  /// Submits the ready gate with tracking and practice-rep facts.
  Future<BattleMatch> ready(
    String matchId, {
    required bool tracking,
    required bool practiceComplete,
  });

  /// One-second live heartbeat (`heartbeat`).
  Future<BattleMatch> heartbeat(String matchId, {required bool tracking});

  /// Sends one camera-counted rep (`rep`). Event ids stay stable on retry so
  /// the server dedupes.
  Future<BattleMatch> reportRep(String matchId, PendingRepEvent event);

  /// Leaves or cancels the match (`leave`). The reply is the server's final
  /// view; it may carry a receipt or a no-result.
  Future<BattleMatch> leave(String matchId);
}

/// Honest backend placeholder for builds without arena credentials.
///
/// Every call fails with [BattleFailureKind.unconfigured]; the UI renders the
/// unconfigured state and never schedules polling.
class UnconfiguredBattleBackend implements BattleBackend {
  const UnconfiguredBattleBackend();

  BattleFailure get _failure => const BattleFailure(
        BattleFailureKind.unconfigured,
        'The arena service is not configured in this build. Challenge links '
            'and battles need backend credentials.',
      );

  @override
  bool get configured => false;

  @override
  Future<ArenaProfile?> currentProfile() async => throw _failure;

  @override
  Future<BattleInbox> inbox() async => throw _failure;

  @override
  Future<BattleMatch> acceptLink(String token) async => throw _failure;

  @override
  Future<BattleRequest> sendChallenge(String target) async => throw _failure;

  @override
  Future<BattleRequest> requestRematch(String matchId) async => throw _failure;

  @override
  Future<BattleMatch> acceptRequest(String requestId) async => throw _failure;

  @override
  Future<BattleRequest> respondToRequest(
    String requestId,
    BattleRequestResponse response,
  ) async =>
      throw _failure;

  @override
  Future<BattleQueueState> queueJoin() async => throw _failure;

  @override
  Future<BattleQueueState> queuePoll() async => throw _failure;

  @override
  Future<void> queueLeave() async => throw _failure;

  @override
  Future<BattleMatch> matchState(String matchId) async => throw _failure;

  @override
  Future<BattleMatch> ready(
    String matchId, {
    required bool tracking,
    required bool practiceComplete,
  }) async =>
      throw _failure;

  @override
  Future<BattleMatch> heartbeat(String matchId, {required bool tracking}) async =>
      throw _failure;

  @override
  Future<BattleMatch> reportRep(String matchId, PendingRepEvent event) async =>
      throw _failure;

  @override
  Future<BattleMatch> leave(String matchId) async => throw _failure;
}
