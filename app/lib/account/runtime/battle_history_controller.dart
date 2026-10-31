/// Battle history state.
///
/// The history list is exactly the confirmed receipts the server returns.
/// Casual receipts carry no rating change and no result is ever derived or
/// optimistically added on the client.
library;

import 'package:flutter/foundation.dart';

import '../../domain/arena_types.dart';
import '../data/account_api.dart';
import '../models/account_models.dart';
import 'leaderboard_controller.dart' show AccountLoadStatus;

/// Loads and holds the viewer's confirmed receipts.
class BattleHistoryController extends ChangeNotifier {
  BattleHistoryController({required AccountApi api}) : _api = api;

  final AccountApi _api;

  AccountLoadStatus _status = AccountLoadStatus.initial;
  List<ResultReceipt> _receipts = const <ResultReceipt>[];
  String? _message;
  bool _loading = false;

  AccountLoadStatus get status => _status;

  /// Confirmed receipts only, newest first.
  List<ResultReceipt> get receipts => List.unmodifiable(_receipts);

  String? get message => _message;

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
      final receipts = await _api.history();
      _receipts = receipts;
      _status = receipts.isEmpty
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

  void reset() {
    _receipts = const <ResultReceipt>[];
    _status = AccountLoadStatus.initial;
    _message = null;
    notifyListeners();
  }
}
