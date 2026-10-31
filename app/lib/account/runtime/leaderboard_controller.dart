/// Leaderboard state.
///
/// Rows are exactly what the `leaderboard` action confirmed: the server's top
/// page plus the viewer's own row when outside it. A failed refresh never
/// invents, reorders or rerates a row — it keeps the last confirmed page and
/// reports the failure with a retry.
library;

import 'package:flutter/foundation.dart';

import '../data/account_api.dart';
import '../models/account_models.dart';

/// Shared loading state for account lists.
enum AccountLoadStatus {
  initial,
  loading,
  ready,
  empty,
  offline,
  error,
  unconfigured,
}

/// Loads and holds the ranked ladder.
class LeaderboardController extends ChangeNotifier {
  LeaderboardController({
    required AccountApi api,
    String? Function()? viewerId,
  })  : _api = api,
        _viewerId = viewerId ?? (() => null);

  static const int topPageSize = 100;

  final AccountApi _api;
  final String? Function() _viewerId;

  AccountLoadStatus _status = AccountLoadStatus.initial;
  List<ArenaLeaderboardEntry> _entries = const <ArenaLeaderboardEntry>[];
  String? _message;
  bool _loading = false;

  AccountLoadStatus get status => _status;

  /// Last server-confirmed rows, newest load only.
  List<ArenaLeaderboardEntry> get entries => List.unmodifiable(_entries);

  String? get message => _message;

  String? get viewerId => _viewerId();

  /// The viewer's row from the server page, or null when unranked.
  ArenaLeaderboardEntry? get viewerEntry {
    final id = _viewerId();
    if (id == null) {
      return null;
    }
    for (final entry in _entries) {
      if (entry.isViewer(id)) {
        return entry;
      }
    }
    return null;
  }

  /// True when the server appended the viewer below the top page.
  bool get viewerOutsideTopPage {
    final entry = viewerEntry;
    return entry != null && entry.rank > topPageSize;
  }

  Future<void> load({bool force = false}) async {
    if (_loading) {
      return;
    }
    if (!force && _status == AccountLoadStatus.ready) {
      return;
    }
    _loading = true;
    _status = AccountLoadStatus.loading;
    _message = null;
    notifyListeners();
    try {
      final entries = await _api.leaderboard();
      _entries = entries;
      _status = entries.isEmpty
          ? AccountLoadStatus.empty
          : AccountLoadStatus.ready;
    } on AccountException catch (error) {
      _status = error.code == 'unconfigured'
          ? AccountLoadStatus.unconfigured
          : error.isRetryable
              ? AccountLoadStatus.offline
              : AccountLoadStatus.error;
      _message = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clears state on sign-out so a new account never sees the old ladder.
  void reset() {
    _entries = const <ArenaLeaderboardEntry>[];
    _status = AccountLoadStatus.initial;
    _message = null;
    notifyListeners();
  }
}
