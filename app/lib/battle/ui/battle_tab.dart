/// Battle tab home.
///
/// Incoming requests lead when present; otherwise solo practice is
/// the first action. Setup and availability notes follow the action.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/arena_config.dart';
import '../../linking/arena_linking.dart';
import '../../linking/challenge_auth.dart';
import '../../linking/challenge_share.dart';
import '../../linking/challenge_share_view.dart';
import '../../solo/ui/solo_page.dart';
import '../../theme/arena_tokens.dart';
import '../runtime/battle_controller.dart';
import '../runtime/battle_runtime.dart';
import '../state/battle_models.dart';
import '../state/battle_phase.dart';
import '../state/battle_snapshot.dart';
import 'battle_dialogs.dart';
import 'battle_flow_page.dart';
import 'battle_inbox_page.dart';
import 'battle_style.dart';
import 'battle_widgets.dart';

/// The Battle tab body; owns pushing the match flow page.
class BattleTab extends StatefulWidget {
  const BattleTab({super.key});

  @override
  State<BattleTab> createState() => _BattleTabState();
}

class _BattleTabState extends State<BattleTab> {
  bool _flowOpen = false;
  bool _linkOpening = false;

  static const Set<BattlePhase> _flowPhases = <BattlePhase>{
    BattlePhase.preparing,
    BattlePhase.ready,
    BattlePhase.countdown,
    BattlePhase.live,
    BattlePhase.reconnecting,
    BattlePhase.result,
    BattlePhase.noResult,
    BattlePhase.exiting,
  };

