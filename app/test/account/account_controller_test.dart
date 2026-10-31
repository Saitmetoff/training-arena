/// Account controller tests: session lifecycle, username claim, avatar rules,
/// offline retry, sign-out and token handling. All provider and transport
/// details run through the fakes, so no real token or email is involved.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/account/auth/arena_auth.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/account/runtime/account_controller.dart';

import 'fakes.dart';

void main() {
  late FakeArenaAuthGateway auth;
  late FakeAccountApi api;
  late AccountController controller;

  setUp(() {
    auth = FakeArenaAuthGateway();
    api = FakeAccountApi();
    controller = AccountController(auth: auth, api: api);
    controller.addListener(() {});
  });

  tearDown(() => controller.dispose());

  group('session lifecycle', () {
    test('no stored session lands signed out with no profile', () async {
      await controller.initialize();

      expect(controller.status, AccountStatus.signedOut);
      expect(controller.signedIn, isFalse);
      expect(controller.profile, isNull);
      expect(controller.viewer.value, isNull);
    });

    test('a restored session loads the authoritative profile', () async {
      auth.restoredSession = auth.session;

      await controller.initialize();

      expect(controller.signedIn, isTrue);
      expect(controller.profile, fakeViewer());
      expect(controller.viewer.value, fakeViewer());
    });

    test('a profile that cannot load keeps the session and stays retryable',
        () async {
      auth.restoredSession = auth.session;
      api.profileError = const AccountException.network();

      await controller.initialize();

      expect(controller.signedIn, isTrue);
      expect(controller.profile, isNull);
      expect(controller.profileError, contains('offline'));
      expect(controller.viewer.value, isNull);

      api.profileError = null;
      await controller.refreshProfile();

      expect(controller.profile, fakeViewer());
      expect(controller.profileError, isNull);
    });

    test('a rejected session fails closed to signed out with plain copy',
        () async {
      auth.restoredSession = auth.session;
      api.profileError = const AccountException(
        'unauthorized',
        'Sign in to continue.',
        statusCode: 401,
      );

      await controller.initialize();

      expect(controller.status, AccountStatus.signedOut);
      expect(controller.profile, isNull);
      expect(controller.notice, 'Your sign-in expired. Sign in again to continue.');
      expect(auth.signOutCalls, 1);
    });

    test('expired local sessions refresh through the gateway', () async {
      auth.restoredSession = ArenaAuthSession(
        accessToken: 'old-access',
        userId: fakeViewerId,
        refreshToken: fakeRefreshToken,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      auth.session = auth.restoredSession!;

      await controller.initialize();

      expect(controller.signedIn, isTrue);
      expect(await controller.accessToken(), 'refreshed-access-token');
      expect(auth.refreshCalls, 1);
    });

    test('accessToken returns the stored token when refresh is offline',
        () async {
      auth.session = ArenaAuthSession(
        accessToken: 'stale-but-local',
        userId: fakeViewerId,
        refreshToken: fakeRefreshToken,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final expired = auth.session;
      auth.restoredSession = expired;
      auth.refreshError = const AccountException.network();

      await controller.initialize();
      final token = await controller.accessToken();

      expect(token, 'stale-but-local');
      expect(controller.signedIn, isTrue);
    });

    test('a refused refresh ends the session and drops the token', () async {
      auth.session = ArenaAuthSession(
        accessToken: 'stale',
        userId: fakeViewerId,
        refreshToken: fakeRefreshToken,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      auth.restoredSession = auth.session;
      auth.refreshError = const AccountException(
        'expired',
        'Your sign-in expired. Sign in again to continue.',
      );

      await controller.initialize();
      final token = await controller.accessToken();

      expect(token, isNull);
      expect(controller.status, AccountStatus.signedOut);
      expect(controller.profile, isNull);
    });
  });

  group('sign-in', () {
    test('Google sign-in loads the profile and refreshes the viewer', () async {
      final profile = await controller.signInWithGoogle();

      expect(profile, fakeViewer());
      expect(controller.status, AccountStatus.signedIn);
      expect(controller.viewer.value, fakeViewer());
    });

    test('a first sign-in without a username stays in the username step',
        () async {
      api.profile = fakeViewer(username: null);
      await controller.signInWithGoogle();

      expect(controller.signedIn, isTrue);
      expect(controller.usernameRequired, isTrue);
    });

    test('email-code sign-in asks for the code and never keeps the address',
        () async {
      await controller.requestEmailCode('  play@example.invalid ');
      await controller.verifyEmailCode(
        email: 'play@example.invalid',
        code: '123456',
      );

      expect(auth.lastRequestedEmail, 'play@example.invalid');
      expect(auth.lastVerifiedCode, '123456');
      expect(controller.signedIn, isTrue);
      expect(controller.profile, fakeViewer());
    });

    test('cancellation surfaces the plain provider message', () async {
      auth.googleError = const AccountException(
        'cancelled',
        'Sign-in was cancelled. Nothing changed.',
      );

      await expectLater(
        controller.signInWithGoogle(),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(controller.status, isNot(AccountStatus.signedIn));
      expect(controller.notice, 'Sign-in was cancelled. Nothing changed.');
      expect(controller.notice!.contains('@'), isFalse);
    });
  });

  group('username claim', () {
    setUp(() async {
      await controller.signInWithGoogle();
    });

    test('normalizes before sending and updates the viewer', () async {
      final profile = await controller.claimUsername('  Kokoro_2  ');

      expect(api.lastUsernameUpdate, 'Kokoro_2');
      expect(profile.username, 'Kokoro_2');
      expect(controller.viewer.value!.username, 'Kokoro_2');
    });

    test('an unchanged name is a no-op without a round trip', () async {
      final before = api.profileCalls;
      final profile = await controller.claimUsername(' AZIZBEK ');

      expect(api.lastUsernameUpdate, isNull);
      expect(profile, fakeViewer());
      expect(api.profileCalls, before);
    });

    test('a server race reports an actionable duplicate message', () async {
      api.updateUsernameError = const AccountException(
        'username_taken',
        'username already exists for someone@example.invalid',
      );

      await expectLater(
        controller.claimUsername('taken'),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'username_taken')
              .having((e) => e.message, 'message',
                  'That username is taken. Try another.'),
        ),
      );
      expect(controller.notice, 'That username is taken. Try another.');
      expect(controller.viewer.value!.username, 'azizbek');
    });

    test('invalid local input never reaches the backend', () async {
      await expectLater(
        controller.claimUsername('a!b'),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'username_invalid')
              .having((e) => e.message, 'message',
                  'Use letters, digits and underscore only.'),
        ),
      );
      expect(api.lastUsernameUpdate, isNull);
    });

    test('claiming before sign-in fails closed', () async {
      final signedOut = AccountController(auth: auth, api: api);
      await expectLater(
        signedOut.claimUsername('someone'),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'unauthenticated'),
        ),
      );
      signedOut.dispose();
    });
  });

  group('avatar', () {
    setUp(() async {
      await controller.signInWithGoogle();
    });

    test('accepts a valid image and sends sniffed base64', () async {
      final bytes = fakeJpegBytes();
      final profile = await controller.updateAvatar(
        AvatarUpload(bytes: bytes, mimeType: 'image/jpeg'),
      );

      expect(api.lastAvatarBase64, base64Encode(bytes));
      expect(api.lastAvatarMimeType, 'image/jpeg');
      expect(profile.avatarUrl, isNotNull);
    });

    test('rejects camera frames before any upload', () async {
      await expectLater(
        controller.updateAvatar(
          AvatarUpload(bytes: fakeCameraFrameBytes(), mimeType: 'image/jpeg'),
        ),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'avatar_invalid'),
        ),
      );
      expect(api.lastAvatarBase64, isNull);
    });

    test('rejects oversized images before any upload', () async {
      await expectLater(
        controller.updateAvatar(
          AvatarUpload(
            bytes: fakeJpegBytes(length: ArenaAvatarLimits.maxBytes + 8),
            mimeType: 'image/jpeg',
          ),
        ),
        throwsA(
          isA<AccountException>()
              .having((e) => e.code, 'code', 'avatar_too_large'),
        ),
      );
      expect(api.lastAvatarBase64, isNull);
    });

    test('a rejected image keeps the profile and reports the reason', () async {
      api.updateAvatarError = const AccountException(
        'avatar_invalid',
        'That photo was not accepted. Choose a JPEG, PNG or WebP image.',
      );

      await expectLater(
        controller.updateAvatar(
          AvatarUpload(bytes: fakeJpegBytes(), mimeType: 'image/jpeg'),
        ),
        throwsA(
          isA<AccountException>().having((e) => e.code, 'code', 'avatar_invalid'),
        ),
      );
      expect(controller.profile, fakeViewer());
      expect(controller.notice, contains('JPEG'));
    });

    test('remove is available with and without an avatar', () async {
      final profile = await controller.removeAvatar();
      expect(profile.avatarUrl, isNull);
      expect(controller.profile, fakeViewer());
    });
  });

  group('sign-out and deletion', () {
    test('sign-out clears local state even when the server call fails',
        () async {
      await controller.signInWithGoogle();
      auth.signOutError = const AccountException.network();

      await controller.signOut();

      expect(controller.status, AccountStatus.signedOut);
      expect(controller.profile, isNull);
      expect(controller.viewer.value, isNull);
      expect(auth.signOutCalls, 1);
      expect(controller.notice, 'You are signed out.');
    });

    test('deleteAccount clears local state and reports the result', () async {
      await controller.signInWithGoogle();

      await controller.deleteAccount();

      expect(api.deleteCalls, 1);
      expect(auth.signOutCalls, 1);
      expect(controller.status, AccountStatus.signedOut);
      expect(controller.profile, isNull);
      expect(controller.notice, 'Your account was deleted.');
    });

    test('a failed deletion keeps the session for a retry', () async {
      await controller.signInWithGoogle();
      api.deleteError = const AccountException.network();

      await expectLater(controller.deleteAccount(), throwsA(isA<AccountException>()));

      expect(controller.signedIn, isTrue);
      expect(controller.profile, fakeViewer());
    });
  });
}
