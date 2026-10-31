/// Persists whether the in-context notification prompt was shown.
///
/// The prompt is shown once, when the user first sends or receives a
/// challenge request. Remembering the answer means a second request never
/// nags; a denial keeps the in-app request authoritative and usable.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Storage seam for the "asked once" flag.
abstract interface class NotificationPermissionStore {
  Future<bool> hasAsked();

  Future<void> markAsked();
}

/// `shared_preferences` implementation (best effort; failures mean "ask").
class SharedPreferencesNotificationPermissionStore
    implements NotificationPermissionStore {
  static const String storageKey = 'arena.notifications.permission_asked';

  @override
  Future<bool> hasAsked() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(storageKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markAsked() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(storageKey, true);
    } catch (_) {
      // Losing the flag at worst asks once more; never fatal.
    }
  }
}

/// In-memory store for tests and previews.
class InMemoryNotificationPermissionStore
    implements NotificationPermissionStore {
  InMemoryNotificationPermissionStore({bool asked = false}) : _asked = asked;

  bool _asked;

  @override
  Future<bool> hasAsked() async => _asked;

  @override
  Future<void> markAsked() async => _asked = true;
}
