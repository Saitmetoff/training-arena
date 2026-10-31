/// Result share card renderer.
///
/// Renders the exact artwork exported by task `09` at the token type scale
/// from `design/arena/DESIGN_SYSTEM.md`. The sharer is always the left, lime
/// panel; the opponent is always the right, violet panel. Avatars are never
/// fetched from the network here: only an explicit [avatarImages] map (the
/// receipt snapshot) is painted, so exports are deterministic and no camera
/// frame or remote image can leak into the card.
///
/// Every block has a fixed allocated height (from [ResultShareCardLayout])
/// and scales its own content down when a font or a long identity needs more
/// room. The export can therefore never overflow or clip the mandated facts.
library;

import 'package:flutter/material.dart';

import '../battle/ui/battle_style.dart';
import '../domain/arena_types.dart';
import '../theme/arena_tokens.dart';
import 'result_share_copy.dart';
import 'result_share_models.dart';
import 'result_share_qr.dart';

/// Safe area and element metrics for one export format.
///
/// [contentRect] is the generous central safe area that must contain the
/// headline, scores, identities, CTA, URL and QR. Values are logical at the
/// fixed [ResultShareFormat.pixelRatio]; multiply by 2 for export pixels.
class ResultShareCardLayout {
  const ResultShareCardLayout._(
    this.format,
    this.safeArea, {
    required this.qrSize,
    required this.headlineHeight,
    required this.kickerHeight,
    required this.scoreRowHeight,
    required this.metaRowHeight,
    required this.ctaHeight,
    required this.avatarSize,
    required this.panelPadding,
    required this.footnoteHeight,
  });

  factory ResultShareCardLayout.forFormat(ResultShareFormat format) {
    switch (format) {
      case ResultShareFormat.stories:
        return const ResultShareCardLayout._(
          ResultShareFormat.stories,
          EdgeInsets.fromLTRB(54, 156, 54, 180),
          qrSize: 132,
          headlineHeight: 72,
          kickerHeight: 16,
          scoreRowHeight: 200,
          metaRowHeight: 32,
          ctaHeight: 64,
          avatarSize: 32,
          panelPadding: 16,
          footnoteHeight: 44,
        );
      case ResultShareFormat.feed:
        return const ResultShareCardLayout._(
          ResultShareFormat.feed,
          EdgeInsets.fromLTRB(43, 68, 43, 81),
          qrSize: 104,
          headlineHeight: 48,
          kickerHeight: 16,
          scoreRowHeight: 184,
          metaRowHeight: 30,
          ctaHeight: 52,
          avatarSize: 28,
          panelPadding: 12,
          footnoteHeight: 38,
        );
    }
  }

  final ResultShareFormat format;

  /// Inset that keeps content clear of platform story/feed chrome.
  final EdgeInsets safeArea;

  final double qrSize;
  final double headlineHeight;
  final double kickerHeight;
  final double scoreRowHeight;
  final double metaRowHeight;
  final double ctaHeight;
  final double avatarSize;
  final double panelPadding;
  final double footnoteHeight;

  Size get logicalSize => Size(format.logicalWidth, format.logicalHeight);

  /// Rect (logical px) every mandatory element stays inside.
  Rect get contentRect => Rect.fromLTRB(
        safeArea.left,
        safeArea.top,
        format.logicalWidth - safeArea.right,
        format.logicalHeight - safeArea.bottom,
      );

  /// Same rect in exported pixels, for the spec and tests.
  Rect get contentRectPixels => Rect.fromLTRB(
        contentRect.left * ResultShareFormat.pixelRatio,
        contentRect.top * ResultShareFormat.pixelRatio,
        contentRect.right * ResultShareFormat.pixelRatio,
        contentRect.bottom * ResultShareFormat.pixelRatio,
      );

  /// Total height allocated to fixed blocks; the column distributes the
  /// remainder with `spaceBetween`.
  double get fixedContentHeight =>
      kickerHeight +
      headlineHeight +
      scoreRowHeight +
      metaRowHeight +
      ctaHeight +
      qrSize +
      footnoteHeight;

  bool get fitsContent => fixedContentHeight <= contentRect.height + 0.01;
}

/// Renders one [ResultShareCard] at its exact export layout.
class ResultShareCardView extends StatelessWidget {
  const ResultShareCardView({
    super.key,
    required this.card,
    required this.format,
    this.avatarImages = const <String, ImageProvider>{},
  });

  final ResultShareCard card;
  final ResultShareFormat format;

  /// Optional avatar providers keyed by profile id. Missing or empty entries
  /// fall back to the two-letter monogram; nothing is fetched remotely.
  final Map<String, ImageProvider> avatarImages;

