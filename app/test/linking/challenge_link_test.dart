import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/linking/challenge_link.dart';

void main() {
  group('ChallengeLink.tryParse', () {
    test('parses the shared HTTPS form and normalizes the token', () {
      final link = ChallengeLink.tryParse(
        Uri.parse('https://example.invalid/c/Ab12Cd34Ef56'),
        expectedHost: 'example.invalid',
      );
      expect(link, isNotNull);
      expect(link!.token, 'ab12cd34ef56');
      expect(link.source, ChallengeLinkSource.https);
      expect(link.readableCode, 'AB12-CD34-EF56');
    });

    test('rejects a different host or path', () {
      expect(
        ChallengeLink.tryParse(
          Uri.parse('https://evil.invalid/c/ab12cd34ef56'),
          expectedHost: 'example.invalid',
        ),
        isNull,
      );
      expect(
        ChallengeLink.tryParse(
          Uri.parse('https://example.invalid/other/ab12cd34ef56'),
          expectedHost: 'example.invalid',
        ),
        isNull,
      );
      expect(
        ChallengeLink.tryParse(
          Uri.parse('https://example.invalid/c/too-short'),
          expectedHost: 'example.invalid',
        ),
        isNull,
      );
    });

    test('parses the trainingarena local fallback scheme', () {
      final link = ChallengeLink.tryParse(
        Uri.parse('trainingarena://challenge/ab12cd34ef56'),
      );
      expect(link, isNotNull);
      expect(link!.token, 'ab12cd34ef56');
      expect(link.source, ChallengeLinkSource.scheme);
      expect(
        ChallengeLink.tryParse(Uri.parse('trainingarena://other/ab12cd34ef56')),
        isNull,
      );
    });

    test('ignores foreign schemes', () {
      expect(ChallengeLink.tryParse(Uri.parse('https://example.com/c/abc')), isNull);
      expect(ChallengeLink.tryParse(Uri.parse('someapp://open')), isNull);
    });

    test('parses pasted text as a link or a bare code', () {
      final fromUrl = ChallengeLink.tryParseText(
        'https://example.invalid/c/ab12cd34ef56',
        expectedHost: 'example.invalid',
      );
      expect(fromUrl!.token, 'ab12cd34ef56');

      final fromCode = ChallengeLink.tryParseText('AB12-CD34-EF56');
      expect(fromCode!.token, 'ab12cd34ef56');
      expect(fromCode.source, ChallengeLinkSource.code);

      expect(ChallengeLink.tryParseText('hello world'), isNull);
      expect(ChallengeLink.tryParseText(''), isNull);
      expect(ChallengeLink.tryParseText('abc'), isNull);
    });

    test('readableCode groups any token length', () {
      expect(ChallengeLink.readableCodeFor('9f2k4p7q'), '9F2K-4P7Q');
      expect(ChallengeLink.readableCodeFor('ab12cd34ef56'), 'AB12-CD34-EF56');
    });
  });
}
