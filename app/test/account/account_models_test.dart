/// Account value-object rules: username normalization, email shape, avatar
/// image limits and the failure surface. Nothing here decides uniqueness;
/// the backend unique index owns that.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/account/models/account_models.dart';
import 'package:training_arena/domain/arena_types.dart';

import 'fakes.dart';

void main() {
  group('ArenaUsername', () {
    test('normalize trims only surrounding whitespace', () {
      expect(ArenaUsername.normalize('  Zuhra_1  '), 'Zuhra_1');
      expect(ArenaUsername.normalize('\tazizbek\n'), 'azizbek');
      expect(ArenaUsername.normalize('zuh  ra'), 'zuh  ra');
    });

    test('isSame compares normalized names without case', () {
      expect(ArenaUsername.isSame('Zuhra', ' zuhra '), isTrue);
      expect(ArenaUsername.isSame('zuhra', 'zuhraa'), isFalse);
    });

    test('valid names pass at both length bounds', () {
      expect(ArenaUsername.validationMessage('abc'), isNull);
      expect(ArenaUsername.validationMessage('a' * 20), isNull);
      expect(ArenaUsername.validationMessage('Arena_9'), isNull);
    });

    test('empty, short, long, bad characters and reserved names fail', () {
      expect(ArenaUsername.validationMessage('   '), 'Choose a username.');
      expect(ArenaUsername.validationMessage('ab'), 'Use at least 3 characters.');
      expect(
        ArenaUsername.validationMessage('a' * 21),
        'Use at most 20 characters.',
      );
      expect(
        ArenaUsername.validationMessage('zuhra!'),
        'Use letters, digits and underscore only.',
      );
      expect(
        ArenaUsername.validationMessage('  ADmin '),
        'That username is reserved. Try another.',
      );
    });

    test('normalized input is what the backend receives', () {
      const raw = '  Kokoro_2  ';
      expect(ArenaUsername.validationMessage(raw), isNull);
      expect(ArenaUsername.normalize(raw), 'Kokoro_2');
    });
  });

  group('ArenaEmail', () {
    test('normalizes and validates the address shape', () {
      expect(ArenaEmail.normalize('  a@b.co '), 'a@b.co');
      expect(ArenaEmail.validationMessage(''), 'Enter your email address.');
      expect(
        ArenaEmail.validationMessage('not-an-email'),
        'Enter a valid email address.',
      );
      expect(ArenaEmail.validationMessage('a@b.co'), isNull);
    });
  });

  group('ArenaAvatarLimits', () {
    test('sniffs JPEG, PNG and WebP signatures', () {
      expect(ArenaAvatarLimits.sniffMimeType(fakeJpegBytes()), 'image/jpeg');
      expect(
        ArenaAvatarLimits.sniffMimeType(<int>[
          0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00,
        ]),
        'image/png',
      );
      expect(
        ArenaAvatarLimits.sniffMimeType(<int>[
          0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50,
        ]),
        'image/webp',
      );
    });

    test('camera-like raw bytes are never a supported image', () {
      expect(ArenaAvatarLimits.sniffMimeType(fakeCameraFrameBytes()), isNull);
      expect(ArenaAvatarLimits.sniffMimeType(<int>[]), isNull);
    });

    test('validation messages are actionable and catch every rejection', () {
      expect(
        ArenaAvatarLimits.validationMessage(
          const AvatarUpload(bytes: <int>[], mimeType: 'image/jpeg'),
        ),
        contains('empty'),
      );
      expect(
        ArenaAvatarLimits.validationMessage(
          AvatarUpload(
            bytes: fakeJpegBytes(length: ArenaAvatarLimits.maxBytes + 1),
            mimeType: 'image/jpeg',
          ),
        ),
        contains('2 MB'),
      );
      expect(
        ArenaAvatarLimits.validationMessage(
          AvatarUpload(
            bytes: fakeCameraFrameBytes(),
            mimeType: 'image/jpeg',
          ),
        ),
        contains('not a supported image'),
      );
      expect(
        ArenaAvatarLimits.validationMessage(
          AvatarUpload(bytes: fakeJpegBytes(), mimeType: 'image/png'),
        ),
        contains('does not match its file type'),
      );
      expect(
        ArenaAvatarLimits.validationMessage(
          AvatarUpload(bytes: fakeJpegBytes(), mimeType: 'image/jpeg'),
        ),
        isNull,
      );
    });
  });

  group('AccountException', () {
    test('classifies unauthenticated and retryable failures', () {
      const unauthorized = AccountException('unauthorized', 'Sign in.');
      const notFound = AccountException('not_found', 'Gone.');
      const network = AccountException.network();
      const server = AccountException('internal_error', 'Down.', statusCode: 500);

      expect(unauthorized.isUnauthenticated, isTrue);
      expect(notFound.isUnauthenticated, isFalse);
      expect(network.isRetryable, isTrue);
      expect(server.isRetryable, isTrue);
      expect(notFound.isRetryable, isFalse);
    });

    test('toString never carries a message, token or email', () {
      const error = AccountException(
        'username_taken',
        'That username is taken. Try another.',
      );
      expect(error.toString(), 'AccountException(username_taken)');
      expect(error.toString().contains('@'), isFalse);
    });
  });

  group('leaderboard and public player view objects', () {
    test('leaderboard rows know the viewer and compare by value', () {
      final entry = ArenaLeaderboardEntry(profile: fakeViewer(), rank: 12);
      expect(entry.isViewer(fakeViewerId), isTrue);
      expect(entry.isViewer(fakeOpponentId), isFalse);
      expect(entry.isViewer(null), isFalse);
      expect(
        entry,
        ArenaLeaderboardEntry(profile: fakeViewer(), rank: 12),
      );
    });

    test('public player falls back to a safe display name', () {
      const anonymous = ArenaPublicPlayer(
        profile: ArenaProfile(id: 'someone'),
      );
      expect(anonymous.displayName, 'player');
      expect(
        ArenaPublicPlayer(profile: fakeOpponent()).displayName,
        'zuhra',
      );
    });
  });
}
