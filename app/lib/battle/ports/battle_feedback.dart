/// Native cues used by the battle runtime.
///
/// Haptics and screen-reader announcements go through this port so tests can
/// record them and hosts without a native surface stay silent but correct.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Cue methods for countdown, live thresholds and results.
abstract interface class BattleFeedback {
  void countdownTick(int secondsLeft);

  void roundStarted();

  void finalTenSeconds();

  void finalThreeSeconds();

  void trackingLost();

  void trackingRestored();

  void warning();

  void resultConfirmed();

  void tap();

  /// Polite announcement for screen readers.
  void announce(String message);
}

/// Default implementation: `HapticFeedback` plus `SemanticsService`.
class NativeBattleFeedback implements BattleFeedback {
  const NativeBattleFeedback();

  @override
  void countdownTick(int secondsLeft) {
    HapticFeedback.selectionClick();
  }

  @override
  void roundStarted() {
    HapticFeedback.mediumImpact();
  }

  @override
  void finalTenSeconds() {
    HapticFeedback.lightImpact();
  }

  @override
  void finalThreeSeconds() {
    HapticFeedback.mediumImpact();
  }

  @override
  void trackingLost() {
    HapticFeedback.heavyImpact();
  }

  @override
  void trackingRestored() {
    HapticFeedback.selectionClick();
  }

  @override
  void warning() {
    HapticFeedback.heavyImpact();
  }

  @override
  void resultConfirmed() {
    HapticFeedback.mediumImpact();
  }

  @override
  void tap() {
    HapticFeedback.selectionClick();
  }

  @override
  void announce(String message) {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return;
    }
    SemanticsService.sendAnnouncement(views.first, message, TextDirection.ltr);
  }
}

/// No-op feedback for previews and non-native hosts.
class SilentBattleFeedback implements BattleFeedback {
  const SilentBattleFeedback();

  @override
  void countdownTick(int secondsLeft) {}

  @override
  void roundStarted() {}

  @override
  void finalTenSeconds() {}

  @override
  void finalThreeSeconds() {}

  @override
  void trackingLost() {}

  @override
  void trackingRestored() {}

  @override
  void warning() {}

  @override
  void resultConfirmed() {}

  @override
  void tap() {}

  @override
  void announce(String message) {}
}
