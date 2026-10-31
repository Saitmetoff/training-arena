/// Arena challenge API boundary.
///
/// The server implementation is owned by task `04` (`supabase/`, `backend/`)
/// and follows `docs/API.md`:
///
/// - `GET /functions/v1/arena?token=<token>` resolves a link read-only. It
///   must not create a profile, request, queue seat or match.
/// - `POST /functions/v1/arena` carries authenticated `{action,params}` and
///   answers `{data:...}` / `{error:{code,message}}`.
///
/// This file contains no match or request logic beyond translating those
/// envelopes. Every mutation is an explicit call; opening a link only calls
/// [resolveLink].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/arena_config.dart';
import '../domain/arena_types.dart';
import 'challenge_models.dart';

/// Supplies the current Supabase access token. The account task (`06`) owns
/// the session; task `05` only consumes it. Returning null fails closed.
typedef AccessTokenProvider = Future<String?> Function();

/// Transport-facing challenge operations.
abstract class ArenaChallengeApi {
  /// Read-only link resolution. Never mutates.
  Future<ChallengeResolution> resolveLink(String token);

  /// Creates one recipient request for [token] (`request_send`).
  Future<ChallengeRequest> sendRequest(String token);

  /// Accepts/declines/cancels one request (`request_respond`).
  Future<ChallengeRequest> respondToRequest(
    String requestId,
    ChallengeRequestResponse response,
  );

  /// Profile, durable link and any active match (`profile`).
  Future<ChallengeAccountSnapshot> accountSnapshot();

  /// Finds this actor's pending outgoing request to [ownerId] (`inbox`).
  ///
  /// Used to recover gracefully from `request_exists` without inventing a
  /// request id or a match.
  Future<ChallengeRequest?> pendingOutgoingRequestTo(String ownerId);

  /// Best-effort analytics (`analytics`).
  Future<void> trackEvent(String event, Map<String, Object?> properties);
}

/// HTTP implementation of [ArenaChallengeApi] against the arena Edge
/// Function. It fails closed when configuration or auth is missing.
class HttpArenaChallengeApi implements ArenaChallengeApi {
  HttpArenaChallengeApi({
    required ArenaConfig config,
    required AccessTokenProvider accessTokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _config = config,
        _accessTokenProvider = accessTokenProvider,
        _client = client ?? http.Client();

  final ArenaConfig _config;
  final AccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  final Duration timeout;

  Uri get _endpoint {
    final base = _config.supabaseUrl.endsWith('/')
        ? _config.supabaseUrl.substring(0, _config.supabaseUrl.length - 1)
        : _config.supabaseUrl;
    return Uri.parse('$base/functions/v1/arena');
  }

  Map<String, String> _headers({String? bearer}) {
    return <String, String>{
      'accept': 'application/json',
      if (_config.supabaseAnonKey.isNotEmpty)
        'apikey': _config.supabaseAnonKey,
      if (bearer != null) 'authorization': 'Bearer $bearer',
    };
  }

  void _ensureConfigured() {
    if (!_config.hasSupabaseCredentials) {
      throw const ChallengeApiException(
        'not_configured',
        message: 'The arena backend is not configured in this build.',
      );
    }
  }

  @override
  Future<ChallengeResolution> resolveLink(String token) async {
    _ensureConfigured();
    final uri = _endpoint.replace(queryParameters: <String, String>{
      ..._endpoint.queryParameters,
      'token': token,
    });
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers())
          .timeout(timeout);
    } on SocketException {
      throw const ChallengeApiException.network();
    } on TimeoutException {
      throw const ChallengeApiException.network();
    } on http.ClientException {
      throw const ChallengeApiException.network();
    }
    final data = _decodeEnvelope(response, requireData: false);
    final available = data['available'] == true;
    final owner = _profile(data['owner']);
    final rawStatus = data['reason'] ?? data['status'];
    final status = available
        ? (data['owner_offline'] == true
            ? ChallengeLinkStatus.ownerOffline
            : ChallengeLinkStatus.available)
        : (rawStatus is String
            ? ChallengeApiException.statusFromErrorCode(rawStatus)
            : ChallengeLinkStatus.unavailable);
    return ChallengeResolution(
      token: token,
      status: status,
      owner: owner,
      message: data['message']?.toString(),
    );
  }

