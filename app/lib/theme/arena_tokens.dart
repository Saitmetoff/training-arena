import 'package:flutter/material.dart';

/// Single source of truth for Training Arena colors.
///
/// Every Dart surface must read colors from here; the native splash in
/// `android/app/src/main/res/values/colors.xml` mirrors `charcoal` only.
/// Changing a token is a product-contract change (see `docs/CONTRACT.md`).
abstract final class ArenaColors {
  /// App background.
  static const Color charcoal = Color(0xFF17191A);

  /// Cards and navigation surfaces.
  static const Color graphite = Color(0xFF242729);

  /// Raised elements such as sheets and chips.
  static const Color raised = Color(0xFF303537);

  /// Decorative 1px dividers; no contrast claim.
  static const Color line = Color(0xFF3B4245);

  /// Control and input boundaries; stays at or above 3:1.
  static const Color lineStrong = Color(0xFF6F787A);

  /// Current player and primary action.
  static const Color lime = Color(0xFFD6FF3F);

  /// Text and icons on lime/player surfaces.
  static const Color playerInk = Color(0xFF17191A);

  /// Background wash for the signed-in player's panels.
  static const Color playerWash = Color(0xFF2A2F1B);

  /// Opponent identity.
  static const Color violet = Color(0xFFBEA1FF);

  /// Text and icons on violet/opponent surfaces.
  static const Color opponentInk = Color(0xFF17191A);

  /// Background wash for the opponent's panels.
  static const Color opponentWash = Color(0xFF2B2637);

  /// Primary text.
  static const Color softWhite = Color(0xFFF6F7F2);

  /// Secondary text.
  static const Color secondary = Color(0xFFB6BDB9);

  /// Quiet/disabled text.
  static const Color quiet = Color(0xFF9BA59E);

  /// Positive states (ready, win).
  static const Color positive = Color(0xFF7AE5A0);

  /// Warning states.
  static const Color warning = Color(0xFFFFD66E);

  /// Errors and destructive actions.
  static const Color danger = Color(0xFFFF807C);

  /// Focus ring.
  static const Color focus = Color(0xFFF6F7F2);

  /// Modal and sheet scrim (0.78 charcoal).
  static const Color overlay = Color(0xC717191A);
}
