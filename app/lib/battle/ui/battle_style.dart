/// Typography and spacing helpers for the battle surfaces.
///
/// Colors come from [ArenaColors] only (single token file); these styles add
/// the task-01 type scale and numeric treatment without introducing a second
/// visual system.
library;

import 'package:flutter/widgets.dart';

import '../../theme/arena_tokens.dart';

/// Battle type scale from `design/arena/tokens.json`.
abstract final class ArenaBattleText {
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle display = TextStyle(
    fontSize: 72,
    height: 0.9,
    fontWeight: FontWeight.w900,
    letterSpacing: -2.16,
    fontFeatures: _tabular,
  );

  static const TextStyle score = TextStyle(
    fontSize: 52,
    height: 0.95,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.04,
    fontFeatures: _tabular,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.68,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.24,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle smallStrong = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.96,
  );
}

/// Spacing and radius scale from `design/arena/tokens.json`.
abstract final class ArenaBattleSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;

  static const double radiusSmall = 10;
  static const double radiusControl = 14;
  static const double radiusCard = 20;

  static const EdgeInsets cardPadding = EdgeInsets.all(s5);
  static const EdgeInsets screenGutter = EdgeInsets.symmetric(
    horizontal: s4,
    vertical: s3,
  );

  /// Minimum touch target from the design system.
  static const double minTarget = 48;
}

/// Convenience text styles tinted with contract colors.
abstract final class BattleInkColors {
  static const Color primary = ArenaColors.softWhite;
  static const Color secondary = ArenaColors.secondary;
  static const Color quiet = ArenaColors.quiet;
}

/// Formats a request expiry as a short factual countdown.
String formatBattleCountdown(DateTime? until) {
  if (until == null) {
    return '24 hours';
  }
  final remaining = until.difference(DateTime.now());
  if (remaining.isNegative) {
    return 'expired';
  }
  if (remaining.inHours >= 1) {
    final minutes = remaining.inMinutes % 60;
    return '${remaining.inHours} h $minutes min';
  }
  return '${remaining.inMinutes} min';
}
