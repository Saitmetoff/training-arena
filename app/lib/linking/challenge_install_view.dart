/// In-app install/update recovery page.
///
/// Shown when an installed build cannot handle challenge links yet (feature
/// flag off, or an older build). It mirrors the web landing page: Play route
/// carrying the install-referrer token, a visible "reopen this link after
/// installing" instruction, and the readable short code fallback.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/arena_config.dart';
import '../domain/arena_types.dart';
import '../theme/arena_tokens.dart';
import 'challenge_analytics.dart';
import 'challenge_link.dart';

/// Testable boundary around the Play listing.
abstract class ChallengeInstallLauncher {
  Future<bool> openPlayStore(Uri url);
}

/// `url_launcher` implementation; failures are non-fatal.
class UrlLauncherChallengeInstallLauncher implements ChallengeInstallLauncher {
  const UrlLauncherChallengeInstallLauncher();

  @override
  Future<bool> openPlayStore(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Install/update recovery content.
class ChallengeInstallView extends StatelessWidget {
  const ChallengeInstallView({
    super.key,
    required this.token,
    required this.config,
    required this.launcher,
    required this.analytics,
    this.sender,
    this.message,
    this.onRetry,
    this.onClose,
  });

  final String token;
  final ArenaConfig config;
  final ChallengeInstallLauncher launcher;
  final ChallengeAnalyticsSink analytics;
  final ArenaProfile? sender;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  Future<void> _openStore(BuildContext context) async {
    await analytics.track(
      ChallengeAnalyticsEvent.installCtaTapped,
      const <String, Object?>{'surface': 'app'},
    );
    final opened = await launcher.openPlayStore(config.installReferrerUrl(token));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ArenaColors.raised,
          content: Text(
            config.playStoreUrl,
            style: const TextStyle(color: ArenaColors.softWhite),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = ChallengeLink.readableCodeFor(token);
    return ChallengeEntryScaffold(
      key: const ValueKey('challenge-install-view'),
      onClose: onClose,
      kicker: 'Not installed',
      content: [
        const _EntryTitle('Install Fault'),
        ChallengeChallengerIdentity(sender: sender),
        const ChallengeInfoBanner(
          variant: ChallengeBannerVariant.positive,
          title: 'Three steps, then you battle',
          body: 'Install or update the app, reopen this challenge link, then '
              'send your request. No friend search and no code typing.',
        ),
        if (message != null)
          ChallengeInfoBanner(
            variant: ChallengeBannerVariant.warning,
            title: 'Heads up',
            body: message!,
          ),
        const ChallengeSectionCard(
          title: 'Reopen this link after installing',
          body: 'Android App Links and the Play Install Referrer return you to '
              'this exact challenge. If nothing reopens, use the short code '
              'below under Join with code.',
        ),
        ChallengeCodePanel(
          code: code,
          link: config.challengeLink(token).toString(),
        ),
        const SizedBox(height: 8),
        ChallengePrimaryButton(
          key: const ValueKey('challenge-play-button'),
          label: 'Get Fault on Google Play',
          onPressed: () => _openStore(context),
        ),
        if (onRetry != null)
          ChallengeSecondaryButton(
            key: const ValueKey('challenge-install-retry-button'),
            label: 'Already installed? Try again',
            onPressed: onRetry,
          ),
        const ChallengeFootnote(
          'Links use the configured host; it stays example.invalid until the '
          'owner supplies the real domain.',
        ),
      ],
    );
  }
}

/// Shared chrome for every challenge entry screen.
class ChallengeEntryScaffold extends StatelessWidget {
  const ChallengeEntryScaffold({
    super.key,
    required this.content,
    this.onClose,
    this.kicker,
    this.bottom,
  });

  final List<Widget> content;
  final VoidCallback? onClose;
  final String? kicker;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (onClose != null)
                    IconButton(
                      key: const ValueKey('challenge-close-button'),
                      onPressed: onClose,
                      tooltip: 'Close and return to Battle',
                      icon: const Icon(
                        Icons.close,
                        color: ArenaColors.softWhite,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  if (kicker != null)
                    Text(
                      kicker!,
                      style: const TextStyle(
                        color: ArenaColors.quiet,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Screen title used by the challenge entry screens.
class ChallengeEntryTitle extends StatelessWidget {
  const ChallengeEntryTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: ArenaColors.softWhite,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    );
  }
}

class _EntryTitle extends StatelessWidget {
  const _EntryTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ChallengeEntryTitle(text);
}

/// Challenger identity block.
class ChallengeChallengerIdentity extends StatelessWidget {
  const ChallengeChallengerIdentity({
    super.key,
    required this.sender,
    this.role = 'challenger · opponent',
    this.large = true,
  });

  final ArenaProfile? sender;
  final String role;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final username = sender?.username;
    final label = username != null && username.isNotEmpty
        ? '@$username'
        : 'Fault challenger';
    final initials = _initials(username);
    final size = large ? 56.0 : 40.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: ArenaColors.raised,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: initials.isEmpty
                ? const Icon(Icons.person, color: ArenaColors.violet)
                : Text(
                    initials,
                    style: TextStyle(
                      color: ArenaColors.violet,
                      fontSize: large ? 20 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ArenaColors.softWhite,
                    fontSize: large ? 20 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: ArenaColors.quiet,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? username) {
    if (username == null || username.isEmpty) {
      return '';
    }
    final upper = username.toUpperCase();
    return upper.length >= 2 ? upper.substring(0, 2) : upper;
  }
}

enum ChallengeBannerVariant { info, positive, warning, danger }

/// Inline banner with an honest state message.
class ChallengeInfoBanner extends StatelessWidget {
  const ChallengeInfoBanner({
    super.key,
    required this.variant,
    required this.title,
    this.body,
    this.actions = const <Widget>[],
  });

  final ChallengeBannerVariant variant;
  final String title;
  final String? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      ChallengeBannerVariant.info => ArenaColors.secondary,
      ChallengeBannerVariant.positive => ArenaColors.positive,
      ChallengeBannerVariant.warning => ArenaColors.warning,
      ChallengeBannerVariant.danger => ArenaColors.danger,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArenaColors.graphite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              style: const TextStyle(
                color: ArenaColors.secondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Plain card with a title and body.
class ChallengeSectionCard extends StatelessWidget {
  const ChallengeSectionCard({
    super.key,
    required this.title,
    required this.body,
    this.orderedSteps,
  });

  final String title;
  final String body;
  final List<String>? orderedSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArenaColors.graphite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ArenaColors.softWhite,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: ArenaColors.secondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (orderedSteps != null) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < orderedSteps!.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ',
                      style: const TextStyle(
                        color: ArenaColors.lime,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        orderedSteps![i],
                        style: const TextStyle(
                          color: ArenaColors.secondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Readable short code plus the full HTTPS link.
class ChallengeCodePanel extends StatelessWidget {
  const ChallengeCodePanel({super.key, required this.code, required this.link});

  final String code;
  final String link;

  Future<void> _copy(BuildContext context, String value, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$label copied.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not copy. Select the text instead.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Readable short code',
            style: TextStyle(color: ArenaColors.quiet, fontSize: 12),
          ),
          const SizedBox(height: 6),
          SelectableText(
            code,
            key: const ValueKey('challenge-code-text'),
            style: const TextStyle(
              color: ArenaColors.softWhite,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            link,
            style: const TextStyle(color: ArenaColors.quiet, fontSize: 12),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _copy(context, link, 'Link'),
                child: const Text('Copy link'),
              ),
              TextButton(
                onPressed: () => _copy(context, code, 'Code'),
                child: const Text('Copy code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lime primary action.
class ChallengePrimaryButton extends StatelessWidget {
  const ChallengePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ArenaColors.lime,
        foregroundColor: ArenaColors.charcoal,
        disabledBackgroundColor: ArenaColors.raised,
        disabledForegroundColor: ArenaColors.quiet,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: ArenaColors.charcoal,
              ),
            )
          : Text(label),
    );
  }
}

/// Outlined secondary action.
class ChallengeSecondaryButton extends StatelessWidget {
  const ChallengeSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ArenaColors.softWhite,
        side: const BorderSide(color: ArenaColors.raised),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Quiet action (leave, retry links).
class ChallengeQuietButton extends StatelessWidget {
  const ChallengeQuietButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ArenaColors.secondary,
        minimumSize: const Size.fromHeight(44),
      ),
      child: Text(label),
    );
  }
}

/// Small footnote copy.
class ChallengeFootnote extends StatelessWidget {
  const ChallengeFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: ArenaColors.quiet,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
