/// Deterministic fixture mode for previews only.
///
/// Fixtures render every battle surface with invented, clearly-labelled data
/// so reviewers and task 10 can drive the UI without a backend. They are
/// gated behind the compile-time flag `ARENA_FEATURE_PREVIEW_FIXTURES`
/// (default false) and they never produce ranked or casual receipts:
/// `queueJoin`, `ready` and `reportRep` fail with a labelled conflict.
library;

import 'dart:async';

import '../../domain/arena_types.dart';
import '../ports/battle_backend.dart';
import '../ports/battle_camera.dart';
import '../ports/battle_clock.dart';
import '../state/battle_failure.dart';
import '../state/battle_models.dart';
import '../state/battle_phase.dart';

/// Preview profile data. Invented for design review only.
abstract final class BattleFixtureData {
  static const ArenaProfile viewer = ArenaProfile(
    id: 'fixture-viewer',
    username: 'azizbek',
    rating: 1042,
    rankedWins: 7,
    rankedBattles: 11,
  );

  static const ArenaProfile opponent = ArenaProfile(
    id: 'fixture-opponent',
    username: 'zuhra',
    rating: 1060,
    rankedWins: 9,
    rankedBattles: 14,
  );

  static const String matchId = 'fixture-match-1';
  static const String requestId = 'fixture-request-1';
  static const String token = '9f2k4p7q';
}

/// Preview-only backend. Read-only for anything that could become a
/// competitive receipt.
class FixtureBattleBackend implements BattleBackend {
  FixtureBattleBackend({required this.clock});

  final BattleClock clock;

  int _heartbeats = 0;
  BattleMatch? _match;

  static const BattleFailure _receiptBlocked = BattleFailure(
    BattleFailureKind.conflict,
    'Preview fixtures never produce ranked or casual receipts. Connect a '
    'real arena backend to complete a match.',
  );

  @override
  bool get configured => true;

  @override
  Future<ArenaProfile?> currentProfile() async => BattleFixtureData.viewer;

  @override
  Future<BattleInbox> inbox() async {
    return BattleInbox(
      serverNow: clock.now().add(const Duration(seconds: 1)),
      requests: <BattleRequest>[
        BattleRequest(
          id: BattleFixtureData.requestId,
          kind: BattleRequestKind.pending,
          sender: BattleFixtureData.opponent,
          exercise: ArenaExercise.pushUps,
          mode: ArenaMatchMode.casual,
          receivedAt: clock.now().subtract(const Duration(minutes: 2)),
          expiresAt: clock.now().add(const Duration(hours: 23, minutes: 40)),
        ),
      ],
    );
  }

  @override
  Future<BattleMatch> acceptLink(String token) async => _createMatch();

  @override
  Future<BattleRequest> requestRematch(String matchId) async =>
      throw _receiptBlocked;

  @override
  Future<BattleMatch> acceptRequest(String requestId) async => _createMatch();

