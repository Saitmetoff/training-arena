/// HTTP implementation of [BattleBackend] against the arena Edge Function.
///
/// Speaks the exact `POST /functions/v1/arena` envelope from `docs/API.md`
/// (`{action,params}` → `{data}` / `{error:{code,message}}`) and parses the
/// battle subset into battle models. Challenge-link resolution and the
/// request send/poll loop stay with task 05's `ArenaChallengeApi`; this
/// adapter consumes the same configured project and access token.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/arena_config.dart';
import '../../camera/camera_types.dart' show arenaCounterVersion;
import '../../domain/arena_types.dart';
import '../ports/battle_backend.dart';
import '../state/battle_failure.dart';
import '../state/battle_models.dart';

/// Supplies the current Supabase access token; null fails closed.
typedef BattleAccessTokenProvider = Future<String?> Function();

/// Arena Edge Function battle client.
class HttpBattleBackend implements BattleBackend {
  HttpBattleBackend({
    required ArenaConfig config,
    required BattleAccessTokenProvider accessTokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.linkAcceptPollInterval = const Duration(seconds: 2),
    this.linkAcceptTimeout = const Duration(seconds: 20),
  }) : _config = config,
       _accessTokenProvider = accessTokenProvider,
       _client = client ?? http.Client();

  final ArenaConfig _config;
  final BattleAccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  final Duration timeout;
  final Duration linkAcceptPollInterval;
  final Duration linkAcceptTimeout;

  String? _viewerId;
  String? _viewerToken;

  @override
  bool get configured => _config.hasSupabaseCredentials;

  Uri get _endpoint {
    final base = _config.supabaseUrl.endsWith('/')
        ? _config.supabaseUrl.substring(0, _config.supabaseUrl.length - 1)
        : _config.supabaseUrl;
    return Uri.parse('$base/functions/v1/arena');
  }

  @override
  Future<ArenaProfile?> currentProfile() async {
    final data = await _post('profile', const <String, Object?>{});
    final profile = _profile(data['profile']);
    _viewerId = profile?.id ?? _viewerId;
    return profile;
  }

  @override
  Future<BattleInbox> inbox() async {
    final data = await _post('inbox', const <String, Object?>{});
    if (_viewerId == null) {
      await currentProfile();
    }
    final rawRequests = data['requests'];
    final requests = <BattleRequest>[];
    if (rawRequests is List) {
      for (final raw in rawRequests) {
        final request = _request(raw, _viewerId);
        if (request != null) {
          requests.add(request);
        }
      }
    }
    return BattleInbox(
      requests: requests,
      activeMatchId: data['active_match_id']?.toString(),
      viewerBusy: data['viewer_busy'] == true,
      serverNow: _dateTime(data['server_now']),
    );
  }

