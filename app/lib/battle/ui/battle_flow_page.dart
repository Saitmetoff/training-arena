/// Single phase-driven page for the whole match flow.
///
/// Preparation (exercise reveal, demonstration, private camera guidance and
/// the single unscored practice rep), ready gate, server countdown, 60-second
/// live round with reconnect banners, and the server-confirmed result or
/// no-result. The page never shows a local winner and never offers manual
/// competitive rep entry.
library;

import 'package:flutter/material.dart';

import '../../domain/arena_types.dart';
import '../../camera/phone_placement.dart';
import '../../theme/arena_tokens.dart';
import '../data/camera_session_bridge.dart';
import '../runtime/battle_controller.dart';
import '../runtime/battle_runtime.dart';
import '../state/battle_phase.dart';
import '../state/battle_snapshot.dart';
import 'battle_athlete_demo.dart';
import 'battle_dialogs.dart';
import 'battle_style.dart';
import 'battle_widgets.dart';

/// Match flow screen pushed by the Battle tab or a link landing (task 05).
class BattleFlowPage extends StatelessWidget {
  const BattleFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BattleRuntimeScope.of(context);
    final snapshot = controller.snapshot;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context, controller);
      },
      child: Scaffold(
        key: const ValueKey('battle-flow'),
        backgroundColor: ArenaColors.charcoal,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NoticeBar(snapshot: snapshot),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    ArenaBattleSpace.s4,
                    ArenaBattleSpace.s2,
                    ArenaBattleSpace.s4,
                    ArenaBattleSpace.s6,
                  ),
                  child: AnimatedSwitcher(
                    key: const ValueKey('battle-phase-switcher'),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey(snapshot.phase),
                      child: _body(context, controller, snapshot),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    BattleController controller,
    BattleSnapshot snapshot,
  ) {
    switch (snapshot.phase) {
      case BattlePhase.updateRequired:
        return Column(
          children: [
            const Text(
              'Update required',
              key: ValueKey('battle-update-required'),
              style: TextStyle(color: ArenaColors.softWhite, fontSize: 28),
            ),
            const Text(
              'Install the latest owner-test APK on both phones, then sign in again. '
              'The server keeps the authoritative battle outcome.',
              style: TextStyle(color: ArenaColors.secondary),
            ),
            TextButton(
              onPressed: () {
                controller.exitToHome();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Battle'),
            ),
          ],
        );
      case BattlePhase.preparing:
        return _PrepareBody(controller: controller, snapshot: snapshot);
      case BattlePhase.ready:
        return _ReadyBody(controller: controller, snapshot: snapshot);
      case BattlePhase.countdown:
        return _CountdownBody(controller: controller, snapshot: snapshot);
      case BattlePhase.live:
      case BattlePhase.reconnecting:
        return _LiveBody(controller: controller, snapshot: snapshot);
      case BattlePhase.result:
        return _ResultBody(controller: controller, snapshot: snapshot);
      case BattlePhase.noResult:
        return _NoResultBody(controller: controller, snapshot: snapshot);
      case BattlePhase.exiting:
        return _ExitingBody(reason: snapshot.exitReason);
      case BattlePhase.loading:
      case BattlePhase.resolving:
      case BattlePhase.home:
      case BattlePhase.inbox:
      case BattlePhase.exited:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(ArenaBattleSpace.s6),
            child: Text(
              'Returning to Battle…',
              style: TextStyle(color: ArenaColors.secondary),
            ),
          ),
        );
    }
  }

  void _handleBack(BuildContext context, BattleController controller) {
    final phase = controller.snapshot.phase;
    if (phase == BattlePhase.result ||
        phase == BattlePhase.noResult ||
        phase == BattlePhase.updateRequired) {
      controller.exitToHome();
      Navigator.of(context).pop();
      return;
    }
    final reason = switch (phase) {
      BattlePhase.preparing => BattleExitReason.leftPreparation,
      BattlePhase.ready => BattleExitReason.cancelledMatch,
      BattlePhase.countdown => BattleExitReason.leftCountdown,
      BattlePhase.live || BattlePhase.reconnecting => BattleExitReason.leftLive,
      BattlePhase.exiting => BattleExitReason.leftLive,
      _ => BattleExitReason.cancelledMatch,
    };
    _confirmLeave(context, controller, reason);
  }

  static Future<void> _confirmLeave(
    BuildContext context,
    BattleController controller,
    BattleExitReason reason,
  ) {
    return showBattleLeaveDialog(
      context,
      reason: reason,
      onConfirm: () => controller.confirmLeave(reason),
    );
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
      padding: const EdgeInsets.fromLTRB(
        ArenaBattleSpace.s4,
        ArenaBattleSpace.s2,
        ArenaBattleSpace.s4,
        0,
      ),
      child: BattleBanner(
        key: const ValueKey('battle-flow-notice'),
        variant: variant,
        title: notice,
      ),
    );
  }
}

