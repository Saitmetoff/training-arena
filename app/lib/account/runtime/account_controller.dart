/// Account controller.
///
/// Owns the session lifecycle, the signed-in [ArenaProfile], username claim,
/// avatar updates and the access token handed to the linking and battle HTTP
/// clients. Provider and transport details stay behind [ArenaAuthGateway] and
/// [AccountApi], so tests run entirely on fakes.
///
/// Rules encoded here:
/// - the server is the only authority for username uniqueness and avatars;
/// - a failed or expired session fails closed to signed-out with plain copy;
/// - no signal path ever logs or displays a token or email address.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/arena_types.dart';
import '../auth/arena_auth.dart';
import '../auth/auth_store.dart';
import '../data/account_api.dart';
import '../models/account_models.dart';

/// Coarse account lifecycle shown by the shell.
enum AccountStatus { restoring, signedOut, signedIn }

/// Session and profile orchestrator shared by the account surfaces.
class AccountController extends ChangeNotifier {
  AccountController({
    required ArenaAuthGateway auth,
    required AccountApi api,
    ValueNotifier<ArenaProfile?>? viewer,
    DateTime Function()? now,
  })  : _auth = auth,
        _api = api,
        _now = now ?? DateTime.now,
        viewer = viewer ?? ValueNotifier<ArenaProfile?>(null);

  final ArenaAuthGateway _auth;
  final AccountApi _api;
  final DateTime Function() _now;

  /// Signed-in identity for the battle runtime and the account surfaces.
  final ValueNotifier<ArenaProfile?> viewer;

  AccountStatus _status = AccountStatus.restoring;
  ArenaAuthSession? _session;
  ArenaProfile? _profile;
  bool _busy = false;
  bool _googleSignInPending = false;
  String? _notice;
  String? _profileError;

  /// Monotonic auth epoch. Any operation that changes the signed-in identity
  /// (sign-out, deletion, a newer sign-in) bumps it so an older in-flight
  /// response cannot apply its session or profile afterwards.
  int _generation = 0;

  /// Single in-flight refresh shared by concurrent token callers.
  Future<ArenaAuthSession>? _refreshInFlight;

  AccountStatus get status => _status;

  bool get signedIn => _status == AccountStatus.signedIn && _session != null;

  ArenaProfile? get profile => _profile;

  bool get busy => _busy;

  bool get canCancelSignIn => _googleSignInPending && !signedIn;

  /// True when the server has no username for this account yet. Battles and
  /// challenges require one; avatars do not.
  bool get usernameRequired {
    final username = _profile?.username;
    return signedIn && (username == null || username.isEmpty);
  }

  /// Last user-facing account message (plain sentence) or null.
  String? get notice => _notice;

  /// Set when the profile could not be loaded but the session is intact.
  String? get profileError => _profileError;

  void clearNotice() {
    if (_notice == null) {
      return;
    }
    _notice = null;
    notifyListeners();
  }

  /// Restores a persisted session and loads the profile. Safe to call once at
  /// startup; failures leave the shell usable and signed out or retryable.
  Future<void> initialize() async {
    final generation = _generation;
    _status = AccountStatus.restoring;
    notifyListeners();
    ArenaAuthSession? session;
    try {
      session = await _auth.restoreSession();
    } catch (_) {
      session = null;
    }
    if (generation != _generation) {
      // A sign-out or newer sign-in superseded this restore.
      return;
    }
    if (session == null) {
      _status = AccountStatus.signedOut;
      notifyListeners();
      return;
    }
    _session = session;
    _status = AccountStatus.signedIn;
    notifyListeners();
    try {
      await _loadProfile();
    } on AccountException {
      // `_loadProfile` already recorded the honest state: signed out on an
      // expired session, or signed in with a retryable profile error.
    }
  }

  /// Reloads the authoritative profile.
  Future<ArenaProfile> refreshProfile() => _loadProfile();

  /// Google provider sign-in. Requires the release redirect configuration.
  Future<ArenaProfile> signInWithGoogle() async {
    return _runSignIn(() => _auth.signInWithGoogle(), google: true);
  }

