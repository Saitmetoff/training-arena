/// Battle-to-sharing adapter.
///
/// The battle feature calls [BattleChallengeSharer] for every "challenge a
/// friend" action. Result-based invites carry the server-confirmed receipt
/// and open the exact-card preview; invites without a receipt keep the
/// existing text share and can never open the result preview.
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../battle/ports/battle_challenge_sharer.dart';
import '../domain/arena_types.dart';
import '../linking/challenge_models.dart';
import 'result_share_models.dart';
import 'result_share_preview.dart';
import 'result_share_service.dart';

/// Values needed to open the preview. The viewer id is the identity the
/// receipt is interpreted from; the snapshot may arrive prefetched.
class ResultSharePreviewRequest {
  const ResultSharePreviewRequest({
    required this.receipt,
    required this.viewerId,
    this.snapshot,
  });

  final ResultReceipt receipt;
  final String viewerId;
  final ChallengeAccountSnapshot? snapshot;
}

/// Presents the exact-card preview. Faked in tests; the production
/// implementation pushes a route on the app navigator.
abstract interface class ResultSharePresenter {
  Future<bool> present(
    ResultSharePreviewRequest request,
    ResultShareService service,
  );
}

/// Pushes [ResultSharePreviewPage] on the app's navigator.
class NavigatorResultSharePresenter implements ResultSharePresenter {
  const NavigatorResultSharePresenter(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<bool> present(
    ResultSharePreviewRequest request,
    ResultShareService service,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return false;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultSharePreviewPage(
          receipt: request.receipt,
          viewerId: request.viewerId,
          service: service,
          initialSnapshot: request.snapshot,
        ),
      ),
    );
    return true;
  }
}

/// [BattleChallengeSharer] that routes confirmed receipts through the card
/// preview and everything else through the task `05` text share.
class ResultShareChallengeSharer implements BattleChallengeSharer {
  const ResultShareChallengeSharer({
    required ResultShareService service,
    required ResultSharePresenter presenter,
    required ValueListenable<ArenaProfile?> viewer,
    BattleChallengeSharer? fallback,
  })  : _service = service,
        _presenter = presenter,
        _viewer = viewer,
        _fallback = fallback;

  final ResultShareService _service;
  final ResultSharePresenter _presenter;
  final ValueListenable<ArenaProfile?> _viewer;
  final BattleChallengeSharer? _fallback;

  @override
  Future<String?> shareChallenge(BattleChallengeInvite invite) async {
    final receipt = invite.receipt;
    if (receipt == null) {
      // No confirmed receipt: never claim an outcome. Keep the task 05 text
      // share (or the honest pending copy) for plain friend challenges.
      final fallback = _fallback;
      if (fallback != null) {
        return fallback.shareChallenge(invite);
      }
      return 'No confirmed result to share. A challenge card needs a '
          'server-confirmed receipt.';
    }

    final profile = _viewer.value;
    if (profile == null) {
      await _service.trackBlocked('signed_out');
      return 'Sign in before sharing a confirmed result.';
    }

    try {
      validateResultReceipt(receipt: receipt, viewerId: profile.id);
    } on ResultShareException catch (error) {
      await _service.trackBlocked(error.code);
      return error.message;
    }

    final opened = await _presenter.present(
      ResultSharePreviewRequest(
        receipt: receipt,
        viewerId: profile.id,
      ),
      _service,
    );
    return opened ? null : 'The share preview could not be opened.';
  }
}
