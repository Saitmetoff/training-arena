/// Result-share orchestration: validated card creation, native share,
/// clipboard and PNG export.
///
/// Everything here consumes confirmed server data only. The service never
/// generates a token, a score, a winner or a link locally, and it refuses
/// preview fixtures at the type boundary.
library;

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../config/arena_config.dart';
import '../domain/arena_types.dart';
import '../linking/challenge_analytics.dart';
import '../linking/challenge_models.dart';
import '../linking/challenge_share.dart';
import 'result_share_models.dart';

/// Task `09` analytics events, recorded through the documented `analytics`
/// action. Properties never carry a username, token, URL, score or receipt
/// id. Opening a share sheet is never a referral.
abstract final class ResultShareAnalyticsEvent {
  /// The exact-card preview was opened for a confirmed receipt.
  static const String previewOpened = 'result_share_preview_opened';

  /// The card PNG was rendered for sharing.
  static const String cardExported = 'result_share_card_exported';

  /// The system share sheet opened with the card image.
  static const String sheetOpened = 'result_share_sheet_opened';

  /// The challenge URL was copied to the clipboard.
  static const String linkCopied = 'result_share_link_copied';

  /// The text-only system share opened.
  static const String systemShareOpened = 'result_share_system_share_opened';

  /// A share was refused because the result or link was not confirmed.
  static const String blocked = 'result_share_blocked';

  /// Rendering or opening the image share failed.
  static const String imageFailed = 'result_share_image_failed';
}

/// Loads the owner's confirmed account snapshot (profile + durable link).
abstract interface class ResultShareAccountSource {
  Future<ChallengeAccountSnapshot> load();
}

/// Production source over task `05`'s share service.
class ChallengeShareAccountSource implements ResultShareAccountSource {
  const ChallengeShareAccountSource(this._service);

  final ChallengeShareService _service;

  @override
  Future<ChallengeAccountSnapshot> load() => _service.loadSnapshot();
}

/// Platform share boundary; faked in tests.
abstract interface class ResultShareLauncher {
  /// Shares the rendered PNG with a caption. The image itself carries the
  /// URL and QR, so caption-stripping destinations stay usable.
  Future<void> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String mimeType,
    required String text,
    String? subject,
  });

  /// Text-only system share (link and message, no image).
  Future<void> shareText(String text, {String? subject});
}

/// `share_plus` implementation.
class SharePlusResultShareLauncher implements ResultShareLauncher {
  const SharePlusResultShareLauncher();

  @override
  Future<void> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String mimeType,
    required String text,
    String? subject,
  }) async {
    final file = XFile.fromData(
      pngBytes,
      name: fileName,
      mimeType: mimeType,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[file],
        text: text,
        subject: subject,
        fileNameOverrides: <String>[fileName],
      ),
    );
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}

/// Clipboard boundary; faked in tests.
abstract interface class ResultShareClipboard {
  Future<void> copy(String text);
}

/// System clipboard implementation.
class SystemResultShareClipboard implements ResultShareClipboard {
  const SystemResultShareClipboard();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

/// Captures the mounted, exact-card [RepaintBoundary] at export density.
abstract interface class ResultShareCapture {
  Future<Uint8List> capturePng({
    required GlobalKey boundaryKey,
    required ResultShareFormat format,
  });
}

/// Production capture over `RenderRepaintBoundary.toImage`.
class RepaintBoundaryResultShareCapture implements ResultShareCapture {
  const RepaintBoundaryResultShareCapture();

