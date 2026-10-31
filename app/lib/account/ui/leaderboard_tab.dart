/// Leaderboard tab body (left bottom tab).
///
/// Rows are the server-confirmed ranked ladder with username, avatar and
/// rating. The viewer's own row is lime and is shown below the top page when
/// the server appends it; a separator explains that it is outside the top
/// page. A failed load keeps the last confirmed page and retries.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../runtime/account_runtime.dart';
import '../runtime/leaderboard_controller.dart';
import 'account_widgets.dart';
import 'player_card_sheet.dart';

/// Leaderboard tab.
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) {
      return;
    }
    _requested = true;
    final runtime = AccountRuntimeScope.maybeOf(context);
    if (runtime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          runtime.leaderboard.load();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = AccountRuntimeScope.maybeOf(context);
    if (runtime == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s4,
          ArenaBattleSpace.s6,
        ),
        children: [
          Text(
            'Leaderboard',
            style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          const AccountEmptyPanel(
            title: 'Leaderboard is unavailable',
            body: 'This build has no account runtime wired.',
          ),
        ],
      );
    }
    final controller = runtime.leaderboard;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => RefreshIndicator(
        color: ArenaColors.lime,
        backgroundColor: ArenaColors.graphite,
        onRefresh: () => controller.load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            ArenaBattleSpace.s4,
            ArenaBattleSpace.s4,
            ArenaBattleSpace.s4,
            ArenaBattleSpace.s6,
          ),
          children: [
            Text(
              'Leaderboard',
              style: ArenaBattleText.h1.copyWith(color: ArenaColors.softWhite),
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            Text(
              'Ranked players. Only server-confirmed ranked results change '
              'rating; friend challenges are casual.',
              style: ArenaBattleText.small.copyWith(
                color: ArenaColors.secondary,
              ),
            ),
            const SizedBox(height: ArenaBattleSpace.s4),
            ..._buildBody(context, runtime, controller),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    AccountRuntime runtime,
    LeaderboardController controller,
  ) {
    switch (controller.status) {
      case AccountLoadStatus.initial:
      case AccountLoadStatus.loading:
        return const <Widget>[AccountLoadingRows()];
      case AccountLoadStatus.empty:
        return <Widget>[
          const AccountEmptyPanel(
            title: 'No ranked players yet',
            body: 'Participation appears after the first completed ranked '
                'match. Nothing here is a guess.',
          ),
        ];
      case AccountLoadStatus.unconfigured:
        return <Widget>[
          AccountProblemPanel(
            title: 'Arena service not configured',
            body: controller.message ??
                'The leaderboard needs backend credentials.',
            variant: BattleBannerVariant.warning,
            onRetry: () => controller.load(force: true),
          ),
        ];
      case AccountLoadStatus.offline:
        return <Widget>[
          AccountProblemPanel(
            title: 'You are offline',
            body: controller.message ??
                'The leaderboard cannot be reached right now. The last '
                    'confirmed page is still shown below.',
            onRetry: () => controller.load(force: true),
          ),
          if (controller.entries.isNotEmpty) ...[
            const SizedBox(height: ArenaBattleSpace.s3),
            ..._rows(context, runtime, controller),
          ],
        ];
      case AccountLoadStatus.error:
        return <Widget>[
          AccountProblemPanel(
            title: 'Could not load the leaderboard',
            body: controller.message ?? 'The server answered unexpectedly.',
            onRetry: () => controller.load(force: true),
          ),
          if (controller.entries.isNotEmpty) ...[
            const SizedBox(height: ArenaBattleSpace.s3),
            ..._rows(context, runtime, controller),
          ],
        ];
      case AccountLoadStatus.ready:
        return _rows(context, runtime, controller);
    }
  }

  List<Widget> _rows(
    BuildContext context,
    AccountRuntime runtime,
    LeaderboardController controller,
  ) {
    final viewerId = controller.viewerId;
    final rows = <Widget>[];
    var viewerSeparatorAdded = false;
    for (var index = 0; index < controller.entries.length; index++) {
      final entry = controller.entries[index];
      final isViewer = entry.isViewer(viewerId);
      if (isViewer && controller.viewerOutsideTopPage && !viewerSeparatorAdded) {
        viewerSeparatorAdded = true;
        rows.add(const _YourPositionDivider());
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: ArenaBattleSpace.s2),
          child: LeaderboardRow(
            key: ValueKey('leaderboard-row-${entry.profile.id}'),
            entry: entry,
            isViewer: isViewer,
            onTap: isViewer
                ? null
                : () {
                    showPlayerCardSheet(
                      context,
                      runtime: runtime,
                      userId: entry.profile.id,
                      rank: entry.rank,
                    );
                  },
          ),
        ),
      );
    }
    return rows;
  }
}

class _YourPositionDivider extends StatelessWidget {
  const _YourPositionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('leaderboard-your-position'),
      padding: const EdgeInsets.symmetric(vertical: ArenaBattleSpace.s2),
      child: Row(
        children: [
          Text(
            'Your position',
            style: ArenaBattleText.micro.copyWith(color: ArenaColors.lime),
          ),
          const SizedBox(width: ArenaBattleSpace.s2),
          Expanded(
            child: Container(height: 1, color: ArenaColors.line),
          ),
        ],
      ),
    );
  }
}