  @override
  Widget build(BuildContext context) {
    final layout = ResultShareCardLayout.forFormat(format);
    return Semantics(
      container: true,
      image: true,
      label: ResultShareCopy.cardSemanticSummary(card),
      child: ExcludeSemantics(
        child: SizedBox(
          key: const ValueKey('result-share-card'),
          width: layout.logicalSize.width,
          height: layout.logicalSize.height,
          child: ColoredBox(
            color: ArenaColors.charcoal,
            child: Padding(
              padding: layout.safeArea,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Kicker(
                    text: ResultShareCopy.kicker(card),
                    height: layout.kickerHeight,
                  ),
                  _Headline(
                    text: card.headline,
                    height: layout.headlineHeight,
                    color: _headlineColor(card.outcome),
                  ),
                  _ScoreRow(
                    card: card,
                    layout: layout,
                    avatarImages: avatarImages,
                  ),
                  _MetaRow(card: card, height: layout.metaRowHeight),
                  _CtaBlock(text: card.cta, height: layout.ctaHeight),
                  _LinkFooter(card: card, layout: layout),
                  _Footnote(card: card, layout: layout),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _headlineColor(ResultShareOutcome outcome) => switch (outcome) {
        ResultShareOutcome.win => ArenaColors.lime,
        ResultShareOutcome.loss => ArenaColors.violet,
        ResultShareOutcome.draw => ArenaColors.softWhite,
        ResultShareOutcome.noResult => ArenaColors.softWhite,
      };
}

class _Kicker extends StatelessWidget {
  const _Kicker({required this.text, required this.height});

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('share-card-kicker'),
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.text,
    required this.height,
    required this.color,
  });

  final String text;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('share-card-headline'),
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: ArenaBattleText.h1.copyWith(color: color),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.card,
    required this.layout,
    required this.avatarImages,
  });

  final ResultShareCard card;
  final ResultShareCardLayout layout;
  final Map<String, ImageProvider> avatarImages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('share-card-scores'),
      height: layout.scoreRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ScorePanel(
              key: const ValueKey('share-card-score-viewer'),
              player: card.viewerPlayer,
              role: 'you · player',
              accent: false,
              score: card.hasConfirmedScores ? card.viewerPlayer.score : null,
              ratingAfter: card.viewerRatingAfter,
              ratingChange: card.viewerRatingChange,
              layout: layout,
              avatarImages: avatarImages,
            ),
          ),
          const SizedBox(width: ArenaBattleSpace.s3),
          Expanded(
            child: _ScorePanel(
              key: const ValueKey('share-card-score-opponent'),
              player: card.opponentPlayer,
              role: 'opponent',
              accent: true,
              score: card.hasConfirmedScores ? card.opponentPlayer.score : null,
              ratingAfter: card.opponentRatingAfter,
              ratingChange: card.opponentRatingChange,
              layout: layout,
              avatarImages: avatarImages,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    super.key,
    required this.player,
    required this.role,
    required this.accent,
    required this.score,
    required this.ratingAfter,
    required this.ratingChange,
    required this.layout,
    required this.avatarImages,
  });

  final ArenaReceiptPlayer player;
  final String role;
  final bool accent;
  final int? score;
  final int? ratingAfter;
  final int? ratingChange;
  final ResultShareCardLayout layout;
  final Map<String, ImageProvider> avatarImages;

  @override
  Widget build(BuildContext context) {
    final identityColor = accent ? ArenaColors.violet : ArenaColors.lime;
    final wash = accent ? ArenaColors.opponentWash : ArenaColors.playerWash;
    return Container(
      padding: EdgeInsets.all(layout.panelPadding),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
        border: Border.all(color: identityColor.withValues(alpha: 0.45)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(
                  player: player,
                  size: layout.avatarSize,
                  color: identityColor,
                  wash: wash,
                  provider: avatarImages[player.profile.id],
                ),
                const SizedBox(width: ArenaBattleSpace.s2),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      handleFor(player),
                      maxLines: 1,
                      style: ArenaBattleText.h3.copyWith(
                        color: ArenaColors.softWhite,
                      ),
                    ),
                    Text(
                      role,
                      maxLines: 1,
                      style: ArenaBattleText.small.copyWith(
                        color: identityColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: ArenaBattleSpace.s2),
            if (score != null)
              Text(
                '$score',
                style: ArenaBattleText.score.copyWith(color: identityColor),
              )
            else
              Text(
                '—',
                key: ValueKey('share-card-no-score-${player.profile.id}'),
                style: ArenaBattleText.score.copyWith(color: ArenaColors.quiet),
              ),
            Text(
              score != null ? 'reps' : 'no confirmed score',
              style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
            ),
            if (ratingAfter != null) ...[
              const SizedBox(height: ArenaBattleSpace.s1),
              Text(
                _ratingLabel(ratingAfter!, ratingChange),
                key: ValueKey('share-card-rating-${player.profile.id}'),
                style: ArenaBattleText.smallStrong.copyWith(
                  color: ArenaColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _ratingLabel(int after, int? change) {
    if (change == null || change == 0) {
      return 'Arena rating $after';
    }
    final sign = change > 0 ? '+' : '−';
    return 'Arena rating $after ($sign${change.abs()})';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.player,
    required this.size,
    required this.color,
    required this.wash,
    this.provider,
  });

  final ArenaReceiptPlayer player;
  final double size;
  final Color color;
  final Color wash;
  final ImageProvider? provider;

  String get _initials {
    final name = player.profile.username?.trim();
    final value = (name == null || name.isEmpty)
        ? player.profile.displayName.trim()
        : name;
    if (value.isEmpty) {
      return '??';
    }
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return value.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: wash,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: provider == null
          ? Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _initials,
                    style: ArenaBattleText.smallStrong.copyWith(color: color),
                  ),
                ),
              ),
            )
          : Image(
              image: provider!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      _initials,
                      style:
                          ArenaBattleText.smallStrong.copyWith(color: color),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

enum _PillTone { neutral, positive, warning }

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.card, required this.height});

  final ResultShareCard card;
  final double height;

  @override
  Widget build(BuildContext context) {
    final noResult = card.outcome == ResultShareOutcome.noResult;
    return SizedBox(
      key: const ValueKey('share-card-meta'),
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pill(
              label: '${card.exerciseLabel} · ${card.durationLabel}',
              tone: _PillTone.neutral,
            ),
            const SizedBox(width: ArenaBattleSpace.s2),
            _Pill(
              label: ResultShareCopy.modeChip(card),
              tone: noResult
                  ? _PillTone.warning
                  : card.ranked
                      ? _PillTone.positive
                      : _PillTone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone});

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _PillTone.neutral => ArenaColors.secondary,
      _PillTone.positive => ArenaColors.positive,
      _PillTone.warning => ArenaColors.warning,
    };
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
      child: Text(
        label,
        maxLines: 1,
        style: ArenaBattleText.smallStrong.copyWith(color: color),
      ),
    );
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({required this.text, required this.height});

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('share-card-cta'),
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaBattleSpace.s4,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.lime,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: ArenaBattleText.h2.copyWith(
            color: ArenaColors.playerInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LinkFooter extends StatelessWidget {
  const _LinkFooter({required this.card, required this.layout});

  final ResultShareCard card;
  final ResultShareCardLayout layout;

  @override
  Widget build(BuildContext context) {
    ResultShareQr? qr;
    try {
      qr = ResultShareQr.fromUrl(
        card.challengeUrl,
        expectedHost: card.challengeUrl.host,
      );
    } on ResultShareException {
      qr = null;
    }
    return SizedBox(
      key: const ValueKey('share-card-link'),
      height: layout.qrSize,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (qr != null)
            ResultShareQrView(
              key: const ValueKey('share-card-qr'),
              qr: qr,
              size: layout.qrSize,
              semanticLabel: card.qrSemanticLabel,
            )
          else
            Container(
              key: const ValueKey('share-card-qr-unavailable'),
              width: layout.qrSize,
              height: layout.qrSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ArenaColors.raised,
                borderRadius:
                    BorderRadius.circular(ArenaBattleSpace.radiusSmall),
                border: Border.all(color: ArenaColors.line),
              ),
              child: Text(
                'QR\nunavailable',
                textAlign: TextAlign.center,
                style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
              ),
            ),
          const SizedBox(width: ArenaBattleSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan or open the live challenge',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArenaBattleText.small.copyWith(
                    color: ArenaColors.secondary,
                  ),
                ),
                const SizedBox(height: ArenaBattleSpace.s1),
                Text(
                  card.challengeUrl.toString(),
                  key: const ValueKey('share-card-url'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArenaBattleText.smallStrong.copyWith(
                    color: ArenaColors.softWhite,
                  ),
                ),
                const SizedBox(height: ArenaBattleSpace.s1),
                Text(
                  'Code ${card.readableCode}',
                  key: const ValueKey('share-card-code'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArenaBattleText.micro.copyWith(
                    color: ArenaColors.quiet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.card, required this.layout});

  final ResultShareCard card;
  final ResultShareCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final text = card.isPreview
        ? ResultShareCopy.previewNote
        : '${ResultShareCopy.newChallengeNote} ${ResultShareCopy.readOnlyNote}';
    return SizedBox(
      key: const ValueKey('share-card-footnote'),
      height: layout.footnoteHeight,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
      ),
    );
  }
}
