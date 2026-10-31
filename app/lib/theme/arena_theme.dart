import 'package:flutter/material.dart';

import 'arena_tokens.dart';

/// Builds the Training Arena dark theme from [ArenaColors].
///
/// Task 01 owns the full visual system; the baseline only fixes the
/// contract colors, the charcoal background and the lime primary action.
abstract final class ArenaTheme {
  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: ArenaColors.lime,
      onPrimary: ArenaColors.charcoal,
      secondary: ArenaColors.violet,
      onSecondary: ArenaColors.charcoal,
      error: ArenaColors.danger,
      onError: ArenaColors.charcoal,
      surface: ArenaColors.graphite,
      onSurface: ArenaColors.softWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ArenaColors.charcoal,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: ArenaColors.charcoal,
        foregroundColor: ArenaColors.softWhite,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ArenaColors.graphite,
        indicatorColor: ArenaColors.lime,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? ArenaColors.lime : ArenaColors.quiet,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? ArenaColors.charcoal : ArenaColors.secondary,
            size: 24,
          );
        }),
      ),
    );
  }
}
