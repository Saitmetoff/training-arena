/// Confirmation dialogs for battle actions.
///
/// Destructive actions always confirm first; copy stays factual.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../state/battle_phase.dart';
import 'battle_style.dart';

/// Copy for the leave/cancel dialogs by phase.
class BattleLeaveCopy {
  const BattleLeaveCopy({
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;

  static BattleLeaveCopy forReason(BattleExitReason reason) {
    switch (reason) {
      case BattleExitReason.leftPreparation:
        return const BattleLeaveCopy(
          title: 'Leave preparation?',
          body: 'The match stays open for 10 minutes, then expires. No rating '
              'changes if nobody returns.',
          confirmLabel: 'Leave preparation',
        );
      case BattleExitReason.cancelledMatch:
        return const BattleLeaveCopy(
          title: 'Cancel this match?',
          body: 'If you leave, the countdown cannot start and the match '
              'expires in 10 minutes.',
          confirmLabel: 'Cancel match',
        );
      case BattleExitReason.leftCountdown:
        return const BattleLeaveCopy(
          title: 'Leave the countdown?',
          body: 'The battle cannot start without you. Leaving abandons the '
              'match.',
          confirmLabel: 'Leave match',
        );
      case BattleExitReason.leftLive:
        return const BattleLeaveCopy(
          title: 'Leave this battle?',
          body: 'Leaving during a live round forfeits the match. If the '
              'service is unreachable, the result is no result and no rating '
              'changes. The server confirms the outcome.',
          confirmLabel: 'Leave battle',
        );
      case BattleExitReason.declinedRequest:
      case BattleExitReason.cancelledRequest:
      case BattleExitReason.blockedPlayer:
      case BattleExitReason.matchExpired:
      case BattleExitReason.none:
        return const BattleLeaveCopy(
          title: 'Leave this screen?',
          body: 'Nothing is started unattended.',
          confirmLabel: 'Leave',
        );
    }
  }
}

/// Shows the leave confirmation; calls [onConfirm] only on the danger action.
Future<void> showBattleLeaveDialog(
  BuildContext context, {
  required BattleExitReason reason,
  required VoidCallback onConfirm,
}) {
  final copy = BattleLeaveCopy.forReason(reason);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: ArenaColors.graphite,
        title: Text(
          copy.title,
          style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
        ),
        content: Text(
          copy.body,
          style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Stay',
              style: TextStyle(color: ArenaColors.softWhite),
            ),
          ),
          TextButton(
            key: const ValueKey('battle-leave-confirm'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm();
            },
            child: Text(
              copy.confirmLabel,
              style: const TextStyle(color: ArenaColors.danger),
            ),
          ),
        ],
      );
    },
  );
}

/// Decline confirmation for a pending request.
Future<void> showBattleDeclineDialog(
  BuildContext context, {
  required String username,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: ArenaColors.graphite,
        title: Text(
          'Decline this request?',
          style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
        ),
        content: Text(
          'Nothing is replayed or rescheduled. @$username can send a new '
          'challenge later.',
          style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Keep request',
              style: TextStyle(color: ArenaColors.softWhite),
            ),
          ),
          TextButton(
            key: const ValueKey('battle-decline-confirm'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm();
            },
            child: const Text(
              'Decline',
              style: TextStyle(color: ArenaColors.danger),
            ),
          ),
        ],
      );
    },
  );
}

/// Join-with-code fallback entry.
Future<void> showJoinCodeDialog(
  BuildContext context, {
  required Future<void> Function(String code) onJoin,
}) {
  final controller = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: ArenaColors.graphite,
        title: Text(
          'Join with code',
          style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('battle-code-field'),
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 16,
              style: const TextStyle(color: ArenaColors.softWhite),
              decoration: const InputDecoration(
                labelText: 'Short code',
                labelStyle: TextStyle(color: ArenaColors.secondary),
                counterText: '',
              ),
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              'The code is the short identifier from a challenge link. '
              'Looking up a code never creates a request or match by itself.',
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.quiet,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ArenaColors.softWhite),
            ),
          ),
          TextButton(
            key: const ValueKey('battle-code-join'),
            onPressed: () {
              final code = controller.text;
              Navigator.of(dialogContext).pop();
              onJoin(code);
            },
            child: const Text(
              'Join challenge',
              style: TextStyle(color: ArenaColors.lime),
            ),
          ),
        ],
      );
    },
  );
}