  @override
  Future<Uint8List> capturePng({
    required GlobalKey boundaryKey,
    required ResultShareFormat format,
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) {
      throw const ResultShareException(
        'preview_required',
        'The card preview must be visible before sharing.',
      );
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw const ResultShareException(
        'preview_required',
        'The card preview is not ready to export yet.',
      );
    }
    if (renderObject.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }
    final ui.Image image;
    try {
      image = await renderObject.toImage(
        pixelRatio: ResultShareFormat.pixelRatio,
      );
    } catch (_) {
      throw const ResultShareException(
        'export_failed',
        'The card image could not be rendered. Try again.',
      );
    }
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const ResultShareException(
          'export_failed',
          'The card image could not be encoded. Try again.',
        );
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

/// Prepares and shares confirmed result cards.
class ResultShareService {
  const ResultShareService({
    required ResultShareAccountSource account,
    required ArenaConfig config,
    required ResultShareLauncher launcher,
    required ResultShareClipboard clipboard,
    required ChallengeAnalyticsSink analytics,
  })  : _account = account,
        _config = config,
        _launcher = launcher,
        _clipboard = clipboard,
        _analytics = analytics;

  final ResultShareAccountSource _account;
  final ArenaConfig _config;
  final ResultShareLauncher _launcher;
  final ResultShareClipboard _clipboard;
  final ChallengeAnalyticsSink _analytics;

  /// Loads the owner's link/profile, mapping transport failures to factual
  /// card copy. A cached [ChallengeAccountSnapshot] can be passed so an
  /// already confirmed link works offline; nothing is invented when it is
  /// missing.
  Future<ChallengeAccountSnapshot> loadAccount({
    ChallengeAccountSnapshot? snapshot,
    String source = 'result',
  }) async {
    if (snapshot != null) {
      return snapshot;
    }
    try {
      return await _account.load();
    } on ChallengeShareException catch (error) {
      await _analytics.track(
        ResultShareAnalyticsEvent.blocked,
        <String, Object?>{'source': source, 'reason': error.code},
      );
      throw ResultShareException(error.code, error.message);
    } on ResultShareException {
      rethrow;
    } catch (_) {
      await _analytics.track(
        ResultShareAnalyticsEvent.blocked,
        <String, Object?>{'source': source, 'reason': 'link_unavailable'},
      );
      throw const ResultShareException(
        'link_unavailable',
        'Your challenge link could not be loaded. Reconnect and try again.',
      );
    }
  }

  /// Builds the only shareable card type. Throws [ResultShareException] with
  /// factual copy when the receipt or link is not confirmed.
  Future<ConfirmedResultShareCard> prepare({
    required ResultReceipt receipt,
    required String viewerId,
    ChallengeAccountSnapshot? snapshot,
    String source = 'result',
  }) async {
    validateResultReceipt(receipt: receipt, viewerId: viewerId);
    final account = await loadAccount(snapshot: snapshot, source: source);
    return confirmResultShareCard(
      receipt: receipt,
      viewerId: viewerId,
      account: account,
      config: _config,
    );
  }

  /// Renders and shares the exact preview card as a PNG plus caption.
  Future<void> shareCardImage({
    required ConfirmedResultShareCard card,
    required Uint8List pngBytes,
    required ResultShareFormat format,
  }) async {
    await _analytics.track(
      ResultShareAnalyticsEvent.cardExported,
      _properties(card, format),
    );
    try {
      await _launcher.shareImage(
        pngBytes: pngBytes,
        fileName: _fileName(card, format),
        mimeType: 'image/png',
        text: card.caption,
        subject: 'Fault challenge',
      );
    } catch (_) {
      await _analytics.track(
        ResultShareAnalyticsEvent.imageFailed,
        _properties(card, format),
      );
      throw const ResultShareException(
        'share_failed',
        'The share sheet could not be opened, so nothing was shared. The '
            'card is still visible in the preview.',
      );
    }
    await _analytics.track(
      ResultShareAnalyticsEvent.sheetOpened,
      _properties(card, format),
    );
  }

  /// Copies the real challenge URL; the readable code stays visible in the
  /// card. Returns the copied text so the UI can show the code in a snackbar.
  Future<String> copyLink(ConfirmedResultShareCard card) async {
    final text = card.copyText;
    try {
      await _clipboard.copy(text);
    } catch (_) {
      throw const ResultShareException(
        'copy_failed',
        'The link could not be copied. Select the URL from the card instead.',
      );
    }
    await _analytics.track(
      ResultShareAnalyticsEvent.linkCopied,
      <String, Object?>{
        'mode': card.analyticsMode,
        'outcome': card.analyticsOutcome,
      },
    );
    return text;
  }

  /// Opens the platform share sheet with the caption and link only.
  Future<void> shareLinkText(ConfirmedResultShareCard card) async {
    try {
      await _launcher.shareText(
        card.caption,
        subject: 'Fault challenge',
      );
    } catch (_) {
      throw const ResultShareException(
        'share_failed',
        'The share sheet could not be opened. Copy the link instead.',
      );
    }
    await _analytics.track(
      ResultShareAnalyticsEvent.systemShareOpened,
      <String, Object?>{
        'mode': card.analyticsMode,
        'outcome': card.analyticsOutcome,
      },
    );
  }

  /// Records that the exact-card preview opened. Never a referral.
  Future<void> trackPreviewOpened(
    ResultReceipt receipt,
    ResultShareFormat format,
  ) {
    return _analytics.track(
      ResultShareAnalyticsEvent.previewOpened,
      <String, Object?>{
        'mode': receipt.mode.wire,
        'outcome': receipt.outcome.wire,
        'format': format.name,
      },
    );
  }

  /// Records a refused share without any identity or link data.
  Future<void> trackBlocked(String reason) {
    return _analytics.track(
      ResultShareAnalyticsEvent.blocked,
      <String, Object?>{'source': 'result', 'reason': reason},
    );
  }

  Map<String, Object?> _properties(
    ConfirmedResultShareCard card,
    ResultShareFormat format,
  ) =>
      <String, Object?>{
        'mode': card.analyticsMode,
        'outcome': card.analyticsOutcome,
        'format': format.name,
      };

  String _fileName(ConfirmedResultShareCard card, ResultShareFormat format) =>
      'fault-challenge-${card.analyticsOutcome}-${format.name}.png';
}
