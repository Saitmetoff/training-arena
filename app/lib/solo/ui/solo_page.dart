/// Solo max-reps set screen.
///
/// Reachable from the Battle tab when `ARENA_FEATURE_SOLO_MODE` is on. A solo
/// set is practice: the screen states that it creates no receipt, rating or
/// leaderboard entry, and a self-reported set is labelled as such.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../../camera/camera_preview.dart';
import '../../camera/phone_placement.dart';
import '../../battle/ports/battle_feedback.dart';
import '../../theme/arena_tokens.dart';
import '../data/solo_result_store.dart';
import '../domain/solo_badges.dart';
import '../domain/solo_result.dart';
import '../domain/solo_streak.dart';
import '../runtime/solo_controller.dart';

class SoloPage extends StatefulWidget {
  const SoloPage({super.key, this.controller, this.cameraEnabled = false});

  /// Test seam; when omitted the page builds its own controller.
  final SoloController? controller;

  /// Mirrors `ArenaConfig.cameraCountingEnabled` so the intro can be honest
  /// about which path exists in this build.
  final bool cameraEnabled;

  @override
  State<SoloPage> createState() => _SoloPageState();
}

class _SoloPageState extends State<SoloPage> {
  late final SoloController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SoloController(
          store: SharedPreferencesSoloResultStore(),
          cameraEnabled: widget.cameraEnabled,
        );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final snapshot = _controller.snapshot;
            return ListView(
              key: const ValueKey('solo-page'),
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
                      key: const ValueKey('solo-back'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: ArenaColors.softWhite,
                      tooltip: 'Back to Battle',
                    ),
                    Text(
                      'Solo set',
                      style: ArenaBattleText.h1.copyWith(
                        color: ArenaColors.softWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ArenaBattleSpace.s3),
                ..._body(snapshot),
                const SizedBox(height: ArenaBattleSpace.s5),
                Text(
                  'Solo sets are practice: no receipt, no rating, no '
                  'leaderboard. Results stay on this device.',
                  style: ArenaBattleText.small.copyWith(
                    color: ArenaColors.quiet,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(SoloSnapshot snapshot) {
    switch (snapshot.phase) {
      case SoloPhase.intro:
        return _intro(snapshot);
      case SoloPhase.countdown:
        return _countdown(snapshot);
      case SoloPhase.practice:
        return _practice();
      case SoloPhase.counting:
        return _counting(snapshot);
      case SoloPhase.manualEntry:
        return _manualEntry(snapshot);
      case SoloPhase.result:
        return _result(snapshot);
    }
  }

  List<Widget> _intro(SoloSnapshot snapshot) {
    return [
      Text(
        'A max-reps set on your own. Counted by your camera when it is on, '
        'or entered by hand.',
        style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
      ),
      const SizedBox(height: ArenaBattleSpace.s4),
      if (snapshot.cameraEnabled) ...[
        Text(
          '$cameraPhonePlacementGuidance You will do one unscored practice rep first.',
          key: const ValueKey('solo-placement'),
          style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        BattlePrimaryButton(
          key: const ValueKey('solo-start-camera'),
          label: 'Count with camera',
          onPressed: _controller.startCamera,
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
      ],
      BattleSecondaryButton(
        key: const ValueKey('solo-start-manual'),
        label: 'Enter reps manually · self-reported',
        block: true,
        onPressed: _controller.startManualEntry,
      ),
      const SizedBox(height: ArenaBattleSpace.s3),
      if (!snapshot.cameraEnabled) ...[
        BattleBanner(
          key: const ValueKey('solo-camera-off'),
          variant: BattleBannerVariant.info,
          title: 'Self-reported solo set',
          body:
              'Complete your ${_controller.exercise.label.toLowerCase()}, then enter your count. '
              'Camera counting is not available in this beta.',
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
      ],
      if (snapshot.message != null) ...[
        BattleBanner(
          key: const ValueKey('solo-camera-message'),
          variant: BattleBannerVariant.warning,
          title: 'Could not complete this action',
          body: snapshot.message!,
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
      ],
      if (snapshot.stats.sessions > 0) ...[
        _StatsCard(stats: snapshot.stats),
        const SizedBox(height: ArenaBattleSpace.s4),
      ],
      _StreakCard(streak: snapshot.streak),
      const SizedBox(height: ArenaBattleSpace.s4),
      _BadgeGrid(
        badges: soloBadges(stats: snapshot.stats, streak: snapshot.streak),
      ),
      const SizedBox(height: ArenaBattleSpace.s4),
      _SoloHistory(results: snapshot.recentResults),
    ];
  }

  List<Widget> _countdown(SoloSnapshot snapshot) {
    return [
      const SizedBox(height: ArenaBattleSpace.s6),
      BattleTimerValue(
        seconds: snapshot.countdown,
        semanticLabel: 'Starting in ${snapshot.countdown} seconds',
        large: true,
      ),
      const SizedBox(height: ArenaBattleSpace.s3),
      Text(
        'Get into position.',
        textAlign: TextAlign.center,
        style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
      ),
    ];
  }

  List<Widget> _practice() {
    return [
      _cameraPreview(),
      const SizedBox(height: ArenaBattleSpace.s3),
      Text(
        cameraPhonePlacementGuidance,
        key: const ValueKey('solo-practice-placement'),
        style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
      ),
      Text(
        'One unscored practice rep to check your framing. It does not count.',
        style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
      ),
    ];
  }

  List<Widget> _counting(SoloSnapshot snapshot) {
    return [
      _cameraPreview(),
      const SizedBox(height: ArenaBattleSpace.s3),
      BattleTimerValue(
        seconds: snapshot.reps,
        semanticLabel: '${snapshot.reps} reps',
        large: true,
      ),
      const SizedBox(height: ArenaBattleSpace.s1),
      Text(
        '${snapshot.elapsedSeconds}s elapsed',
        textAlign: TextAlign.center,
        style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
      ),
      const SizedBox(height: ArenaBattleSpace.s4),
      BattlePrimaryButton(
        key: const ValueKey('solo-end-set'),
        label: 'End set',
        onPressed: () => unawaited(_controller.endSet()),
      ),
    ];
  }

  List<Widget> _manualEntry(SoloSnapshot snapshot) {
    return [
      Text(
        'How many ${_controller.exercise.label.toLowerCase()} did you complete?',
        style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
      ),
      const SizedBox(height: ArenaBattleSpace.s3),
      _ManualEntryField(controller: _controller),
      const SizedBox(height: ArenaBattleSpace.s4),
      BattlePrimaryButton(
        key: const ValueKey('solo-save-manual'),
        label: 'Use this count',
        onPressed: snapshot.reps > 0 ? _controller.submitManual : null,
        semanticEnabled: snapshot.reps > 0,
      ),
      const SizedBox(height: ArenaBattleSpace.s2),
      Center(
        child: BattleQuietButton(
          key: const ValueKey('solo-cancel-manual'),
          label: 'Cancel',
          onPressed: () => unawaited(_controller.restart()),
        ),
      ),
    ];
  }

  List<Widget> _result(SoloSnapshot snapshot) {
    final result = snapshot.result;
    final previousBest = snapshot.previousBestReps;
    if (result == null) {
      return const <Widget>[];
    }
    return [
      if (_controller.cameraSession != null)
        CameraTraceControls(session: _controller.cameraSession!),
      Text(
        '${result.reps}',
        textAlign: TextAlign.center,
        style: ArenaBattleText.display.copyWith(color: ArenaColors.softWhite),
      ),
      Text(
        'reps · ${result.source.label}',
        textAlign: TextAlign.center,
        style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
      ),
      if (result.durationSeconds > 0) ...[
        const SizedBox(height: ArenaBattleSpace.s1),
        Text(
          '${result.durationSeconds}s set',
          textAlign: TextAlign.center,
          style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
        ),
      ],
      const SizedBox(height: ArenaBattleSpace.s4),
      if (snapshot.message != null) ...[
        BattleBanner(
          key: const ValueKey('solo-save-error'),
          variant: BattleBannerVariant.warning,
          title: snapshot.message!,
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
      ],
      if (previousBest != null && result.reps > previousBest) ...[
        BattleBanner(
          key: const ValueKey('solo-personal-best'),
          variant: BattleBannerVariant.positive,
          title:
              'New personal best · ${result.source.label} '
              '${result.exercise.label.toLowerCase()}',
          body: previousBest == 0
              ? 'Your first recorded set with this counting source.'
              : 'Previous best: $previousBest reps',
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
      ],
      if (snapshot.saved) ...[
        const BattleBanner(
          key: ValueKey('solo-saved'),
          variant: BattleBannerVariant.info,
          title: 'Saved on this device',
          body: 'Nothing was sent anywhere.',
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        BattlePrimaryButton(
          key: const ValueKey('solo-again'),
          label: 'Start another set',
          onPressed: () => unawaited(_controller.restart()),
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Center(
          child: BattleQuietButton(
            key: const ValueKey('solo-done'),
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        _StatsCard(stats: snapshot.stats),
        const SizedBox(height: ArenaBattleSpace.s4),
        _StreakCard(streak: snapshot.streak),
        const SizedBox(height: ArenaBattleSpace.s4),
        _BadgeGrid(
          badges: soloBadges(stats: snapshot.stats, streak: snapshot.streak),
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
      ] else ...[
        BattlePrimaryButton(
          key: const ValueKey('solo-save'),
          label: snapshot.saving ? 'Saving…' : 'Save to this device',
          onPressed: snapshot.saving
              ? null
              : () async {
                  await _controller.save();
                  if (_controller.snapshot.saved) {
                    const NativeBattleFeedback().resultConfirmed();
                  }
                },
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Center(
          child: BattleQuietButton(
            key: const ValueKey('solo-discard'),
            label: 'Discard',
            onPressed: snapshot.saving
                ? null
                : () => unawaited(_controller.restart()),
          ),
        ),
      ],
    ];
  }

  Widget _cameraPreview() {
    final session = _controller.cameraSession;
    if (session == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
      child: SizedBox(height: 360, child: CameraPreview(session: session)),
    );
  }
}

class _SoloHistory extends StatelessWidget {
  const _SoloHistory({required this.results});
  final List<SoloSetResult> results;

  @override
  Widget build(BuildContext context) => BattleCard(
    key: const ValueKey('solo-history'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 7 days',
          style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
        ),
        if (results.isEmpty)
          Text(
            'Your saved sets will appear here.',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
          ),
        for (final result in results) ...[
          const SizedBox(height: ArenaBattleSpace.s3),
          Text(
            '${MaterialLocalizations.of(context).formatShortDate(result.completedAt.toLocal())}'
            ' · ${result.exercise.label}',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
          ),
          Text(
            '${result.reps} reps · ${result.source.label}',
            style: ArenaBattleText.smallStrong.copyWith(
              color: ArenaColors.softWhite,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ManualEntryField extends StatefulWidget {
  const _ManualEntryField({required this.controller});

  final SoloController controller;

  @override
  State<_ManualEntryField> createState() => _ManualEntryFieldState();
}

class _ManualEntryFieldState extends State<_ManualEntryField> {
  late final TextEditingController _field = TextEditingController(
    text: '${widget.controller.snapshot.reps}',
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _apply(int value) {
    widget.controller.setManualReps(value);
    final text = '${widget.controller.snapshot.reps}';
    _field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: ArenaBattleSpace.s2,
          runSpacing: ArenaBattleSpace.s2,
          children: [
            BattleSecondaryButton(
              key: const ValueKey('solo-minus-10'),
              label: '-10',
              onPressed: () => _apply(widget.controller.snapshot.reps - 10),
            ),
            BattleSecondaryButton(
              key: const ValueKey('solo-minus-1'),
              label: '-1',
              onPressed: () => _apply(widget.controller.snapshot.reps - 1),
            ),
            BattleSecondaryButton(
              key: const ValueKey('solo-plus-1'),
              label: '+1',
              onPressed: () => _apply(widget.controller.snapshot.reps + 1),
            ),
            BattleSecondaryButton(
              key: const ValueKey('solo-plus-10'),
              label: '+10',
              onPressed: () => _apply(widget.controller.snapshot.reps + 10),
            ),
          ],
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        SizedBox(
          width: 160,
          child: TextField(
            key: const ValueKey('solo-manual-field'),
            controller: _field,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
            decoration: const InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed != null) {
                widget.controller.setManualReps(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<SoloBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('solo-badges'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges ${unlockedBadgeCount(badges)} / ${badges.length}',
          style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
        ),
        const SizedBox(height: ArenaBattleSpace.s2),
        Wrap(
          spacing: ArenaBattleSpace.s2,
          runSpacing: ArenaBattleSpace.s2,
          children: <Widget>[
            for (final badge in badges) _BadgeChip(badge: badge),
          ],
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final SoloBadge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return Semantics(
      label:
          '${badge.title}. ${unlocked ? 'Unlocked' : 'Locked'}. '
          '${badge.description}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaBattleSpace.s3,
          vertical: ArenaBattleSpace.s2,
        ),
        decoration: BoxDecoration(
          color: unlocked ? ArenaColors.playerWash : ArenaColors.raised,
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
          border: Border.all(
            color: unlocked ? ArenaColors.lime : ArenaColors.line,
          ),
        ),
        child: Text(
          unlocked ? badge.title : '${badge.title} · locked',
          style: ArenaBattleText.small.copyWith(
            color: unlocked ? ArenaColors.lime : ArenaColors.quiet,
            fontWeight: unlocked ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final SoloStreak streak;

  @override
  Widget build(BuildContext context) {
    final goal = streak.goalReps;
    final progress = goal <= 0
        ? 0.0
        : (streak.todayReps / goal).clamp(0.0, 1.0).toDouble();
    final String headline;
    if (streak.goalMetToday) {
      headline = 'Daily goal met.';
    } else if (streak.current > 0) {
      headline = '${streak.remainingToday} reps to keep the streak alive.';
    } else {
      headline = '${streak.remainingToday} reps to start a streak.';
    }
    return Container(
      key: const ValueKey('solo-streak'),
      padding: const EdgeInsets.all(ArenaBattleSpace.s4),
      decoration: BoxDecoration(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
        border: Border.all(color: ArenaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today ${streak.todayReps} / $goal reps',
                  style: ArenaBattleText.h3.copyWith(
                    color: ArenaColors.softWhite,
                  ),
                ),
              ),
              Text(
                streak.current > 0
                    ? 'Streak: ${streak.current} days'
                    : 'No streak yet',
                style: ArenaBattleText.smallStrong.copyWith(
                  color: ArenaColors.lime,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: ArenaColors.lime,
              backgroundColor: ArenaColors.graphite,
            ),
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          Text(
            headline,
            style: ArenaBattleText.small.copyWith(color: ArenaColors.secondary),
          ),
          if (streak.longest > 0) ...[
            const SizedBox(height: ArenaBattleSpace.s1),
            Text(
              'Longest streak: ${streak.longest} days',
              style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final SoloStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('solo-stats'),
      padding: const EdgeInsets.all(ArenaBattleSpace.s4),
      decoration: BoxDecoration(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
        border: Border.all(color: ArenaColors.line),
      ),
      child: Row(
        children: [
          _Stat(label: 'Total reps', value: '${stats.totalReps}'),
          _Stat(label: 'Last set', value: '${stats.last?.reps ?? 0}'),
          _Stat(label: 'Sessions', value: '${stats.sessions}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
          ),
        ],
      ),
    );
  }
}