  @override
  Future<BattleMatch> acceptLink(String token) async {
    final data = await _post('request_send', <String, Object?>{'token': token});
    final request = data['request'];
    if (request is Map) {
      final matchId = request['match_id']?.toString();
      if (matchId != null && matchId.isNotEmpty) {
        return matchState(matchId);
      }
    }
    // Mutual acceptance can arrive slightly later; poll the authoritative
    // profile until the server reports the active match.
    final deadline = DateTime.now().add(linkAcceptTimeout);
    await currentProfile();
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(linkAcceptPollInterval);
      final data = await _post('profile', const <String, Object?>{});
      final matchId = data['active_match_id']?.toString();
      if (matchId != null && matchId.isNotEmpty) {
        return matchState(matchId);
      }
    }
    throw const BattleFailure(
      BattleFailureKind.conflict,
      'The challenge was sent. It becomes a match when the other player '
      'accepts.',
    );
  }

  @override
  Future<BattleRequest> sendChallenge(String target) async {
    final data = await _post('request_send', <String, Object?>{
      'token': target,
    });
    final request = data['request'];
    if (request is! Map) {
      throw const BattleFailure(
        BattleFailureKind.serverFailure,
        'The arena answered with a malformed request.',
      );
    }
    return _request(request, _viewerId) ??
        BattleRequest(
          id: request['id']?.toString() ?? 'request',
          kind: BattleRequestKind.pending,
          sender:
              _profile(request['recipient'] ?? request['sender']) ??
              const ArenaProfile(id: 'unknown', username: 'player'),
          exercise: ArenaExercise.pushUps,
          matchId: request['match_id']?.toString(),
        );
  }

  @override
  Future<BattleMatch> acceptRequest(String requestId) async {
    final data = await _post('request_accept', <String, Object?>{
      'request_id': requestId,
    });
    return _requiredMatch(data['match']);
  }

  @override
  Future<BattleRequest> requestRematch(String matchId) async {
    if (_viewerId == null) await currentProfile();
    final data = await _post('request_rematch', {'match_id': matchId});
    // A refreshed bearer clears the cached identity inside _post.
    if (_viewerId == null) await currentProfile();
    final request = _request(data['request'], _viewerId);
    if (request == null) {
      throw const BattleFailure(
        BattleFailureKind.serverFailure,
        'The arena answered without a pending request.',
      );
    }
    return request;
  }

  @override
  Future<BattleRequest> respondToRequest(
    String requestId,
    BattleRequestResponse response,
  ) async {
    final data = await _post('request_respond', <String, Object?>{
      'request_id': requestId,
      'response': response == BattleRequestResponse.decline
          ? 'decline'
          : 'cancel',
    });
    final request = data['request'];
    if (request is! Map) {
      throw const BattleFailure(
        BattleFailureKind.serverFailure,
        'The arena answered with a malformed request.',
      );
    }
    return _request(request, _viewerId) ??
        BattleRequest(
          id: requestId,
          kind: BattleRequestKind.cancelled,
          sender:
              _profile(request['sender']) ??
              const ArenaProfile(id: 'unknown', username: 'player'),
          exercise: ArenaExercise.pushUps,
        );
  }

  @override
  Future<BattleQueueState> queueJoin() async {
    final data = await _post('queue_join', const <String, Object?>{});
    return _queue(data);
  }

  @override
  Future<BattleQueueState> queuePoll() async {
    final data = await _post('queue_poll', const <String, Object?>{});
    return _queue(data);
  }

  @override
  Future<void> queueLeave() async {
    await _post('queue_leave', const <String, Object?>{});
  }

  @override
  Future<BattleMatch> matchState(String matchId) async {
    final data = await _post('match_state', <String, Object?>{
      'match_id': matchId,
      'counter_version': arenaCounterVersion,
    });
    return _requiredMatch(data['match']);
  }

  @override
  Future<BattleMatch> ready(
    String matchId, {
    required bool tracking,
    required bool practiceComplete,
  }) async {
    final data = await _post('ready', <String, Object?>{
      'counter_version': arenaCounterVersion,
      'match_id': matchId,
      'tracking': tracking,
      'practice_complete': practiceComplete,
    });
    return _requiredMatch(data['match']);
  }

  @override
  Future<BattleMatch> heartbeat(
    String matchId, {
    required bool tracking,
  }) async {
    final data = await _post('heartbeat', <String, Object?>{
      'counter_version': arenaCounterVersion,
      'match_id': matchId,
      'tracking': tracking,
    });
    return _requiredMatch(data['match']);
  }

  @override
  Future<BattleMatch> reportRep(String matchId, PendingRepEvent event) async {
    final data = await _post('rep', <String, Object?>{
      'match_id': matchId,
      'event_id': event.eventId,
      'sequence': event.sequence,
      'observed_at': event.observedAt.toUtc().toIso8601String(),
      'counter_version': event.counterVersion,
    });
    return _requiredMatch(data['match']);
  }

  @override
  Future<BattleMatch> leave(String matchId) async {
    final data = await _post('leave', <String, Object?>{'match_id': matchId});
    return _requiredMatch(data['match']);
  }

  // ------------------------------------------------------------- transport --

  Future<Map<String, Object?>> _post(
    String action,
    Map<String, Object?> params,
  ) async {
    if (!configured) {
      throw const BattleFailure(
        BattleFailureKind.unconfigured,
        'The arena service is not configured in this build.',
      );
    }
    final accessToken = await _accessTokenProvider();
    if (_viewerToken != accessToken) {
      _viewerToken = accessToken;
      _viewerId = null;
    }
    if (accessToken == null || accessToken.isEmpty) {
      throw const BattleFailure(
        BattleFailureKind.unauthorized,
        'Sign in to use the arena.',
      );
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
    } on SocketException {
      throw const BattleFailure(
        BattleFailureKind.offline,
        'The arena is unreachable. Check your connection.',
      );
    } on TimeoutException {
      throw const BattleFailure(
        BattleFailureKind.offline,
        'The arena did not answer in time.',
      );
    } on http.ClientException {
      throw const BattleFailure(
        BattleFailureKind.offline,
        'The arena is unreachable. Check your connection.',
      );
    }
    return _decode(response);
  }

  Map<String, Object?> _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const BattleFailure(
        BattleFailureKind.serverFailure,
        'The arena answered with malformed data.',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const BattleFailure(
        BattleFailureKind.serverFailure,
        'The arena answered with malformed data.',
      );
    }
    final error = decoded['error'];
    if (error is Map) {
      final code = error['code']?.toString() ?? 'unknown';
      throw BattleFailure(
        _failureKind(code, response.statusCode),
        error['message']?.toString() ??
            'The arena refused the request ($code).',
      );
    }
    if (response.statusCode >= 400) {
      throw BattleFailure(
        _failureKind('http_${response.statusCode}', response.statusCode),
        'The arena refused the request (${response.statusCode}).',
      );
    }
    final data = decoded['data'];
    if (data is Map<String, Object?>) {
      return data;
    }
    return const <String, Object?>{};
  }

  BattleFailureKind _failureKind(String code, int statusCode) {
    if (statusCode == 401) {
      return BattleFailureKind.unauthorized;
    }
    switch (code) {
      case 'update_required':
        return BattleFailureKind.updateRequired;
      case 'not_configured':
        return BattleFailureKind.unconfigured;
      case 'not_authenticated':
      case 'unauthenticated':
      case 'invalid_token':
      case 'session_expired':
        return BattleFailureKind.unauthorized;
      case 'link_not_found':
      case 'request_not_found':
      case 'match_not_found':
      case 'not_found':
      case 'profile_not_found':
        return BattleFailureKind.notFound;
      case 'blocked':
      case 'player_blocked':
      case 'blocked_peer':
        return BattleFailureKind.blocked;
      case 'busy':
      case 'match_not_live':
      case 'match_closed':
      case 'request_expired':
      case 'already_queued':
      case 'conflict':
      case 'expired':
        return BattleFailureKind.conflict;
      default:
        return BattleFailureKind.serverFailure;
    }
  }

  // ---------------------------------------------------------------- parsing --

  BattleMatch _requiredMatch(Object? value) {
    final match = _match(value);
    if (match == null) {
      throw const BattleFailure(
        BattleFailureKind.serverFailure,
        'The arena answered without a match.',
      );
    }
    return match;
  }

  BattleMatch? _match(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id']?.toString();
    final exercise = ArenaExercise.tryFromWire(value['exercise']);
    final mode = ArenaMatchMode.tryFromWire(value['mode']);
    final status = ArenaMatchStatus.tryFromWire(value['status']);
    if (id == null || id.isEmpty || exercise == null || mode == null) {
      return null;
    }
    final players = <BattleMatchPlayer>[];
    final rawPlayers = value['players'];
    if (rawPlayers is List) {
      for (final raw in rawPlayers) {
        final player = _matchPlayer(raw);
        if (player != null) {
          players.add(player);
        }
      }
    }
    return BattleMatch(
      id: id,
      exercise: exercise,
      mode: mode,
      status: status ?? ArenaMatchStatus.preparing,
      players: players,
      startsAt: _dateTime(value['starts_at']),
      endsAt: _dateTime(value['ends_at']),
      serverNow: _dateTime(value['server_now']),
      receipt: _receipt(value['receipt']),
      reason: value['reason']?.toString(),
    );
  }

  BattleMatchPlayer? _matchPlayer(Object? value) {
    if (value is! Map) {
      return null;
    }
    final profile = _profile(value);
    if (profile == null) {
      return null;
    }
    return BattleMatchPlayer(
      profile: profile,
      score: _int(value['score']) ?? 0,
      ready: value['ready'] == true,
      tracking: value['tracking'] == true,
      lastSeen: _dateTime(value['last_seen']),
    );
  }

  ResultReceipt? _receipt(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id']?.toString();
    final matchId = value['match_id']?.toString();
    final exercise = ArenaExercise.tryFromWire(value['exercise']);
    final mode = ArenaMatchMode.tryFromWire(value['mode']);
    final outcome = ArenaMatchOutcome.tryFromWire(value['outcome']);
    if (id == null || matchId == null || exercise == null || mode == null) {
      return null;
    }
    final players = <ArenaReceiptPlayer>[];
    final rawPlayers = value['players'];
    if (rawPlayers is List) {
      for (final raw in rawPlayers) {
        if (raw is! Map) {
          continue;
        }
        final profile = _profile(raw);
        if (profile == null) {
          continue;
        }
        players.add(
          ArenaReceiptPlayer(
            profile: profile,
            score: _int(raw['score']) ?? 0,
            ratingAfter: _int(raw['rating_after']),
            ratingChange: _int(raw['rating_change']),
          ),
        );
      }
    }
    return ResultReceipt(
      id: id,
      matchId: matchId,
      exercise: exercise,
      mode: mode,
      players: players,
      outcome: outcome ?? ArenaMatchOutcome.noResult,
      winnerId: value['winner_id']?.toString(),
      finishedAt: _dateTime(value['finished_at']),
      reason: value['reason']?.toString(),
    );
  }

  BattleRequest? _request(Object? value, String? viewerId) {
    if (value is! Map) {
      return null;
    }
    final id = value['id']?.toString();
    final sender = _profile(value['sender']);
    final recipient = _profile(value['recipient']);
    final status = value['status']?.toString();
    if (id == null || sender == null || recipient == null || status == null) {
      return null;
    }
    if (id.isEmpty ||
        viewerId == null ||
        (sender.id != viewerId && recipient.id != viewerId)) {
      return null;
    }
    final kind = switch (status) {
      'pending' => BattleRequestKind.pending,
      'expired' => BattleRequestKind.expired,
      'cancelled' || 'canceled' || 'declined' => BattleRequestKind.cancelled,
      _ => null,
    };
    if (kind == null) {
      return null;
    }
    return BattleRequest(
      id: id,
      kind: kind,
      sender: sender,
      recipient: recipient,
      isOutgoing: sender.id == viewerId,
      exercise:
          ArenaExercise.tryFromWire(value['exercise']) ?? ArenaExercise.pushUps,
      mode: ArenaMatchMode.tryFromWire(value['mode']) ?? ArenaMatchMode.casual,
      receivedAt: _dateTime(value['created_at']),
      expiresAt: _dateTime(value['expires_at']),
      matchId: value['match_id']?.toString(),
      note: value['note']?.toString(),
    );
  }

  BattleQueueState _queue(Map<String, Object?> data) {
    final match = _match(data['match']);
    final queued = data['queued'];
    return BattleQueueState(
      matchId: match?.id,
      joinedAt: _dateTime(data['queued_since'] ?? data['joined_at']),
      expiresAt: _dateTime(data['expires_at']),
      serverNow: match?.serverNow ?? _dateTime(data['server_now']),
      queued: queued is bool ? queued : null,
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
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
