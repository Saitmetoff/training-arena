/// Swaps the normal shell for the focused challenge experience.
///
/// A cold or warm link always lands on one challenge route first — the
/// recipient never has to navigate tabs, find a friend, import contacts or
/// re-type a code. Closing the view returns to the shell without cancelling
/// the durable link or the pending request.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'arena_linking.dart';
import 'challenge_entry_controller.dart';
import 'challenge_entry_view.dart';

/// Hosts [child] until the controller leaves the idle state.
class ChallengeLinkHost extends StatefulWidget {
  const ChallengeLinkHost({
    super.key,
    required this.child,
    this.onMatchReady,
  });

  /// The normal app content (the arena shell).
  final Widget child;

  /// Called with the confirmed match id; task `07` routes to preparation.
  final void Function(String matchId)? onMatchReady;

  @override
  State<ChallengeLinkHost> createState() => _ChallengeLinkHostState();
}

class _ChallengeLinkHostState extends State<ChallengeLinkHost> {
  ChallengeEntryController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final linking = ArenaLinkingScope.of(context);
    if (identical(_controller, linking.controller)) {
      return;
    }
    _controller?.removeListener(_onControllerChanged);
    _controller = linking.controller..addListener(_onControllerChanged);
    unawaited(_controller!.start());
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linking = ArenaLinkingScope.of(context);
    final controller = _controller;
    if (controller == null || controller.state is ChallengeEntryIdle) {
      return widget.child;
    }
    return ChallengeEntryView(
      controller: controller,
      installLauncher: linking.installLauncher,
      analytics: linking.analytics,
      onMatchReady: widget.onMatchReady,
    );
  }
}
