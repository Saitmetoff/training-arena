/// Reusable battle components following `design/arena/COMPONENT_INVENTORY.md`.
library;

import 'package:flutter/material.dart';

import '../../domain/arena_types.dart';
import '../../theme/arena_tokens.dart';
import 'battle_style.dart';

/// Chip variants from the component inventory. Text always carries the state,
/// so color is never the only signal.
enum BattleChipVariant { neutral, positive, warning, danger, player, opponent }

/// Status chip: dot + word.
class BattleChip extends StatelessWidget {
  const BattleChip({
    super.key,
    required this.label,
    this.variant = BattleChipVariant.neutral,
  });

  final String label;
  final BattleChipVariant variant;

  Color get _color => switch (variant) {
        BattleChipVariant.neutral => ArenaColors.secondary,
        BattleChipVariant.positive => ArenaColors.positive,
        BattleChipVariant.warning => ArenaColors.warning,
        BattleChipVariant.danger => ArenaColors.danger,
        BattleChipVariant.player => ArenaColors.lime,
        BattleChipVariant.opponent => ArenaColors.violet,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaBattleSpace.s3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ArenaColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: ArenaBattleSpace.s2),
          // Flexible so long labels wrap inside the pill instead of
          // overflowing at large text sizes.
          Flexible(
            child: Text(
              label,
              style: ArenaBattleText.smallStrong.copyWith(
                color: ArenaColors.softWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner variants; replaces, never stacks.
enum BattleBannerVariant { info, positive, warning, danger }

/// Icon + title + body + optional actions.
class BattleBanner extends StatelessWidget {
  const BattleBanner({
    super.key,
    required this.title,
    this.body,
    this.variant = BattleBannerVariant.info,
    this.actions = const <Widget>[],
    this.icon,
  });

  final String title;
  final String? body;
  final BattleBannerVariant variant;
  final List<Widget> actions;
  final IconData? icon;

  Color get _color => switch (variant) {
        BattleBannerVariant.info => ArenaColors.secondary,
        BattleBannerVariant.positive => ArenaColors.positive,
        BattleBannerVariant.warning => ArenaColors.warning,
        BattleBannerVariant.danger => ArenaColors.danger,
      };

  IconData get _icon => icon ??
      switch (variant) {
        BattleBannerVariant.info => Icons.info_outline,
        BattleBannerVariant.positive => Icons.check_circle_outline,
        BattleBannerVariant.warning => Icons.warning_amber_outlined,
        BattleBannerVariant.danger => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArenaBattleSpace.cardPadding,
      decoration: BoxDecoration(
        color: ArenaColors.graphite,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
        border: Border.all(color: ArenaColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _color, size: 22, semanticLabel: null),
          const SizedBox(width: ArenaBattleSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArenaBattleText.h3.copyWith(
                    color: ArenaColors.softWhite,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: ArenaBattleSpace.s1),
                  Text(
                    body!,
                    style: ArenaBattleText.small.copyWith(
                      color: ArenaColors.secondary,
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: ArenaBattleSpace.s3),
                  Wrap(
                    spacing: ArenaBattleSpace.s2,
                    runSpacing: ArenaBattleSpace.s2,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Player identity row: avatar (photo or monogram) + `@username` + role.
class BattleIdentity extends StatelessWidget {
  const BattleIdentity({
    super.key,
    required this.profile,
    this.role,
    this.accent = false,
    this.large = false,
    this.nameOverride,
  });

  final ArenaProfile profile;
  final String? role;

  /// True for the opponent (violet); false for the signed-in player (lime).
  final bool accent;
  final bool large;
  final String? nameOverride;

  String get _initials {
    final name = profile.username ?? profile.displayName;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '??';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }
    final value = parts.first;
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return value.substring(0, 2).toUpperCase();
  }

  Color get _identityColor =>
      accent ? ArenaColors.violet : ArenaColors.lime;

  Color get _wash =>
      accent ? ArenaColors.opponentWash : ArenaColors.playerWash;

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 44.0;
    final name = nameOverride ?? '@${profile.username ?? profile.displayName}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _wash,
            shape: BoxShape.circle,
            border: Border.all(color: _identityColor, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _avatar(),
        ),
        const SizedBox(width: ArenaBattleSpace.s3),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: (large ? ArenaBattleText.h3 : ArenaBattleText.body)
                    .copyWith(color: ArenaColors.softWhite),
                overflow: TextOverflow.ellipsis,
              ),
              if (role != null)
                Text(
                  role!,
                  style: ArenaBattleText.small.copyWith(
                    color: _identityColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar() {
    final url = profile.avatarUrl;
    if (url == null || url.isEmpty) {
      return Center(
        child: Text(
          _initials,
          style: ArenaBattleText.h3.copyWith(color: _identityColor),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          _initials,
          style: ArenaBattleText.h3.copyWith(color: _identityColor),
        ),
      ),
    );
  }
}

/// Raised card shell.
class BattleCard extends StatelessWidget {
  const BattleCard({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ArenaBattleSpace.cardPadding,
      decoration: BoxDecoration(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
        border: Border.all(color: accent ?? ArenaColors.line),
      ),
      child: child,
    );
  }
}

/// Score panel: identity, big server-confirmed value, unit and state line.
class BattleScorePanel extends StatelessWidget {
  const BattleScorePanel({
    super.key,
    required this.profile,
    required this.score,
    required this.stateLine,
    required this.ownerLabel,
    this.accent = false,
  });

  /// Player whose score is displayed.
  final ArenaProfile profile;

  /// Server-confirmed reps only.
  final int score;
  final String stateLine;

  /// Full accessible owner label, e.g. `Your` or `@zuhra's`.
  final String ownerLabel;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final panelColor =
        accent ? ArenaColors.opponentWash : ArenaColors.playerWash;
    final borderColor = (accent ? ArenaColors.violet : ArenaColors.lime)
        .withValues(alpha: 0.45);
    final valueColor =
        accent ? ArenaColors.violet : ArenaColors.lime;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(ArenaBattleSpace.s4),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BattleIdentity(
              profile: profile,
              role: accent ? 'opponent' : 'you · player',
              accent: accent,
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
            Semantics(
              container: true,
              label: '$ownerLabel score: $score reps',
              child: ExcludeSemantics(
                child: Text(
                  '$score',
                  style: ArenaBattleText.score.copyWith(color: valueColor),
                ),
              ),
            ),
            Text(
              'reps',
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.quiet,
              ),
            ),
            const SizedBox(height: ArenaBattleSpace.s1),
            Text(
              stateLine,
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary lime block action.
class BattlePrimaryButton extends StatelessWidget {
  const BattlePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.large = false,
    this.block = true,
    this.semanticEnabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool large;
  final bool block;
  final bool semanticEnabled;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      enabled: semanticEnabled,
      label: label,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ArenaColors.lime,
          foregroundColor: ArenaColors.playerInk,
          minimumSize: Size(
            block ? double.infinity : ArenaBattleSpace.minTarget,
            large ? 72 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: ArenaBattleSpace.s5),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ArenaBattleSpace.radiusControl),
          ),
          textStyle: ArenaBattleText.body.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
    return button;
  }
}

/// Secondary raised action.
class BattleSecondaryButton extends StatelessWidget {
  const BattleSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.block = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool block;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: ArenaColors.raised,
        foregroundColor: ArenaColors.softWhite,
        minimumSize: Size(
          block ? double.infinity : ArenaBattleSpace.minTarget,
          48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: ArenaBattleSpace.s5),
        side: const BorderSide(color: ArenaColors.lineStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
        ),
        textStyle: ArenaBattleText.body.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Quiet underlined text fallback.
class BattleQuietButton extends StatelessWidget {
  const BattleQuietButton({
    super.key,
    required this.label,
    this.onPressed,
    this.block = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool block;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ArenaColors.secondary,
        minimumSize: Size(
          block ? double.infinity : ArenaBattleSpace.minTarget,
          48,
        ),
        textStyle: ArenaBattleText.body.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: ArenaColors.secondary,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Destructive bordered action; always paired with a confirmation dialog.
class BattleDangerButton extends StatelessWidget {
  const BattleDangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.block = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool block;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ArenaColors.danger,
        minimumSize: Size(
          block ? double.infinity : ArenaBattleSpace.minTarget,
          48,
        ),
        side: const BorderSide(color: ArenaColors.danger),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
        ),
        textStyle: ArenaBattleText.body.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// The single dominant action on Battle: 104px lime block.
class BattleHeroAction extends StatelessWidget {
  const BattleHeroAction({
    super.key,
    required this.title,
    required this.helper,
    this.onPressed,
  });

  final String title;
  final String helper;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $helper',
      child: Material(
        color: ArenaColors.lime,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(ArenaBattleSpace.s5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: ArenaBattleText.h2.copyWith(
                          color: ArenaColors.playerInk,
                        ),
                      ),
                      const SizedBox(height: ArenaBattleSpace.s1),
                      Text(
                        helper,
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.playerInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: ArenaColors.playerInk,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary 76px raised action with an opponent-tinted mark.
class BattleSecondaryAction extends StatelessWidget {
  const BattleSecondaryAction({
    super.key,
    required this.title,
    required this.helper,
    this.onPressed,
    this.icon = Icons.accessibility_new,
  });

  final String title;
  final String helper;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $helper',
      child: Material(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(ArenaBattleSpace.s4),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(ArenaBattleSpace.radiusControl),
              border: Border.all(color: ArenaColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ArenaColors.opponentWash,
                    borderRadius:
                        BorderRadius.circular(ArenaBattleSpace.radiusSmall),
                  ),
                  child: Icon(icon, color: ArenaColors.violet),
                ),
                const SizedBox(width: ArenaBattleSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: ArenaBattleText.h3.copyWith(
                          color: ArenaColors.softWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        helper,
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent label for preview fixture mode.
class BattlePreviewBanner extends StatelessWidget {
  const BattlePreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const BattleBanner(
      key: ValueKey('battle-preview-banner'),
      variant: BattleBannerVariant.warning,
      title: 'Preview fixtures',
      body: 'Simulated data for design review. Fixtures never produce ranked '
          'or casual receipts, scores or ratings.',
    );
  }
}

/// Section kicker.
class BattleKicker extends StatelessWidget {
  const BattleKicker(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
    );
  }
}

/// Big numeric timer/countdown value with an accessible label.
class BattleTimerValue extends StatelessWidget {
  const BattleTimerValue({
    super.key,
    required this.seconds,
    required this.semanticLabel,
    this.dangerAt10 = false,
    this.large = false,
  });

  final int seconds;
  final String semanticLabel;
  final bool dangerAt10;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = dangerAt10 && seconds <= 10
        ? ArenaColors.danger
        : ArenaColors.softWhite;
    return Semantics(
      liveRegion: false,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Text(
          '$seconds',
          textAlign: TextAlign.center,
          style: (large ? ArenaBattleText.display : ArenaBattleText.score)
              .copyWith(color: color),
        ),
      ),
    );
  }
}
