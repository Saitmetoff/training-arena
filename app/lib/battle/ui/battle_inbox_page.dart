/// Request inbox page with the required loading, empty, offline, blocked,
/// expired, busy and cancelled states.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../runtime/battle_controller.dart';
import '../runtime/battle_runtime.dart';
import '../state/battle_models.dart';
import '../state/battle_phase.dart';
import '../state/battle_snapshot.dart';
import 'battle_dialogs.dart';
import 'battle_style.dart';
import 'battle_widgets.dart';

/// Full request inbox (`inbox` action data).
class BattleInboxPage extends StatefulWidget {
  const BattleInboxPage({super.key});

  @override
  State<BattleInboxPage> createState() => _BattleInboxPageState();
}

class _BattleInboxPageState extends State<BattleInboxPage> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened) {
      _opened = true;
      // Deferred: opening the inbox notifies the controller, and notifying
      // an InheritedNotifier during dependency resolution is illegal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          BattleRuntimeScope.of(context).openInbox();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = BattleRuntimeScope.of(context);
    final snapshot = controller.snapshot;
    return Scaffold(
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: ListView(
          key: const ValueKey('battle-inbox-page'),
          padding: const EdgeInsets.fromLTRB(
            ArenaBattleSpace.s4,
            ArenaBattleSpace.s2,
            ArenaBattleSpace.s4,
            ArenaBattleSpace.s6,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('inbox-back'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  color: ArenaColors.softWhite,
                  tooltip: 'Back to Battle',
                ),
                Text(
                  'Requests',
                  style: ArenaBattleText.h1.copyWith(
                    color: ArenaColors.softWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
            if (snapshot.notice != null) ...[
              BattleBanner(
                key: const ValueKey('inbox-notice'),
                variant: BattleBannerVariant.info,
                title: snapshot.notice!,
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
            ],
            ..._buildBody(controller, snapshot),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BattleController controller,
    BattleSnapshot snapshot,
  ) {
    switch (snapshot.inboxStatus) {
      case BattleLoadStatus.initial:
      case BattleLoadStatus.loading:
        return const [
          _InboxLoading(),
        ];
      case BattleLoadStatus.offline:
        return [
          BattleBanner(
            key: const ValueKey('inbox-offline'),
            variant: BattleBannerVariant.danger,
            title: 'You are offline',
            body: snapshot.inboxMessage ??
                'Requests cannot be reached right now. Nothing was dropped.',
            actions: [
              BattleSecondaryButton(
                key: const ValueKey('inbox-retry'),
                label: 'Retry',
                onPressed: controller.refreshInbox,
              ),
            ],
          ),
        ];
      case BattleLoadStatus.error:
        return [
          BattleBanner(
            key: const ValueKey('inbox-error'),
            variant: BattleBannerVariant.danger,
            title: 'Could not load requests',
            body: snapshot.inboxMessage ??
                'The server answered unexpectedly.',
            actions: [
              BattleSecondaryButton(
                key: const ValueKey('inbox-retry'),
                label: 'Retry',
                onPressed: controller.refreshInbox,
              ),
            ],
          ),
        ];
      case BattleLoadStatus.unconfigured:
        return [
          BattleBanner(
            key: const ValueKey('inbox-unconfigured'),
            variant: BattleBannerVariant.warning,
            title: 'Arena service not configured',
            body: snapshot.inboxMessage ??
                'Requests need backend credentials.',
          ),
        ];
      case BattleLoadStatus.signedOut:
        return [
          const BattleBanner(
            key: ValueKey('inbox-signed-out'),
            variant: BattleBannerVariant.info,
            title: 'Sign in to see requests',
            body: 'A pending challenge is kept and resumes after sign-in.',
          ),
        ];
      case BattleLoadStatus.blocked:
        return [
          BattleBanner(
            key: const ValueKey('inbox-blocked'),
            variant: BattleBannerVariant.warning,
            title: 'Requests are unavailable',
            body: snapshot.inboxMessage ??
                'This account cannot send or accept requests.',
          ),
        ];
      case BattleLoadStatus.empty:
      case BattleLoadStatus.ready:
        if (snapshot.requests.isEmpty) {
          return [
            BattleCard(
              key: const ValueKey('inbox-empty'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No requests right now',
                    style: ArenaBattleText.h3.copyWith(
                      color: ArenaColors.softWhite,
                    ),
                  ),
                  const SizedBox(height: ArenaBattleSpace.s2),
                  Text(
                    'A request appears here when someone challenges you. '
                    'Requests expire after 24 hours.',
                    style: ArenaBattleText.body.copyWith(
                      color: ArenaColors.secondary,
                    ),
                  ),
                  const SizedBox(height: ArenaBattleSpace.s4),
                  BattlePrimaryButton(
                    label: 'Challenge a friend',
                    block: false,
                    onPressed: () => controller.challengeFriend(),
                  ),
                ],
              ),
            ),
          ];
        }
        return [
          for (final request in snapshot.requests) ...[
            _RequestCard(
              request: request,
              controller: controller,
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
          ],
          Text(
            'Requests expire after 24 hours. One accepted battle at a time, '
            'and only when both players are present.',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
          ),
        ];
    }
  }
}

class _InboxLoading extends StatelessWidget {
  const _InboxLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading requests',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: ArenaColors.graphite,
                borderRadius:
                    BorderRadius.circular(ArenaBattleSpace.radiusCard),
              ),
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
          ],
          Text(
            'Loading requests…',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
          ),
        ],
      ),
    );
  }
}

class OutgoingRequestCard extends StatelessWidget {
  const OutgoingRequestCard({
    super.key,
    required this.request,
    required this.controller,
  });

  final BattleRequest request;
  final BattleController controller;

