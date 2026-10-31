/// Shared account widgets: page header, loading skeleton, empty and problem
/// panels, the leaderboard row and the confirmed-receipt row.
///
/// Colors and type come from the design tokens and the battle style helpers;
/// this file defines no second palette.
library;

import 'package:flutter/material.dart';

import '../../domain/arena_types.dart';
import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../models/account_models.dart';

/// Back arrow + screen title, matching the battle pages.
class AccountPageHeader extends StatelessWidget {
  const AccountPageHeader({
    super.key,
    required this.title,
    this.backLabel = 'Back',
    this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: ValueKey('account-back-${title.toLowerCase()}'),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          color: ArenaColors.softWhite,
          tooltip: backLabel,
        ),
        Flexible(
          child: Text(
            title,
            style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
          ),
        ),
      ],
    );
  }
}

/// Skeleton rows for the account lists.
class AccountLoadingRows extends StatelessWidget {
  const AccountLoadingRows({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('account-loading'),
      children: [
        for (var i = 0; i < count; i++) ...[
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: ArenaColors.raised,
              borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
              border: Border.all(color: ArenaColors.line),
            ),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
        ],
      ],
    );
  }
}

/// Honest empty state with a title and one explanatory sentence.
class AccountEmptyPanel extends StatelessWidget {
  const AccountEmptyPanel({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return BattleBanner(
      key: const ValueKey('account-empty'),
      variant: BattleBannerVariant.info,
      title: title,
      body: body,
      actions: action == null ? const <Widget>[] : <Widget>[action!],
    );
  }
}

/// Offline/error state with a retry action.
class AccountProblemPanel extends StatelessWidget {
  const AccountProblemPanel({
    super.key,
    required this.title,
    required this.body,
    required this.onRetry,
    this.variant = BattleBannerVariant.danger,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;
  final BattleBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    return BattleBanner(
      key: const ValueKey('account-problem'),
      variant: variant,
      title: title,
      body: body,
      actions: <Widget>[
        BattleSecondaryButton(
          key: const ValueKey('account-retry'),
          label: 'Retry',
          onPressed: onRetry,
        ),
      ],
    );
  }
}

/// One leaderboard row. The current player is lime; every other identity is
/// violet, exactly like the two-identity rule elsewhere.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.isViewer,
    this.onTap,
  });

  final ArenaLeaderboardEntry entry;
  final bool isViewer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: isViewer
          ? 'Your ranked position ${entry.rank}, '
              '@${entry.profile.username}, rating ${entry.profile.rating}'
          : 'Ranked position ${entry.rank}, '
              '@${entry.profile.username}, rating ${entry.profile.rating}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: ArenaBattleSpace.minTarget),
            padding: const EdgeInsets.all(ArenaBattleSpace.s3),
            decoration: BoxDecoration(
              color: isViewer ? ArenaColors.playerWash : ArenaColors.graphite,
              borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
              border: Border.all(
                color: isViewer ? ArenaColors.lime : ArenaColors.line,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: ArenaBattleText.h3.copyWith(
                      color: isViewer
                          ? ArenaColors.lime
                          : ArenaColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: ArenaBattleSpace.s2),
                Expanded(
                  child: BattleIdentity(
                    profile: entry.profile,
                    role: isViewer ? 'you · ranked' : 'ranked',
                    accent: !isViewer,
                  ),
                ),
                const SizedBox(width: ArenaBattleSpace.s2),
                Text(
                  '${entry.profile.rating}',
                  style: ArenaBattleText.h3.copyWith(
                    color: ArenaColors.softWhite,
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

/// One confirmed receipt as a factual history row.
class ReceiptHistoryCard extends StatelessWidget {
  const ReceiptHistoryCard({
    super.key,
    required this.receipt,
    required this.viewerId,
    this.onOpponentTap,
  });

  final ResultReceipt receipt;
  final String? viewerId;

  /// Opens the public player card for the opponent, when they are known.
  final void Function(ArenaProfile opponent)? onOpponentTap;

  ArenaReceiptPlayer? get _viewerPlayer {
    for (final player in receipt.players) {
      if (player.profile.id == viewerId) {
        return player;
      }
    }
    return null;
  }

  ArenaReceiptPlayer? get _opponentPlayer {
    for (final player in receipt.players) {
      if (player.profile.id != viewerId) {
        return player;
      }
    }
    return null;
  }

  String get _headline {
    final viewer = _viewerPlayer;
    final opponent = _opponentPlayer;
    final viewerName = viewer?.profile.username;
    final opponentName = opponent?.profile.username;
    switch (receipt.outcome) {
      case ArenaMatchOutcome.win:
        return receipt.outcomeFor(viewerId ?? '')
            ? 'You beat @$opponentName'
            : '@$viewerName beat you';
      case ArenaMatchOutcome.draw:
        return 'Draw — ${viewer?.score ?? 0} each';
      case ArenaMatchOutcome.noResult:
        return 'No result';
    }
  }

  String? get _ratingChangeLabel {
    if (receipt.mode != ArenaMatchMode.ranked) {
      return null;
    }
    final viewer = _viewerPlayer;
    final change = viewer?.ratingChange;
    final after = viewer?.ratingAfter;
    if (change == null) {
      return null;
    }
    final signed = change > 0 ? '+$change' : '$change';
    if (after == null) {
      return 'Rating $signed';
    }
    return 'Rating $signed · now $after';
  }

  @override
  Widget build(BuildContext context) {
    final viewer = _viewerPlayer;
    final opponent = _opponentPlayer;
    final change = _ratingChangeLabel;
    return BattleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: ArenaBattleSpace.s2,
            runSpacing: ArenaBattleSpace.s2,
            children: [
              BattleChip(
                label: receipt.mode == ArenaMatchMode.ranked
                    ? 'Ranked'
                    : 'Casual',
                variant: receipt.mode == ArenaMatchMode.ranked
                    ? BattleChipVariant.player
                    : BattleChipVariant.neutral,
              ),
              BattleChip(label: receipt.exercise.label),
              BattleChip(
                label: receipt.outcome == ArenaMatchOutcome.noResult
                    ? 'No result'
                    : receipt.outcome == ArenaMatchOutcome.draw
                        ? 'Draw'
                        : receipt.outcomeFor(viewerId ?? '')
                            ? 'Win'
                            : 'Loss',
                variant: receipt.outcome == ArenaMatchOutcome.draw
                    ? BattleChipVariant.warning
                    : receipt.outcome == ArenaMatchOutcome.noResult
                        ? BattleChipVariant.neutral
                        : receipt.outcomeFor(viewerId ?? '')
                            ? BattleChipVariant.positive
                            : BattleChipVariant.danger,
              ),
            ],
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          Text(
            _headline,
            style: ArenaBattleText.h3.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s1),
          Text(
            viewer == null || opponent == null
                ? 'Confirmed result'
                : 'You ${viewer.score} — ${opponent.score} @${opponent.profile.username}',
            style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          Text(
            '$arenaRoundSeconds s round · ${_formatFinished(receipt.finishedAt)}',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
          ),
          if (receipt.reason != null && receipt.reason!.isNotEmpty) ...[
            const SizedBox(height: ArenaBattleSpace.s1),
            Text(
              receipt.reason!,
              style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              change,
              style: ArenaBattleText.smallStrong.copyWith(
                color: ArenaColors.lime,
              ),
            ),
          ],
          if (opponent != null && onOpponentTap != null) ...[
            const SizedBox(height: ArenaBattleSpace.s3),
            BattleQuietButton(
              key: const ValueKey('history-opponent'),
              label: 'View @${opponent.profile.username ?? 'player'}',
              onPressed: () => onOpponentTap!(opponent.profile),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatFinished(DateTime? finishedAt) {
    if (finishedAt == null) {
      return 'confirmed';
    }
    final local = finishedAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
