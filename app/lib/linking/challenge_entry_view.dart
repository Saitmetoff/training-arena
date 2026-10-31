/// Focused challenge entry screens.
///
/// Every state from `docs/decisions/05-challenge-link-interface-decisions.md`
/// is rendered here with honest copy: nothing promises asynchronous replay,
/// no local match is invented, and the readable code is always available.
library;

import 'package:flutter/material.dart';

import '../theme/arena_tokens.dart';
import 'challenge_analytics.dart';
import 'challenge_auth.dart';
import 'challenge_entry_controller.dart';
import 'challenge_install_view.dart';
import 'challenge_link.dart';
import 'challenge_models.dart';

/// Renders one [ChallengeEntryState]. The host owns lifecycle; this widget
/// is stateless and re-renders on controller notifications.
class ChallengeEntryView extends StatelessWidget {
  const ChallengeEntryView({
    super.key,
    required this.controller,
    required this.installLauncher,
    required this.analytics,
    this.onMatchReady,
  });

  final ChallengeEntryController controller;
  final ChallengeInstallLauncher installLauncher;
  final ChallengeAnalyticsSink analytics;

  /// Called when the backend confirmed a match. Task `07` wires this to the
  /// preparation route; the default leaves the focused experience.
  final void Function(String matchId)? onMatchReady;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return KeyedSubtree(
      key: const ValueKey('challenge-entry-view'),
      child: switch (state) {
        ChallengeEntryIdle() => const SizedBox.shrink(),
        ChallengeEntryResolving(:final token) => _ResolvingView(
            token: token,
            onClose: controller.dismiss,
          ),
        ChallengeEntryReview() => _ReviewView(
            state: state,
            controller: controller,
          ),
        ChallengeEntrySignIn() => _SignInView(
            state: state,
            controller: controller,
          ),
        ChallengeEntryWaiting() => _WaitingView(
            state: state,
            controller: controller,
          ),
        ChallengeEntryUnavailable() => _UnavailableView(
            state: state,
            controller: controller,
          ),
        ChallengeEntryFailure() => _FailureView(
            state: state,
            controller: controller,
          ),
        ChallengeEntryMatchReady() => _MatchReadyView(
            state: state,
            onMatchReady: onMatchReady,
            onDone: controller.dismiss,
          ),
        ChallengeEntryInstallRequired() => ChallengeInstallView(
            token: state.token,
            config: controller.config,
            launcher: installLauncher,
            analytics: analytics,
            message: state.message,
            onRetry: controller.retry,
            onClose: controller.dismiss,
          ),
      },
    );
  }
}

class _ResolvingView extends StatelessWidget {
  const _ResolvingView({required this.token, this.onClose});

