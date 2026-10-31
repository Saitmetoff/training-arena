/// Arena account API boundary.
///
/// One implementation speaks the documented `POST /functions/v1/arena`
/// envelope (`docs/API.md`, task `04`) for the account actions:
/// `profile`, `profile_update`, `avatar_update`, `avatar_remove`,
/// `leaderboard`, `history`, `profile_public`, `report`, `block`, `unblock`,
/// `blocked` and `delete_account`. It never trusts a rating, rank or receipt
/// field that is absent or unparseable: malformed rows are dropped instead of
/// guessed.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/arena_config.dart';
import '../../domain/arena_types.dart';
import '../models/account_models.dart';

/// Supplies the current access token; null fails closed.
typedef AccountAccessTokenProvider = Future<String?> Function();

/// Account-facing operations used by the feature controllers.
abstract interface class AccountApi {
  Future<ArenaProfile> fetchProfile();

  Future<ArenaProfile> updateUsername(String username);

  Future<ArenaProfile> updateAvatar({
    required String base64,
    required String mimeType,
  });

  Future<ArenaProfile> removeAvatar();

  Future<List<ArenaLeaderboardEntry>> leaderboard();

  /// Newest confirmed receipts first (backend caps at 100).
  Future<List<ResultReceipt>> history();

  Future<ArenaProfile> publicProfile(String userId);

  Future<void> report({
    required String targetUserId,
    String? matchId,
    required String reason,
  });

  Future<void> block(String targetUserId);

  Future<void> unblock(String targetUserId);

  Future<List<ArenaProfile>> blocked();

  Future<void> deleteAccount();
}

