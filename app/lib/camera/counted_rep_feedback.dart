import 'package:flutter/services.dart';

/// Non-blocking platform feedback. A missing cue never changes the count.
Future<void> playCountedRepCue() async {
  await Future.wait<void>([
    SystemSound.play(SystemSoundType.click).catchError((Object _) {}),
    HapticFeedback.lightImpact().catchError((Object _) {}),
  ]);
}
