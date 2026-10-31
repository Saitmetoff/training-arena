/// "Challenge a friend" share flow.
///
/// Tapping the action opens the platform share sheet immediately with the
/// confirmed message, then shows the durable-link waiting state. Leaving the
/// waiting state never cancels the link.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/arena_tokens.dart';
import 'arena_linking.dart';
import 'challenge_install_view.dart';
import 'challenge_link.dart';
import 'challenge_models.dart';
import 'challenge_share.dart';

/// Large lime "Challenge a friend" action for the Battle tab (task `07`
/// embeds this widget). The durable link is prefetched so the share sheet
/// opens without a visible delay.
class ChallengeFriendButton extends StatefulWidget {
  const ChallengeFriendButton({super.key, this.source = 'battle'});

  /// Analytics source label (`battle` or `result`, task `09`).
  final String source;

  @override
  State<ChallengeFriendButton> createState() => _ChallengeFriendButtonState();
}

class _ChallengeFriendButtonState extends State<ChallengeFriendButton> {
  ChallengeShareService? _service;
  ChallengeAccountSnapshot? _snapshot;
  String? _errorMessage;
  bool _busy = false;
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final linking = ArenaLinkingScope.of(context);
    if (identical(_service, linking.shareService)) {
      return;
    }
    _service = linking.shareService;
    if (!_requestedLoad) {
      _requestedLoad = true;
      unawaited(_loadSnapshot());
    }
  }

  Future<void> _loadSnapshot() async {
    try {
      final snapshot = await _service!.loadSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _errorMessage = null;
      });
    } on ChallengeShareException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _share() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final result = await _service!.shareChallenge(
        snapshot: _snapshot,
        source: widget.source,
      );
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeShareWaitingPage(
            result: result,
            service: _service!,
            source: widget.source,
          ),
        ),
      );
    } on ChallengeShareException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('challenge-friend-action'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChallengePrimaryButton(
          key: const ValueKey('challenge-friend-button'),
          label: 'Challenge a friend',
          busy: _busy,
          onPressed: _share,
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ChallengeInfoBanner(
              variant: ChallengeBannerVariant.danger,
              title: 'Challenge a friend is unavailable',
              body: _errorMessage,
            ),
          ),
        const ChallengeFootnote(
          'Opens the system share sheet with your durable challenge link. '
          'Sharing is not a referral; a recipient profile is created only '
          'when someone accepts.',
        ),
      ],
    );
  }
}

/// Waiting/request state for the link owner.
class ChallengeShareWaitingPage extends StatefulWidget {
  const ChallengeShareWaitingPage({
    super.key,
    required this.result,
    required this.service,
    this.source = 'battle',
    this.linkOnly = false,
  });

  final ChallengeShareResult result;
  final ChallengeShareService service;
  final String source;
  final bool linkOnly;

  @override
  State<ChallengeShareWaitingPage> createState() =>
      _ChallengeShareWaitingPageState();
}

class _ChallengeShareWaitingPageState extends State<ChallengeShareWaitingPage> {
  bool _sharing = false;

  Future<void> _shareAgain() async {
    setState(() => _sharing = true);
    try {
      await widget.service.shareChallenge(
        snapshot: widget.result.snapshot,
        source: widget.source,
      );
      if (!mounted) {
        return;
      }
      setState(() => _sharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ArenaColors.raised,
          content: Text(
            'Challenge link shared again.',
            style: TextStyle(color: ArenaColors.softWhite),
          ),
        ),
      );
    } on ChallengeShareException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _sharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ArenaColors.raised,
          content: Text(
            error.message,
            style: const TextStyle(color: ArenaColors.softWhite),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-share-waiting-view'),
      kicker: 'Live challenge',
      onClose: () => Navigator.of(context).maybePop(),
      content: [
        ChallengeEntryTitle(
          widget.linkOnly ? 'My challenge link' : 'Your link is live',
        ),
        ChallengeChallengerIdentity(
          sender: result.profile,
          role: 'you · challenger',
        ),
        const ChallengeInfoBanner(
          variant: ChallengeBannerVariant.positive,
          title: 'Leave without cancelling',
          body: 'Anyone who opens the link can send you a live challenge. The '
              'link stays valid until you revoke it or delete your account, '
              'and a username change never breaks it.',
        ),
        ChallengeSectionCard(
          title: 'Message preview',
          body: result.message,
        ),
        ChallengeCodePanel(
          code: ChallengeLink.readableCodeFor(result.token),
          link: result.link.toString(),
        ),
        const ChallengeFootnote(
          'Opening a share sheet is never counted as a referral. Nothing is '
          'created until a recipient sends a request, and a request only '
          'becomes a match when you accept it.',
        ),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChallengePrimaryButton(
            key: const ValueKey('challenge-share-again-button'),
            label: widget.linkOnly ? 'Share link' : 'Share again',
            busy: _sharing,
            onPressed: _shareAgain,
          ),
          const SizedBox(height: 8),
          ChallengeQuietButton(
            key: const ValueKey('challenge-share-done-button'),
            label: 'Done',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