  void _syncFlowRoute(BattleController controller, BattleSnapshot snapshot) {
    final flow = _flowPhases.contains(snapshot.phase);
    if (flow && !_flowOpen) {
      _flowOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _flowOpen = false;
          return;
        }
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(builder: (_) => const BattleFlowPage()),
            )
            .whenComplete(() => _flowOpen = false);
      });
    } else if (!flow && _flowOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = BattleRuntimeScope.of(context);
    final config = ArenaConfigScope.of(context);
    final snapshot = controller.snapshot;
    _syncFlowRoute(controller, snapshot);
    final queueActive = snapshot.queuePhase == BattleQueuePhase.searching ||
        snapshot.queuePhase == BattleQueuePhase.extended;

    return PopScope(
      // Back while searching cancels the seat first; a second back leaves
      // Battle. Repeating the action is harmless.
      canPop: !queueActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(controller.stopRankedSearch());
      },
      child: ListView(
        key: const ValueKey('battle-home'),
        padding: const EdgeInsets.fromLTRB(
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s6,
        ),
        children: [
          _NoticeBar(snapshot: snapshot),
          Text(
            'Battle',
            style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          if (snapshot.previewFixtures) ...[
            const BattlePreviewBanner(),
            const SizedBox(height: ArenaBattleSpace.s3),
          ],
          ..._buildBody(controller, snapshot, config),
        ],
      ),
    );
  }

  List<Widget> _buildBody(
    BattleController controller,
    BattleSnapshot snapshot,
    ArenaConfig config,
  ) {
    final children = <Widget>[];
    final homeNotices = <Widget>[];
    // Ranked needs both the release flag and camera counting: a ranked round
    // with no camera can never produce a score, so the tab must not claim it.
    final cameraAvailable = config.cameraCountingEnabled;
    final rankedAvailable = config.rankedMatchmakingEnabled && cameraAvailable;

    if (!snapshot.signedIn &&
        snapshot.inboxStatus != BattleLoadStatus.unconfigured) {
      homeNotices.add(
        const _HomeStatus(
          key: ValueKey('battle-signed-out'),
          title: 'Sign in to battle',
          body: 'A link you opened is saved. Sign in and you return to that '
              'exact challenge.',
        ),
      );
    }

    switch (snapshot.inboxStatus) {
      case BattleLoadStatus.initial:
      case BattleLoadStatus.loading:
        homeNotices.add(const _InboxSkeleton());
      case BattleLoadStatus.unconfigured:
        homeNotices.add(
          const _HomeStatus(
            key: ValueKey('battle-unconfigured'),
            variant: BattleBannerVariant.warning,
            title: 'Friend battles are unavailable in this build',
            body:
                'You can practice solo. Ask the beta organizer for the latest '
                'battle-enabled build; your challenge link is kept.',
          ),
        );
      case BattleLoadStatus.offline:
        homeNotices.add(
          _ProblemBanner(
            key: const ValueKey('battle-offline'),
            variant: BattleBannerVariant.danger,
            title: 'You are offline',
            body: snapshot.inboxMessage ??
                'Requests and matches cannot be reached right now.',
            onRetry: controller.loadHome,
          ),
        );
      case BattleLoadStatus.error:
        homeNotices.add(
          _ProblemBanner(
            key: const ValueKey('battle-error'),
            variant: BattleBannerVariant.danger,
            title: 'Could not load Battle',
            body: snapshot.inboxMessage ?? 'The server answered unexpectedly.',
            onRetry: controller.loadHome,
          ),
        );
      case BattleLoadStatus.blocked:
        homeNotices.add(
          BattleBanner(
            key: const ValueKey('battle-blocked'),
            variant: BattleBannerVariant.warning,
            title: 'Challenging is unavailable',
            body: snapshot.inboxMessage ??
                'This player cannot be challenged from your account.',
          ),
        );
      case BattleLoadStatus.signedOut:
        break;
      case BattleLoadStatus.empty:
      case BattleLoadStatus.ready:
        final incoming = snapshot.incomingRequest;
        if (incoming != null) {
          children.add(
            _IncomingRequestCard(
              request: incoming,
              onAccept: () => controller.acceptRequest(incoming.id),
              onDecline: () => showBattleDeclineDialog(
                context,
                username: incoming.sender.username ?? 'the challenger',
                onConfirm: () => controller.declineRequest(incoming.id),
              ),
              onOpenInbox: () => _openInbox(controller),
            ),
          );
          children.add(const SizedBox(height: ArenaBattleSpace.s4));
        }
    }

    final queueActive = snapshot.queuePhase == BattleQueuePhase.searching ||
        snapshot.queuePhase == BattleQueuePhase.extended;
    if (queueActive) {
      children.add(
        _RankedSearchCard(
          snapshot: snapshot,
          onStop: controller.stopRankedSearch,
          onChallengeFriend: () => controller.challengeFriend(),
        ),
      );
      children.add(const SizedBox(height: ArenaBattleSpace.s4));
    } else if (snapshot.queuePhase == BattleQueuePhase.stopped) {
      children.add(
        BattleBanner(
          key: const ValueKey('battle-search-stopped'),
          variant: BattleBannerVariant.warning,
          title: 'No opponent found in 60 seconds',
          body: 'The queue stopped. Nothing was created and no rating changed.',
          actions: [
            BattleSecondaryButton(
              key: const ValueKey('battle-retry-search'),
              label: 'Retry ranked search',
              onPressed: controller.startRankedSearch,
            ),
            BattlePrimaryButton(
              label: 'Challenge a friend',
              block: false,
              onPressed: () => controller.challengeFriend(),
            ),
          ],
        ),
      );
      children.add(const SizedBox(height: ArenaBattleSpace.s4));
    }

    for (final request in snapshot.requests.where(
      (request) =>
          request.isOutgoing && request.kind == BattleRequestKind.pending,
    )) {
      children.add(
        OutgoingRequestCard(
          key: ValueKey('battle-request-pending-${request.id}'),
          request: request,
          controller: controller,
        ),
      );
      children.add(const SizedBox(height: ArenaBattleSpace.s3));
    }

    if (config.soloModeEnabled) {
      children.add(
        BattleHeroAction(
          key: const ValueKey('battle-solo-set'),
          title: 'Start solo set',
          helper: 'Practice on your own. No account needed.',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SoloPage(cameraEnabled: cameraAvailable),
            ),
          ),
        ),
      );
      children.add(const SizedBox(height: ArenaBattleSpace.s3));
    }
    children.add(
      BattleHeroAction(
        key: const ValueKey('battle-challenge-friend'),
        title: 'Challenge a friend',
        helper: 'Share a link. Nothing is sent until they open it.',
        onPressed: () => controller.challengeFriend(),
      ),
    );
    children.add(const SizedBox(height: ArenaBattleSpace.s3));
    if (config.challengeLinksEnabled) {
      children.add(
        BattleSecondaryButton(
          key: const ValueKey('battle-my-link'),
          label: _linkOpening ? 'Loading link…' : 'My challenge link / code',
          block: true,
          onPressed: _linkOpening ? null : _openMyLink,
        ),
      );
      children.add(const SizedBox(height: ArenaBattleSpace.s3));
    }
    for (final notice in homeNotices) {
      children.add(notice);
      children.add(const SizedBox(height: ArenaBattleSpace.s3));
    }
    if (rankedAvailable) {
      children.add(
        BattleSecondaryAction(
          key: const ValueKey('battle-find-opponent'),
          title: 'Find an opponent',
          helper: 'Ranked · camera-counted · rating changes only after a '
              'confirmed result',
          onPressed: controller.startRankedSearch,
        ),
      );
    } else if (snapshot.inboxStatus != BattleLoadStatus.unconfigured) {
      children.add(
        _HomeStatus(
          key: const ValueKey('battle-ranked-unavailable'),
          title: 'Ranked matchmaking is unavailable',
          body: config.rankedMatchmakingEnabled
              ? 'This build does not enable camera counting, so ranked battles '
                  'cannot be scored.'
              : 'This build does not include ranked matchmaking.',
        ),
      );
    }
    children.add(const SizedBox(height: ArenaBattleSpace.s3));
    children.add(
      Center(
        child: BattleQuietButton(
          key: const ValueKey('battle-join-code'),
          label: 'Join with code',
          onPressed: () =>
              showJoinCodeDialog(context, onJoin: controller.joinWithCode),
        ),
      ),
    );
    if (snapshot.inboxStatus != BattleLoadStatus.unconfigured) {
      children.add(const SizedBox(height: ArenaBattleSpace.s3));
      children.add(
        Text(
          cameraAvailable
              ? 'Live 60-second battles only: push-ups or squats, counted by '
                  'your camera. No bots and no replaying an old score.'
              : 'Camera counting is off in this build. Friend challenges and the '
                  'inbox still work; ranked battles stay unavailable.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
      );
    }
    return children;
  }

  void _openInbox(BattleController controller) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const BattleInboxPage()))
        .whenComplete(controller.closeInbox);
  }

  Future<void> _openMyLink() async {
    if (_linkOpening) return;
    final linking = ArenaLinkingScope.of(context);
    setState(() => _linkOpening = true);
    try {
      if (!await linking.auth.isSignedIn()) {
        if (!mounted) return;
        final method = await showModalBottomSheet<ChallengeAuthMethod>(
          context: context,
          builder: (context) => SafeArea(
            child: Padding(
              padding: ArenaBattleSpace.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sign in to get your challenge link'),
                  for (final method in ChallengeAuthMethod.values)
                    BattleSecondaryButton(
                      label: method == ChallengeAuthMethod.google
                          ? 'Continue with Google'
                          : 'Continue with email',
                      onPressed: () => Navigator.of(context).pop(method),
                    ),
                ],
              ),
            ),
          ),
        );
        if (method == null || !mounted) return;
        await linking.auth.signIn(method);
      }
      final result = await linking.shareService.prepareChallenge();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeShareWaitingPage(
            result: result,
            service: linking.shareService,
            linkOnly: true,
          ),
        ),
      );
    } on ChallengeShareException catch (error) {
      _linkError(error.message);
    } on ChallengeAuthException catch (error) {
      _linkError(error.message);
    } catch (_) {
      _linkError('Could not load your challenge link. Try again.');
    } finally {
      if (mounted) setState(() => _linkOpening = false);
    }
  }

  void _linkError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _NoticeBar extends StatelessWidget {
  const _NoticeBar({required this.snapshot});

  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final notice = snapshot.notice;
    if (notice == null) {
      return const SizedBox.shrink();
    }
    final variant = switch (snapshot.noticeKind) {
      BattleNoticeKind.positive => BattleBannerVariant.positive,
      BattleNoticeKind.warning => BattleBannerVariant.warning,
      BattleNoticeKind.danger => BattleBannerVariant.danger,
      BattleNoticeKind.info || null => BattleBannerVariant.info,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaBattleSpace.s3),
      child: BattleBanner(
        key: const ValueKey('battle-notice'),
        variant: variant,
        title: notice,
      ),
    );
  }
}