  @override
  Widget build(BuildContext context) => BattleBanner(
        variant: BattleBannerVariant.info,
        title: 'Request pending',
        body: 'Waiting for @${request.recipient?.username ?? 'your opponent'} '
            'to accept. Both players must prepare and become ready again. '
            'Expires in ${formatBattleCountdown(request.expiresAt)}.',
        actions: [
          BattleQuietButton(
            label: 'Cancel request',
            onPressed: () => controller.cancelRequest(request.id),
          ),
        ],
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.controller});

  final BattleRequest request;
  final BattleController controller;

  @override
  Widget build(BuildContext context) {
    if (request.isOutgoing && request.kind == BattleRequestKind.pending) {
      return OutgoingRequestCard(request: request, controller: controller);
    }
    final username = request.sender.username ?? 'the challenger';
    return Semantics(
      container: true,
      label: 'Request from @$username',
      child: BattleCard(
        accent: request.kind == BattleRequestKind.pending
            ? ArenaColors.violet
            : ArenaColors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chipFor(request.kind),
                if (request.receivedAt != null)
                  Text(
                    'Received',
                    style: ArenaBattleText.small.copyWith(
                      color: ArenaColors.quiet,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
            BattleIdentity(
              profile: request.sender,
              role: 'challenger · opponent',
              accent: true,
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
            ..._bodyFor(context, username),
          ],
        ),
      ),
    );
  }

  BattleChip _chipFor(BattleRequestKind kind) {
    switch (kind) {
      case BattleRequestKind.pending:
        return const BattleChip(
          label: 'Pending',
          variant: BattleChipVariant.positive,
        );
      case BattleRequestKind.offlineChallenger:
        return const BattleChip(
          label: 'Challenger offline',
          variant: BattleChipVariant.warning,
        );
      case BattleRequestKind.expired:
        return const BattleChip(label: 'Expired');
      case BattleRequestKind.busyPlayer:
        return const BattleChip(
          label: 'In a battle',
          variant: BattleChipVariant.warning,
        );
      case BattleRequestKind.cancelled:
        return const BattleChip(label: 'Cancelled');
      case BattleRequestKind.blocked:
        return const BattleChip(
          label: 'Blocked',
          variant: BattleChipVariant.danger,
        );
    }
  }

  List<Widget> _bodyFor(BuildContext context, String username) {
    switch (request.kind) {
      case BattleRequestKind.pending:
        return [
          Text(
            '${request.mode.label} · 60 seconds · '
            'expires in ${formatBattleCountdown(request.expiresAt)}',
            style: ArenaBattleText.body.copyWith(
              color: ArenaColors.secondary,
            ),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          Wrap(
            spacing: ArenaBattleSpace.s2,
            runSpacing: ArenaBattleSpace.s2,
            children: [
              BattlePrimaryButton(
                key: const ValueKey('inbox-accept'),
                label: 'Accept challenge',
                block: false,
                onPressed: () => controller.acceptRequest(request.id),
              ),
              BattleSecondaryButton(
                key: const ValueKey('inbox-decline'),
                label: 'Decline',
                onPressed: () => showBattleDeclineDialog(
                  context,
                  username: username,
                  onConfirm: () => controller.declineRequest(request.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          Text(
            'Accepting creates a match. Both players must be ready and '
            'present before it starts.',
            style: ArenaBattleText.small.copyWith(
              color: ArenaColors.quiet,
            ),
          ),
        ];
      case BattleRequestKind.offlineChallenger:
        return [
          Text(
            'Live challenges need both players at the same time. Sending '
            'tells @$username you are ready to battle now. It is not a '
            'replay, and there is no old score to beat.',
            style: ArenaBattleText.body.copyWith(
              color: ArenaColors.secondary,
            ),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          BattlePrimaryButton(
            key: const ValueKey('inbox-send-live'),
            label: 'Send live challenge',
            block: false,
            onPressed: () => controller.challengeFriend(),
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          Text(
            'If they do not respond, the request expires with no match '
            'created.',
            style: ArenaBattleText.small.copyWith(
              color: ArenaColors.quiet,
            ),
          ),
        ];
      case BattleRequestKind.expired:
        return [
          Text(
            'Requests expire 24 hours after they are sent. Nothing was '
            'created for this one and no rating changed.',
            style: ArenaBattleText.body.copyWith(
              color: ArenaColors.secondary,
            ),
          ),
          BattleQuietButton(
            key: const ValueKey('inbox-challenge-again'),
            label: 'Challenge @$username again',
            onPressed: () => controller.challengeFriend(),
          ),
        ];
      case BattleRequestKind.busyPlayer:
        return [
          Text(
            '@$username is finishing another battle. Wait until they finish '
            'before trying again. A player can never have two active battles '
            'at once.',
            style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          Wrap(
            spacing: ArenaBattleSpace.s2,
            runSpacing: ArenaBattleSpace.s2,
            children: [
              BattlePrimaryButton(
                key: const ValueKey('inbox-send-live'),
                label: 'Share a challenge link',
                block: false,
                onPressed: () => controller.challengeFriend(),
              ),
              BattleSecondaryButton(
                label: 'Back to Battle',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ];
      case BattleRequestKind.cancelled:
        return [
          Text(
            'This request was cancelled. Nothing was created and no rating '
            'changed.',
            style: ArenaBattleText.body.copyWith(
              color: ArenaColors.secondary,
            ),
          ),
        ];
      case BattleRequestKind.blocked:
        return [
          Text(
            request.note ??
                'You cannot challenge this player from your account.',
            style: ArenaBattleText.body.copyWith(
              color: ArenaColors.secondary,
            ),
          ),
        ];
    }
  }
}
