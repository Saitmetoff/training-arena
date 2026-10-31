/// Public player card and its report/block actions.
///
/// The card shows only the safe public identity the `profile_public` action
/// returns: username, avatar, rating, ranked wins and ranked battles (plus a
/// ladder rank when the caller knows it). Email, tokens and camera data are
/// never requested, stored or rendered. Report reasons are 3–500 characters;
/// a block hides future requests and queue opponents server-side.
library;

import 'package:flutter/material.dart';

import '../../theme/arena_tokens.dart';
import '../../battle/ui/battle_style.dart';
import '../../battle/ui/battle_widgets.dart';
import '../models/account_models.dart';
import '../runtime/account_runtime.dart';
import 'account_widgets.dart';

/// Opens the public player card for [userId].
Future<void> showPlayerCardSheet(
  BuildContext context, {
  required AccountRuntime runtime,
  required String userId,
  int? rank,
  String? matchId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ArenaColors.graphite,
    builder: (_) => _PlayerCardSheet(
      runtime: runtime,
      userId: userId,
      rank: rank,
      matchId: matchId,
    ),
  );
}

enum _CardStatus { loading, ready, deleted, error }

class _PlayerCardSheet extends StatefulWidget {
  const _PlayerCardSheet({
    required this.runtime,
    required this.userId,
    this.rank,
    this.matchId,
  });

  final AccountRuntime runtime;
  final String userId;
  final int? rank;
  final String? matchId;

  @override
  State<_PlayerCardSheet> createState() => _PlayerCardSheetState();
}

class _PlayerCardSheetState extends State<_PlayerCardSheet> {
  _CardStatus _status = _CardStatus.loading;
  ArenaPublicPlayer? _player;
  String _message = '';
  String? _actionMessage;
  bool _busy = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _CardStatus.loading;
    });
    try {
      final profile = await widget.runtime.api.publicProfile(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _player = ArenaPublicPlayer(profile: profile, rank: widget.rank);
        _status = _CardStatus.ready;
      });
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (error.code == 'not_found') {
          _status = _CardStatus.deleted;
        } else {
          _status = _CardStatus.error;
          _message = error.message;
        }
      });
    }
  }

  Future<void> _report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _ReportDialog(),
    );
    if (reason == null || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _actionMessage = null;
    });
    try {
      await widget.runtime.api.report(
        targetUserId: widget.userId,
        matchId: widget.matchId,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      setState(() => _actionMessage = 'Report sent.');
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _actionMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArenaColors.graphite,
        title: Text(
          'Block this player?',
          style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
        ),
        content: Text(
          'Their requests are hidden and you cannot meet in ranked queue. '
          'You can unblock in Settings.',
          style: ArenaBattleText.body.copyWith(color: ArenaColors.secondary),
        ),
        actions: [
          TextButton(
            key: const ValueKey('player-block-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('player-block-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Block',
              style: TextStyle(color: ArenaColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _actionMessage = null;
    });
    try {
      await widget.runtime.api.block(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _blocked = true;
        _actionMessage = 'Blocked. Their challenges and queue matches are hidden.';
      });
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _actionMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _unblock() async {
    setState(() {
      _busy = true;
      _actionMessage = null;
    });
    try {
      await widget.runtime.api.unblock(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _blocked = false;
        _actionMessage = 'Unblocked.';
      });
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _actionMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ArenaBattleSpace.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Player',
            style: ArenaBattleText.micro.copyWith(color: ArenaColors.violet),
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
          switch (_status) {
            _CardStatus.loading => const AccountLoadingRows(count: 1),
            _CardStatus.deleted => const AccountEmptyPanel(
                key: ValueKey('player-card-deleted'),
                title: 'Player unavailable',
                body: 'This player is no longer available.',
              ),
            _CardStatus.error => AccountProblemPanel(
                key: const ValueKey('player-card-error'),
                title: 'Could not load this player',
                body: _message,
                onRetry: _load,
              ),
            _CardStatus.ready => _readyBody(),
          },
        ],
      ),
    );
  }

  Widget _readyBody() {
    final player = _player!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BattleIdentity(
          key: const ValueKey('player-card-identity'),
          profile: player.profile,
          role: player.rank == null ? 'player' : 'ranked #${player.rank}',
          accent: true,
          large: true,
        ),
        const SizedBox(height: ArenaBattleSpace.s3),
        Wrap(
          spacing: ArenaBattleSpace.s2,
          runSpacing: ArenaBattleSpace.s2,
          children: [
            BattleChip(
              label: 'Arena rating ${player.profile.rating}',
              variant: BattleChipVariant.opponent,
            ),
            BattleChip(label: 'Ranked wins ${player.profile.rankedWins}'),
            BattleChip(label: 'Ranked battles ${player.profile.rankedBattles}'),
          ],
        ),
        const SizedBox(height: ArenaBattleSpace.s4),
        if (_actionMessage != null) ...[
          BattleBanner(
            key: const ValueKey('player-card-action-result'),
            variant: BattleBannerVariant.info,
            title: _actionMessage!,
          ),
          const SizedBox(height: ArenaBattleSpace.s3),
        ],
        if (_blocked)
          BattleSecondaryButton(
            key: const ValueKey('player-card-unblock'),
            label: 'Unblock',
            block: true,
            onPressed: _busy ? null : _unblock,
          )
        else ...[
          BattleSecondaryButton(
            key: const ValueKey('player-card-report'),
            label: 'Report',
            block: true,
            onPressed: _busy ? null : _report,
          ),
          const SizedBox(height: ArenaBattleSpace.s2),
          BattleDangerButton(
            key: const ValueKey('player-card-block'),
            label: 'Block',
            block: true,
            onPressed: _busy ? null : _block,
          ),
        ],
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < 3) {
      setState(() => _error = 'Describe the problem in a few words.');
      return;
    }
    if (reason.length > 500) {
      setState(() => _error = 'Keep the report under 500 characters.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArenaColors.graphite,
      title: Text(
        'Report this player',
        style: ArenaBattleText.h2.copyWith(color: ArenaColors.softWhite),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('report-reason-field'),
            controller: _controller,
            maxLines: 3,
            maxLength: 500,
            autofocus: true,
            style: ArenaBattleText.body.copyWith(color: ArenaColors.softWhite),
            decoration: InputDecoration(
              hintText: 'What happened?',
              hintStyle:
                  ArenaBattleText.body.copyWith(color: ArenaColors.quiet),
              filled: true,
              fillColor: ArenaColors.raised,
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ArenaBattleSpace.radiusControl),
                borderSide: const BorderSide(color: ArenaColors.lineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ArenaBattleSpace.radiusControl),
                borderSide: const BorderSide(color: ArenaColors.lime, width: 2),
              ),
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              key: const ValueKey('report-error'),
              style: ArenaBattleText.small.copyWith(color: ArenaColors.danger),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('report-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('report-send'),
          onPressed: _submit,
          child: const Text('Send report'),
        ),
      ],
    );
  }
}
