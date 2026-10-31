/// Durable pending-challenge state.
///
/// A pending challenge survives auth redirects, process restarts and install
/// recovery. It is cleared only by an explicit accept-into-match, an explicit
/// decline/cancel, or an unrecoverable expiry — never by closing a screen.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/arena_types.dart';
import 'challenge_link.dart';
import 'challenge_models.dart';

/// Everything the app must remember about an in-progress challenge.
class PendingChallengeState {
  const PendingChallengeState({
    required this.token,
    this.sender,
    this.requestId,
    this.requestStatus,
    this.matchId,
    this.receivedAt,
    this.expiresAt,
    this.source,
  });

  final String token;

  /// Resolved challenger identity; null until `resolve_link` succeeds.
  final ArenaProfile? sender;

  /// Set after this device sent its request.
  final String? requestId;

  final ChallengeRequestStatus? requestStatus;

  /// Set once mutual acceptance created a match.
  final String? matchId;

  final DateTime? receivedAt;

  /// Server request expiry (24 hours after send).
  final DateTime? expiresAt;

  final ChallengeLinkSource? source;

  /// A stored request that expired before any match exists.
  bool isExpired(DateTime now) {
    final expiry = expiresAt;
    return matchId == null &&
        requestId != null &&
        expiry != null &&
        !now.isBefore(expiry);
  }

  bool get hasRequest => requestId != null;

  PendingChallengeState copyWith({
    String? token,
    ArenaProfile? sender,
    String? requestId,
    ChallengeRequestStatus? requestStatus,
    String? matchId,
    DateTime? receivedAt,
    DateTime? expiresAt,
    ChallengeLinkSource? source,
  }) {
    return PendingChallengeState(
      token: token ?? this.token,
      sender: sender ?? this.sender,
      requestId: requestId ?? this.requestId,
      requestStatus: requestStatus ?? this.requestStatus,
      matchId: matchId ?? this.matchId,
      receivedAt: receivedAt ?? this.receivedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      source: source ?? this.source,
    );
  }

  /// Domain view consumed by later battle/account tasks.
  ChallengeContext toContext() => ChallengeContext(
        token: token,
        sender: sender,
        matchId: matchId,
        receivedAt: receivedAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'token': token,
        if (sender != null) 'sender': _profileToJson(sender!),
        if (requestId != null) 'request_id': requestId,
        if (requestStatus != null) 'request_status': requestStatus!.wire,
        if (matchId != null) 'match_id': matchId,
        if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (source != null) 'source': source!.wire,
      };

  static PendingChallengeState? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final token = value['token']?.toString();
    if (token == null || token.isEmpty) {
      return null;
    }
    return PendingChallengeState(
      token: token,
      sender: _profileFromJson(value['sender']),
      requestId: value['request_id']?.toString(),
      requestStatus: ChallengeRequestStatus.tryFromWire(value['request_status']),
      matchId: value['match_id']?.toString(),
      receivedAt: _dateTime(value['received_at']),
      expiresAt: _dateTime(value['expires_at']),
      source: _sourceFromWire(value['source']),
    );
  }

  static Map<String, Object?> _profileToJson(ArenaProfile profile) =>
      <String, Object?>{
        'id': profile.id,
        if (profile.username != null) 'username': profile.username,
        if (profile.avatarUrl != null) 'avatar_url': profile.avatarUrl,
        'rating': profile.rating,
        'ranked_wins': profile.rankedWins,
        'ranked_battles': profile.rankedBattles,
      };

  static ArenaProfile? _profileFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }
    return ArenaProfile(
      id: id,
      username: value['username']?.toString(),
      avatarUrl: value['avatar_url']?.toString(),
      rating: _int(value['rating']) ?? arenaStartingRating,
      rankedWins: _int(value['ranked_wins']) ?? 0,
      rankedBattles: _int(value['ranked_battles']) ?? 0,
    );
  }

  static ChallengeLinkSource? _sourceFromWire(Object? value) {
    for (final source in ChallengeLinkSource.values) {
      if (source.wire == value) {
        return source;
      }
    }
    return null;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

/// Storage used by the landing flows and tests.
abstract class ChallengePersistence {
  Future<PendingChallengeState?> readPending();

  Future<void> writePending(PendingChallengeState state);

  Future<void> clearPending();

  /// True once this install's Play Install Referrer was consumed.
  Future<bool> isInstallReferrerHandled();

  Future<void> markInstallReferrerHandled();
}

/// Deterministic in-memory store; the fallback when platform storage is not
/// available and the primary store in tests.
class MemoryChallengePersistence implements ChallengePersistence {
  PendingChallengeState? _pending;
  bool _referrerHandled = false;

  @override
  Future<PendingChallengeState?> readPending() async => _pending;

  @override
  Future<void> writePending(PendingChallengeState state) async {
    _pending = state;
  }

  @override
  Future<void> clearPending() async {
    _pending = null;
  }

  @override
  Future<bool> isInstallReferrerHandled() async => _referrerHandled;

  @override
  Future<void> markInstallReferrerHandled() async {
    _referrerHandled = true;
  }
}

/// SharedPreferences-backed store with a memory fallback so the shell keeps
/// working when the platform channel is unavailable (tests, previews).
class SharedPreferencesChallengePersistence implements ChallengePersistence {
  SharedPreferencesChallengePersistence({MemoryChallengePersistence? fallback})
      : _fallback = fallback ?? MemoryChallengePersistence();

  static const String pendingKey = 'arena.pending_challenge.v1';
  static const String referrerHandledKey = 'arena.install_referrer.v1';

  final MemoryChallengePersistence _fallback;
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
  Future<PendingChallengeState?> readPending() async {
    final prefs = await _open();
    final raw = prefs?.getString(pendingKey);
    if (raw == null) {
      return _fallback.readPending();
    }
    try {
      return PendingChallengeState.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writePending(PendingChallengeState state) async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.writePending(state);
    }
    await prefs.setString(pendingKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clearPending() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.clearPending();
    }
    await prefs.remove(pendingKey);
  }

  @override
  Future<bool> isInstallReferrerHandled() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.isInstallReferrerHandled();
    }
    return prefs.getBool(referrerHandledKey) ?? false;
  }

  @override
  Future<void> markInstallReferrerHandled() async {
    final prefs = await _open();
    if (prefs == null) {
      return _fallback.markInstallReferrerHandled();
    }
    await prefs.setBool(referrerHandledKey, true);
  }
}