  final String token;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-resolving-view'),
      kicker: 'Challenge link',
      onClose: onClose,
      content: [
        const SizedBox(height: 48),
        const Center(
          child: CircularProgressIndicator(color: ArenaColors.lime),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Opening challenge link…',
            style: TextStyle(color: ArenaColors.secondary),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Read-only: nothing is created until you accept.',
            style: const TextStyle(color: ArenaColors.quiet, fontSize: 12),
            key: ValueKey('challenge-resolving-$token'),
          ),
        ),
      ],
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.state, required this.controller});

  final ChallengeEntryReview state;
  final ChallengeEntryController controller;

  @override
  Widget build(BuildContext context) {
    final resolution = state.resolution;
    final username = resolution.owner?.username;
    final handle = username != null && username.isNotEmpty
        ? '@$username'
        : 'This challenger';
    final offline = resolution.isOwnerOffline;
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-landing-review'),
      kicker: 'Challenge link',
      onClose: controller.dismiss,
      content: [
        if (state.restored)
          const ChallengeInfoBanner(
            variant: ChallengeBannerVariant.positive,
            title: 'Your challenge was kept',
            body: 'You left before sending your request. The link is still '
                'attached to your account.',
          ),
        ChallengeChallengerIdentity(sender: resolution.owner),
        ChallengeEntryTitle('$handle challenges you'),
        const Text(
          'Push-ups or squats. 60 seconds, counted by your camera, with the '
          'result confirmed by the server.',
          style: TextStyle(
            color: ArenaColors.secondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (offline)
          ChallengeInfoBanner(
            variant: ChallengeBannerVariant.warning,
            title: 'Challenger offline',
            body: 'Live challenges need both players at the same time. '
                'Sending tells $handle you are ready to battle now. It is not '
                'a replay, and there is no old score to beat.',
          ),
        ChallengeSectionCard(
          title: 'How this works',
          body: 'Opening this page is read-only. Nothing is created until you '
              'send your request, and there is no old score to beat.',
          orderedSteps: <String>[
            'Send your challenge request. This link stays attached to it.',
            'When $handle accepts, prepare: see the exercise and take one '
                'unscored practice rep.',
            'You both confirm ready, then a 5-second countdown and a '
                '60-second live battle.',
          ],
        ),
        const ChallengeSectionCard(
          title: 'Your camera stays on your phone',
          body: 'Camera frames are processed on your device and never '
              'uploaded. Only rep counts are sent to the match score.',
        ),
        if (state.errorMessage != null)
          ChallengeInfoBanner(
            variant: ChallengeBannerVariant.danger,
            title: 'The request was not sent',
            body: state.errorMessage,
          ),
        ChallengeFootnote(
          'Requests expire after 24 hours · code ${ChallengeLink.readableCodeFor(resolution.token)} · '
          'sign-in is required to send a request.',
        ),
      ],
      bottom: ChallengePrimaryButton(
        key: const ValueKey('challenge-accept-button'),
        label: offline ? 'Send live challenge' : 'Accept challenge',
        busy: state.sending,
        onPressed: controller.acceptChallenge,
      ),
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView({required this.state, required this.controller});

  final ChallengeEntrySignIn state;
  final ChallengeEntryController controller;

  @override
  Widget build(BuildContext context) {
    final resolution = state.resolution;
    final username = resolution.owner?.username;
    final handle = username != null && username.isNotEmpty
        ? '@$username'
        : 'this challenger';
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-signin-view'),
      kicker: 'Sign in',
      onClose: controller.dismiss,
      content: [
        const ChallengeEntryTitle('Sign in to accept'),
        ChallengeChallengerIdentity(sender: resolution.owner),
        const ChallengeInfoBanner(
          variant: ChallengeBannerVariant.positive,
          title: 'Your challenge is kept',
          body: 'Sign in and you return to this exact challenge. No friend '
              'search, no typing a code.',
        ),
        ChallengeSectionCard(
          title: 'What happens next',
          body: 'Opening this page is read-only. The link stays pending until '
              'you send a request.',
          orderedSteps: <String>[
            'Sign in with Google or email.',
            'Send your request to $handle.',
            'Prepare and battle for 60 seconds when you are both available.',
          ],
        ),
        if (state.errorMessage != null)
          ChallengeInfoBanner(
            variant: ChallengeBannerVariant.danger,
            title: 'Sign-in did not complete',
            body: state.errorMessage,
          ),
        ChallengeFootnote(
          'Code ${ChallengeLink.readableCodeFor(resolution.token)}',
        ),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChallengePrimaryButton(
            key: const ValueKey('challenge-signin-google'),
            label: 'Continue with Google',
            busy: state.signingIn,
            onPressed: () => controller.signIn(ChallengeAuthMethod.google),
          ),
          const SizedBox(height: 10),
          ChallengeSecondaryButton(
            key: const ValueKey('challenge-signin-email'),
            label: 'Continue with email',
            onPressed: state.signingIn
                ? null
                : () => controller.signIn(ChallengeAuthMethod.email),
          ),
        ],
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({required this.state, required this.controller});

  final ChallengeEntryWaiting state;
  final ChallengeEntryController controller;

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArenaColors.graphite,
        title: const Text(
          'Cancel this request?',
          style: TextStyle(color: ArenaColors.softWhite),
        ),
        content: const Text(
          'Nothing is replayed or rescheduled. You can send a new live '
          'challenge later.',
          style: TextStyle(color: ArenaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep request'),
          ),
          TextButton(
            key: const ValueKey('challenge-cancel-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Cancel request',
              style: TextStyle(color: ArenaColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancelPendingRequest();
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = state.sender?.username;
    final handle = username != null && username.isNotEmpty
        ? '@$username'
        : 'your challenger';
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-waiting-view'),
      kicker: 'Live challenge',
      onClose: controller.dismiss,
      content: [
        ChallengeEntryTitle(state.restored ? 'Still waiting' : 'Request sent'),
        ChallengeChallengerIdentity(sender: state.sender),
        ChallengeInfoBanner(
          variant: ChallengeBannerVariant.positive,
          title: 'Your request is with $handle',
          body: 'Requests last 24 hours. You can leave this screen; the '
              'request stays. If $handle is offline, nothing starts until you '
              'are both available — this is not a replay and there is no old '
              'score to beat.',
        ),
        if (state.errorMessage != null)
          ChallengeInfoBanner(
            variant: ChallengeBannerVariant.danger,
            title: 'Could not check for an accepted match',
            body: state.errorMessage,
          ),
        ChallengeCodePanel(
          code: ChallengeLink.readableCodeFor(state.token),
          link: controller.config.challengeLink(state.token).toString(),
        ),
        ChallengeFootnote(
          'Once $handle accepts, both players return and confirm readiness '
          'before the 60-second battle starts.',
        ),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChallengePrimaryButton(
            key: const ValueKey('challenge-check-button'),
            label: 'Check again',
            busy: state.checking,
            onPressed: controller.checkForAcceptedMatch,
          ),
          const SizedBox(height: 8),
          ChallengeQuietButton(
            key: const ValueKey('challenge-cancel-button'),
            label: 'Cancel request',
            onPressed: () => _confirmCancel(context),
          ),
        ],
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.state, required this.controller});

  final ChallengeEntryUnavailable state;
  final ChallengeEntryController controller;

  @override
  Widget build(BuildContext context) {
    final username = controller.pendingChallenge?.sender?.username;
    final handle = username != null && username.isNotEmpty
        ? '@$username'
        : 'this challenger';
    final copy = _unavailableCopy(state.status, handle);
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-unavailable-view'),
      kicker: 'Challenge link',
      onClose: controller.dismiss,
      content: [
        ChallengeEntryTitle(copy.$1),
        ChallengeInfoBanner(
          variant: ChallengeBannerVariant.warning,
          title: copy.$1,
          body: state.message?.isNotEmpty == true ? state.message : copy.$2,
        ),
        ChallengeFootnote(
          'A challenge link identifies a person for a new live battle — it '
          'never stores or replays a match. Code '
          '${ChallengeLink.readableCodeFor(state.token)}',
        ),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.status == ChallengeLinkStatus.busyPlayer)
            ChallengePrimaryButton(
              key: const ValueKey('challenge-retry-button'),
              label: 'Try again',
              onPressed: controller.retry,
            ),
          ChallengeQuietButton(
            label: 'Back to Battle',
            onPressed: controller.dismiss,
          ),
        ],
      ),
    );
  }

  static (String, String) _unavailableCopy(
    ChallengeLinkStatus status,
    String handle,
  ) {
    switch (status) {
      case ChallengeLinkStatus.revoked:
        return (
          'This challenge link was revoked',
          'The owner replaced or revoked it. Ask $handle for a new live '
              'challenge link.',
        );
      case ChallengeLinkStatus.expired:
        return (
          'This challenge request expired',
          'Requests last 24 hours. Ask $handle for a new live challenge when '
              'you are both available.',
        );
      case ChallengeLinkStatus.completed:
        return (
          'This challenge already happened',
          'A challenge link is not a rematch. Ask $handle for a new live '
              'challenge; nothing is replayed and there is no old score to '
              'beat.',
        );
      case ChallengeLinkStatus.busyPlayer:
        return (
          '$handle is in another battle',
          'Nothing was sent. Try again after the current battle finishes.',
        );
      case ChallengeLinkStatus.blocked:
        return (
          'This challenge is unavailable',
          'You cannot send a challenge to this player. Nothing was sent.',
        );
      case ChallengeLinkStatus.ownerOffline:
      case ChallengeLinkStatus.available:
      case ChallengeLinkStatus.unavailable:
        return (
          'This challenge link is unavailable',
          'It was revoked, expired, or the account was deleted. A challenge '
              'link identifies a person for a new live battle — it never '
              'stores or replays a match.',
        );
    }
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.state, required this.controller});

  final ChallengeEntryFailure state;
  final ChallengeEntryController controller;

  @override
  Widget build(BuildContext context) {
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-failure-view'),
      kicker: 'Challenge link',
      onClose: controller.dismiss,
      content: [
        const ChallengeEntryTitle('Challenge could not be opened'),
        ChallengeInfoBanner(
          variant: ChallengeBannerVariant.danger,
          title: 'Something interrupted the link',
          body: state.message,
        ),
        const ChallengeFootnote(
          'Nothing was created. Your link stays attached until it opens, and '
          'you can try again whenever the arena is reachable.',
        ),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.retryable)
            ChallengePrimaryButton(
              key: const ValueKey('challenge-retry-button'),
              label: 'Try again',
              onPressed: controller.retry,
            ),
          ChallengeQuietButton(
            label: 'Back to Battle',
            onPressed: controller.dismiss,
          ),
        ],
      ),
    );
  }
}

class _MatchReadyView extends StatelessWidget {
  const _MatchReadyView({
    required this.state,
    required this.onMatchReady,
    required this.onDone,
  });

  final ChallengeEntryMatchReady state;
  final void Function(String matchId)? onMatchReady;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final username = state.sender?.username;
    final handle = username != null && username.isNotEmpty
        ? '@$username'
        : 'your opponent';
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-match-ready-view'),
      kicker: 'Match ready',
      content: [
        const ChallengeEntryTitle('Your match is ready'),
        ChallengeInfoBanner(
          variant: ChallengeBannerVariant.positive,
          title: 'Both players are in',
          body: 'The live casual match with $handle is created. It starts only '
              'after you both return, take one practice rep and confirm '
              'readiness.',
        ),
        const ChallengeSectionCard(
          title: 'No unattended start',
          body: 'Countdown and live play never begin while either player is '
              'away. The match expires after 10 minutes in preparation with '
              'no rating change.',
        ),
      ],
      bottom: ChallengePrimaryButton(
        key: const ValueKey('challenge-open-battle-button'),
        label: 'Continue to preparation',
        onPressed: () {
          onDone();
          onMatchReady?.call(state.matchId);
        },
      ),
    );
  }
}
