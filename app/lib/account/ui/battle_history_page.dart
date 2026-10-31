/// Battle history page.
///
/// Shows confirmed receipts only: exercise, the fixed 60-second round format,
/// scores, outcome, mode and a rating change only when the receipt carries one
/// (ranked results). Empty, loading, offline and deleted-account snapshots are
/// handled with plain copy.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../runtime/account_runtime.dart';
import '../runtime/leaderboard_controller.dart' show AccountLoadStatus;
import 'account_widgets.dart';
import 'player_card_sheet.dart';

/// Full confirmed battle history.
class BattleHistoryPage extends StatefulWidget {
  const BattleHistoryPage({super.key, required this.runtime});

  final AccountRuntime runtime;

  @override
  State<BattleHistoryPage> createState() => _BattleHistoryPageState();
}

class _BattleHistoryPageState extends State<BattleHistoryPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) {
      return;
    }
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.runtime.history.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.runtime.history;
    final viewerId = widget.runtime.controller.profile?.id;
    return Scaffold(
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => RefreshIndicator(
            color: ArenaColors.lime,
            backgroundColor: ArenaColors.graphite,
            onRefresh: () => controller.load(force: true),
            child: ListView(
              key: const ValueKey('battle-history-page'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                ArenaBattleSpace.s4,
                ArenaBattleSpace.s2,
                ArenaBattleSpace.s4,
                ArenaBattleSpace.s6,
              ),
              children: [
                const AccountPageHeader(
                  title: 'Battle history',
                  backLabel: 'Back to Profile',
                ),
                const SizedBox(height: ArenaBattleSpace.s3),
                ..._buildBody(context, viewerId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, String? viewerId) {
    final controller = widget.runtime.history;
    switch (controller.status) {
      case AccountLoadStatus.initial:
      case AccountLoadStatus.loading:
        return const <Widget>[AccountLoadingRows()];
      case AccountLoadStatus.empty:
        return const <Widget>[
          AccountEmptyPanel(
            key: ValueKey('history-empty'),
            title: 'No battles yet',
            body: 'Confirmed results appear here after your first match. '
                'Casual and ranked receipts both count; only ranked results '
                'change rating.',
          ),
        ];
      case AccountLoadStatus.unconfigured:
        return <Widget>[
          AccountProblemPanel(
            key: const ValueKey('history-unconfigured'),
            title: 'Arena service not configured',
            body: controller.message ??
                'Battle history needs backend credentials.',
            variant: BattleBannerVariant.warning,
            onRetry: () => controller.load(force: true),
          ),
        ];
      case AccountLoadStatus.offline:
      case AccountLoadStatus.error:
        return <Widget>[
          AccountProblemPanel(
            key: const ValueKey('history-problem'),
            title: AccountLoadStatus.offline == controller.status
                ? 'You are offline'
                : 'Could not load battle history',
            body: controller.message ??
                'Nothing was dropped; retry when the connection is back.',
            onRetry: () => controller.load(force: true),
          ),
        ];
      case AccountLoadStatus.ready:
        return <Widget>[
          for (final receipt in controller.receipts) ...[
            ReceiptHistoryCard(
              key: ValueKey('history-receipt-${receipt.id}'),
              receipt: receipt,
              viewerId: viewerId,
              onOpponentTap: (opponent) {
                showPlayerCardSheet(
                  context,
                  runtime: widget.runtime,
                  userId: opponent.id,
                  matchId: receipt.matchId,
                );
              },
            ),
            const SizedBox(height: ArenaBattleSpace.s3),
          ],
          Text(
            'Receipts are immutable snapshots confirmed by the server.',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
          ),
        ];
    }
  }
}