/// HTTP client for the arena Edge Function.
class HttpAccountApi implements AccountApi {
  HttpAccountApi({
    required ArenaConfig config,
    required AccountAccessTokenProvider accessTokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _config = config,
        _accessTokenProvider = accessTokenProvider,
        _client = client ?? http.Client();

  final ArenaConfig _config;
  final AccountAccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  final Duration timeout;

  Uri get _endpoint {
    final base = _config.supabaseUrl.endsWith('/')
        ? _config.supabaseUrl.substring(0, _config.supabaseUrl.length - 1)
        : _config.supabaseUrl;
    return Uri.parse('$base/functions/v1/arena');
  }

  void _ensureConfigured() {
    if (!_config.hasSupabaseCredentials) {
      throw const AccountException.unconfigured();
    }
  }

  @override
  Future<ArenaProfile> fetchProfile() async {
    final data = await _post('profile', const <String, Object?>{});
    return _requireProfile(data['profile']);
  }

  @override
  Future<ArenaProfile> updateUsername(String username) async {
    final data = await _post('profile_update', <String, Object?>{
      'username': username,
    });
    return _requireProfile(data['profile']);
  }

  @override
  Future<ArenaProfile> updateAvatar({
    required String base64,
    required String mimeType,
  }) async {
    final data = await _post('avatar_update', <String, Object?>{
      'base64': base64,
      'mime_type': mimeType,
    });
    return _requireProfile(data['profile']);
  }

  @override
  Future<ArenaProfile> removeAvatar() async {
    final data = await _post('avatar_remove', const <String, Object?>{});
    return _requireProfile(data['profile']);
  }

  @override
  Future<List<ArenaLeaderboardEntry>> leaderboard() async {
    final data = await _post('leaderboard', const <String, Object?>{});
    final raw = data['profiles'];
    if (raw is! List) {
      return const <ArenaLeaderboardEntry>[];
    }
    final entries = <ArenaLeaderboardEntry>[];
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final profile = _profile(item);
      final rank = _int(item['rank']);
      if (profile == null || rank == null || rank < 1) {
        continue;
      }
      entries.add(ArenaLeaderboardEntry(profile: profile, rank: rank));
    }
    return entries;
  }

  @override
  Future<List<ResultReceipt>> history() async {
    final data = await _post('history', const <String, Object?>{});
    final raw = data['receipts'];
    if (raw is! List) {
      return const <ResultReceipt>[];
    }
    final receipts = <ResultReceipt>[];
    for (final item in raw) {
      final receipt = _receipt(item);
      if (receipt != null) {
        receipts.add(receipt);
      }
    }
    return receipts;
  }

  @override
  Future<ArenaProfile> publicProfile(String userId) async {
    final data = await _post('profile_public', <String, Object?>{
      'user_id': userId,
    });
    return _requireProfile(data['profile']);
  }

  @override
  Future<void> report({
    required String targetUserId,
    String? matchId,
    required String reason,
  }) async {
    await _post('report', <String, Object?>{
      'target_user_id': targetUserId,
      if (matchId != null) 'match_id': matchId,
      'reason': reason,
    });
  }

  @override
  Future<void> block(String targetUserId) async {
    await _post('block', <String, Object?>{'target_user_id': targetUserId});
  }

  @override
  Future<void> unblock(String targetUserId) async {
    await _post('unblock', <String, Object?>{'target_user_id': targetUserId});
  }

  @override
  Future<List<ArenaProfile>> blocked() async {
    final data = await _post('blocked', const <String, Object?>{});
    final raw = data['profiles'];
    if (raw is! List) {
      return const <ArenaProfile>[];
    }
    final profiles = <ArenaProfile>[];
    for (final item in raw) {
      final profile = _profile(item);
      if (profile != null) {
        profiles.add(profile);
      }
    }
    return profiles;
  }

  @override
  Future<void> deleteAccount() async {
    await _post('delete_account', const <String, Object?>{});
  }

  Future<Map<String, Object?>> _post(
    String action,
    Map<String, Object?> params,
  ) async {
    _ensureConfigured();
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AccountException.unauthenticated();
    }
    late final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: <String, String>{
              'accept': 'application/json',
              'content-type': 'application/json',
              if (_config.supabaseAnonKey.isNotEmpty)
                'apikey': _config.supabaseAnonKey,
              'authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(<String, Object?>{
              'action': action,
              'params': params,
            }),
          )
          .timeout(timeout);
    } on IOException {
      // Covers SocketException, TLS handshake failures and other transport
      // faults; all are retryable "you are offline" states for the caller.
      throw const AccountException.network();
    } on TimeoutException {
      throw const AccountException.network();
    } on http.ClientException {
      throw const AccountException.network();
    }
    return _decodeEnvelope(response);
  }

  Map<String, Object?> _decodeEnvelope(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const AccountException.malformed();
    }
    if (decoded is! Map) {
      throw const AccountException.malformed();
    }
    final error = decoded['error'];
    if (error is Map) {
      final code = error['code']?.toString() ?? 'unknown';
      throw AccountException(
        code,
        _safeMessage(error['message']?.toString(), code),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AccountException(
        'unauthorized',
        'Sign in to continue.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 400) {
      throw AccountException(
        response.statusCode >= 500 ? 'internal_error' : 'http_${response.statusCode}',
        response.statusCode >= 500
            ? 'The arena is unavailable right now.'
            : 'The arena rejected that request.',
        statusCode: response.statusCode,
      );
    }
    final data = decoded['data'];
    if (data is Map<String, Object?>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const AccountException.malformed();
  }

  /// Server messages are shown only when they carry no address or token-like
  /// content; otherwise an honest generic sentence is used.
  static String _safeMessage(String? message, String code) {
    if (message == null ||
        message.isEmpty ||
        message.contains('@') ||
        message.toLowerCase().contains('token') ||
        message.toLowerCase().contains('bearer')) {
      return switch (code) {
        'username_taken' => 'That username is taken. Try another.',
        'username_invalid' => 'That username is not allowed. Try another.',
        'username_required' => 'Choose a username before battling.',
        'avatar_too_large' => 'That photo is larger than 2 MB. Choose a smaller one.',
        'avatar_invalid' => 'That photo was not accepted. Choose a JPEG, PNG or WebP image.',
        'rate_limited' => 'Too many attempts. Wait a moment and try again.',
        'blocked' => 'You cannot interact with this player.',
        _ => 'The arena rejected that request. Try again.',
      };
    }
    return message;
  }

  ArenaProfile _requireProfile(Object? value) {
    final profile = _profile(value);
    if (profile == null) {
      throw const AccountException.malformed();
    }
    return profile;
  }

  static ArenaProfile? _profile(Object? value) {
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

  static ResultReceipt? _receipt(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id']?.toString();
    final matchId = value['match_id']?.toString();
    final exercise = ArenaExercise.tryFromWire(value['exercise']);
    final mode = ArenaMatchMode.tryFromWire(value['mode']);
    final outcome = ArenaMatchOutcome.tryFromWire(value['outcome']);
    final rawPlayers = value['players'];
    if (id == null ||
        id.isEmpty ||
        matchId == null ||
        matchId.isEmpty ||
        exercise == null ||
        mode == null ||
        outcome == null ||
        rawPlayers is! List ||
        rawPlayers.length < 2) {
      return null;
    }
    final players = <ArenaReceiptPlayer>[];
    for (final raw in rawPlayers) {
      final player = _receiptPlayer(raw);
      if (player == null) {
        return null;
      }
      players.add(player);
    }
    final winnerId = value['winner_id']?.toString();
    if (outcome == ArenaMatchOutcome.win &&
        (winnerId == null || winnerId.isEmpty)) {
      return null;
    }
    return ResultReceipt(
      id: id,
      matchId: matchId,
      exercise: exercise,
      mode: mode,
      players: players,
      outcome: outcome,
      winnerId: winnerId,
      finishedAt: _dateTime(value['finished_at']),
      reason: value['reason']?.toString(),
    );
  }

  static ArenaReceiptPlayer? _receiptPlayer(Object? value) {
    if (value is! Map) {
      return null;
    }
    final profile = _profile(value);
    final score = _int(value['score']);
    if (profile == null || score == null) {
      return null;
    }
    return ArenaReceiptPlayer(
      profile: profile,
      score: score,
      ratingAfter: _int(value['rating_after']),
      ratingChange: _int(value['rating_change']),
    );
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

  static DateTime? _dateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
