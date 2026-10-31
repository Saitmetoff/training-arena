/// Persistence seam for local solo set history.
///
/// Solo results are device-local and non-competitive. The platform store
/// keeps the newest [soloResultHistoryLimit] entries; tests use
/// [InMemorySoloResultStore] or the SharedPreferences mock.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/solo_result.dart';

/// Oldest entries beyond this limit are dropped on write.
const int soloResultHistoryLimit = 100;

List<SoloSetResult> trimSoloResults(List<SoloSetResult> results) =>
    results.length <= soloResultHistoryLimit
        ? List<SoloSetResult>.of(results)
        : results.sublist(0, soloResultHistoryLimit);

abstract interface class SoloResultStore {
  Future<List<SoloSetResult>> read();

  Future<void> write(List<SoloSetResult> results);
}

/// Default in-memory store; correct within one process.
class InMemorySoloResultStore implements SoloResultStore {
  InMemorySoloResultStore([List<SoloSetResult>? initial])
      : _results = List<SoloSetResult>.of(initial ?? const <SoloSetResult>[]);

  List<SoloSetResult> _results;

  @override
  Future<List<SoloSetResult>> read() async =>
      List<SoloSetResult>.unmodifiable(_results);

  @override
  Future<void> write(List<SoloSetResult> results) async {
    _results = trimSoloResults(results);
  }
}

/// Durable device storage. A failed write must not look like a saved set.
class SharedPreferencesSoloResultStore implements SoloResultStore {
  static const String resultsKey = 'arena.solo.results.v1';

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
  Future<List<SoloSetResult>> read() async {
    final prefs = await _open();
    if (prefs == null) {
      throw StateError('Persistent solo storage is unavailable');
    }
    final raw = prefs.getStringList(resultsKey) ?? const <String>[];
    final results = <SoloSetResult>[];
    for (final entry in raw) {
      try {
        final parsed = SoloSetResult.tryFromJson(jsonDecode(entry));
        if (parsed != null) {
          results.add(parsed);
        }
      } catch (_) {
        // Corrupt entry: skip it rather than losing the whole history.
      }
    }
    return results;
  }

  @override
  Future<void> write(List<SoloSetResult> results) async {
    final prefs = await _open();
    if (prefs == null) {
      throw StateError('Persistent solo storage is unavailable');
    }
    final encoded = trimSoloResults(results)
        .map((result) => jsonEncode(result.toJson()))
        .toList(growable: false);
    if (!await prefs.setStringList(resultsKey, encoded)) {
      throw StateError('Solo history was not saved');
    }
  }
}