// ---------------------------------------------------------------- preparation

class _PrepareBody extends StatelessWidget {
  const _PrepareBody({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final match = snapshot.match;
    if (match == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          kicker: 'Preparation · 1 of 3',
          onLeave: () => showBattleLeaveDialog(
            context,
            reason: BattleExitReason.leftPreparation,
            onConfirm: () =>
                controller.confirmLeave(BattleExitReason.leftPreparation),
          ),
        ),
        Text(
          'Preparation',
          style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattleCard(
          key: const ValueKey('battle-prep-exercise'),
          accent: ArenaColors.lime,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BattleKicker('Exercise revealed'),
              const SizedBox(height: ArenaBattleSpace.s1),
              Text(
                match.exercise.label,
                style: ArenaBattleText.h1.copyWith(color: ArenaColors.lime),
              ),
              const SizedBox(height: ArenaBattleSpace.s2),
              Text(
                'One exercise, chosen by the server when the match was '
                'created. It is revealed here and does not change. There is '
                'no manual score entry.',
                style: ArenaBattleText.small.copyWith(
                  color: ArenaColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        BattleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BattleKicker('3D demonstration'),
              const SizedBox(height: ArenaBattleSpace.s2),
              BattleAthleteDemo(exercise: match.exercise),
              const SizedBox(height: ArenaBattleSpace.s2),
              Text(
                'Instructional only. It does not verify form and does not '
                'count reps.',
                style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        _CameraCard(controller: controller, snapshot: snapshot),
        const SizedBox(height: ArenaBattleSpace.s3),
        const _FramingCard(),
        const SizedBox(height: ArenaBattleSpace.s3),
        _PracticeCard(controller: controller, snapshot: snapshot),
        const SizedBox(height: ArenaBattleSpace.s3),
        BattlePrimaryButton(
          key: const ValueKey('battle-ready-button'),
          label: 'I’m ready',
          large: true,
          semanticEnabled: snapshot.canSubmitReady,
          onPressed: controller.requestReady,
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Text(
          'Both players must be present and ready. The countdown cannot '
          'start unattended.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final status = snapshot.cameraStatus;
    final (chipLabel, chipVariant, color) = switch (status) {
      BattleCameraStatus.tracking => (
        'Camera ready · tracking',
        BattleChipVariant.positive,
        ArenaColors.positive,
      ),
      BattleCameraStatus.framing => (
        'Framing',
        BattleChipVariant.warning,
        ArenaColors.warning,
      ),
      BattleCameraStatus.trackingLost => (
        'Tracking lost',
        BattleChipVariant.warning,
        ArenaColors.warning,
      ),
      BattleCameraStatus.permissionDenied => (
        'Permission denied',
        BattleChipVariant.danger,
        ArenaColors.danger,
      ),
      BattleCameraStatus.unavailable => (
        'Unavailable',
        BattleChipVariant.warning,
        ArenaColors.warning,
      ),
      BattleCameraStatus.preparing => (
        'Preparing camera',
        BattleChipVariant.neutral,
        ArenaColors.secondary,
      ),
      BattleCameraStatus.unknown => (
        'Camera placeholder',
        BattleChipVariant.neutral,
        ArenaColors.secondary,
      ),
    };
    return BattleCard(
      key: const ValueKey('battle-camera-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BattleKicker('Camera preview (private)'),
          const SizedBox(height: ArenaBattleSpace.s2),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: ArenaColors.charcoal,
              borderRadius: BorderRadius.circular(
                ArenaBattleSpace.radiusControl,
              ),
              border: Border.all(color: ArenaColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                battleCameraPreview(controller.camera) ??
                    Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: color,
                        size: 36,
                      ),
                    ),
                Positioned(
                  top: ArenaBattleSpace.s2,
                  left: ArenaBattleSpace.s2,
                  child: BattleChip(label: chipLabel, variant: chipVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          Text(
            snapshot.cameraMessage ??
                'Frames are processed on this device and never uploaded. '
                    'Only rep counts leave the phone.',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _FramingCard extends StatelessWidget {
  const _FramingCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      cameraPhonePlacementGuidance,
      'Clear space around you for the full movement.',
    ];
    return BattleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Framing',
            style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: ArenaBattleSpace.s1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check,
                    color: ArenaColors.positive,
                    size: 18,
                  ),
                  const SizedBox(width: ArenaBattleSpace.s2),
                  Expanded(
                    child: Text(
                      tip,
                      style: ArenaBattleText.small.copyWith(
                        color: ArenaColors.secondary,
                      ),
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

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final state = snapshot.practice;
    return BattleCard(
      key: const ValueKey('battle-practice-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice rep',
            style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          if (state == PracticeState.notStarted) ...[
            BattleSecondaryButton(
              key: const ValueKey('battle-practice-rep'),
              label: 'Take 1 practice rep',
              block: true,
              onPressed: controller.takePracticeRep,
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              'Exactly one practice rep. It is never scored.',
              style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
            ),
          ] else if (state == PracticeState.counting) ...[
            const BattleChip(
              key: ValueKey('battle-practice-counting'),
              label: 'Waiting for the camera',
              variant: BattleChipVariant.warning,
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              snapshot.cameraMessage ??
                  'Complete one rep in frame. There is no manual score '
                      'entry.',
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.secondary,
              ),
            ),
          ] else ...[
            const BattleChip(
              key: ValueKey('battle-practice-done'),
              label: 'Practice rep counted — 1 of 1',
              variant: BattleChipVariant.positive,
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              'Unscored. It never changes the battle score.',
              style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ ready gate

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final opponent = snapshot.opponent;
    final viewer = snapshot.viewer;
    final opponentReady = snapshot.opponentReady;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          kicker: 'Ready check · 2 of 3',
          onLeave: () => showBattleLeaveDialog(
            context,
            reason: BattleExitReason.cancelledMatch,
            onConfirm: () =>
                controller.confirmLeave(BattleExitReason.cancelledMatch),
          ),
        ),
        Text(
          'Ready check',
          style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        _ReadyPair(
          viewer: viewer,
          opponent: opponent,
          opponentReady: opponentReady,
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        if (opponentReady)
          const BattleBanner(
            key: ValueKey('battle-both-ready'),
            variant: BattleBannerVariant.positive,
            title: 'Both players ready',
            body: 'The countdown starts on the server clock in a moment.',
          )
        else
          const BattleBanner(
            key: ValueKey('battle-ready-waiting'),
            variant: BattleBannerVariant.positive,
            title: 'Nothing starts unattended',
            body:
                'The countdown begins only when both players are ready and '
                'connected. If one player leaves, the match expires in 10 '
                'minutes without a rating change.',
          ),
        const SizedBox(height: ArenaBattleSpace.s3),
        Text(
          opponentReady
              ? 'Starting the countdown…'
              : 'Waiting for @${opponent?.username ?? 'your opponent'}. '
                    'Nothing starts until you both confirm ready.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        BattleDangerButton(
          label: 'Cancel match',
          onPressed: () => showBattleLeaveDialog(
            context,
            reason: BattleExitReason.cancelledMatch,
            onConfirm: () =>
                controller.confirmLeave(BattleExitReason.cancelledMatch),
          ),
        ),
      ],
    );
  }
}

class _ReadyPair extends StatelessWidget {
  const _ReadyPair({
    required this.viewer,
    required this.opponent,
    required this.opponentReady,
  });

  final ArenaProfile? viewer;
  final ArenaProfile? opponent;
  final bool opponentReady;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BattleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BattleKicker('You'),
                const SizedBox(height: ArenaBattleSpace.s2),
                if (viewer != null)
                  BattleIdentity(profile: viewer!, role: 'you · player'),
                const SizedBox(height: ArenaBattleSpace.s2),
                const BattleChip(
                  label: 'Ready',
                  variant: BattleChipVariant.positive,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: ArenaBattleSpace.s3),
        Expanded(
          child: BattleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BattleKicker('Opponent'),
                const SizedBox(height: ArenaBattleSpace.s2),
                if (opponent != null)
                  BattleIdentity(
                    profile: opponent!,
                    role: 'opponent',
                    accent: true,
                  ),
                const SizedBox(height: ArenaBattleSpace.s2),
                if (opponentReady)
                  const BattleChip(
                    label: 'Ready',
                    variant: BattleChipVariant.positive,
                  )
                else
                  const BattleChip(label: 'Waiting for them'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- countdown

class _CountdownBody extends StatelessWidget {
  const _CountdownBody({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final seconds = controller.countdownSecondsRemaining ?? 5;
    final match = snapshot.match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          kicker: 'Countdown',
          onLeave: () => showBattleLeaveDialog(
            context,
            reason: BattleExitReason.leftCountdown,
            onConfirm: () =>
                controller.confirmLeave(BattleExitReason.leftCountdown),
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s5),
        Text(
          'Get into position',
          textAlign: TextAlign.center,
          style: ArenaBattleText.h3.copyWith(color: ArenaColors.secondary),
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleTimerValue(
          key: const ValueKey('battle-countdown-value'),
          seconds: seconds,
          semanticLabel: 'Countdown seconds: $seconds',
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Text(
          '${match?.exercise.label ?? 'Exercise'} · 60 seconds · opponent '
          '@${snapshot.opponent?.username ?? 'opponent'}',
          textAlign: TextAlign.center,
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
        const SizedBox(height: ArenaBattleSpace.s5),
        _ReadyPair(
          viewer: snapshot.viewer,
          opponent: snapshot.opponent,
          opponentReady: true,
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        Text(
          'The countdown starts from the server clock. It cannot start '
          'unattended.',
          textAlign: TextAlign.center,
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ live round

class _LiveBody extends StatelessWidget {
  const _LiveBody({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final match = snapshot.match;
    if (match == null) {
      return const SizedBox.shrink();
    }
    final seconds = controller.liveSecondsRemaining ?? 60;
    final progress = controller.roundProgress;
    final viewer = snapshot.viewer;
    final opponent = snapshot.opponent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          kicker: 'Live · ${match.exercise.label}',
          onLeave: () => showBattleLeaveDialog(
            context,
            reason: BattleExitReason.leftLive,
            onConfirm: () => controller.confirmLeave(BattleExitReason.leftLive),
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        BattleTimerValue(
          key: const ValueKey('battle-live-timer'),
          seconds: seconds,
          semanticLabel: 'Time remaining: $seconds seconds',
          dangerAt10: true,
          large: true,
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Semantics(
          label: 'Round progress: ${(progress * 100).round()} percent',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: ArenaColors.graphite,
              color: seconds <= 10 ? ArenaColors.danger : ArenaColors.lime,
            ),
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Text(
          '${match.exercise.label} · 60 seconds',
          textAlign: TextAlign.center,
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
        if (battleCameraPreview(controller.camera) != null) ...[
          const SizedBox(height: ArenaBattleSpace.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
            child: SizedBox(
              height: 160,
              child: battleCameraPreview(controller.camera),
            ),
          ),
        ],
        const SizedBox(height: ArenaBattleSpace.s4),
        _LiveStatusBanner(controller: controller, snapshot: snapshot),
        const SizedBox(height: ArenaBattleSpace.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: viewer == null
                  ? const SizedBox.shrink()
                  : BattleScorePanel(
                      key: const ValueKey('battle-score-you'),
                      profile: viewer,
                      ownerLabel: 'Your',
                      score: snapshot.viewerPlayer?.score ?? 0,
                      stateLine: _viewerStateLine(snapshot),
                    ),
            ),
            const SizedBox(width: ArenaBattleSpace.s3),
            Expanded(
              child: opponent == null
                  ? const SizedBox.shrink()
                  : BattleScorePanel(
                      key: const ValueKey('battle-score-opp'),
                      profile: opponent,
                      ownerLabel: '@${opponent.username ?? 'opponent'}\'s',
                      accent: true,
                      score: snapshot.opponentPlayer?.score ?? 0,
                      stateLine: _opponentStateLine(snapshot),
                    ),
            ),
          ],
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        Text(
          'Scores are confirmed by the server. Camera frames never leave the '
          'device. A lost connection gets 10 seconds to recover before a '
          'forfeit; a shared service failure gives no result.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
      ],
    );
  }

  String _viewerStateLine(BattleSnapshot snapshot) {
    if (snapshot.connection == BattleConnection.serviceOutage) {
      return 'Last confirmed by server';
    }
    if (snapshot.connection == BattleConnection.selfTrackingLost ||
        snapshot.cameraStatus == BattleCameraStatus.trackingLost) {
      return 'Counting paused';
    }
    return 'Tracking: stable';
  }

  String _opponentStateLine(BattleSnapshot snapshot) {
    switch (snapshot.connection) {
      case BattleConnection.opponentReconnecting:
        return 'Reconnecting…';
      case BattleConnection.opponentLost:
        return 'Connection lost';
      case BattleConnection.serviceOutage:
        return 'Last confirmed by server';
      case BattleConnection.selfTrackingLost:
      case BattleConnection.online:
        return snapshot.opponentTracking ? 'Live' : 'Tracking paused';
    }
  }
}

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.reconnectExpired &&
        snapshot.connection == BattleConnection.serviceOutage) {
      return BattleBanner(
        key: const ValueKey('battle-live-status'),
        variant: BattleBannerVariant.danger,
        title: 'Connection lost for more than 10 seconds',
        body:
            'The server will confirm the outcome. No local result is '
            'assumed. You can keep retrying or leave the battle.',
        actions: [
          BattleSecondaryButton(
            key: const ValueKey('battle-retry-connection'),
            label: 'Retry connection',
            onPressed: controller.retryConnection,
          ),
          BattleDangerButton(
            label: 'Leave battle',
            onPressed: () => showBattleLeaveDialog(
              context,
              reason: BattleExitReason.leftLive,
              onConfirm: () =>
                  controller.confirmLeave(BattleExitReason.leftLive),
            ),
          ),
        ],
      );
    }
    switch (snapshot.connection) {
      case BattleConnection.selfTrackingLost:
        return BattleBanner(
          key: const ValueKey('battle-live-status'),
          variant: BattleBannerVariant.warning,
          title: 'Camera tracking lost — your counting is paused',
          body:
              'The shared clock keeps running. Re-scan when you are back '
              'in frame. Your last confirmed score stays visible.',
          actions: [
            BattleSecondaryButton(
              key: const ValueKey('battle-rescan'),
              label: 'Try re-scan',
              onPressed: controller.retryTracking,
            ),
          ],
        );
      case BattleConnection.opponentReconnecting:
      case BattleConnection.opponentLost:
        return const BattleBanner(
          key: ValueKey('battle-live-status'),
          variant: BattleBannerVariant.warning,
          title: 'Opponent reconnecting',
          body:
              'They have ten seconds to recover before the server confirms '
              'a forfeit. Their panel shows the last confirmed score.',
        );
      case BattleConnection.serviceOutage:
        return BattleBanner(
          key: const ValueKey('battle-live-status'),
          variant: BattleBannerVariant.danger,
          title: 'Battle service unreachable',
          body:
              'The score cannot be confirmed. If the outage continues, '
              'this battle ends with no result and no rating change.',
          actions: [
            BattleSecondaryButton(
              key: const ValueKey('battle-retry-connection'),
              label: 'Retry connection',
              onPressed: controller.retryConnection,
            ),
            BattleDangerButton(
              label: 'Leave battle',
              onPressed: () => showBattleLeaveDialog(
                context,
                reason: BattleExitReason.leftLive,
                onConfirm: () =>
                    controller.confirmLeave(BattleExitReason.leftLive),
              ),
            ),
          ],
        );
      case BattleConnection.online:
        return const BattleBanner(
          key: ValueKey('battle-live-status'),
          variant: BattleBannerVariant.positive,
          title: 'Tracking and connection stable',
          body:
              'Both players are counted. Scores appear as the server '
              'confirms reps.',
        );
    }
  }
}

// ---------------------------------------------------------------------- result

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final receipt = snapshot.receipt;
    if (receipt == null) {
      return const SizedBox.shrink();
    }
    final viewerId = snapshot.viewerId;
    ArenaReceiptPlayer? viewer;
    ArenaReceiptPlayer? opponent;
    for (final player in receipt.players) {
      if (player.profile.id == viewerId) {
        viewer = player;
      } else {
        opponent = player;
      }
    }
    final viewerKnown = viewerId != null && viewer != null;
    final won = viewerKnown && receipt.outcomeFor(viewerId);
    String? unknownWinner;
    if (!viewerKnown && receipt.outcome == ArenaMatchOutcome.win) {
      for (final player in receipt.players) {
        if (player.profile.id == receipt.winnerId) {
          unknownWinner = player.profile.username;
          break;
        }
      }
    }
    final draw = receipt.outcome == ArenaMatchOutcome.draw;
    final margin = (viewer?.score ?? 0) - (opponent?.score ?? 0);
    final opponentName = opponent?.profile.username ?? 'opponent';
    // A forfeit decides the match without a scored round; never present it as
    // a zero-margin score ("beat me by 0").
    final forfeit = switch (receipt.reason) {
      'opponent_absent' || 'abandoned_preparing' || 'service_outage' => true,
      _ => false,
    };
    final headline = draw
        ? (viewerKnown
              ? 'Draw — ${viewer.score} each'
              : 'Draw — server confirmed')
        : !viewerKnown
        ? (unknownWinner == null ? 'Result confirmed' : '@$unknownWinner won')
        : won
        ? (forfeit
              ? '@$opponentName didn\'t finish — win confirmed'
              : 'I beat @$opponentName by ${margin.abs()}')
        : (forfeit
              ? 'I didn\'t finish — @$opponentName wins'
              : '@$opponentName beat me by ${margin.abs()}');
    final headlineColor = draw || !viewerKnown
        ? ArenaColors.softWhite
        : won
        ? ArenaColors.lime
        : ArenaColors.violet;
    final ranked = receipt.mode == ArenaMatchMode.ranked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TopBar(kicker: 'Confirmed result', onLeave: null),
        battleCameraTraceControls(controller.camera),
        Text(
          headline,
          key: const ValueKey('battle-result-headline'),
          style: ArenaBattleText.h1.copyWith(color: headlineColor),
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ResultScore(
                      label: viewerKnown
                          ? 'You'
                          : '@${receipt.players.isEmpty ? 'player' : (receipt.players.first.profile.username ?? 'player')}',
                      score: viewerKnown
                          ? viewer.score
                          : (receipt.players.isEmpty
                                ? 0
                                : receipt.players.first.score),
                      color: ArenaColors.lime,
                      wash: ArenaColors.playerWash,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ArenaBattleSpace.s3,
                    ),
                    child: Text(
                      '–',
                      style: ArenaBattleText.h2.copyWith(
                        color: ArenaColors.quiet,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _ResultScore(
                      label: '@$opponentName',
                      score: opponent?.score ?? 0,
                      color: ArenaColors.violet,
                      wash: ArenaColors.opponentWash,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ArenaBattleSpace.s4),
              Wrap(
                spacing: ArenaBattleSpace.s2,
                runSpacing: ArenaBattleSpace.s2,
                children: [
                  BattleChip(label: '${receipt.exercise.label} · 60 seconds'),
                  if (ranked)
                    BattleChip(
                      label: _rankedLabel(viewer),
                      variant: BattleChipVariant.positive,
                    )
                  else
                    const BattleChip(label: 'Casual · rating unchanged'),
                ],
              ),
              const SizedBox(height: ArenaBattleSpace.s3),
              Text(
                'Confirmed by the server. The receipt is immutable: names, '
                'scores and rating are a snapshot.',
                style: ArenaBattleText.small.copyWith(
                  color: ArenaColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        if (viewerKnown && !snapshot.previewFixtures) ...[
          BattlePrimaryButton(
            key: const ValueKey('battle-result-rematch'),
            label: controller.rematching
                ? 'Requesting…'
                : 'Challenge @$opponentName again',
            onPressed: controller.rematching ? null : controller.requestRematch,
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
        ],
        BattlePrimaryButton(
          key: const ValueKey('battle-result-share'),
          label: 'Share challenge',
          large: true,
          onPressed: () => controller.challengeFriend(receipt: receipt),
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        BattleSecondaryButton(
          key: const ValueKey('battle-result-back'),
          label: 'Back to Battle',
          block: true,
          onPressed: () {
            controller.exitToHome();
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Text(
          'Sharing starts a new challenge for a new live battle. It never '
          'replays this match or compares old scores.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('battle-receipt-details'),
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Receipt details',
              style: ArenaBattleText.smallStrong.copyWith(
                color: ArenaColors.secondary,
              ),
            ),
            children: [
              _ReceiptRow(label: 'Receipt', value: receipt.id),
              _ReceiptRow(
                label: 'Exercise',
                value: '${receipt.exercise.label} · 60 seconds',
              ),
              _ReceiptRow(label: 'Mode', value: receipt.mode.label),
              _ReceiptRow(
                label: 'Confirmed',
                value: receipt.finishedAt?.toIso8601String() ?? 'Server time',
              ),
              const _ReceiptRow(label: 'Source', value: 'Server receipt'),
            ],
          ),
        ),
      ],
    );
  }

  String _rankedLabel(ArenaReceiptPlayer? viewer) {
    final after = viewer?.ratingAfter;
    final change = viewer?.ratingChange;
    if (after == null) {
      return 'Ranked · rating confirmed by server';
    }
    final before = after - (change ?? 0);
    return 'Ranked · $before → $after';
  }
}

class _ResultScore extends StatelessWidget {
  const _ResultScore({
    required this.label,
    required this.score,
    required this.color,
    required this.wash,
  });

  final String label;
  final int score;
  final Color color;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaBattleSpace.s4),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: ArenaBattleText.small.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          Semantics(
            label: '$label score: $score reps',
            child: ExcludeSemantics(
              child: Text(
                '$score',
                style: ArenaBattleText.score.copyWith(color: color),
              ),
            ),
          ),
          Text(
            'reps',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaBattleSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.softWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- no result

class _NoResultBody extends StatelessWidget {
  const _NoResultBody({required this.controller, required this.snapshot});

  final BattleController controller;
  final BattleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TopBar(kicker: 'Confirmed outcome', onLeave: null),
        battleCameraTraceControls(controller.camera),
        Text(
          'No result',
          key: const ValueKey('battle-no-result-headline'),
          style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattleBanner(
          key: const ValueKey('battle-no-result-reason'),
          variant: BattleBannerVariant.warning,
          title: 'No rating change',
          body:
              snapshot.noResultReason ??
              'The match ended without a confirmed score.',
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattleSecondaryButton(
          key: const ValueKey('battle-no-result-back'),
          label: 'Back to Battle',
          block: true,
          onPressed: () {
            controller.exitToHome();
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Text(
          'A no-result keeps the rating unchanged for both players.',
          style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
        ),
      ],
    );
  }
}

class _ExitingBody extends StatelessWidget {
  const _ExitingBody({required this.reason});

  final BattleExitReason reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ArenaBattleSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Leaving the match',
            style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          Text(
            'Reporting your leave to the server. No local outcome is '
            'assumed.',
            style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.kicker, required this.onLeave});

  final String kicker;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onLeave != null)
          IconButton(
            key: const ValueKey('battle-leave'),
            onPressed: onLeave,
            icon: const Icon(Icons.close),
            color: ArenaColors.softWhite,
            tooltip: 'Leave',
          ),
        Expanded(
          child: Text(
            kicker.toUpperCase(),
            style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
          ),
        ),
      ],
    );
  }
}
