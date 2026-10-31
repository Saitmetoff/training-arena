/// Exact-card preview and share actions.
///
/// The preview renders the same [ResultShareCardView] that is exported, so
/// what the sharer sees is the artwork that leaves the device. The card CTA
/// is painted artwork, not an interactive link: only the real buttons below
/// the preview invoke the share sheet, clipboard or system share.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../battle/ui/battle_style.dart';
import '../battle/ui/battle_widgets.dart';
import '../domain/arena_types.dart';
import '../linking/challenge_models.dart';
import '../theme/arena_tokens.dart';
import 'result_share_card_view.dart';
import 'result_share_models.dart';
import 'result_share_service.dart';

/// Full-screen preview for one confirmed receipt.
class ResultSharePreviewPage extends StatefulWidget {
  const ResultSharePreviewPage({
    super.key,
    required this.receipt,
    required this.viewerId,
    required this.service,
    this.initialSnapshot,
    this.initialFormat = ResultShareFormat.stories,
    this.capture = const RepaintBoundaryResultShareCapture(),
    this.avatarImages = const <String, ImageProvider>{},
    this.source = 'result',
  });

  final ResultReceipt receipt;
  final String viewerId;
  final ResultShareService service;

  /// Prefetched confirmed account snapshot; null loads from the backend.
  final ChallengeAccountSnapshot? initialSnapshot;

  final ResultShareFormat initialFormat;

  /// Export boundary seam; tests inject a deterministic capture.
  final ResultShareCapture capture;

  /// Receipt-snapshot avatars keyed by profile id. No network loading here.
  final Map<String, ImageProvider> avatarImages;

  final String source;

  @override
  State<ResultSharePreviewPage> createState() => _ResultSharePreviewPageState();
}

