/// QR generation for result share cards.
///
/// The QR always encodes the same real challenge URL printed on the card
/// (`https://<host>/c/<token>`). Generation is deterministic: the same URL
/// produces the same module matrix, which the export tests pin. Validation
/// reuses [ChallengeLink] so an unrelated or malformed URL can never be
/// painted into artwork.
library;

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../linking/challenge_link.dart';
import '../theme/arena_tokens.dart';
import 'result_share_models.dart';

/// Error-correction level fixed for share cards. Level M tolerates damaged
/// prints and keeps the modules readable at feed sizes.
const int resultShareQrErrorCorrectLevel = QrErrorCorrectLevel.M;

/// Quiet zone required by QR scanners, in modules (ISO/IEC 18004).
const int resultShareQrQuietZoneModules = 4;

/// A validated, deterministic QR matrix.
class ResultShareQr {
  const ResultShareQr._(this.url, this.modules);

  /// The exact URL the QR opens; identical to the visible link.
  final Uri url;

  /// `modules[row][col]` is true for dark modules.
  final List<List<bool>> modules;

  int get moduleCount => modules.length;

  bool isDark(int row, int col) => modules[row][col];

  /// Builds the matrix for a challenge URL, validating the URL first.
  ///
  /// [expectedHost] is the configured `ARENA_LINK_HOST`; a URL on another
  /// host is rejected so a foreign link cannot be painted into a card.
  static ResultShareQr fromUrl(Uri url, {String? expectedHost}) {
    final parsed = ChallengeLink.tryParse(url, expectedHost: expectedHost);
    if (parsed == null || url.scheme != 'https') {
      throw const ResultShareException(
        'invalid_link',
        'The card link is not a valid arena challenge URL, so no QR was '
            'created.',
      );
    }
    try {
      final code = QrCode.fromData(
        data: url.toString(),
        errorCorrectLevel: resultShareQrErrorCorrectLevel,
      );
      final image = QrImage(code);
      final size = image.moduleCount;
      final modules = List<List<bool>>.generate(
        size,
        (row) => List<bool>.generate(size, (col) => image.isDark(row, col)),
        growable: false,
      );
      return ResultShareQr._(url, modules);
    } catch (_) {
      throw const ResultShareException(
        'qr_failed',
        'The QR code for the challenge link could not be created. Copy the '
            'link instead.',
      );
    }
  }
}

/// Paints a [ResultShareQr] on the light artwork tile.
class ResultShareQrPainter extends CustomPainter {
  const ResultShareQrPainter(
    this.qr, {
    this.background = ArenaColors.softWhite,
    this.moduleColor = ArenaColors.charcoal,
    this.quietZoneModules = resultShareQrQuietZoneModules,
  });

  final ResultShareQr qr;
  final Color background;
  final Color moduleColor;
  final int quietZoneModules;

  @override
  void paint(Canvas canvas, Size size) {
    final totalModules = qr.moduleCount + quietZoneModules * 2;
    final moduleSize = size.shortestSide / totalModules;
    final backgroundPaint = Paint()..color = background;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final modulePaint = Paint()..color = moduleColor;
    for (var row = 0; row < qr.moduleCount; row++) {
      for (var col = 0; col < qr.moduleCount; col++) {
        if (!qr.isDark(row, col)) {
          continue;
        }
        final left = (col + quietZoneModules) * moduleSize;
        final top = (row + quietZoneModules) * moduleSize;
        canvas.drawRect(
          Rect.fromLTWH(left, top, moduleSize, moduleSize),
          modulePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ResultShareQrPainter oldDelegate) =>
      !identical(oldDelegate.qr, qr) ||
      oldDelegate.background != background ||
      oldDelegate.moduleColor != moduleColor ||
      oldDelegate.quietZoneModules != quietZoneModules;
}

/// QR block with an accessible label; the visible URL sits next to it.
class ResultShareQrView extends StatelessWidget {
  const ResultShareQrView({
    super.key,
    required this.qr,
    required this.size,
    this.semanticLabel,
  });

  final ResultShareQr qr;
  final double size;

  /// Full alt text; defaults to the URL-carrying label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel ??
          'QR code that opens the live challenge ${qr.url}',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            size: Size.square(size),
            painter: ResultShareQrPainter(qr),
          ),
        ),
      ),
    );
  }
}