class _HomeStatus extends StatelessWidget {
  const _HomeStatus({
    super.key,
    required this.title,
    required this.body,
    this.variant = BattleBannerVariant.info,
  });

  final String title;
  final String body;
  final BattleBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    final warning = variant == BattleBannerVariant.warning;
    return Container(
      padding: const EdgeInsets.all(ArenaBattleSpace.s4),
      decoration: BoxDecoration(
        color: ArenaColors.graphite,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline,
            color: warning ? ArenaColors.warning : ArenaColors.secondary,
            size: 20,
          ),
          const SizedBox(width: ArenaBattleSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArenaBattleText.smallStrong.copyWith(
                    color: ArenaColors.softWhite,
                  ),
                ),
                const SizedBox(height: ArenaBattleSpace.s1),
                Text(
                  body,
                  style: ArenaBattleText.small.copyWith(
                    color: ArenaColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({
    super.key,
    required this.variant,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final BattleBannerVariant variant;
  final String title;
  final String body;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return BattleBanner(
      variant: variant,
      title: title,
      body: body,
      actions: [
        BattleSecondaryButton(
          key: const ValueKey('battle-retry-load'),
          label: 'Retry',
          onPressed: () => onRetry(),
        ),
      ],
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading requests',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: ArenaColors.graphite,
                borderRadius: BorderRadius.circular(
                  ArenaBattleSpace.radiusCard,
                ),
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

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onOpenInbox,
  });

  final BattleRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    final username = request.sender.username ?? 'The challenger';
    return Semantics(
      container: true,
      label: 'Request from @$username',
      child: BattleCard(
        key: const ValueKey('battle-incoming-card'),
        accent: ArenaColors.violet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BattleChip(
                  label: 'Incoming request',
                  variant: BattleChipVariant.opponent,
                ),
                Text(
                  'Expires in ${formatBattleCountdown(request.expiresAt)}',
                  style: ArenaBattleText.small.copyWith(
                    color: ArenaColors.quiet,
                  ),
                ),
              ],
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
              style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              '${request.mode.label} · 60 seconds. '
              'The exercise is revealed in preparation.',
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
                  key: const ValueKey('battle-accept-request'),
                  label: 'Accept challenge',
                  block: false,
                  onPressed: onAccept,
                ),
                BattleSecondaryButton(
                  key: const ValueKey('battle-decline-request'),
                  label: 'Decline',
                  onPressed: onDecline,
                ),
              ],
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
            Text(
              'Accepting creates a match. The countdown cannot start until '
              'both players are ready and present.',
              style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: BattleQuietButton(
                key: const ValueKey('battle-open-inbox'),
                label: 'View all requests',
                onPressed: onOpenInbox,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedSearchCard extends StatelessWidget {
  const _RankedSearchCard({
    required this.snapshot,
    required this.onStop,
    required this.onChallengeFriend,
  });

  final BattleSnapshot snapshot;
  final Future<void> Function() onStop;
  final VoidCallback onChallengeFriend;

  @override
  Widget build(BuildContext context) {
    final elapsed = snapshot.queueElapsed.inSeconds.clamp(0, 60);
    return Semantics(
      container: true,
      label: 'Ranked search',
      child: BattleCard(
        key: const ValueKey('battle-search-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                snapshot.queueOffline
                    ? const BattleChip(
                        key: ValueKey('battle-search-offline'),
                        label: 'Reconnecting',
                        variant: BattleChipVariant.danger,
                      )
                    : const BattleChip(
                        label: 'Searching',
                        variant: BattleChipVariant.warning,
                      ),
                Text(
                  '$elapsed s / 60 s',
                  style: ArenaBattleText.small.copyWith(
                    color: ArenaColors.quiet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
            Text(
              snapshot.queueOffline
                  ? 'The arena is unreachable. Your queue seat stays open '
                      'for up to 60 seconds; no opponent is promised and '
                      'nothing is created offline.'
                  : 'Looking for a ranked opponent near your rating. Nobody '
                      'is promised to be online.',
              style: ArenaBattleText.body.copyWith(
                color: snapshot.queueOffline
                    ? ArenaColors.warning
                    : ArenaColors.secondary,
              ),
            ),
            if (snapshot.queueExtended) ...[
              const SizedBox(height: ArenaBattleSpace.s2),
              Text(
                'Still searching. You can challenge a friend instead; '
                'switching cancels the queue seat.',
                style: ArenaBattleText.small.copyWith(
                  color: ArenaColors.warning,
                ),
              ),
            ],
            const SizedBox(height: ArenaBattleSpace.s3),
            Semantics(
              label: 'Search time used: $elapsed of 60 seconds',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: elapsed / 60,
                  minHeight: 12,
                  backgroundColor: ArenaColors.charcoal,
                  color: ArenaColors.lime,
                ),
              ),
            ),
            const SizedBox(height: ArenaBattleSpace.s4),
            Wrap(
              spacing: ArenaBattleSpace.s2,
              runSpacing: ArenaBattleSpace.s2,
              children: [
                BattleSecondaryButton(
                  key: const ValueKey('battle-stop-search'),
                  label: 'Stop search',
                  onPressed: () => onStop(),
                ),
                BattlePrimaryButton(
                  key: const ValueKey('battle-search-challenge-friend'),
                  label: 'Challenge a friend',
                  block: false,
                  onPressed: onChallengeFriend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