  @override
  Future<ChallengeRequest> sendRequest(String token) async {
    final data = await _post('request_send', <String, Object?>{
      'token': token,
    });
    return _request(data['request']);
  }

  @override
  Future<ChallengeRequest> respondToRequest(
    String requestId,
    ChallengeRequestResponse response,
  ) async {
    final data = await _post('request_respond', <String, Object?>{
      'request_id': requestId,
      'response': response.wire,
    });
    return _request(data['request']);
  }

  @override
  Future<ChallengeAccountSnapshot> accountSnapshot() async {
    final data = await _post('profile', const <String, Object?>{});
    final profile = _profile(data['profile']);
    if (profile == null) {
      throw const ChallengeApiException.malformed();
    }
    var linkMap = data['link'];
    var token = _linkToken(linkMap);
    if (token.isEmpty) {
      // A brand-new account has no durable link until the documented
      // `link_rotate` action creates one. Rotate instead of failing the
      // snapshot so the waiting poll and the share sheet work on first use.
      final rotated = await _post('link_rotate', const <String, Object?>{});
      linkMap = rotated['link'];
      token = _linkToken(linkMap);
    }
    if (token.isEmpty || linkMap is! Map) {
      throw const ChallengeApiException.malformed();
    }
    return ChallengeAccountSnapshot(
      profile: profile,
      link: ChallengeLinkInfo(
        token: token,
        code: linkMap['code']?.toString() ?? token,
      ),
      activeMatchId: data['active_match_id']?.toString(),
    );
  }

  static String _linkToken(Object? value) {
    if (value is! Map) {
      return '';
    }
    return value['token']?.toString() ?? '';
  }

  @override
  Future<ChallengeRequest?> pendingOutgoingRequestTo(String ownerId) async {
    final data = await _post('inbox', const <String, Object?>{});
    final requests = data['requests'];
    if (requests is! List) {
      return null;
    }
    for (final item in requests) {
      if (item is! Map) {
        continue;
      }
      final recipient = item['recipient'];
      final recipientId = recipient is Map ? recipient['id']?.toString() : null;
      if (recipientId != ownerId) {
        continue;
      }
      final status = ChallengeRequestStatus.tryFromWire(item['status']);
      if (status == ChallengeRequestStatus.pending) {
        return _request(item);
      }
    }
    return null;
  }

  @override
  Future<void> trackEvent(
    String event,
    Map<String, Object?> properties,
  ) async {
    await _post('analytics', <String, Object?>{
      'event': event,
      'properties': properties,
    });
  }

  Future<Map<String, Object?>> _post(
    String action,
    Map<String, Object?> params,
  ) async {
    _ensureConfigured();
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ChallengeApiException.unauthenticated();
    }
    late final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: <String, String>{
              ..._headers(bearer: accessToken),
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, Object?>{
              'action': action,
              'params': params,
            }),
          )
          .timeout(timeout);
    } on SocketException {
      throw const ChallengeApiException.network();
    } on TimeoutException {
      throw const ChallengeApiException.network();
    } on http.ClientException {
      throw const ChallengeApiException.network();
    }
    return _decodeEnvelope(response);
  }

  Map<String, Object?> _decodeEnvelope(
    http.Response response, {
    bool requireData = true,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ChallengeApiException.malformed();
    }
    if (decoded is! Map<String, Object?>) {
      throw const ChallengeApiException.malformed();
    }
    final error = decoded['error'];
    if (error is Map) {
      throw ChallengeApiException(
        error['code']?.toString() ?? 'unknown',
        message: error['message']?.toString(),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 400) {
      throw ChallengeApiException(
        'http_${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final data = decoded['data'];
    if (data is Map<String, Object?>) {
      return data;
    }
    if (requireData) {
      throw const ChallengeApiException.malformed();
    }
    return const <String, Object?>{};
  }

  ChallengeRequest _request(Object? value) {
    if (value is! Map) {
      throw const ChallengeApiException.malformed();
    }
    final id = value['id']?.toString();
    final status = ChallengeRequestStatus.tryFromWire(value['status']);
    if (id == null || id.isEmpty || status == null) {
      throw const ChallengeApiException.malformed();
    }
    return ChallengeRequest(
      id: id,
      status: status,
      expiresAt: _dateTime(value['expires_at']),
      matchId: value['match_id']?.toString(),
    );
  }

  ArenaProfile? _profile(Object? value) {
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
