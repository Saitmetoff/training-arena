/// Transport client for the notification actions in `docs/API.md`.
///
/// Only two actions are used:
///
/// - `device_register` — `{token, platform}` → `{ok:true}`. This is the only
///   place a device token is sent. Tokens are never logged, never put in
///   analytics properties and never returned to UI code.
/// - `analytics` — `{event, properties}` → `{ok:true}` (best effort).
///
/// The implementation mirrors the other arena clients: authenticated
/// `POST /functions/v1/arena` with the `{action,params}` envelope, failing
/// closed when configuration or the session is missing.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/arena_config.dart';

/// Supplies the current Supabase access token; null fails closed.
typedef NotificationAccessTokenProvider = Future<String?> Function();

/// Minimal arena transport used by the notification layer.
abstract interface class NotificationApi {
  /// Registers this device for best-effort push (`device_register`).
  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  /// Best-effort product analytics (`analytics`).
  Future<void> trackEvent(String event, Map<String, Object?> properties);
}

/// Typed failure for the two notification actions.
class NotificationApiException implements Exception {
  const NotificationApiException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'NotificationApiException($code)';
}

/// HTTP implementation against the arena Edge Function.
class HttpNotificationApi implements NotificationApi {
  HttpNotificationApi({
    required ArenaConfig config,
    required NotificationAccessTokenProvider accessTokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _config = config,
        _accessTokenProvider = accessTokenProvider,
        _client = client ?? http.Client();

  final ArenaConfig _config;
  final NotificationAccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    await _post('device_register', <String, Object?>{
      'token': token,
      'platform': platform,
    });
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

  Uri get _endpoint {
    final base = _config.supabaseUrl.endsWith('/')
        ? _config.supabaseUrl.substring(0, _config.supabaseUrl.length - 1)
        : _config.supabaseUrl;
    return Uri.parse('$base/functions/v1/arena');
  }

  Future<void> _post(
    String action,
    Map<String, Object?> params,
  ) async {
    if (!_config.hasSupabaseCredentials) {
      throw const NotificationApiException('not_configured');
    }
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const NotificationApiException('unauthenticated');
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
      throw const NotificationApiException(
        'offline',
        message: 'The arena is unreachable.',
      );
    } on TimeoutException {
      throw const NotificationApiException(
        'offline',
        message: 'The arena did not answer in time.',
      );
    } on http.ClientException {
      throw const NotificationApiException(
        'offline',
        message: 'The arena is unreachable.',
      );
    }
    _decode(response);
  }

  void _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const NotificationApiException('malformed');
    }
    if (decoded is! Map) {
      throw const NotificationApiException('malformed');
    }
    final error = decoded['error'];
    if (error is Map) {
      // The message is never surfaced with token content; only the code is
      // used by callers.
      throw NotificationApiException(
        error['code']?.toString() ?? 'unknown',
        message: 'The arena rejected the notification action.',
      );
    }
    if (response.statusCode >= 400) {
      throw NotificationApiException('http_${response.statusCode}');
    }
  }
}