  /// Stops waiting for a browser return without clearing the pending challenge.
  Future<void> cancelSignIn() async {
    if (!canCancelSignIn) {
      return;
    }
    final generation = _invalidateIdentity();
    _busy = true;
    notifyListeners();
    var durableFailure = false;
    try {
      await _auth.clearLocalAuth();
    } catch (_) {
      durableFailure = true;
    }
    if (generation != _generation) {
      return;
    }
    _busy = false;
    _notice = durableFailure
        ? 'Sign-in stopped here, but this device could not erase the saved '
            'sign-in state. Start a fresh sign-in before continuing.'
        : 'Sign-in was cancelled. You can try again.';
    notifyListeners();
  }

  /// Sends the email code. The address is not stored.
  Future<void> requestEmailCode(String email) async {
    final value = ArenaEmail.normalize(email);
    final invalid = ArenaEmail.validationMessage(value);
    if (invalid != null) {
      throw AccountException('email_invalid', invalid);
    }
    _busy = true;
    _notice = null;
    notifyListeners();
    try {
      await _auth.requestEmailCode(value);
    } on AccountException catch (error) {
      _notice = error.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Verifies the emailed code and loads the profile.
  Future<ArenaProfile> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    return _runSignIn(
      () => _auth.verifyEmailCode(email: email, code: code),
    );
  }

  /// Claims a unique normalized username. Uniqueness is decided by the
  /// backend unique index; a race surfaces as `username_taken`.
  Future<ArenaProfile> claimUsername(String raw) async {
    final normalized = ArenaUsername.normalize(raw);
    final invalid = ArenaUsername.validationMessage(normalized);
    if (invalid != null) {
      throw AccountException('username_invalid', invalid);
    }
    final current = _profile;
    final currentName = current?.username;
    if (current != null &&
        currentName != null &&
        currentName.isNotEmpty &&
        ArenaUsername.isSame(currentName, normalized)) {
      return current;
    }
    if (!signedIn) {
      throw const AccountException.unauthenticated();
    }
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      final updated = await _api.updateUsername(normalized);
      _requireCurrentIdentity(generation);
      _applyProfile(updated);
      _notice = null;
      return updated;
    } on AccountException catch (error) {
      _requireCurrentIdentity(generation);
      final mapped = _mapUsernameError(error);
      _notice = mapped.message;
      throw mapped;
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  /// Uploads a validated avatar. Client validation mirrors the backend
  /// limits; the server remains the final authority.
  Future<ArenaProfile> updateAvatar(AvatarUpload upload) async {
    if (upload.sizeBytes > ArenaAvatarLimits.maxBytes) {
      throw const AccountException(
        'avatar_too_large',
        'That photo is larger than 2 MB. Choose a smaller one.',
      );
    }
    final invalid = ArenaAvatarLimits.validationMessage(upload);
    if (invalid != null) {
      throw AccountException('avatar_invalid', invalid);
    }
    final sniffed = ArenaAvatarLimits.sniffMimeType(upload.bytes);
    if (sniffed == null) {
      throw const AccountException(
        'avatar_invalid',
        'That file is not a supported image. Choose a JPEG, PNG or WebP photo.',
      );
    }
    if (!signedIn) {
      throw const AccountException.unauthenticated();
    }
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      final updated = await _api.updateAvatar(
        base64: base64Encode(upload.bytes),
        mimeType: sniffed,
      );
      _requireCurrentIdentity(generation);
      _applyProfile(updated);
      _notice = null;
      return updated;
    } on AccountException catch (error) {
      _requireCurrentIdentity(generation);
      if (error.isUnauthenticated) {
        await _endSession(
          'Your sign-in expired. Sign in again to continue.',
        );
        throw const AccountException(
          'expired',
          'Your sign-in expired. Sign in again to continue.',
        );
      }
      _notice = error.message;
      rethrow;
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  /// Removes the avatar; the profile keeps working without one.
  Future<ArenaProfile> removeAvatar() async {
    if (!signedIn) {
      throw const AccountException.unauthenticated();
    }
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      final updated = await _api.removeAvatar();
      _requireCurrentIdentity(generation);
      _applyProfile(updated);
      _notice = null;
      return updated;
    } on AccountException catch (error) {
      _requireCurrentIdentity(generation);
      if (error.isUnauthenticated) {
        await _endSession(
          'Your sign-in expired. Sign in again to continue.',
        );
        throw const AccountException(
          'expired',
          'Your sign-in expired. Sign in again to continue.',
        );
      }
      _notice = error.message;
      rethrow;
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  /// Signs out locally first; the server logout is best effort.
  ///
  /// The identity is invalidated and the in-memory state dropped immediately,
  /// before the gateway call, so an in-flight refresh cannot be applied during
  /// sign-out. Pending durable auth is cleared even when no in-memory session
  /// exists yet (for example during an in-flight restore).
  Future<void> signOut() async {
    final session = _session;
    final generation = _invalidateIdentity();
    _clearLocalState();
    _busy = true;
    notifyListeners();
    var durableFailure = false;
    try {
      if (session != null) {
        try {
          await _auth.signOut(session);
        } on AuthStorageException {
          durableFailure = true;
        } catch (_) {
          // Local sign-out must succeed even when the network does not.
        }
      } else {
        try {
          await _auth.clearLocalAuth();
        } on AuthStorageException {
          durableFailure = true;
        } catch (_) {
          // Best effort; there was no in-memory session to clear.
        }
      }
    } finally {
      // A newer sign-in may have started while the durable clear ran; never
      // overwrite its state or notice.
      if (generation == _generation) {
        _notice = durableFailure
            ? 'You are signed out here, but this device could not erase the '
                'saved session. Sign out again after restarting.'
            : 'You are signed out.';
        _busy = false;
        notifyListeners();
      }
    }
  }

  /// Deletes the account through the documented `delete_account` action.
  ///
  /// A failed server deletion keeps the valid session so the retry is
  /// possible. A deletion that finishes after a newer sign-in must not erase
  /// or expire the newer account.
  Future<void> deleteAccount() async {
    if (!signedIn) {
      throw const AccountException.unauthenticated();
    }
    final session = _session;
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      await _api.deleteAccount();
    } on AccountException catch (error) {
      if (generation != _generation) {
        rethrow;
      }
      if (error.isUnauthenticated) {
        await _endSession(
          'Your sign-in expired. Sign in again to continue.',
        );
        throw const AccountException(
          'expired',
          'Your sign-in expired. Sign in again to continue.',
        );
      }
      // The account still exists; keep the session so the retry is possible.
      _notice = error.message;
      rethrow;
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
    if (generation != _generation) {
      // A newer sign-in superseded the deletion; leave that account alone.
      return;
    }
    // The server deletion succeeded: remove the durable session too. The
    // in-memory clear always runs, but the notice must not claim the saved
    // copy was erased when storage refused.
    var durableFailure = false;
    if (session != null) {
      try {
        await _auth.signOut(session);
      } on AuthStorageException {
        durableFailure = true;
      } catch (_) {
        // Best effort; the in-memory clear below still runs.
      }
    }
    if (generation != _generation) {
      // A newer sign-in started during the durable clear; do not clear it.
      return;
    }
    _invalidateIdentity();
    _clearLocalState();
    _notice = durableFailure
        ? 'Your account was deleted, but this device could not erase the '
            'saved session. Sign out again after restarting.'
        : 'Your account was deleted.';
    notifyListeners();
  }

  /// Current access token for the arena HTTP clients; refreshes when close to
  /// expiry. Returns null when signed out.
  Future<String?> accessToken() async {
    final active = _session;
    if (active == null) {
      return null;
    }
    if (active.isExpired(_now())) {
      final generation = _generation;
      // Share one refresh between concurrent token callers so an older
      // invalid-grant reply can never race a newer success.
      final refresh = _refreshInFlight ??= _auth.refreshSession(active);
      try {
        final refreshed = await refresh;
        if (generation != _generation) {
          // A sign-out or newer sign-in happened during the refresh; never
          // resurrect the old account's token.
          return null;
        }
        _session = refreshed;
        notifyListeners();
        return refreshed.accessToken;
      } on AccountException catch (error) {
        if (generation != _generation) {
          return null;
        }
        if (error.code == 'cancelled') {
          // A newer identity superseded this refresh; it must not sign out.
          return null;
        }
        if (error.isRetryable || error.code == 'storage') {
          // Keep the current session on a transient refresh or secure-storage
          // failure; only a real expiry signs the user out.
          return active.accessToken;
        }
        await _endSession('Your sign-in expired. Sign in again to continue.');
        return null;
      } finally {
        if (identical(_refreshInFlight, refresh)) {
          _refreshInFlight = null;
        }
      }
    }
    return active.accessToken;
  }

  // ------------------------------------------------------------- internals

  Future<ArenaProfile> _runSignIn(
    Future<ArenaAuthSession> Function() operation, {
    bool google = false,
  }) async {
    _busy = true;
    _notice = null;
    // Starting a sign-in supersedes any older auth work; a newer sign-in will
    // in turn supersede this one.
    final generation = _invalidateIdentity();
    _googleSignInPending = google;
    notifyListeners();
    try {
      final session = await operation();
      if (generation != _generation) {
        throw const AccountException(
          'cancelled',
          'Sign-in was superseded. Try again.',
        );
      }
      _session = session;
      _status = AccountStatus.signedIn;
      return await _loadProfile();
    } on AccountException catch (error) {
      if (generation == _generation) {
        _notice = error.message;
      }
      rethrow;
    } finally {
      if (generation == _generation) {
        _busy = false;
        _googleSignInPending = false;
        notifyListeners();
      }
    }
  }

  Future<ArenaProfile> _loadProfile() async {
    final generation = _generation;
    try {
      final profile = await _api.fetchProfile();
      if (generation != _generation) {
        // A newer account/session owns the state now; do not overwrite it.
        return profile;
      }
      _applyProfile(profile);
      _profileError = null;
      return profile;
    } on AccountException catch (error) {
      if (generation != _generation) {
        // A stale failure must not end the newer session.
        rethrow;
      }
      if (error.isUnauthenticated) {
        await _endSession('Your sign-in expired. Sign in again to continue.');
        throw const AccountException(
          'expired',
          'Your sign-in expired. Sign in again to continue.',
        );
      }
      _profileError = error.isRetryable
          ? error.message
          : 'Could not load your profile. Try again.';
      notifyListeners();
      rethrow;
    }
  }

  AccountException _mapUsernameError(AccountException error) {
    if (error.code == 'username_taken') {
      return const AccountException(
        'username_taken',
        'That username is taken. Try another.',
      );
    }
    if (error.code == 'username_invalid') {
      return AccountException('username_invalid', error.message);
    }
    if (error.isUnauthenticated) {
      return const AccountException(
        'expired',
        'Your sign-in expired. Sign in again to continue.',
      );
    }
    return error;
  }

  void _applyProfile(ArenaProfile profile) {
    _profile = profile;
    _profileError = null;
    viewer.value = profile;
  }

  Future<void> _endSession(String notice) async {
    final session = _session;
    // Invalidate and drop the identity before awaiting the gateway, so a
    // delayed expired-response logout cannot clear a newer sign-in.
    final generation = _invalidateIdentity();
    _clearLocalState();
    _busy = false;
    notifyListeners();
    var durableFailure = false;
    try {
      if (session != null) {
        try {
          await _auth.signOut(session);
        } on AuthStorageException {
          durableFailure = true;
        } catch (_) {
          // Local state is already cleared; the server call is best effort.
        }
      } else {
        try {
          await _auth.clearLocalAuth();
        } on AuthStorageException {
          durableFailure = true;
        } catch (_) {
          // Best effort; there was no in-memory session to clear.
        }
      }
    } finally {
      if (generation == _generation) {
        _notice = durableFailure
            ? '$notice This device could not erase the saved session; sign '
                'out again after restarting.'
            : notice;
        notifyListeners();
      }
    }
  }

  /// Invalidates every in-flight identity operation and returns the new
  /// generation, without touching the current in-memory state.
  int _invalidateIdentity() {
    // Detach any in-flight refresh so it cannot be joined by the next identity.
    _refreshInFlight = null;
    _googleSignInPending = false;
    return ++_generation;
  }

  /// Fails a stale response closed without mutating or expiring the newer
  /// identity that replaced it.
  void _requireCurrentIdentity(int generation) {
    if (generation != _generation) {
      throw const AccountException(
        'cancelled',
        'A newer sign-in replaced this account. Try again.',
      );
    }
  }

  /// Drops the signed-in state; callers invalidate the identity first.
  void _clearLocalState() {
    _session = null;
    _profile = null;
    _profileError = null;
    _status = AccountStatus.signedOut;
    viewer.value = null;
  }

}