class _ResultSharePreviewPageState extends State<ResultSharePreviewPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  ConfirmedResultShareCard? _card;
  String? _error;
  ResultShareFormat _format = ResultShareFormat.stories;
  bool _busy = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    if (_requested && _card != null) {
      return;
    }
    _requested = true;
    if (mounted) {
      setState(() {
        _error = null;
        _card = null;
      });
    }
    try {
      final card = await widget.service.prepare(
        receipt: widget.receipt,
        viewerId: widget.viewerId,
        snapshot: widget.initialSnapshot,
        source: widget.source,
      );
      if (!mounted) {
        return;
      }
      setState(() => _card = card);
      await widget.service.trackPreviewOpened(widget.receipt, _format);
    } on ResultShareException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'The challenge link could not be prepared. Reconnect and '
            'try again.';
      });
    }
  }

  Future<void> _shareImage() async {
    final card = _card;
    if (card == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final png = await widget.capture.capturePng(
        boundaryKey: _boundaryKey,
        format: _format,
      );
      await widget.service.shareCardImage(
        card: card,
        pngBytes: png,
        format: _format,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Card shared. The link starts a new live challenge.');
    } on ResultShareException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copyLink() async {
    final card = _card;
    if (card == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.copyLink(card);
      if (!mounted) {
        return;
      }
      _showMessage('Challenge link copied. Code ${card.readableCode}');
    } on ResultShareException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _systemShare() async {
    final card = _card;
    if (card == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.shareLinkText(card);
      if (!mounted) {
        return;
      }
      _showMessage('System share opened with the link and message.');
    } on ResultShareException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ArenaColors.raised,
        content: Text(
          message,
          style: const TextStyle(color: ArenaColors.softWhite),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('result-share-preview'),
      backgroundColor: ArenaColors.charcoal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(onClose: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ArenaBattleSpace.s4,
                  0,
                  ArenaBattleSpace.s4,
                  ArenaBattleSpace.s6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Share challenge',
                      style: ArenaBattleText.h1.copyWith(
                        color: ArenaColors.softWhite,
                      ),
                    ),
                    const SizedBox(height: ArenaBattleSpace.s2),
                    const BattleBanner(
                      variant: BattleBannerVariant.info,
                      title: 'A new challenge, not a replay',
                      body: 'The link identifies you for a new live casual '
                          'battle. It never replays this match, compares old '
                          'scores or promises a rematch. Opening it is '
                          'read-only until your friend accepts.',
                    ),
                    const SizedBox(height: ArenaBattleSpace.s3),
                    _FormatToggle(
                      format: _format,
                      enabled: !_busy,
                      onChanged: (format) => setState(() => _format = format),
                    ),
                    const SizedBox(height: ArenaBattleSpace.s3),
                    if (_card != null)
                      _CardPreview(
                        boundaryKey: _boundaryKey,
                        card: _card!,
                        format: _format,
                        avatarImages: widget.avatarImages,
                      )
                    else if (_error != null)
                      BattleBanner(
                        key: const ValueKey('result-share-error'),
                        variant: BattleBannerVariant.danger,
                        title: 'Challenge link unavailable',
                        body: _error,
                        actions: [
                          BattleSecondaryButton(
                            key: const ValueKey('result-share-retry'),
                            label: 'Try again',
                            onPressed: _prepare,
                          ),
                        ],
                      )
                    else
                      const _LoadingCard(),
                    const SizedBox(height: ArenaBattleSpace.s4),
                    if (_card != null) ...[
                      Text(
                        'Identities are the receipt snapshot from match time. '
                        'A later rename does not change this card.',
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.quiet,
                        ),
                      ),
                      const SizedBox(height: ArenaBattleSpace.s3),
                      BattlePrimaryButton(
                        key: const ValueKey('result-share-primary'),
                        label: 'Share challenge',
                        large: true,
                        semanticEnabled: !_busy,
                        onPressed: _busy ? null : _shareImage,
                      ),
                      const SizedBox(height: ArenaBattleSpace.s2),
                      BattleSecondaryButton(
                        key: const ValueKey('result-share-copy'),
                        label: 'Copy challenge link',
                        block: true,
                        onPressed: _busy ? null : _copyLink,
                      ),
                      const SizedBox(height: ArenaBattleSpace.s2),
                      BattleQuietButton(
                        key: const ValueKey('result-share-system'),
                        label: 'System share',
                        block: true,
                        onPressed: _busy ? null : _systemShare,
                      ),
                      const SizedBox(height: ArenaBattleSpace.s1),
                      Text(
                        'System share sends the message and link only. Some '
                        'destination apps drop captions, so the card itself '
                        'carries the URL and QR code.',
                        style: ArenaBattleText.small.copyWith(
                          color: ArenaColors.quiet,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaBattleSpace.s2,
        ArenaBattleSpace.s1,
        ArenaBattleSpace.s4,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('result-share-close'),
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: ArenaColors.softWhite,
            tooltip: 'Close preview',
          ),
          Expanded(
            child: Text(
              'CONFIRMED RESULT · PREVIEW',
              style: ArenaBattleText.micro.copyWith(color: ArenaColors.quiet),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatToggle extends StatelessWidget {
  const _FormatToggle({
    required this.format,
    required this.enabled,
    required this.onChanged,
  });

  final ResultShareFormat format;
  final bool enabled;
  final ValueChanged<ResultShareFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('result-share-format'),
      children: [
        for (final option in ResultShareFormat.values) ...[
          Expanded(
            child: _FormatOption(
              option: option,
              selected: option == format,
              enabled: enabled,
              onPressed: () => onChanged(option),
            ),
          ),
          if (option != ResultShareFormat.values.last)
            const SizedBox(width: ArenaBattleSpace.s2),
        ],
      ],
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final ResultShareFormat option;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final border = selected ? ArenaColors.lime : ArenaColors.lineStrong;
    final labelColor =
        selected ? ArenaColors.lime : ArenaColors.softWhite;
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label} ${option.ratioLabel} export, '
          '${option.dimensionsLabel} pixels',
      child: Material(
        color: ArenaColors.raised,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaBattleSpace.s3,
              vertical: ArenaBattleSpace.s2,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(ArenaBattleSpace.radiusControl),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${option.label} ${option.ratioLabel}',
                  style: ArenaBattleText.smallStrong.copyWith(
                    color: labelColor,
                  ),
                ),
                Text(
                  '${option.pixelWidth}×${option.pixelHeight}',
                  style: ArenaBattleText.micro.copyWith(
                    color: ArenaColors.quiet,
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('result-share-loading'),
      height: 320,
      decoration: BoxDecoration(
        color: ArenaColors.graphite,
        borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusCard),
        border: Border.all(color: ArenaColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: ArenaColors.lime),
          const SizedBox(height: ArenaBattleSpace.s4),
          Text(
            'Creating your challenge link…',
            style: ArenaBattleText.body.copyWith(
              color: ArenaColors.secondary,
            ),
          ),
          const SizedBox(height: ArenaBattleSpace.s1),
          Text(
            'Nothing is created by opening this preview.',
            style: ArenaBattleText.small.copyWith(color: ArenaColors.quiet),
          ),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.boundaryKey,
    required this.card,
    required this.format,
    required this.avatarImages,
  });

  final GlobalKey boundaryKey;
  final ResultShareCard card;
  final ResultShareFormat format;
  final Map<String, ImageProvider> avatarImages;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / format.logicalWidth)
            .clamp(0.0, 1.0);
        return SizedBox(
          height: format.logicalHeight * scale,
          child: Center(
            child: SizedBox(
              width: format.logicalWidth * scale,
              height: format.logicalHeight * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: ResultShareCardView(
                    card: card,
                    format: format,
                    avatarImages: avatarImages,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
