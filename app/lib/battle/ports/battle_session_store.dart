/// Persistence seam for the active match id.
///
/// The battle controller writes the id when a match is created and clears it
/// once the server confirms a terminal outcome. The platform store below
/// keeps the id across process death; tests use
/// [InMemoryBattleSessionStore] or the SharedPreferences mock.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Stores the active match id across lifecycle/process changes.
abstract interface class BattleSessionStore {
  Future<String?> readActiveMatchId();

  Future<void> writeActiveMatchId(String? matchId);
}

/// Default in-memory store; correct within one process.
class InMemoryBattleSessionStore implements BattleSessionStore {
  String? _activeMatchId;

  @override
  Future<String?> readActiveMatchId() async => _activeMatchId;

  @override
  Future<void> writeActiveMatchId(String? matchId) async {
    _activeMatchId = matchId;
  }
}

/// SharedPreferences-backed store with a memory fallback so hosts without
/// the platform channel (tests, previews) keep working.
class SharedPreferencesBattleSessionStore implements BattleSessionStore {
  SharedPreferencesBattleSessionStore({BattleSessionStore? fallback})
      : _fallback = fallback ?? InMemoryBattleSessionStore();

  static const String activeMatchKey = 'arena.active_match_id.v1';

  final BattleSessionStore _fallback;
  SharedPreferences? _prefs;
  bool _prefsUnavailable = false;

  Future<SharedPreferences?> _open() async {
    if (_prefsUnavailable) {
      return null;
    }
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      return prefs;
    } catch (_) {
      _prefsUnavailable = true;
      return null;
    }
  }

  @override
  Future<String?> readActiveMatchId() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.readActiveMatchId();
    }
    return prefs.getString(activeMatchKey);
  }

  @override
  Future<void> writeActiveMatchId(String? matchId) async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.writeActiveMatchId(matchId);
    }
    if (matchId == null || matchId.isEmpty) {
      await prefs.remove(activeMatchKey);
    } else {
      await prefs.setString(activeMatchKey, matchId);
    }
  }
}
