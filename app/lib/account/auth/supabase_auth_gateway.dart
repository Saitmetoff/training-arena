/// Supabase GoTrue auth gateway.
///
/// Implements the provider contract behind [ArenaAuthGateway] over the
/// documented Supabase Auth HTTP API:
///
/// * email codes: `POST /auth/v1/otp` then `POST /auth/v1/verify`;
/// * Google: `GET /auth/v1/authorize` with PKCE (`S256`) and
///   `POST /auth/v1/token?grant_type=pkce` after the redirect returns;
/// * refresh/sign-out: `grant_type=refresh_token` and `/auth/v1/logout`.
///
/// It fails closed when no project or redirect is configured. Tokens and
/// email addresses never enter log lines or error messages.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../config/arena_config.dart';
import '../models/account_models.dart';
import 'arena_auth.dart';
import 'auth_store.dart';

/// Returns true when the platform accepted the browser launch.
typedef AuthBrowserOpener = Future<bool> Function(Uri url);

/// OAuth redirect entry point backed by `app_links`.
class AppLinksAuthRedirectLinks implements ArenaAuthRedirectLinks {
  AppLinksAuthRedirectLinks({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> initialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Uri> get links {
    try {
      return _appLinks.uriLinkStream.handleError((Object _) {});
    } catch (_) {
      return const Stream<Uri>.empty();
    }
  }
}

/// `url_launcher` browser boundary.
class UrlLauncherAuthBrowser implements ArenaAuthBrowser {
  const UrlLauncherAuthBrowser();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Production gateway over the configured Supabase project.
class SupabaseAuthGateway implements ArenaAuthGateway {
  SupabaseAuthGateway({
    required ArenaConfig config,
    required AuthSessionStore store,
    ArenaAuthRedirectLinks? links,
    ArenaAuthBrowser browser = const UrlLauncherAuthBrowser(),
    http.Client? client,
    DateTime Function()? now,
    Random? random,
    this.redirectTimeout = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 20),
  })  : _config = config,
        _store = store,
        _links = links ?? AppLinksAuthRedirectLinks(),
        _browser = browser,
        _client = client ?? http.Client(),
        _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  final ArenaConfig _config;
  final AuthSessionStore _store;
  final ArenaAuthRedirectLinks _links;
  final ArenaAuthBrowser _browser;
  final http.Client _client;
  final DateTime Function() _now;
  final Random _random;
  final Duration redirectTimeout;
  final Duration requestTimeout;

  /// Identity generation. Every operation that establishes or clears an
  /// identity (a sign-in attempt, a sign-out or a local clear) bumps it, so an
  /// operation started earlier can neither persist its session nor delete a
  /// newer one. A read-only restore/refresh only observes it.
  int _epoch = 0;

  bool _isCurrent(int epoch) => epoch == _epoch;

  /// Clears the stored session only while [epoch] is still the active identity.
  Future<void> _clearStoredSessionForEpoch(int epoch) async {
    if (!_isCurrent(epoch)) {
      return;
    }
    await _clearStoredSessionQuietly();
  }

  /// Clears the stored verifier only while [epoch] is still active.
  Future<void> _clearStoredPkceForEpoch(int epoch) async {
    if (!_isCurrent(epoch)) {
      return;
    }
    await _clearStoredPkceQuietly();
  }

  Uri get _authBase {
    final base = _config.supabaseUrl.endsWith('/')
        ? _config.supabaseUrl.substring(0, _config.supabaseUrl.length - 1)
        : _config.supabaseUrl;
    return Uri.parse('$base/auth/v1');
  }

  void _ensureConfigured() {
    if (!_config.hasSupabaseCredentials) {
      throw const AccountException(
        'unconfigured',
        'Sign-in is not configured in this build.',
      );
    }
  }

  Map<String, String> get _jsonHeaders => <String, String>{
        'accept': 'application/json',
        'content-type': 'application/json',
        if (_config.supabaseAnonKey.isNotEmpty) 'apikey': _config.supabaseAnonKey,
      };

  @override
  Future<ArenaAuthSession?> restoreSession() async {
    final epoch = _epoch;
    final resumed = await _resumeInterruptedRedirect(epoch);
    if (resumed != null) {
      // A newer identity must never be replaced by this stale result.
      return epoch == _epoch ? resumed : null;
    }
    if (epoch != _epoch) {
      return null;
    }
    final stored = await _store.readSession();
    if (stored == null) {
      return null;
    }
    if (epoch != _epoch) {
      // A logout ran while the session was being read/migrated.
      return null;
    }
    if (!stored.isExpired(_now())) {
      return stored;
    }
    final refreshToken = stored.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearStoredSessionForEpoch(epoch);
      return null;
    }
    try {
      return await _refreshSession(stored, epoch);
    } on AccountException catch (error) {
      if (epoch != _epoch) {
        // A newer identity took ownership while this restore was in flight; a
        // retryable failure must not hand back the older stored session.
        return null;
      }
      if (error.isRetryable || error.code == 'storage') {
        // Offline or a transient secure-storage failure: keep the local
        // session so the shell stays signed in and the next online call can
        // refresh or report the expiry honestly.
        return stored;
      }
      await _clearStoredSessionForEpoch(epoch);
      return null;
    }
  }

  @override
  Future<ArenaAuthSession> signInWithGoogle() async {
    _ensureConfigured();
    final epoch = ++_epoch;
    final redirect = _redirectUri();
    final verifier = _newVerifier();
    final challenge = _challengeFor(verifier);
    try {
      await _store.writePkceVerifier(verifier);
    } on AuthStorageException {
      throw const AccountException(
        'storage',
        'This device cannot store the sign-in state securely. Try again.',
      );
    }

    final authorize = _authBase.replace(
      path: '${_authBase.path}/authorize',
      queryParameters: <String, String>{
        'provider': 'google',
        'redirect_to': redirect.toString(),
        'code_challenge': challenge,
        'code_challenge_method': 's256',
        'flow_type': 'pkce',
      },
    );

    final completer = Completer<Uri>();
    final subscription = _links.links.listen((uri) {
      if (!completer.isCompleted && _matchesRedirect(uri, redirect)) {
        completer.complete(uri);
      }
    });
    try {
      final opened = await _openBrowser(authorize);
      if (!opened) {
        await _clearStoredPkceForEpoch(epoch);
        throw const AccountException(
          'browser_unavailable',
          'A browser could not be opened. Try again.',
        );
      }
      final callback = await completer.future.timeout(
        redirectTimeout,
        onTimeout: () {
          throw const AccountException(
            'cancelled',
            'Sign-in was cancelled. Nothing changed.',
          );
        },
      );
      return await _exchangeCode(callback, verifier, epoch);
    } finally {
      await subscription.cancel();
    }
  }

  Future<bool> _openBrowser(Uri url) async {
    try {
      return await _browser.open(url);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestEmailCode(String email) async {
    _ensureConfigured();
    final value = ArenaEmail.normalize(email);
    final invalid = ArenaEmail.validationMessage(value);
    if (invalid != null) {
      throw AccountException('email_invalid', invalid);
    }
    final response = await _send(
      'POST',
      _authBase.replace(path: '${_authBase.path}/otp'),
      body: <String, Object?>{'email': value, 'create_user': true},
    );
    if (response.statusCode >= 400) {
      throw _mapAuthError(response);
    }
  }

  @override
  Future<ArenaAuthSession> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    _ensureConfigured();
    final epoch = ++_epoch;
    final value = ArenaEmail.normalize(email);
    final trimmedCode = code.trim();
    if (trimmedCode.length < 4 || trimmedCode.length > 10) {
      throw const AccountException(
        'code_invalid',
        'Enter the code from the email.',
      );
    }
    final response = await _send(
      'POST',
      _authBase.replace(path: '${_authBase.path}/verify'),
      body: <String, Object?>{
        'type': 'email',
        'email': value,
        'token': trimmedCode,
      },
    );
    if (response.statusCode >= 400) {
      throw _mapAuthError(response);
    }
    return _persistSession(_sessionFromBody(response.body), epoch);
  }

  @override
  Future<ArenaAuthSession> refreshSession(ArenaAuthSession session) async {
    return _refreshSession(session, _epoch);
  }

  Future<ArenaAuthSession> _refreshSession(
    ArenaAuthSession session,
    int epoch,
  ) async {
    _ensureConfigured();
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearStoredSessionForEpoch(epoch);
      throw const AccountException(
        'expired',
        'Your sign-in expired. Sign in again to continue.',
      );
    }
    final response = await _send(
      'POST',
      _authBase.replace(
        path: '${_authBase.path}/token',
        queryParameters: <String, String>{'grant_type': 'refresh_token'},
      ),
      body: <String, Object?>{'refresh_token': refreshToken},
    );
    if (epoch != _epoch) {
      // A logout cleared the session while this refresh was in flight; do not
      // write the refreshed token back.
      throw const AccountException(
        'cancelled',
        'Your sign-in was cleared. Sign in again to continue.',
      );
    }
    if (response.statusCode >= 400) {
      final mapped = _mapAuthError(response);
      if (mapped.isRetryable) {
        throw mapped;
      }
      await _clearStoredSessionForEpoch(epoch);
      throw const AccountException(
        'expired',
        'Your sign-in expired. Sign in again to continue.',
      );
    }
    return _persistSession(_sessionFromBody(response.body), epoch);
  }

  @override
  Future<void> signOut(ArenaAuthSession session) async {
    // Invalidate any in-flight restore/refresh/sign-in before clearing so a
    // late reply cannot write the credential back or erase a newer identity.
    final epoch = ++_epoch;
    // Attempt durable local cleanup and best-effort server revocation
    // independently: a storage failure must still revoke the token server
    // side, and a server failure must still erase the local copy.
    Object? localFailure;
    try {
      await _clearLocalForEpoch(epoch);
    } catch (error) {
      localFailure = error;
    }
    if (_config.hasSupabaseCredentials && session.accessToken.isNotEmpty) {
      try {
        await _send(
          'POST',
          _authBase.replace(path: '${_authBase.path}/logout'),
          body: const <String, Object?>{},
          bearer: session.accessToken,
        );
      } catch (_) {
        // Best effort: the durable local clear is the primary contract.
      }
    }
    if (localFailure != null) {
      throw localFailure is AuthStorageException
          ? localFailure
          : const AuthStorageException(
              'The saved session could not be erased from this device.',
            );
    }
  }

  @override
  Future<void> clearLocalAuth() async {
    final epoch = ++_epoch;
    await _clearLocalForEpoch(epoch);
  }

  /// Clears session and verifier while [epoch] is still the active identity.
  ///
  /// Both mutations are queued before the first await so a newer sign-in that
  /// starts mid-clear cannot slip a fresh verifier between them.
  Future<void> _clearLocalForEpoch(int epoch) async {
    if (!_isCurrent(epoch)) {
      // A newer sign-in superseded this clear; never erase it.
      return;
    }
    final sessionClear = _store.clearSession();
    final pkceClear = _store.clearPkceVerifier();
    Object? localFailure;
    try {
      await sessionClear;
    } catch (error) {
      localFailure = error;
    }
    try {
      await pkceClear;
    } catch (error) {
      localFailure ??= error;
    }
    if (localFailure != null) {
      throw localFailure is AuthStorageException
          ? localFailure
          : const AuthStorageException(
              'The saved session could not be erased from this device.',
            );
    }
  }

  // ------------------------------------------------------------- internals

  Uri _redirectUri() {
    final raw = _config.authRedirectUrl.trim();
    if (raw.isEmpty) {
      throw const AccountException(
        'unconfigured',
        'Google sign-in is not configured in this build.',
      );
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw const AccountException(
        'unconfigured',
        'Google sign-in is not configured in this build.',
      );
    }
    return uri;
  }

  Future<ArenaAuthSession?> _resumeInterruptedRedirect(int epoch) async {
    final verifier = await _store.readPkceVerifier();
    if (verifier == null || verifier.isEmpty) {
      return null;
    }
    final redirect = Uri.tryParse(_config.authRedirectUrl.trim());
    if (redirect == null || !redirect.hasScheme) {
      await _clearStoredPkceForEpoch(epoch);
      return null;
    }
    final cold = await _links.initialLink();
    if (cold == null || !_matchesRedirect(cold, redirect)) {
      return null;
    }
    try {
      return await _exchangeCode(cold, verifier, epoch);
    } on AccountException {
      // `_exchangeCode` keeps the verifier for retryable transport/server
      // errors and clears it once the authorization code is consumed or
      // permanently rejected. The pending challenge is owned by the challenge
      // persistence layer and is left untouched.
      return null;
    }
  }

  Future<ArenaAuthSession> _exchangeCode(
    Uri callback,
    String verifier,
    int epoch,
  ) async {
    if (epoch != _epoch) {
      throw const AccountException(
        'cancelled',
        'Sign-in was cancelled. Nothing changed.',
      );
    }
    final fragment = _fragmentParameters(callback);
    final error =
        callback.queryParameters['error'] ?? fragment['error'];
    if (error != null) {
      await _clearStoredPkceForEpoch(epoch);
      throw const AccountException(
        'cancelled',
        'Sign-in was cancelled. Nothing changed.',
      );
    }
    final code = callback.queryParameters['code'] ?? fragment['code'];
    if (code == null || code.isEmpty) {
      await _clearStoredPkceForEpoch(epoch);
      throw const AccountException(
        'cancelled',
        'Sign-in did not complete. Try again.',
      );
    }
    final response = await _send(
      'POST',
      _authBase.replace(
        path: '${_authBase.path}/token',
        queryParameters: <String, String>{'grant_type': 'pkce'},
      ),
      body: <String, Object?>{'auth_code': code, 'code_verifier': verifier},
    );
    if (response.statusCode >= 400) {
      final mapped = _mapAuthError(response);
      if (!mapped.isRetryable) {
        // The provider will never accept this authorization code again. The
        // guard means a superseded sign-in never clears a newer verifier.
        await _clearStoredPkceForEpoch(epoch);
      }
      // A retryable transport/server error keeps the verifier so a cold
      // redirect can be retried when the service recovers.
      throw mapped;
    }
    // A 2xx token response consumes the single-use authorization code. From
    // here the verifier can no longer be retried: on a storage failure the
    // user must start a fresh sign-in instead of replaying this redirect.
    try {
      final session =
          await _persistSession(_sessionFromBody(response.body), epoch);
      await _clearStoredPkceForEpoch(epoch);
      return session;
    } catch (_) {
      await _clearStoredPkceForEpoch(epoch);
      rethrow;
    }
  }

  Future<ArenaAuthSession> _persistSession(
    ArenaAuthSession session,
    int epoch,
  ) async {
    if (epoch != _epoch) {
      // A logout superseded this sign-in; never write the credential back.
      throw const AccountException(
        'cancelled',
        'Sign-in was cancelled. Nothing changed.',
      );
    }
    try {
      await _store.writeSession(session);
    } on AuthStorageException {
      // Never claim a durable sign-in when the secure store refused it.
      throw const AccountException(
        'storage',
        'This device could not save your session securely. Sign in again.',
      );
    }
    if (epoch != _epoch) {
      // A newer identity started while the write was in flight; the caller
      // must not apply this superseded result.
      throw const AccountException(
        'cancelled',
        'Sign-in was cancelled. Nothing changed.',
      );
    }
    return session;
  }

  /// Best-effort clears for internal failure paths: a storage failure must not
  /// mask the real provider error the caller needs to see.
  Future<void> _clearStoredSessionQuietly() async {
    try {
      await _store.clearSession();
    } catch (_) {
      // The caller already has an honest failure to report.
    }
  }

  Future<void> _clearStoredPkceQuietly() async {
    try {
      await _store.clearPkceVerifier();
    } catch (_) {
      // The caller already has an honest failure to report.
    }
  }

  static bool _matchesRedirect(Uri uri, Uri redirect) {
    return uri.scheme.toLowerCase() == redirect.scheme.toLowerCase() &&
        uri.host.toLowerCase() == redirect.host.toLowerCase() &&
        uri.path == redirect.path;
  }

  static Map<String, String> _fragmentParameters(Uri uri) {
    if (uri.fragment.isEmpty) {
      return const <String, String>{};
    }
    return Uri.splitQueryString(uri.fragment);
  }

  Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, Object?>? body,
    String? bearer,
  }) async {
    try {
      final headers = <String, String>{
        ..._jsonHeaders,
        if (bearer != null) 'authorization': 'Bearer $bearer',
      };
      final response = method == 'POST'
          ? await _client
              .post(url, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(requestTimeout)
          : await _client.get(url, headers: headers).timeout(requestTimeout);
      return response;
    } on SocketException {
      throw const AccountException.network();
    } on TimeoutException {
      throw const AccountException.network();
    } on http.ClientException {
      throw const AccountException.network();
    }
  }

  ArenaAuthSession _sessionFromBody(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const AccountException.malformed();
    }
    if (decoded is! Map) {
      throw const AccountException.malformed();
    }
    final accessToken = decoded['access_token']?.toString();
    final user = decoded['user'];
    final userId = user is Map ? user['id']?.toString() : null;
    if (accessToken == null ||
        accessToken.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      throw const AccountException.malformed();
    }
    final expiresAt = _expiry(decoded);
    return ArenaAuthSession(
      accessToken: accessToken,
      userId: userId,
      refreshToken: decoded['refresh_token']?.toString(),
      expiresAt: expiresAt,
    );
  }

  DateTime? _expiry(Map<Object?, Object?> body) {
    final rawExpiresAt = body['expires_at'];
    if (rawExpiresAt is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (rawExpiresAt * 1000).round(),
        isUtc: true,
      ).toLocal();
    }
    final rawExpiresIn = body['expires_in'];
    if (rawExpiresIn is num) {
      return _now().add(Duration(seconds: rawExpiresIn.round()));
    }
    return null;
  }

  AccountException _mapAuthError(http.Response response) {
    if (response.statusCode == 429) {
      return const AccountException(
        'rate_limited',
        'Too many attempts. Wait a moment and try again.',
        statusCode: 429,
      );
    }
    if (response.statusCode >= 500) {
      return AccountException(
        'internal_error',
        'The sign-in service is unavailable right now.',
        statusCode: response.statusCode,
      );
    }
    String? code;
    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        code = decoded['error_code']?.toString() ??
            decoded['error']?.toString() ??
            decoded['code']?.toString();
        message = decoded['msg']?.toString() ??
            decoded['error_description']?.toString() ??
            decoded['message']?.toString();
      }
    } on FormatException {
      // Fall through to the generic mapping.
    }
    switch (code) {
      case 'otp_expired':
      case 'otp_disabled':
      case 'invalid_grant':
      case 'validation_failed':
        return const AccountException(
          'code_invalid',
          'That code is invalid or expired. Request a new one.',
        );
      case 'email_exists':
        return const AccountException(
          'email_taken',
          'That email already has an account. Sign in instead.',
        );
      case 'email_address_invalid':
      case 'email_address_not_authorized':
        return const AccountException(
          'email_invalid',
          'That email address is not accepted. Check it and try again.',
        );
      case 'over_email_send_rate_limit':
        return const AccountException(
          'rate_limited',
          'Too many emails. Wait a moment and try again.',
        );
      case 'user_banned':
        return const AccountException(
          'forbidden',
          'This account is unavailable. Contact support.',
        );
      case 'mfa_required':
        return const AccountException(
          'forbidden',
          'This account needs extra verification it does not support yet.',
        );
      case 'bad_json':
      case 'invalid_request':
        return const AccountException(
          'invalid_request',
          'The sign-in request was not accepted. Try again.',
        );
      default:
        break;
    }
    if (response.statusCode == 400 || response.statusCode == 401) {
      return const AccountException(
        'unauthorized',
        'Sign-in did not complete. Try again.',
        statusCode: 401,
      );
    }
    return AccountException(
      'error',
      message ?? 'Sign-in did not complete. Try again.',
      statusCode: response.statusCode,
    );
  }

  String _newVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List<String>.generate(
      64,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  static String _challengeFor(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
