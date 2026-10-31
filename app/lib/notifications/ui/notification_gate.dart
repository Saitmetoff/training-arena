/// Focused gate for a notification tap.
///
/// It renders exactly what the authoritative server confirmed: the pending
/// request the notification named, the match it named, or an honest
/// explanation for expired/cancelled/blocked/already-accepted targets. The
/// gate never invents a request, an opponent or a result.
library;

import 'package:flutter/material.dart';

import '../../battle/state/battle_models.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../../theme/arena_tokens.dart';
import '../notification_service.dart';

/// Displays [NotificationService.route] as a full screen.
class NotificationGate extends StatelessWidget {
  const NotificationGate({
    super.key,
    required this.service,
    required this.onAcceptRequest,
    required this.onDeclineRequest,
    required this.onResumeMatch,
    required this.onBackToBattle,
  });

  final NotificationService service;
  final Future<void> Function(BattleRequest request) onAcceptRequest;
  final Future<void> Function(BattleRequest request) onDeclineRequest;
  final Future<void> Function(String matchId) onResumeMatch;
  final VoidCallback onBackToBattle;

  @override
  Widget build(BuildContext context) {
    final route = service.route;
    return Scaffold(
      key: const ValueKey('notification-gate'),
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ArenaBattleSpace.screenGutter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ArenaBattleSpace.s5),
              Text(
                'Challenge alerts',
                style: ArenaBattleText.h1.copyWith(
                  color: ArenaColors.softWhite,
                ),
              ),
              const SizedBox(height: ArenaBattleSpace.s4),
              switch (route) {
                NotificationRouteIdle() => const SizedBox.shrink(),
                NotificationRouteOpening(:final targetLabel) => _Opening(
                    targetLabel: targetLabel,
                  ),
                NotificationRouteRequest(:final request) => _RequestCard(
                    request: request,
                    onAccept: () => onAcceptRequest(request),
                    onDecline: () => onDeclineRequest(request),
                    onOpenBattle: onBackToBattle,
                  ),
                NotificationRouteMatch(:final matchId) => _MatchReady(
                    matchId: matchId,
                    onOpen: () => onResumeMatch(matchId),
                    onOpenBattle: onBackToBattle,
                  ),
                NotificationRouteClosed(
                  :final title,
                  :final message,
                  :final matchId
                ) =>
                  _Closed(
                    title: title,
                    message: message,
                    onResume:
                        matchId == null ? null : () => onResumeMatch(matchId),
                    onOpenBattle: onBackToBattle,
                  ),
                NotificationRouteFailed(:final message) => _Failed(
                    message: message,
                    onRetry: service.retry,
                    onOpenBattle: onBackToBattle,
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Opening extends StatelessWidget {
  const _Opening({required this.targetLabel});

  final String targetLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: ArenaColors.lime),
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        Text(
          'Checking $targetLabel with the arena…',
          key: const ValueKey('notification-opening'),
          textAlign: TextAlign.center,
          style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onOpenBattle,
  });

  final BattleRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onOpenBattle;

  @override
  Widget build(BuildContext context) {
    final username = request.sender.username ?? 'The challenger';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BattleCard(
          key: const ValueKey('notification-request-card'),
          accent: ArenaColors.violet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BattleChip(
                label: 'Pending request',
                variant: BattleChipVariant.opponent,
              ),
              const SizedBox(height: ArenaBattleSpace.s4),
              BattleIdentity(
                profile: request.sender,
                role: 'challenger · opponent',
                accent: true,
                large: true,
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              Text(
                '@$username challenged you',
                style: ArenaBattleText.h2.copyWith(
                  color: ArenaColors.softWhite,
                ),
              ),
              const SizedBox(height: ArenaBattleSpace.s2),
              Text(
                '${request.exercise.label} · ${request.mode.label} · 60 '
                'seconds. Camera-counted reps only.',
                style: ArenaBattleText.body.copyWith(
                  color: ArenaColors.secondary,
                ),
              ),
              const SizedBox(height: ArenaBattleSpace.s4),
              Wrap(
                spacing: ArenaBattleSpace.s2,
                runSpacing: ArenaBattleSpace.s2,
                children: [
                  BattlePrimaryButton(
                    key: const ValueKey('notification-accept'),
                    label: 'Accept challenge',
                    block: false,
                    onPressed: onAccept,
                  ),
                  BattleSecondaryButton(
                    key: const ValueKey('notification-decline'),
                    label: 'Decline',
                    onPressed: onDecline,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        BattleQuietButton(
          key: const ValueKey('notification-open-battle'),
          label: 'Open Battle instead',
          onPressed: onOpenBattle,
        ),
      ],
    );
  }
}

class _MatchReady extends StatelessWidget {
  const _MatchReady({
    required this.matchId,
    required this.onOpen,
    required this.onOpenBattle,
  });

  final String matchId;
  final VoidCallback onOpen;
  final VoidCallback onOpenBattle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BattleBanner(
          key: ValueKey('notification-match-ready'),
          variant: BattleBannerVariant.positive,
          title: 'Your battle is ready',
          body: 'Both players still need to confirm readiness in preparation. '
              'Nothing starts unattended.',
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattlePrimaryButton(
          key: const ValueKey('notification-open-match'),
          label: 'Open preparation',
          block: true,
          onPressed: onOpen,
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleQuietButton(
          label: 'Back to Battle',
          onPressed: onOpenBattle,
        ),
      ],
    );
  }
}

class _Closed extends StatelessWidget {
  const _Closed({
    required this.title,
    required this.message,
    required this.onResume,
    required this.onOpenBattle,
  });

  final String title;
  final String message;
  final VoidCallback? onResume;
  final VoidCallback onOpenBattle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BattleBanner(
          key: const ValueKey('notification-closed'),
          variant: BattleBannerVariant.warning,
          title: title,
          body: message,
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        if (onResume != null) ...[
          BattlePrimaryButton(
            key: const ValueKey('notification-resume-match'),
            label: 'Resume match',
            block: true,
            onPressed: onResume,
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
        ],
        BattleSecondaryButton(
          key: const ValueKey('notification-back-to-battle'),
          label: 'Back to Battle',
          block: true,
          onPressed: onOpenBattle,
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.message,
    required this.onRetry,
    required this.onOpenBattle,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onOpenBattle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BattleBanner(
          key: const ValueKey('notification-failed'),
          variant: BattleBannerVariant.danger,
          title: 'Could not check that notification',
          body: message,
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattlePrimaryButton(
          key: const ValueKey('notification-retry'),
          label: 'Try again',
          block: true,
          onPressed: () => onRetry(),
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleQuietButton(
          label: 'Back to Battle',
          onPressed: onOpenBattle,
        ),
      ],
    );
  }
}

/// In-context rationale shown before the OS permission dialog.
///
/// Returns true when the user allows notifications. A false result never
/// affects the request itself.
Future<bool> showNotificationPermissionRationale(BuildContext context) async {
  final allowed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        key: const ValueKey('notification-permission-dialog'),
        backgroundColor: ArenaColors.graphite,
        title: Text(
          'Turn on challenge alerts?',
          style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
        ),
        content: Text(
          'Fault can notify you when a challenge request arrives or '
          'your ranked match is ready. Your inbox always shows the same '
          'requests, so declining only turns off the alerts.',
          style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
        ),
        actions: [
          TextButton(
            key: const ValueKey('notification-permission-not-now'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            key: const ValueKey('notification-permission-allow'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      );
    },
  );
  return allowed ?? false;
}