  @override
  Future<BattleRequest> sendChallenge(String target) async {
    return BattleRequest(
      id: 'fixture-sent-1',
      kind: BattleRequestKind.pending,
      sender: BattleFixtureData.opponent,
      exercise: ArenaExercise.pushUps,
      receivedAt: clock.now(),
      expiresAt: clock.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<BattleRequest> respondToRequest(
    String requestId,
    BattleRequestResponse response,
  ) async {
    return BattleRequest(
      id: requestId,
      kind: BattleRequestKind.cancelled,
      sender: BattleFixtureData.opponent,
      exercise: ArenaExercise.pushUps,
    );
  }

  @override
  Future<BattleQueueState> queueJoin() async => throw _receiptBlocked;

  @override
  Future<BattleQueueState> queuePoll() async => throw _receiptBlocked;

  @override
  Future<void> queueLeave() async {}

  @override
  Future<BattleMatch> matchState(String matchId) async {
    return _match ?? _createMatch();
  }

  @override
  Future<BattleMatch> ready(
    String matchId, {
    required bool tracking,
    required bool practiceComplete,
  }) async => throw _receiptBlocked;

  @override
  Future<BattleMatch> heartbeat(
    String matchId, {
    required bool tracking,
  }) async {
    _heartbeats++;
    final match = _match ?? _createMatch();
    // Preview-only opponent motion so reviewers can see score panels move.
    // The viewer's own reps are never scored by fixtures.
    final simulatedOpponent =
        (match.players.isEmpty || match.players.length < 2)
        ? 0
        : (_heartbeats ~/ 4).clamp(0, 99);
    final players = <BattleMatchPlayer>[];
    for (final player in match.players) {
      players.add(
        player.profile.id == BattleFixtureData.viewer.id
            ? player
            : player.copyWith(score: simulatedOpponent, tracking: true),
      );
    }
    _match = match.copyWith(
      status: ArenaMatchStatus.live,
      players: players,
      startsAt:
          match.startsAt ?? clock.now().subtract(const Duration(seconds: 5)),
      endsAt: match.endsAt ?? clock.now().add(const Duration(seconds: 60)),
      serverNow: clock.now().add(const Duration(seconds: 1)),
    );
    return _match!;
  }

  @override
  Future<BattleMatch> reportRep(String matchId, PendingRepEvent event) async =>
      throw _receiptBlocked;

  @override
  Future<BattleMatch> leave(String matchId) async {
    final match = _match ?? _createMatch();
    return match.copyWith(
      status: ArenaMatchStatus.noResult,
      serverNow: clock.now().add(const Duration(seconds: 1)),
      reason: 'Preview fixture: no receipt is produced by fixture mode.',
    );
  }

  BattleMatch _createMatch() {
    _match = BattleMatch(
      id: BattleFixtureData.matchId,
      exercise: ArenaExercise.pushUps,
      mode: ArenaMatchMode.casual,
      status: ArenaMatchStatus.preparing,
      players: const <BattleMatchPlayer>[
        BattleMatchPlayer(profile: BattleFixtureData.viewer, tracking: true),
        BattleMatchPlayer(profile: BattleFixtureData.opponent, tracking: true),
      ],
      serverNow: clock.now().add(const Duration(seconds: 1)),
    );
    return _match!;
  }
}

/// Preview-only camera that counts deterministic reps on the shared clock.
class FixtureBattleCamera implements BattleCamera {
  @override
  Future<void> suspend() async {}

  @override
  Future<void> resume() async {}
  FixtureBattleCamera({required this.clock});

  final BattleClock clock;

  final StreamController<BattleCameraUpdate> _updates =
      StreamController<BattleCameraUpdate>.broadcast();
  final StreamController<BattleRepEvent> _reps =
      StreamController<BattleRepEvent>.broadcast();

  BattleTimer? _practiceTimer;
  bool _disposed = false;

  @override
  Future<BattleCameraStatus> prepare(ArenaExercise exercise) async {
    _updates.add(
      const BattleCameraUpdate(
        BattleCameraStatus.framing,
        message: 'Preview fixture framing guidance. Nothing is recorded.',
      ),
    );
    _updates.add(const BattleCameraUpdate(BattleCameraStatus.tracking));
    return BattleCameraStatus.tracking;
  }

  @override
  Stream<BattleCameraUpdate> get updates => _updates.stream;

  @override
  Stream<BattleRepEvent> get reps => _reps.stream;

  @override
  Future<void> startPractice() async {
    _practiceTimer?.cancel();
    _practiceTimer = clock.schedule(const Duration(milliseconds: 600), () {
      if (!_disposed) {
        _reps.add(
          BattleRepEvent(
            eventId: 'fixture-practice-1',
            sequence: 1,
            counterVersion: 'fixture-counter/1.0.0',
            observedAt: clock.now(),
            practice: true,
            competitive: false,
          ),
        );
      }
    });
  }

  @override
  Future<void> startMatch() async {
    // Fixture mode never emits competitive reps: fixtures cannot produce a
    // score or a receipt.
  }

  @override
  Future<void> stop() async {
    _practiceTimer?.cancel();
    _practiceTimer = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _updates.close();
    await _reps.close();
  }
}
